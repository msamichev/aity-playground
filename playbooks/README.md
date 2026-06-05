# Playbooks — универсальные процедуры команд

> Этот каталог — **источник правды** для всех команд методологии. Читается **любым AI**, не только Claude.

## Двухуровневая архитектура команд

```
┌─────────────────────────────────────────────────────────────┐
│ playbooks/<name>.md   ← Источник правды (обычный Markdown)  │
│   • полная процедура                                        │
│   • читается любым AI: Claude, Codex, DeepSeek, Minimax,    │
│     Cursor, Gemini, Aider, и т.д.                           │
│   • триггерные фразы — в таблице в AGENTS.md                │
└───────────────────┬─────────────────────────────────────────┘
                    │ ссылается на
                    ▼
┌─────────────────────────────────────────────────────────────┐
│ .claude/skills/<name>/SKILL.md   ← Тонкая обёртка для Claude│
│   • YAML frontmatter с длинным description (авто-триггер)   │
│   • тело: «открой playbooks/<name>.md и выполни»            │
│   • НЕ дублирует содержимое — только указатель              │
└─────────────────────────────────────────────────────────────┘
```

**Идея:** контент один. Claude Code получает приятный авто-триггер по семантике через `description` в YAML. Другие AI читают `AGENTS.md` → видят таблицу триггеров → открывают нужный playbook напрямую.

## Список playbooks

Порядок отражает типовой жизненный цикл: фазовые переходы → пред-фазная проверка → повседневная работа → утилиты.

