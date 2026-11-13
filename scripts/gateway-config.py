#!/usr/bin/env python3
"""
Конфиг, на котором стартует шлюз: litellm/config.yaml без алиасов, у которых пуст ключ.

Алиас выпадает, если его api_key ссылается на os.environ/<VAR>, а VAR в окружении пуста.
Вместе с ним из fallbacks уходят ссылки на него. То же правило у sync-agents.py для OpenCode.

openrouter/* разворачивается в весь каталог OpenRouter (scripts/openrouter_catalog.py): каждая модель
под своим ID. Цепочка openrouter/* в fallbacks достаётся каждой модели каталога, у которой нет своей.

Запускает gateway.sh из build/litellm-venv (там есть PyYAML), окружение — уже с .env:
    gateway-config.py litellm/config.yaml build/litellm/config.yaml
"""

import os
import pathlib
import sys

import yaml

from openrouter_catalog import catalog, is_wildcard


def empty_key(model):
    key = model.get("litellm_params", {}).get("api_key")
    if isinstance(key, str) and key.startswith("os.environ/"):
        name = key.split("/", 1)[1]
        if not os.environ.get(name):
            return name
    return None


def expand_openrouter(models):
    """openrouter/* -> модель на каждый ID каталога. Без каталога wildcard остаётся как есть."""
    expanded, names = [], []
    for model in models:
        params = model.get("litellm_params", {})
        if not is_wildcard(model["model_name"], params.get("model", "")):
            expanded.append(model)
            continue
        found = catalog()
        if found is None:
            print("  openrouter/*: каталог недоступен и не сохранён, модели вызываются как openrouter/<id>")
            expanded.append(model)
            continue
        for item in found:
            info = {"supports_function_calling": item["tools"]}
            if item["context"]:
                info["max_input_tokens"] = item["context"]
            if item["output"]:
                info["max_output_tokens"] = item["output"]
            expanded.append({
                "model_name": item["id"],
                "litellm_params": {**params, "model": "openrouter/" + item["id"]},
                "model_info": info,
            })
            names.append(item["id"])
        print(f"  openrouter/*: {len(found)} моделей из каталога OpenRouter")
    return expanded, names


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
    config["model_list"], catalog_names = expand_openrouter(kept)

    router = config.get("router_settings") or {}
    chains = []
    for entry in router.get("fallbacks", []):
        for alias, targets in entry.items():
            if alias in dropped:
                continue
            targets = [t for t in targets if t not in dropped]
            if targets:
                chains.append({alias: targets})
    if catalog_names:
        own = {alias for chain in chains for alias in chain}
        shared = next((chain.pop("openrouter/*") for chain in chains if "openrouter/*" in chain), None)
        chains = [chain for chain in chains if chain]
        if shared:
            chains += [{name: shared} for name in catalog_names if name not in own]
    if "fallbacks" in router:
        router["fallbacks"] = chains

    for alias, var in dropped.items():
        print(f"  {alias}: выключен, в .env пусто: {var}")

    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.write_text(yaml.safe_dump(config, allow_unicode=True, sort_keys=False), encoding="utf-8")


if __name__ == "__main__":
    main()
