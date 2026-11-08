#!/usr/bin/env bash
# Офлайн-комплект на внешнем SSD: всё, чтобы поднять окружение без npm, PyPI и GitHub.
#   kit.sh refresh               пересобрать то, у чего сменилась версия, и переписать MANIFEST
#   kit.sh check                 сверить файлы комплекта с MANIFEST
#   kit.sh install-litellm DIR   поставить LiteLLM в venv DIR только из комплекта, без сети
#   kit.sh has-litellm           есть ли LiteLLM в комплекте (код выхода)
# Путь к комплекту — AI_KIT (по умолчанию на SSD), как в ollama.sh.
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
MANIFEST="$AI_KIT/MANIFEST"

UV_VENV="$ROOT/build/uv-venv"
LITELLM_VENV="$ROOT/build/litellm-venv"

say() { printf '%s\n' "$*"; }
die() { printf '%s\n' "$*" >&2; exit 1; }

need_kit() { [ -d "$AI_KIT" ] || die "Нет комплекта: $AI_KIT (SSD подключён?)"; }

# Версия компонента из прошлого MANIFEST: строка «# version <имя> <значение>».
old_version() { [ -f "$MANIFEST" ] && awk -v n="$1" '$1=="#" && $2=="version" && $3==n {print $4}' "$MANIFEST" || true; }

# --- текущие версии ---

v_opencode() { opencode --version 2>/dev/null | tail -1; }
v_uv() { "$UV_VENV/bin/uv" --version | awk '{print $2}'; }
v_python() { "$LITELLM_VENV/bin/python" -c 'import platform; print(platform.python_version())'; }
v_litellm() { "$LITELLM_VENV/bin/python" -c 'import importlib.metadata as m; print(m.version("litellm"))'; }
v_repo() { git -C "$ROOT" rev-parse --short HEAD; }
v_ollama() { find "$AI_KIT/runtime/ollama" -maxdepth 1 -name 'v*' -type d 2>/dev/null | sort -V | tail -1 | xargs -I{} basename {}; }

# --- сборка компонентов ---

build_opencode() {
  local v="$1" dir="$AI_KIT/opencode"
  local pkg bin
  pkg="$(npm root -g)/opencode-ai"
  bin="$pkg/node_modules/opencode-darwin-arm64/bin/opencode"
  [ -x "$bin" ] || die "Не нашёл бинарник OpenCode: $bin"
  rm -rf "$dir" && mkdir -p "$dir/bin"
  npm pack --silent "opencode-ai@$v" "opencode-darwin-arm64@$v" --pack-destination "$dir" >/dev/null
  cp "$bin" "$dir/bin/opencode"
}

build_uv() {
  local v="$1" dir="$AI_KIT/python/uv"
  rm -rf "$dir" && mkdir -p "$dir"
  "$UV_VENV/bin/pip" download -q --disable-pip-version-check --no-deps --only-binary=:all: --platform macosx_11_0_arm64 "uv==$v" -d "$dir"
}

build_python() {
  local v="$1" dir="$AI_KIT/python/cpython" src
  src="$("$UV_VENV/bin/uv" python dir)/cpython-$v-macos-aarch64-none"
  [ -d "$src" ] || die "Нет сборки Python у uv: $src"
  rm -rf "$dir" && mkdir -p "$dir"
  # Сборки python-build-standalone переносимы: архив разворачивается в любую папку.
  tar -czf "$dir/cpython-$v-macos-aarch64.tar.gz" -C "$(dirname "$src")" "$(basename "$src")"
}

build_litellm() {
  local dir="$AI_KIT/python" pip_venv="$ROOT/build/kit-pip"
  rm -rf "$dir/wheels" && mkdir -p "$dir/wheels"
  "$UV_VENV/bin/uv" pip freeze --python "$LITELLM_VENV/bin/python" 2>/dev/null >"$dir/requirements.lock"
  # pip wheel берёт готовые колёса и собирает те, что есть только исходниками.
  [ -x "$pip_venv/bin/pip" ] || "$UV_VENV/bin/uv" venv -q --seed "$pip_venv" --python "$LITELLM_VENV/bin/python"
  "$pip_venv/bin/pip" wheel -q --disable-pip-version-check --no-deps -r "$dir/requirements.lock" -w "$dir/wheels"
}

build_repo() {
  local dir="$AI_KIT/repo"
  mkdir -p "$dir"
  git -C "$ROOT" bundle create "$dir/ai-workspace.bundle.tmp" --all 2>/dev/null
  mv "$dir/ai-workspace.bundle.tmp" "$dir/ai-workspace.bundle"
}

refresh_one() {
  local name="$1" current="$2" path="$3" old
  old="$(old_version "$name")"
  if [ "$old" = "$current" ] && [ -e "$AI_KIT/$path" ]; then
    say "  $name $current — без изменений"
    return
  fi
  say "  $name ${old:-нет} -> $current"
  "build_$name" "$current"
}

