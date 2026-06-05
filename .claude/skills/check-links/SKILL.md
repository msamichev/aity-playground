---
name: check-links
description: Run the link graph validator and produce a report. Use when the user says "/check-links", "проверь ссылки", "что с графом", "проверь связки", or before a significant commit/push to make sure the knowledge graph is healthy. The skill runs scripts/validate-links.sh --report and presents the output in a structured way. If there are issues, suggests fixes.
---

# Check Links (Claude Code skill wrapper)

Это **тонкая обёртка** для Claude Code. Полная процедура — в общем playbook'е, который читается любым AI:

→ **[playbooks/check-links.md](../../../playbooks/check-links.md)**

## Что делать

1. Открой `playbooks/check-links.md` (через инструмент чтения файлов).
2. Выполни описанную там процедуру пошагово.
3. Не отклоняйся от шагов playbook'а — если что-то непонятно, спроси пользователя.

## Почему так

См. [METHODOLOGY.md §6](../../../METHODOLOGY.md#6-agentsmd-и-команды-помощники) — двухуровневая архитектура команд.
Контент один, но Claude Code получает skill с авто-триггером по `description`, а другие AI читают playbook напрямую через `AGENTS.md`.

## Связки

- [playbooks/check-links.md](../../../playbooks/check-links.md) — источник правды
- [AGENTS.md](../../../AGENTS.md) — общая таблица триггеров
