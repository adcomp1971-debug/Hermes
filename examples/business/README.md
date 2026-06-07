---
title: Business — Hermes-Box Configuration Example
tier: business
audience: 20–100 people
difficulty: intermediate
estimated_cost: $8,000–$18,000 one-time + $400–$1,200/mo
hardware: 2× RTX 4090 or 1× A100 80GB
models: Nemotron Nano / Qwen 2.5 32B+
profile: gpu or full
created: 2026-06-07
---

# Business Configuration Example

> **20–100 users** | Multi-department AI assistant, guardrails, secure remote access, production-grade

This configuration is designed for a mid-size organization that needs reliable, private AI with security guardrails, better model quality (32B+), and team-wide remote access. It runs on a dedicated workstation or server with 2× consumer GPUs or a single datacenter GPU.

---

## Overview

| Attribute | Value |
|-----------|-------|
| Users | 20–100 |
| AI Model | Qwen 2.5 32B (4-bit) or Nemotron Nano (~15B) |
| Docker Profile | `docker compose --profile gpu up` |
| UI | Open WebUI |
| Guardrails | Hermes Guardrails (PII redaction, content policy, rate limiting) |
| Remote Access | Tailscale mesh VPN |
| GPU | 2× RTX 4090 24GB (NVLink) or 1× A100 80GB |
| RAM | 64 GB |
| Storage | 500 GB NVMe |

---

## Architecture

```
┌────────────────────────────────────────────────────────────┐
│                    BUSINESS DEPLOYMENT                      │
│                                                            │
│   ┌──────────────────────────────────────────────────┐     │
│   │              DEDICATED SERVER                     │     │
│   │  ┌───────┐ ┌──────────┐ ┌────────┐ ┌──────────┐ │     │
│   │  │ Ollama │ │ Open     │ │ Hermes │ │Guardrails│ │     │
│   │  │ Server │ │ WebUI    │ │ Agent  │ │ :8001    │ │     │
│   │  │:11434  │ │ :3000    │ │ :8787  │ │          │ │     │
│   │  └───┬───┘ └────┬─────┘ └───┬────┘ └────┬─────┘ │     │
│   │      │           │           │            │        │     │
│   │      └───────────┴───────────┴────────────┘        │     │
│   │                    Docker Compose                   │     │
│   ├─────────────────────────────────────────────────────┤     │
│   │ 2× RTX 4090 (NVLink)  •  64 GB RAM  •  1 TB NVMe   │     │
│   └─────────────────────────────────────────────────────┘     │
│                         │                                     │
│              ┌──────────┴──────────┐                          │
│              ▼                     ▼                           │
│        Tailscale VPN          Local LAN                        │
│      (remote workers)       (office network)                   │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

---

## Hardware Recommendations

### Option A: Dual RTX 4090 Workstation

| Component | Recommendation | Est. Cost |
|-----------|---------------|-----------|
| CPU | AMD Ryzen 9 7950X / Intel i9-14900K | $550 |
| Motherboard | ASUS Pro WS TRX50 / Gigabyte Z790 Aorus | $400 |
| RAM | 64 GB (2×32) DDR5-6000 | $200 |
| GPU 1 | NVIDIA RTX 4090 24GB | $1,600 |
| GPU 2 | NVIDIA RTX 4090 24GB (NVLink bridge optional) | $1,600 |
| Storage | 1 TB NVMe PCIe 4.0 | $100 |
| PSU | 1600W Platinum | $350 |
| Case | Full tower (enough airflow for 2× 450W GPUs) | $150 |
| **Total** | | **~$4,950** |

### Option B: Single Datacenter GPU

| Component | Recommendation | Est. Cost |
|-----------|---------------|-----------|
| Server | Dell R750xa / Supermicro SYS-510T | $3,000 |
| GPU | NVIDIA A100 80GB PCIe | $12,000 |
| RAM | 128 GB DDR5 | $400 |
| Storage | 2 TB NVMe (RAID-1) | $300 |
| **Total** | | **~$15,700** |

> For cloud rental: A100 80GB on runpod.io ~$2.50/hr, Lambda Labs ~$1.50/hr

---

## Setup Steps

### 1. Server Preparation

```bash
# Full OS update
sudo apt update && sudo apt upgrade -y

