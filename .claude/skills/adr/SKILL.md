---
name: adr
description: Create a new Architecture Decision Record (ADR). Use when the user says "/adr", "новое архитектурное решение", "пишем ADR", "запиши решение", or has just made a significant technical/architectural decision that needs to be documented. Significant means anything someone might ask "why" about in 6 months — choice of database, framework, integration approach, security model. Asks whether the ADR is tied to an external-tracker task (optional). Creates docs/adr/YYYYMMDD-HHmm-[<TASK-ID>-]<slug>.md from template and prompts the user to fill in Context/Decision/Consequences/Alternatives. The ADR INDEX (docs/adr/INDEX.md) is regenerated automatically by scripts/build-adr-index.py on pre-commit — do NOT edit the index manually.
---

# Adr (Claude Code skill wrapper)

Это **тонкая обёртка** для Claude Code. Полная процедура — в общем playbook'е, который читается любым AI:

→ **[playbooks/adr.md](../../../playbooks/adr.md)**

## Что делать

1. Открой `playbooks/adr.md` (через инструмент чтения файлов).
2. Выполни описанную там процедуру пошагово.
3. Не отклоняйся от шагов playbook'а — если что-то непонятно, спроси пользователя.

## Почему так

См. [METHODOLOGY.md §6](../../../METHODOLOGY.md#6-agentsmd-и-команды-помощники) — двухуровневая архитектура команд.
Контент один, но Claude Code получает skill с авто-триггером по `description`, а другие AI читают playbook напрямую через `AGENTS.md`.

## Связки

- [playbooks/adr.md](../../../playbooks/adr.md) — источник правды
- [AGENTS.md](../../../AGENTS.md) — общая таблица триггеров
