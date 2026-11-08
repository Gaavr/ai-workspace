# Tasks

## 1. Ollama
- [x] 1.1 Скачать `ollama-darwin.tgz` v0.40.15 (186 МБ) с GitHub releases в
      `ai-workspace-kit/installers/`, сверить SHA-256 с `sha256sum.txt` релиза.
- [x] 1.2 Распаковать в `ai-workspace-kit/runtime/ollama/v0.40.15/`.
- [x] 1.3 `scripts/ollama.sh start|stop|status`: `OLLAMA_MODELS` на SSD, порт 11434,
      без тома SSD — предупреждение и выход без ошибки.
- [x] 1.4 `.env.example`: `AI_SSD`, `AI_KIT`, `OLLAMA_HOST_URL=http://localhost:11434`.
- [x] 1.5 `gateway.sh start|stop` поднимает и гасит Ollama вместе со шлюзом.

## 2. Модель
- [x] 2.1 `Modelfile` в `litellm/ollama/gpt-oss-20b.Modelfile`: GGUF с SSD, `num_ctx 16384`.
- [x] 2.2 `ollama create gpt-oss-20b-ssd`; проверить вызов инструмента напрямую через Ollama.
- [x] 2.3 Инструменты не вызываются — спросить владельца про `ollama pull gpt-oss:20b` (~13 ГБ).
      Не понадобилось: импорт из GGUF вызывает инструменты (17 ток/с, 91% на GPU).

## 3. Шлюз
- [x] 3.1 Алиас `gpt-oss-coder-local` с `model_info` (16384 / 4096).
- [x] 3.2 Все цепочки fallback заканчиваются на `gpt-oss-coder-local`.
- [x] 3.3 `sync-agents.py`, `gateway/gpt-oss-coder-local` виден в OpenCode.

## 4. Без LM Studio
- [x] 4.1 Скачать `LM-Studio-0.4.28-2-arm64.dmg` (573 МБ) в `ai-workspace-kit/installers/`.
- [x] 4.2 Попытка поставить запасным: на загрузке gpt-oss-20b Mac завис (`mlock`, `--parallel 4`).
      Решение владельца — убрать: приложение, `~/.lmstudio`, настройки — в корзину,
      строка `PATH` из `~/.zshrc` убрана. Установщик остаётся в комплекте.
- [x] 4.3 Алиаса LM Studio и `LMSTUDIO_HOST_URL` нет в конфигах.
- [x] 4.4 Старые LM Studio 0.3.16, 0.3.35 и Ollama.app 0.6.8 — в корзину.

## 5. Проверка
- [x] 5.1 `openspec validate add-local-models --strict`.
- [x] 5.2 `oc.sh run --agent lead -m gateway/gpt-oss-coder-local` — ответ и вызов инструмента.
- [x] 5.3 Персона `algo-coach` на локальной модели.
      Роль держит слабее облачной: готового кода нет, но псевдокод — сразу, а не третьей подсказкой.
- [x] 5.4 Временный шлюз с мёртвыми бесплатными алиасами → ответ от локальной.
- [x] 5.5 Без SSD: шлюз стартует, предупреждение про локальные модели.
- [x] 5.6 Память при работе агента на локальной модели: свободно не меньше 1 ГБ, система отвечает.
      Сторож `kern.memorystatus_level`: минимум 6% (~1 ГБ) за все прогоны, не срабатывал.
- [x] 5.7 README: локальные модели, память, без SSD.
