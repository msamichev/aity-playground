# Open MR Playbook

> **Универсальная процедура.** Читается любым AI: Claude, Codex, DeepSeek, Minimax, Cursor, Gemini, Aider и т.п.
> **Триггер:** `/open-mr` или фразы «открой MR», «давай PR», «open mr».
> **Тонкая обёртка для Claude Code:** [.claude/skills/open-mr/SKILL.md](../.claude/skills/open-mr/SKILL.md).

---

Открывает Merge Request в `main` из текущей feature-ветки. Использует `glab` CLI, либо печатает URL для открытия в GitLab UI вручную.

## Когда использовать

После того как `/save-all` или `/full-ahead` запушили коммит в feature-ветку. Изменения готовы к ревью.

**Не использовать:**
- На `main` или защищённой ветке — нечего ревьюить.
- Если работа не завершена — лучше Draft MR, который ты создашь явно с флагом `--draft`.
- Если pipeline в origin/feature ещё не отработал — подожди (или открывай Draft).

## Алгоритм

### Шаг 1. Сбор контекста

```bash
current_branch=$(git rev-parse --abbrev-ref HEAD)

# Защита: не на main
[ "$current_branch" = "main" ] && { echo "Нельзя открывать MR из main."; exit 1; }

# Защита: ветка соответствует паттерну
if ! echo "$current_branch" | grep -qE '^(feature|bugfix|hotfix|chore|docs)/'; then
  echo "Имя ветки '$current_branch' не соответствует паттерну '<тип>/<ID>-<slug>'. См. AGENTS.md §4.3."
  exit 1
fi

# Извлечь ID задачи из имени ветки (для типов кроме chore/docs)
task_id=$(echo "$current_branch" | grep -oE '<ID-PREFIX>-[0-9]+' || echo "")
```

`<ID-PREFIX>` берётся из `AGENTS.md §0` поле `id_prefix` (например, `PROJ`).

### Шаг 2. Pre-flight проверки

- Текущая ветка запушена в origin: `git rev-parse "@{u}" >/dev/null 2>&1` (если нет upstream — `git push -u origin "$current_branch"`).
- `scripts/ci-push.sh` зелёный (build, types, SAST + gitleaks, SCA, tests). Минимум — `scripts/validate-links.sh` + Fast-уровень.
- Нет несохранённых изменений: `git diff --quiet && git diff --cached --quiet`.
- Если в `changelogs/unreleased/` ещё нет файла-фрагмента под эту задачу — предложи создать (это требование для будущего `/release`, см. [release.md](release.md)).
- **Если изменения затрагивают критичные модули или вызывают тревогу** (auth, payments, секреты, обработка пользовательского ввода) — рассмотри `scripts/local-ci.sh --deep` для локальной отладки до открытия MR. Иначе deep-проверки сами отработают в GitLab nightly (`security-deep:nightly`).

### Шаг 3. Подготовь title и описание

**Title** — последний коммит в feature-ветке (Conventional Commits), без trailer'ов:

```bash
title=$(git log -1 --pretty=%s)
```

**Description** — берётся из шаблона `.gitlab/merge_request_templates/default.md` (он применяется автоматически в GitLab UI, если шаблон существует). В тело подставляются:
- Прямая ссылка на задачу в трекере: `<tracker_url из AGENTS.md §0>/<task_id>`.
- Раздел «Что сделано» — из тела коммита.
- Раздел «Как проверить» — заполняется автором; если AI работал в autonomous mode и есть `## Критерий приёмки` в плане — скопируй пункты.
- Чек-лист (тесты добавлены, доки обновлены, нет секретов, pipeline зелёный) — из шаблона.
- Trailer `Refs: <task_id>`.

### Шаг 3.5. Self-review (обязательный pre-MR гейт)

