# Deployment Guide

Technical deep-dive for production-grade deployment of Hermes-Box — covering hardware requirements, Docker Compose profiles, environment variables, security hardening, and operational best practices.

---

## Hardware Requirements per Tier

### Tier 1: Basic (CPU-Only)

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU | 8 cores x86_64 (e.g., Intel i7, AMD Ryzen 7) | 16 cores (e.g., AMD EPYC, Intel Xeon) |
| RAM | 16 GB | 32 GB |
| Storage | 50 GB SSD | 100 GB NVMe |
| GPU | None | None |
| Network | 100 Mbps | 1 Gbps |

**Reference hardware:** Desktop PC with Ryzen 7, 32 GB RAM, 512 GB NVMe

**Expected performance:** ~5-15 tokens/sec on 3B-8B parameter models (CPU-only). Suitable for light experimentation and single-user use.

### Tier 2: GPU (Consumer)

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU | 8 cores | 12+ cores |
| RAM | 32 GB | 64 GB |
| Storage | 100 GB NVMe | 200 GB NVMe |
| GPU | **NVIDIA RTX 3060** (12 GB VRAM) | NVIDIA RTX 4090 (24 GB VRAM) |
| Network | 1 Gbps | 1 Gbps |

**Reference hardware:** Workstation with RTX 4090, AMD Ryzen 9, 64 GB RAM, 2 TB NVMe

**Expected token throughput (RTX 4090, llama3.1:8b):**
- Prompt processing: ~4,000 tokens/sec
- Text generation: ~80-120 tokens/sec
- Supports 8B models at full context, 70B models with 4-bit quantization

### Tier 3: Enterprise (Datacenter)

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU | 16 cores | 32+ cores (dual-socket Xeon/EPYC) |
| RAM | 128 GB | 256-512 GB |
| Storage | 500 GB NVMe (RAID-1) | 2 TB NVMe (RAID-10) |
| GPU | **NVIDIA A100** (40 GB) | 4× **NVIDIA H100** (80 GB each) |
| Network | 10 Gbps | 25-100 Gbps |
| Redundancy | Single PSU | Dual PSU, UPS |

**Reference hardware:** NVIDIA DGX H100 (8× H100, 2 TB RAM, 30 TB NVMe)

**Expected throughput (H100, llama3.1:70b FP16):**
- Prompt processing: ~12,000 tokens/sec
- Text generation: ~150-200 tokens/sec
- Multi-model serving: 2-4 concurrent 70B models or 1x 405B model with tensor parallelism

### GPU Compatibility Matrix

| GPU | VRAM | Profiles Supported | Model Capacity |
|-----|------|-------------------|----------------|
| RTX 3060 | 12 GB | `gpu`, `full` | Up to 8B (FP16), 13B (4-bit quantized) |
| RTX 3090 | 24 GB | `gpu`, `full` | Up to 13B (FP16), 34B (4-bit) |
| RTX 4090 | 24 GB | `gpu`, `full` | Up to 13B (FP16), 34B (4-bit) |
| A10G | 24 GB | `gpu`, `full` | Up to 13B (FP16), 34B (4-bit) |
| A100 40GB | 40 GB | `gpu`, `full` | Up to 34B (FP16), 70B (4-bit) |
| A100 80GB | 80 GB | `gpu`, `full` | Up to 70B (FP16), 120B (4-bit) |
| H100 | 80 GB | `gpu`, `full` | Up to 70B (FP16), 120B (4-bit) |
| 4× H100 | 320 GB | `full` | 405B (FP16 with TP) |

---

## Docker Compose Profiles

Hermes-Box uses Docker Compose **profiles** to selectively enable services based on your needs.

### Available Profiles

```
basic  ───  open-webui, hermes, tailscale
  │          (CPU-only, no local inference)
  │
gpu  ─────  basic + ollama (GPU) + guardrails
  │          (local LLM with GPU acceleration)
  │
full ────  gpu + dashboard
            (everything, including monitoring)
```

### Usage

```bash
# Start basic profile
docker compose --profile basic up -d

# Start GPU profile
docker compose --profile gpu up -d

# Start full profile
docker compose --profile full up -d
```

### Profile Interactions

Services can belong to multiple profiles. For example, `open-webui` and `hermes` are in all three profiles, while `ollama` (GPU mode) is only in `gpu` and `full`.

