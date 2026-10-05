#!/usr/bin/env python3
"""
Синхронизация агентов: agents/*.md -> Claude Code, OpenCode, Codex, GigaCode.

Git остаётся единственным источником правды. Правишь файл в agents/, запускаешь
скрипт, все инструменты приводятся в соответствие. Сгенерированные файлы
руками не правят — они будут перезаписаны.

Формат файла: YAML-frontmatter + тело промпта.

    ---
    name: functional-tester
    description: Проверяет, делает ли приложение то, что обещано в спеках
    readonly: true
    ---
    Ты проверяешь...

readonly: true — агент не правит код, но может писать отчёты в reviews/.
В OpenCode это запрет на уровне прав, в Claude Code убран инструмент Edit,
в GigaCode — инструмент edit, в Codex держится только на тексте промпта.

Куда пишет:
    Claude Code  ~/.claude/agents/<name>.md
    OpenCode     opencode/agent/<name>.md   (~/.config/opencode/agent — ссылка сюда)
    Codex        ~/.codex/agents/<name>.toml
    GigaCode     gigacode/agents/<name>.md  (~/.gigacode/agents — ссылка сюда)

Использование:
    ./scripts/sync-agents.py           # записать
    ./scripts/sync-agents.py --dry-run # показать, что изменится
"""

import argparse
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
AGENT_DIRS = [ROOT / "agents", ROOT / "agents.local"]
HOME = pathlib.Path.home()
REPORT_DIR = "reviews"
GIGACODE_READONLY_TOOLS = ["read_file", "read_many_files", "grep_search", "glob",
                           "list_directory", "run_shell_command", "write_file"]


def parse_frontmatter(text, path):
    """Минимальный парсер YAML-frontmatter: плоские пары key: value."""
    if not text.startswith("---"):
        raise ValueError(f"{path.name}: нет frontmatter в начале файла")
    parts = text.split("---", 2)
    if len(parts) < 3:
        raise ValueError(f"{path.name}: frontmatter не закрыт")

    meta = {}
    for line in parts[1].strip().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or ":" not in line:
            continue
        key, _, value = line.partition(":")
        value = value.strip().strip('"').strip("'")
        meta[key.strip()] = value

    return meta, parts[2].strip()


def yaml_str(value):
    """Берёт строку в кавычки, только если без них YAML прочтёт её иначе."""
    risky = (": " in value or " #" in value or value != value.strip()
             or value[:1] in "\"'[]{}&*!|>%@`-?")
    return json.dumps(value, ensure_ascii=False) if risky else value


def render_claude(agent):
    lines = ["---", f"name: {agent['name']}",
             f"description: {yaml_str(agent['description'])}"]
    if agent["readonly"]:
        lines.append("tools: Read, Grep, Glob, Bash, Write")
    lines += ["---", "", agent["body"], ""]
    return "\n".join(lines)


def render_opencode(agent):
    lines = ["---", f"description: {yaml_str(agent['description'])}",
             "mode: subagent"]
    if agent["temperature"]:
        lines.append(f"temperature: {agent['temperature']}")
    if agent["readonly"]:
        lines += ["permission:", "  edit:", '    "*": deny',
                  f'    "{REPORT_DIR}/**": allow']
    lines += ["---", agent["body"], ""]
    return "\n".join(lines)


def render_codex(agent):
    # sandbox_mode не выставляем: read-only запрещает запись и сборке с тестами,
    # а агенту нужно запускать приложение. Запрет править код держится на промпте.
    body = agent["body"].replace("\\", "\\\\").replace('"""', '""\\"')
    return "\n".join([
        f"name = {json.dumps(agent['name'], ensure_ascii=False)}",
        f"description = {json.dumps(agent['description'], ensure_ascii=False)}",
        f'developer_instructions = """\n{body}\n"""',
        "",
    ])


def render_gigacode(agent):
    lines = ["---", f"name: {agent['name']}",
             f"description: {yaml_str(agent['description'])}"]
    if agent["readonly"]:
        lines.append("tools:")
        lines += [f"  - {tool}" for tool in GIGACODE_READONLY_TOOLS]
    lines += ["---", "", agent["body"], ""]
    return "\n".join(lines)


TARGETS = [
    ("Claude Code", lambda name: HOME / ".claude" / "agents" / f"{name}.md",
     render_claude),
    ("OpenCode", lambda name: ROOT / "opencode" / "agent" / f"{name}.md",
     render_opencode),
    ("Codex", lambda name: HOME / ".codex" / "agents" / f"{name}.toml",
     render_codex),
    ("GigaCode", lambda name: ROOT / "gigacode" / "agents" / f"{name}.md",
     render_gigacode),
]


def collect_agents():
    agents = []
    seen = {}

    for directory in AGENT_DIRS:
        if not directory.is_dir():
            continue
        for path in sorted(directory.glob("*.md")):
            if path.name.startswith("_") or path.name.upper() == "README.MD":
                continue
            meta, body = parse_frontmatter(path.read_text(encoding="utf-8"), path)
            for required in ("name", "description"):
                if required not in meta:
                    raise ValueError(f"{path.name}: не хватает поля '{required}'")
            if meta["name"] in seen:
                sys.exit(f"Дубль name '{meta['name']}': {seen[meta['name']]} и {path}")
            seen[meta["name"]] = path
            agents.append({
                "name": meta["name"],
                "description": meta["description"],
                "readonly": meta.get("readonly", "false").lower() == "true",
                "temperature": meta.get("temperature", ""),
                "body": body,
            })

    if not agents:
        sys.exit("Не найдено ни одного .md в agents/ и agents.local/")
    return agents


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true",
                        help="показать, что изменится, ничего не записывать")
    args = parser.parse_args()

    try:
        agents = collect_agents()
    except ValueError as error:
        sys.exit(str(error))

    for agent in agents:
        print(agent["name"] + (" (только чтение)" if agent["readonly"] else ""))
        for label, target, render in TARGETS:
            path = target(agent["name"])
            content = render(agent)
            if path.exists() and path.read_text(encoding="utf-8") == content:
                state = "без изменений"
            else:
                state = "обновится" if path.exists() else "создастся"
                if not args.dry_run:
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_text(content, encoding="utf-8")
            print(f"  {label:<12} {path}  [{state}]")

    if args.dry_run:
        print("\n[dry-run] ничего не записано", file=sys.stderr)


if __name__ == "__main__":
    main()
