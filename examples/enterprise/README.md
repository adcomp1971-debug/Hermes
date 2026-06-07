---
title: Enterprise — Hermes-Box Configuration Example
tier: enterprise
audience: 100+ people
difficulty: advanced
estimated_cost: $120,000–$450,000 one-time + $8,000–$25,000/mo ops
hardware: Multi-GPU cluster (4× H100 / 8× A100)
models: Nemotron Super 120B / Llama 3.1 405B
profile: full
created: 2026-06-07
---

# Enterprise Configuration Example

> **100+ users** | High-availability, SSO, audit, multi-GPU cluster, production SLA

This configuration is designed for large organizations requiring a fully redundant, secure, and auditable AI infrastructure. It uses NVIDIA NIM containers with 120B+ models, tensor parallelism across multiple H100/A100 GPUs, SSO integration, and a complete observability stack.

---

## Overview

| Attribute | Value |
|-----------|-------|
| Users | 100+ (unlimited with horizontal scaling) |
| AI Model | Nemotron Super 120B (FP8) / Llama 3.1 405B (FP16 with TP) |
| Inference | NVIDIA NIM containers (Kubernetes-native) |
| Docker Profile | `docker compose --profile full up` |
| Guardrails | Hermes Guardrails + external policy engine (OPA) |
| SSO | Keycloak / Azure AD / Okta via Traefik reverse proxy |
| HA | Active-passive failover across 2+ nodes |
| Audit | Structured JSON logs to Loki + immutable archive |
| Backup | Automated off-site with disaster recovery |
| Monitoring | Prometheus + Grafana + Loki + Alertmanager |

---

## Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                        ENTERPRISE HERMES-BOX CLUSTER                         │
│                                                                              │
│    ┌─────────────────────┐          ┌─────────────────────┐                  │
│    │   Node 1 (Active)   │          │   Node 2 (Standby)   │                 │
│    │                     │  Gluster │                      │                 │
│    │ ┌─────────────────┐ │  ┌───────┤ ┌─────────────────┐  │               │
│    │ │   Traefik LB    │◄├──┤ VIP   ├─┤   Traefik LB    │  │               │
│    │ │   :443 (TLS)    │ │  └───────┤ │   :443 (TLS)    │  │               │
│    │ └────────┬────────┘ │          │ └────────┬────────┘  │               │
│    │          │           │          │          │            │               │
│    │ ┌────────┴────────┐ │          │ ┌────────┴────────┐  │               │
│    │ │   Keycloak SSO  │ │          │ │   Keycloak SSO  │  │               │
│    │ │   :8080/auth    │ │          │ │   :8080/auth    │  │               │
│    │ └────────┬────────┘ │          │ └────────┬────────┘  │               │
│    │          │           │          │          │            │               │
│    │ ┌────────┴────────┐ │          │ ┌────────┴────────┐  │               │
│    │ │  Open WebUI     │ │          │ │  Open WebUI     │  │               │
│    │ │  (multi-tenant) │ │          │ │  (multi-tenant) │  │               │
│    │ └────────┬────────┘ │          │ └────────┬────────┘  │               │
│    │          │           │          │          │            │               │
│    │ ┌────────┴────────┐ │          │ ┌────────┴────────┐  │               │
│    │ │  Hermes Agent   │ │          │ │  Hermes Agent   │  │               │
│    │ │  (orchestrator) │ │          │ │  (orchestrator) │  │               │
│    │ └────────┬────────┘ │          │ └────────┬────────┘  │               │
│    │          │           │          │          │            │               │
│    │ ┌────────┴────────┐ │          │ ┌────────┴────────┐  │               │
│    │ │  Guardrails     │ │          │ │  Guardrails     │  │               │
│    │ │  + OPA Engine   │ │          │ │  + OPA Engine   │  │               │
│    │ └────────┬────────┘ │          │ └────────┬────────┘  │               │
│    │          │           │          │          │            │               │
│    │ ┌────────┴────────┐ │          │ ┌────────┴────────┐  │               │
│    │ │  NIM Inference  │ │          │ │  NIM Inference  │  │               │
│    │ │  Server (gRPC)  │ │          │ │  Server (gRPC)  │  │               │
│    │ └────────┬────────┘ │          │ └────────┬────────┘  │               │
│    └──────────┼──────────┘          └──────────┼──────────┘                  │
│               │                                 │                            │
│    ┌──────────┴─────────────────────────────────┴──────────┐               │
│    │              NVIDIA NIM CLUSTER (GPU Pool)              │               │
│    │                                                        │               │
│    │    ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐            │
│    │    │  H100-1  │  │  H100-2  │  │  H100-3  │  │  H100-4  │            │
│    │    │  80 GB   │  │  80 GB   │  │  80 GB   │  │  80 GB   │            │
│    │    └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘            │
│    │         │              │              │              │                  │
│    │         └──────────────┴──────────────┴──────────────┘                  │
│    │                Tensor Parallelism (NVSwitch)                            │
│    └────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│    ┌──────────────────────────────────────────────────────────────────┐     │
│    │                     OBSERVABILITY STACK                           │     │
│    │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────────────┐  │     │
│    │  │Prometheus│  │  Grafana │  │   Loki   │  │  Alertmanager  │  │     │
│    │  │:9090     │  │  :3001   │  │  :3100   │  │  :9093         │  │     │
│    │  └──────────┘  └──────────┘  └──────────┘  └────────────────┘  │     │
│    └──────────────────────────────────────────────────────────────────┘     │
│                                                                              │
│    ┌──────────────────────────────────────────────────────────────────┐     │
│    │                     STORAGE LAYER (GlusterFS)                     │     │
│    │  ┌──────────────┐  ┌──────────────┐  ┌───────────────────────┐  │     │
│    │  │  NIM Cache   │  │ Volume Data  │  │  Audit Archive (WORM) │  │     │
│    │  │  500 GB NVMe  │  │  2 TB NVMe   │  │  10 TB Cold Storage  │  │     │
│    │  └──────────────┘  └──────────────┘  └───────────────────────┘  │     │
│    └──────────────────────────────────────────────────────────────────┘     │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Hardware Recommendations

