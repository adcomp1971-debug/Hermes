<p align="center">
  <img src="docs/screenshots/hermes-box-banner.png" alt="Hermes Box" width="800">
</p>

<br>

<div align="center">

# 🤖 Hermes Box

**AI Infrastructure in a Box** — Self-hosted LLM Stack for Small and Medium Business

<br>

[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)](docker-compose.yml)
[![GPU](https://img.shields.io/badge/GPU-NVIDIA-76B900?logo=nvidia&logoColor=white)](#-hardware-requirements)
[![CPU](https://img.shields.io/badge/CPU-Fallback-FF6F00)](#-hardware-requirements)
[![Telegram](https://img.shields.io/badge/Chat-Telegram-26A5E4?logo=telegram&logoColor=white)](#-features)
[![Open WebUI](https://img.shields.io/badge/UI-Open%20WebUI-FF6B6B)](#-quick-start)

<br>

[🚀 Quick Start](#-quick-start) •
[🏗️ Architecture](#-architecture) •
[📊 Tiers](#-deployment-tiers) •
[🔧 Configuration](#-configuration) •
[📖 Documentation](ARCHITECTURE.md)

</div>

---

## 💡 What is Hermes Box?

Hermes Box is a **turnkey AI infrastructure** that turns any server with a GPU into a private, secure AI assistant for your entire team.

**No cloud dependency. No monthly per-seat fees. No data leaving your network.**

```bash
# One command to deploy your own AI stack
git clone https://github.com/adcomp1971/hermes-box
cd hermes-box && ./setup.sh
# → Open http://localhost:3000 → Chat with your private AI
```

### Why Hermes Box?

| Problem | Hermes Box Solution |
|---------|-------------------|
| ChatGPT costs $20–$30/user/month | **One-time hardware cost, $0/user** |
| Cloud AI trains on your data | **100% private, runs on your hardware** |
| Need DevOps to deploy AI | **One script, done in 5 minutes** |
| Team needs remote access | **Built-in VPN (Tailscale)** |
| No internet? No AI | **Runs fully offline** |

---

## ✨ Features

- **🧠 Private LLM Inference** — Ollama with Qwen, Llama, Nemotron — fully local
- **💬 Web Chat UI** — Open WebUI with mobile-responsive interface
- **🤖 Telegram Bot** — AI assistant for your whole team in Telegram
- **🔒 Guardrails** — PII redaction, rate limiting, prompt injection protection
- **🔐 VPN Included** — Tailscale for secure remote access
- **📊 Dashboard** — Real-time monitoring with health checks
- **📦 One Command Deploy** — `./setup.sh` does everything
- **🎯 Three Tiers** — From RTX 3060 to H100 cluster

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                        USER ACCESS LAYER                              │
│   ┌──────────┐   ┌──────────────┐   ┌──────────────────┐            │
│   │   🌐     │   │   📱        │   │   🔐             │            │
│   │ Web UI   │   │ Telegram Bot│   │   VPN Client     │            │
│   │ :3000    │   │             │   │   (Tailscale)    │            │
│   └────┬─────┘   └──────┬──────┘   └────────┬─────────┘            │
│        │                │                    │                       │
├────────┼────────────────┼────────────────────┼──────────────────────┤
│        │       SERVICE LAYER                 │                      │
│   ┌────▼────────────┬───▼────────────┬──────▼──────────┐           │
│   │  Hermes Agent   │  Guardrails    │  Tailscale      │           │
│   │  :8787          │  :8001         │  VPN Gateway    │           │
│   │  Orchestration  │  Security      │  Mesh Network   │           │
│   └────┬────────────┴───┬────────────┴──────┬──────────┘           │
│        │                │                    │                       │
│   ┌────▼────────────────▼──────────────────────┐                    │
│   │           AI INFERENCE LAYER                │                    │
│   │   ┌────────────────────────────────────┐   │                    │
│   │   │  Ollama / NVIDIA NIM               │   │                    │
│   │   │  Qwen 2.5 · Llama 3 · Nemotron    │   │                    │
│   │   │  TensorRT-LLM · Triton Server     │   │                    │
│   │   └──────────────┬─────────────────────┘   │                    │
│   └─────────────────┼─────────────────────────┘                    │
│                     │                                               │
├─────────────────────┼───────────────────────────────────────────────┤
│              HARDWARE LAYER                                         │
│   ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │
│   │ RTX 3060 │  │ RTX 4090 │  │ A100 80GB│  │ H100 Cluster     │  │
│   │ 12GB VRAM│  │ 24GB VRAM│  │ 80GB VRAM│  │ 640GB+ VRAM      │  │
│   │      Small Office    │  │   Business    │  │   Enterprise     │  │
│   └──────────┘  └──────────┘  └──────────┘  └──────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘
```

**Data flow:**
1. User sends message via Web UI, Telegram, or VPN
2. Hermes Agent receives, routes, orchestrates
3. Guardrails scans for PII/injections (blocks or redacts)
4. Ollama/NIM runs inference on local GPU
5. Response flows back through the chain to the user

---

## 📊 Deployment Tiers

| Tier | Users | Hardware | Model | Cost | Profile |
|------|-------|----------|-------|------|---------|
| 🥉 **Small Office** | 5–20 | RTX 3060/4060 (12GB) or CPU | Qwen 2.5 7B / Llama 3.1 8B | ~$1,200–$1,600 | `basic` |
| 🥈 **Business** | 20–100 | 2× RTX 4090 / A100 (80GB) | Qwen 2.5 32B / Nemotron Nano | ~$8K–$18K | `gpu` |
| 🥇 **Enterprise** | 100+ | 4–8× H100 / A100 cluster | Nemotron Super 120B / Ultra 550B | ~$120K+ or rental | `full` |

> 💡 **No GPU?** Use `basic` profile with Qwen 2.5 7B on CPU. Slower but fully functional.

---

## 🚀 Quick Start

### Prerequisites

- [Docker](https://docs.docker.com/engine/install/) + [Docker Compose](https://docs.docker.com/compose/install/)
- Linux or macOS (Windows via WSL2)
- Optional: NVIDIA GPU + [nvidia-container-toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)

### 5-Step Setup

```bash
# 1. Clone
git clone https://github.com/adcomp1971/hermes-box
cd hermes-box

# 2. Configure (edit .env with your tokens)
cp .env.example .env
# → Set TELEGRAM_BOT_TOKEN if you want Telegram bot

# 3. Run setup (detects GPU automatically)
./setup.sh

# 4. Pull a model
docker exec hermes-ollama ollama pull qwen2.5:7b

# 5. Open the UI
open http://localhost:3000   # Web Chat
# → Or talk to your Telegram bot
```

### Docker Compose Profiles

```bash
# CPU-only (basic stack)
docker compose --profile basic up -d

# With GPU support
docker compose --profile gpu up -d

# Full enterprise stack
docker compose --profile full up -d
```

---

## 🔧 Configuration

### Minimal `.env`

```bash
TELEGRAM_BOT_TOKEN=***     # From @BotFather (optional)
WEBUI_SECRET_KEY=***       # Auto-generated if empty
TS_AUTHKEY=***             # Tailscale auth key (optional)
```

### Hermes Agent (`config/hermes.yaml`)

Configure agent behavior, tool access, and model selection:
- **Model:** Switch between Ollama, NVIDIA NIM, or external API
- **Tools:** Enable/disable terminal, file, web access
- **Gateway:** Telegram, webhook, or direct CLI

See [docs/deployment.md](docs/deployment.md) for full configuration reference.

---

## 🖥️ Screenshots

<div align="center">
  <img src="docs/screenshots/webui-chat.png" alt="Open WebUI Chat" width="400">
  <img src="docs/screenshots/telegram-bot.png" alt="Telegram Bot" width="400">
  <br>
  <img src="docs/screenshots/dashboard.png" alt="Monitoring Dashboard" width="800">
</div>

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Deep dive into system design |
| [docs/quickstart.md](docs/quickstart.md) | Step-by-step for non-technical users |
| [docs/deployment.md](docs/deployment.md) | Production deployment guide |
| [examples/small-office](examples/small-office/) | Small office config & walkthrough |
| [examples/business](examples/business/) | Business tier deployment |
| [examples/enterprise](examples/enterprise/) | Enterprise HA setup |

---

## 🛡️ Security

- **PII Detection** — Emails, phones, SSNs, credit cards auto-redacted
- **Prompt Injection Protection** — Blocked at gateway level
- **Rate Limiting** — 100 req/min per user
- **VPN** — All traffic through encrypted mesh (Tailscale)
- **No Cloud** — Your data never leaves your hardware

See [SECURITY.md](SECURITY.md) for full details.

---

## 🤝 Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

**Ideas for contributions:**
- Add support for more models (Mistral, Gemma, Phi)
- Create Helm chart for Kubernetes deployment
- Add monitoring with Prometheus/Grafana
- Build a mobile app
- Translate docs to other languages

---

## 📄 License

MIT © [Alex Skver](https://github.com/adcomp1971)

---

<div align="center">
  <sub>Built with ❤️ for businesses that value privacy and independence from cloud AI.</sub>
</div>
