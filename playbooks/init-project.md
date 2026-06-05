# Init Project Playbook

> **Универсальная процедура.** Читается любым AI: Claude, Codex, DeepSeek, Minimax, Cursor, Gemini, Aider и т.п.
> **Триггер:** `/init-project` или соответствующая фраза на естественном языке (см. таблицу триггеров в [AGENTS.md](../AGENTS.md)).
> **Тонкая обёртка для Claude Code:** [.claude/skills/init-project/SKILL.md](../.claude/skills/init-project/SKILL.md).

---

Однократная инициализация нового проекта. Запускается **один раз**, в свежескопированном seed-репозитории.

## Что делает (на высоком уровне)

1. Проверяет, что фаза действительно Phase 0 (см. ниже).
2. Создаёт симлинк `CLAUDE.md → AGENTS.md` (или fallback на Windows).
3. Читает всё содержимое `inbox/` и кратко резюмирует, что там увидел.
4. Задаёт уточняющие вопросы по тем разделам `docs/idea/` и `docs/product/`, которые не получается заполнить из `inbox/`.
5. Заполняет `docs/idea/` (5 разделов) и `docs/product/` (3 файла) из обсуждений + ответов.
6. Заполняет шапку `AGENTS.md` (one-liner, product name).
7. Создаёт первый ретро-файл и первый ADR `YYYYMMDD-HHmm-bootstrap.md` со ссылками на исходные материалы.
8. Делает первый коммит (`chore: bootstrap project from methodology-seed`).

## Алгоритм пошагово

### Шаг 0. Безопасность: проверь, что это действительно первый запуск

`/init-project` запускается **только первым** разработчиком на свежескопированном seed-репо. Все последующие разработчики используют [`/onboard-developer`](onboard-developer.md), который настраивает только локальные конфиги (`CLAUDE.local.md`, `.claude/settings.local.json`), не перетирая командное.

```bash
# 1. AGENTS.md §0 не должен быть заполнен (PROJECT_NAME — плейсхолдер)
grep -q '<PROJECT_NAME>' AGENTS.md || INIT_DONE=1

# 2. docs/idea/ — только шаблоны без реального контента
filled=$(ls docs/idea/ 2>/dev/null | grep -v -E '^(README\.md|TEMPLATE\.md|template\.md|.*-template\.md|0[0-9]-.*\.md)$' | wc -l)
[ "$filled" -gt 0 ] && INIT_DONE=1

# 3. CODEOWNERS не должен существовать (создаётся в Шаге 5.5)
[ -f CODEOWNERS ] && INIT_DONE=1
```

Если **любая** из этих проверок сработала (`INIT_DONE=1`) — репо уже инициализирован. **Остановись** и подскажи пользователю:

> Похоже, проект уже инициализирован. Если ты новый разработчик в команде — запусти `/onboard-developer` (настроит твои локальные конфиги, не затронет командные). Если нужно дополнить идею после обсуждений — `/sync-idea`. Перезапись `/init-project` поверх инициализированного репо **не делается** во избежание затирания командной работы.

Сценарий перезаписи `/init-project` поверх существующего проекта **не поддерживается** в team+ai — слишком опасно для команды.

### Шаг 1. Симлинк AGENTS.md ↔ CLAUDE.md

```bash
# Проверь ОС
if [[ "$OSTYPE" == "linux-gnu"* || "$OSTYPE" == "darwin"* ]]; then
  # Linux / macOS — простой симлинк
  [[ -L CLAUDE.md || ! -e CLAUDE.md ]] && ln -sf AGENTS.md CLAUDE.md
else
  # Windows: проверь core.symlinks
  if git config --get core.symlinks | grep -q true; then
    ln -sf AGENTS.md CLAUDE.md
  else
    # Fallback: копия + pre-commit hook
    cp AGENTS.md CLAUDE.md
    echo "⚠️  Symlinks отключены в git. Активирован fallback: scripts/sync-claude-md.sh синхронизирует AGENTS.md → CLAUDE.md в pre-commit hook."
  fi
fi
```

### Шаг 1.5. Установи и активируй pre-commit hooks

**Зачем именно здесь:** первый коммит (Шаг 8) уже должен пройти через хуки (lint, secrets, conventional-commits, validate-links). Если установить хуки **после** первого коммита — он уйдёт без проверок, что и есть ровно та silent-дыра, ради которой эта методология не полагается на дисциплину.

