## ADDED Requirements

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