Прочитай [`playbooks/self-review.md`](self-review.md) — 7-пунктный смысловой чек-лист. Это правило [AGENTS.md §5 п.10](../AGENTS.md#5-правила-работы-ai-ассистента).

- **Все пункты зелёные** → переходи к Шагу 4.
- **Хоть один красный** → стоп. Объясни пользователю, какой именно пункт красный, что предлагаешь сделать. После фикса — повторный прогон `scripts/ci-push.sh` и повторное чтение чек-листа.

Self-review **дополняет** `merge-coordinator` (следующий шаг), не дублирует. Разделение:
- Self-review — **смысловые** проверки (логика соответствует плану, нет swallowed errors, secrets/PII в логах, обратная совместимость).
- merge-coordinator — **структурные** проверки (rebase, ADR, changelog-фрагмент, `Refs:` trailer).

### Шаг 4. Прогон merge-coordinator subagent

Перед открытием MR обязательно прогони read-only subagent [`merge-coordinator`](../.claude/agents/merge-coordinator.md). Он проверяет специфичные для команды инварианты, которые `code-reviewer`/`test-runner`/`security-auditor` не покрывают:

- Имя ветки и `Refs:` trailer в коммитах.
- Rebase на свежий `origin/main` (выполни `git fetch origin --quiet` перед запуском subagent'а).
- Коллизии timestamp-имён в `docs/adr/` между текущей веткой и `origin/main`.
- Наличие фрагмента `changelogs/unreleased/<ID>-<slug>.md` для пользовательских изменений.
- Имя файла плана содержит ID задачи.

Реакция:
- **МОЖНО ОТКРЫВАТЬ MR** — переходи к Шагу 5.
- **ЕСТЬ БЛОКЕРЫ** — основная сессия применяет фиксы (rebase, переименование ADR, создание changelog-фрагмента и т.п.), затем повторный прогон. `maxTurns: 2`; на 3-м раунде того же класса блокеров — эскалация пользователю.

### Шаг 4.5. Опционально — прогон /critic

Если изменения нетривиальные — предложи пользователю запустить `/critic` (см. [critic.md](critic.md)) **до** открытия MR. Результаты — в Description или в `plans/<plan-file>.md` как дополнения.

### Шаг 5. Открой MR

#### Если установлен `glab`

```bash
glab mr create \
  --source-branch "$current_branch" \
  --target-branch main \
  --title "$title" \
  --description "$mr_description" \
  --squash-before-merge \
  --remove-source-branch \
  --assignee="@me"
```

Reviewers (`--reviewer @<handle>`) — спроси пользователя или возьми из `CLAUDE.local.md` (если там указаны preferred reviewers).

#### Если `glab` не установлен

Распечатай URL для открытия в браузере:

```
https://<gitlab-host>/<group>/<project>/-/merge_requests/new?merge_request[source_branch]=<branch>&merge_request[target_branch]=main
```

И заготовку описания, которую пользователь скопирует в форму.

`<gitlab-host>`, `<group>/<project>` определи из `git config --get remote.origin.url` (нормализуй ssh `git@host:group/project.git` → https `https://host/group/project`).

### Шаг 6. Покажи результат

```
✅ MR открыт: <URL>

Title:        <title>
Source:       <branch>
Target:       main
Task:         <task_id> → <tracker_url>/<task_id>
Reviewers:    @<handle>, @<handle>

Что дальше:
  • Дождись зелёного pipeline.
  • Получи 1+ approve от другого разработчика (не от автора).
  • Все обязательные threads должны быть разрешены.
  • Squash on merge + удаление ветки — автоматически.

Если pipeline упадёт — /save локально, /save-all, обновится тот же MR.
```

## Правила

- **Не открывай MR из main.** Защита в Шаге 1.
- **Не пиши `Closes #N`** — у нас нет GitLab Issues, задача во внешнем трекере. Только `Refs: <task_id>`.
- **Не назначай себя ревьюером.** Минимум 1 approve от другого разработчика (см. [AGENTS.md §4.3](../AGENTS.md#43-git)).
- **Не отключай squash.** В team+ai squash on merge — обязателен (см. регламент).
- **Не закрывай MR за пользователя** даже после approve. Merge button нажимает автор.

## Что НЕ делает

- **Не мержит** — это решение автора после approve и зелёного pipeline.
- **Не делает push сам** — Шаг 2 ожидает, что коммит уже запушен (`/save-all` или `/full-ahead`).
- **Не открывает Draft по умолчанию** — для Draft автор явно говорит «открой Draft MR».
- **Не обновляет статус задачи в трекере** — это вручную или через интеграцию GitLab ↔ трекер.

## Связки

- [save-all playbook](save-all.md) — push в feature перед MR
- [full-ahead playbook](full-ahead.md) — полный цикл с push
- [self-review playbook](self-review.md) — обязательный pre-MR смысловой чек-лист (Шаг 3.5)
- [critic playbook](critic.md) — стресс-тест перед открытием MR
- [release playbook](release.md) — MR с release-коммитом
- [.claude/agents/merge-coordinator.md](../.claude/agents/merge-coordinator.md) — Шаг 4 structural gate
- [../scripts/ci-push.sh](../scripts/ci-push.sh) — pre-push гейт (Шаг 2)
- [../scripts/ci-deep.sh](../scripts/ci-deep.sh) — opt-in локальная отладка перед MR
- [AGENTS.md §4.3](../AGENTS.md#43-git) — git-модель
- [AGENTS.md §5 п.10](../AGENTS.md#5-правила-работы-ai-ассистента) — правило «перед /open-mr — прочитан self-review»
- [.gitlab/merge_request_templates/default.md](../.gitlab/merge_request_templates/default.md) — шаблон описания
- [https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260522-1400-team-ai-ci-tiers-with-gitlab-nightly-deep.md](https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260522-1400-team-ai-ci-tiers-with-gitlab-nightly-deep.md) — ADR, вводящий self-review как pre-MR gate
