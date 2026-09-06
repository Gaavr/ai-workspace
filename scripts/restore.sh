#!/usr/bin/env bash
# Восстановление данных Open WebUI из архива.
set -euo pipefail

cd "$(dirname "$0")/.."
ARCHIVE="${1:?Укажи путь к .tar.gz}"
[ -f "$ARCHIVE" ] || { echo "Нет файла: $ARCHIVE"; exit 1; }

echo "Восстановить из: $ARCHIVE"
echo "Текущая история чатов будет перезаписана."
read -rp "Продолжить? [y/N] " ok
[ "$ok" = "y" ] || exit 0

docker compose stop open-webui
rm -rf data/open-webui
tar xzf "$ARCHIVE" -C data
docker compose start open-webui

echo "Готово. Обнови вкладку в браузере."
