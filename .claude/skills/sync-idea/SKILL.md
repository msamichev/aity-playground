---
name: sync-idea
description: Update docs/idea/ and docs/architecture/ with new content from inbox/ or recent conversations. Use when the user says "/sync-idea", "обнови idea", "перенеси из inbox в idea", "синхронизируй", or after a significant brainstorming session that produced new files in inbox/ or substantial content in chat. Unlike /init-project (which is run ONCE on a fresh project), this skill is run repeatedly as new context arrives. It does NOT overwrite existing filled content — only fills gaps and asks before changing accepted statements.
---

# Sync Idea (Claude Code skill wrapper)

Это **тонкая обёртка** для Claude Code. Полная процедура — в общем playbook'е, который читается любым AI:

→ **[playbooks/sync-idea.md](../../../playbooks/sync-idea.md)**

## Что делать

1. Открой `playbooks/sync-idea.md` (через инструмент чтения файлов).
2. Выполни описанную там процедуру пошагово.
3. Не отклоняйся от шагов playbook'а — если что-то непонятно, спроси пользователя.

## Почему так

См. [METHODOLOGY.md §6](../../../METHODOLOGY.md#6-agentsmd-и-команды-помощники) — двухуровневая архитектура команд.
Контент один, но Claude Code получает skill с авто-триггером по `description`, а другие AI читают playbook напрямую через `AGENTS.md`.

## Связки

- [playbooks/sync-idea.md](../../../playbooks/sync-idea.md) — источник правды
- [AGENTS.md](../../../AGENTS.md) — общая таблица триггеров
