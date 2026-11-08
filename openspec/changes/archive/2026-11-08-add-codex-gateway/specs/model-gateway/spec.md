## ADDED Requirements

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

## MODIFIED Requirements

### Requirement: OpenCode ходит через шлюз
Провайдер `gateway` в OpenCode SHALL генерироваться `sync-agents.py` из `model_list`
в `~/.config/opencode/opencode.json`, с `baseURL` шлюза и ключом-заглушкой шлюза.
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
