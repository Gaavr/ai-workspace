# Локальные модели через Ollama

Решения владельца 08.11.2026: рантайм — Ollama, модель для теста — gpt-oss-20b,
всё тяжёлое — только на внешнем SSD. LM Studio сначала решили ставить запасным,
после зависания Mac на загрузке модели — убрали (решение владельца 08.11.2026).

## Why
Последнее звено цепочки моделей должно работать без интернета и без чьего-либо аккаунта.
Пока его нет, отключение OpenRouter оставляет агентов без модели.

## What Changes
- **Ollama** — открытый (MIT), основной локальный рантайм. CLI-сборка
  `ollama-darwin.tgz` v0.40.15 (186 МБ, GitHub releases) лежит на SSD
  в `Apps/AI/ai-workspace-kit/runtime/ollama/` и запускается оттуда. В `/Applications`
  ничего не ставится, автозапуска нет. Хранилище моделей — `AI Models/ollama-models` на SSD (`AI Models/Ollama` — битый ярлык Finder).
- `scripts/ollama.sh start|stop|status`; `gateway.sh start` поднимает Ollama вместе со шлюзом,
  если SSD подключён, `stop` гасит обоих.
- **gpt-oss-20b** импортируется в Ollama из уже лежащего на SSD
  `AI Models/lmstudio-community/gpt-oss-20b-GGUF/gpt-oss-20b-MXFP4.gguf`, без скачивания.
- Алиас `gpt-oss-coder-local` — последнее звено всех цепочек: бесплатных и платных.
- **LM Studio не ставится.** Закрытое приложение, а на 16 ГБ его настройки по умолчанию
  (`mlock`, `--parallel 4`) повесили систему на gpt-oss-20b. Установщик
  `LM-Studio-0.4.28-2-arm64.dmg` (573 МБ) остаётся в комплекте на будущее; приложение,
  `~/.lmstudio`, его настройки и строка `PATH` в `~/.zshrc` убраны, файлы — в корзине.
- Старые установщики на SSD (LM Studio 0.3.16 и 0.3.35, Ollama.app 0.6.8) — в корзину.
  Очищает корзину владелец.

## Out of scope
- Модели крупнее ~12 ГБ: в 16 ГБ не помещаются.
- Второй локальный рантайм. Вернуться к нему — отдельным change-ем, на машине с памятью больше.

## Impact
`scripts/ollama.sh`, `scripts/gateway.sh`, `litellm/config.yaml`, `.env.example`
(`OLLAMA_HOST_URL`, `AI_SSD`, `AI_KIT`), `README.md`, новая спека `local-models`,
дельта `model-gateway`.
