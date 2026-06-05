---
name: save
description: Stage and commit local changes WITHOUT pushing. Use when the user says "/save", "сохрани", "закоммить", "сделай коммит" but NOT when they ask to push. This skill ALWAYS stages files explicitly (poimenno) — never uses `git add .` or `git add -A`. It validates that pre-commit hooks pass, then creates a Conventional Commits message based on the diff. Does NOT push.
---

# Save (Claude Code skill wrapper)

Это **тонкая обёртка** для Claude Code. Полная процедура — в общем playbook'е, который читается любым AI:

→ **[playbooks/save.md](../../../playbooks/save.md)**

## Что делать

1. Открой `playbooks/save.md` (через инструмент чтения файлов).
2. Выполни описанную там процедуру пошагово.
3. Не отклоняйся от шагов playbook'а — если что-то непонятно, спроси пользователя.

## Почему так

См. [METHODOLOGY.md §6](../../../METHODOLOGY.md#6-agentsmd-и-команды-помощники) — двухуровневая архитектура команд.
Контент один, но Claude Code получает skill с авто-триггером по `description`, а другие AI читают playbook напрямую через `AGENTS.md`.

## Связки

- [playbooks/save.md](../../../playbooks/save.md) — источник правды
- [AGENTS.md](../../../AGENTS.md) — общая таблица триггеров
