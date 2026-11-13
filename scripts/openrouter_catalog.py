"""
Каталог моделей OpenRouter для шлюза: разворачивает openrouter/* из litellm/config.yaml в список моделей.

LiteLLM сам не отдаёт каталог OpenRouter в /v1/models, поэтому gateway-config.py и sync-agents.py
берут его отсюда. Только stdlib: sync-agents.py запускается системным python3.
Без сети берётся последний сохранённый список из build/litellm/openrouter-models.json.
"""

import json
import pathlib
import urllib.request

URL = "https://openrouter.ai/api/v1/models"
CACHE = pathlib.Path(__file__).resolve().parent.parent / "build" / "litellm" / "openrouter-models.json"


def catalog():
    """[{id, context, output, tools}] или None, если нет ни сети, ни сохранённого списка."""
    try:
        with urllib.request.urlopen(URL, timeout=15) as response:
            data = json.load(response)["data"]
        models = []
        for item in data:
            top = item.get("top_provider") or {}
            models.append({
                "id": item["id"],
                "context": item.get("context_length") or top.get("context_length"),
                "output": top.get("max_completion_tokens"),
                "tools": "tools" in (item.get("supported_parameters") or []),
            })
        models.sort(key=lambda model: model["id"])
        CACHE.parent.mkdir(parents=True, exist_ok=True)
        CACHE.write_text(json.dumps(models, indent=1), encoding="utf-8")
        return models
    except (OSError, ValueError, KeyError):
        if CACHE.exists():
            return json.loads(CACHE.read_text(encoding="utf-8"))
        return None


def is_wildcard(model_name, model):
    return model_name.endswith("/*") and model.startswith("openrouter/")
