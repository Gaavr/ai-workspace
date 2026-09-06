#!/usr/bin/env bash
# Бэкап данных Open WebUI. История чатов через git не переносится —
# это единственный способ сохранить её между машинами.
set -euo pipefail

cd "$(dirname "$0")/.."
DEST="${1:-$HOME/Backups/ai-workspace}"
STAMP="$(date +%Y%m%d-%H%M%S)"
mkdir -p "$DEST"

if [ ! -d data/open-webui ]; then
  echo "Нет data/open-webui — нечего сохранять"
  exit 1
fi

tar czf "$DEST/open-webui-$STAMP.tar.gz" \
  --exclude="open-webui/cache" \
  -C data open-webui

SIZE=$(du -h "$DEST/open-webui-$STAMP.tar.gz" | cut -f1)
echo "Сохранено: $DEST/open-webui-$STAMP.tar.gz ($SIZE)"

ls -1t "$DEST"/open-webui-*.tar.gz 2>/dev/null | tail -n +15 | xargs -r rm --
COUNT=$(ls -1 "$DEST"/open-webui-*.tar.gz 2>/dev/null | wc -l | tr -d ' ')
echo "Копий в архиве: $COUNT (храним последние 14)"
