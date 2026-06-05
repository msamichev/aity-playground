---
name: save-all
description: Stage, commit, AND push to the CURRENT FEATURE BRANCH (push to main is forbidden in team+ai). Use when the user says "/save-all", "полное сохранение", "сохрани и пушни". Refuses to run on main/master. Validates that the branch name follows the `<type>/<task-id>-<slug>` pattern from AGENTS.md §4.3. Requires scripts/validate-links.sh AND scripts/ci-push.sh green before push (scripts/ci-push.sh = build/types + SAST + gitleaks + SCA + trivy + tests; new default since v0.3.0, replaces the old monolithic scripts/local-ci.sh). Enforces `Refs: <task-id>` trailer in the commit body. Suggests `/open-mr` if no MR is open yet for this branch. Self-review checklist (playbooks/self-review.md) is NOT required here — it is the pre-MR gate read in /open-mr, since a feature-checkpoint push may be incomplete work.
---

# Save All (Claude Code skill wrapper)

Это **тонкая обёртка** для Claude Code. Полная процедура — в общем playbook'е, который читается любым AI:

→ **[playbooks/save-all.md](../../../playbooks/save-all.md)**

## Что делать

1. Открой `playbooks/save-all.md` (через инструмент чтения файлов).
2. Выполни описанную там процедуру пошагово.
3. Не отклоняйся от шагов playbook'а — если что-то непонятно, спроси пользователя.

## Почему так

См. [METHODOLOGY.md §6](../../../METHODOLOGY.md#6-agentsmd-и-команды-помощники) — двухуровневая архитектура команд.
Контент один, но Claude Code получает skill с авто-триггером по `description`, а другие AI читают playbook напрямую через `AGENTS.md`.

## Связки

- [playbooks/save-all.md](../../../playbooks/save-all.md) — источник правды
- [AGENTS.md](../../../AGENTS.md) — общая таблица триггеров
