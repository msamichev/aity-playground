# Save All Playbook

> **Универсальная процедура.** Читается любым AI: Claude, Codex, DeepSeek, Minimax, Cursor, Gemini, Aider и т.п.
> **Триггер:** `/save-all` или соответствующая фраза на естественном языке (см. таблицу триггеров в [AGENTS.md](../AGENTS.md)).
> **Тонкая обёртка для Claude Code:** [.claude/skills/save-all/SKILL.md](../.claude/skills/save-all/SKILL.md).

---

Полный сейв: коммит + push **в текущую feature-ветку** (push в `main` запрещён регламентом).

## Алгоритм

1. **Проверь текущую ветку**:
   ```bash
   current_branch=$(git rev-parse --abbrev-ref HEAD)
   if [ "$current_branch" = "main" ]; then
     echo "Ошибка: push в main запрещён. Создай feature-ветку: git checkout -b feature/<ID-задачи>-<slug>"
     exit 1
   fi
   ```
   Ветка должна соответствовать паттернам из [`AGENTS.md §4.3`](../AGENTS.md#43-git): `feature/<ID>-...`, `bugfix/<ID>-...`, `hotfix/<ID>-...`, `chore/...`, `docs/...`. Если нет — остановись и спроси пользователя.
2. Выполни весь алгоритм `/save` (stage + commit поимённо). В теле коммита — обязательный trailer `Refs: <ID-задачи>` (если AI участвовал значимо — также `Co-Authored-By: Claude <noreply@anthropic.com>`).
3. **Перед push**:
   - `scripts/validate-links.sh` — должен быть зелёным.
   - `scripts/ci-push.sh` — должен быть зелёным (это новый дефолт `scripts/local-ci.sh` после v0.3.0). Эквивалент `pre-commit run --all-files` (Fast-уровень) — установлен как git hook и срабатывает на самом commit. Если pre-commit hook ещё не настроен — сначала `scripts/local-ci.sh --fast`.
   - **Self-review checklist** ([`playbooks/self-review.md`](self-review.md)) **не обязателен** на этом этапе: push в feature-ветку — это checkpoint, фича может быть не готова. Self-review читается **перед `/open-mr`** (см. [open-mr.md](open-mr.md)).
   - Глубокие проверки (`scripts/ci-deep.sh`: mutation, SBOM, container scan) — opt-in локально перед `/open-mr` для отладки. Основное место запуска — GitLab CI nightly (`security-deep:nightly`).
4. `git push -u origin "$current_branch"` (либо `git push --force-with-lease`, если ветка уже существует на origin и нужно перепушить после rebase).
5. Если в `origin` ещё нет открытого MR из этой ветки в `main` — предложи запустить `/open-mr`.
6. Покажи URL pipeline-а для текущей ветки:
   - GitLab CI: `https://gitlab.com/<owner>/<repo>/-/pipelines?ref=<branch>`

## Правила

- **Push в `main` запрещён.** Локально его блокирует `scripts/pre-push-guard.sh`, на сервере — branch protection. Любые изменения в `main` идут только через MR (см. [`/open-mr`](open-mr.md)).
- `--force-with-lease` — допустим только в **свою** feature-ветку (например, после rebase на свежий `main`). `--force` запрещён всюду. Force-push в защищённые ветки — запрещён.
- Если CI на стороне сервера упадёт — **не делай повторный push с фиксом сразу**. Сначала разберись, что именно упало.

## Что НЕ делает

- **Не открывает MR.** Это отдельная команда [`/open-mr`](open-mr.md).
- **Не делает bump версии методологии.** Это отдельная команда `/release` (см. [release.md](release.md)).
- Не запускает деплой автоматически — это manual.

## Связки

- [save playbook](save.md) — без push
- [open-mr playbook](open-mr.md) — открытие MR после push (читает self-review)
- [self-review playbook](self-review.md) — pre-MR смысловой чек-лист (не на этом этапе, перед `/open-mr`)
- [full-ahead playbook](full-ahead.md) — полный цикл с автокоммитом
- [../scripts/ci-push.sh](../scripts/ci-push.sh) — pre-push гейт (Шаг 3)
- [../scripts/ci-deep.sh](../scripts/ci-deep.sh) — opt-in локальная отладка
- [../scripts/local-ci.sh](../scripts/local-ci.sh) — фасад трёх уровней
- [AGENTS.md §4.3](../AGENTS.md#43-git) — конвенции Git
- [AGENTS.md §5 п.10](../AGENTS.md#5-правила-работы-ai-ассистента) — правило «перед push»