# NVIDIA drivers + container toolkit
sudo apt install nvidia-driver-550 nvidia-utils-550
sudo apt install nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# Verify GPUs
nvidia-smi topo -m
# Check NVLink: nvidia-smi nvlink --status
```

### 2. Clone & Configure

```bash
git clone https://github.com/nousresearch/hermes-box.git
cd hermes-box

# Environment variables
cat > .env << 'EOF'
WEBUI_SECRET_KEY=$(openssl rand -hex 64)
TELEGRAM_BOT_TOKEN=your:bot_token_here
TS_AUTHKEY=tskey-auth-xxxxxxxxxxxxxxxxxxxx
EOF

chmod 600 .env
source .env
```

### 3. Pre-Pull Models

```bash
# Option A: Qwen 2.5 32B (4-bit quantized — ~18 GB VRAM)
docker run --rm -v ollama_data:/root/.ollama ollama/ollama pull qwen2.5:32b

# Option B: Nemotron Nano (NVIDIA NIM)
# Requires NGC API key: https://build.nvidia.com/explore/
docker login nvcr.io
# Use the NIM container directly — see NIM section below
```

### 4. Start GPU Profile

```bash
docker compose --profile gpu up -d
```

This starts:
- `ollama` (GPU-accelerated inference)
- `open-webui` (Web chat on port 3000)
- `hermes` (Agent orchestration on port 8787)
- `guardrails` (Content filtering on port 8001)
- `tailscale` (VPN)

### 5. Configure Guardrails

Edit `config/guardrails.yaml` for your organization's policies:

```yaml
content_policy:
  enabled: true
  blocked_categories:
    - "prompt_injection"
    - "code_execution_disguised"
    - "pii_leakage"  # Added for business compliance
  action: "block"
  block_message: "This content violates company AI usage policy."

pii:
  enabled: true
  action: "redact"
  patterns:
    - name: "email"
      regex: "..."
      severity: medium
    - name: "phone_us"
      regex: "..."
      severity: medium
    - name: "ssn"
      regex: "..."
      severity: high
    # Add business-specific patterns:
    - name: "employee_id"
      regex: "EMP-[0-9]{6}"
      severity: medium
    - name: "internal_hostname"
      regex: "[a-z]+\\-internal\\.company\\.com"
      severity: low

rate_limiting:
  enabled: true
  requests_per_minute: 500  # Business tier allows more throughput
  burst: 50
```

### 6. (Optional) Use NVIDIA NIM Containers

For higher throughput and enterprise support, replace Ollama with NIM:

```yaml
# docker-compose.override.yml
services:
  # Remove the default ollama (we replace it with NIM)
  nim-llm:
    image: nvcr.io/nim/meta/llama-3.1-8b-instruct:latest
    container_name: hermes-nim
    restart: unless-stopped
    ports:
      - "8000:8000"
    environment:
      - NGC_API_KEY=${NVIDIA_NGC_KEY}
      - MODEL_NAME=nemotron-nano
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 2
              capabilities: [gpu]
    volumes:
      - nim_cache:/model-cache
    profiles: ["gpu", "full"]

volumes:
  nim_cache:
```

### 7. Configure Tailscale for Team Access

In `docker-compose.yml` your Tailscale container already exists. For business:

```yaml
# Add to docker-compose.override.yml
services:
  tailscale:
    environment:
      - TS_AUTHKEY=${TS_AUTHKEY}
      - TS_HOSTNAME=hermes-business
      - TS_SERVE_PORT=3000
      - TS_EXTRA_ARGS=--advertise-tags=tag:hermes
    labels:
      - "tailscale.funnel=false"  # Don't expose publicly
```

Then in the Tailscale admin console:
1. Create an ACL tag `tag:hermes`
2. Create [ACL rules](https://tailscale.com/kb/1018/acls/) to control who can access:

```json
{
  "tagOwners": { "tag:hermes": ["admin@company.com"] },
  "acls": [
    { "action": "accept", "src": ["group:engineering"], "dst": ["tag:hermes:3000"] },
    { "action": "accept", "src": ["group:it"], "dst": ["tag:hermes:*"] }
  ]
}
```

### 8. Verify

```bash
# Health check
./scripts/health-check.sh