### Minimum: 4× H100 80GB Cluster

| Component | Specification | Qty | Est. Cost |
|-----------|--------------|-----|-----------|
| GPU Node | NVIDIA HGX H100 4-GPU baseboard | 1 | $120,000 |
| CPU | Dual AMD EPYC 9654 (96 cores each) | — | Included |
| RAM | 512 GB DDR5 | — | Included |
| Storage | 3.84 TB NVMe (RAID-10) | — | Included |
| Network | NVIDIA ConnectX-7 Dual 100GbE | — | Included |
| **Subtotal** | | | **~$120,000** |

### Recommended: 8× H100 80GB with Redundancy

| Component | Specification | Qty | Est. Cost |
|-----------|--------------|-----|-----------|
| Primary Node | NVIDIA DGX H100 (8× H100, 2 TB RAM) | 1 | $300,000 |
| Standby Node | Dell R760xa + 4× H100 80GB | 1 | $130,000 |
| Shared Storage | Pure Storage //X NVMe + GlusterFS | 1 | $30,000 |
| Networking | Arista 100GbE switch, redundant paths | 1 | $15,000 |
| UPS | APC Smart-UPS 5000VA | 2 | $4,000 |
| **Total** | | | **~$480,000** |

### Cloud Alternative

| Service | Configuration | Est. Monthly |
|---------|--------------|--------------|
| AWS | p5.48xlarge (8× H100) — on-demand | ~$50,000/mo |
| Azure | ND H100 v5 — 1-year reserved | ~$28,000/mo |
| GCP | a3-highgpu-8g — 3-year commitment | ~$22,000/mo |
| Lambda Labs | 8× H100 cluster — reserved | ~$18,000/mo |
| CoreWeave | 8× H100 — spot with persistence | ~$12,000–$15,000/mo |