write_manifest() {
  local tmp="$MANIFEST.tmp"
  {
    echo "# ai-workspace-kit, собран scripts/kit.sh refresh $(date +%F)"
    echo "# Проверка: scripts/kit.sh check"
    for line in "$@"; do echo "# version $line"; done
    (cd "$AI_KIT" && find . -type f ! -name MANIFEST ! -name MANIFEST.tmp ! -name '.DS_Store' ! -name '._*' \
      | sed 's|^\./||' | LC_ALL=C sort | while IFS= read -r f; do shasum -a 256 "$f"; done)
  } >"$tmp"
  mv "$tmp" "$MANIFEST"
}

refresh() {
  need_kit
  [ -x "$LITELLM_VENV/bin/python" ] || die "Нет build/litellm-venv: сначала scripts/gateway.sh start"
  local vo vu vp vl vr vol
  vo="$(v_opencode)"; vu="$(v_uv)"; vp="$(v_python)"; vl="$(v_litellm)"; vr="$(v_repo)"; vol="$(v_ollama)"
  say "Комплект: $AI_KIT"
  refresh_one opencode "$vo" "opencode/bin/opencode"
  refresh_one uv "$vu" "python/uv"
  refresh_one python "$vp" "python/cpython/cpython-$vp-macos-aarch64.tar.gz"
  refresh_one litellm "$vl" "python/requirements.lock"
  refresh_one repo "$vr" "repo/ai-workspace.bundle"
  cp "$ROOT/docs/offline-kit.md" "$AI_KIT/README.md"
  say "  MANIFEST: считаю SHA-256"
  write_manifest "opencode $vo" "uv $vu" "python $vp" "litellm $vl" "repo $vr" "ollama ${vol:-нет}"
  say "Готово"
}

check() {
  need_kit
  [ -f "$MANIFEST" ] || die "Нет $MANIFEST: сначала scripts/kit.sh refresh"
  local failed=0 listed actual
  # shasum -c сам называет испорченные и пропавшие файлы.
  if ! (cd "$AI_KIT" && grep -v '^#' "$MANIFEST" | shasum -a 256 -c --quiet - 2>&1); then
    failed=1
  fi
  listed="$(grep -v '^#' "$MANIFEST" | sed 's/^[0-9a-f]*  //' | LC_ALL=C sort)"
  actual="$(cd "$AI_KIT" && find . -type f ! -name MANIFEST ! -name '.DS_Store' ! -name '._*' | sed 's|^\./||' | LC_ALL=C sort)"
  extra="$(comm -13 <(echo "$listed") <(echo "$actual"))"
  if [ -n "$extra" ]; then
    say "Нет в MANIFEST:"; echo "$extra" | sed 's/^/  /'
    failed=1
  fi
  [ "$failed" -eq 0 ] && say "Комплект цел, файлов: $(echo "$listed" | wc -l | tr -d ' ')" || die "Комплект не совпадает с MANIFEST"
}

install_litellm() {
  local venv="${1:?путь к venv}" py_tar py_dir uv_bin
  need_kit
  [ -f "$AI_KIT/python/requirements.lock" ] || die "В комплекте нет LiteLLM"
  # uv — из колеса распаковкой: системный Python для этого не нужен.
  uv_bin="$ROOT/build/uv-bin/uv"
  if [ ! -x "$uv_bin" ]; then
    mkdir -p "$(dirname "$uv_bin")"
    unzip -o -j -q "$(ls "$AI_KIT"/python/uv/*.whl | head -1)" '*.data/scripts/uv' -d "$(dirname "$uv_bin")"
    chmod +x "$uv_bin"
  fi
  py_tar="$(ls "$AI_KIT"/python/cpython/*.tar.gz | head -1)"
  py_dir="$ROOT/build/python/$(basename "$py_tar" .tar.gz)"
  if [ ! -x "$py_dir/bin/python3" ]; then
    mkdir -p "$py_dir"
    tar -xzf "$py_tar" -C "$py_dir" --strip-components 1
  fi
  UV_OFFLINE=1 "$uv_bin" venv -q "$venv" --python "$py_dir/bin/python3"
  UV_OFFLINE=1 VIRTUAL_ENV="$venv" "$uv_bin" pip install -q --no-index \
    --find-links "$AI_KIT/python/wheels" -r "$AI_KIT/python/requirements.lock"
}

case "${1:-}" in
  refresh) refresh ;;
  check) check ;;
  install-litellm) shift; install_litellm "$@" ;;
  has-litellm) [ -f "$AI_KIT/python/requirements.lock" ] && [ -d "$AI_KIT/python/wheels" ] ;;
  *) echo "Использование: $0 refresh|check|install-litellm <venv>|has-litellm" >&2; exit 2 ;;
esac
