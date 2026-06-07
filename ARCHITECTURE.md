# Hermes-Box Architecture

**AI Infrastructure in a Box** — a self-contained, Docker-based platform that bundles Ollama, Open WebUI, Hermes Agent, guardrails, monitoring, and VPN into a single deployable stack.

---

## System Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                        USER ACCESS LAYER                             │
│                                                                      │
│   ┌──────────────┐  ┌──────────────┐  ┌─────────────────────────┐   │
│   │   Web UI     │  │   Telegram   │  │    VPN (Tailscale)      │   │
│   │  :3000       │  │   Bot (API)  │  │    Secure Tunnel        │   │
│   └──────┬───────┘  └──────┬───────┘  └───────────┬─────────────┘   │
│          │                 │                       │                 │
├──────────┼─────────────────┼───────────────────────┼─────────────────┤
│          │                 │                       │                 │
│   ┌──────┴─────────────────┴───────────────────────┴──────────┐     │
│   │                    SERVICE LAYER                            │     │
│   │                                                             │     │
│   │  ┌─────────────────┐    ┌──────────────────────────────┐   │     │
│   │  │  Hermes Agent   │    │  Guardrails                  │   │     │
│   │  │  Orchestration  │◄──►│  Security Policies           │   │     │
│   │  │  :8787          │    │  :8001                       │   │     │
│   │  └────────┬────────┘    └──────────────────────────────┘   │     │
│   │           │                                                 │     │
│   │  ┌────────┴──────────────────────────────────────────┐     │     │
│   │  │         Open WebUI                                │     │     │
│   │  │         Chat Interface / API Gateway              │     │     │
│   │  │         :3000  ←→  :8080                          │     │     │
│   │  └────────┬──────────────────────────────────────────┘     │     │
│   │           │                                                 │     │
│   │  ┌────────┴──────────────────────────────────────────┐     │     │
│   │  │         Ollama (AI Inference)                     │     │     │
│   │  │         Model Serving :11434                      │     │     │
│   │  └───────────────────────────────────────────────────┘     │     │
│   │                                                             │     │
│   │  ┌──────────────────────────────────────────────────────┐   │     │
│   │  │  Dashboard (Monitoring)  :9119                       │   │     │
│   │  └──────────────────────────────────────────────────────┘   │     │
│   └─────────────────────────────────────────────────────────────┘     │
│                                                                      │
├──────────────────────────────────────────────────────────────────────┤
│                        INFRASTRUCTURE LAYER                           │
│                                                                      │
│   ┌──────────────────────────────────────────────────────────────┐  │
│   │                    Docker Compose                             │  │
│   │  ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐        │  │
│   │  │oll │ │web │ │her │ │grd │ │dsh │ │ts  │        │  │
│   │  └────┘ └────┘ └────┘ └────┘ └────┘ └────┘        │  │
│   │  Profiles: full │ gpu │ basic                       │  │
│   └───────────────────────────────────────────────────┘  │
│                                                                      │
│   ┌──────────────────────────────────────────────────────────────┐  │
│   │                     Host OS (Linux)                           │  │
│   │          NVIDIA Drivers / Docker Engine / Networking          │  │
│   └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
├──────────────────────────────────────────────────────────────────────┤
│                        HARDWARE LAYER                                │
│                                                                      │
│   ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │
│   │  CPU     │  │  RAM     │  │  Storage │  │  GPU (optional)  │  │
│   │  x86_64  │  │  8-512GB │  │  SSD     │  │  NVIDIA / AMD    │  │
│   └──────────┘  └──────────┘  └──────────┘  └──────────────────┘  │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Component Descriptions

### 1. Ollama (AI Inference Engine)
- **Image:** `ollama/ollama:latest`
- **Port:** `11434`
- **Purpose:** Runs and serves large language models locally (Llama, Mistral, DeepSeek, Qwen, etc.)
- **Storage:** Persistent volume at `ollama_data:/root/.ollama` for model weights
- **GPU:** NVIDIA GPU passthrough via `device reservations`

### 2. Open WebUI (Chat Interface)
- **Image:** `ghcr.io/open-webui/open-webui:main`
- **Port:** `3000` (exposed) → `8080` (container)
- **Purpose:** Full-featured web chat UI; supports multi-user, RAG, conversation history
- **Storage:** `webui_data:/app/backend/data`
- **Dependency:** Requires Ollama to be healthy first