---

## Setup Steps

### Phase 1: Infrastructure (Day 1–3)

```bash
# ─── Node 1: Primary ───

# 1. Install Ubuntu Server 24.04 LTS
# 2. Install NVIDIA drivers + Fabric Manager (NVLink)
sudo apt install nvidia-driver-550 nvidia-fabricmanager-550
sudo apt install nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# 3. Enable GPU compute isolation
sudo nvidia-smi -pm 1
sudo nvidia-smi -lgc 1500,1980  # Lock GPU clocks for stability

# 4. Install GlusterFS for shared volumes
sudo apt install glusterfs-server
sudo systemctl start glusterd

# 5. Configure storage
sudo mkfs.xfs /dev/nvme1n1
sudo mkdir /data/hermes
sudo mount /dev/nvme1n1 /data/hermes

# 6. Join to Gluster pool (Node 2)
sudo gluster peer probe node2.internal
sudo gluster volume create hermes_vol replica 2 \
  transport tcp \
  node1.internal:/data/hermes \
  node2.internal:/data/hermes

sudo gluster volume start hermes_vol
sudo mount -t glusterfs node1.internal:/hermes_vol /mnt/hermes
```

### Phase 2: NVIDIA NIM Setup (Day 3–5)

```bash
# 1. Create NGC API key: https://build.nvidia.com/explore/
docker login nvcr.io

# 2. Pull NIM containers
# Nemotron Super 120B (FP8 — requires 4× H100)
docker pull nvcr.io/nim/nvidia/nemotron-super-120b:latest

# Nemotron Nano 15B (lightweight — for guardrails/secondary)
docker pull nvcr.io/nim/nvidia/nemotron-nano-8b:latest

# NIM Embedding (for RAG)
docker pull nvcr.io/nim/nvidia/nim-embedding:latest

# 3. Deploy NIM inference server with tensor parallelism
cat > docker-compose.override.yml << 'NIMEOF'
version: "3.9"

services:
  nim-super:
    image: nvcr.io/nim/nvidia/nemotron-super-120b:latest
    container_name: hermes-nim-super
    restart: unless-stopped
    ports:
      - "8000:8000"
    environment:
      - NGC_API_KEY=${NGC_API_KEY}
      - MODEL_NAME=nemotron-super-120b
      - NIM_TENSOR_PARALLEL_GPUS=4
      - NIM_PIPELINE_PARALLEL_GPUS=1
      - NIM_MAX_BATCH_SIZE=64
      - NIM_MAX_INPUT_LENGTH=8192
      - NIM_MAX_OUTPUT_LENGTH=4096
      - NIM_CACHE_DIR=/model-cache
    volumes:
      - nim_cache_super:/model-cache
      - /mnt/hermes/nim/config:/etc/nim:ro
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              device_ids: ["0", "1", "2", "3"]  # Reserve 4 GPUs
              capabilities: [gpu]
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/v1/health/ready"]
      interval: 30s
      timeout: 15s
      retries: 5
    profiles: ["full"]

  nim-embed:
    image: nvcr.io/nim/nvidia/nim-embedding:latest
    container_name: hermes-nim-embed
    restart: unless-stopped
    ports:
      - "8002:8000"
    environment:
      - NGC_API_KEY=${NGC_API_KEY}
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              device_ids: ["4"]
              capabilities: [gpu]
    profiles: ["full"]

volumes:
  nim_cache_super:
NIMEOF
```

### Phase 3: SSO Integration (Day 5–6)

