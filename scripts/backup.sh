#!/usr/bin/env bash
# Бэкап тома Open WebUI. История чатов через git не переносится —
# это единственный способ сохранить её между машинами.
set -euo pipefail

DEST="${1:-$HOME/backups/ai-workspace}"
STAMP="$(date +%Y%m%d-%H%M%S)"
mkdir -p "$DEST"

docker run --rm \
  -v ai-workspace_open-webui-data:/data:ro \
  -v "$DEST":/backup \
  alpine tar czf "/backup/open-webui-$STAMP.tar.gz" -C /data .

echo "Сохранено: $DEST/open-webui-$STAMP.tar.gz"

ls -1t "$DEST"/open-webui-*.tar.gz | tail -n +8 | xargs -r rm --
echo "Оставлено последних 7 копий."