### 3. Hermes Agent (Orchestration)
- **Image:** `hermes-agent/hermes:latest`
- **Port:** `8787`
- **Purpose:** AI agent orchestration layer — manages tool use, multi-step reasoning, and connects to external services (Telegram, APIs)
- **Storage:** `hermes_data:/var/lib/hermes`
- **Config:** `./config/hermes.yaml` mounted read-only
- **Key env vars:** `TELEGRAM_BOT_TOKEN`, `OPENAI_API_KEY`

### 4. Guardrails (Security Layer)
- **Image:** `hermes-agent/guardrails:latest`
- **Port:** `8001`
- **Purpose:** Content filtering, prompt injection detection, PII redaction, and policy enforcement
- **Config:** `./config/guardrails.yaml` mounted read-only
- **Enabled in:** `full` and `gpu` profiles

### 5. Dashboard (Monitoring)
- **Image:** `nginx:alpine`
- **Port:** `9119`
- **Purpose:** Static monitoring dashboard serving screenshots and status
- **Only in:** `full` profile

### 6. Tailscale (VPN Gateway)
- **Image:** `tailscale/tailscale:latest`
- **Purpose:** Secure mesh VPN for remote access — no open ports needed on the host firewall
- **Networking:** Requires `NET_ADMIN` and `SYS_MODULE` capabilities + `/dev/net/tun`

---

## Data Flow

### Chat Request (Web UI)

```
User Browser  ──HTTP──►  Open WebUI (:3000)
                              │
                              ▼
                         Ollama (:11434)
                              │
                         ┌────┴────┐
                         │         │
                    Hermes     Guardrails
                    (:8787)    (:8001)
                         │         │
                         └────┬────┘
                              │
                              ▼
                        Response ──► User
```

### Telegram Bot Interaction

```
Telegram User ──► Telegram API
                      │
                      ▼
                Hermes Agent (:8787)
                 ┌─────┴─────┐
                 │           │
            Ollama      Guardrails
            (:11434)    (:8001)
                 │           │
                 └─────┬─────┘
                       │
                       ▼
                Response ──► Telegram User
```

### Admin Remote Access (VPN)

```
Admin Device ──Tailscale──► Tailscale Sidecar (hermes-vpn)
                                │
                          ┌─────┴─────┐
                          │    :3000  │  Open WebUI
                          │    :8787  │  Hermes API
                          │    :9119  │  Dashboard
                          └───────────┘
```

---

## Deployment Tiers

| Tier | Profile | Services | Recommended Hardware | Use Case |
|------|---------|----------|---------------------|----------|
| **Basic** | `basic` | Open WebUI, Hermes, Tailscale | 8+ CPU cores, 16 GB RAM, no GPU | Lightweight setup; CPU-only inference; remote access via VPN |
| **GPU** | `gpu` | Basic + Ollama (GPU) + Guardrails | 8+ CPU cores, 32 GB RAM, NVIDIA GPU (8+ GB VRAM) | Local LLM inference with GPU acceleration and guardrails |
| **Full** | `full` | All services including Dashboard | 16+ CPU cores, 64 GB RAM, NVIDIA GPU (24+ GB VRAM) | Production-ready with monitoring, full security stack, and dashboard |

---

## Volume Map

| Volume Name | Container Mount | Purpose |
|-------------|----------------|---------|
| `ollama_data` | `/root/.ollama` | Model weights and Ollama config |
| `webui_data` | `/app/backend/data` | Chat history, user data, RAG documents |
| `hermes_data` | `/var/lib/hermes` | Agent state, conversation logs |
| `guardrails_data` | `/var/lib/guardrails` | Guardrails policies and audit logs |
| `tailscale_data` | `/var/lib/tailscale` | VPN credentials and state |

---

## Port Map

| Port | Service | Protocol | Purpose |
|------|---------|----------|---------|
| `11434` | Ollama | HTTP | Model inference API |
| `3000` | Open WebUI | HTTP | Web chat interface |
| `8787` | Hermes Agent | HTTP | Agent orchestration API |
| `8001` | Guardrails | HTTP | Security policy API |
| `9119` | Dashboard | HTTP | Monitoring dashboard |

---

## Security Model

1. **Defense in depth** — Guardrails service filters all model I/O
2. **VPN-only access** — Tailscale provides encrypted mesh networking; no public port exposure
3. **Read-only config mounts** — Configuration files are mounted `:ro` inside containers
4. **Least privilege** — Docker socket access is limited to the Hermes container only
5. **Secret management** — All secrets via environment variables (`.env` file, gitignored)
