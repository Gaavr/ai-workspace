# model-gateway Specification

## Purpose
Шлюз LiteLLM — единственное место, откуда инструменты берут модели: весь каталог OpenRouter
под ID моделей и локальная модель Ollama. Своих алиасов нет: сменить модель уровня — правка
одной строки в `agents/targets.json`. Шлюз работает нативно, без Docker.

## Requirements

### Requirement: Каталог OpenRouter вместо алиасов
Облачные модели SHALL подключаться одной записью `openrouter/*`, своих алиасов SHALL NOT быть.
Шлюз и `sync-agents.py` SHALL разворачивать её по каталогу OpenRouter: модель — под своим ID,
без сети — по сохранённому `build/litellm/openrouter-models.json`. Локальная модель SHALL
называться `ollama/<модель Ollama>`. Ключи SHALL браться из `os.environ/…`, не из конфига.

#### Scenario: Модель появилась на OpenRouter
- **GIVEN** OpenRouter добавил модель в каталог
- **WHEN** шлюз перезапускается
- **THEN** модель вызывается через шлюз по её ID без правок `litellm/config.yaml`

#### Scenario: Модель пропала у провайдера
- **GIVEN** бесплатную модель уровня убрали с OpenRouter
- **WHEN** в `agents/targets.json` у уровня меняется ID модели и запускается `sync-agents.py`
- **THEN** агенты уровня работают на новой модели без правок в своих файлах

#### Scenario: Нет сети при старте шлюза
- **GIVEN** сети нет, сохранённый список каталога есть
- **WHEN** выполняется `scripts/gateway.sh start`
- **THEN** шлюз стартует с моделями из сохранённого списка

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

### Requirement: Последнее звено работает без интернета
Каждая цепочка fallback SHALL заканчиваться на `ollama/gpt-oss-20b-ssd`.
Локальная модель SHALL NOT вести дальше ни на какую облачную модель.

#### Scenario: Нет интернета
- **GIVEN** SSD подключён, Ollama запущена, сети нет
- **WHEN** агент уровня `smart` шлёт запрос
- **THEN** облачные модели по цепочке падают
- **AND** ответ приходит от `ollama/gpt-oss-20b-ssd`

#### Scenario: Бесплатные модели кончились
- **GIVEN** `nvidia/nemotron-3-ultra-550b-a55b:free` и `cohere/north-mini-code:free` отвечают ошибкой
- **WHEN** агент шлёт запрос на `nvidia/nemotron-3-ultra-550b-a55b:free`
- **THEN** ответ приходит от `ollama/gpt-oss-20b-ssd`
- **AND** платные модели не вызываются

### Requirement: Шлюз только для этого Mac
Шлюз SHALL слушать только `127.0.0.1`. Ключ нативного шлюза SHALL быть постоянной
заглушкой `sk-local-gateway`, а не секретом из `.env`. Запросы SHALL приниматься в форматах
Chat Completions и Responses.

#### Scenario: Запрос из локальной сети
- **WHEN** другая машина в сети обращается к порту шлюза по адресу этого Mac
- **THEN** соединение не устанавливается

#### Scenario: Приложение без доступа к .env
- **GIVEN** Codex App запущен из Dock, без переменных из `.env`
- **WHEN** он шлёт запрос в шлюз через провайдер `gateway`
- **THEN** шлюз отвечает

### Requirement: Лимиты моделей из каталога
У каждой модели шлюза SHALL быть известны `max_input_tokens` и `max_output_tokens`:
у моделей каталога — из каталога OpenRouter, у локальных — из `model_info` в `litellm/config.yaml`.
Из них собираются лимиты контекста для OpenCode и окно контекста профилей Codex.

#### Scenario: Модель каталога в OpenCode
- **WHEN** запущен `scripts/sync-agents.py`
- **THEN** в OpenCode есть `gateway/<ID модели>` с контекстом и лимитом вывода из каталога

### Requirement: Бесплатное падает только на бесплатное
`router_settings.fallbacks` SHALL переводить бесплатную модель только на бесплатные
и локальные. Платная модель SHALL NOT появляться в цепочке бесплатной. Цепочка `openrouter/*`
SHALL доставаться каждой модели каталога без своей цепочки.

#### Scenario: Бесплатная модель недоступна
- **GIVEN** `nvidia/nemotron-3-ultra-550b-a55b:free` отвечает ошибкой
- **WHEN** агент шлёт запрос на эту модель
- **THEN** ответ приходит от `cohere/north-mini-code:free`
- **AND** платные модели не вызываются

#### Scenario: Модель каталога без своей цепочки
- **GIVEN** у модели каталога нет своей цепочки, и она отвечает ошибкой
- **WHEN** агент шлёт запрос на эту модель
- **THEN** ответ приходит от локальной модели

### Requirement: OpenCode видит каталог через шлюз
Провайдер `gateway` в OpenCode SHALL генерироваться `sync-agents.py` из `model_list`
с развёрнутым каталогом OpenRouter в `~/.config/opencode/opencode.json`, с `baseURL` шлюза
и ключом-заглушкой шлюза. Модель по умолчанию SHALL браться из уровня `smart`
в `agents/targets.json`. `scripts/oc.sh` SHALL поднимать шлюз, если он не запущен,
и SHALL передавать OpenCode только ключи провайдеров моделей, а не весь `.env`.

#### Scenario: Уровень ссылается на несуществующую модель
- **WHEN** в `agents/targets.json` указан `gateway/<ID>`, которого нет ни в каталоге, ни в `model_list`
- **THEN** `sync-agents.py` печатает предупреждение с именем уровня и модели

#### Scenario: Каталог недоступен и не сохранён
- **GIVEN** сети нет и `build/litellm/openrouter-models.json` нет
- **WHEN** запускается `sync-agents.py`
- **THEN** он печатает предупреждение, в OpenCode остаются только модели из `model_list`

#### Scenario: Запуск OpenCode при выключенном шлюзе
- **GIVEN** шлюз не запущен
- **WHEN** выполняется `scripts/oc.sh`
- **THEN** шлюз стартует, затем открывается OpenCode

### Requirement: Модель без ключа выпадает
Запись `model_list`, у которой ключ (`api_key: os.environ/<VAR>`) пуст в `.env` и в окружении,
SHALL NOT попадать в конфиг, на котором стартует шлюз, в его цепочки fallback и в список
`gateway` в OpenCode. Для `openrouter/*` это выключает весь каталог. Шлюз и `sync-agents.py`
SHALL печатать пропущенную запись и пустую переменную.

#### Scenario: Ключ OpenRouter не задан
- **GIVEN** `OPENROUTER_API_KEY` пуст
- **WHEN** запускаются `gateway.sh start` и `sync-agents.py`
- **THEN** моделей каталога нет ни в шлюзе, ни в OpenCode
- **AND** остаётся локальная модель
