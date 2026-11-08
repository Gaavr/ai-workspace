#!/usr/bin/env bash
# Вторая копия проектов на внешнем SSD: ~/Projects/{Apps,ai,YT} -> CodeProjects/Projects/.
#   sync-projects.sh            синхронизировать
#   sync-projects.sh --dry-run  показать, что изменится
# Рабочие папки целиком, с .git и незакоммиченным. Без секретов и сборочного мусора.
# Удалённое и перезаписанное на Mac не пропадает: уходит в CodeProjects/Projects-deleted/<дата-время>/.
# Старые копии в CodeProjects/ не трогаются.
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
SRC="$HOME/Projects"
FOLDERS=(Apps ai YT)
DEST="$AI_SSD/CodeProjects/Projects"
DELETED="$AI_SSD/CodeProjects/Projects-deleted/$(date +%Y-%m-%d_%H%M%S)"

[ -d "$AI_SSD" ] || { echo "SSD не подключён: $AI_SSD" >&2; exit 1; }

DRY=0
[ "${1:-}" = "--dry-run" ] && DRY=1

sources=()
for folder in "${FOLDERS[@]}"; do
  [ -d "$SRC/$folder" ] && sources+=("$SRC/$folder") || echo "Нет $SRC/$folder, пропускаю" >&2
done

# Порядок фильтров важен: .env.example включается раньше, чем исключаются .env.*.
FILTERS=(
  --include='.env.example'
  --exclude='.env' --exclude='.env.*'
  --exclude='mcpo/config.json'
  --exclude='*.p8' --exclude='*.p12' --exclude='*.pem' --exclude='*.key' --exclude='*.mobileprovision'
  --exclude='DerivedData/' --exclude='build/' --exclude='.build/' --exclude='node_modules/'
  --exclude='.claude/worktrees/' --exclude='.DS_Store'
)

[ "$DRY" -eq 0 ] && mkdir -p "$DEST"

# 1. Удалённое на Mac. openrsync с --delete и --backup вместе не удаляет ничего, поэтому список
# удалений берётся из пробного прогона, а файлы переносятся в $DELETED вручную.
# rsync перечисляет содержимое раньше папки, так что к папке она уже почти пуста.
moved=0
while IFS= read -r rel; do
  [ -n "$rel" ] || continue
  rel="${rel%/}"
  src="$DEST/$rel"
  [ -e "$src" ] || [ -L "$src" ] || continue
  if [ "$DRY" -eq 1 ]; then echo "удалится: $rel"; continue; fi
  dst="$DELETED/$rel"
  mkdir -p "$(dirname "$dst")"
  if [ -d "$src" ] && [ ! -L "$src" ] && [ -e "$dst" ]; then
    # Папка, чьи файлы уже перенесены: доносим остаток (например, исключённые .DS_Store).
    ditto "$src" "$dst" && find "$src" -depth -delete
  else
    mv "$src" "$dst"
  fi
  moved=$((moved + 1))
done < <([ -d "$DEST" ] && rsync -a -n -v --delete "${FILTERS[@]}" "${sources[@]}" "$DEST/" | sed -n 's/^deleting //p')

# 1б. Папки, которых на Mac больше нет, но rsync их не тронул: в них остались исключённые
# файлы (обычно .DS_Store от Finder). find идёт сверху вниз: переехала папка — вложенные уже не найдутся.
while IFS= read -r dir; do
  rel="${dir#"$DEST"/}"
  [ -e "$SRC/$rel" ] || [ ! -d "$dir" ] && continue
  if [ "$DRY" -eq 1 ]; then echo "удалится: $rel/"; continue; fi
  dst="$DELETED/$rel"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ]; then ditto "$dir" "$dst" && find "$dir" -depth -delete; else mv "$dir" "$dst"; fi
  moved=$((moved + 1))
done < <([ -d "$DEST" ] && find "$DEST" -mindepth 2 -name .git -prune -o -type d -print)

# 2. Копирование. Прежние версии перезаписанных файлов --backup кладёт туда же.
if [ "$DRY" -eq 1 ]; then
  rsync -a -n -v "${FILTERS[@]}" "${sources[@]}" "$DEST/"
else
  rsync -a --backup --backup-dir="$DELETED" "${FILTERS[@]}" "${sources[@]}" "$DEST/"
  echo "Копия: $DEST"
  if [ "$moved" -gt 0 ]; then echo "Удалено на Mac, перенесено: $moved"; fi
  if [ -d "$DELETED" ]; then echo "Удалённое и перезаписанное: $DELETED"; fi
fi
