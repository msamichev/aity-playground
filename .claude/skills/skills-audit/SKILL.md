---
name: skills-audit
description: Audit installed Claude Code skills: which were actively used recently, which are candidates for removal due to context-tax. Use when the user says "/skills-audit", "аудит skills", "какие skills я не использую", "почисти skills". Recommended monthly. Heuristic-based (uses git history and project structure), recommends but does NOT remove anything automatically.
---

# Skills Audit (Claude Code skill wrapper)

Это **тонкая обёртка** для Claude Code. Полная процедура — в общем playbook'е, который читается любым AI:

→ **[playbooks/skills-audit.md](../../../playbooks/skills-audit.md)**

## Что делать

1. Открой `playbooks/skills-audit.md` (через инструмент чтения файлов).
2. Выполни описанную там процедуру пошагово.
3. Не отклоняйся от шагов playbook'а — если что-то непонятно, спроси пользователя.

## Почему так

См. [METHODOLOGY.md §6](../../../METHODOLOGY.md#6-agentsmd-и-команды-помощники) — двухуровневая архитектура команд.
Контент один, но Claude Code получает skill с авто-триггером по `description`, а другие AI читают playbook напрямую через `AGENTS.md`.

## Связки

- [playbooks/skills-audit.md](../../../playbooks/skills-audit.md) — источник правды
- [AGENTS.md](../../../AGENTS.md) — общая таблица триггеров
