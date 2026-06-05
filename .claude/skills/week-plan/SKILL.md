---
name: week-plan
description: Create or update a weekly plan with up to 5 key results. Use when the user says "/week-plan", "давай план на неделю", "что делаем эту неделю", "план недели". The skill creates plans/weeks/YYYY-WNN.md (ISO week) with up to 5 prioritized goals for the week, capacity check, and links to relevant feature plans. NOT a daily todo — week-level only. Helps avoid lost-in-the-weeds problem with solo development.
---

# Week Plan (Claude Code skill wrapper)

Это **тонкая обёртка** для Claude Code. Полная процедура — в общем playbook'е, который читается любым AI:

→ **[playbooks/week-plan.md](../../../playbooks/week-plan.md)**

## Что делать

1. Открой `playbooks/week-plan.md` (через инструмент чтения файлов).
2. Выполни описанную там процедуру пошагово.
3. Не отклоняйся от шагов playbook'а — если что-то непонятно, спроси пользователя.

## Почему так

См. [METHODOLOGY.md §6](../../../METHODOLOGY.md#6-agentsmd-и-команды-помощники) — двухуровневая архитектура команд.
Контент один, но Claude Code получает skill с авто-триггером по `description`, а другие AI читают playbook напрямую через `AGENTS.md`.

## Связки

- [playbooks/week-plan.md](../../../playbooks/week-plan.md) — источник правды
- [AGENTS.md](../../../AGENTS.md) — общая таблица триггеров
