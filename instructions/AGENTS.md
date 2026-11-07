# Общие правила

Читают Claude Code, Codex и OpenCode во всех проектах. Источник: `ai-workspace/instructions/AGENTS.md`.

- Отвечай по-русски. Код, идентификаторы и коммиты — как принято в проекте.
- Не пересказывай, что собираешься сделать. Делай и показывай результат.
- Задача неоднозначна — уточни у человека, а не угадывай.
- Перед правкой прочитай окружающий код и пиши в его стиле.

## Скилы, агенты, MCP

Claude Code, Codex и OpenCode берут их из одного места — `~/Projects/ai/ai-workspace`.
Новые и изменённые кладёшь только туда, не в папки самого инструмента
(`~/.claude/skills`, `~/.codex/skills`, `~/.agents/skills`, `~/.config/opencode/skill`, `~/.claude/agents` и т. п.).

- Скил: `skills/<имя>/SKILL.md`, личный или с рабочим контекстом — `skills.local/<имя>/SKILL.md`.
- Агент: `agents/<имя>.md`, формат в `agents/README.md`.
- MCP-сервер: `mcp/servers.json`, ключи — в `.env`.

После этого запусти `python3 ~/Projects/ai/ai-workspace/scripts/sync-agents.py`: он разложит всё по трём инструментам.
