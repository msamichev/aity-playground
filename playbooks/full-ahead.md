# Full Ahead Playbook

> **Универсальная процедура.** Читается любым AI: Claude, Codex, DeepSeek, Minimax, Cursor, Gemini, Aider и т.п.
> **Триггер:** `/full-ahead` или соответствующая фраза на естественном языке (см. таблицу триггеров в [AGENTS.md](../AGENTS.md)).
> **Тонкая обёртка для Claude Code:** [.claude/skills/full-ahead/SKILL.md](../.claude/skills/full-ahead/SKILL.md).

---

Полный локальный CI-цикл + autonomous progression. Аналог «полный вперёд» из PMatrix.

## Когда использовать

После того как закончил работу над фичей в собственной feature-ветке и готов выложить её в `origin` + открыть MR в `main`. До запуска — `git status` показывает осмысленные изменения, текущая ветка — **не `main`**, имя ветки соответствует паттерну `<тип>/<ID-задачи>-<slug>` ([AGENTS.md §4.3](../AGENTS.md#43-git)).

**Не использовать:**
- На ветке `main` — push в `main` запрещён, скрипт остановится с ошибкой.
- В Phase 0 (нет кода — нечего тестировать). Используй `/save` вместо.
- Если изменения частичные (план не завершён) — лучше `/save`, потом доделать, потом `/full-ahead`.

## Алгоритм

### Шаг 1. Предварительные проверки

```bash
git status                            # должен показывать осмысленные изменения
scripts/validate-links.sh             # граф зелёный
```

Если граф красный — почини **до** запуска основного цикла.

### Шаг 2. Локальный pre-push CI

```bash
scripts/ci-push.sh
```

Это **дефолтный гейт перед push в feature-ветку**: build/types → SAST + secrets → SCA + license → tests + coverage. Минуты, не десятки минут.

Подразумевается, что pre-commit hook уже установлен (`pre-commit install --hook-type pre-commit --hook-type commit-msg`) и стадия `ci-fast.sh` отработала на самом коммите. Если не установлен — сначала прогнать `scripts/local-ci.sh --fast` (или `scripts/ci-fast.sh`).

**Deep-проверки** (mutation, SBOM, container/IaC scan) в команде живут как **GitLab CI nightly job** `security-deep:nightly` (см. `.gitlab-ci.yml`). Локальный `scripts/ci-deep.sh` — opt-in для отладки конкретной регрессии перед `/open-mr`. По умолчанию `/full-ahead` его не запускает.

Эквиваленты:

- `scripts/local-ci.sh` без флагов = `ci-push.sh`.
- `scripts/local-ci.sh --fast` = `ci-fast.sh`.
- `scripts/local-ci.sh --deep` = `ci-push.sh` + `ci-deep.sh` (только локальная отладка).

### Шаг 3. Autonomous fix loop

Если какой-то шаг упал:

1. Прочитай вывод, определи **что именно** упало (билд, тест, mutation, security).
2. Если это однозначная техническая ошибка (linter, type error, missing import) — **чини сам**, без подтверждения.
3. Если это семантическая ошибка (логика, тест на бизнес-правило) — **остановись и спроси пользователя**.
4. После фикса — перезапусти `scripts/ci-push.sh`.
5. Повторяй пока всё не зелёное.

**Hard limit:** не больше 5 итераций. Если за 5 циклов не зелёное — остановись, доложи пользователю что застрял, попроси разобрать вручную.

### Шаг 4. Subagent review-gate (только если включён autonomous mode)

**Эта секция применяется, только если в `AGENTS.md §0` есть `autonomous_mode: enabled`.** В обычном режиме переходи к Шагу 5.

После того как `scripts/ci-push.sh` зелёный, прогоняем four-gate review:

#### 4.1. `code-reviewer` subagent

Вызывай явно: «Запусти `code-reviewer` subagent на staged-изменениях».

- Subagent возвращает структурированный отчёт (формат — в [`.claude/agents/code-reviewer.md`](../.claude/agents/code-reviewer.md)).
- Если **ВЕРНУТЬ В РАБОТУ** — основная сессия применяет блокеры. После фикса — повторный прогон `scripts/ci-push.sh` + повторный вызов `code-reviewer`.
- **`maxTurns: 2`.** Третий раз с тем же классом проблем → эскалация пользователю с конкретным вопросом, цикл не продолжаем.
- Если **ОДОБРЕНО** — переход к 4.2.

#### 4.2. `test-runner` subagent

Вызывай: «Запусти `test-runner` subagent».

- Subagent прогоняет полный набор тестов, ищет незакрытые edge-cases, предлагает 1-3 новых теста.
- Если **ВЕРНУТЬ В РАБОТУ** — применяй предложенные тесты, чини падения. Повторный прогон.
- **`maxTurns: 2`** для цикла Test↔Coder. Третий раз — эскалация.
- Если **ОДОБРЕНО** или **ПРОПУЩЕНО** (нет тестов в Phase 1 без тестового стека) — переход к 4.3.

#### 4.3. `security-auditor` subagent — условно

Запускается, если staged-изменения затрагивают критичные модули. Эвристика:

- Файлы содержат `auth`, `login`, `password`, `token`, `payment`, `billing`, `upload`, `download`, `crypto`, `secret`, `env`.
- Изменения в обработчиках user input на бэкенде.
- Использование `eval`, `exec`, `subprocess`, `os.system`, `pickle.loads`, `yaml.load` без `safe_load`.
- Изменения в `security/dangerous-commands.md` или `.claude/settings.json`.

Если ни одно условие не сработало — `security-auditor` пропускается до `/release`.

Если запускается:
- Subagent возвращает отчёт с классификацией Sev1/Sev2/Sev3.
- **Sev1** — блокер. Чини, повтори. `maxTurns: 2`, потом эскалация.
- **Sev2** в `/full-ahead` — suggest (запиши в `plans/<feature>.md`, не блокер). В `/release` — блокер.
- **Sev3** — всегда suggest.

#### 4.4. `merge-coordinator` subagent

Запускается перед коммитом и push. В отличие от code-reviewer/test-runner/security-auditor, который смотрят на код, [`merge-coordinator`](../.claude/agents/merge-coordinator.md) проверяет состояние feature-ветки относительно команды:

- Имя ветки и `Refs:` trailer в коммитах.
- Rebase на свежий `origin/main` (предварительно сделай `git fetch origin --quiet`).
- Коллизии timestamp-имён в `docs/adr/` (если в feature-ветке есть новые ADR).
- Наличие фрагмента `changelogs/unreleased/<ID>-<slug>.md` для пользовательских изменений.
- Имя файла плана с ID задачи.

Если **ЕСТЬ БЛОКЕРЫ** — основная сессия применяет фиксы (rebase, переименование ADR, создание changelog-фрагмента) и повторяет. `maxTurns: 2`; третий раунд — эскалация.

Если **МОЖНО ОТКРЫВАТЬ MR** — переходи к 4.5.

#### 4.5. Проверка критерия приёмки

Если в `plans/<feature>.md` есть секция `## Критерий приёмки` (markdown checklist) — пройдись по пунктам, отметь выполненные (`[x]`). Если есть невыполненный — цикл не завершён, возвращайся к Шагу 1.

### Шаг 5. Stop hook чеклист

В autonomous mode на событие `Stop` срабатывает `scripts/stop-checklist.sh` ([`stop-checklist.sh`](../scripts/stop-checklist.sh)). Он проверяет:

- `scripts/ci-push.sh` зелёный.
- `scripts/validate-links.sh` зелёный.
- `gitleaks detect --staged` чисто.
- Все пункты `## Критерий приёмки` в активном плане отмечены `[x]`.

Если чеклист красный — autonomous mode помечает фичу **как не выполненную**, цикл не закрывает, и докладывает пользователю.

### Шаг 6. Коммит и push в feature-ветку

Когда всё зелёное (`scripts/ci-push.sh` + four subagent-гейтов + Stop hook):

1. Запусти алгоритм из `/save-all`:
   - проверка что текущая ветка — не `main` и соответствует паттерну `<тип>/<ID>-<slug>`
   - stage поимённо
   - conventional commit message с trailer `Refs: <ID-задачи>` (покажи пользователю перед коммитом)
   - `git push -u origin <current-branch>` (в свою feature-ветку, **не в main**)
2. **Если за этим push следует `/open-mr`** — сейчас самое время прочитать [`playbooks/self-review.md`](self-review.md) (7-пунктный смысловой чек-лист). Это правило AGENTS.md §5 п.10. Если хоть один пункт красный — фикс и повторный прогон `scripts/ci-push.sh`; не открывай MR с красным чек-листом.
3. Если в `origin` ещё нет открытого MR из этой ветки — предложи запустить `/open-mr` для открытия Merge Request в `main`.
4. Если это промежуточный feature-checkpoint push (фича ещё не готова к ревью) — self-review **не нужен**, просто доложи о push.
5. Доложи о результате.

### Шаг 7. Ретро (опционально)

Если в процессе было что-то нетривиальное (несколько итераций, неожиданный фикс) — предложи `/retro`.

## Правила

- **В autonomous loop — без подтверждения** на каждый шаг. Это и есть «vibe».
- Семантические фиксы (бизнес-логика, тесты на смысл) — всегда **остановиться и спросить**.
- При повторяющейся ошибке (одна и та же 2+ раза) — остановись, не толчи. Доложи.
- Не отключай гейты (`--no-verify`, `--skip-tests`) — лучше зафиксировать что упало и разбираться.
- **Writes — только основная сессия.** Subagents в Шаге 4 — read-only по контракту. Не пытайся попросить их что-то поправить.
- **maxTurns цикла Subagent↔Coder = 2.** Третий раз тот же класс проблем = эскалация, не продолжаем цикл.

## Три уровня локального CI

После `/adopt-stack` локальный CI разнесён по трём уровням (см. [ADR-1432](https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260518-1432-split-local-ci-into-tiers.md) + [team+ai-специфика 20260522-1400](https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260522-1400-team-ai-ci-tiers-with-gitlab-nightly-deep.md)):

| Уровень | Скрипт | Где | Что внутри |
|---|---|---|---|
| **Fast** | `scripts/ci-fast.sh` | локально, каждый commit | Pre-commit: формат, линт, секреты, conventional commits |
| **Push** | `scripts/ci-push.sh` | локально, перед push в feature-ветку | Build & types; SAST + gitleaks **+ semgrep** (`p/security-audit` + `p/insecure-deserialization`); SCA + license (trivy fs); tests + coverage; **code-clone (jscpd `--threshold 5`)** |
| **Deep** | `scripts/ci-deep.sh` | **GitLab CI nightly** (`security-deep:nightly`); локально — opt-in для отладки | **Mutation testing** (75% / 85% критичные), SBOM, container/IaC scan |

Раньше всё это было одним `scripts/local-ci.sh` из 9 шагов — но прогон mutation/SBOM/container в pre-push гейте умножает время команды на N разработчиков × M итераций.

Self-review checklist выделен в отдельный [`playbooks/self-review.md`](self-review.md) — 7 пунктов, читает автор **перед `/open-mr`** (Шаг 6.2 этого playbook'а). Не перед каждым checkpoint push. Дополняет `merge-coordinator` (структурные vs смысловые).

`scripts/local-ci.sh` остаётся фасадом: без флагов = `ci-push.sh`, `--fast` = `ci-fast.sh`, `--deep` = `ci-push.sh` + `ci-deep.sh` (для локальной отладки регрессий).

## Связки

- [scripts/ci-fast.sh](../scripts/ci-fast.sh) — pre-commit уровень
- [scripts/ci-push.sh](../scripts/ci-push.sh) — pre-push уровень (дефолт в Шаге 2)
- [scripts/ci-deep.sh](../scripts/ci-deep.sh) — opt-in локально; основное место — GitLab CI nightly
- [scripts/local-ci.sh](../scripts/local-ci.sh) — фасад трёх уровней
- [scripts/stop-checklist.sh](../scripts/stop-checklist.sh) — Stop hook чеклист (Шаг 5)
- [self-review playbook](self-review.md) — 7-пунктный смысловой чек-лист перед `/open-mr` (Шаг 6.2)
- [open-mr playbook](open-mr.md) — pre-MR gate, читает self-review
- [save-all playbook](save-all.md) — простой push в feature-ветку без полного цикла
- [autonomous-mode playbook](autonomous-mode.md) — флаги, контракт и эскалации
- [plan playbook](plan.md) — где формализуется критерий приёмки, используемый в Шаге 4.5
- [.claude/agents/code-reviewer.md](../.claude/agents/code-reviewer.md) — Шаг 4.1
- [.claude/agents/test-runner.md](../.claude/agents/test-runner.md) — Шаг 4.2
- [.claude/agents/security-auditor.md](../.claude/agents/security-auditor.md) — Шаг 4.3
- [.claude/agents/merge-coordinator.md](../.claude/agents/merge-coordinator.md) — Шаг 4.4
- [METHODOLOGY.md «Качество кода»](../METHODOLOGY.md#9-качество-кода) — три уровня гейта
- [.gitlab-ci.yml](../.gitlab-ci.yml) — `security-deep:nightly` job
- [https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260522-1400-team-ai-ci-tiers-with-gitlab-nightly-deep.md](https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260522-1400-team-ai-ci-tiers-with-gitlab-nightly-deep.md) — ADR с поправками под MR-флоу
- [https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260518-1432-split-local-ci-into-tiers.md](https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260518-1432-split-local-ci-into-tiers.md) — базовый ADR про разнесение
- [https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260520-1700-autonomous-mode-with-readonly-subagents.md](https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260520-1700-autonomous-mode-with-readonly-subagents.md) — ADR, вводящий Шаг 4 и Шаг 5
