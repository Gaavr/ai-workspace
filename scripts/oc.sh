#!/usr/bin/env bash
# OpenCode без Docker: ключи из .env, конфиг, агенты и скиллы из ~/.config/opencode.
# Аргументы уходят в opencode как есть: oc.sh, oc.sh ~/Projects/Apps/grams, oc.sh run "..."
set -euo pipefail

ROOT="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"

set -a
# shellcheck disable=SC1091
. "$ROOT/.env"
set +a

exec opencode "$@"
