# ai-workspace

Local AI environment with swappable model providers.

## Overview

Open WebUI for chats talks to a LiteLLM gateway, which routes requests to cloud or local models. Switching providers means editing one YAML file.

Claude Code, Codex and OpenCode share skills, agents, global instructions and MCP servers. The repository holds one source for each, `scripts/sync-agents.py` lays it out into every tool's config.

## Components

| Service | Port | Role |
|---|---|---|
| Open WebUI | 3000 | chats, personas |
| LiteLLM | 4000 | gateway, routing |
| mcpo | 8000 | MCP over OpenAPI |
| Ollama | 11434 | local inference, native |

Ollama runs outside Docker. Containers on macOS have no Metal access.

## Setup

```bash
git clone <repo> && cd ai-workspace
./bootstrap.sh
```

The script creates `.env` and exits. Fill in the keys, then run again:

```bash
./bootstrap.sh full
```

Profiles: `full` (48 GB), `light` (16–32 GB), `cloud` (no local models).

The script also runs `scripts/sync-agents.py`, which links skills and agents into Claude Code, Codex and OpenCode and generates `mcpo/config.json`.

Then create an account in Open WebUI, get an API key from Settings → Account, add it to `.env`, and sync personas:

```bash
python3 scripts/sync-personas.py
```

## Layout

```
ai-workspace/
├── docker-compose.yml
├── bootstrap.sh
├── litellm/config.yaml      model aliases, fallback
├── prompts/                 Open WebUI personas
├── prompts.local/           personas, not in git
├── instructions/AGENTS.md   global rules for all three tools
├── skills/                  skills
├── skills.local/            skills, not in git
├── agents/                  agents, neutral format
│   └── targets.json         model tier per tool
├── agents.local/            agents, not in git
├── mcp/servers.json         MCP servers
├── opencode/
│   ├── opencode.jsonc       provider, not in git
│   └── opencode.example.jsonc
├── mcpo/config.json         generated, not in git
├── build/                   generated agents, not in git
├── scripts/
│   ├── sync-agents.py       skills, agents, rules, MCP -> tools
│   ├── mcp-run.py           starts an MCP server with keys from .env
│   ├── oc.sh                OpenCode with model keys from .env
│   ├── sync-personas.py
│   ├── backup.sh
│   └── restore.sh
└── data/                    Open WebUI database, not in git
```

## Model aliases

Personas and agents reference an alias, not a model:

```yaml
model_list:
  - model_name: qwen-coder-local
    litellm_params:
      model: ollama_chat/qwen3-coder:30b
      api_base: os.environ/OLLAMA_HOST_URL
```

Naming scheme: `model-role-location`. For example `qwen-coder-cloud-free`, `qwen-chat-local`.

Replacing the model behind an alias requires no changes to personas:

```bash
ollama pull qwen4:30b
# change model: in litellm/config.yaml
docker compose restart litellm
```

## Fallback

```yaml
router_settings:
  fallbacks:
    - laguna-coder-cloud-free: ["qwen-coder-cloud-free", "qwen-chat-local"]
    - qwen-coder-cloud-free: ["qwen-coder-local", "qwen-chat-local"]
```

Triggers on any provider error: exhausted rate limit, insufficient credits, revoked key, no network.

## Personas

A chat with a system prompt and a fixed model. File in `prompts/`:

```markdown
---
id: algo-coach
name: Coding Challenge Coach
base: qwen-coder-cloud-free
temperature: 0.3
---
System prompt.
```

Required fields: `id`, `name`, `base`.

```bash
python3 scripts/sync-personas.py           # add and update
python3 scripts/sync-personas.py --prune   # remove those missing from files
python3 scripts/sync-personas.py --dry-run # print payload only
```

Git is the source of truth. Edits made in the interface get overwritten.

## Agents, skills, MCP

Shared by Claude Code, Codex and OpenCode. Edit the source in the repository, then:

```bash
python3 scripts/sync-agents.py            # apply
python3 scripts/sync-agents.py --dry-run  # show changes only
```

Tools read all of this at startup, so start a new session afterwards.

| Source | Claude Code | Codex | OpenCode |
|---|---|---|---|
| `skills/` | `~/.claude/skills/` | `~/.agents/skills/` | reads both |
| `agents/` | `~/.claude/agents/*.md` | `~/.codex/agents/*.toml` | `~/.config/opencode/agent/*.md` |
| `instructions/AGENTS.md` | `~/.claude/CLAUDE.md` | `~/.codex/AGENTS.md` | `~/.config/opencode/AGENTS.md` |
| `mcp/servers.json` | `~/.claude.json` | `~/.codex/config.toml` | `~/.config/opencode/opencode.json` |

Skills and instructions are symlinks into the repository. Agents are generated into `build/` and linked from there. The script recognizes its own links and entries and leaves everything else alone.

**Skill** — a procedure the model pulls in when the task matches its description. Same `SKILL.md` format in all three tools, see [skills/README.md](skills/README.md).

**Agent** — one file, three renderings:

```markdown
---
description: Code review. Changes nothing.
role: subagent        # primary | subagent
access: read-only     # read-only | edit
tier: smart           # key in agents/targets.json
---
Instructions.
```

`tier` maps to a model per tool in `agents/targets.json`. Primary agents go to OpenCode only. Details in [agents/README.md](agents/README.md).

**MCP server** — `mcp/servers.json`, Claude Desktop format. Secrets stay in `.env`:

```json
"jira": {
  "command": "uvx",
  "args": ["mcp-atlassian"],
  "env": { "JIRA_URL": "${JIRA_URL}", "JIRA_API_TOKEN": "${JIRA_API_TOKEN}" }
}
```

Client configs call `scripts/mcp-run.py <name>`, which reads `.env` and hands the server only the variables listed in its `env`. A server with an empty variable is skipped. Open WebUI gets the same servers through mcpo: `mcpo/config.json` is generated with values filled in, since the wrapper is not reachable from the container.

## Public and private

| Path | In git |
|---|---|
| `prompts/`, `skills/`, `agents/`, `mcp/` | yes |
| `prompts.local/`, `skills.local/`, `agents.local/` | no |
| `.env`, `data/`, `build/`, `mcpo/config.json` | no |

Config files reference environment variables, not values. The repository is publishable as is.

## Diagram

![Architecture](docs/architecture.drawio.png)