# Manual checks
curl -sf http://localhost:3000 && echo "✓ Web UI"
curl -sf http://localhost:11434/api/tags && echo "✓ Ollama models"
curl -sf http://localhost:8001/health && echo "✓ Guardrails"
curl -sf http://localhost:8787 && echo "✓ Hermes"

# GPU utilization
nvidia-smi
watch -n1 nvidia-smi
```

---

## Expected Performance

### Dual RTX 4090 — Qwen 2.5 32B (4-bit)

| Metric | Value |
|--------|-------|
| Prompt processing | ~5,000 tokens/sec |
| Text generation | ~80–100 tokens/sec |
| Concurrent users | 4–6 (intelligent queuing) |
| Context window | 32K tokens |
| First token latency | ~300 ms |
| Model split | 1 GPU for model, 1 for batch |

### A100 80GB — Nemotron Nano (FP16)

| Metric | Value |
|--------|-------|
| Prompt processing | ~8,000 tokens/sec |
| Text generation | ~120–160 tokens/sec |
| Concurrent users | 8–12 |
| Context window | 128K tokens |
| First token latency | ~200 ms |

---

## Cost Estimate

### Year 1 (Dual RTX 4090)

| Item | One-Time | Monthly |
|------|----------|---------|
| Hardware | $4,950 | — |
| Electricity (300W idle, 900W load, 10h/day) | — | $60–$100 |
| Internet (business fiber, static IP) | — | $100–$200 |
| Tailscale Business (up to 100 users) | — | $30 |
| Backups (offsite S3/B2, ~50 GB) | — | $5–$10 |
| Domain + TLS (wildcard cert) | $80/yr | ~$7 |
| Maintenance (10% hardware/year) | — | ~$40 |
| **Total** | **~$5,030** | **~$242–$387/mo** |
| **Year 1 Total** | | **~$8,000–$9,700** |

### Year 1 (A100 80GB — purchased)

| Item | One-Time | Monthly |
|------|----------|---------|
| Hardware (A100 + server) | $15,700 | — |
| Electricity (450W load 24/7) | — | $120–$170 |
| Rest (same as above) | — | ~$177–$277 |
| **Total** | **~$15,700** | **~$300–$450/mo** |
| **Year 1 Total** | | **~$19,300–$21,100** |

### Cloud Rental (A100 80GB — runpod.io)

| Item | Cost |
|------|------|
| GPU instance (24/7) | ~$1,800/mo |
| Storage (500 GB persistent) | ~$20/mo |
| **Total** | **~$1,820/mo** |

---

## Business-Specific Configurations

### Multi-Tenant Isolation

For departments that need separate data stores:

```yaml
# docker-compose.override.yml
services:
  open-webui:
    volumes:
      - webui_engineering:/app/backend/data:ro
    environment:
      - WEBUI_AUTH_REQUIRED=true
      - WEBUI_DEFAULT_USER_ROLE=pending  # Admin must approve
```

### RAG Pipeline

Add a local embedding model for document search:

```bash
docker exec hermes-ollama pull nomic-embed-text:v1
```

Then in Open WebUI, enable RAG under **Admin Settings → Documents** and upload company policies, wikis, and knowledge base files.

### Audit Logging

```yaml
# config/hermes.yaml
logging:
  level: "info"
  format: "json"
  audit_log: /var/lib/hermes/audit.log  # All agent interactions logged

# config/guardrails.yaml
logging:
  log_all_requests: true
  log_blocked_requests: true
  log_redacted_fields: true
  audit_file: /var/lib/guardrails/audit.log
  retention_days: 90  # Compliance requirement
```

---

## Limitations of This Tier

- ⚠️ No high-availability / failover (single host)
- ⚠️ No SSO integration (use Tailscale ACLs as workaround)
- ⚠️ No dedicated monitoring dashboard (add Prometheus/Grafana manually)
- ⚠️ Manual backups required for volumes
- ⚠️ GPU fallback: if the GPU fails, model won't load (CPU fallback requires config change)

---

## Upgrade Path to Enterprise

1. Add a second server for HA → cluster the stack
2. Switch from Ollama to NVIDIA NIM with Nemotron Super 120B
3. Add Prometheus + Grafana + Loki for observability
4. Implement SSO (Keycloak / Azure AD) behind Traefik reverse proxy
5. Add dedicated vector database (Qdrant/Weaviate) for production RAG
