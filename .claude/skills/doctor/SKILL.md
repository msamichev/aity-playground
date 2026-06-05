---
name: doctor
description: Phase-aware pre-phase environment check. Determines the project's current phase (phase-0 Discovery / phase-0.5 Architecture / phase-1 Stack / phase-2-feature / phase-2 between features), reads .claude/expected-tools.md and .claude/recommended-skills.md, and produces a single unified report covering CLI / MCP servers / runtimes / recommended skills filtered for that phase, plus a conflict check (e.g. ctx7 CLI vs context7 MCP, Superpowers skill vs /plan playbook). Use when the user says "/doctor", "проверь окружение", "что у меня установлено", "health check". Also runs automatically at the end of /init-project, /adopt-stack, and at Step 0 of /plan (the pre-feature check). Reports status and install commands; does NOT install anything. For a focused skills-only deep dive, see /skills-suggest.
---

# Doctor (Claude Code skill wrapper)

Это **тонкая обёртка** для Claude Code. Полная процедура — в общем playbook'е, который читается любым AI:

→ **[playbooks/doctor.md](../../../playbooks/doctor.md)**

## Что делать

1. Открой `playbooks/doctor.md` (через инструмент чтения файлов).
2. Выполни описанную там процедуру пошагово.
3. Не отклоняйся от шагов playbook'а — если что-то непонятно, спроси пользователя.

## Почему так

См. [METHODOLOGY.md §6](../../../METHODOLOGY.md#6-agentsmd-и-команды-помощники) — двухуровневая архитектура команд.
Контент один, но Claude Code получает skill с авто-триггером по `description`, а другие AI читают playbook напрямую через `AGENTS.md`.

## Связки

- [playbooks/doctor.md](../../../playbooks/doctor.md) — источник правды
- [AGENTS.md](../../../AGENTS.md) — общая таблица триггеров
