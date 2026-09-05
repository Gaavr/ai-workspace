#!/usr/bin/env python3
"""
Синхронизация персон: prompts/*.md -> Open WebUI.

Git остаётся единственным источником правды. Правишь файл, запускаешь скрипт,
Open WebUI приводится в соответствие. Правки, сделанные руками в UI, будут
перезаписаны — это и есть смысл.

Формат файла: YAML-frontmatter + тело промпта.

    ---
    id: qa-engineer
    name: QA инженер
    base: smart
    description: Пишет автотесты для moshub-autotest
    temperature: 0.2
    ---
    Ты senior QA automation engineer...

Использование:
    ./scripts/sync-personas.py           # аддитивно (import)
    ./scripts/sync-personas.py --prune   # точная сверка (sync, удаляет лишнее)
    ./scripts/sync-personas.py --export  # выгрузить текущее состояние в JSON
    ./scripts/sync-personas.py --dry-run # показать, что отправится
"""

import argparse
import json
import os
import pathlib
import sys
import urllib.error
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parent.parent
PROMPTS_DIR = ROOT / "prompts"


def load_env():
    """Читает .env, не затирая уже выставленные переменные окружения."""
    env_file = ROOT / ".env"
    if not env_file.exists():
        return
    for line in env_file.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        os.environ.setdefault(key.strip(), value.strip())


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


def coerce(value):
    """Приводит строку из frontmatter к числу, если она похожа на число."""
    try:
        return int(value)
    except ValueError:
        pass
    try:
        return float(value)
    except ValueError:
        return value


def build_model(meta, system_prompt, path):
    for required in ("id", "name", "base"):
        if required not in meta:
            raise ValueError(f"{path.name}: не хватает поля '{required}'")

    params = {"system": system_prompt}
    for key in ("temperature", "top_p", "num_ctx", "max_tokens"):
        if key in meta:
            params[key] = coerce(meta[key])

    return {
        "id": meta["id"],
        "name": meta["name"],
        "base_model_id": meta["base"],
        "params": params,
        "meta": {
            "description": meta.get("description", ""),
            "profile_image_url": "/static/favicon.png",
        },
        "is_active": True,
    }


def collect_models():
    if not PROMPTS_DIR.is_dir():
        sys.exit(f"Нет каталога {PROMPTS_DIR}")

    models = []
    for path in sorted(PROMPTS_DIR.glob("*.md")):
        meta, body = parse_frontmatter(path.read_text(encoding="utf-8"), path)
        models.append(build_model(meta, body, path))

    if not models:
        sys.exit(f"В {PROMPTS_DIR} не найдено ни одного .md")
    return models


def call_api(url, key, path, payload=None, method="GET"):
    data = json.dumps(payload).encode("utf-8") if payload is not None else None
    request = urllib.request.Request(
        f"{url.rstrip('/')}{path}",
        data=data,
        method=method,
        headers={
            "Authorization": f"Bearer {key}",
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as error:
        body = error.read().decode("utf-8", errors="replace")[:500]
        sys.exit(f"HTTP {error.code} на {path}\n{body}")
    except urllib.error.URLError as error:
        sys.exit(f"Не достучался до {url}: {error.reason}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--prune", action="store_true",
                        help="точная сверка: удаляет персоны, которых нет в prompts/")
    parser.add_argument("--export", action="store_true",
                        help="выгрузить текущее состояние Open WebUI в stdout")
    parser.add_argument("--dry-run", action="store_true",
                        help="показать payload, ничего не отправлять")
    args = parser.parse_args()

    load_env()
    url = os.environ.get("OPENWEBUI_URL", "http://localhost:3000")
    key = os.environ.get("OPENWEBUI_API_KEY", "")

    if args.export:
        if not key:
            sys.exit("Нужен OPENWEBUI_API_KEY в .env")
        print(json.dumps(call_api(url, key, "/api/v1/models/export"),
                         ensure_ascii=False, indent=2))
        return

    models = collect_models()

    if args.dry_run:
        print(json.dumps({"models": models}, ensure_ascii=False, indent=2))
        print(f"\n[dry-run] {len(models)} персон, ничего не отправлено",
              file=sys.stderr)
        return

    if not key:
        sys.exit("Нужен OPENWEBUI_API_KEY в .env (админский ключ)")

    endpoint = "/api/v1/models/sync" if args.prune else "/api/v1/models/import"
    call_api(url, key, endpoint, {"models": models}, method="POST")

    mode = "sync (с удалением лишнего)" if args.prune else "import (аддитивно)"
    print(f"Готово: {len(models)} персон через {mode}")
    for model in models:
        print(f"  - {model['id']} -> {model['base_model_id']}")


if __name__ == "__main__":
    main()
