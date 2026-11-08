# Офлайн-комплект на внешнем SSD

Решение владельца 08.11.2026: комплект в `Apps/AI/ai-workspace-kit` на SSD, внутри —
установщики рантайма, OpenCode, LiteLLM с Python 3.12 и снимок репо.

## Why
Всё уже стоит, но на новой машине установка зависит от npm, PyPI и GitHub. Закроют любой
из них — поднять окружение не из чего. Комплект на SSD поднимает его без сети.

## What Changes
- `scripts/kit.sh refresh` собирает комплект; `scripts/kit.sh check` сверяет его с `MANIFEST`.
- Внутри `ai-workspace-kit/`:
  - `installers/` — Ollama и LM Studio (кладёт `add-local-models`);
  - `opencode/` — npm-пакеты `opencode-ai` и `opencode-darwin-arm64` той версии, что стоит,
    и сам бинарник `opencode`: он работает без Node;
  - `python/` — колесо `uv`, сборка CPython 3.12 для `uv`, колёса `litellm[proxy]`
    со всеми зависимостями под 3.12 и `requirements.lock`;
  - `repo/ai-workspace.bundle` — `git bundle --all`;
  - `MANIFEST` — версии и SHA-256 каждого файла; `README.md` — как поднять всё с нуля без сети.
- `gateway.sh` ставит LiteLLM из комплекта, если он доступен, иначе из сети.

## Out of scope
- Claude Code и Codex: их отключение — тот самый случай, от которого комплект страхует.
- Зеркало репозиториев с историей и push — `add-repo-mirror`.
- Модели: уже лежат на SSD в `AI Models`.

## Impact
`scripts/kit.sh`, `scripts/gateway.sh`, `README.md`, новая спека `offline-kit`.
