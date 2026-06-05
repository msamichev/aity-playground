---
name: skills-suggest
description: Focused, skills-only deep dive. Recommends Claude Code skills for the current project, filtered by BOTH the current phase (phase-0 / 0.5 / 1 / 2-feature) AND the stack/architecture context — using the "Применимо в фазах" tags in .claude/recommended-skills.md. For each recommended skill, gives details: why it helps, alternatives, conflicts (Conflicts with: field), repo links. Use when the user says "/skills-suggest", "какие skills поставить", "recommend skills", "что мне рекомендовать". Also runs automatically at the end of /adopt-architecture and /adopt-stack. Only recommends VERIFIED skills from the catalog, never invents skill names. Does NOT install anything. For a combined CLI+MCP+runtimes+skills environment overview, use /doctor instead — this skill is the deep-dive version that focuses only on skills.
---

# Skills Suggest (Claude Code skill wrapper)

Это **тонкая обёртка** для Claude Code. Полная процедура — в общем playbook'е, который читается любым AI:

→ **[playbooks/skills-suggest.md](../../../playbooks/skills-suggest.md)**

## Что делать

1. Открой `playbooks/skills-suggest.md` (через инструмент чтения файлов).
2. Выполни описанную там процедуру пошагово.
3. Не отклоняйся от шагов playbook'а — если что-то непонятно, спроси пользователя.

## Почему так

См. [METHODOLOGY.md §6](../../../METHODOLOGY.md#6-agentsmd-и-команды-помощники) — двухуровневая архитектура команд.
Контент один, но Claude Code получает skill с авто-триггером по `description`, а другие AI читают playbook напрямую через `AGENTS.md`.

## Связки

- [playbooks/skills-suggest.md](../../../playbooks/skills-suggest.md) — источник правды
- [AGENTS.md](../../../AGENTS.md) — общая таблица триггеров
