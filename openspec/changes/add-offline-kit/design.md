# Design

## OpenCode без Node
`opencode-ai` — обёртка, сам OpenCode — скомпилированный бинарник в пакете
`opencode-darwin-arm64`. В комплект идут оба `.tgz` (`npm pack`) и бинарник отдельно:
на машине без Node достаточно положить его в `PATH`.

## LiteLLM без PyPI
- `requirements.lock` — `uv pip freeze` из `build/litellm-venv`.
- Колёса — `pip download -r requirements.lock --only-binary=:all: --python-version 3.12
  --platform macosx_14_0_arm64` в `python/wheels/`.
- Python — сборка, которую `uv` уже скачал (`uv python dir`), архивом в `python/cpython/`.
- Установка без сети: `UV_PYTHON_INSTALL_MIRROR=file://…/python/cpython`,
  `uv pip install --no-index --find-links python/wheels -r requirements.lock`.

## Где включается комплект
`gateway.sh install` смотрит `AI_KIT` (по умолчанию путь на SSD). Есть `python/wheels` —
ставит из комплекта, нет — из сети, как сейчас. Порядок «комплект первым» делает установку
воспроизводимой и заодно проверяет комплект при каждой установке.

## Свежесть
`kit.sh refresh` пересобирает только то, у чего поменялась версия, и переписывает `MANIFEST`.
`kit.sh check` пересчитывает SHA-256 и называет расхождения. Запускать после обновления
OpenCode или LiteLLM.

## Риски
- Сборка CPython от `uv` зависит от версии `uv`: в `MANIFEST` пишутся обе.
- Колёса под macOS 14+ arm64. Для другой архитектуры комплект не годится — это записано
  в `README.md` комплекта.
