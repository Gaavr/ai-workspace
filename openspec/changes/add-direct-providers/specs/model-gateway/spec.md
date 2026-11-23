## ADDED Requirements

### Requirement: Прямые провайдеры как резерв той же модели
Для платной модели каталога, у автора которой есть свой API, SHALL быть запись той же модели
напрямую под именем `direct/<провайдер>/<ID у провайдера>`: `direct/zai/glm-5.3-flash`
для `z-ai/glm-5.3-flash`, `direct/deepseek/deepseek-v4-flash` для `deepseek/deepseek-v4-flash`.
Цепочка fallback модели каталога SHALL идти на её прямую запись, затем на локальную модель.

#### Scenario: OpenRouter заблокировал аккаунт
- **GIVEN** в `.env` есть `ZAI_API_KEY`, OpenRouter отвечает 401
- **WHEN** агент уровня `fast` шлёт запрос на `z-ai/glm-5.3-flash`
- **THEN** ответ приходит от `direct/zai/glm-5.3-flash`

#### Scenario: Недоступны оба облачных провайдера
- **GIVEN** OpenRouter и z.ai отвечают ошибкой
- **WHEN** агент шлёт запрос на `z-ai/glm-5.3-flash`
- **THEN** ответ приходит от `ollama/gpt-oss-20b-ssd`

#### Scenario: Ключ DeepSeek ещё не получен
- **GIVEN** `DEEPSEEK_API_KEY` пуст
- **WHEN** запускаются `gateway.sh start` и `sync-agents.py`
- **THEN** `direct/deepseek/deepseek-v4-flash` нет ни в шлюзе, ни в OpenCode
- **AND** цепочка `deepseek/deepseek-v4-flash` идёт сразу на `ollama/gpt-oss-20b-ssd`

## MODIFIED Requirements

### Requirement: Бесплатное падает только на бесплатное
`router_settings.fallbacks` SHALL переводить бесплатную модель только на бесплатные
и локальные. Платная модель SHALL NOT появляться в цепочке бесплатной. Платная модель SHALL
падать на ту же модель у другого провайдера или на локальную, а не на другую платную модель.
Цепочка `openrouter/*` SHALL доставаться каждой модели каталога без своей цепочки.

#### Scenario: Бесплатная модель недоступна
- **GIVEN** `nvidia/nemotron-3-ultra-550b-a55b:free` отвечает ошибкой
- **WHEN** агент шлёт запрос на эту модель
- **THEN** ответ приходит от `cohere/north-mini-code:free`
- **AND** платные модели не вызываются

#### Scenario: Модель каталога без своей цепочки
- **GIVEN** у модели каталога нет своей цепочки, и она отвечает ошибкой
- **WHEN** агент шлёт запрос на эту модель
- **THEN** ответ приходит от локальной модели

#### Scenario: Платная модель недоступна
- **GIVEN** `z-ai/glm-5.3-flash` отвечает ошибкой
- **WHEN** агент шлёт запрос на эту модель
- **THEN** DeepSeek не вызывается, запрос идёт на GLM у z.ai или на локальную модель
