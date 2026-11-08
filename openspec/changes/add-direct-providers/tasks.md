# Tasks

## 1. Владелец
- [ ] 1.1 Аккаунт z.ai (международный), пополнение, ключ в `.env` как `ZAI_API_KEY`.
- [ ] 1.2 Аккаунт DeepSeek, пополнение, ключ в `.env` как `DEEPSEEK_API_KEY`.

## 2. Шлюз
- [ ] 2.1 `.env.example`: `ZAI_API_KEY`, `DEEPSEEK_API_KEY` вместо закомментированных заготовок.
- [ ] 2.2 `litellm/config.yaml`: алиасы `glm-coder-zai`, `deepseek-coder-direct` с `model_info`;
      цепочки «та же модель у другого провайдера → локальная», без перекрёстного GLM ↔ DeepSeek.
- [ ] 2.3 `scripts/gateway-config.py`: фильтр алиасов с пустыми ключами и их ссылок
      в `fallbacks`, вывод в `build/litellm/config.yaml`.
- [ ] 2.4 `gateway.sh start` — через фильтр; печать пропущенных алиасов.
- [ ] 2.5 `sync-agents.py`: то же правило для списка `gateway` в OpenCode.

## 3. Проверка
- [ ] 3.1 `openspec validate add-direct-providers --strict`.
- [ ] 3.2 Без ключей: прямых алиасов нет в шлюзе и в `oc.sh models gateway`, цепочки целы.
- [ ] 3.3 С ключами: оба алиаса отвечают; сверить имена моделей с `/models` провайдера.
- [ ] 3.4 Fallback на временном шлюзе: `glm-coder-cloud` с битым ключом OpenRouter → `glm-coder-zai`.
- [ ] 3.5 README: прямые провайдеры и правило про пустые ключи.
