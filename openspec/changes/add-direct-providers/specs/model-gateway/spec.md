## ADDED Requirements

### Requirement: Прямые провайдеры как резерв той же модели
Для каждой платной модели через OpenRouter SHALL быть алиас той же модели напрямую
у её автора: `glm-coder-zai` для GLM, `deepseek-coder-direct` для DeepSeek. Цепочка
fallback платного алиаса SHALL идти на прямой алиас той же модели, затем на локальную модель.

#### Scenario: OpenRouter заблокировал аккаунт
- **GIVEN** в `.env` есть `ZAI_API_KEY`, OpenRouter отвечает 401
- **WHEN** агент уровня `fast` шлёт запрос на `glm-coder-cloud`
- **THEN** ответ приходит от `glm-coder-zai`

#### Scenario: Недоступны оба облачных провайдера
- **GIVEN** OpenRouter и z.ai отвечают ошибкой
- **WHEN** агент шлёт запрос на `glm-coder-cloud`
- **THEN** ответ приходит от локальной модели

### Requirement: Алиас без ключа выпадает
Алиас, у которого в `.env` пуста переменная из `os.environ/…`, SHALL NOT попадать в конфиг,
на котором стартует шлюз, в его цепочки fallback и в список `gateway` в OpenCode.
Шлюз и `sync-agents.py` SHALL печатать пропущенный алиас и пустую переменную.

#### Scenario: Ключ DeepSeek ещё не получен
- **GIVEN** `DEEPSEEK_API_KEY` пуст
- **WHEN** запускаются `gateway.sh start` и `sync-agents.py`
- **THEN** `deepseek-coder-direct` нет ни в шлюзе, ни в OpenCode
- **AND** цепочка `deepseek-coder-cloud` идёт сразу на локальную модель

## MODIFIED Requirements

### Requirement: Fallback не тратит денег без спроса
`router_settings.fallbacks` SHALL переводить бесплатный алиас только на бесплатные
и локальные. Платный алиас SHALL NOT появляться в цепочке бесплатного. Платный алиас
SHALL падать на ту же модель у другого провайдера, а не на другую платную модель.

#### Scenario: Бесплатная модель недоступна
- **GIVEN** модель за `nemotron-coder-cloud-free` отвечает ошибкой
- **WHEN** агент шлёт запрос на этот алиас
- **THEN** ответ приходит от `north-coder-cloud-free`
- **AND** платные алиасы не вызываются

#### Scenario: Платная модель недоступна
- **GIVEN** `glm-coder-cloud` отвечает ошибкой
- **WHEN** агент шлёт запрос на этот алиас
- **THEN** DeepSeek не вызывается, запрос идёт на GLM у другого провайдера
