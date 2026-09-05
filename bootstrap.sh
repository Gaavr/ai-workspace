#!/usr/bin/env bash
# Разворот окружения на новой машине.
# Профили: full (48GB+), light (16-32GB), cloud (без локальных моделей)
set -euo pipefail

PROFILE="${1:-full}"
cd "$(dirname "$0")"

say() { printf '\n\033[1m%s\033[0m\n' "$*"; }

say "Профиль: $PROFILE"

# --- .env ---
if [ ! -f .env ]; then
  cp .env.example .env
  say "Создан .env — впиши ключи и запусти снова."
  if command -v openssl >/dev/null; then
    echo "Заготовки:"
    echo "  WEBUI_SECRET_KEY=$(openssl rand -hex 32)"
    echo "  LITELLM_MASTER_KEY=sk-$(openssl rand -hex 24)"
  fi
  exit 1
fi

# --- Ollama: только нативно, Docker на macOS не даёт Metal ---
if [ "$PROFILE" != "cloud" ]; then
  if ! command -v ollama >/dev/null; then
    say "Ставлю Ollama нативно"
    case "$(uname -s)" in
      Darwin) command -v brew >/dev/null && brew install ollama \
                || { echo "Поставь Ollama с ollama.com и запусти снова"; exit 1; } ;;
      Linux)  curl -fsSL https://ollama.com/install.sh | sh ;;
      *)      echo "Поставь Ollama вручную"; exit 1 ;;
    esac
  fi

  pgrep -x ollama >/dev/null || { say "Запускаю Ollama"; ollama serve >/dev/null 2>&1 & sleep 3; }

  say "Тяну модели"
  case "$PROFILE" in
    full)  ollama pull qwen3-coder:30b; ollama pull qwen3:8b ;;
    light) ollama pull qwen3:8b ;;
  esac
fi

# --- Стек ---
say "Поднимаю Open WebUI, LiteLLM, mcpo"
docker compose up -d

say "Жду готовности Open WebUI"
for _ in $(seq 1 30); do
  curl -sf http://localhost:3000/health >/dev/null && break
  sleep 2
done

cat <<EOF

Готово.
  Open WebUI  http://localhost:3000
  LiteLLM     http://localhost:4000
  mcpo        http://localhost:8000

Дальше:
  1. Заведи админский аккаунт в Open WebUI (локальный, не облачный).
  2. Settings -> Account -> API Keys, ключ положи в .env как OPENWEBUI_API_KEY.
  3. ./scripts/sync-personas.py
EOF
