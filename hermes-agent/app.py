"""
Hermes Agent — thin orchestration layer.

Responsibilities:
  - /health        liveness probe (used by docker healthcheck)
  - /chat          HTTP endpoint: routes a prompt to RAG (if doc-grounded) or Ollama
  - Telegram bot   same routing, gated by an explicit ID allowlist

Deliberately small. This is glue, not a framework.
"""
import os
import asyncio
import logging

import httpx
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

logging.basicConfig(level=logging.INFO)
log = logging.getLogger("hermes")

OLLAMA_URL = os.environ.get("OLLAMA_BASE_URL", "http://ollama:11434")
RAG_URL = os.environ.get("RAG_URL", "http://rag:8002")
MODEL = os.environ.get("HERMES_MODEL", "qwen2.5:7b")
TG_TOKEN = os.environ.get("TELEGRAM_BOT_TOKEN", "").strip()

# Allowlist: comma-separated Telegram numeric IDs. Empty list = bot refuses everyone.
_raw_ids = os.environ.get("ALLOWED_TELEGRAM_IDS", "").strip()
ALLOWED_IDS = {int(x) for x in _raw_ids.split(",") if x.strip().isdigit()}

app = FastAPI(title="Hermes Agent")


class ChatRequest(BaseModel):
    prompt: str
    use_rag: bool = True


@app.get("/health")
async def health():
    return {"status": "ok"}


async def _ask_rag(prompt: str) -> str | None:
    """Try the RAG service; return None if it has no answer or is unreachable."""
    try:
        async with httpx.AsyncClient(timeout=60) as c:
            r = await c.post(f"{RAG_URL}/query", json={"question": prompt})
            if r.status_code == 200:
                data = r.json()
                if data.get("grounded"):
                    return data["answer"]
    except Exception as e:
        log.warning("RAG unavailable: %s", e)
    return None


async def _ask_ollama(prompt: str) -> str:
    async with httpx.AsyncClient(timeout=120) as c:
        r = await c.post(
            f"{OLLAMA_URL}/api/generate",
            json={"model": MODEL, "prompt": prompt, "stream": False},
        )
        r.raise_for_status()
        return r.json().get("response", "").strip()


async def route(prompt: str, use_rag: bool = True) -> str:
    if use_rag:
        grounded = await _ask_rag(prompt)
        if grounded:
            return grounded
    return await _ask_ollama(prompt)


@app.post("/chat")
async def chat(req: ChatRequest):
    if not req.prompt.strip():
        raise HTTPException(400, "empty prompt")
    return {"response": await route(req.prompt, req.use_rag)}


# ─── Telegram bot (optional, runs only if token present) ───
async def _start_telegram():
    if not TG_TOKEN:
        log.info("No TELEGRAM_BOT_TOKEN set — Telegram bot disabled.")
        return
    if not ALLOWED_IDS:
        log.warning("TELEGRAM_BOT_TOKEN set but ALLOWED_TELEGRAM_IDS empty — bot will reject all users.")

    from telegram import Update
    from telegram.ext import ApplicationBuilder, ContextTypes, MessageHandler, filters

    async def on_message(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
        uid = update.effective_user.id
        if uid not in ALLOWED_IDS:
            await update.message.reply_text("⛔ Access denied. Your ID is not on the allowlist.")
            log.warning("Rejected Telegram user %s", uid)
            return
        answer = await route(update.message.text or "")
        await update.message.reply_text(answer or "(no response)")

    application = ApplicationBuilder().token(TG_TOKEN).build()
    application.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, on_message))
    log.info("Starting Telegram bot for %d allowed user(s).", len(ALLOWED_IDS))
    await application.initialize()
    await application.start()
    await application.updater.start_polling()


@app.on_event("startup")
async def startup():
    asyncio.create_task(_start_telegram())
