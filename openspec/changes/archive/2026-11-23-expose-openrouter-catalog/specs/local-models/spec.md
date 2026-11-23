## MODIFIED Requirements

### Requirement: Открытый основной рантайм
Основной локальный рантайм SHALL быть открытым — Ollama. Он SHALL запускаться скриптом
с внешнего SSD, без установки в `/Applications` и без автозапуска. Модели SHALL храниться
на SSD (`OLLAMA_MODELS`).

#### Scenario: Запуск со шлюзом
- **GIVEN** SSD подключён
- **WHEN** выполняется `scripts/gateway.sh start`
- **THEN** поднимаются Ollama и шлюз
- **AND** `ollama/gpt-oss-20b-ssd` отвечает через шлюз

#### Scenario: SSD не подключён
- **GIVEN** тома SSD нет
- **WHEN** выполняется `scripts/gateway.sh start`
- **THEN** шлюз стартует, Ollama — нет
- **AND** скрипт печатает, что локальные модели недоступны

### Requirement: Тестовая модель из того, что уже есть
gpt-oss-20b SHALL импортироваться в Ollama из GGUF, уже лежащего на SSD, с контекстом
не меньше 16 тыс. токенов, под именем `gpt-oss-20b-ssd`. Модель SHALL вызывать инструменты.

#### Scenario: Агент на локальной модели
- **WHEN** выполняется `scripts/oc.sh run --agent lead -m gateway/ollama/gpt-oss-20b-ssd "…"`
- **THEN** агент отвечает и может вызвать инструмент
