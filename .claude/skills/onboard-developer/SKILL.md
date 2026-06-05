---
name: onboard-developer
description: Configure local AI conf for a developer who just cloned an already-initialised team+ai repo. Use when the user says "/onboard-developer", "я новый в проекте", "настрой меня", "onboard", "я только что склонировал". Creates personal CLAUDE.local.md and .claude/settings.local.json from templates, checks they are in .gitignore, runs /doctor, prints command cheat sheet. Does NOT write to team-owned files (AGENTS.md, playbooks, scripts, docs/). Refuses to run on a non-initialised repo and points to /init-project.
---

# Onboard Developer (Claude Code skill wrapper)

Это **тонкая обёртка** для Claude Code. Полная процедура — в общем playbook'е, который читается любым AI:

→ **[playbooks/onboard-developer.md](../../../playbooks/onboard-developer.md)**

## Что делать

1. Открой `playbooks/onboard-developer.md` (через инструмент чтения файлов).
2. Выполни описанную там процедуру пошагово.
3. Не отклоняйся от шагов playbook'а — если что-то непонятно, спроси пользователя.

## Почему так

См. [METHODOLOGY.md §6](../../../METHODOLOGY.md#6-agentsmd-и-команды-помощники) — двухуровневая архитектура команд.
Контент один, но Claude Code получает skill с авто-триггером по `description`, а другие AI читают playbook напрямую через `AGENTS.md`.

## Связки

- [playbooks/onboard-developer.md](../../../playbooks/onboard-developer.md) — источник правды
- [playbooks/init-project.md](../../../playbooks/init-project.md) — что делает первый разработчик
- [AGENTS.md](../../../AGENTS.md) — общая таблица триггеров
