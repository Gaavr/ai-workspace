# Агенты

Один файл на агента, из него `scripts/sync-agents.py` собирает версии для Claude Code, OpenCode и Codex.

## Формат

```markdown
---
description: Разбирает готовый код на баги и риски. Ничего не правит.
role: subagent        # primary | subagent
access: read-only     # read-only | edit
tier: smart           # уровень из targets.json
temperature: 0.2      # только OpenCode
---
Инструкции.
```

`name` по умолчанию берётся из имени файла. Frontmatter плоский: `ключ: значение`, без вложенности.

| Поле | Claude Code | OpenCode | Codex |
|---|---|---|---|
| `role: primary` | не попадает | `mode: primary` | не попадает |
| `access: read-only` | `disallowedTools: Write, Edit, NotebookEdit` | `permission.edit: deny` | строка в инструкциях |
| `tier` | `model` | `model` | `model_reasoning_effort` |

У Codex `sandbox_mode` в файле агента не работает, подагент наследует песочницу родителя, поэтому запрет правок там только словами.

Агенты с `role: primary` уходят только в OpenCode: в Claude Code и Codex нет выбора основного агента из списка, а как подагент «ведущий» будет мешать.

## Поля только для одного инструмента

Префикс с именем инструмента, вложенность через точку:

```yaml
opencode.mode: all
opencode.permission.bash: ask
claude.color: green
codex.features.shell_tool: false
```

## Модели

`targets.json` переводит `tier` в конкретные поля. Поменять модель для всех агентов уровня — правка одной строки.

## Приватные

`agents.local/` — тот же формат, не в git.
