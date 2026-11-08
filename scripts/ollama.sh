#!/usr/bin/env bash
# Ollama с внешнего SSD: бинарник из ai-workspace-kit, модели в «AI Models/ollama-models».
#   ollama.sh start | stop | status | <любая команда ollama: list, create, ps, stop <модель>, …>
# Без тома SSD start предупреждает и выходит без ошибки: шлюз работает и без локальных моделей.
set -euo pipefail

ROOT="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"

env_value() {
  (
    set -a
    # shellcheck disable=SC1091
    [ -f "$ROOT/.env" ] && . "$ROOT/.env"
    printf '%s' "${!1:-}"
  )
}

AI_SSD="${AI_SSD:-$(env_value AI_SSD)}"
AI_SSD="${AI_SSD:-/Volumes/Samsung T7 Shield}"
AI_KIT="${AI_KIT:-$(env_value AI_KIT)}"
AI_KIT="${AI_KIT:-$AI_SSD/Apps/AI/ai-workspace-kit}"
export OLLAMA_MODELS="$AI_SSD/AI Models/ollama-models"
export OLLAMA_HOST="127.0.0.1:11434"
PID_FILE="$ROOT/build/ollama.pid"
LOG="$ROOT/build/ollama.log"

running() { curl -sf "http://$OLLAMA_HOST/api/version" >/dev/null 2>&1; }

# Самая свежая распакованная версия в комплекте.
binary() { find "$AI_KIT/runtime/ollama" -maxdepth 2 -name ollama -type f 2>/dev/null | sort -V | tail -1; }

need_ssd() {
  [ -d "$AI_SSD" ] && return
  echo "SSD не подключён ($AI_SSD): локальные модели недоступны" >&2
  return 1
}

start() {
  if running; then echo "Ollama уже работает: http://$OLLAMA_HOST"; return; fi
  need_ssd || return 0
  local bin
  bin="$(binary)"
  if [ -z "$bin" ]; then
    echo "Нет Ollama в $AI_KIT/runtime/ollama: локальные модели недоступны" >&2
    return 0
  fi
  mkdir -p "$ROOT/build" "$OLLAMA_MODELS"
  nohup "$bin" serve >"$LOG" 2>&1 &
  echo $! >"$PID_FILE"
  for _ in $(seq 1 30); do
    running && { echo "Ollama запущена: http://$OLLAMA_HOST"; return; }
    sleep 1
  done
  echo "Ollama не поднялась, лог: $LOG" >&2
  tail -20 "$LOG" >&2
  return 1
}

stop() {
  if [ -f "$PID_FILE" ] && kill "$(cat "$PID_FILE")" 2>/dev/null; then
    # Ждём выхода: иначе restart увидит старый процесс и не перечитает конфиг.
    for _ in $(seq 1 20); do kill -0 "$(cat "$PID_FILE")" 2>/dev/null || break; sleep 0.5; done
    echo "Ollama остановлена"
  else
    echo "Ollama не была запущена этим скриптом"
  fi
  rm -f "$PID_FILE"
}

exec_ollama() {
  need_ssd || exit 1
  local bin
  bin="$(binary)"
  [ -n "$bin" ] || { echo "Нет Ollama в $AI_KIT/runtime/ollama" >&2; exit 1; }
  exec "$bin" "$@"
}

# stop без аргумента гасит сервер, stop <модель> — команда Ollama: выгрузить модель из памяти.
case "${1:-}" in
  start) start ;;
  stop) [ $# -eq 1 ] && stop || exec_ollama "$@" ;;
  status) running && echo "работает: http://$OLLAMA_HOST" || { echo "не запущена"; exit 1; } ;;
  "") echo "Использование: $0 start|stop|status|<команда ollama>" >&2; exit 2 ;;
  *) exec_ollama "$@" ;;
esac