```bash
# 1. Проверь, что pre-commit установлен (бинарь)
if ! command -v pre-commit >/dev/null 2>&1; then
  echo "pre-commit не установлен. Установи: pip install pre-commit (или brew install pre-commit на macOS)."
  echo "Затем повтори этот шаг или продолжай — /doctor подсветит проблему в Шаге 9."
else
  # 2. Активируй ВСЕ ТРИ типа хуков. Без всех трёх stage 'commit-msg' и 'pre-push'
  #    в .pre-commit-config.yaml молча не работают.
  pre-commit install \
    && pre-commit install --hook-type commit-msg \
    && pre-commit install --hook-type pre-push
fi
```

**Если установка не получилась** (нет сети, нет прав, не питон-окружение, корпоративный прокси, как в реальных кейсах с DNS-блоком на ghcr.io) — продолжай инициализацию. `/doctor` в Шаге 9 пометит проблему и покажет команду установки. **Не блокируй сессию.**

### Шаг 2. Прочитай inbox/

```bash
ls -la inbox/
find inbox/ -type f \( -name "*.md" -o -name "*.txt" -o -name "*.json" \) | head -50
```

Прочитай содержимое — там могут быть:
- Экспорты чатов с LLM (md, txt, json)
- Голосовые расшифровки
- Файлы документов (pdf уже загружен в context — проверь)
- Изображения скриншотов
- Произвольные «мысли»

**Структура inbox не нормирована** — содержимое может быть в любом виде. Твоя задача — извлечь смысл, **не критиковать формат**.

Резюмируй пользователю что нашёл:
> Я прочитал inbox/. Нашёл:
> - 2 экспорта чатов с ChatGPT (общий смысл: <X>, <Y>)
> - 1 голосовая расшифровка про <Z>
> - PDF с конкурентным анализом
> - Файл `random-thoughts.txt` со списком фич
>
> Перейду к заполнению `docs/idea/` и `docs/product/`. Если в каком-то разделе данных недостаточно — я задам уточняющий вопрос.

### Шаг 3. Заполни docs/product/ (3 файла)

| Файл | Что в нём | Если данных нет |
|---|---|---|
| `docs/product/vision.md` | 1 абзац: что строим, для кого, какая проблема решается. | Задай 3 вопроса: что/кому/зачем. |
| `docs/product/audience.md` | Кто пользователь, его профиль, jobs-to-be-done. | Задай 2 вопроса: типичный пользователь и его боль. |
| `docs/product/goals.md` | Цели на ближайший горизонт (3-6 мес): метрики успеха, что считаем «получилось». | Задай 1 вопрос: «что считаем успехом через 3 месяца?» |

В конце каждого файла — обязательная секция `## Связки` со ссылками на смежные документы.

### Шаг 4. Заполни docs/idea/ (5 разделов)

Это **frozen-снимок** идейного ядра на момент инициализации. Один файл = один раздел.

| № | Файл | Что в нём |
|---|---|---|
| 01 | `01-idea.md` | Сердцевина: что это, для кого, зачем + принятые идейные решения (например, «продаём по подписке, не по транзакциям»). |
| 02 | `02-research.md` | Что мы выяснили, что есть на рынке (конкуренты, существующие решения, что не сработало у других). |
| 03 | `03-principles.md` | Принципы: что важно делать так, а не иначе. Что мы НЕ делаем. Это контракт для AI. |
| 04 | `04-mvp.md` | Минимум для показа: capabilities (что система должна уметь) + что обязательно / что отложено. Опционально — этапы развития (MVP → Pilot → Scale). |
| 05 | `05-risks.md` | Что может пойти не так. По каждому риску — митигация или признак «пока не знаем». |

**Что НЕ идёт в `docs/idea/`:** долгосрочная картинка (`docs/product/vision.md`), сегменты аудитории (`docs/product/audience.md`), высокоуровневая архитектура (`docs/architecture/overview.md` — заполняется в `/adopt-architecture`), архитектурные ADR (`docs/adr/`).

**Если данных в `inbox/` для какого-то раздела не хватает** — задай **до 3 уточняющих вопросов разом**, не дёргай по одному. Если ответов всё равно мало — заполни файл как `<заглушка>` с пометкой «требует доработки» и впиши в `plans/YYYY-MM-DD-fill-idea-gaps.md` как первый план.

В каждом файле — обязательная секция `## Связки`.

### Шаг 5. Обнови AGENTS.md §0

В `AGENTS.md` §0 нужно заполнить:
- `<PROJECT_NAME>` — кратко, kebab-case + читаемое название.
- One-liner про продукт — взять из `docs/product/vision.md`.
- Поле **Команда** — заполнить вопросами пользователю:
  - `team_size: <N>` — сколько разработчиков в команде (обычно 4-7).
  - `external_tracker: <Jira | YouTrack | Yandex Tracker | other>` — какой трекер используют.
  - `tracker_url: <https://...>` — корневой URL трекера, для подстановки кликабельных ссылок на задачи в MR.
  - `id_prefix: <PROJ>` — префикс ID задач (например, `PROJ-142` → префикс `PROJ`). Используется в именах веток, планов, ADR.

