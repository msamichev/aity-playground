# Release Playbook

> **Универсальная процедура.** Читается любым AI: Claude, Codex, DeepSeek, Minimax, Cursor, Gemini, Aider и т.п.
> **Триггер:** `/release` или фразы «делаем релиз», «bump версии», «выкатываем новую версию», «зарелизим».
> **Тонкая обёртка для Claude Code:** [.claude/skills/release/SKILL.md](../.claude/skills/release/SKILL.md).

---

## Что делает

Финализирует версию методологии. Двигает [`VERSION`](../VERSION), переписывает секцию `## [Unreleased]` в [`CHANGELOG.md`](../CHANGELOG.md) под конкретную версию, при MINOR/MAJOR — создаёт черновик гайда в [`migrations/`](../migrations/), делает release-коммит. **Не пушит** — push отдельно через `/save-all`.

## Когда запускать

- Накопилось несколько изменений в файлах методологии, хочется зафиксировать как версию.
- Перед публикацией / перед копированием в новый проект, чтобы baseline был чистый.
- После завершения большой работы (закрытие плана, выполнение ADR).

**Не запускать:**
- На каждый коммит — это не semantic-release. Релиз ≠ коммит.
- В скопированном проекте (продуктовом), если ты не правишь файлы самой методологии. VERSION методологии не имеет смысла поднимать в проекте, который её просто использует.

## Принцип: один файл на MR против merge-конфликтов

В team+ai **отдельная аккумулирующая секция `## [Unreleased]` в `CHANGELOG.md` не ведётся** (она была бы постоянным источником merge-конфликтов при параллельной работе нескольких разработчиков). Вместо этого:

- Каждый MR кладёт **отдельный файл** в `changelogs/unreleased/<ID-NNN>-slug.md` со своей записью (формат Keep a Changelog внутри файла: подсекции `### Added` / `### Changed` / `### Fixed` / `### Removed` / `### Deprecated` / `### Security`).
- `/release` собирает все эти файлы в один блок `## [X.Y.Z] — DATE` в `CHANGELOG.md` через скрипт [`scripts/build-changelog.py`](../scripts/build-changelog.py), затем удаляет исходные фрагменты.

