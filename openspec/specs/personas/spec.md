# personas Specification

## Purpose
Персона — режим разговора: свой системный промпт на весь диалог, выбирается человеком.
Один файл в `prompts/` доступен в Claude Code, Codex, OpenCode и Open WebUI.

## Requirements

### Requirement: Один файл на персону
Персона SHALL описываться файлом `prompts/<id>.md` (личная — `prompts.local/<id>.md`)
с полями `id`, `name`, `base` и необязательными `description`, `temperature`, `tier`.
`id` SHALL состоять из латиницы в нижнем регистре, цифр и дефиса. Файлы на подчёркивание
SHALL пропускаться.

#### Scenario: Неправильный id
- **WHEN** у персоны `id: Algo Coach`
- **THEN** `sync-agents.py` останавливается с ошибкой и именем файла

### Requirement: Персона в каждом инструменте
`sync-agents.py` SHALL раскладывать персону так:
- Claude Code — output style `~/.claude/output-styles/<id>.md` без инструкций для кода;
- Codex — профиль `~/.codex/<id>.config.toml` с `developer_instructions`, запуск `codex -p <id>`;
- OpenCode — основной агент, выбирается по Tab или `--agent <id>`.

`base` SHALL использоваться только Open WebUI. Инструменты берут модель сессии или `tier`.

#### Scenario: Персона в OpenCode
- **WHEN** выполняется `scripts/oc.sh run --agent algo-coach "Кто ты?"`
- **THEN** отвечает модель шлюза в роли тренера

#### Scenario: Персона в Codex
- **WHEN** выполняется `codex -p algo-coach`
- **THEN** сессия идёт с промптом персоны поверх обычных инструкций Codex

### Requirement: Чужие профили Codex не трогаются
В `~/.codex/` скрипт SHALL удалять только ссылки на профили персон из `build/codex/profiles/`.

#### Scenario: Персона удалена
- **GIVEN** в `~/.codex/` есть ссылка `AGENTS.md` и свой профиль `light.config.toml`
- **WHEN** файл персоны удалён и запущен `sync-agents.py`
- **THEN** удалена только ссылка на профиль этой персоны

### Requirement: Имя персоны не совпадает с агентом
`id` персоны SHALL NOT совпадать с именем агента.

#### Scenario: Совпадение
- **WHEN** есть агент `lead` и персона с `id: lead`
- **THEN** `sync-agents.py` останавливается с ошибкой