Если пользователь не знает или не хочет отвечать сейчас — оставь плейсхолдер и впиши в `plans/YYYY-MM-DD-fill-team-config.md`.

**НЕ ТРОГАЙ** разделы про стек (§1) и индекс ADR (§3) — стек заполнит `/adopt-stack`, ADR будут дописываться по мере появления (индекс `docs/adr/INDEX.md` генерируется автоматически на pre-commit).

### Шаг 5.5. Создай командные файлы (CODEOWNERS, MR template, .gitignore-additions)

Это специфично для team+ai — обеспечивает работу MR-флоу и защиту командных файлов.

**5.5.1. CODEOWNERS** в корне репо. Минимальный шаблон (хэндлы спросить у пользователя — реальные GitLab usernames или группы):

```
# Базовый шаблон — обновите хэндлы под вашу команду
AGENTS.md                @<architects>
.claude/agents/          @<architects>
.claude/commands/        @<architects>
.claude/skills/          @<architects>
playbooks/               @<architects>
scripts/                 @<architects>
security/                @<security-team>
docs/adr/                @<architects>
docs/product/            @<pm>
docs/idea/               @<pm>
.gitlab-ci.yml           @<devops>
.gitlab/                 @<architects>
CODEOWNERS               @<architects>
```

Спроси пользователя одним блоком: «Кто владельцы (хэндлы GitLab) для: architects, security-team, pm, devops? Можно одного человека на несколько ролей. Если групп ещё нет — впиши плейсхолдеры `@<role>` и обнови позже».

**5.5.2. MR template** — `.gitlab/merge_request_templates/default.md`. Базовый шаблон описания MR (что сделано, как протестировано, чеклист автора, ссылка на задачу через `tracker_url` + `id_prefix`). Создаётся автоматически (см. `templates/merge_request_template.md` в семени методологии — он копируется).

**5.5.3. `.gitignore` — добавить личные конфиги** (если их там ещё нет):

```bash
cat >> .gitignore <<'EOF'

# --- Team+AI: личные оверрайды разработчика (не коммитим) ---
CLAUDE.local.md
.claude/settings.local.json
EOF
```

Это критично: без этих строк личные оверрайды и секреты могут случайно попасть в командный репо.

### Шаг 6. Создай первый ADR

`docs/adr/YYYYMMDD-HHmm-bootstrap.md` — фиксирует факт инициализации со ссылками на источники.

**Перед заполнением ADR прочитай реальную версию методологии:**

```bash
METHODOLOGY_VERSION=$(cat VERSION 2>/dev/null || echo "unknown")
# Например: "0.1.0". Если файла VERSION нет — методология скопирована со старой ревизии.
```

Подставь это значение в поле Context ADR вместо плейсхолдера `X.Y`. Это нужно, чтобы через полгода можно было понять, на какой версии методологии стартовал проект — и какие migration guides применять для апгрейда.

```markdown
# YYYYMMDD-HHmm-bootstrap

## Status
Accepted

## Date
YYYY-MM-DD

## Decision Maker(s)
<имя пользователя>

## Context

Проект инициализирован из methodology-seed (версия <значение из VERSION, например 0.1.0>). Источники наполнения:
- inbox/ — список конкретных файлов
- Обсуждения в чате с AI на дату инициализации

## Decision

Принять методологию из METHODOLOGY.md как стандарт работы.
Стек не выбран — Phase 0 (Discovery).

## Consequences

### Positive
- Единая структура, понятная между сессиями
- Готовый pre-commit / CI на базовом уровне

### Negative or Trade-offs
- Жёсткая структура может ощущаться как оверхед на ранней стадии

### Follow-ups
- После завершения проработки идеи → `/adopt-stack` для Phase 1

## Alternatives considered

- Свободная организация — отклонено: контекст между сессиями теряется

## Связки

- [METHODOLOGY.md](../METHODOLOGY.md)
- [docs/idea/](../idea/)
- [docs/product/vision.md](../product/vision.md)
```

Допиши строку в индекс ADR в `AGENTS.md` §3.

### Шаг 7. Первый ретро

`retrospectives/YYYY-MM-DD_HH-MM_init-project.md` — кратко 5 пунктов про сам процесс инициализации.

### Шаг 8. Первый коммит

```bash
git add AGENTS.md CLAUDE.md CODEOWNERS .gitlab/ .gitignore docs/ retrospectives/
git commit -m "chore: bootstrap project from team+ai seed

- Read inbox/ and populated docs/idea/ + docs/product/
- Filled AGENTS.md §0 (team config) and §5
- Created CODEOWNERS and MR template
- Created bootstrap ADR
- Created first retrospective"
```

