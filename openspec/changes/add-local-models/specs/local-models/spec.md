## ADDED Requirements

### Requirement: Открытый основной рантайм
Основной локальный рантайм SHALL быть открытым — Ollama. Он SHALL запускаться скриптом
с внешнего SSD, без установки в `/Applications` и без автозапуска. Модели SHALL храниться
на SSD (`OLLAMA_MODELS`).

#### Scenario: Запуск со шлюзом
- **GIVEN** SSD подключён
- **WHEN** выполняется `scripts/gateway.sh start`
- **THEN** поднимаются Ollama и шлюз
- **AND** `gpt-oss-coder-local` отвечает через шлюз

#### Scenario: SSD не подключён
- **GIVEN** тома SSD нет
- **WHEN** выполняется `scripts/gateway.sh start`
- **THEN** шлюз стартует, Ollama — нет
- **AND** скрипт печатает, что локальные модели недоступны

### Requirement: Тестовая модель из того, что уже есть
gpt-oss-20b SHALL импортироваться в Ollama из GGUF, уже лежащего на SSD, с контекстом
не меньше 16 тыс. токенов. Модель SHALL вызывать инструменты.

#### Scenario: Агент на локальной модели
- **WHEN** выполняется `scripts/oc.sh run --agent lead -m gateway/gpt-oss-coder-local "…"`
- **THEN** агент отвечает и может вызвать инструмент

### Requirement: Закрытый рантайм только запасной
LM Studio SHALL NOT стоять в цепочках fallback и SHALL NOT запускаться при входе в систему.
Он SHALL читать модели из той же папки на SSD, без копий.

#### Scenario: Выбор LM Studio вручную
- **GIVEN** в LM Studio запущен сервер
- **WHEN** выполняется `scripts/oc.sh -m gateway/gpt-oss-coder-lmstudio`
- **THEN** OpenCode работает через LM Studio

### Requirement: Старые установщики не удаляются насовсем
Заменённые установщики SHALL перемещаться в корзину, а не удаляться.

#### Scenario: Замена установщиков
- **WHEN** на SSD кладутся новые Ollama и LM Studio
- **THEN** старые LM Studio 0.3.16, 0.3.35 и Ollama.app 0.6.8 лежат в корзине тома