```yaml
# docker-compose.override.yml (additions)

services:
  keycloak:
    image: quay.io/keycloak/keycloak:25.0
    container_name: hermes-sso
    restart: unless-stopped
    command: start --proxy-headers xforwarded
    ports:
      - "8080:8080"
    environment:
      - KC_HOSTNAME=a**th.hermes.company.com
      - KC_HOSTNAME_PORT=443
      - KC_HTTP_ENABLED=***      - KC_DB=postgres
      - KC_DB_URL=jdbc:postgresql://postgres:5432/keycloak
      - KC_DB_USERNAME=keycloak
      - KC_DB_PASSWORD=${KC_DB_PASSWORD}
      - KEYCLOAK_ADMIN=admin
      - KEYCLOAK_ADMIN_PASSWORD=${KEYCLOAK_ADMIN_PASSWORD}
    volumes:
      - /mnt/hermes/keycloak/themes:/opt/keycloak/themes/custom
    depends_on:
      postgres:
        condition: service_healthy
    profiles: ["full"]

  postgres:
    image: postgres:16-alpine
    container_name: hermes-postgres
    restart: unless-stopped
    environment:
      - POSTGRES_DB=keycloak
      - POSTGRES_USER=keycloak
      - POSTGRES_PASSWORD=${KC_DB_PASSWORD}
    volumes:
      - postgres_sso:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U keycloak"]
    profiles: ["full"]

  traefik:
    image: traefik:v3.1
    container_name: hermes-traefik
    restart: unless-stopped
    ports:
      - "443:443"
      - "9090:9090"  # Metrics
    command:
      - "--providers.docker=true"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.letsencrypt.acme.tlschallenge=true"
      - "--certificatesresolvers.letsencrypt.acme.email=admin@company.com"
      - "--certificatesresolvers.letsencrypt.acme.storage=/certs/acme.json"
      - "--metrics.prometheus=true"
      - "--log.level=info"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - traefik_certs:/certs
    labels:
      # Open WebUI behind SSO
      - "traefik.http.routers.webui.rule=Host(`chat.hermes.company.com`)"
      - "traefik.http.routers.webui.tls=true"
      - "traefik.http.routers.webui.tls.certresolver=letsencrypt"
      - "traefik.http.routers.webui.middlewares=sso-auth@docker"
      # Hermes API
      - "traefik.http.routers.hermes.rule=Host(`api.hermes.company.com`)"
      - "traefik.http.routers.hermes.tls=true"
      - "traefik.http.routers.hermes.middlewares=sso-auth@docker"
    profiles: ["full"]

volumes:
  postgres_sso:
  traefik_certs:
```

SSO Configuration Steps:

1. Open Keycloak at `auth.hermes.company.com`
2. Create a realm `hermes-enterprise`
3. Configure SAML/OIDC clients for Open WebUI
4. Map LDAP/Active Directory groups to Keycloak roles
5. Add the middleware to Traefik for token validation

### Phase 4: Monitoring & Observability (Day 6–7)

```yaml
# docker-compose.override.yml (additions)

services:
  prometheus:
    image: prom/prometheus:v2.53
    container_name: hermes-prometheus
    restart: unless-stopped
    ports:
      - "9090:9090"
    command:
      - "--config.file=/etc/prometheus/prometheus.yml"
      - "--storage.tsdb.retention.time=90d"
      - "--storage.tsdb.retention.size=100GB"
    volumes:
      - ./config/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus_data:/prometheus
    profiles: ["full"]

  grafana:
    image: grafana/grafana:11.1
    container_name: hermes-grafana
    restart: unless-stopped
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}
      - GF_INSTALL_PLUGINS=grafana-piechart-panel
      - GF_AUTH_GENERIC_OAUTH_ENABLED=***      - GF_AUTH_GENERIC_OAUTH_NAME=Keycloak
      - GF_AUTH_GENERIC_OAUTH_CLIENT_ID=grafana
      - GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET=${GRAFANA_SSO_SECRET}
      - GF_AUTH_GENERIC_OAUTH_AUTH_URL=https://auth.hermes.company.com/realms/hermes-enterprise/protocol/openid-connect/auth
      - GF_AUTH_GENERIC_OAUTH_TOKEN_URL=https://auth.hermes.company.com/realms/hermes-enterprise/protocol/openid-connect/token
      - GF_AUTH_GENERIC_OAUTH_API_URL=https://auth.hermes.company.com/realms/hermes-enterprise/protocol/openid-connect/userinfo
    volumes:
      - grafana_data:/var/lib/grafana
    profiles: ["full"]

  loki:
    image: grafana/loki:3.0
    container_name: hermes-loki
    restart: unless-stopped
    ports:
      - "3100:3100"
    command: -config.file=/etc/loki/loki.yml
    volumes:
      - ./config/loki.yml:/etc/loki/loki.yml:ro
      - loki_data:/loki
    profiles: ["full"]

  alertmanager:
    image: prom/alertmanager:v0.27
    container_name: hermes-alertmanager
    restart: unless-stopped
    ports:
      - "9093:9093"
    command:
      - "--config.file=/etc/alertmanager/alertmanager.yml"
    volumes:
      - ./config/alertmanager.yml:/etc/alertmanager/alertmanager.yml:ro
    profiles: ["full"]

volumes:
  prometheus_data:
  grafana_data:
  loki_data:
```

