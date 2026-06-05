---
name: adopt-architecture
description: Adopt architectural patterns BEFORE choosing concrete technologies. Use this skill when the user says "/adopt-architecture", "выбираем архитектуру", "спроектируй архитектуру", "adopt architecture", or when Phase 0 (discovery) is done but Phase 1 (stack choice) hasn't started. This skill works through architectural forks (monolith vs microservices, request/response vs event-driven, etc.), creates ADRs for each significant decision, updates docs/architecture/overview.md with C4 diagram, and runs /skills-suggest. Do NOT use this skill before /init-project, or if docs/idea/ is not yet filled.
---

# Adopt Architecture (Claude Code skill wrapper)

Это **тонкая обёртка** для Claude Code. Полная процедура — в общем playbook'е, который читается любым AI:

→ **[playbooks/adopt-architecture.md](../../../playbooks/adopt-architecture.md)**

## Что делать

1. Открой `playbooks/adopt-architecture.md` (через инструмент чтения файлов).
2. Выполни описанную там процедуру пошагово.
3. Не отклоняйся от шагов playbook'а — если что-то непонятно, спроси пользователя.

## Почему так

См. [METHODOLOGY.md §6](../../../METHODOLOGY.md#6-agentsmd-и-команды-помощники) — двухуровневая архитектура команд.
Контент один, но Claude Code получает skill с авто-триггером по `description`, а другие AI читают playbook напрямую через `AGENTS.md`.

## Связки

- [playbooks/adopt-architecture.md](../../../playbooks/adopt-architecture.md) — источник правды
- [AGENTS.md](../../../AGENTS.md) — общая таблица триггеров
