# Expected Tools

> Каталог инструментов, которые `/doctor` ожидает увидеть установленными.
> **Редактируется руками.** `/doctor` читает этот файл и проверяет каждый пункт.

---

## Категория: required (без них методология не работает)

<!-- expected-required-start -->
- `git` — система контроля версий. Установка: уже стоит на всех современных машинах разработчика. Проверка: `git --version`
- `node` — Node.js (≥18.0). Нужен для запуска генераторов и многих скриптов. Установка: https://nodejs.org/ или `nvm install 20`
- `pre-commit` — фреймворк pre-commit hooks. **Установка (предпочтительно):** `pipx install pre-commit` (macOS/Linux: `brew install pipx` или `apt install pipx` сначала). **Альтернативы:** `brew install pre-commit` (macOS), `pip install --user pre-commit` (тогда добавь `~/.local/bin` в `PATH`). **После установки — обязательно три команды активации:** `pre-commit install && pre-commit install --hook-type commit-msg && pre-commit install --hook-type pre-push`. **Why pipx:** стандарт для Python CLI tools — изолированное окружение, бинарь всегда в `PATH` без активации virtualenv. Решает типичную ловушку `pip --user`, когда бинарь оказывается в `~/Library/Python/<ver>/bin/` вне PATH. **Why три `--hook-type`:** в `.pre-commit-config.yaml` определены три stage — default (lint/format/secrets), `commit-msg` (conventional-commits), `pre-push` (pre-push-guard). Без всех трёх `--hook-type` хуки на `commit-msg` и `pre-push` **молча не активируются**, и проверки уходят в фоновую тишину. `/doctor` проверяет факт активации (наличие `.git/hooks/pre-commit`, `.git/hooks/commit-msg`, `.git/hooks/pre-push`), а не только наличие бинаря.
- `gitleaks` — поиск секретов в коде. Установка: `brew install gitleaks` (macOS), `apt install gitleaks` (Linux), https://github.com/gitleaks/gitleaks/releases (Windows). **Why (помимо pre-commit hook):** pre-commit-хук `gitleaks/gitleaks` скачивает свой бинарь в кэш и проверяет **только staged-файлы**. Системный CLI нужен для разовых проверок до коммита: `gitleaks detect --source=inbox/ --no-banner` перед разбором содержимого `inbox/` (импортированные чаты с LLM часто содержат API-ключи, токены, фрагменты `.env`). Pre-commit это не ловит, потому что `inbox/` обычно в `.gitignore` или содержимое не staged.
<!-- expected-required-end -->

## Категория: recommended (хорошо иметь)

<!-- expected-recommended-start -->
- `gh` — GitHub CLI. Установка: `brew install gh`, `apt install gh`, https://cli.github.com/. Полезно для PR (если когда-то перейдёшь с push-to-main), issues, repo-операций.
- `ctx7` — Context7 CLI для актуальной документации библиотек. Установка: `npm install -g ctx7` или использовать через `npx -y ctx7`. **Важно:** free tier — 1000 запросов/месяц + 60/час, используй осознанно. Альтернатива MCP-режиму: `claude mcp add context7 -- npx -y @upstash/context7-mcp@latest`. **Conflicts with:** MCP `context7` (выбирать одно — CLI дешевле по токенам).
- `shellcheck` — статический анализ shell-скриптов. Установка: `brew install shellcheck`, `apt install shellcheck`. **Why:** pre-commit-хук `shellcheck-py` ловит то же самое в коммите, но системный CLI удобен для двух кейсов — (1) правка shell-скриптов методологии (`scripts/validate-links.sh`, `pre-push-guard.sh`, `sync-claude-md.sh`, и т.п.) с IDE-интеграцией на лету; (2) ручной прогон **до `/adopt-stack`** при правках seed-скриптов и **после `/adopt-stack`**, когда сгенерированы стек-специфичные обёртки (`local-ci.sh`, CI-shell-скрипты) — проверить их до первого коммита, а не ждать pre-commit'а.
- `hadolint` — линтер Dockerfile (если работаешь с Docker). Установка: `brew install hadolint`.
- `semgrep` — кросс-языковой SAST с custom-rules. Установка: `pip install semgrep` (или `brew install semgrep`). **Why:** ловит deserialization-CVE (pickle/yaml/eval/exec/subprocess shell=True), которые часто генерирует AI (CVE-2025-62373 Pipecat pickle RCE, CVE-2025-1716 picklescan bypass). Запускается в `scripts/ci-push.sh` Шаг 2 рядом с `gitleaks` с конфигами `p/security-audit` + `p/insecure-deserialization` (только severity ERROR). В команде локально — первая линия защиты, server-side в GitLab CI MR-pipeline — вторая. Если не установлен — шаг пропускается с подсказкой; для расширенной защиты установить рекомендуется (см. [ADR-1500](https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260522-1500-security-auditor-owasp-llm-top10-and-semgrep.md)). **Conflicts with:** ничем (дополняет `gitleaks` и stack-специфичный `bandit`/`gosec`).
- `jscpd` — кросс-языковой Copy/Paste Detector. Установка: `npm install -g jscpd` (или `pip install jscpd-py`). **Why:** документированная AI-патология — GitClear 2024 фиксирует 8x рост дубликатов от AI и -44% YoY доли рефакторинга. В команде дубликаты особенно вредны: рефакторить чужой код после squash merge дороже, чем переиспользовать существующий хелпер сразу. Запускается в `scripts/ci-push.sh` Шаг 5 с `--threshold 5 --gitignore`. Если не установлен — шаг пропускается; `/adopt-stack` сможет заменить на стек-релевантный (`dupl` для Go, `pmd-cpd` для Java, `pylint --enable=duplicate-code` для Python). См. [ADR-1530](https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260522-1530-ci-push-code-clone-defense-against-ai-duplication.md). **Conflicts with:** ничем.
<!-- expected-recommended-end -->

