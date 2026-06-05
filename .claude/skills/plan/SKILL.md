---
name: plan
description: Create a new feature plan from the template. Entry point into phase-2-feature. FIRST asks the user for the external-tracker task ID (e.g. PROJ-142) — prefix comes from AGENTS.md §0 `id_prefix`. Then runs /doctor pre-feature check (skipped if .claude/settings.local.json has doctorAcknowledged=true with doctorLastPhase=phase-2-feature). Then copies plans/TEMPLATE.md to plans/YYYY-MM-DD-<TASK-ID>-<slug>.md, fills date/title, embeds tracker URL into the plan header. In autonomous mode collects all clarifying questions in one block (front-loaded) and requires a machine-readable `## Критерий приёмки` checklist. Use when the user says "/plan", "создай план", "новый план для X". One plan = one task. Do NOT use for tiny one-off edits.
---

# Plan (Claude Code skill wrapper)

Это **тонкая обёртка** для Claude Code. Полная процедура — в общем playbook'е, который читается любым AI:

→ **[playbooks/plan.md](../../../playbooks/plan.md)**

## Что делать

1. Открой `playbooks/plan.md` (через инструмент чтения файлов).
2. Выполни описанную там процедуру пошагово.
3. Не отклоняйся от шагов playbook'а — если что-то непонятно, спроси пользователя.

## Почему так

См. [METHODOLOGY.md §6](../../../METHODOLOGY.md#6-agentsmd-и-команды-помощники) — двухуровневая архитектура команд.
Контент один, но Claude Code получает skill с авто-триггером по `description`, а другие AI читают playbook напрямую через `AGENTS.md`.

## Связки

- [playbooks/plan.md](../../../playbooks/plan.md) — источник правды
- [AGENTS.md](../../../AGENTS.md) — общая таблица триггеров
