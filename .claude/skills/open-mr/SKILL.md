---
name: open-mr
description: Open a GitLab Merge Request into main from the current feature branch. Use when the user says "/open-mr", "открой MR", "давай PR", "open mr", "создай merge request", or after a successful push and they want to start review. Refuses to run from main or non-feature branches. Pre-flight: scripts/ci-push.sh green + no uncommitted changes + branch pushed to origin. THEN runs two pre-MR gates: (1) reads playbooks/self-review.md (7-point SEMANTIC checklist — covers logic, swallowed errors, secrets/PII, backwards compatibility) — this is the rule from AGENTS.md §5 п.10; (2) runs the merge-coordinator subagent (STRUCTURAL checks — rebase on main, no ADR timestamp collisions, changelogs/unreleased/<ID>.md fragment exists, `Refs:` trailer present). Self-review and merge-coordinator complement each other, not duplicate. Uses `glab mr create` if available; otherwise prints a ready-to-paste GitLab "New MR" URL. Pre-fills title from the last commit message, description from .gitlab/merge_request_templates/default.md, extracts task ID from branch name and adds tracker link plus `Refs: <ID>` trailer. Never assigns the author as reviewer (1+ approve from another developer required by team+ai policy).
---

# Open MR (Claude Code skill wrapper)

Это **тонкая обёртка** для Claude Code. Полная процедура — в общем playbook'е, который читается любым AI:

→ **[playbooks/open-mr.md](../../../playbooks/open-mr.md)**

## Что делать

1. Открой `playbooks/open-mr.md` (через инструмент чтения файлов).
2. Выполни описанную там процедуру пошагово.
3. Не отклоняйся от шагов playbook'а — если что-то непонятно, спроси пользователя.

## Почему так

См. [METHODOLOGY.md §6](../../../METHODOLOGY.md#6-agentsmd-и-команды-помощники) — двухуровневая архитектура команд.
Контент один, но Claude Code получает skill с авто-триггером по `description`, а другие AI читают playbook напрямую через `AGENTS.md`.

## Связки

- [playbooks/open-mr.md](../../../playbooks/open-mr.md) — источник правды
- [playbooks/save-all.md](../../../playbooks/save-all.md) — что предшествует MR
- [AGENTS.md](../../../AGENTS.md) — общая таблица триггеров
