#!/usr/bin/env bash
set -euo pipefail

echo "🤖 Hermes Box setup"

# ─── .env ───────────────────────────────────────────
if [ ! -f .env ]; then
  cp .env.example .env
  echo "Created .env from template."
fi

# Force a real secret — never leave the change-me default.
if ! grep -q '^WEBUI_SECRET_KEY=.\+' .env || grep -q 'change-me' .env; then
  SECRET="$(openssl rand -hex 32)"
  # portable in-place edit (works on GNU and BSD sed)
  if sed --version >/dev/null 2>&1; then
    sed -i "s|^WEBUI_SECRET_KEY=.*|WEBUI_SECRET_KEY=${SECRET}|" .env
  else
    sed -i '' "s|^WEBUI_SECRET_KEY=.*|WEBUI_SECRET_KEY=${SECRET}|" .env
  fi
  echo "Generated WEBUI_SECRET_KEY."
fi

# ─── GPU detection → pick profile ──────────────────
PROFILE="basic"
if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1; then
  PROFILE="gpu"
  echo "NVIDIA GPU detected → profile: gpu"
else
  echo "No GPU detected → profile: basic (CPU inference, slower)"
fi

# ─── Build + launch ────────────────────────────────
echo "Building images..."
docker compose --profile "$PROFILE" build

echo "Starting stack..."
docker compose --profile "$PROFILE" up -d

cat <<EOF

✅ Hermes Box is starting.

Next steps:
  1. Pull a model:    docker exec hermes-ollama ollama pull qwen2.5:7b
  2. Pull embeddings: docker exec hermes-ollama ollama pull nomic-embed-text
  3. Drop documents into ./documents/ then:  curl -X POST http://localhost:8002/ingest
  4. Open the chat UI: http://localhost:3000

Telegram bot: set TELEGRAM_BOT_TOKEN and ALLOWED_TELEGRAM_IDS in .env, then re-run.
EOF
