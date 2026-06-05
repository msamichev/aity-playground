---
name: full-ahead
description: Run the local pre-push CI cycle (build/types + SAST + gitleaks + SCA + trivy + tests via scripts/ci-push.sh), autonomously fix issues until green, then commit and push to the CURRENT FEATURE BRANCH (push to main forbidden in team+ai). Use when the user says "/full-ahead", "полный вперёд", "полный цикл", "прогнать всё". Deep checks (mutation, SBOM, container scan) are NOT in the default loop — they live in scripts/ci-deep.sh and the GitLab CI nightly job `security-deep:nightly`. After green and push, IF the push leads to /open-mr — reads playbooks/self-review.md (7-point semantic checklist) before opening MR; if it is just a feature checkpoint push, self-review is skipped. In autonomous mode also runs four-gate subagent review (code-reviewer, test-runner, security-auditor, merge-coordinator). Suggests `/open-mr` if no MR exists for this branch. Refuses to run from main or a non-feature branch. Do NOT use this skill before /adopt-stack — there's nothing to build/test yet.
---

# Full Ahead (Claude Code skill wrapper)

Это **тонкая обёртка** для Claude Code. Полная процедура — в общем playbook'е, который читается любым AI:

→ **[playbooks/full-ahead.md](../../../playbooks/full-ahead.md)**

## Что делать

1. Открой `playbooks/full-ahead.md` (через инструмент чтения файлов).
2. Выполни описанную там процедуру пошагово.
3. Не отклоняйся от шагов playbook'а — если что-то непонятно, спроси пользователя.

## Почему так

См. [METHODOLOGY.md §6](../../../METHODOLOGY.md#6-agentsmd-и-команды-помощники) — двухуровневая архитектура команд.
Контент один, но Claude Code получает skill с авто-триггером по `description`, а другие AI читают playbook напрямую через `AGENTS.md`.

## Связки

- [playbooks/full-ahead.md](../../../playbooks/full-ahead.md) — источник правды
- [AGENTS.md](../../../AGENTS.md) — общая таблица триггеров