| Имя | Что делает |
|---|---|
| [init-project.md](init-project.md) | Phase 0: однократная инициализация при старте проекта. В конце запускает `/doctor`. |
| [adopt-architecture.md](adopt-architecture.md) | Phase 0.5: архитектурные развилки → ADR. В конце запускает `/skills-suggest`. |
| [adopt-stack.md](adopt-stack.md) | Phase 0 → Phase 1: материализация структуры кода под выбранный стек. В конце запускает `/doctor` и `/skills-suggest`. |
| [doctor.md](doctor.md) | **Фазно-осознанная** пред-фазная проверка окружения: CLI / MCP / runtimes / skills под текущую фазу + конфликты + команды установки. Главная команда серии. |
| [skills-suggest.md](skills-suggest.md) | Фокусированный разбор **только по skills** (детально под фазу + стек, с конфликтами и альтернативами). |
| [skills-audit.md](skills-audit.md) | Раз в месяц: какие установленные skills реально использовались, что удалить. |
| [plan.md](plan.md) | Создать план фичи. **Шаг 0** запускает `/doctor` под `phase-2-feature` как pre-feature чек. |
| [full-ahead.md](full-ahead.md) | «Полный вперёд» — autonomous progression: `ci-push.sh` (Push-уровень) → fix loop → commit → push в feature-ветку. Self-review читается только перед `/open-mr`, не на каждом checkpoint push. В autonomous mode добавляется four-gate review через subagents (code-reviewer, test-runner, security-auditor, merge-coordinator). Deep-проверки — в GitLab CI nightly. |
| [autonomous-mode.md](autonomous-mode.md) | Включает/настраивает autonomous mode: front-loaded clarification в `/plan`, four-gate review в `/full-ahead`, Stop hook чеклист. Опционально, opt-in через флаг в AGENTS.md §0. |
| [autopilot.md](autopilot.md) | Автономное выполнение многофазного плана **в своей feature-ветке**: код → four-gate + `/critic` → при предметном опасении сверка с интернетом → **коммит фазы с `Refs:`, без push** → журнал прогона. Вопросы только на старте, на тупике — стоп с отчётом. Push/MR — ручной шаг (`/open-mr`). Полный набор предохранителей (`autopilot-preflight.sh` + проверка ветки). |
| [save.md](save.md) | Локальный коммит без push. |
| [save-all.md](save-all.md) | Коммит + push в текущую feature-ветку (push в `main` запрещён); требует зелёного `scripts/ci-push.sh`. |
| [self-review.md](self-review.md) | 7-пунктный смысловой чек-лист перед `/open-mr` (без триггера; обязательное pre-MR правило AGENTS.md §5 п.10; дополняет `merge-coordinator` subagent). |
| [release.md](release.md) | Финализация версии методологии: bump `VERSION`, `[Unreleased]` → `[X.Y.Z]` в `CHANGELOG.md`, при MINOR/MAJOR — черновик migration guide. Уровень подтверждается пользователем. Не пушит. |
| [adr.md](adr.md) | Записать архитектурное решение. |
| [retro.md](retro.md) | Ретроспектива сессии. |
| [sync-idea.md](sync-idea.md) | Подтянуть новые материалы из `inbox/` в `docs/idea/` и `docs/architecture/`. |
| [critic.md](critic.md) | Раскритиковать план с 4 ролей (skeptic, security, devil's advocate, simplifier). |
| [week-plan.md](week-plan.md) | План на ISO-неделю, ≤5 ключевых результатов. |
| [check-links.md](check-links.md) | Отчёт по графу связей. |

## Как другие AI пользуются playbook'ами

Подробное описание совместимости — в [METHODOLOGY.md «Совместимость с другими AI и IDE»](../METHODOLOGY.md#10-совместимость-с-другими-ai-и-ide). Ниже — практические рецепты для копирования.

### Codex CLI / Gemini CLI / Aider — из коробки

Эти инструменты читают `AGENTS.md` как часть открытого стандарта. **Ничего настраивать не надо** — заработают сразу.

### Cursor — рецепт настройки

Cursor читает `.cursor/rules/*.mdc`. Сделай обёртки по аналогии с `.claude/skills/`:

```bash
mkdir -p .cursor/rules

# Пример обёртки для /init-project
cat > .cursor/rules/init-project.mdc <<'EOF'
---
description: Initialize a new project from the seed methodology. Use when the user says "инициализируй проект", "init project", "/init-project", or has just copied methodology-seed into a fresh repo.
alwaysApply: false
---

См. процедуру в [playbooks/init-project.md](../../playbooks/init-project.md). Выполни её пошагово.
EOF
```

Повтори для остальных 11 команд — description бери из соответствующего `.claude/skills/<name>/SKILL.md`.

**Скрипт-автоматизация:**

В seed входит готовый генератор [`scripts/gen-cursor-rules.sh`](../scripts/gen-cursor-rules.sh). Использование:

```bash
# Сгенерировать все обёртки одной командой:
scripts/gen-cursor-rules.sh

# Проверить, что .cursor/rules/ синхронизирован с .claude/skills/ (для CI):
scripts/gen-cursor-rules.sh --check
```

Скрипт читает YAML frontmatter каждого `.claude/skills/<name>/SKILL.md` и генерирует соответствующий `.cursor/rules/<name>.mdc`. Контент playbook'а не дублируется — Cursor открывает `playbooks/<name>.md` по ссылке из обёртки.

Папка `.cursor/rules/` **не входит в seed по умолчанию** — она генерируется однократно (или при добавлении нового skill).

### GitHub Copilot Workspace — рецепт настройки

GitHub Copilot Workspace, Copilot Chat и Copilot Code Review автоматически читают `.github/copilot-instructions.md` в корне репозитория. Этот файл — один свободный markdown с инструкциями для AI (overview проекта, правила, безопасность, команды). В отличие от Claude Code skills и Cursor rules с path-scoping — Copilot Workspace не поддерживает auto-trigger по семантике, работает по статическим инструкциям.

В seed входит готовый генератор [`scripts/gen-copilot-instructions.sh`](../scripts/gen-copilot-instructions.sh). Использование:

```bash
# Сгенерировать / обновить .github/copilot-instructions.md из AGENTS.md:
scripts/gen-copilot-instructions.sh

# Проверить актуальность (для CI / pre-commit):
scripts/gen-copilot-instructions.sh --check
```

Скрипт парсит ключевые секции `AGENTS.md` (§0 Project one-liner, §5 Правила работы AI, §4.4 Безопасность, §6 Команды) и собирает один производный markdown с шапкой «AUTOGENERATED — не редактируй». Источник правды — `AGENTS.md`.

Файл `.github/copilot-instructions.md` **не входит в seed по умолчанию** — генерируется однократно (или при изменении AGENTS.md). По аналогии с `.cursor/rules/`.

### Claude Code `@-imports` (опциональное расширение)

Claude Code поддерживает синтаксис `@path/to/file.md` внутри `CLAUDE.md`. При чтении Claude автоматически инлайнит содержимое указанного файла. Это позволяет держать `CLAUDE.md` компактным (Anthropic best practices: «bloated CLAUDE.md → Claude ignores half of it»), а тяжёлые секции выносить в отдельные `docs/`-файлы.

**Когда использовать.** Если `AGENTS.md` (и его симлинк `CLAUDE.md`) приближается к 300 строкам — пора выносить. **Сейчас в seed `AGENTS.md` 256 строк (≤300 — в рамках)**, поэтому методология не вкладывает @-imports по умолчанию. Триггер для применения у себя: 280+ строк. В команде это вероятнее произойдёт раньше, чем у соло (больше правил, больше команд).

**Что выносить (приоритет по «отсечь сразу видимый рост»):**

1. **§6 «Триггерные команды»** — большая таблица команд. Дубликат уже есть в [`playbooks/README.md`](README.md), можно ссылаться на него.
2. **§4.4 «Безопасность»** — если у вас в проекте появятся специфичные правила (OWASP LLM Top 10, политики secrets, корпоративные compliance-требования) — вынести в `docs/security-rules.md`.
3. **§2 «Карта проекта»** — статическая, редко меняется после `/adopt-stack`. Хороший кандидат для выноса.
4. **§6.1 «Autonomous mode (опция)»** — если в команде autonomous mode активно используется — расширенная конфигурация может вынестись отдельно.

**Как применить, не ломая cross-vendor:**

**Вариант А (рекомендуется)** — обычные markdown-ссылки в `AGENTS.md`, **без** `@-imports`:

```markdown
## 6. Триггерные команды

Полный список и описания — в [`playbooks/README.md`](playbooks/README.md).
Краткие триггеры:
- `/full-ahead` — полный цикл CI + push в feature-ветку.
- `/open-mr` — Merge Request в main.
- ...
```

Не-Claude AI (Codex, Cursor, Aider, Copilot) открывают ссылку и читают — это работает везде. Claude тоже читает. **Cross-vendor совместимость сохраняется.**

**Вариант Б (Claude-only усиление)** — `@-imports` в `CLAUDE.md` после расщепления с `AGENTS.md`:

1. Удалить симлинк `CLAUDE.md → AGENTS.md`.
2. `CLAUDE.md` — новый отдельный файл, начинающийся с `@AGENTS.md` + `@docs/security-rules.md` + другие @-imports.
3. `scripts/sync-claude-md.sh` — отключить или переписать.

Минус: Claude получает **больше контекста** через @-imports, чем разработчики на Codex/Cursor/Copilot. Это **сознательное** Claude-усиление, не баг — обсудить с командой как принципиальное решение, желательно через ADR.

**Рекомендация методологии:** оставайся на Варианте А, пока не упрёшься в 300 строк. Вариант Б — только если **вся команда** на Claude Code и cross-vendor больше не приоритет.

### aider — рецепт

В корне проекта создай `.aider.conf.yml`:

```yaml
read:
  - AGENTS.md
  - METHODOLOGY.md

# Опционально — добавь часто используемые playbooks как read-only context
# read:
#   - playbooks/full-ahead.md
#   - playbooks/save-all.md
```

aider автоматически прочитает AGENTS.md в начале каждой сессии. Когда говоришь триггерную фразу — он находит её в таблице §6 и открывает playbook.

### Continue.dev — рецепт

В `.continue/config.yaml` добавь:

```yaml
systemMessage: |
  Это проект на методологии methodology-seed. Прочитай AGENTS.md в начале сессии.
  Команды и их триггеры — в AGENTS.md §6, открывай соответствующие playbooks/<name>.md по запросу.

contextProviders:
  - name: file
    params: {}
```

### DeepSeek / Minimax / GLM / Qwen и другие чат-LLM без CLI

**Вариант 1 — ручной:**

1. В начале сессии вставь содержимое `AGENTS.md` в системный промпт или первое сообщение.
2. Скажи: «Когда увидишь триггерную фразу из §6 — попроси меня дать содержимое нужного playbook'а».
3. По мере работы вставляй файлы по запросу AI.

**Вариант 2 — через клиент-оркестратор:**

Используй aider, continue.dev или cline с этой моделью как backend. Они умеют работать с любым OpenAI-compatible API и читают файлы проекта сами.

Пример конфига aider под DeepSeek:

```bash
aider --model deepseek/deepseek-coder \
      --openai-api-base https://api.deepseek.com/v1 \
      --openai-api-key $DEEPSEEK_API_KEY
```

### Что не получится без Claude Code

- **Авто-триггер по семантике** — у других AI триггер ловится только по точному совпадению фразы или явной `/команде`.
- **Bypass Permissions** — Claude-only.
- **Auto-memory** в формате Claude — у каждого AI свой механизм памяти.

Всё критичное (граф знаний, проверки качества, документы) работает одинаково везде.

## Правила при редактировании

- **Меняй контент только в playbook'е.** Тонкая обёртка в `.claude/skills/` не содержит логики — она просто ссылка.
- **Если меняешь триггерные фразы** — обнови:
  1. `description` в `.claude/skills/<name>/SKILL.md` (это работает для Claude Code).
  2. Таблицу триггеров в `AGENTS.md §6` (это работает для всех остальных AI).
- **Имена файлов playbook'ов** — kebab-case, совпадают с именем skill (без префикса `/`).

## Связки

- [../AGENTS.md](../AGENTS.md) — таблица триггеров для всех AI
- [../METHODOLOGY.md](../METHODOLOGY.md) §6 — описание двухуровневой архитектуры
- [../.claude/skills/](../.claude/skills/) — тонкие обёртки для Claude Code
