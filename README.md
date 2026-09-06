# ai-workspace

Локальное AI-окружение с подменяемыми провайдерами моделей.

## Обзор

Два интерфейса — Open WebUI для чатов, OpenCode для агентных задач — обращаются к общему шлюзу LiteLLM. Шлюз маршрутизирует запросы на облачные или локальные модели.


![Architecture](docs/architecture.png)


Смена провайдера — правка одного YAML. Интерфейсы не затрагиваются.

## Состав

| Сервис | Порт | Роль |
|---|---|---|
| Open WebUI | 3000 | чаты, персоны |
| LiteLLM | 4000 | шлюз, маршрутизация |
| mcpo | 8000 | MCP через OpenAPI |
| Ollama | 11434 | локальный инференс, нативно |

Ollama ставится вне Docker. В контейнере на macOS нет доступа к Metal.

## Установка

```bash
git clone <repo> && cd ai-workspace
./bootstrap.sh
```

Скрипт создаёт `.env` и завершается. Заполни ключи, запусти снова:

```bash
./bootstrap.sh full
```

Профили: `full` (48 ГБ), `light` (16–32 ГБ), `cloud` (без локальных моделей).

Затем создай аккаунт в Open WebUI, получи API-ключ в Settings → Account, добавь в `.env`, синхронизируй персоны:

```bash
python3 scripts/sync-personas.py
```

## Структура

```
ai-workspace/
├── docker-compose.yml
├── bootstrap.sh
├── litellm/config.yaml      алиасы моделей, fallback
├── prompts/                 персоны Open WebUI
├── prompts.local/           персоны, не в git
├── opencode/
│   ├── opencode.jsonc       провайдер, не в git
│   ├── agent/               агенты
│   ├── skill/               скиллы
│   └── skill.local/         скиллы, не в git
├── mcpo/config.json         MCP-серверы
├── scripts/
│   ├── sync-personas.py
│   ├── backup.sh
│   └── restore.sh
└── data/                    база Open WebUI, не в git
```

## Алиасы моделей

Персоны и агенты ссылаются на алиас, а не на модель:

```yaml
model_list:
  - model_name: qwen-coder-local
    litellm_params:
      model: ollama_chat/qwen3-coder:30b
      api_base: os.environ/OLLAMA_HOST_URL
```

Схема имён: `модель-роль-место`. Например `qwen-coder-cloud-free`, `qwen-chat-local`.

Замена модели за алиасом не требует правки персон:

```bash
ollama pull qwen4:30b
# изменить model: в litellm/config.yaml
docker compose restart litellm
```

## Fallback

```yaml
router_settings:
  fallbacks:
    - laguna-coder-cloud-free: ["qwen-coder-cloud-free", "qwen-chat-local"]
    - qwen-coder-cloud-free: ["qwen-coder-local", "qwen-chat-local"]
```

Срабатывает на любую ошибку провайдера: исчерпанный лимит, нехватку кредитов, отозванный ключ, отсутствие сети.

## Персоны

Чат с системным промптом и заданной моделью. Файл в `prompts/`:

```markdown
---
id: algo-coach
name: Тренер по задачам
base: qwen-coder-cloud-free
temperature: 0.3
---
Системный промпт.
```

Обязательные поля: `id`, `name`, `base`.

```bash
python3 scripts/sync-personas.py           # добавить и обновить
python3 scripts/sync-personas.py --prune   # удалить отсутствующие в файлах
python3 scripts/sync-personas.py --dry-run # показать payload
```

Git — источник правды. Правки в интерфейсе перезаписываются.

## Агенты и скиллы

Только OpenCode.

**Агент** — системный промпт, модель и права доступа. Файл в `opencode/agent/`:

```markdown
---
description: Ревью кода
mode: subagent
model: gateway/laguna-coder-cloud-free
tools:
  write: false
  edit: false
---
Инструкция.
```

Режимы: `primary` (выбирается для сессии), `subagent` (вызывается через `@имя`), `all`.

**Скилл** — процедура, подключаемая моделью при совпадении с описанием. Папка в `opencode/skill/` с файлом `SKILL.md`:

```markdown
---
name: run-tests
description: Использовать когда нужно запустить тесты или разобрать падение
---
Инструкция.
```

Модель постоянно видит только `description`. Тело подгружается при срабатывании.

Изменения применяются после перезапуска OpenCode.

## Публичное и приватное

| Путь | В git |
|---|---|
| `prompts/`, `opencode/skill/` | да |
| `prompts.local/`, `opencode/skill.local/` | нет |
| `.env`, `data/` | нет |

Конфиги содержат ссылки на переменные окружения, не значения. Репозиторий публикуем как есть.

## Бэкапы

История чатов не версионируется — это SQLite в `data/`.

```bash
./scripts/backup.sh                  # в ~/Backups/ai-workspace
./scripts/restore.sh <архив.tar.gz>
```

Cron в 3:00, хранится 14 копий. Кэш моделей исключён.