| Service | `basic` | `gpu` | `full` |
|---------|:-------:|:-----:|:------:|
| `ollama` | | ✓ | ✓ |
| `open-webui` | ✓ | ✓ | ✓ |
| `hermes` | ✓ | ✓ | ✓ |
| `guardrails` | | ✓ | ✓ |
| `dashboard` | | | ✓ |
| `tailscale` | ✓ | ✓ | ✓ |

---

## Environment Variables

### Core Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `WEBUI_SECRET_KEY` | `change-me-in-production` | **Yes** | Secret key for Open WebUI session encryption. Generate with `openssl rand -hex 64`. Minimum 32 characters. |
| `TELEGRAM_BOT_TOKEN` | (empty) | No | Telegram bot token for agent access via Telegram. Obtain from [@BotFather](https://t.me/botfather). |
| `OPENAI_API_KEY` | (empty) | No | OpenAI API key if using remote models alongside local ones. |

### VPN Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `TS_AUTHKEY` | (empty) | For VPN | Tailscale pre-auth key. Generate from [Tailscale admin console](https://login.tailscale.com/admin/settings/keys). Use an **ephemeral** key for single-use or **reusable** key for persistent nodes. |
| `TS_HOSTNAME` | `hermes-box` | No | Hostname advertised on the Tailscale network. |

### Optional Tuning Variables

These can be added to your `.env` for performance tuning:

```bash
# Ollama
OLLAMA_NUM_PARALLEL=4          # Concurrent model loads (default: 1)
OLLAMA_MAX_LOADED_MODELS=2      # Max models kept in memory (default: 1)
OLLAMA_KEEP_ALIVE=5m            # How long to keep model loaded after use

# Hermes Agent
HERMES_LOG_LEVEL=info           # Log verbosity (debug, info, warn, error)
HERMES_MAX_TOKENS=4096          # Max tokens per agent response

# Guardrails
GUARDRAILS_LOG_LEVEL=info
```

---

## Production Hardening

### 1. Secret Management

```bash
# Generate a strong secret key
openssl rand -hex 64 > /etc/hermes-box/secrets/webui_secret
chmod 600 /etc/hermes-box/secrets/webui_secret

# In .env, reference it
WEBUI_SECRET_KEY=$(cat /etc/hermes-box/secrets/webui_secret)
```

**Never** commit `.env` to version control. The `.gitignore` already excludes it.

### 2. Firewall Rules

Restrict access to only necessary ports. If using Tailscale (recommended), you can drop all public ports:

```bash
# Block all public access to container ports
sudo ufw default deny incoming
sudo ufw allow ssh              # Keep SSH access
sudo ufw allow in on tailscale0  # Allow Tailscale interface
sudo ufw enable
```

If you must expose services to the local network, bind only to the Tailscale interface:

```yaml
# In docker-compose.override.yml (gitignored)
services:
  open-webui:
    ports:
      - "100.64.x.x:3000:8080"  # Tailscale IP only
```

### 3. TLS / HTTPS

For production, terminate TLS at a reverse proxy:

```yaml
# Recommended: Traefik or Caddy as reverse proxy
services:
  traefik:
    image: traefik:v3
    ports:
      - "443:443"
    labels:
      - "traefik.http.routers.webui.rule=Host(`hermes.example.com`)"
      - "traefik.http.routers.webui.tls=true"
      - "traefik.http.routers.webui.tls.certresolver=letsencrypt"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
```

### 4. Resource Limits

Prevent runaway containers from consuming all host resources:

```yaml
# docker-compose.override.yml
services:
  ollama:
    deploy:
      resources:
        limits:
          cpus: "8"
          memory: "32G"
        reservations:
          cpus: "4"
          memory: "16G"
  open-webui:
    deploy:
      resources:
        limits:
          memory: "4G"
  hermes:
    deploy:
      resources:
        limits:
          memory: "2G"
```

### 5. Logging

Configure log rotation to prevent disk filling:

```yaml
# docker-compose.override.yml
services:
  ollama:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

### 6. Read-Only Root Filesystem

For additional security, run containers with read-only root filesystems where possible:

```yaml
services:
  guardrails:
    read_only: true
    tmpfs:
      - /tmp:size=128M
```

---

## Backup Strategy

### What to Back Up

| Data | Volume | Criticality | Frequency |
|------|--------|-------------|-----------|
| Model weights | `ollama_data` | **Low** (re-downloadable) | Monthly (or skip) |
| Chat history & users | `webui_data` | **High** (irreplaceable) | Daily |
| Agent state & logs | `hermes_data` | **Medium** | Daily |
| Guardrails config & logs | `guardrails_data` | **Medium** | Weekly |
| VPN credentials | `tailscale_data` | **High** (tied to auth key) | Before re-auth |
| Environment secrets | `.env` | **Critical** | Manual backup |

### Automated Backup Script

```bash
#!/bin/bash
# /root/hermes-box/scripts/backup.sh

BACKUP_DIR="/backups/hermes-box"
DATE=$(date +%Y-%m-%d_%H%M%S)
mkdir -p "$BACKUP_DIR"

# Backup volumes
for volume in webui_data hermes_data guardrails_data tailscale_data; do
  docker run --rm \
    -v "$volume":/source \
    -v "$BACKUP_DIR":/backup \
    alpine tar czf "/backup/${volume}_${DATE}.tar.gz" -C /source .
done

# Backup configuration files
tar czf "$BACKUP_DIR/config_${DATE}.tar.gz" \
  -C /root/hermes-box config/

# Backup environment (encrypted)
gpg --symmetric --cipher-algo AES256 \
  -o "$BACKUP_DIR/env_${DATE}.gpg" \
  /root/hermes-box/.env

# Keep only last 30 days of backups
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +30 -delete
find "$BACKUP_DIR" -name "*.gpg" -mtime +30 -delete
```

### Restore Procedure

```bash
# Stop services
docker compose --profile full down

# Restore a volume (example: webui_data)
docker run --rm \
  -v webui_data:/target \
  -v /backups/hermes-box:/backup \
  alpine tar xzf "/backup/webui_data_2024-01-01_120000.tar.gz" -C /target

# Restart services
docker compose --profile full up -d
```

### Disaster Recovery Checklist

- [ ] `.env` file backed up (encrypted) off-site
- [ ] `docker compose` config files version-controlled (Git)
- [ ] `tailscale_data` volume backed up before key rotation
- [ ] Test restore at least once per quarter
- [ ] Monitor disk usage on backup volume

---

## Monitoring & Health Checks

Each service has a built-in health check defined in `docker-compose.yml`:

```bash
# Check all container health
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# View logs for troubleshooting
docker logs hermes-ollama -f --tail 50
docker logs hermes-webui -f --tail 50
docker logs hermes-core -f --tail 50
```

### Recommended Monitoring Stack

For production, add Prometheus + Grafana (outside this project scope, but compatible):

```yaml
# docker-compose.override.yml
services:
  prometheus:
    image: prom/prometheus
    ports: ["9090:9090"]
    volumes:
      - ./config/prometheus.yml:/etc/prometheus/prometheus.yml
  grafana:
    image: grafana/grafana
    ports: ["3001:3000"]
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=change-me
```

---

## Upgrading

```bash
cd /root/hermes-box

# Pull latest images
docker compose --profile full pull

# Recreate containers with new images
docker compose --profile full up -d --remove-orphans

# Clean old images
docker image prune -a
```

### Version Pinning

For production, pin specific image tags instead of using `latest`:

```yaml
# docker-compose.override.yml
services:
  ollama:
    image: ollama/ollama:0.3.11
  open-webui:
    image: ghcr.io/open-webui/open-webui:v0.3.8
```

---

## Troubleshooting Common Issues

| Issue | Diagnosis | Resolution |
|-------|-----------|------------|
| **Ollama won't start** | `docker logs hermes-ollama` shows GPU errors | Ensure `nvidia-container-toolkit` is installed: `sudo apt install nvidia-container-toolkit && sudo systemctl restart docker` |
| **Out of memory** | Container exits with code 137 | Reduce model size, add `OLLAMA_NUM_PARALLEL=1`, or increase host RAM |
| **Disk full** | `df -h` shows 100% usage | Run `docker system prune -a --volumes` to clean unused data |
| **VPN not connecting** | `docker logs hermes-vpn` shows auth errors | Regenerate Tailscale auth key and restart: `docker compose restart tailscale` |
| **Web UI slow** | High latency on first request | Model is loading from disk. Set `OLLAMA_KEEP_ALIVE=10m` to keep it in memory |
| **Port conflicts** | `docker compose up` fails with "port already allocated" | Change host port mapping in `docker-compose.override.yml` |
