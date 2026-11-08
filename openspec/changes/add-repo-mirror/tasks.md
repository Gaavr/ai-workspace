# Tasks

## 0. Требования
- [x] 0.1 Ответы владельца на открытые вопросы: SSD, рабочие папки целиком, без секретов,
      `Apps`, `ai`, `YT`, старые копии не трогать, запуск командой.

## 1. Скрипт
- [x] 1.1 `scripts/sync-projects.sh [--dry-run]`: rsync `~/Projects/{Apps,ai,YT}` в
      `CodeProjects/Projects/`, путь к SSD из `AI_SSD`; без SSD — понятная ошибка.
- [x] 1.2 Исключения: секреты и сборочный мусор из спеки, `.env.example` остаётся.
- [x] 1.3 `--delete` с `--backup-dir` в `CodeProjects/Projects-deleted/<дата-время>/`.

## 2. Проверка
- [x] 2.1 `openspec validate add-repo-mirror --strict`.
- [x] 2.2 `--dry-run` ничего не пишет.
- [x] 2.3 Первая синхронизация: в копиях git-история и `git status` совпадают с Mac.
      HEAD, ссылки и `fsck` совпадают у всех шести; `git status` grams в копии без `build/` — она исключена.
- [x] 2.4 В копии нет `.env` и `mcpo/config.json`, есть `.env.example`; нет `build/`, worktrees.
- [x] 2.5 Удалённый на Mac тестовый файл уходит в `Projects-deleted/`.
- [x] 2.6 Старые копии (`xcode/`, `MyApps/` …) не изменились.
- [x] 2.7 README: копия проектов.
