# Прямые провайдеры z.ai и DeepSeek

Решение владельца 08.11.2026: подключить оба, как резерв той же модели.

## Why
Сейчас весь облачный доступ идёт через один аккаунт OpenRouter. Заблокируют его или не пройдёт
оплата — у шлюза не останется ни одной облачной модели. z.ai и DeepSeek — два отдельных
аккаунта у самих авторов моделей, в другой юрисдикции, чем OpenRouter.

## What Changes
- Алиасы `glm-coder-zai` (`zai/glm-5.3-flash`) и `deepseek-coder-direct`
  (`deepseek/deepseek-v4-flash`) в `litellm/config.yaml`, ключи `ZAI_API_KEY`
  и `DEEPSEEK_API_KEY` в `.env`.
- Платная цепочка — та же модель у другого провайдера, в конце локальная:
  `glm-coder-cloud` → `glm-coder-zai` → `gpt-oss-coder-local`,
  `deepseek-coder-cloud` → `deepseek-coder-direct` → `gpt-oss-coder-local`.
  Перекрёстный fallback GLM ↔ DeepSeek убирается.
- Алиас с пустым ключом в `.env` выпадает: шлюз стартует с отфильтрованным конфигом
  `build/litellm/config.yaml`, `sync-agents.py` не показывает его в OpenCode.
  Так же уже работает с MCP-серверами.

## Out of scope
- Регистрация, пополнение счёта и получение ключей — делает владелец.
- Подписка z.ai GLM Coding Plan и её Anthropic-совместимый вход для Claude Code.

## Impact
`litellm/config.yaml`, `.env.example`, `scripts/gateway.sh`, `scripts/sync-agents.py`,
`README.md`, дельта `model-gateway`. Звено `gpt-oss-coder-local` приходит из `add-local-models`:
до него цепочки кончаются на прямом провайдере.
