# tool-sync Specification

## Purpose
Один источник в репо для Claude Code, Codex и OpenCode. `scripts/sync-agents.py` раскладывает
скилы, агентов, правила и MCP по конфигам каждого инструмента. Пропал один инструмент —
те же скилы и агенты остаются в двух других.

## Requirements

### Requirement: Источник правды в репо
Скилы (`skills/`, `skills.local/`), агенты (`agents/`, `agents.local/`), глобальные правила
(`instructions/AGENTS.md`) и MCP-серверы (`mcp/servers.json`) SHALL жить только в репо.
Папки `*.local/` SHALL NOT попадать в git.

#### Scenario: Новый скил
- **WHEN** в `skills/<имя>/SKILL.md` добавлен скил и запущен `sync-agents.py`
- **THEN** скил виден в Claude Code, Codex и OpenCode

### Requirement: Свои ссылки и чужие файлы
Скрипт SHALL создавать в папках инструментов только симлинки в репо и SHALL удалять только
свои симлинки, которых больше нет в источнике. Настоящий файл на месте ссылки SHALL NOT
перезаписываться: скрипт печатает предупреждение и пропускает его.

#### Scenario: Пользователь положил свой файл
- **GIVEN** в `~/.codex/` лежит свой профиль `light.config.toml`
- **WHEN** запускается `sync-agents.py`
- **THEN** файл не тронут

### Requirement: Агент в нейтральном формате
Агент SHALL описываться одним файлом с полями `description`, `role`, `access`, `tier`.
`sync-agents.py` SHALL собирать из него версии для трёх инструментов в `build/`.
`tier` SHALL переводиться в модель через `agents/targets.json`. Агент с `role: primary`
SHALL попадать только в OpenCode.

#### Scenario: Агент только для чтения
- **GIVEN** у агента `access: read-only`
- **THEN** в Claude Code ему запрещены Write, Edit и NotebookEdit
- **AND** в OpenCode `permission.edit: deny`
- **AND** в Codex запрет записан в инструкциях

### Requirement: MCP без секретов в конфигах
Записи MCP в конфигах клиентов SHALL вызывать `scripts/mcp-run.py <имя>`, который берёт ключи
из `.env`. Сервер с пустой переменной SHALL пропускаться. Для Open WebUI `mcpo/config.json`
SHALL генерироваться со значениями и правами 600.

#### Scenario: Не заданы ключи Jira
- **GIVEN** в `.env` пусто `JIRA_API_TOKEN`
- **WHEN** запускается `sync-agents.py`
- **THEN** сервер jira не попадает ни в один клиент, скрипт пишет почему

### Requirement: Пробный прогон
`sync-agents.py --dry-run` SHALL показывать все изменения и SHALL NOT менять файлы.

#### Scenario: Повторный запуск
- **GIVEN** источник не менялся с прошлого запуска
- **WHEN** выполняется `sync-agents.py --dry-run`
- **THEN** изменений нет

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
