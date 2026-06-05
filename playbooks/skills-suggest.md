# Skills Suggest Playbook

> **Универсальная процедура.** Читается любым AI: Claude, Codex, DeepSeek, Minimax, Cursor, Gemini, Aider и т.п.
> **Триггер:** `/skills-suggest` или фразы «какие skills поставить», «что мне рекомендовать», «recommend skills».
> **Тонкая обёртка для Claude Code:** [.claude/skills/skills-suggest/SKILL.md](../.claude/skills/skills-suggest/SKILL.md).

---

## Что делает

Смотрит на **текущую фазу и состояние проекта** (выбранную архитектуру, стек, ADR'ы) и предлагает **только проверенные** skills из каталога [`.claude/recommended-skills.md`](../.claude/recommended-skills.md).

**Не устанавливает ничего автоматически.** Только показывает команды установки.

**Соотношение с `/doctor`:** `/doctor` — единый пред-фазный отчёт (CLI + MCP + runtimes + короткий список skills под фазу). `/skills-suggest` — **детальный** разбор skills: зачем каждый, на что обратить внимание, какие альтернативы, какие конфликты, ссылки на репозитории. Запускай его, когда нужны подробности именно по skills.

## Когда запускать

- **После `/adopt-architecture`** — автоматически предлагает архитектурно-релевантные skills.
- **После `/adopt-stack`** — автоматически предлагает стек-релевантные skills.
- **Вручную** в любой момент — `/skills-suggest`.
- **Раз в несколько месяцев** для проверки новых релевантных skills (вместе с `/skills-audit`).

## Алгоритм

### Шаг 0. Определи фазу проекта

По той же эвристике, что использует `/doctor`:
- `AGENTS.md §0` метка фазы.
- Наличие реального содержимого в `docs/architecture/overview.md`.
- Наличие кодовых папок (`backend/`, `frontend/`, `services/`, `src/`).
- Наличие активного плана в `plans/`.

Возможные значения: `phase-0` / `phase-0.5` / `phase-1` / `phase-2-feature` / `phase-2`. При неоднозначности — спроси пользователя одним вопросом.

### Шаг 1. Определить контекст проекта

Прочитай:
- `AGENTS.md` — секции «Стек» (§1), «Карта» (§2), «Индекс ADR» (§3).
- Релевантные ADR'ы в `docs/adr/` — особенно про архитектуру и стек.
- `docs/architecture/overview.md` — какие компоненты есть.

Определи:
- **Есть ли фронт?** (наличие папок `frontend/`, `src/components/`, упоминаний React/Vue/Angular/Svelte)
- **Есть ли бэк?**
- **Какой фронт-фреймворк?** (React / Vue / Angular / SvelteKit / другой)
- **Есть ли мобильный фронт?** (React Native, Flutter)
- **Какой бэк-стек?** (Node / Python / Go / Java/Kotlin / .NET / Rust)
- **Есть ли документы?** (генерация PDF/docx/xlsx/pptx — часто для отчётов, инвойсов, и т.п.)
- **Есть ли e2e-тесты UI?** (упоминание Playwright/Cypress/Selenium)

### Шаг 2. Прочитать каталог

Прочитать `.claude/recommended-skills.md`. Каталог сгруппирован по применимости:
- Универсальные (для любого проекта)
- Фронт-специфичные
- React-специфичные
- React Native
- Документы
- Тестирование UI

### Шаг 3. Сопоставить контекст, фазу и каталог

Сформировать список **релевантных** skills. Учитывай **два фильтра одновременно**:

1. **Фаза.** Поле `Применимо в фазах:` каждого раздела/skill'а должно включать текущую фазу. Например, `frontend-design` помечен `0.5, 1, 2-feature` — в `phase-0` его не предлагаем; в `phase-0.5` — предлагаем, **если** по idea уже понятно, что будет фронт.
2. **Стек/контекст.** Не предлагай skills, которые не применимы к текущему стеку или продукту.

Примеры:
- `phase-0`: skills почти не нужны. Только если пользователь явно собирается строить свой MCP — упомяни `mcp-builder`. Обычно секция «Рекомендуемые» пуста.
- `phase-0.5`, фронт по idea: frontend-design (думать о дизайне до кода).
- `phase-1`, React-fullstack: frontend-design, web-design-guidelines, react-best-practices, composition-patterns.
- `phase-1`, backend-only API без фронта: ни frontend-*, ни react-*. Возможно webapp-testing если фича позже потребует UI-тестов — но в `phase-1` ещё рано.
- `phase-2-feature`, фича генерирует PDF: docx/xlsx/pdf/pptx из document-skills.
- `phase-2-feature`, фича касается UI-сценария: webapp-testing.

Также покажи **явные конфликты** для уже установленных skills — на основе поля `Conflicts with:` (см. шаг 5).

### Шаг 4. Проверить что уже установлено

```bash
claude plugin list 2>/dev/null
ls ~/.claude/skills/ 2>/dev/null
ls .claude/skills/ 2>/dev/null  # project-level
```

Из списка рекомендаций **исключить уже установленные**.

### Шаг 5. Сформировать отчёт

Структура:

```
📦 Рекомендации skills под этот проект

Фаза: <phase-id>
Контекст: <тип проекта> на <стек>, <тип архитектуры>

⚠️ Конфликты среди установленных:
  - <X> и <Y> установлены одновременно. См. ../.claude/recommended-skills.md.
  (раздел скрыт если конфликтов нет)

✅ Уже установлены:
  - frontend-design (anthropics/skills)

🆕 Рекомендуется установить:

  1. **web-design-guidelines** (Vercel)
     Зачем: 100+ правил UI/UX, accessibility, performance
     Установка: npx skills add vercel-labs/agent-skills --skill web-design-guidelines
     Альтернатива (Claude Code marketplace):
       /plugin marketplace add vercel-labs/agent-skills
       /plugin install web-design-guidelines@vercel-agent-skills

  2. **react-best-practices** (Vercel)
     Зачем: 40+ правил производительности React/Next.js
     Установка: npx skills add vercel-labs/agent-skills --skill react-best-practices

🤔 Рассмотреть отдельно:

  - **Superpowers** (obra/superpowers)
    Это процессная дисциплина (brainstorming → plan → execute с TDD).
    **Пересекается с нашим /plan playbook.** Если установишь — придётся выбирать,
    использовать наш /plan или Superpowers' brainstorm+write-plan+execute-plan.
    Не рекомендую устанавливать без явного намерения.
    Подробнее: https://github.com/obra/superpowers

ℹ️ Чего НЕТ в рынке (заранее, чтобы ты не искал):
  - Универсальный «архитектурный» skill — используем наш playbook /adopt-architecture
  - Skill для написания backend API — стандартного не существует, используется промптом
  - Skill для тестирования бэка — используется наш /full-ahead с mutation testing
```

### Шаг 6. Лимит — не более 3-4 рекомендаций за раз

Согласно индустрии (см. [`.claude/recommended-skills.md`](../.claude/recommended-skills.md)), **8-12 установленных skills** — оптимум. Не предлагай ставить 10 штук сразу.

Если по контексту релевантно много — приоритизируй:
1. Что закрывает явный gap (нет UI-стандартов → frontend-design)
2. Что массово используется (web-design-guidelines)
3. Узкое (react-best-practices)
4. Остальное помечай как «можно посмотреть позже»

### Шаг 7. Не устанавливай автоматически

**Никаких автоматических `npx skills add`.** Команды показываем, пользователь копирует и запускает сам. Это его машина, его выбор.

После установки (вне Claude Code) — Claude Code сам подхватит новые skills (live change detection). Подсказать перезапустить сессию если нужно.

### Шаг 8. Записать в ADR если значимое решение

Если пользователь решил установить Superpowers (это меняет workflow) — предложи зафиксировать как ADR:

```
docs/adr/YYYYMMDD-HHmm-adopt-superpowers.md
```

С обоснованием: «Используем Superpowers вместо собственного /plan, т.к. ...».

Это потому что **установка Superpowers — это архитектурное решение про процесс работы**, не операционная мелочь.

## Что НЕ делает

- Не предлагает skills, которые **не существуют в природе**.
- Не предлагает skills, не подходящие к контексту (фронтовые для backend-only).
- Не устанавливает автоматически.
- Не предлагает MCP-серверы (это `/doctor`).

## Связки

- [.claude/recommended-skills.md](../.claude/recommended-skills.md) — каталог skills
- [METHODOLOGY.md «Совместимость с другими AI и IDE»](../METHODOLOGY.md#10-совместимость-с-другими-ai-и-ide) — совместимость и философия skills
- [adopt-architecture playbook](adopt-architecture.md) — первый автозапуск
- [adopt-stack playbook](adopt-stack.md) — второй автозапуск
- [skills-audit playbook](skills-audit.md) — обратная сторона: чистка неиспользуемых
- [doctor playbook](doctor.md) — отдельная команда про CLI/MCP/runtime
