---
name: adopt-stack
description: Adopt a concrete technology stack and materialize the project structure. Use this skill when the user says "выбираем стек", "/adopt-stack", "пора писать код", "переходим в Phase 1", or when the discovery phase is over and a concrete implementation is about to start. This skill transitions the project from Phase 0 (discovery, no code) to Phase 1 (stack chosen, scaffolding ready). It asks about project type (frontend-only, backend-only, fullstack, monorepo-microservices, library), languages, and CI provider, then generates code folders, stack-specific pre-commit hooks, CI pipeline, and updates AGENTS.md. Do NOT use this skill before /init-project has been run, or before there is enough clarity in docs/idea/.
---

# Adopt Stack (Claude Code skill wrapper)

Это **тонкая обёртка** для Claude Code. Полная процедура — в общем playbook'е, который читается любым AI:

→ **[playbooks/adopt-stack.md](../../../playbooks/adopt-stack.md)**

## Что делать

1. Открой `playbooks/adopt-stack.md` (через инструмент чтения файлов).
2. Выполни описанную там процедуру пошагово.
3. Не отклоняйся от шагов playbook'а — если что-то непонятно, спроси пользователя.

## Почему так

См. [METHODOLOGY.md §6](../../../METHODOLOGY.md#6-agentsmd-и-команды-помощники) — двухуровневая архитектура команд.
Контент один, но Claude Code получает skill с авто-триггером по `description`, а другие AI читают playbook напрямую через `AGENTS.md`.

## Связки

- [playbooks/adopt-stack.md](../../../playbooks/adopt-stack.md) — источник правды
- [AGENTS.md](../../../AGENTS.md) — общая таблица триггеров
