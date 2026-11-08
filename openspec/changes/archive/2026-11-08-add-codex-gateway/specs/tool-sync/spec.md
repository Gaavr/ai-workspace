## ADDED Requirements

### Requirement: Codex видит уровни шлюза
`sync-agents.py` SHALL добавлять в свой блок `~/.codex/config.toml` провайдер `gateway`
с адресом шлюза и `wire_api = "responses"` и SHALL создавать профили
`~/.codex/<уровень>.config.toml` для каждого уровня OpenCode из `agents/targets.json`,
чья модель — алиас шлюза. Профиль SHALL задавать провайдер `gateway`, модель-алиас
и окно контекста из `model_info`. Секреты из `.env` SHALL NOT записываться в конфиги Codex,
только ключ-заглушка шлюза.

#### Scenario: Запуск Codex на уровне smart
- **GIVEN** шлюз запущен
- **WHEN** выполняется `codex -p smart`
- **THEN** Codex отвечает через шлюз моделью уровня `smart`

#### Scenario: Сменилась модель уровня
- **WHEN** в `agents/targets.json` у `smart` другой алиас и запущен `sync-agents.py`
- **THEN** профиль `smart` Codex и агенты OpenCode уровня `smart` указывают на новый алиас

#### Scenario: Свои профили владельца
- **GIVEN** в `~/.codex/` лежат свои профили `light`, `medium`, `text`
- **WHEN** запускается `sync-agents.py`
- **THEN** они не тронуты