### Phase 5: Security Hardening (Day 7–8)

```yaml
# config/guardrails.yaml — Enterprise Edition

rate_limiting:
  enabled: true
  requests_per_minute: 2000
  burst: 200
  window_seconds: 60
  block_status_code: 429
  block_message: "Rate limit exceeded. Contact IT for quota increase."

pii:
  enabled: true
  action: "block"  # Enterprise: block on sight, don't just redact
  patterns:
    - name: "email"
      regex: "..."
      severity: medium
      action: "redact"
    - name: "ssn"
      regex: "..."
      severity: high
      action: "block"
    - name: "credit_card"
      regex: "..."
      severity: high
      action: "block"
    - name: "phi"
      description: "HIPAA protected health information patterns"
      regex: "..."
      severity: critical
      action: "block"

content_policy:
  enabled: true
  blocked_categories:
    - "prompt_injection"
    - "code_execution_disguised"
    - "malicious_url_generation"
    - "hate_speech"
    - "pii_leakage"
    - "intellectual_property_violation"
    - "competitor_analysis"
  action: "block"
  block_message: "This request violates company AI usage policy. Incident logged."

opa_policy:
  enabled: true
  endpoint: "http://opa:8181/v1/data/hermes/allow"
  timeout: 500ms
  cache_ttl: 60s

logging:
  level: "warn"
  log_all_requests: true
  log_blocked_requests: true
  log_redacted_fields: true
  audit_file: /var/lib/guardrails/audit.log
  audit_format: "json"
  retention_days: 365  # Enterprise compliance
  remote_logging:
    enabled: true
    endpoint: "http://loki:3100/loki/api/v1/push"
    batch_size: 1000
    interval: 5s
```

---

## Expected Performance

### 4× H100 — Nemotron Super 120B (FP8)

| Metric | Value |
|--------|-------|
| Prompt processing | ~15,000 tokens/sec |
| Text generation | ~180–250 tokens/sec |
| Concurrent users | 20–40 (intelligent batching) |
| Context window | 128K tokens |
| First token latency | ~150 ms |
| TP throughput | ~400 req/min (peak) |

### 8× H100 — Llama 3.1 405B (FP16 with TP=8)

| Metric | Value |
|--------|-------|
| Prompt processing | ~20,000 tokens/sec |
| Text generation | ~250–350 tokens/sec |
| Concurrent users | 40–80 |
| Context window | 128K tokens |
| First token latency | ~100 ms |
| TP throughput | ~800 req/min (peak) |
| SLA | 99.9% uptime with active-passive failover |

---

## Cost Estimate

### On-Premise — Year 1 (8× H100 + Standby)

