# Tasks

## 1. Код (коммит d209d2b)
- [x] 1.1 `litellm/config.yaml`: `openrouter/*` вместо алиасов, `ollama/gpt-oss-20b-ssd`, цепочка `openrouter/*`.
- [x] 1.2 `scripts/openrouter_catalog.py`: каталог из сети, кеш в `build/litellm/openrouter-models.json`.
- [x] 1.3 `scripts/gateway-config.py`: разворот `openrouter/*`, общая цепочка для моделей каталога.
- [x] 1.4 `scripts/sync-agents.py`: каталог в провайдере `gateway` OpenCode и в профилях Codex.
- [x] 1.5 `agents/targets.json`, `prompts/`: ID моделей каталога.
- [x] 1.6 README.

## 2. Спеки
- [x] 2.1 Дельты `model-gateway`, `local-models`, `tool-sync`.
- [x] 2.2 `openspec validate expose-openrouter-catalog --strict`.
