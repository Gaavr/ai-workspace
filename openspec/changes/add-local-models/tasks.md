# Tasks

## 1. Ollama
- [ ] 1.1 Скачать `ollama-darwin.tgz` v0.40.15 (186 МБ) с GitHub releases в
      `ai-workspace-kit/installers/`, сверить SHA-256 с `sha256sum.txt` релиза.
- [ ] 1.2 Распаковать в `ai-workspace-kit/runtime/ollama/v0.40.15/`.
- [ ] 1.3 `scripts/ollama.sh start|stop|status`: `OLLAMA_MODELS` на SSD, порт 11434,
      без тома SSD — предупреждение и выход без ошибки.
- [ ] 1.4 `.env.example`: `AI_SSD`, `AI_KIT`, `OLLAMA_HOST_URL=http://localhost:11434`.
- [ ] 1.5 `gateway.sh start|stop` поднимает и гасит Ollama вместе со шлюзом.

## 2. Модель
- [ ] 2.1 `Modelfile` в `litellm/ollama/gpt-oss-20b.Modelfile`: GGUF с SSD, `num_ctx 16384`.
- [ ] 2.2 `ollama create gpt-oss-20b-ssd`; проверить вызов инструмента напрямую через Ollama.
- [ ] 2.3 Инструменты не вызываются — спросить владельца про `ollama pull gpt-oss:20b` (~13 ГБ).

## 3. Шлюз
- [ ] 3.1 Алиас `gpt-oss-coder-local` с `model_info` (16384 / 4096).
- [ ] 3.2 Все цепочки fallback заканчиваются на `gpt-oss-coder-local`.
- [ ] 3.3 `sync-agents.py`, `gateway/gpt-oss-coder-local` виден в OpenCode.

## 4. LM Studio
- [ ] 4.1 Скачать `LM-Studio-0.4.28-2-arm64.dmg` (573 МБ) в `ai-workspace-kit/installers/`.
- [ ] 4.2 Поставить в `/Applications`; папка моделей — `AI Models` на SSD; без автозапуска при входе
      (настройки в приложении — показать владельцу, где).
- [ ] 4.3 Алиас `gpt-oss-coder-lmstudio` (`LMSTUDIO_HOST_URL`, порт 1234), вне fallback.
- [ ] 4.4 Старые LM Studio 0.3.16, 0.3.35 и Ollama.app 0.6.8 — в корзину.

## 5. Проверка
- [ ] 5.1 `openspec validate add-local-models --strict`.
- [ ] 5.2 `oc.sh run --agent lead -m gateway/gpt-oss-coder-local` — ответ и вызов инструмента.
- [ ] 5.3 Персона `algo-coach` на локальной модели.
- [ ] 5.4 Временный шлюз с мёртвыми бесплатными алиасами → ответ от локальной.
- [ ] 5.5 Без SSD: шлюз стартует, предупреждение про локальные модели.
- [ ] 5.6 LM Studio: ответ через `gpt-oss-coder-lmstudio`, Ollama-модель выгружена.
- [ ] 5.7 README: локальные модели, память, без SSD.
