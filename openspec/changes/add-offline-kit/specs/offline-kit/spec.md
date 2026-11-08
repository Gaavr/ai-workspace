## ADDED Requirements

### Requirement: Подъём без сети
С комплектом на SSD окружение SHALL подниматься на чистом Mac на Apple Silicon без доступа
к npm, PyPI и GitHub: репо из `git bundle`, OpenCode, LiteLLM на Python 3.12, Ollama.

#### Scenario: Новый Mac без интернета
- **GIVEN** чистый Mac, подключён SSD, сети нет
- **WHEN** выполняются шаги из `ai-workspace-kit/README.md`
- **THEN** шлюз отвечает, OpenCode запускается и отвечает через локальную модель

### Requirement: Комплект проверяем
В комплекте SHALL быть `MANIFEST` с версией и SHA-256 каждого файла. `scripts/kit.sh check`
SHALL сверять файлы с ним и называть каждое расхождение.

#### Scenario: Испорченный файл
- **GIVEN** колесо в `python/wheels/` повреждено
- **WHEN** выполняется `scripts/kit.sh check`
- **THEN** скрипт выходит с ошибкой и называет файл

### Requirement: Обновление по версиям
`scripts/kit.sh refresh` SHALL перекачивать только компоненты, у которых изменилась версия,
и SHALL переписывать `MANIFEST`.

#### Scenario: Обновился OpenCode
- **GIVEN** OpenCode обновлён, LiteLLM — нет
- **WHEN** выполняется `scripts/kit.sh refresh`
- **THEN** заменены только файлы OpenCode, колёса LiteLLM не скачиваются

### Requirement: Установка из комплекта первой
`gateway.sh` SHALL ставить LiteLLM из комплекта, если комплект доступен, и SHALL ставить
из сети только без него.

#### Scenario: Первый запуск шлюза при подключённом SSD
- **GIVEN** `build/litellm-venv` нет, SSD подключён
- **WHEN** выполняется `scripts/gateway.sh start`
- **THEN** LiteLLM ставится без обращения к PyPI
