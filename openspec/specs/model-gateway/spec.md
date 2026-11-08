# model-gateway Specification

## Purpose
Шлюз LiteLLM — единственное место, где перечислены модели. Инструменты и агенты обращаются
к алиасам, а не к моделям: сменить провайдера или модель — правка одной строки
в `litellm/config.yaml`. Шлюз работает нативно, без Docker.

## Requirements

### Requirement: Алиасы вместо моделей
Каждая модель SHALL быть описана в `litellm/config.yaml` как алиас по схеме
`модель-роль-где[-free]`. Агенты, персоны и уровни в `agents/targets.json` SHALL ссылаться
только на алиасы. Ключи провайдеров SHALL браться из переменных окружения
(`os.environ/…`), значения SHALL NOT попадать в конфиг.

#### Scenario: Модель пропала у провайдера
- **GIVEN** бесплатная модель за алиасом убрана с OpenRouter
- **WHEN** в `litellm/config.yaml` у алиаса меняется `model:` и шлюз перезапускается
- **THEN** агенты и персоны работают на новой модели без правок в своих файлах

### Requirement: Лимиты в model_info
У каждого алиаса SHALL быть `model_info.max_input_tokens` и `model_info.max_output_tokens`.
Из них собираются лимиты контекста для OpenCode.

#### Scenario: Новый алиас
- **WHEN** в `model_list` добавлен алиас с `model_info`
- **AND** запущен `scripts/sync-agents.py`
- **THEN** в OpenCode появляется `gateway/<алиас>` с теми же лимитами

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

### Requirement: Нативный запуск
Шлюз SHALL запускаться через `scripts/gateway.sh start|stop|restart|status|logs` без Docker.
Первый запуск SHALL сам ставить LiteLLM в `build/litellm-venv` на Python 3.12 через `uv`.
Ключи SHALL читаться из `.env`, лог и pid SHALL лежать в `build/`.

#### Scenario: Первый запуск на чистой машине
- **GIVEN** `build/litellm-venv` нет
- **WHEN** выполняется `scripts/gateway.sh start`
- **THEN** LiteLLM ставится, шлюз отвечает на `http://localhost:4000/health/liveliness`

#### Scenario: Шлюз не поднялся
- **WHEN** процесс LiteLLM завершился при старте
- **THEN** скрипт выходит с ошибкой и печатает хвост лога

### Requirement: OpenCode ходит через шлюз
Провайдер `gateway` в OpenCode SHALL генерироваться `sync-agents.py` из `model_list`
в `~/.config/opencode/opencode.json`, с `baseURL` шлюза и ключом `{env:LITELLM_MASTER_KEY}`.
Модель по умолчанию SHALL браться из уровня `smart` в `agents/targets.json`.
`scripts/oc.sh` SHALL поднимать шлюз, если он не запущен, и SHALL передавать OpenCode
только ключи провайдеров моделей, а не весь `.env`.

#### Scenario: Уровень ссылается на несуществующий алиас
- **WHEN** в `agents/targets.json` указан `gateway/<алиас>`, которого нет в `model_list`
- **THEN** `sync-agents.py` печатает предупреждение с именем уровня и алиаса

#### Scenario: Запуск OpenCode при выключенном шлюзе
- **GIVEN** шлюз не запущен
- **WHEN** выполняется `scripts/oc.sh`
- **THEN** шлюз стартует, затем открывается OpenCode

### Requirement: Последнее звено работает без интернета
Каждая цепочка fallback — бесплатная и платная — SHALL заканчиваться на `gpt-oss-coder-local`.
Локальный алиас SHALL NOT вести дальше ни на какую облачную модель.

#### Scenario: Нет интернета
- **GIVEN** SSD подключён, Ollama запущена, сети нет
- **WHEN** агент уровня `smart` шлёт запрос
- **THEN** облачные алиасы по цепочке падают
- **AND** ответ приходит от `gpt-oss-coder-local`

#### Scenario: Бесплатные модели кончились
- **GIVEN** `nemotron-coder-cloud-free` и `north-coder-cloud-free` отвечают ошибкой
- **WHEN** агент шлёт запрос на `nemotron-coder-cloud-free`
- **THEN** ответ приходит от `gpt-oss-coder-local`
- **AND** платные алиасы не вызываются

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
Алиас, у которого ключ (`api_key: os.environ/<VAR>`) пуст в `.env` и в окружении, SHALL NOT попадать в конфиг,
на котором стартует шлюз, в его цепочки fallback и в список `gateway` в OpenCode.
Шлюз и `sync-agents.py` SHALL печатать пропущенный алиас и пустую переменную.

#### Scenario: Ключ DeepSeek ещё не получен
- **GIVEN** `DEEPSEEK_API_KEY` пуст
- **WHEN** запускаются `gateway.sh start` и `sync-agents.py`
- **THEN** `deepseek-coder-direct` нет ни в шлюзе, ни в OpenCode
- **AND** цепочка `deepseek-coder-cloud` идёт сразу на локальную модель
