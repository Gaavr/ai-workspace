#!/usr/bin/env bash
# LiteLLM без Docker: venv в build/, ключи из .env, лог и pid тоже в build/.
#   gateway.sh start | stop | restart | status | logs
# start и stop заодно поднимают и гасят Ollama с внешнего SSD (scripts/ollama.sh).
# Первый start ставит LiteLLM сам: uv из PyPI, через него Python 3.12 и litellm[proxy].
set -euo pipefail

ROOT="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
VENV="$ROOT/build/litellm-venv"
UV_VENV="$ROOT/build/uv-venv"
PID_FILE="$ROOT/build/litellm.pid"
LOG="$ROOT/build/litellm.log"
PORT="${LITELLM_PORT:-4000}"

running() { curl -sf "http://localhost:$PORT/health/liveliness" >/dev/null 2>&1; }

install() {
  [ -x "$VENV/bin/litellm" ] && return
  echo "Ставлю LiteLLM в build/litellm-venv"
  [ -x "$UV_VENV/bin/uv" ] || { python3 -m venv "$UV_VENV" && "$UV_VENV/bin/pip" install -q uv; }
  # Под свежий системный Python у зависимостей LiteLLM нет готовых сборок, uv берёт 3.12 сам.
  "$UV_VENV/bin/uv" venv -q "$VENV" --python 3.12
  VIRTUAL_ENV="$VENV" "$UV_VENV/bin/uv" pip install -q 'litellm[proxy]'
}

start() {
  # Локальная модель — последнее звено всех цепочек: без неё шлюз работает, но без страховки.
  "$ROOT/scripts/ollama.sh" start || echo "Ollama не поднялась, шлюз стартует без локальных моделей" >&2
  if running; then echo "Шлюз уже работает: http://localhost:$PORT"; return; fi
  install
  (
    set -a
    # shellcheck disable=SC1091
    . "$ROOT/.env"
    set +a
    # В старом .env адрес Ollama для контейнера, а шлюз теперь на хосте.
    OLLAMA_HOST_URL="${OLLAMA_HOST_URL:-http://localhost:11434}"
    export OLLAMA_HOST_URL="${OLLAMA_HOST_URL/host.docker.internal/localhost}"
    nohup "$VENV/bin/litellm" --config "$ROOT/litellm/config.yaml" --port "$PORT" >"$LOG" 2>&1 &
    echo $! >"$PID_FILE"
  )
  for _ in $(seq 1 60); do
    running && { echo "Шлюз запущен: http://localhost:$PORT"; return; }
    kill -0 "$(cat "$PID_FILE")" 2>/dev/null || break
    sleep 1
  done
  echo "Шлюз не поднялся, лог: $LOG" >&2
  tail -20 "$LOG" >&2
  exit 1
}

stop_gateway() {
  if [ -f "$PID_FILE" ] && kill "$(cat "$PID_FILE")" 2>/dev/null; then
    # Ждём выхода: иначе restart увидит старый процесс и не перечитает конфиг.
    for _ in $(seq 1 20); do kill -0 "$(cat "$PID_FILE")" 2>/dev/null || break; sleep 0.5; done
    echo "Шлюз остановлен"
  else
    echo "Шлюз не был запущен этим скриптом"
  fi
  rm -f "$PID_FILE"
}

case "${1:-}" in
  start) start ;;
  stop) stop_gateway; "$ROOT/scripts/ollama.sh" stop ;;
  restart) stop_gateway; start ;;
  status)
    "$ROOT/scripts/ollama.sh" status | sed 's/^/Ollama: /' || true
    running && echo "Шлюз: работает, http://localhost:$PORT" || { echo "Шлюз: не запущен"; exit 1; }
    ;;
  logs) tail -f "$LOG" ;;
  *) echo "Использование: $0 start|stop|restart|status|logs" >&2; exit 2 ;;
esac
