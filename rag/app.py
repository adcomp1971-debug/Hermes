"""
Hermes RAG — chat over your own documents, fully local.

No external vector DB: embeddings live in a numpy array on disk.
Good enough for thousands of chunks (small/medium office). For larger
corpora, swap _Store for a real vector DB later.

Pipeline:
  ingest:  read .txt/.md/.pdf from /data/documents -> chunk -> embed (Ollama) -> persist
  query:   embed question -> cosine top-k -> stuff into prompt -> answer with Ollama
"""
import os
import glob
import json
import pickle
import logging

import numpy as np
import httpx
from fastapi import FastAPI
from pydantic import BaseModel
from pypdf import PdfReader

logging.basicConfig(level=logging.INFO)
log = logging.getLogger("rag")

OLLAMA_URL = os.environ.get("OLLAMA_BASE_URL", "http://ollama:11434")
EMBED_MODEL = os.environ.get("EMBED_MODEL", "nomic-embed-text")
GEN_MODEL = os.environ.get("HERMES_MODEL", "qwen2.5:7b")
DOC_DIR = "/data/documents"
STORE_PATH = "/var/lib/rag/store.pkl"
CHUNK = 800       # chars per chunk
OVERLAP = 100
TOP_K = 4
MIN_SCORE = 0.35  # below this, we treat the corpus as "no answer here"

app = FastAPI(title="Hermes RAG")


class _Store:
    def __init__(self):
        self.vectors = np.zeros((0, 0))
        self.chunks: list[str] = []
        self.sources: list[str] = []

    def save(self):
        os.makedirs(os.path.dirname(STORE_PATH), exist_ok=True)
        with open(STORE_PATH, "wb") as f:
            pickle.dump((self.vectors, self.chunks, self.sources), f)

    def load(self):
        if os.path.exists(STORE_PATH):
            with open(STORE_PATH, "rb") as f:
                self.vectors, self.chunks, self.sources = pickle.load(f)
            log.info("Loaded %d chunks from store.", len(self.chunks))


store = _Store()


def _read(path: str) -> str:
    if path.lower().endswith(".pdf"):
        try:
            return "\n".join((p.extract_text() or "") for p in PdfReader(path).pages)
        except Exception as e:
            log.warning("PDF read failed %s: %s", path, e)
            return ""
    with open(path, encoding="utf-8", errors="ignore") as f:
        return f.read()


def _chunk(text: str) -> list[str]:
    text = " ".join(text.split())
    out, i = [], 0
    while i < len(text):
        out.append(text[i:i + CHUNK])
        i += CHUNK - OVERLAP
    return [c for c in out if c.strip()]


async def _embed(texts: list[str]) -> np.ndarray:
    vecs = []
    async with httpx.AsyncClient(timeout=120) as c:
        for t in texts:
            r = await c.post(f"{OLLAMA_URL}/api/embeddings",
                             json={"model": EMBED_MODEL, "prompt": t})
            r.raise_for_status()
            vecs.append(r.json()["embedding"])
    return np.array(vecs, dtype=np.float32)


class IngestResult(BaseModel):
    files: int
    chunks: int


@app.post("/ingest", response_model=IngestResult)
async def ingest():
    files = glob.glob(f"{DOC_DIR}/**/*", recursive=True)
    files = [f for f in files if f.lower().endswith((".txt", ".md", ".pdf"))]
    all_chunks, all_src = [], []
    for path in files:
        for ch in _chunk(_read(path)):
            all_chunks.append(ch)
            all_src.append(os.path.basename(path))
    if not all_chunks:
        return IngestResult(files=0, chunks=0)
    vecs = await _embed(all_chunks)
    # normalize for cosine via dot product
    norms = np.linalg.norm(vecs, axis=1, keepdims=True)
    store.vectors = vecs / np.clip(norms, 1e-8, None)
    store.chunks = all_chunks
    store.sources = all_src
    store.save()
    log.info("Ingested %d files, %d chunks.", len(files), len(all_chunks))
    return IngestResult(files=len(files), chunks=len(all_chunks))


class Query(BaseModel):
    question: str


@app.post("/query")
async def query(q: Query):
    if not store.chunks:
        return {"grounded": False, "answer": None}
    qv = (await _embed([q.question]))[0]
    qv = qv / max(np.linalg.norm(qv), 1e-8)
    scores = store.vectors @ qv
    top = np.argsort(scores)[::-1][:TOP_K]
    if float(scores[top[0]]) < MIN_SCORE:
        return {"grounded": False, "answer": None}
    context = "\n\n".join(
        f"[{store.sources[i]}] {store.chunks[i]}" for i in top
    )
    prompt = (
        "Answer the question using ONLY the context below. "
        "If the context does not contain the answer, say so plainly. "
        "Cite the source filename in brackets.\n\n"
        f"Context:\n{context}\n\nQuestion: {q.question}\nAnswer:"
    )
    async with httpx.AsyncClient(timeout=120) as c:
        r = await c.post(f"{OLLAMA_URL}/api/generate",
                         json={"model": GEN_MODEL, "prompt": prompt, "stream": False})
        r.raise_for_status()
        answer = r.json().get("response", "").strip()
    return {"grounded": True, "answer": answer,
            "sources": sorted({store.sources[i] for i in top})}


@app.get("/health")
async def health():
    return {"status": "ok", "chunks": len(store.chunks)}


@app.on_event("startup")
async def startup():
    store.load()
