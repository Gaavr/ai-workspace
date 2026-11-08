# Локальные модели: Ollama и LM Studio

Решения владельца 08.11.2026: оба рантайма, последнее звено fallback — Ollama,
модель для теста — gpt-oss-20b, всё тяжёлое — только на внешнем SSD.

## Why
Последнее звено цепочки моделей должно работать без интернета и без чьего-либо аккаунта.
Пока его нет, отключение OpenRouter оставляет агентов без модели.

## What Changes
- **Ollama** — открытый (MIT), основной локальный рантайм. CLI-сборка
  `ollama-darwin.tgz` v0.40.15 (186 МБ, GitHub releases) лежит на SSD
  в `Apps/AI/ai-workspace-kit/runtime/ollama/` и запускается оттуда. В `/Applications`
  ничего не ставится, автозапуска нет. Хранилище моделей — `AI Models/Ollama` на SSD.
- `scripts/ollama.sh start|stop|status`; `gateway.sh start` поднимает Ollama вместе со шлюзом,
  если SSD подключён, `stop` гасит обоих.
- **gpt-oss-20b** импортируется в Ollama из уже лежащего на SSD
  `AI Models/lmstudio-community/gpt-oss-20b-GGUF/gpt-oss-20b-MXFP4.gguf`, без скачивания.
- Алиас `gpt-oss-coder-local` — последнее звено всех цепочек: бесплатных и платных.
- **LM Studio** — закрытое приложение, поэтому только запасной вариант и не на критическом
  пути. `LM-Studio-0.4.28-2-arm64.dmg` (573 МБ, installers.lmstudio.ai) — в комплект на SSD
  и в `/Applications`. Папка моделей — `AI Models` на SSD как есть, без автозапуска при входе.
  Алиас `gpt-oss-coder-lmstudio`, в fallback не участвует, выбирается через `-m`.
- Старые установщики на SSD (LM Studio 0.3.16 и 0.3.35, Ollama.app 0.6.8) — в корзину.
  Очищает корзину владелец.

## Out of scope
- Модели крупнее ~12 ГБ: в 16 ГБ не помещаются.
- Ollama и LM Studio одновременно с загруженной моделью — не хватит памяти.

## Impact
`scripts/ollama.sh`, `scripts/gateway.sh`, `litellm/config.yaml`, `.env.example`
(`OLLAMA_HOST_URL`, `LMSTUDIO_HOST_URL`), `README.md`, новая спека `local-models`,
дельта `model-gateway`.
