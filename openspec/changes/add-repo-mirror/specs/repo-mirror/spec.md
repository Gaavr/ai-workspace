## ADDED Requirements

### Requirement: Вторая копия проектов на SSD
`scripts/sync-projects.sh` SHALL копировать папки `Apps`, `ai`, `YT` из `~/Projects`
в `CodeProjects/Projects/` на внешнем SSD с той же раскладкой. Рабочие папки SHALL
копироваться целиком: с `.git`, незакоммиченными и неотслеживаемыми файлами.

#### Scenario: Mac пропал, GitHub закрыт
- **GIVEN** копия на SSD сделана после последней работы
- **WHEN** проект открывается из `CodeProjects/Projects/<путь>` на другом Mac
- **THEN** есть вся git-история и незакоммиченные изменения

### Requirement: Без секретов и сборочного мусора
В копию SHALL NOT попадать `.env` и `.env.*` (кроме `.env.example`), `mcpo/config.json`,
файлы ключей `*.p8`, `*.p12`, `*.pem`, `*.key`, профили `*.mobileprovision`, а также
`DerivedData`, `build/`, `.build/`, `node_modules/` и `.claude/worktrees/`.

#### Scenario: Проект с ключами
- **GIVEN** в `~/Projects/ai/ai-workspace` есть `.env` с ключами
- **WHEN** выполняется синхронизация
- **THEN** в копии есть `.env.example`, а `.env` нет

### Requirement: Удалённое не пропадает
Файл, удалённый на Mac, SHALL удаляться из копии с переносом в
`CodeProjects/Projects-deleted/<дата-время>/`, а не насовсем. Прежняя версия
перезаписанного файла SHALL уходить туда же.

#### Scenario: Случайно удалённый файл
- **GIVEN** файл удалён на Mac и прошла синхронизация
- **THEN** его нет в `CodeProjects/Projects/`, он лежит в `Projects-deleted/<дата-время>/`

### Requirement: Старые копии не трогаются
Синхронизация SHALL писать только в `CodeProjects/Projects/` и
`CodeProjects/Projects-deleted/`. Остальное в `CodeProjects/` SHALL оставаться как есть.

#### Scenario: Расходящаяся старая копия
- **GIVEN** в `CodeProjects/MyApps/Swift/Lucid Focus` есть коммит, которого нет на Mac
- **WHEN** выполняется синхронизация
- **THEN** эта папка не изменилась
