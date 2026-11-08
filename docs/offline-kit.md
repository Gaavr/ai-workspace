# ai-workspace-kit

Офлайн-комплект ai-workspace: поднять всё на чистом Mac на Apple Silicon без npm, PyPI
и GitHub. Собирает и проверяет `scripts/kit.sh` из репо, источник этого файла —
`docs/offline-kit.md`.

## Что внутри

| Папка | Что | Зачем |
|---|---|---|
| `repo/ai-workspace.bundle` | git bundle со всеми ветками | сам репо |
| `opencode/bin/opencode` | бинарник OpenCode | работает без Node |
| `opencode/*.tgz` | npm-пакеты `opencode-ai` и `opencode-darwin-arm64` | если Node есть |
| `python/uv/` | колесо `uv` | ставит LiteLLM |
| `python/cpython/` | Python 3.12, сборка python-build-standalone | под LiteLLM |
| `python/wheels/`, `python/requirements.lock` | LiteLLM со всеми зависимостями | шлюз |
| `runtime/ollama/` | распакованная Ollama | локальные модели, запускается отсюда |
| `installers/` | архив Ollama, установщик LM Studio | на будущее |
| `MANIFEST` | версии и SHA-256 каждого файла | проверка |

Модели лежат рядом, в `AI Models/` на том же SSD. Только macOS 14+ на Apple Silicon.

## Поднять с нуля без сети

Путь к комплекту ниже — `$KIT`:

```bash
KIT="/Volumes/Samsung T7 Shield/Apps/AI/ai-workspace-kit"
```

1. Репо:
   ```bash
   mkdir -p ~/Projects/ai
   git clone "$KIT/repo/ai-workspace.bundle" ~/Projects/ai/ai-workspace
   cd ~/Projects/ai/ai-workspace
   ```
2. Ключи: `cp .env.example .env` и заполнить ключи провайдеров из менеджера паролей.
3. OpenCode:
   ```bash
   mkdir -p ~/.local/bin && cp "$KIT/opencode/bin/opencode" ~/.local/bin/
   export PATH="$HOME/.local/bin:$PATH"
   ```
4. Шлюз и Ollama. LiteLLM ставится из комплекта сам, без сети:
   ```bash
   scripts/gateway.sh start
   ```
5. Скилы, агенты, персоны, конфиг OpenCode. Без системного Python — тем, что поставил шлюз:
   ```bash
   build/python/*/bin/python3 scripts/sync-agents.py
   ```
6. Работа:
   ```bash
   scripts/oc.sh
   ```
   Без интернета модель одна — `gateway/gpt-oss-coder-local`, на неё и упадёт любая цепочка.

## Обновить и проверить

```bash
scripts/kit.sh refresh   # после обновления OpenCode, LiteLLM, Python или новых коммитов
scripts/kit.sh check     # сверить файлы с MANIFEST
```

`refresh` пересобирает только то, у чего сменилась версия. Ollama и LM Studio он не качает:
их версии меняются вручную, в `installers/` и `runtime/ollama/<версия>/`.
