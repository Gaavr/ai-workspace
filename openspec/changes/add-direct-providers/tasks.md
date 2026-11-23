# Tasks

## 1. Владелец
- [ ] 1.1 Аккаунт z.ai (международный), пополнение, ключ в `.env` как `ZAI_API_KEY`.
- [ ] 1.2 Аккаунт DeepSeek, пополнение, ключ в `.env` как `DEEPSEEK_API_KEY`.

## 2. Шлюз
- [x] 2.1 `.env.example`: `ZAI_API_KEY`, `DEEPSEEK_API_KEY`.
- [x] 2.2 `litellm/config.yaml`: записи `direct/zai/glm-5.3-flash`, `direct/deepseek/deepseek-v4-flash`
      с `model_info`; цепочки `z-ai/glm-5.3-flash` и `deepseek/deepseek-v4-flash`
      → прямая запись → `ollama/gpt-oss-20b-ssd`.
- [x] 2.3 `scripts/gateway-config.py`: фильтр записей с пустыми ключами и ссылок на них
      в `fallbacks`, вывод в `build/litellm/config.yaml`.
- [x] 2.4 `gateway.sh start` — через фильтр; печать пропущенных записей.
- [x] 2.5 `sync-agents.py`: то же правило для списка `gateway` в OpenCode.

## 3. Проверка
- [x] 3.1 `openspec validate add-direct-providers --strict`.
- [x] 3.2 Без ключей: записей `direct/…` нет в шлюзе и в `oc.sh models gateway`,
      цепочки `z-ai/glm-5.3-flash` и `deepseek/deepseek-v4-flash` идут на локальную модель.
- [ ] 3.3 С ключами: обе прямые записи отвечают; сверить ID и лимиты с `/models` провайдера.
- [ ] 3.4 Fallback на временном шлюзе: `z-ai/glm-5.3-flash` с битым ключом OpenRouter
      → `direct/zai/glm-5.3-flash`.
- [x] 3.5 README: прямые провайдеры, имена `direct/…`, правило про пустые ключи.
