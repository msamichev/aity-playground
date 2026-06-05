---
name: autonomous-mode
description: Configure or toggle autonomous mode of team+ai. Use when the user says "/autonomous", "включи autonomous mode", "автономный режим", "работай автономно", "vibe mode", or asks how the autonomous loop works. In team+ai, autonomous mode is constrained to the developer's OWN FEATURE BRANCH (after `git rebase origin/main`). It never writes to main or other developers' branches; Stop hook checks the branch. The skill checks readiness (via /doctor phase-2-feature), reports missing components (.claude/agents/, scripts/stop-checklist.sh, Stop hook registration), and either flips the autonomous_mode flag in AGENTS.md §0 permanently or runs the next cycle in autonomous mode one-off. Does NOT execute features by itself — that's /full-ahead. Do NOT use this skill in Phase 0 / Phase 0.5.
---

# Autonomous Mode (Claude Code skill wrapper)

Это **тонкая обёртка** для Claude Code. Полная процедура — в общем playbook'е, который читается любым AI:

→ **[playbooks/autonomous-mode.md](../../../playbooks/autonomous-mode.md)**

## Что делать

1. Открой `playbooks/autonomous-mode.md` (через инструмент чтения файлов).
2. Выполни описанную там процедуру пошагово.
3. Не отклоняйся от шагов playbook'а — если что-то непонятно, спроси пользователя.

## Почему так

См. [METHODOLOGY.md §6](../../../METHODOLOGY.md#6-agentsmd-и-команды-помощники) — двухуровневая архитектура команд.
Контент один, но Claude Code получает skill с авто-триггером по `description`, а другие AI читают playbook напрямую через `AGENTS.md`.

## Связки

- [playbooks/autonomous-mode.md](../../../playbooks/autonomous-mode.md) — источник правды
- [AGENTS.md](../../../AGENTS.md) — общая таблица триггеров
