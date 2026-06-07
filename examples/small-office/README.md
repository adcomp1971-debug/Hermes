---
title: Small Office — Hermes-Box Configuration Example
tier: small-office
audience: 5–20 people
difficulty: beginner
estimated_cost: $1,200–$2,500 one-time + $20–$60/mo
hardware: Single RTX 3060/4060 or CPU-only
models: Qwen 2.5 7B
profile: basic
created: 2026-06-07
---

# Small Office Configuration Example

> **5–20 users** | Light collaboration, internal chatbot, document Q&A, basic RAG

This configuration is designed for a small team that wants a private, self-hosted AI assistant without a large hardware or operational budget. It runs on a single desktop or refurbished workstation and uses a 7B-parameter model that performs well on consumer GPUs.

---

## Overview

| Attribute | Value |
|-----------|-------|
| Users | 5–20 |
| AI Model | Qwen 2.5 7B (ollama) |
| Docker Profile | `docker compose --profile basic up` |
| UI | Open WebUI |
| Remote Access | Tailscale VPN (optional) |
| GPU | Single RTX 3060 12GB / RTX 4060 16GB, or CPU-only |
| RAM | 16 GB (CPU) / 32 GB (GPU) |
| Storage | 100 GB SSD |

---

## Hardware Recommendations

### Option A: Dedicated Mini Workstation (GPU)

| Component | Recommendation | Est. Cost |
|-----------|---------------|-----------|
| CPU | Intel i7-13700 / AMD Ryzen 7 7700 | $350 |
| RAM | 32 GB DDR5 | $100 |
| GPU | NVIDIA RTX 4060 16GB or RTX 3060 12GB | $300–$500 |
| Storage | 1 TB NVMe SSD | $80 |
| PSU | 650W Gold | $80 |
| Case | Mini tower | $50 |
| **Total** | | **~$1,160–$1,560** |

### Option B: CPU-Only (Existing Desktop)

| Component | Recommendation | Est. Cost |
|-----------|---------------|-----------|
| CPU | Intel i7 / AMD Ryzen 7 (8+ cores) | Existing |
| RAM | 32 GB (16 GB minimum) | $80 |
| Storage | 512 GB+ SSD | Existing |
| **Total** | | **~$80** (if reusing hardware) |

> **CPU-only performance:** Qwen 2.5 7B runs at ~5–15 tokens/sec on 8+ cores. Suitable for async chat and batch document work but not real-time conversation.

---

## Setup Steps

### 1. Prerequisites

```bash
# Install Docker Engine (Ubuntu/Debian)
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker

# Install NVIDIA dependencies (GPU only)
sudo apt install nvidia-driver-545 nvidia-utils-545
sudo apt install nvidia-container-toolkit
sudo systemctl restart docker
```

### 2. Clone & Configure

```bash
git clone https://github.com/nousresearch/hermes-box.git
cd hermes-box

# Create environment file
cp .env.template .env 2>/dev/null || touch .env
# Edit .env:
#   WEBUI_SECRET_KEY=$(openssl rand -hex 64)
#   Optional: TELEGRAM_BOT_TOKEN=your:token_here
#   Optional: TS_AUTHKEY=tskey-auth-xxxxx
```

### 3. Pre-Pull the Model

```bash
# Pull the 7B model before starting services
docker run --rm -v ollama_data:/root/.ollama ollama/ollama pull qwen2.5:7b
```

### 4. Start Services

```bash
docker compose --profile basic up -d
```

This starts:
- `open-webui` (Web chat on port 3000)
- `hermes` (Agent orchestration on port 8787)
- `tailscale` (VPN — only connects if `TS_AUTHKEY` is set)

### 5. Verify

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
# Expected:
# hermes-webui    Up ...    0.0.0.0:3000->8080/tcp
# hermes-core     Up ...    0.0.0.0:8787->8787/tcp
# hermes-vpn      Up ...    (no ports exposed)

curl -sf http://localhost:3000 && echo "Web UI OK"
curl -sf http://localhost:8787 && echo "Hermes OK"
```

### 6. Open Web UI & Configure

1. Open `http://localhost:3000` in a browser
2. Create the first admin account
3. Go to **Admin Settings → Models** and verify `qwen2.5:latest` is available
4. (Optional) Enable user signups for the team — set `WEBUI_SECRET_KEY` first

---

## Expected Performance

### With RTX 4060 16GB

| Metric | Value |
|--------|-------|
| Prompt processing | ~2,500 tokens/sec |
| Text generation | ~50–80 tokens/sec |
| Concurrent users | 2–3 (before queuing) |
| Context window | 32K tokens |
| First token latency | ~500 ms |

### CPU-Only (16-core)

| Metric | Value |
|--------|-------|
| Prompt processing | ~200 tokens/sec |
| Text generation | ~8–15 tokens/sec |
| Concurrent users | 1 (queue others) |
| Context window | 8K tokens (practical) |
| First token latency | ~2–5 seconds |

---

## Cost Estimate

| Item | One-Time | Monthly |
|------|----------|---------|
| Hardware (Option A) | $1,200–$1,600 | — |
| Electricity (150W GPU idle, 250W load, 8h/day) | — | $15–$25 |
| Internet (static IP or Tailscale Funnel optional) | — | $0–$10 |
| Tailscale Personal (3 users free, 20 users ~$5/mo) | — | $0–$5 |
| Domain + TLS (optional) | $15/yr | ~$1.25 |
| **Total** | **~$1,200–$1,600** | **~$20–$41/mo** |
| **Year 1 Total** | | **~$1,440–$2,100** |

> 💡 **Tip:** A refurbished Dell Precision workstation ($400–$600) with a used RTX 3060 ($200) can bring the one-time cost below $800.

---

## Config Files

### `docker-compose.override.yml` (optional tuning)

```yaml
version: "3.9"

services:
  ollama:
    deploy:
      resources:
        limits:
          cpus: "8"
          memory: "24G"
        reservations:
          cpus: "4"
          memory: "8G"
  open-webui:
    deploy:
      resources:
        limits:
          memory: "2G"
  hermes:
    deploy:
      resources:
        limits:
          memory: "1G"
```

### `config/hermes.yaml` (model config)

```yaml
agent:
  model: "ollama/qwen2.5:latest"
  max_turns: 50
  temperature: 0.7
  max_tokens: 2048
  toolsets:
    - file
    - web
    - terminal

providers:
  ollama:
    base_url: "http://ollama:11434"
    default_model: "qwen2.5:latest"
    timeout: 120
    keep_alive: "10m"

gateways:
  telegram:
    enabled: false  # Enable with your bot token
    bot_token: "${TELEGRAM_BOT_TOKEN}"
```

---

## Limitations of This Tier

- ⚠️ No guardrails service — content filtering is disabled
- ⚠️ No monitoring dashboard
- ⚠️ Single point of failure (one machine)
- ⚠️ 7B model quality — fine for Q&A, not for complex reasoning
- ⚠️ No high-availability or backup SLA

---

## Recommended For

- Law firms wanting private document Q&A
- Small dev teams needing a code assistant
- Medical offices doing HIPAA-compliant summaries (air-gapped)
- Non-profits on a budget
- School IT departments for internal helpdesk

---

## Upgrade Path

When the team grows beyond 20 users or needs more capable models:

1. Add a second GPU → migrate to `Business` tier (2× RTX 4090)
2. Switch to `--profile gpu` for guardrails and GPU inference
3. Add Prometheus + Grafana for monitoring
4. Set up daily volume backups
