# Onboard Developer Playbook

> **Универсальная процедура.** Читается любым AI: Claude, Codex, DeepSeek, Minimax, Cursor, Gemini, Aider и т.п.
> **Триггер:** `/onboard-developer` или фразы «я новый в проекте», «настрой меня», «onboard».
> **Тонкая обёртка для Claude Code:** [.claude/skills/onboard-developer/SKILL.md](../.claude/skills/onboard-developer/SKILL.md).

---

Настраивает рабочее место **второго и последующих разработчиков** после клонирования инициализированного репо. Создаёт локальные конфиги (`CLAUDE.local.md`, `.claude/settings.local.json`), запускает `/doctor`, печатает cheat sheet. **Не пишет в командные файлы.**

## Когда использовать

- Только что склонировал командный репо.
- Хочу настроить свои личные AI-предпочтения, не задев командное.

## Когда НЕ использовать

- Свежий seed-репо без инициализации — нужен `/init-project` (только первый разработчик).
- Командное обновление AGENTS.md / playbooks / scripts — это через MR, а не через `/onboard-developer`.

## Алгоритм

### Шаг 1. Проверь, что репо инициализирован

```bash
# AGENTS.md §0 должен быть заполнен (PROJECT_NAME — не плейсхолдер)
grep -q '<PROJECT_NAME>' AGENTS.md && {
  echo "Репо ещё не инициализирован. Запусти /init-project (если ты первый разработчик)."
  exit 1
}

# docs/idea/ должен быть наполнен
test -s docs/idea/01-idea.md || {
  echo "docs/idea/ выглядит пустым. Команде стоит запустить /init-project / /sync-idea сначала."
  exit 1
}

# CODEOWNERS должен существовать
test -f CODEOWNERS || {
  echo "Нет CODEOWNERS. Команде стоит дозаполнить /init-project (Шаг 5.5)."
  exit 1
}
```

Если любая проверка не прошла — остановись и подскажи, что должна сделать команда.

### Шаг 2. Создай личные конфиги

**2.1. `CLAUDE.local.md`** — личные оверрайды поверх `AGENTS.md`. Создаётся из шаблона `.claude/templates/CLAUDE.local.md.example` (если шаблон есть в репо) или из inline-заготовки:

```markdown
# CLAUDE.local.md

> Личные оверрайды поверх AGENTS.md. **Не коммитится.**
> Этот файл загружается после AGENTS.md и побеждает по конфликтам.
> Используй для индивидуальных предпочтений: стиль ответов, любимые инструменты, личные shortcuts.

## Личные предпочтения

<!-- Например: «Отвечай короче в чате, не разворачивай длинные обоснования» -->

## Локальные инструменты

<!-- Например: «У меня nvm, node 22 — используй именно его» -->

## Личный handle в трекере / GitLab

<!-- Если используешь /open-mr — упомяни здесь свой GitLab username для подстановки в reviewers -->

## Связки

- [AGENTS.md](AGENTS.md) — командный контракт
```

**2.2. `.claude/settings.local.json`** — личные MCP, креды, разовые разрешения. Создаётся из шаблона `.claude/templates/settings.local.json.example` или пустой каркас:

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "mcpServers": {},
  "permissions": {}
}
```

### Шаг 3. Проверь .gitignore

Эти файлы **обязаны** быть в `.gitignore`. Если их там нет — добавь и **закоммить отдельным MR** (это уже командное изменение, не личное):

```bash
grep -qE '^CLAUDE\.local\.md$' .gitignore || {
  echo "В .gitignore нет CLAUDE.local.md. Это утечка: твой личный файл может попасть в командный коммит."
  echo "Открой MR с правкой .gitignore через /open-mr."
}
grep -qE '^\.claude/settings\.local\.json$' .gitignore || {
  echo "В .gitignore нет .claude/settings.local.json. Аналогично — открой MR."
}
```

### Шаг 4. Запусти /doctor

```bash
# /doctor под текущую фазу (обычно phase-1 или phase-2-feature на инициализированном репо)
# См. playbooks/doctor.md
```

Цель — увидеть состояние окружения и установить чего не хватает. Не блокируй, даже если что-то из required отсутствует — выведи команду установки.

### Шаг 5. Cheat sheet команд

Печатает пользователю:

```
Привет! Репо инициализирован, твои локальные конфиги созданы.

Основные команды (триггер-фразы — см. AGENTS.md §6):
  /plan <slug>        — создать план фичи (спросит ID задачи в трекере)
  /save               — git commit без push
  /save-all           — git commit + push в текущую feature-ветку
  /full-ahead         — полный CI-цикл + push в feature + подсказка /open-mr
  /open-mr            — открыть Merge Request в main
  /adr <title>        — записать архитектурное решение
  /critic             — стресс-тест плана/решения 4 ролями
  /doctor             — проверка окружения

Правила работы:
  • main защищён, прямой push запрещён
  • feature-ветки: feature/<ID>-<slug>, bugfix/<ID>-<slug>, hotfix/<ID>-<slug>
  • Branch lifetime ≤ 1 неделя
  • Conventional Commits + trailer "Refs: <ID-задачи>"
  • Squash on merge, удаление feature-ветки после

Полный регламент: AGENTS.md §4.3 + METHODOLOGY.md §12 + (если в репо есть) docs/gitlab-workflow.md.
Личные оверрайды: CLAUDE.local.md (только что создан).

Удачи!
```

## Что НЕ делает

- **Не пишет в командные файлы:** AGENTS.md, METHODOLOGY.md, README.md, playbooks/, scripts/, security/, docs/ — никаких правок без MR.
- **Не делает первый коммит** — твой первый коммит будет в feature-ветке для реальной задачи.
- **Не запускает `/adopt-stack` или `/adopt-architecture`** — это командные решения, делает первый разработчик через MR.
- **Не открывает MR** — `.gitignore` правки, если они нужны, ты сам инициируешь через `/open-mr` после `/save`.

## Чек-лист после завершения

- [ ] `CLAUDE.local.md` создан в корне репо.
- [ ] `.claude/settings.local.json` создан.
- [ ] Оба файла **в `.gitignore`** (если не было — открыт MR на их добавление).
- [ ] `/doctor` показал отчёт окружения.
- [ ] Прочитан как минимум AGENTS.md и METHODOLOGY.md §12 «Командная специфика».
- [ ] Понятно как создать feature-ветку и открыть MR.

## Связки

- [init-project playbook](init-project.md) — что делает первый разработчик
- [open-mr playbook](open-mr.md) — открытие первого MR
- [doctor playbook](doctor.md) — проверка окружения
- [AGENTS.md §7](../AGENTS.md#7-память-claude-code-vs-память-проекта) — про `CLAUDE.local.md`
- [METHODOLOGY.md §12](../METHODOLOGY.md#12-командная-специфика) — командная специфика
