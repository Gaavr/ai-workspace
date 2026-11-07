#!/usr/bin/env python3
"""
Запуск MCP-сервера из mcp/servers.json: mcp-run.py <имя>.

Клиенты (Claude Code, Codex, OpenCode) вызывают эту обёртку, а не сервер напрямую.
Так ключи остаются в .env, а не в конфиге каждого клиента, и серверу
достаются только переменные, перечисленные в его env.
"""

import json
import os
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
VAR = re.compile(r"\$\{(\w+)\}")

# GUI-приложения стартуют с урезанным PATH, без brew и node.
EXTRA_PATH = ["/opt/homebrew/bin", "/usr/local/bin", "~/.local/bin", "~/.local/node/bin"]


def load_env():
    env_file = ROOT / ".env"
    values = {}
    if not env_file.exists():
        return values
    for line in env_file.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        values[key.strip()] = value.strip().strip("'\"")
    return values


def main():
    if len(sys.argv) != 2:
        sys.exit("usage: mcp-run.py <server>")
    servers = json.loads((ROOT / "mcp" / "servers.json").read_text(encoding="utf-8"))["mcpServers"]
    server = servers.get(sys.argv[1]) or sys.exit(f"mcp-run: нет сервера {sys.argv[1]} в mcp/servers.json")

    dotenv = load_env()

    def expand(text):
        return VAR.sub(lambda m: os.environ.get(m.group(1)) or dotenv.get(m.group(1), ""), text)

    env = dict(os.environ)
    env.update({key: expand(value) for key, value in server.get("env", {}).items()})
    env["PATH"] = os.pathsep.join([os.path.expanduser(p) for p in EXTRA_PATH] + [env.get("PATH", "")])

    command = server["command"]
    os.execvpe(command, [command, *map(expand, server.get("args", []))], env)


if __name__ == "__main__":
    main()
