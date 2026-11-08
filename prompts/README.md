# Персоны Open WebUI

Чаты с собственным системным промптом и моделью.

## Структура

Один файл — одна персона.

| Путь | В git |
|---|---|
| `prompts/` | да |
| `prompts.local/` | нет |

Файлы на подчёркивание (`_template.md`) скрипт пропускает.

## Поля шапки

Обязательные: `id`, `name`, `base`.
Необязательные: `description`, `temperature`, `top_p`, `num_ctx`, `max_tokens`.

`base` — алиас из `litellm/config.yaml`, не имя реальной модели.
Меняешь модель за алиасом — персона переезжает, файл не трогаешь.

## Создать

```bash
cp prompts/_template.md prompts/имя.md
open -e prompts/имя.md
python3 scripts/sync-personas.py
```

## Команды

| Команда | Что делает |
|---|---|
| `sync-personas.py` | добавляет и обновляет |
| `sync-personas.py --prune` | плюс удаляет то, чего нет в файлах |
| `sync-personas.py --dry-run` | показывает payload, ничего не шлёт |
| `sync-personas.py --export` | выгружает текущее состояние |

## Правки в UI перезаписываются

Git — источник правды. Поправил персону в интерфейсе, запустил скрипт — правка потеряна.
Правь файл.

## В Claude Code, Codex и OpenCode

`scripts/sync-agents.py` раскладывает те же файлы по инструментам кода. `base` им не нужен:
модель берётся из сессии или из `tier` (`agents/targets.json`).

| Инструмент | Чем становится | Как выбрать |
|---|---|---|
| Claude Code | output style | Settings → Claude Code → Output style, в CLI `/config` |
| Codex | профиль `~/.codex/<id>.config.toml` | `codex -p <id>` |
| OpenCode | основной агент | Tab, `oc.sh --agent <id>` |

`id` — латиница в нижнем регистре, цифры, дефис: из него собираются имена файлов.
Поля только для одного инструмента — с префиксом, как у агентов: `claude.keep-coding-instructions: true`.

## Чем отличается от скиллов

Персона — кто ты, активна весь диалог, выбираешь сам.
Скилл — как делать процедуру, подключается сам, живёт в `opencode/skill/`.
