# Tasks

## 0. Требования
- [x] 0.1 Ответы владельца: уровни `smart`/`fast`, шлюз только для этого Mac, персона на чат.

## 1. Шлюз
- [x] 1.1 `gateway.sh`: LiteLLM на `--host 127.0.0.1`, проверки — на `127.0.0.1`.
- [x] 1.2 `gateway.sh` ставит LiteLLM ключ-заглушку `sk-local-gateway`; ключ из `.env` —
      только LiteLLM из docker-compose.
- [x] 1.3 OpenCode: `apiKey` — заглушка; `oc.sh` без `LITELLM_MASTER_KEY`;
      `.env.example`: `LITELLM_MASTER_KEY` только для Open WebUI в Docker.

## 2. Codex
- [x] 2.1 `sync-agents.py`: провайдер `gateway` в своём блоке `~/.codex/config.toml`.
- [x] 2.2 Профили уровней `smart`, `fast` в `build/codex/profiles/` рядом с персонами,
      ссылки в `~/.codex/`; чужие профили не трогаются; имя уровня, совпавшее с персоной, — ошибка.

## 3. Проверка
- [x] 3.1 `openspec validate add-codex-gateway --strict`.
- [x] 3.2 Порт 4000 слушается только на `127.0.0.1`; запрос по адресу Mac в сети не проходит.
- [x] 3.3 OpenCode через шлюз: агент `lead` отвечает.
- [x] 3.4 `codex exec -p smart` отвечает через шлюз; без переменных `.env` в окружении.
- [ ] 3.5 Codex App видит профили и провайдер — проверяет владелец.
- [x] 3.6 README: Codex через шлюз.
