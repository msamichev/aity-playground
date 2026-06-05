---
name: init-project
description: Initialize a new team+ai project from the seed methodology — for the FIRST developer only. Use this skill when the user says "инициализируй проект", "init project", "давай начнём", "/init-project", and the repo has never been initialised (AGENTS.md §0 still has the `<PROJECT_NAME>` placeholder, no CODEOWNERS, docs/idea/ is template-only). HARDLY REFUSES if the repo is already initialised — points the user to `/onboard-developer` instead. Reads inbox/, populates docs/idea/, docs/product/, AGENTS.md §0 (incl. team_size, external_tracker, tracker_url, id_prefix), creates CODEOWNERS, .gitlab/merge_request_templates/default.md, adds CLAUDE.local.md and .claude/settings.local.json to .gitignore, runs /doctor. Warns the user that the first push to main and enabling branch protection on main are Maintainer's manual responsibility.
---

# Init Project (Claude Code skill wrapper)

Это **тонкая обёртка** для Claude Code. Полная процедура — в общем playbook'е, который читается любым AI:

→ **[playbooks/init-project.md](../../../playbooks/init-project.md)**

## Что делать

1. Открой `playbooks/init-project.md` (через инструмент чтения файлов).
2. Выполни описанную там процедуру пошагово.
3. Не отклоняйся от шагов playbook'а — если что-то непонятно, спроси пользователя.

## Почему так

См. [METHODOLOGY.md §6](../../../METHODOLOGY.md#6-agentsmd-и-команды-помощники) — двухуровневая архитектура команд.
Контент один, но Claude Code получает skill с авто-триггером по `description`, а другие AI читают playbook напрямую через `AGENTS.md`.

## Связки

- [playbooks/init-project.md](../../../playbooks/init-project.md) — источник правды
- [AGENTS.md](../../../AGENTS.md) — общая таблица триггеров
