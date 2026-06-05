---
name: autopilot
description: Execute a multi-phase plan (or a large feature) autonomously, phase by phase, committing after each phase WITHOUT pushing. Use when the user says "/autopilot", "автопилот", "выполни план автономно", "иди по плану сам", "автономная работа", "выполни фичу автономно", or hands over a whole plan for hands-off execution. The skill walks the plan's phases: writes code → quality gates (four-gate subagents incl. merge-coordinator + /critic on significant forks) → on a concrete concern, validates against best practices from the internet → fixes → marks acceptance criteria → commits the phase with a `Refs:` trailer (no push) → appends to the plan's run journal. Questions are front-loaded at the start only; if there is no detailed plan, it offers a fork — (A) build the plan together then run, or (B) fully autonomous (decompose, /critic, validate, run). On a real blocker it stops with a clear report. In team+ai it works ONLY on the developer's own feature branch (after rebase on origin/main), NEVER on main or others' branches, and never pushes — push and /open-mr stay manual. Full safeguards: hard deny-list, branch + clean git-tree check, rollback checkpoint, permission allowlist taken upfront (ask/unknown → escalate). Also handles RESUME of an interrupted run: "/autopilot --resume", "продолжи план", "continue autopilot" — rehydrates from the plan (Фазы/Критерий приёмки/Журнал) + git and continues from the first unchecked phase in the same feature branch; long runs survive context compaction and /clear via files + optional PreCompact/SessionStart hooks. Boundaries — /autonomous = config toggle, /full-ahead = one CI cycle + push to feature branch, /autopilot = executes the whole plan without push. Do NOT use on main / a protected branch, in Phase 0 / Phase 0.5, or for a one-file change.
---

# Autopilot (Claude Code skill wrapper)

Это **тонкая обёртка** для Claude Code. Полная процедура — в общем playbook'е, который читается любым AI:

→ **[playbooks/autopilot.md](../../../playbooks/autopilot.md)**

## Что делать

1. Открой `playbooks/autopilot.md` (через инструмент чтения файлов).
2. Выполни описанную там процедуру пошагово.
3. Не отклоняйся от шагов playbook'а — вопросы только на старте; работай только в своей feature-ветке (не `main`); при настоящем тупике останавливайся с отчётом (Шаг 4), push/MR оставляй человеку.

## Почему так

См. [METHODOLOGY.md §6](../../../METHODOLOGY.md#6-agentsmd-и-команды-помощники) — двухуровневая архитектура команд.
Контент один, но Claude Code получает skill с авто-триггером по `description`, а другие AI читают playbook напрямую через `AGENTS.md`.

## Связки

- [playbooks/autopilot.md](../../../playbooks/autopilot.md) — источник правды
- [playbooks/autonomous-mode.md](../../../playbooks/autonomous-mode.md) — тумблер/конфиг режима
- [playbooks/full-ahead.md](../../../playbooks/full-ahead.md) — финализатор/CI (граница ответственности)
- [playbooks/open-mr.md](../../../playbooks/open-mr.md) — открытие MR после прогона
- [AGENTS.md](../../../AGENTS.md) — общая таблица триггеров