| Item | One-Time | Monthly |
|------|----------|---------|
| Primary: NVIDIA DGX H100 (8× H100) | $300,000 | — |
| Standby: Dell R760xa + 4× H100 | $130,000 | — |
| Shared Storage | $30,000 | — |
| Networking (Artica 100GbE switches ×2) | $15,000 | — |
| UPS + PDU | $4,000 | — |
| Rack collocation (power + cooling) | — | $2,000–$4,000 |
| Electricity (8kW avg load × 24/7) | — | $4,000–$6,000 |
| Internet (DIA 1 Gbps × 2) | — | $1,200–$2,000 |
| Engineering time (setup + maintenance) | $20,000 | $5,000 |
| Domain / TLS / DNS | — | $50 |
| Backup storage (AWS S3 Glacier, 5 TB) | — | $100 |
| Monitoring service (Grafana Cloud) | — | $250 |
| **Total** | **~$499,000** | **~$12,600–$17,400/mo** |
| **Year 1 Total** | | **~$650,000–$710,000** |

### Cloud — Monthly Burn Rate

| Service | Configuration | Monthly |
|---------|--------------|---------|
| CoreWeave | 8× H100 reserved + 2× CPU nodes | $14,000–$18,000 |
| Nebius AI | 8× H100 + persistent storage + LB | $16,000–$20,000 |
| Lambda Labs | 8× H100 cluster + attached storage | $18,000 |
| RunPod | 8× H100 community cloud (spot) | $8,000–$12,000 |

---

## Compliance & Audit

### Audit Trail Architecture

```
User Request
  │
  ├──► Traefik (logs HTTP metadata → Loki)
  ├──► Keycloak (logs authentication event → Loki)
  ├──► Guardrails (logs content decisions → Loki + WORM archive)
  │     └── Decision: pass / block / redact
  ├──► Hermes Agent (logs tool calls, reasoning → Loki)
  ├──► NIM (logs inference metadata → Loki)
  └──► Open WebUI (logs session, RAG queries → Loki)
        │
        ▼
   ┌───────────┐
   │   Loki    │──► 30-day hot retention
   └───────────┘
        │
        ▼
   ┌────────────────┐
   │  S3/Glacier    │──► 7-year immutable archive (WORM)
   │  (immutable)   │
   └────────────────┘
```

### Audit Configuration

```yaml
# Sidecar that ships logs to immutable storage
services:
  audit-shipper:
    image: grafana/promtail:3.0
    container_name: hermes-audit-shipper
    volumes:
      - /mnt/hermes/audit:/audit:ro
      - ./config/promtail-audit.yml:/etc/promtail/config.yml:ro
    command:
      - "-config.file=/etc/promtail/config.yml"
    profiles: ["full"]
```

### Compliance Checklist

- [ ] **SOC 2 Type II** — Audit trails, access controls, change management
- [ ] **HIPAA** — All PHI patterns blocked, audit logs immutable (WORM), BAAs with vendors
- [ ] **GDPR** — User data deletion workflows, right to erasure API, data residency controls
- [ ] **FINRA** — Conversations archived for 7+ years with chain-of-custody
- [ ] **ISO 27001** — ISMS integration, RBAC, quarterly access reviews

---

## High-Availability Configuration

### Active-Passive Failover

```yaml
# docker-compose.override.yml on both nodes
services:
  keepalived:
    image: osixia/keepalived:latest
    container_name: hermes-keepalived
    cap_add:
      - NET_ADMIN
    environment:
      - KEEPALIVED_VIRTUAL_IPS=192.168.1.100
      - KEEPALIVED_INTERFACE=eth0
      - KEEPALIVED_PRIORITY=${NODE_PRIORITY}  # 100 on primary, 50 on standby
      - KEEPALIVED_PASSWORD=${KEEPALIVED_PASS}
    network_mode: host
    profiles: ["full"]
```

### Health Check & Auto-Failover

