---
name: experiments-audit
description: Audit the experiments/ folder for stale prototypes. Use when the user says "/experiments-audit", "аудит экспериментов", "почисти experiments", "что в experiments", typically once a month or before a major release. Scans experiments/, computes last-commit age, checks for incoming links from docs/adr/ and plans/, measures folder size, classifies each folder as keep / ask author / safe-to-delete / suspicious-size, and prints a structured report. NEVER deletes anything — removal is a separate manual MR with CODEOWNERS approval.
---

# Experiments Audit (Claude Code skill wrapper)

Это **тонкая обёртка** для Claude Code. Полная процедура — в общем playbook'е, который читается любым AI:

→ **[playbooks/experiments-audit.md](../../../playbooks/experiments-audit.md)**

## Что делать

1. Открой `playbooks/experiments-audit.md` (через инструмент чтения файлов).
2. Выполни описанную там процедуру пошагово.
3. Не отклоняйся от шагов playbook'а — если что-то непонятно, спроси пользователя.

## Почему так

См. [METHODOLOGY.md §6](../../../METHODOLOGY.md#6-agentsmd-и-команды-помощники) — двухуровневая архитектура команд.
Контент один, но Claude Code получает skill с авто-триггером по `description`, а другие AI читают playbook напрямую через `AGENTS.md`.

## Связки

- [playbooks/experiments-audit.md](../../../playbooks/experiments-audit.md) — источник правды
- [playbooks/skills-audit.md](../../../playbooks/skills-audit.md) — аналог для skills
- [AGENTS.md](../../../AGENTS.md) — общая таблица триггеров
