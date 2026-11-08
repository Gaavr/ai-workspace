# Tasks

## 1. Сборка
- [x] 1.1 `scripts/kit.sh` с командами `refresh` и `check`, путь из `AI_KIT`.
- [x] 1.2 OpenCode: `npm pack opencode-ai@<версия>` и `opencode-darwin-arm64@<версия>`, бинарник отдельно.
- [x] 1.3 Python: колесо `uv`, архив CPython 3.12 из `uv python dir`.
- [x] 1.4 LiteLLM: `requirements.lock` из `build/litellm-venv`, колёса под 3.12 arm64.
- [x] 1.5 `git bundle --all` в `repo/ai-workspace.bundle`.
- [x] 1.6 `MANIFEST` (версии, SHA-256) и `README.md` комплекта: подъём с нуля без сети.

## 2. Установка из комплекта
- [x] 2.1 `gateway.sh install`: комплект первым, сеть — без него.

## 3. Проверка
- [x] 3.1 `openspec validate add-offline-kit --strict`.
- [x] 3.2 `kit.sh check` чистый; испорченный файл ловится.
- [x] 3.3 Установка LiteLLM в пустую папку с выключенной сетью для `uv` (`UV_OFFLINE=1`).
- [x] 3.4 OpenCode из комплекта запускается в отдельной папке без Node в `PATH`.
- [x] 3.5 Репо разворачивается из bundle: `git clone repo/ai-workspace.bundle`.
- [x] 3.6 Повторный `kit.sh refresh` без изменений ничего не качает.
- [x] 3.7 README: комплект, когда обновлять.