```bash
#!/bin/bash
# /root/hermes-box/scripts/enterprise-health.sh

HEALTH_ENDPOINTS=(
  "http://localhost:3000/health"
  "http://localhost:8000/v1/health/ready"
  "http://localhost:8001/health"
  "http://localhost:8787/"
  "http://localhost:9090/-/healthy"
  "http://localhost:3100/ready"
)

for ep in "${HEALTH_ENDPOINTS[@]}"; do
  if ! curl -sf --max-time 5 "$ep" > /dev/null 2>&1; then
    echo "FAIL: $ep"
    # Notify PagerDuty / OpsGenie
    curl -X POST https://api.pagerduty.com/v2/... -d '{...}'
  fi
done

# Check GPU health
nvidia-smi --query-gpu=index,name,temperature.gpu,utilization.gpu,memory.used,memory.total \
  --format=csv,noheader
```

---

## Full Stack Service Map

| Service | Container | Port | Profile | Purpose |
|---------|-----------|------|---------|---------|
| NIM Super | hermes-nim-super | 8000 | full | Primary 120B inference (TP=4) |
| NIM Embed | hermes-nim-embed | 8002 | full | Embedding generation for RAG |
| Traefik | hermes-traefik | 443 | full | TLS termination + reverse proxy |
| Keycloak | hermes-sso | 8080 | full | SSO / OIDC / SAML provider |
| PostgreSQL | hermes-postgres | 5432 | full | Keycloak database |
| Guardrails | hermes-guardrails | 8001 | full | Content policy + audit |
| Hermes Agent | hermes-core | 8787 | full | Agent orchestration |
| Open WebUI | hermes-webui | 3000 | full | Multi-tenant chat interface |
| Ollama | hermes-ollama | 11434 | full | Fallback / secondary inference |
| Dashboard | hermes-dashboard | 9119 | full | Monitoring overview |
| Tailscale | hermes-vpn | — | full | Secure mesh VPN |
| Prometheus | hermes-prometheus | 9090 | full | Metrics collection |
| Grafana | hermes-grafana | 3001 | full | Visualization |
| Loki | hermes-loki | 3100 | full | Log aggregation |
| Alertmanager | hermes-alertmanager | 9093 | full | Alert routing |
| Keepalived | hermes-keepalived | — | full | Virtual IP failover |
| OPA | hermes-opa | 8181 | full | External policy engine |
| MinIO | hermes-minio | 9000 | full | S3-compatible audit archive |
| Qdrant | hermes-qdrant | 6333 | full | Vector DB for production RAG |

---

## Operational Runbook

### Daily Operations

```bash
# Check cluster health
ssh hermes-primary
docker ps --format "table {{.Names}}\t{{.Status}}"
kubectl get pods -n hermes  # If using Kubernetes

# Check GPU health
nvidia-smi -q -d TEMPERATURE,UTILIZATION

# View audit log stream
docker logs hermes-guardrails -f --tail 100

# Check model serving metrics
curl -s http://localhost:8000/v1/metrics | grep 'nim_request_'

# Verify replication
gluster volume status hermes_vol
```

### Incident Response

| Incident | Response |
|----------|----------|
| GPU failure | `nvidia-smi -r` to reset, check PCIe reseat, trigger standby failover |
| OOM on model | Restart NIM container: `docker restart hermes-nim-super` |
| NIM slow inference | `curl localhost:8001/v1/health/queue` — check batch queue depth |
| Disk 90%+ full | `docker system prune -a --volumes`, then `gluster volume rebalance` |
| Full failover | `ssh standby && docker compose --profile full up -d` (keepalived auto-switches VIP) |
| Security incident | Lock down: `docker pause hermes-guardrails` then review immutable audit log |

---

## Recommended For

- **Healthcare** — HIPAA-compliant clinical decision support, medical record summarization
- **Finance** — FINRA-compliant trading desk assistant, compliance reporting
- **Legal** — Contract analysis, discovery document processing, privileged communication
- **Government** — Air-gapped deployments, classified data handling, FIPS 140-2 compliance
- **Large Enterprises** — Multi-department AI with RBAC, audit, and chargeback
- **AI Labs** — Research clusters needing heavy inference for evaluation and fine-tuning

---

> **Next steps:** See `docs/deployment.md` in the root of the project for the full deployment guide, and `ARCHITECTURE.md` for the system design.
