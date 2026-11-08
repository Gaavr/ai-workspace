#!/usr/bin/env python3
"""
Конфиг, на котором стартует шлюз: litellm/config.yaml без алиасов, у которых пуст ключ.

Алиас выпадает, если его api_key ссылается на os.environ/<VAR>, а VAR в окружении пуста.
Вместе с ним из fallbacks уходят ссылки на него. То же правило у sync-agents.py для OpenCode.

Запускает gateway.sh из build/litellm-venv (там есть PyYAML), окружение — уже с .env:
    gateway-config.py litellm/config.yaml build/litellm/config.yaml
"""

import os
import pathlib
import sys

import yaml


def empty_key(model):
    key = model.get("litellm_params", {}).get("api_key")
    if isinstance(key, str) and key.startswith("os.environ/"):
        name = key.split("/", 1)[1]
        if not os.environ.get(name):
            return name
    return None


def main():
    src, dst = map(pathlib.Path, sys.argv[1:3])
    config = yaml.safe_load(src.read_text(encoding="utf-8"))

    dropped = {}
    kept = []
    for model in config.get("model_list", []):
        name = empty_key(model)
        if name:
            dropped[model["model_name"]] = name
        else:
            kept.append(model)
    config["model_list"] = kept

    router = config.get("router_settings") or {}
    chains = []
    for entry in router.get("fallbacks", []):
        for alias, targets in entry.items():
            if alias in dropped:
                continue
            targets = [t for t in targets if t not in dropped]
            if targets:
                chains.append({alias: targets})
    if "fallbacks" in router:
        router["fallbacks"] = chains

    for alias, var in dropped.items():
        print(f"  {alias}: выключен, в .env пусто: {var}")

    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.write_text(yaml.safe_dump(config, allow_unicode=True, sort_keys=False), encoding="utf-8")


if __name__ == "__main__":
    main()
