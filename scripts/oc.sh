#!/usr/bin/env bash
# OpenCode без Docker: ключи из .env, конфиг и агенты из ~/.config/opencode, скилы из ~/.agents/skills.
# Всё это раскладывает scripts/sync-agents.py.
# Аргументы уходят в opencode как есть: oc.sh, oc.sh ~/Projects/Apps/grams, oc.sh run "..."
#
# В окружение OpenCode попадают только ключи провайдеров моделей (ALLOWED), а не весь .env:
# агент может прочитать своё окружение, и Jira, Open WebUI и прочее ему видеть незачем.
set -euo pipefail

ROOT="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
ALLOWED=(OPENROUTER_API_KEY LITELLM_MASTER_KEY)

for name in "${ALLOWED[@]}"; do
  value="$(
    set -a
    # shellcheck disable=SC1091
    . "$ROOT/.env"
    printf '%s' "${!name:-}"
  )"
  [ -n "$value" ] && export "$name=$value"
done
unset value

exec opencode "$@"