**Без push.** Первый push в `main` делает Maintainer репозитория (он же обычно создаёт сам репозиторий в GitLab). **После первого push на GitLab нужно включить branch protection на `main`** (Settings → Repository → Protected branches) — иначе остальные правила методологии не сработают на стороне сервера. Подскажи пользователю это явно.

### Шаг 9. Запусти /doctor

После коммита прогони `/doctor` (см. [doctor playbook](doctor.md)). Цель — пользователь сразу видит, что из required установлено, чего не хватает, и какие команды установки. На Phase 0 раздел `contextual` в [`.claude/expected-tools.md`](../.claude/expected-tools.md) ещё пуст (заполнится на `/adopt-stack`) — поэтому это лёгкая базовая проверка.

Если пользователь уже ранее подтвердил `/doctor`-отчёт и в `.claude/settings.local.json` стоит `doctorAcknowledged: true` — автозапуск молча пропускается. Ручной `/doctor` работает всегда.

Не блокируй сессию даже если что-то из required отсутствует — выведи команду установки и переходи к финальному отчёту. Пользователь сам решит, ставить сейчас или позже.

### Шаг 10. Финальный отчёт

Скажи пользователю:
> ✅ Инициализация завершена.
>
> **Что наполнено:**
> - `docs/product/` — 3 файла
> - `docs/idea/` — 5 файлов (X наполненных, Y заглушек)
> - `AGENTS.md` — заголовок и one-liner
> - Первый ADR (`YYYYMMDD-HHmm-bootstrap.md`)
> - Первая ретроспектива
>
> **Состояние окружения:** см. вывод `/doctor` выше. Если в required чего-то нет — лучше доустановить перед `/adopt-architecture` и `/adopt-stack`.
>
> **Что осталось:**
> - Заполнить заглушки: `<список разделов>` (есть план `plans/YYYY-MM-DD-fill-idea-gaps.md`)
> - Когда идея проработана — `/adopt-architecture` (Phase 0.5)
> - Когда определимся со стеком — `/adopt-stack` (Phase 1)
> - **Сделать первый push в `main` (Maintainer) и включить branch protection на `main` в GitLab** — обязательно до того, как другие разработчики начнут работать.
> - Дать команде ссылку на репо. Остальные разработчики после клонирования запускают `/onboard-developer` (настроит личные конфиги, не затронет командное).
>
> Закоммитил локально. Push в `main` — только сейчас, разово, Maintainer'ом репозитория. Все последующие изменения — через feature-ветки и MR.

## Что НЕ делает init-project

- **Не выбирает стек** — это работа `/adopt-stack`.
- **Не создаёт папки с кодом** (`backend/`, `frontend/` и т.д.) — это `/adopt-stack`.
- **Не пушит** — только локальный коммит. Push — отдельной командой.
- **Не трогает `inbox/`** — содержимое остаётся как архив. Пользователь сам решит, удалять или сохранять.
- **Не запускает `/full-ahead`** — нечего тестировать на этой фазе.

## Чек-лист после завершения

- [ ] `CLAUDE.md` существует и читается (симлинк или копия).
- [ ] `pre-commit` установлен и активированы **все три** типа хуков (default / `commit-msg` / `pre-push`) — `/doctor` в Шаге 9 это подтвердит.
- [ ] `docs/product/vision.md` имеет содержимое (не «<заглушка>»).
- [ ] `docs/idea/01-idea.md` имеет содержимое.
- [ ] `AGENTS.md` §0 заполнен: PROJECT_NAME, one-liner, **team_size**, **external_tracker**, **tracker_url**, **id_prefix**.
- [ ] `CODEOWNERS` создан с реальными хэндлами или плейсхолдерами `@<role>`.
- [ ] `.gitlab/merge_request_templates/default.md` существует.
- [ ] `.gitignore` содержит `CLAUDE.local.md` и `.claude/settings.local.json`.
- [ ] Первый ADR создан и в его Context подставлена реальная версия методологии из `VERSION`.
- [ ] Первый ретро создан.
- [ ] `scripts/validate-links.sh` зелёный.
- [ ] Локальный коммит сделан, не запушен.
- [ ] `/doctor` запущен (хотя бы один раз).
- [ ] **Пользователь напомнен**: первый push в `main` — разово Maintainer'ом, потом включить branch protection на `main` в GitLab.

## Связки

- [METHODOLOGY.md](../METHODOLOGY.md) — методология в целом
- [adopt-stack playbook](adopt-stack.md) — следующий шаг (Phase 1)
- [sync-idea playbook](sync-idea.md) — если нужно дополнить уже инициализированный проект
