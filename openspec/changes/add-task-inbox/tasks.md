# Tasks

## 1. Владелец
- [ ] 1.1 Создать приватный репозиторий задач, положить `projects.yaml`, склонировать
      в `~/Projects/ai/tasks`.
- [ ] 1.2 Токен бота и Telegram ID — в `.env` проекта `task-inbox`.

## 2. CLI
- [x] 2.1 `tasks` в проекте `task-inbox`: `list`, `show`, `start`, `review`, `done`, `cancel`,
      `queue`, `add`, `note`, `path`, `projects`, `--json` у чтения.
- [x] 2.2 Установка: `uv tool install --editable ~/Projects/ai/task-inbox`, `tasks --help`.

## 3. Скил
- [x] 3.1 `skills/tasks/SKILL.md`: порядок работы, запреты, чтение без CLI.
- [x] 3.2 `python3 scripts/sync-agents.py --dry-run`, затем `python3 scripts/sync-agents.py`:
      скил виден в `~/.claude/skills/tasks` и `~/.agents/skills/tasks`.

## 4. Проверка
- [x] 4.1 `openspec validate add-task-inbox --strict`.
- [x] 4.2 В скиле нет имён, почты и названий закрытых репозиториев.
- [ ] 4.3 На живом репозитории задач: «посмотри задачи» → `tasks list`, «начни задачу N» →
      ветка, статус `in_progress`, затем `review` со ссылкой на PR.
- [ ] 4.4 Без установленного `tasks` агент читает файлы задач напрямую.
