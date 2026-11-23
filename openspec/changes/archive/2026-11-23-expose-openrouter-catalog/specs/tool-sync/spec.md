## MODIFIED Requirements

### Requirement: Codex видит уровни шлюза
`sync-agents.py` SHALL добавлять в свой блок `~/.codex/config.toml` провайдер `gateway`
с адресом шлюза и `wire_api = "responses"` и SHALL создавать профили
`~/.codex/<уровень>.config.toml` для каждого уровня OpenCode из `agents/targets.json`,
чья модель — модель шлюза (`gateway/<ID>`). Профиль SHALL задавать провайдер `gateway`,
ID модели и окно контекста из её лимитов. Секреты из `.env` SHALL NOT записываться в конфиги
Codex, только ключ-заглушка шлюза.

#### Scenario: Запуск Codex на уровне smart
- **GIVEN** шлюз запущен
- **WHEN** выполняется `codex -p smart`
- **THEN** Codex отвечает через шлюз моделью уровня `smart`

#### Scenario: Сменилась модель уровня
- **WHEN** в `agents/targets.json` у `smart` другой ID модели и запущен `sync-agents.py`
- **THEN** профиль `smart` Codex и агенты OpenCode уровня `smart` указывают на новую модель

#### Scenario: Модели уровня нет в шлюзе
- **WHEN** у уровня в `agents/targets.json` ID, которого нет ни в каталоге, ни в `model_list`
- **THEN** `sync-agents.py` печатает предупреждение и не создаёт профиль этого уровня

#### Scenario: Свои профили владельца
- **GIVEN** в `~/.codex/` лежат свои профили `light`, `medium`, `text`
- **WHEN** запускается `sync-agents.py`
- **THEN** они не тронуты