## Категория: contextual (под выбранный стек, заполняется на /adopt-stack)

<!-- expected-contextual-start -->
<!-- /adopt-stack добавляет сюда стек-специфичные требования.
     До /adopt-stack — список пуст.

     Примеры что может добавиться:
     - docker (если деплой через Docker)
     - kubectl (если k8s)
     - psql / mysql (если SQL БД)
     - python (если бэк на Python)
     - go (если на Go)
     - dotnet (если на .NET)
     - и т.д.
-->
<!-- expected-contextual-end -->

## MCP servers (опционально)

<!-- expected-mcp-start -->
- `context7` — актуальная документация библиотек. **По умолчанию НЕ устанавливаем как MCP** — есть CLI-альтернатива `ctx7`, которая дешевле по токенам. MCP-режим имеет смысл, если активно используешь и платный тариф. Установка MCP: `claude mcp add context7 -- npx -y @upstash/context7-mcp@latest`. **Conflicts with:** `ctx7` CLI (выбирать одно).
<!-- expected-mcp-end -->

---

## Категории по фазам (фильтруются `/doctor`)

Существующие категории выше (`required` / `recommended` / `contextual` / `mcp`) — **глобальные**, применимы всегда. Категории ниже — **фазно-зависимые**: `/doctor` показывает только секции, релевантные текущей фазе проекта.

**Правило:** один инструмент = одна секция. Не дублируй между `required` и `phase-1`. Если инструмент нужен сразу со старта проекта — `required`. Если только начиная с конкретной фазы — соответствующая `phase-X`.

### Фаза 0 (Discovery, нет кода)

<!-- expected-phase-0-start -->
<!-- На этой фазе обычно достаточно required + recommended выше. Секция может оставаться пустой. -->
<!-- expected-phase-0-end -->

### Фаза 0.5 (Architecture Adoption)

<!-- expected-phase-0.5-start -->
- `@mermaid-js/mermaid-cli` (опционально) — локальный рендер C4-диаграмм из `docs/architecture/overview.md`. Установка: `npm install -g @mermaid-js/mermaid-cli`. **Why:** позволяет проверить диаграмму до коммита, GitHub Markdown тоже её отрендерит, но локально удобнее итерироваться.
<!-- expected-phase-0.5-end -->

### Фаза 1 (Stack Adoption)

<!-- expected-phase-1-start -->
<!-- Конкретный стек-специфичный список заполняется командой /adopt-stack
     (там же, где заполняется `expected-contextual`). Эта секция — для инструментов,
     релевантных самому моменту adopt-stack, до выбора языка:

     - `cookiecutter` (опционально) — если будешь использовать готовые шаблоны структуры
     - `tree-sitter` (опционально) — если планируется анализ кода скриптами

     По умолчанию пуста. -->
<!-- expected-phase-1-end -->

### Фаза 2-feature (новая фича в Steady state)

<!-- expected-phase-2-feature-start -->
- `lychee` (опционально) — глубокая проверка внешних ссылок в docs. Установка: `brew install lychee` (macOS), `cargo install lychee` (cross-platform). **Why:** при правке документации в рамках фичи стоит периодически прогонять — обычный `validate-links.sh` проверяет только локальные пути.
<!-- expected-phase-2-feature-end -->

---

## Как использовать этот файл

1. **Не редактируй** маркеры `<!-- expected-...-start -->` и `<!-- expected-...-end -->` — `/doctor` ищет их для парсинга.
2. Каждый пункт — bullet с обратными кавычками вокруг имени инструмента: `` ` ``tool``` ` ``.
3. После имени — тире и описание/команда установки.
4. Для **Required** — обязательно указывай команды установки для трёх ОС (macOS, Linux, Windows), если они разные.

### Inline-поля для фазно-осознанного `/doctor`

В **тексте описания** bullet'а можно использовать опциональные семантические поля. Они парсятся `/doctor` и попадают в соответствующие разделы отчёта:

- `**Why:** ...` — зачем этот инструмент. Идёт в раздел «Why» рядом с командой установки.
- `**Conflicts with:** X, Y` — если установлены и текущий инструмент, и X (или Y) — `/doctor` выведет предупреждение в секции «⚠️ Конфликты».
- `**Replaces:** Z` — текущий инструмент **замещает** Z. Если установлены оба — `/doctor` рекомендует оставить один.

Все три поля опциональны и могут идти в любом порядке после описания. Парсер не падает, если поле отсутствует.

**Пример:**

```markdown
- `ctx7` — Context7 CLI. Установка: `npm install -g ctx7`. **Why:** актуальная документация библиотек, экономит токены. **Conflicts with:** MCP `context7`.
```

## Связки

- [doctor playbook](../playbooks/doctor.md) — читает этот файл
- [adopt-stack playbook](../playbooks/adopt-stack.md) — добавляет в contextual после выбора стека
- [METHODOLOGY.md](../METHODOLOGY.md) §10 — MCP vs CLI
- [recommended-skills.md](recommended-skills.md) — отдельный каталог Claude skills (не CLI)
