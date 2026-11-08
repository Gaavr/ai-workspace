## ADDED Requirements

### Requirement: Codex видит алиасы шлюза
`sync-agents.py` SHALL добавлять в свой блок `~/.codex/config.toml` провайдер шлюза
и профили на его алиасы. Ключ шлюза SHALL NOT записываться в `config.toml` значением.

#### Scenario: Запуск Codex на открытой модели
- **GIVEN** шлюз запущен
- **WHEN** выполняется `codex -p <алиас>`
- **THEN** Codex отвечает через шлюз моделью этого алиаса
