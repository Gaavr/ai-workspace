# Весь каталог OpenRouter вместо алиасов

Задним числом: код сделан в коммите `d209d2b` (13.11.2026), здесь спеки догоняют код.

## Why
Каждая новая модель OpenRouter требовала своего алиаса с ручными лимитами в `litellm/config.yaml`.
Алиасы прятали, какая модель на самом деле отвечает, и устаревали, когда бесплатная модель
пропадала. Каталог OpenRouter уже знает ID, контекст и лимит вывода каждой модели.

## What Changes
- **Своих алиасов нет.** Одна запись `openrouter/*` в `litellm/config.yaml` подключает весь
  каталог. `scripts/gateway-config.py` (шлюз) и `sync-agents.py` (OpenCode, профили Codex)
  разворачивают её по `https://openrouter.ai/api/v1/models`: модель под своим ID, лимиты
  из каталога. Без сети — последний сохранённый список `build/litellm/openrouter-models.json`.
- Локальная модель называется по модели Ollama: `ollama/gpt-oss-20b-ssd`
  (было `gpt-oss-coder-local`).
- Цепочка `openrouter/*` в `fallbacks` достаётся каждой модели каталога без своей цепочки
  и ведёт на локальную модель.
- **BREAKING** Прямые записи z.ai и DeepSeek убраны, вместе с требованием «прямой провайдер
  как резерв той же модели».
- Агенты, персоны (`base:`) и уровни в `agents/targets.json` ссылаются на ID моделей каталога.

## Out of scope
- Судьба незакрытого изменения `add-direct-providers`: оно описано на алиасах и требует
  переделки или закрытия отдельным решением владельца.

## Impact
`litellm/config.yaml`, `scripts/gateway-config.py`, `scripts/openrouter_catalog.py`,
`scripts/sync-agents.py`, `scripts/gateway.sh`, `agents/targets.json`, `prompts/`, README,
дельты `model-gateway`, `local-models`, `tool-sync`.