Это паттерн [GitLab CHANGELOG conflict crisis](https://about.gitlab.com/blog/solving-gitlabs-changelog-conflict-crisis/) — единственный надёжный антидот против merge-конфликтов на CHANGELOG.

Без файла-фрагмента к MR `scripts/build-changelog.py` пропустит ваш вклад в release notes. Pre-commit это не валидирует — это вопрос команды.

## Алгоритм

### Шаг 0. Проверь, что мы в правильном репо

```bash
test -f VERSION || { echo "VERSION-файл не найден. Это либо не корень методологии, либо методология старой ревизии."; exit 1; }
test -f CHANGELOG.md || { echo "CHANGELOG.md не найден."; exit 1; }
```

### Шаг 1. Зафиксируй текущую версию и diff

```bash
CURRENT_VERSION="$(cat VERSION)"
# Найди коммит, в котором VERSION в последний раз менялся:
LAST_BUMP_COMMIT="$(git log --pretty=format:%H -- VERSION | head -1 || true)"
# Если VERSION-файл новый (только что создан) — diff от первого коммита.

# Что менялось в файлах методологии с прошлого bump'а:
git log --oneline ${LAST_BUMP_COMMIT:+${LAST_BUMP_COMMIT}..}HEAD -- . ':!VERSION' ':!CHANGELOG.md'
git diff --stat ${LAST_BUMP_COMMIT:+${LAST_BUMP_COMMIT}..}HEAD -- . ':!VERSION' ':!CHANGELOG.md'
```

Если **с прошлого bump'а нет ни одного коммита в файлах методологии** (только VERSION/CHANGELOG двигались) — отказывайся: «Нечего релизить. Сначала сделай и закоммить правки.»

### Шаг 2. Собери фрагменты из changelogs/unreleased/

```bash
ls changelogs/unreleased/*.md 2>/dev/null | wc -l
```

- **Если файлов нет** — попроси пользователя кратко перечислить изменения (источник: git log из Шага 1). Объясни: для будущих релизов каждый MR должен класть свой фрагмент в `changelogs/unreleased/`, иначе вклад теряется.
- **Если файлы есть** — используй их как источник истины. Покажи пользователю summary (сколько файлов, какие подсекции встречаются) перед сборкой.

### Шаг 3. Предложи уровень bump'а

Эвристика для предложения (не для автономного решения):

| Признак в diff / [Unreleased] | Уровень |
|---|---|
| Удалены / переименованы playbook-и или skills; удалены / переименованы корневые файлы (`AGENTS.md`, `VERSION`, `CHANGELOG.md`); меняется формат имён файлов; меняется обязательный шаг в `init-project`, `adopt-stack`, `adopt-architecture`; ужесточаются правила в `security/dangerous-commands.md` так, что прошлые проекты могут сломаться | **MAJOR** |
| Добавлены новые playbook-и / skills; новая функциональность в существующих (новые шаги, новые секции); новые опциональные инструменты в `expected-tools.md`; новые рекомендуемые skills; обновление дефолтов без breaking | **MINOR** |
| Опечатки, формулировки, обновление версий хуков в `.pre-commit-config.yaml` без breaking, мелкие правки текста, ссылки, документация | **PATCH** |

В пограничном случае — выбирай более высокий уровень (лучше MINOR без переделок, чем PATCH с тихим breaking).

Сформулируй пользователю **одно предложение**:

> Предлагаю **MINOR** (v0.1.0 → v0.2.0). Обоснование: добавлена команда `/release`, в `/doctor` появилась проверка активации git-хуков, материализованы `VERSION`/`CHANGELOG`/`migrations/`. Breaking-изменений нет. Подтверди уровень или укажи свой.

Жди ответа. Если пользователь говорит другой уровень — используй его без споров (он лучше знает контекст).

### Шаг 4. Посчитай новую версию

```bash
# Псевдокод:
case "$LEVEL" in
  MAJOR) echo "${MAJOR}+1.0.0" ;;     # 0.1.0 → 1.0.0
  MINOR) echo "${MAJOR}.${MINOR}+1.0" ;;  # 0.1.0 → 0.2.0
  PATCH) echo "${MAJOR}.${MINOR}.${PATCH}+1" ;;  # 0.1.0 → 0.1.1
esac
```

**Особый случай для версии 0.x.x:** в pre-1.0 эпохе допустимы breaking-изменения и на MINOR. Это нормально — отметь в migration guide, но MINOR-bump'ишь без перехода на 1.0.0. Переход на 1.0.0 — отдельное решение «методология стабильна и публикуется официально», делается явным ADR.

### Шаг 5. Двинь VERSION

```bash
echo "$NEW_VERSION" > VERSION
# Файл должен оканчиваться newline'ом (одна строка + \n).
```

### Шаг 6. Собери CHANGELOG.md из changelogs/unreleased/

```bash
scripts/build-changelog.py --version "$NEW_VERSION" --date "$(date +%Y-%m-%d)"
```

Скрипт:
- читает все `changelogs/unreleased/*.md`,
- группирует записи по подсекциям `Added/Changed/Fixed/Removed/Deprecated/Security`,
- вставляет новый блок `## [<NEW_VERSION>] — <DATE>` под существующей `## [Unreleased]` (которая остаётся пустой каркасной секцией для следующего релиза) в `CHANGELOG.md`,
- удаляет исходные файлы из `changelogs/unreleased/`.

Если пользователь продиктовал записи вручную (Шаг 2 — файлов не было) — заполни подсекции `Added/Changed/Fixed/Removed/Deprecated/Security` в новом блоке руками. Пустые подсекции не показывай.

### Шаг 7. Если MINOR или MAJOR — черновик migration guide

Создай файл `migrations/v<from>-to-v<to>.md` по шаблону:

```markdown
# Миграция v<from> → v<to>

Кратко: что нужно сделать в **уже скопированном проекте**, чтобы подтянуть изменения этой версии методологии.

## Зачем мигрировать

<1-2 предложения: чем версия отличается, ради чего апгрейд>

## Шаги

1. <конкретный шаг — что заменить / добавить в проекте>
2. ...

## Что НЕ нужно делать

<типичные ошибки при апгрейде>

## Связки

- [../CHANGELOG.md](../CHANGELOG.md) — полный список изменений в v<to>
```

Для PATCH-bump'а гайд НЕ нужен (по [ADR-1501](../docs/adr/) — markdown-migration-guides).

### Шаг 8. Валидация

```bash
scripts/validate-links.sh --report   # должно быть зелёным
cat VERSION                          # подтверди значение
```

### Шаг 9. Release-коммит и тег

Поимённо (никаких `git add -A`). Включаем удалённые `changelogs/unreleased/*.md` (через `git rm`, который `build-changelog.py` уже сделал — это в индексе).

```bash
git add VERSION CHANGELOG.md
git add -u changelogs/unreleased/      # удаления файлов после сборки
# Если был создан migration guide:
git add migrations/v<from>-to-v<to>.md
```

Коммит-сообщение (Conventional Commits, тип `chore`):

```
chore(release): v<NEW_VERSION>

<краткое summary что в этом релизе — 2-3 строки из CHANGELOG>

См. CHANGELOG.md и migrations/v<from>-to-v<to>.md (если есть).
```

Аннотированный тег:

```bash
git tag -a "v$NEW_VERSION" -m "Release v$NEW_VERSION"
```

Тег создаётся **локально**. Push тега — отдельный ручной шаг релиз-инженера (см. Шаг 10). Тег не удаляется и не переписывается ([AGENTS.md §4.3](../AGENTS.md#43-git)).

### Шаг 10. НЕ пушь автоматически

В team+ai push в `main` запрещён, и `/release` не имеет прав туда писать. Релиз-инженер делает это вручную и сознательно:

```bash
# После того как release-коммит мерж в main через MR (или прямо релиз-инженером, если репо позволяет в момент релиза):
git push origin main
git push origin "v$NEW_VERSION"
```

Это сознательное разделение: bump версии — локальное решение; публикация — отдельный шаг с проверками CI и формальным релиз-процессом (см. регламент GitLab workflow §9).

Скажи пользователю:

> ✅ Релиз v<NEW_VERSION> зафиксирован локально.
>
> - `VERSION` → v<NEW_VERSION>
> - `CHANGELOG.md` — собран блок `[v<NEW_VERSION>] — <DATE>` из `changelogs/unreleased/`. Исходные файлы удалены.
> - migration guide: <путь или «не создавался, PATCH»>.
> - Коммит: `chore(release): v<NEW_VERSION>`.
> - Локальный тег: `v<NEW_VERSION>`.
>
> Дальше: открой MR в `main` (`/open-mr`) и после approve и merge — push тега релиз-инженером (`git push origin v<NEW_VERSION>`). Затем — GitLab Release в UI и деплой `staging` → `prod` по регламенту.

## Что НЕ делает

- **Не пушит** — push отдельно, ручной шаг релиз-инженера.
- **Не запускает CI / тесты** — это `/full-ahead`.
- **Не двигает версию автоматически без подтверждения** — уровень bump'а всегда подтверждается пользователем.
- **Не делает релиз** при пустом diff (нечего релизить).
- **Не открывает MR** — отдельно через `/open-mr` после release-коммита.
- **Не публикует GitLab Release** — это manual в GitLab UI по регламенту workflow §9.

## Связки

- [VERSION](../VERSION) — единственный источник правды для текущей версии
- [CHANGELOG.md](../CHANGELOG.md) — история, в формате Keep a Changelog
- [migrations/](../migrations/) — гайды перехода между версиями
- [save-all.md](save-all.md) — следующий шаг после релиза (push)
- [AGENTS.md §9](../AGENTS.md#9-когда-обновлять-этот-файл) — правило про [Unreleased]
- [METHODOLOGY.md §10.1](../METHODOLOGY.md) — общие сведения о версионировании
