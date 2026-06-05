# Changelog

Все значимые изменения методологии `team+ai` фиксируются здесь.
Формат: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
версионирование: [Semantic Versioning](https://semver.org/).

Семантика bump'ов и общая политика версионирования — мета-ADR [`20260518-1500-version-methodology-via-version-file`](https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260518-1500-version-methodology-via-version-file.md). Финализация версии — командой `/release`.

## [Unreleased]

## [0.8.0] — 2026-06-04

### Added

- **Восстановимость `/autopilot` на длинных прогонах (`/autopilot --resume`).** Состояние прогона держится в файлах (план `## Фазы` / `## Критерий приёмки` / `## Журнал автономного прогона` + git, коммиты с `Refs:`), а не в окне контекста. `--resume` (и НЛ «продолжи план») реконструирует «сделано/осталось» из плана+журнала+`git log` и продолжает с первой невыполненной фазы **в той же feature-ветке** — переживает авто-компактификацию, `/compact` и `/clear`. Закрытие [мета-ADR 20260604-1911](https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260604-1911-autopilot-context-resumability-and-checkpoints.md).
- **Протокол контрольных точек (без прерываний).** На знаковой границе — коммит (с `Refs:`) + **resume-note** в журнале (состояние / дальше / ключевые решения / открытые риски). autopilot всегда исходит из работы **без присмотра** и **не прерывается** ради сброса контекста: тот ужимается автоматически (auto-compact + делегирование субагентам). `/clear` + `/autopilot --resume` — **ручная опция пользователя** между сессиями (в той же feature-ветке).
- **`scripts/autopilot-precompact.sh`** (PreCompact hook) — крошка в `.claude/autopilot-checkpoint.md` перед авто-компактом (компакт не отменяет). Только при активном прогоне.
- **`scripts/autopilot-session-start.sh`** (SessionStart hook) — после `/clear`/компакта/resume возвращает `additionalContext` «прочитай план+журнал, продолжи в своей feature-ветке». Гард: checkpoint + невыполненный критерий приёмки.
- [`migrations/v0.7-to-v0.8.md`](migrations/v0.7-to-v0.8.md) — гайд (вкл. регистрацию hooks в `.claude/settings.local.json`).

### Changed

- [`scripts/autopilot-preflight.sh`](scripts/autopilot-preflight.sh) — при старте пишет личный `.claude/autopilot-checkpoint.md` (метка «прогон идёт»).
- [`playbooks/autopilot.md`](playbooks/autopilot.md) — разделы «Управление контекстом (длинные прогоны)» и «Resume»; Шаг 0/3/5 (checkpoint create/use/delete).
- [`plans/TEMPLATE.md`](plans/TEMPLATE.md) — в журнал добавлена строка resume-note.
- [`.claude/skills/autopilot/SKILL.md`](.claude/skills/autopilot/SKILL.md) — resume-триггеры в `description`.
- [`AGENTS.md`](AGENTS.md) — §6 (строка `/autopilot`: «продолжи план», «восстановим») и §6.1 (абзац про resumability + hooks).
- `.gitignore` — `.claude/autopilot-checkpoint.md`.
- **Харденинг `playbooks/autopilot.md` по внешнему best-practice ревью** (Anthropic «Effective harnesses for long-running agents», Cognition, Manus, Chroma «Context Rot», Fowler/Böckeler): галочку `## Критерий приёмки` ставит только внешний верификатор (тест / вердикт read-only гейта), не self-report исполнителя; resume сначала прогоняет smoke (ground truth), затем продолжает; добавлены правила идемпотентности фаз и «фазы помельче»; recitation цели+критерия в начале каждой фазы; журнал помечен как **лоссовый** (источник правды = git + верифицированный критерий + smoke); SessionStart-реинъекция — best-effort, не гарантия (resume всегда явно перечитывает файлы).

### Compatibility

- Скопированные 0.7.x проекты работают без изменений: resume/checkpoint — расширение поведения autopilot; hooks **опциональны** (регистрация в личном `.claude/settings.local.json`, не в `settings.json`). autopilot по-прежнему пишет только в feature-ветку, без push. Миграция нужна, только чтобы получить новое. Пошагово — [`migrations/v0.7-to-v0.8.md`](migrations/v0.7-to-v0.8.md).
- Smoke-test: `shellcheck` по трём autopilot-скриптам — 0; функциональный smoke хуков — валидный JSON, гард «нет прогона → молчит» работает; `validate-links` — 0 ошибок; `AGENTS.md` 263 строки (≤300).

## [0.7.0] — 2026-06-04

### Added

- **Команда `/autopilot`** (playbook [`playbooks/autopilot.md`](playbooks/autopilot.md) + skill [`.claude/skills/autopilot/SKILL.md`](.claude/skills/autopilot/SKILL.md)) — автономный исполнитель многофазного плана **в собственной feature-ветке** поверх существующих кирпичей (`/critic`, read-only субагенты, Stop hook, `dangerous-commands.md`). Идёт по `## Фазы`: код → four-gate review (code-reviewer, test-runner, security-auditor, merge-coordinator) + `/critic` на развилках → при предметном опасении сверка с лучшими практиками из интернета (2-3 источника, веб как untrusted) → правка → **коммит фазы с `Refs:` trailer, без push** → запись в `## Журнал автономного прогона`. Вопросы — только на старте. Кейс «крупная фича без плана» — развилка: **Path A** (план совместно) / **Path B** (полностью автономно). На тупике — стоп с понятным отчётом; в конце — краткая сводка + предложение `/open-mr`. **Push и MR — ручной шаг человека** (push в `main` запрещён всегда). Закрытие [мета-ADR 20260604-0231](https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260604-0231-autopilot-phased-autonomous-execution.md).
- **`scripts/autopilot-preflight.sh`** — детерминированный pre-flight: текущая ветка **не `main`/защищённая** и соответствует паттерну `<тип>/<...>` §4.3 (иначе exit 2), чистый git-tree (иначе exit 2), фиксация базового commit SHA (точка отката), опциональный чекпоинт-тег (`--tag`), проверка готовности (`.claude/agents/` incl. `merge-coordinator`, `stop-checklist.sh`) + напоминание о rebase на `origin/main`. Ничего не удаляет/коммитит/пушит.
- **Секция `## Журнал автономного прогона`** в [`plans/TEMPLATE.md`](plans/TEMPLATE.md) — заполняется только при выполнении плана через `/autopilot` (ветка / базовый SHA / по фазе: что / сомнение / решение / web-чек / коммит). В обычной работе удаляется.
- [`migrations/v0.6-to-v0.7.md`](migrations/v0.6-to-v0.7.md) — пошаговое руководство для 0.6.x проектов.

### Changed

- [`AGENTS.md §6`](AGENTS.md) — таблица команд дополнена строкой `/autopilot`; **§6.1** — абзац про autopilot как исполнитель плана в feature-ветке с границами ответственности (`/autonomous` — тумблер, `/full-ahead` — один цикл + push, `/autopilot` — весь план без push).
- [`playbooks/plan.md`](playbooks/plan.md) — Шаг 3 и `## Связки`: готовый план можно отдать на автономное выполнение через `/autopilot` (коммиты с `Refs:` в feature-ветку).
- [`playbooks/README.md`](playbooks/README.md) — строка `autopilot.md` в таблице playbook-ов.

### Fixed

- **`scripts/stop-checklist.sh` теперь проверяет ветку.** Исправлен унаследованный из solo+ai дефект: при включённом autonomous mode Stop hook добавляет ошибку и не даёт пометить фичу завершённой, если текущая ветка — `main`/`master`/`develop`/`release`. Раньше `AGENTS.md §6.1` заявлял эту проверку, но скрипт её не делал (копия solo+ai, push-to-main). Также исправлена унаследованная шапка комментария «методологии solo+ai» → «team+ai». Это защита в глубину к проверке ветки в `autopilot-preflight.sh` (старт) — теперь ветка контролируется и на старте, и на финале autonomous-цикла. Smoke: на `main` хук возвращает exit 2 с понятной ошибкой, на feature-ветке — exit 0.

### Compatibility

- Скопированные 0.6.x проекты продолжают работать без изменений: `/autopilot` — additive-команда, поведение `/full-ahead`, `/autonomous`, `/open-mr` не меняется. autopilot не пишет в `main` (проверка ветки в pre-flight + git-уровневая защита `pre-push-guard.sh` и branch protection). Миграция нужна, только если хочешь команду `/autopilot`. Пошагово — в [`migrations/v0.6-to-v0.7.md`](migrations/v0.6-to-v0.7.md).
- Smoke-test (свежая копия в `/tmp`): `autopilot-preflight.sh` отказывается на `main` (exit 2) и на не-feature ветке (exit 2), на feature-ветке с чистым деревом — exit 0 + базовый SHA, на грязном дереве — exit 2; `shellcheck` — 0 замечаний; `validate-links --report` — 0 ошибок.

## [0.6.1] — 2026-05-22

### Added

- **Документация про опциональное расширение Claude Code `@-imports`** в трёх местах: [`playbooks/README.md`](playbooks/README.md) (раздел «Claude Code @-imports» в cross-vendor секции, с акцентом на команд-ную специфику — применять только если **все** разработчики на Claude Code), [`AGENTS.md §2`](AGENTS.md) (blockquote с предупреждением про cross-vendor контракт), [`METHODOLOGY.md §10`](METHODOLOGY.md) (строка в таблице Claude-специфичных компонентов). **Не применяем** прямо сейчас — `AGENTS.md` 256 строк (≤300, в рамках). Документация — подготовка к будущему. Закрытие [ADR-2100](https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260522-2100-documenting-at-imports-pattern-for-claude-code.md).

### Compatibility

- PATCH bump: только текстовые правки в трёх файлах. Поведение не меняется. Migration guide не требуется (PATCH).

## [0.6.0] — 2026-05-22

### Added

- **`scripts/gen-copilot-instructions.sh`** — генератор `.github/copilot-instructions.md` из `AGENTS.md` для GitHub Copilot Workspace / Copilot Chat / Copilot Code Review. Парсит §0 (Project one-liner), §4.4 (Безопасность, включая `inbox/` untrusted), §5 (Правила работы AI), §6 (таблица команд с MR-флоу) — собирает в один производный markdown с шапкой «AUTOGENERATED». Два режима: дефолтный (генерирует) и `--check` (для CI/pre-commit). Закрытие [ADR-1900](https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260522-1900-gen-copilot-instructions-for-cross-vendor-coverage.md).
- **Раздел «GitHub Copilot Workspace — рецепт настройки»** в [`playbooks/README.md`](playbooks/README.md). В команде это особенно ценно — миксованные конфигурации (часть на Claude Code, часть на Cursor, часть на Copilot Workspace) теперь получают единое содержание из одного `AGENTS.md`.
- [`migrations/v0.5-to-v0.6.md`](migrations/v0.5-to-v0.6.md) — короткий гайд.

### Compatibility

- Скопированные 0.5.x проекты продолжают работать без изменений. Новый скрипт — additive. Файл `.github/copilot-instructions.md` не входит в seed по умолчанию. Миграция нужна, только если в команде есть разработчики на GitHub Copilot Workspace.
- Smoke-test: `bash scripts/gen-copilot-instructions.sh` корректно генерирует файл (~11500 символов для team+ai); `--check` после генерации возвращает «в актуальном состоянии»; shellcheck — 0 замечаний.

## [0.5.0] — 2026-05-22

### Added

- **DORA Four Keys как обязательная секция в [`playbooks/retro.md`](playbooks/retro.md).** Шаг 4 пункт «Метрики релиза (опционально)» переименован в «DORA Four Keys (обязательно)» и расширен полным шаблоном (Deployment Frequency, Lead Time, Change Failure Rate, MTTR + Тренд + Контекст изменений + ссылка на helper-скрипт). Обоснование — [DORA 2025 Report](https://dora.dev/dora-report-2025/): «AI is an amplifier», без четырёх ключей команда не видит, в какую сторону её несёт. Закрытие [ADR-1700](https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260522-1700-dora-four-keys-in-team-retro-and-solo-weekplan.md).
- [`scripts/dora-collect.sh`](scripts/dora-collect.sh) — тонкий helper (~85 строк bash, без зависимостей) для сырых DORA-данных из git: Deployment Frequency (теги `vX.Y.Z` за период), Lead Time (squash-merge коммиты в main), грубая прокси CFR (PATCH-релизы / общее количество). CFR-precise и MTTR заполняются вручную из incident tracker. Дефолтный период — с последнего тега до HEAD. shellcheck чистый.
- [`migrations/v0.4-to-v0.5.md`](migrations/v0.4-to-v0.5.md) — пошаговое руководство для 0.4.x проектов.

### Changed

- **[`retrospectives/TEMPLATE.md`](retrospectives/TEMPLATE.md) полностью переписан под релизный формат.** Прежний шаблон был унаследован из `solo+ai` (посессионный, 5 пунктов: Задача / Как решал / Решил? / Что лучше / Как было/стало) — не соответствовал правилам team+ai из [`playbooks/retro.md`](playbooks/retro.md) («ретро после релиза, файл один на релиз»). Новый шаблон: 6 секций (Что вошло в релиз / Что прошло хорошо / Что лучше / Что меняем / **DORA Four Keys** / Follow-up). Это **унаследованный баг** из создания team+ai через `cp -r solo+ai team+ai` 2026-05-21.
- **[`retrospectives/README.md`](retrospectives/README.md) переписан** — обновлено описание, имя файла, формат, ссылки. Аналогичный фикс наследия solo+ai.
- [`playbooks/retro.md`](playbooks/retro.md) — Шаг 4 пункт о метриках расширен под DORA; раздел «Правила» дополнен пунктом про обязательность DORA Four Keys с обоснованием.

### Compatibility

- Скопированные 0.4.x проекты — `scripts/dora-collect.sh` и обновлённые шаблоны/playbook не ломают существующих ретро. Если у команды уже есть исторические ретро-файлы в старом 5-пунктном формате — оставлять как есть (история), новые ретро писать по новому шаблону. Миграция требует ~10 минут (обновить retro.md, TEMPLATE.md, README.md, добавить dora-collect.sh).
- Smoke-test: `bash scripts/dora-collect.sh` в мета-репо без тегов `vX.Y.Z` — корректно выдаёт «нет тегов» без ошибок (`set -u` без `-e` чтобы data-collection не валился на отсутствии данных); shellcheck — 0 замечаний; `validate-links --report` — 89 md, 704 ссылок, 0 ошибок.

## [0.4.0] — 2026-05-22

### Added

- **OWASP Top 10 for LLM Applications 2025 в security-auditor.** В [`.claude/agents/security-auditor.md`](.claude/agents/security-auditor.md) — отдельная секция «OWASP LLM Top 10 — если проект использует LLM/embeddings в runtime» с 10 пунктами (LLM01 Prompt Injection ... LLM10 Unbounded Consumption). Применяется условно: только если в diff есть импорты `openai`/`anthropic`/`langchain`/`llama`/`transformers`/`chromadb`/etc., либо файлы `prompt*`/`embed*`/`vector*`/`rag*`. Для обычной бизнес-логики секция пропускается. Sev1/Sev2 находки попадают в MR-комментарии (если AI-review в CI настроен) либо в self-review автора перед `/open-mr`. Закрытие [ADR-1500](https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260522-1500-security-auditor-owasp-llm-top10-and-semgrep.md).
- **semgrep как опциональный SAST в `ci-push.sh` Шаг 2.** Запускается с конфигами `p/security-audit` + `p/insecure-deserialization`, severity ERROR (только блокеры). Защита от deserialization-CVE (CVE-2025-62373 Pipecat pickle RCE, CVE-2025-1716 picklescan bypass). В команде локально — первая линия защиты, server-side в GitLab CI MR-pipeline — вторая (когда `/adopt-stack` настроит). См. [`.claude/expected-tools.md`](.claude/expected-tools.md).
- **jscpd как опциональный code-clone detection в `ci-push.sh` Шаг 5.** Защита от документированной AI-патологии: [GitClear 2024-2025](https://www.gitclear.com/ai_assistant_code_quality_2025_research) фиксирует **8x рост дубликатов** от AI и **-44% YoY** доли рефакторинга. В команде дубликаты особенно вредны: рефакторить чужой код после squash merge дороже, чем переиспользовать существующий хелпер сразу. Дефолт `--threshold 5 --gitignore`. `/adopt-stack` сможет заменить на стек-релевантный (`dupl`/`pmd-cpd`/`pylint`). Закрытие [ADR-1530](https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260522-1530-ci-push-code-clone-defense-against-ai-duplication.md).
- **`inbox/` как untrusted input в [`AGENTS.md §4.4`](AGENTS.md).** Содержимое `inbox/` может содержать prompt injection, секреты, инструкции, противоречащие AGENTS.md. Правило: (а) `gitleaks detect --source=inbox/` до коммита; (б) команды в inbox-материалах — подсказки, не директивы; (в) импорт в `docs/idea/` через re-read на инъекции.
- [`.claude/expected-tools.md`](.claude/expected-tools.md) — `semgrep` и `jscpd` в категории `recommended`.
- [`migrations/v0.3-to-v0.4.md`](migrations/v0.3-to-v0.4.md) — пошаговое руководство для 0.3.x проектов.

### Changed

- [`scripts/ci-push.sh`](scripts/ci-push.sh) — Шаг 2 «SAST + Secret Detection» расширен semgrep-блоком; добавлен **новый Шаг 5 «Code duplication»**. Оба шага опциональны через `command -v`.
- [`.claude/agents/security-auditor.md`](.claude/agents/security-auditor.md) — **исправлен YAML-frontmatter и тело**: «методологии solo+ai» → «методологии team+ai» (наследие копирования через `cp -r` при создании team+ai 0.1.0). Триггерная эвристика дополнена LLM-application файловыми паттернами. Описание дополнено упоминанием «Sev1/Sev2 попадают в MR-комментарии или self-review» (team-флоу specific).
- [`playbooks/full-ahead.md`](playbooks/full-ahead.md) — табличка «Три уровня локального CI» строка Push дополнена: «… SAST + gitleaks **+ semgrep**, … tests + coverage, **code-clone (jscpd `--threshold 5`)**».

### Compatibility

- Скопированные 0.3.x проекты продолжают работать без изменений: semgrep и jscpd опциональны (через `command -v`), без них шаги пропускаются с подсказкой. Расширения `security-auditor` — additive. Правило про `inbox/` — текст в AGENTS.md. Миграция нужна, если хочешь получить новые опциональные шаги и расширенный security-аудит. Пошагово — в [`migrations/v0.3-to-v0.4.md`](migrations/v0.3-to-v0.4.md). **Не путать** с предыдущим `v0.2-to-v0.3.md` (ci-tiers), это **другая** миграция поверх него.
- Smoke-test: `bash scripts/ci-push.sh` в Phase 0 без semgrep/jscpd — корректно пропускает; `shellcheck` зелёный; `validate-links --report` — 88 md, 664 ссылок, 0 ошибок.

## [0.3.1] — 2026-05-22

### Fixed

- [`AGENTS.md §6`](AGENTS.md) — описания команд `/full-ahead` и `/autonomous` в таблице ссылались на устаревший **three-gate review**, тогда как в `§6.1` (Autonomous mode) и в [`playbooks/full-ahead.md`](playbooks/full-ahead.md) уже **four-gate review** (с `merge-coordinator` subagent, добавленным в v0.2.0). Прямое противоречие в пределах одного файла — заменено на «four-gate review через subagents (code-reviewer, test-runner, security-auditor, merge-coordinator)». Описание `/full-ahead` также синхронизировано с реальной процедурой v0.3.0: «`ci-push.sh` → fix loop → commit → push в feature-ветку → подсказка `/open-mr`» (раньше — устаревший «clean → build → test → mutation → security → fix → commit → push»). Баг обнаружен при ревью методологий 2026-05-22.

### Compatibility

- PATCH bump: только текстовые правки в таблице команд AGENTS.md. Поведение не меняется, скрипты и playbook'и не затронуты. Migration guide не требуется по [мета-ADR `markdown-migration-guides`](https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260518-1501-markdown-migration-guides.md).

## [0.3.0] — 2026-05-22

### Added

- **Трёхуровневый локальный CI** с поправками под MR-флоу (закрытие [ADR-20260522-1400](https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260522-1400-team-ai-ci-tiers-with-gitlab-nightly-deep.md), на базе [ADR-20260518-1432](https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260518-1432-split-local-ci-into-tiers.md)):
  - [`scripts/ci-fast.sh`](scripts/ci-fast.sh) — Fast-уровень (секунды): `pre-commit run --all-files`. Запускается на каждый commit через git hook.
  - [`scripts/ci-push.sh`](scripts/ci-push.sh) — Push-уровень (минуты): build & types, SAST + gitleaks, SCA + license (trivy fs), tests + coverage. **Новый дефолт `/full-ahead`** перед push в feature-ветку.
  - [`scripts/ci-deep.sh`](scripts/ci-deep.sh) — Deep-уровень. **Основное место запуска в команде — GitLab CI nightly job `security-deep:nightly`**. Локально остаётся opt-in для отладки конкретной регрессии перед `/open-mr`.
- [`playbooks/self-review.md`](playbooks/self-review.md) — 7-пунктный смысловой чек-лист, **читается перед `/open-mr`** (не перед каждым feature-checkpoint push, как в solo+ai). Дополняет `merge-coordinator` subagent: тот делает структурные проверки (rebase, ADR, changelog-фрагмент, trailers), self-review — смысловые (логика, swallowed errors, secrets/PII, обратная совместимость).
- В [`.gitlab-ci.yml`](.gitlab-ci.yml) — новый job `security-deep:nightly` в stage `security`, `rules: $CI_PIPELINE_SOURCE == "schedule"`. Запускается только по GitLab schedule, не на каждом MR. Не блокирует MR, не умножает время команды на N разработчиков. К файлу добавлен блок-комментарий-инструкция, как настроить schedule в GitLab UI (операционная задача release-инженера, не делается через MR).
- [`migrations/v0.2-to-v0.3.md`](migrations/v0.2-to-v0.3.md) — пошаговое руководство для уже скопированных 0.2.x-проектов.

### Changed

- [`scripts/local-ci.sh`](scripts/local-ci.sh) — переписан как тонкий orchestrator (~55 строк вместо ~140). Маршрутизация: без флагов → `ci-push.sh`, `--fast` → `ci-fast.sh`, `--deep` → `ci-push.sh` + `ci-deep.sh` (только для локальной отладки). Старые вызовы продолжают работать (фасадная совместимость).
- [`AGENTS.md §5 п.10`](AGENTS.md) — правило переформулировано под team+ai контракт: **перед push** в feature-ветку — `validate-links.sh` + `ci-push.sh` зелёные; **перед `/open-mr`** — прочитан `self-review.md`; deep-проверки — opt-in локально + nightly в GitLab CI.
- [`METHODOLOGY.md §5 «Качество — автоматикой»` и `§9 «Качество кода»`](METHODOLOGY.md) — оба раздела переписаны под три уровня с указанием «где живёт» (локально vs GitLab CI nightly). Подчёркнуто, что Deep централизован в CI, чтобы не умножать тяжёлые проверки на N разработчиков × M MR-итераций.
- [`playbooks/full-ahead.md`](playbooks/full-ahead.md) — Шаг 2 переключён на `scripts/ci-push.sh`. Расширен Шаг 6.2: «если push идёт под `/open-mr` — сейчас прочитай self-review; если просто feature-checkpoint — пропусти». Раздел «Что включено в local-ci.sh» переписан в табличку с тремя уровнями и пометкой «Deep — в GitLab nightly».
- [`playbooks/save-all.md`](playbooks/save-all.md) — Шаг 3 явно ссылается на `scripts/ci-push.sh` как pre-push гейт, self-review здесь **не обязателен** (он — pre-MR гейт в `/open-mr`).
- [`playbooks/open-mr.md`](playbooks/open-mr.md) — добавлен новый **Шаг 3.5 «Self-review (обязательный pre-MR гейт)»** перед уже существующим Шагом 4 «merge-coordinator». Явно описано разделение ролей: self-review = смысловые проверки, merge-coordinator = структурные. Шаг 2 (pre-flight) обновлён под `ci-push.sh`.
- [`.claude/skills/full-ahead/SKILL.md`](.claude/skills/full-ahead/SKILL.md) — обновлён `description` (упоминает `ci-push.sh`, Deep в CI nightly, self-review перед `/open-mr`, four-gate review).
- [`.claude/skills/save-all/SKILL.md`](.claude/skills/save-all/SKILL.md) — обновлён `description` (упоминает `ci-push.sh` как pre-push требование; self-review явно вынесен в `/open-mr`).
- [`.claude/skills/open-mr/SKILL.md`](.claude/skills/open-mr/SKILL.md) — обновлён `description` (явно упоминает обе pre-MR gate: self-review (semantic) и merge-coordinator (structural); они дополняют, не дублируют).
- [`playbooks/README.md`](playbooks/README.md) — добавлена строка `self-review.md` в таблицу playbook'ов с пометкой «без триггера, pre-MR правило AGENTS.md §5 п.10»; уточнены описания `full-ahead.md` (four-gate review, Deep в nightly), `save-all.md` (push в feature-ветку, `ci-push.sh`), `autonomous-mode.md` (four-gate, ранее three-gate).

### Deprecated

- Флаг `--skip-mutation` у `scripts/local-ci.sh` — печатает warning, продолжает работу. Mutation testing теперь только в Deep-уровне (по умолчанию не запускается локально; основное место — GitLab CI nightly). Будет удалён в 0.4.0.

### Compatibility

- Скопированные проекты на 0.2.x продолжают работать без изменений: `scripts/local-ci.sh` остался как фасад, путь не сменился, флаги совместимы. Миграция нужна, если хочешь получить новые скрипты, self-review playbook, nightly job в `.gitlab-ci.yml` и обновлённые playbook'и. Пошагово — в [`migrations/v0.2-to-v0.3.md`](migrations/v0.2-to-v0.3.md).
- Smoke-test (свежая копия в `/tmp`): `scripts/ci-fast.sh` + `ci-push.sh` + `ci-deep.sh` + `local-ci.sh` с флагами `--fast / --deep / --skip-mutation / --unknown` — все ведут себя корректно; shellcheck по 4 новым скриптам — 0 замечаний; `python3 -c "import yaml; yaml.safe_load(open('.gitlab-ci.yml'))"` — успех; `scripts/validate-links.sh --report` — 87 md, 625 ссылок, 0 ошибок.
- Совместимость с уже существующим `merge-coordinator` subagent (0.2.0): self-review и merge-coordinator работают параллельно как два независимых pre-MR гейта в `/open-mr` (3.5 и 4). Не дублируют друг друга.

## [0.2.0] — 2026-05-22

### Added

- Четвёртый read-only subagent `merge-coordinator` ([`.claude/agents/merge-coordinator.md`](.claude/agents/merge-coordinator.md)). Запускается перед `/open-mr` (новый Шаг 4 в [`playbooks/open-mr.md`](playbooks/open-mr.md)) и в `/full-ahead` (новый Шаг 4.4 в [`playbooks/full-ahead.md`](playbooks/full-ahead.md)) — между `security-auditor` и проверкой критерия приёмки. Проверяет специфичные для команды инварианты, которые `code-reviewer`/`test-runner`/`security-auditor` не покрывают: имя ветки, `Refs:` trailer в коммитах, rebase на свежий `origin/main`, коллизии timestamp-имён в `docs/adr/` относительно `origin/main`, наличие фрагмента в `changelogs/unreleased/<ID>-<slug>.md` для пользовательских изменений, имя файла плана с ID задачи. Возвращает структурированный отчёт «МОЖНО ОТКРЫВАТЬ MR» / «ЕСТЬ БЛОКЕРЫ». `maxTurns: 2`; третий раунд — эскалация пользователю. Read-only по контракту.
- [`migrations/v0.1-to-v0.2.md`](migrations/v0.1-to-v0.2.md) — гайд для уже скопированных 0.1.0-проектов.

### Changed

- `AGENTS.md` §6.1 «Autonomous mode (опция)» — three-gate review → **four-gate review**. Subagent `merge-coordinator` упомянут в списке и явно зафиксирован как обязательный gate в `/open-mr`.
- [`playbooks/open-mr.md`](playbooks/open-mr.md) — новый Шаг 4 «Прогон merge-coordinator subagent» (обязательный, был только code-review через `/critic`); прежний «Опционально — прогон /critic» переименован в Шаг 4.5.
- [`playbooks/full-ahead.md`](playbooks/full-ahead.md) — новый Шаг 4.4 «`merge-coordinator` subagent»; прежний 4.4 «Проверка критерия приёмки» переименован в 4.5.

### Compatibility

- Скопированные 0.1.0-проекты продолжают работать. `merge-coordinator` опционален: в `/open-mr` без него Шаг 4 просто пропускается (если файл `.claude/agents/merge-coordinator.md` отсутствует); в `/full-ahead` autonomous mode — то же. Чтобы подтянуть новую возможность, примени [`migrations/v0.1-to-v0.2.md`](migrations/v0.1-to-v0.2.md): скопируй три файла из свежего seed (`merge-coordinator.md`, обновлённые `open-mr.md`, `full-ahead.md`) и обнови `AGENTS.md` §6.1.

## [0.1.0] — 2026-05-22

Первая публичная версия методологии-шаблона `team+ai` для команд 4-7 человек, работающих по GitLab Flow с обязательными MR. Базируется на `solo+ai` 0.3.0; обоснование решений — мета-ADR [`20260521-1100-team-ai-methodology-on-top-of-solo-ai`](https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260521-1100-team-ai-methodology-on-top-of-solo-ai.md). Реализация — [план `2026-05-21-create-team-ai-methodology`](https://github.com/msamichev/methodology-ai/blob/main/plans/2026-05-21-create-team-ai-methodology.md).

### Added

- Scaffold методологии `team+ai` из `solo+ai` 0.3.0 как стартовая точка. Симлинк `CLAUDE.md → AGENTS.md` работает (Фаза 1).
- `AGENTS.md` §0: поля `team_size`, `external_tracker`, `tracker_url`, `id_prefix` (Фаза 2).
- `AGENTS.md` §2: в карте проекта появились `changelogs/unreleased/`, `.gitlab/merge_request_templates/`, `.gitlab-ci.yml`, `CODEOWNERS`, `.claude/templates/` (Фаза 2).
- `AGENTS.md` §3: индекс ADR теперь генерируется (`docs/adr/INDEX.md`) скриптом `scripts/build-adr-index.py` на pre-commit — паттерн «один файл = одна запись» против merge-конфликтов (Фаза 2).
- `AGENTS.md` §4.1: имена планов / ADR / changelog-фрагментов содержат ID задачи из внешнего трекера; общекомандные ретро после релиза `retrospectives/YYYY-MM-DD-release-vX.Y.Z.md` (Фаза 2).
- `AGENTS.md` §4.3: GitLab Flow — защищённый `main`, feature-ветки `<тип>/<ID>-<slug>`, MR + 1 approve + squash + ≤1 неделя branch lifetime, `Refs:` trailer, запрет force-push в защищённые ветки, защищённые теги (Фаза 2).
- `AGENTS.md` §6: новые команды `/onboard-developer`, `/open-mr`, `/experiments-audit`; обновлены `/init-project`, `/full-ahead`, `/save-all`, `/plan`, `/adr`, `/retro`, `/release`, `/autonomous` (Фаза 2).
- `AGENTS.md` §6.1: оговорка — autonomous mode работает только в собственной feature-ветке после rebase на `main` (Фаза 2).
- `AGENTS.md` §7: про `CLAUDE.local.md` (gitignored, личные оверрайды каждого разработчика) (Фаза 2).
- `AGENTS.md` §9: CODEOWNERS обязателен; индекс ADR не редактируется вручную (Фаза 2).
- `METHODOLOGY.md`: заголовок, intro, TL;DR переписаны под команду; новый раздел `## 12. Командная специфика` с тремя подразделами — 12.1 роли (таблица из GitLab workflow §2), 12.2 git-модель, 12.3 таблица отличий от `solo+ai` (Фаза 3).
- `README.md`: полностью переписан под team+ai (Фаза 3).
- Адаптированы 8 существующих playbooks: `save-all`, `full-ahead`, `init-project`, `plan`, `adr`, `retro`, `release`, `autonomous-mode` — описание поведения соответствует MR-флоу, ID задачи в именах артефактов, общекомандные ретро (Фаза 4).
- Соответствующие 8 `.claude/skills/*/SKILL.md` description обновлены под team+ai (Фаза 10).
- Три новых playbook'а + три SKILL.md обёртки (Фаза 5):
  - `/onboard-developer` — настройка разработчиков №2..N после клонирования; создаёт `CLAUDE.local.md` и `.claude/settings.local.json` из шаблонов, проверяет `.gitignore`, печатает cheat sheet.
  - `/open-mr` — открывает MR в `main` из текущей feature-ветки через `glab` или печатает URL для GitLab UI; парсит ID задачи из имени ветки.
  - `/experiments-audit` — раз в месяц сканирует `experiments/` на кандидатов к удалению (только отчёт, не удаляет).
- Скрипты (Фаза 6):
  - `scripts/build-adr-index.py` — генератор `docs/adr/INDEX.md`; поддерживает `--check` для CI/pre-commit.
  - `scripts/build-changelog.py` — собирает `CHANGELOG.md` из фрагментов `changelogs/unreleased/*.md`, делает `git rm` на исходники.
  - `scripts/pre-push-guard.sh` расширен: запрет push в `main`/`master` с исключением для первого bootstrap-push и env-флага `PRE_PUSH_GUARD_ALLOW_MAIN=1` для релиз-инженера.
- Шаблоны и CODEOWNERS (Фаза 7):
  - `CODEOWNERS` в корне seed-репо с плейсхолдерами `@<role>`.
  - `.gitlab/merge_request_templates/default.md` — полный MR template.
  - `.claude/templates/CLAUDE.local.md.example` и `.claude/templates/settings.local.json.example` — заготовки для `/onboard-developer`.
  - `changelogs/unreleased/README.md` — описание паттерна «один файл = одна запись».
- `security/dangerous-commands.md` (Фаза 8):
  - deny: добавлены `git push origin main/master`, broad-form `git push * main*`, удаление и перезапись release-тегов (`git tag -d v*`, `git push * --delete *v*`, `git push * :refs/tags/v*`, `git update-ref -d refs/tags/v*`, `git tag -f v*`).
  - ask: `--force-with-lease` — допустим в свою feature-ветку с подтверждением; добавлены `git rebase origin/main*`, `git merge*`, `git tag*`.
  - Раздел «Branch protection на GitLab» переписан как обязательные настройки для работы методологии.
- `.pre-commit-config.yaml`: хук `build-adr-index` регенерирует `docs/adr/INDEX.md` при изменении ADR-файлов (Фаза 9).
- `.gitlab-ci.yml`: минимальный starter pipeline (lint: pre-commit + validate-links + `build-adr-index --check`; test/build/security — заглушки до `/adopt-stack`; deploy:* закомментировано по регламенту GitLab workflow §10) (Фаза 9).

### Changed

- `.gitignore`: добавлены `CLAUDE.local.md` и AI-инструмент cache (`.aider.chat.history.md`, `.aider*.bak`, `.cursor/cache/`) (Фаза 7).

### Removed

- `migrations/v0.1-to-v0.2.md` и `migrations/v0.2-to-v0.3.md` — это история переходов `solo+ai`, не применимая к новой методологии (Фаза 1).

### Verified by smoke-test (Фаза 11)

Прогон 2026-05-22 на свежесозданной копии `team+ai/`:

- `scripts/validate-links.sh --report` — 84 md, 540 ссылок, **0 ошибок, 0 warnings** (после фикса 18 битых ссылок на мета-ADR — переведены на GitHub-URL, и `../playbooks/` → `../../playbooks/` в `changelogs/unreleased/README.md`, `../../../AGENTS.md` → `../../AGENTS.md` в MR-template).
- `scripts/build-adr-index.py` — корректно работает на пустой папке (`_Пока ни одного ADR._`), после добавления синтетического ADR парсит статус, дату и summary из `## Decision`, флаг `--check` идемпотентен.
- `scripts/build-changelog.py` — корректно собирает фрагменты `changelogs/unreleased/*.md` (пропуская `README.md`), группирует по Keep-a-Changelog подсекциям, вставляет новый блок `## [X.Y.Z] — DATE` под `## [Unreleased]` (оставляя пустую секцию для будущих записей), делает `git rm` исходных фрагментов.
- `scripts/pre-push-guard.sh` — три сценария: (а) первый push (origin/<branch> не существует) → разрешает с информационным сообщением; (б) push в master без env-флага → блокирует с подсказкой создать feature-ветку и предложением env-флага для релиз-инженера; (в) push в master с `PRE_PUSH_GUARD_ALLOW_MAIN=1` → разрешает.

### Compatibility

- Не применимо: первая версия методологии.
