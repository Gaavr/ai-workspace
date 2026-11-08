# Design

## OpenCode без Node
`opencode-ai` — обёртка, сам OpenCode — скомпилированный бинарник в пакете
`opencode-darwin-arm64`. В комплект идут оба `.tgz` (`npm pack`) и бинарник отдельно:
на машине без Node достаточно положить его в `PATH`.

## LiteLLM без PyPI
- `requirements.lock` — `uv pip freeze` из `build/litellm-venv`.
- Колёса — `pip wheel --no-deps -r requirements.lock` в `python/wheels/`: готовые колёса
  берутся как есть, пакеты только с исходниками собираются. Pip для этого — отдельный
  venv `build/kit-pip` на том же Python 3.12.
- Python — сборка python-build-standalone, которую уже скачал `uv`, архивом
  в `python/cpython/`. Сборки переносимы, поэтому установка просто распаковывает архив
  в `build/python/` и создаёт venv на нём. Зеркало для `uv python install`, как планировалось,
  не нужно: оно требует раскладки релизов GitHub, а архив проще и проверяется тем же SHA-256.
- `uv` — колесо в `python/uv/`. Установка достаёт бинарник из колеса `unzip`-ом:
  на чистом Mac системного Python может не быть.
- Установка без сети: `UV_OFFLINE=1`, `uv pip install --no-index --find-links python/wheels
  -r requirements.lock`. Проверено с пустым кешем `uv`.

## Где включается комплект
`gateway.sh` спрашивает `kit.sh has-litellm` (путь — `AI_KIT`, по умолчанию на SSD). Есть колёса —
ставит через `kit.sh install-litellm`, не встало или комплекта нет — из сети, как раньше. Порядок «комплект первым» делает установку
воспроизводимой и заодно проверяет комплект при каждой установке.

## Свежесть
`kit.sh refresh` пересобирает только то, у чего поменялась версия, и переписывает `MANIFEST`.
`kit.sh check` пересчитывает SHA-256 и называет расхождения. Запускать после обновления
OpenCode или LiteLLM.

## Риски
- Сборка CPython от `uv` зависит от версии `uv`: в `MANIFEST` пишутся обе.
- Колёса под macOS 14+ arm64. Для другой архитектуры комплект не годится — это записано
  в `README.md` комплекта.
