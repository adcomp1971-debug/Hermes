#!/usr/bin/env bash
#
# hermes-box — AI Infrastructure in a Box
# ==========================================
# One-shot setup script for self-hosted LLM stack (SMB)
# Supports Linux and macOS, CPU and GPU profiles.
#
# Usage:
#   chmod +x setup.sh && ./setup.sh
#
set -euo pipefail

# ─── Colors ────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

info()  { printf "${CYAN}[INFO]${NC}  %s\n" "$*"; }
ok()    { printf "${GREEN}[OK]${NC}    %s\n" "$*"; }
warn()  { printf "${YELLOW}[WARN]${NC}  %s\n" "$*"; }
err()   { printf "${RED}[ERROR]${NC} %s\n" "$*"; }
header(){ printf "\n${BOLD}━━━ %s ━━━${NC}\n" "$*"; }

# ─── Prerequisites ─────────────────────────────────────
header "Checking Prerequisites"

HAS_GPU=false
IS_MACOS=false
ARCH=""

case "$(uname -s)" in
  Linux*)  ARCH="linux" ;;
  Darwin*) ARCH="darwin"; IS_MACOS=true ;;
  *)       err "Unsupported OS: $(uname -s)"; exit 1 ;;
esac

# docker
if command -v docker &>/dev/null; then
  ok "docker found: $(docker --version 2>/dev/null || true)"
else
  err "docker is not installed. Install Docker first: https://docs.docker.com/get-docker/"
  exit 1
fi

# docker compose plugin
COMPOSE_CMD=""
if docker compose version &>/dev/null; then
  COMPOSE_CMD="docker compose"
  ok "docker compose plugin found"
elif docker-compose --version &>/dev/null; then
  COMPOSE_CMD="docker-compose"
  warn "Using legacy docker-compose (consider updating to the plugin)"
else
  err "docker compose (plugin or standalone) not found. Install it: https://docs.docker.com/compose/install/"
  exit 1
fi

# nvidia-smi (optional — GPU detection)
if command -v nvidia-smi &>/dev/null; then
  GPU_INFO=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1 || true)
  if [ -n "$GPU_INFO" ]; then
    HAS_GPU=true
    ok "NVIDIA GPU detected: ${GPU_INFO}"
  fi
else
  warn "nvidia-smi not found — GPU profile will be unavailable"
  warn "Install NVIDIA drivers + CUDA toolkit for GPU support: https://developer.nvidia.com/cuda-downloads"
fi

if [ "$HAS_GPU" = false ]; then
  info "No GPU detected — will use CPU profile"
fi

# ─── Working directory ─────────────────────────────────
header "Setup Location"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
ok "Working in ${SCRIPT_DIR}"

# ─── Environment file ──────────────────────────────────
header "Environment Configuration"

ENV_FILE=".env"
ENV_TEMPLATE=".env.template"

if [ -f "$ENV_FILE" ]; then
  ok "${ENV_FILE} already exists — keeping existing configuration"
else
  if [ -f "$ENV_TEMPLATE" ]; then
    cp "$ENV_TEMPLATE" "$ENV_FILE"
    ok "Created ${ENV_FILE} from template"
  else
    warn "No ${ENV_TEMPLATE} found — creating minimal ${ENV_FILE}"
    cat > "$ENV_FILE" <<-EOF
# hermes-box configuration
# Copy this to .env and fill in your values

# Telegram bot token (required for Telegram gateway)
TELEGRAM_BOT_TOKEN=

# OpenAI API key (optional — only needed if using OpenAI models)
OPENAI_API_KEY=

# Tailscale auth key (optional — enables VPN access)
TS_AUTHKEY=

# WebUI secret key (change in production!)
WEBUI_SECRET_KEY=change-me-in-production
EOF
    ok "Created minimal ${ENV_FILE}"
  fi
fi

# ─── Pull models ───────────────────────────────────────
header "Pulling Models"

MODEL_GPU="qwen2.5:32b"
MODEL_CPU="qwen2.5:7b"

if [ "$HAS_GPU" = true ]; then
  MODEL_TO_PULL="$MODEL_GPU"
  info "GPU available — pulling ${BOLD}${MODEL_GPU}${NC}"
else
  MODEL_TO_PULL="$MODEL_CPU"
  info "CPU mode — pulling ${BOLD}${MODEL_CPU}${NC} (lighter model)"
fi

info "Starting ollama pull (this may take a while depending on your connection)..."
ollama pull "$MODEL_TO_PULL" 2>/dev/null || {
  warn "ollama CLI not found or pull failed. Will pull via container on first start."
  warn "Install ollama separately if you need pre-pulled models: https://ollama.com/download"
}

# ─── Docker Compose Up ─────────────────────────────────
header "Starting Services"

if [ "$HAS_GPU" = true ]; then
  PROFILE="gpu"
  info "Launching with GPU profile: ${BOLD}--profile gpu${NC}"
else
  PROFILE="basic"
  info "Launching with CPU profile: ${BOLD}--profile basic${NC}"
fi

$COMPOSE_CMD --profile "$PROFILE" up -d

# ─── Verify & Show URLs ────────────────────────────────
header "Verifying Services"

sleep 5

declare -A SERVICES
SERVICES[ollama]="http://localhost:11434"
SERVICES[open-webui]="http://localhost:3000"
SERVICES[hermes-core]="http://localhost:8787"

UP_COUNT=0
TOTAL_COUNT=${#SERVICES[@]}

for NAME in "${!SERVICES[@]}"; do
  URL="${SERVICES[$NAME]}"
  if curl -sf --max-time 5 "$URL" &>/dev/null; then
    ok "${NAME} is running at ${URL}"
    ((UP_COUNT++))
  else
    warn "${NAME} might still be starting — check with: docker compose logs ${NAME}"
  fi
done

# ─── Success Message ───────────────────────────────────
header "Setup Complete — hermes-box is running!"

echo ""
printf "  ${BOLD}Service${NC}          ${BOLD}URL${NC}\n"
printf "  ─────────────────────────────────────────\n"
printf "  Ollama API        ${CYAN}http://localhost:11434${NC}\n"
printf "  Open WebUI        ${CYAN}http://localhost:3000${NC}\n"
printf "  Hermes Agent      ${CYAN}http://localhost:8787${NC}\n"
echo ""

if [ "$HAS_GPU" = true ]; then
  printf "  ${GREEN}✓${NC} GPU-accelerated profile (${BOLD}${MODEL_GPU}${NC})\n"
else
  printf "  ${YELLOW}ℹ${NC} CPU profile (${BOLD}${MODEL_CPU}${NC})\n"
  printf "  ${YELLOW}ℹ${NC} Install NVIDIA drivers + re-run for GPU support\n"
fi

if $IS_MACOS; then
  printf "  ${YELLOW}ℹ${NC} macOS detected — GPU profile requires NVIDIA hardware (unlikely on Mac)\n"
fi

echo ""
printf "  ${BOLD}Quick commands:${NC}\n"
printf "    View logs:    ${COMPOSE_CMD} logs -f\n"
printf "    Stop all:     ${COMPOSE_CMD} down\n"
printf "    Restart:      ${COMPOSE_CMD} --profile ${PROFILE} up -d\n"
echo ""

if [ "$UP_COUNT" -lt "$TOTAL_COUNT" ]; then
  warn "${UP_COUNT}/${TOTAL_COUNT} services confirmed running"
  info "Run './scripts/health-check.sh' for a detailed status overview"
else
  ok "All ${TOTAL_COUNT} services are running!"
fi

header "hermes-box is ready. Happy building! 🚀"
