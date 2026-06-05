---
name: retro
description: Create a TEAM-WIDE retrospective AFTER A RELEASE (not after each session — that's a solo+ai pattern, doesn't fit a team). Use when the user says "/retro", "давай ретроспективу", "итоги релиза", or after a `vX.Y.Z` tag has been pushed. Copies retrospectives/TEMPLATE.md to retrospectives/YYYY-MM-DD-release-v<VERSION>.md (one file per release, not one per session). Prompts the team to fill sections: what shipped (with `Refs:` to tracker tasks), what went well, what could be better, process changes (with owners and deadlines), optional release metrics. Personal session retrospectives are NOT committed in team+ai — they live in local scratch outside the repo.
---

# Retro (Claude Code skill wrapper)

Это **тонкая обёртка** для Claude Code. Полная процедура — в общем playbook'е, который читается любым AI:

→ **[playbooks/retro.md](../../../playbooks/retro.md)**

## Что делать

1. Открой `playbooks/retro.md` (через инструмент чтения файлов).
2. Выполни описанную там процедуру пошагово.
3. Не отклоняйся от шагов playbook'а — если что-то непонятно, спроси пользователя.

## Почему так

См. [METHODOLOGY.md §6](../../../METHODOLOGY.md#6-agentsmd-и-команды-помощники) — двухуровневая архитектура команд.
Контент один, но Claude Code получает skill с авто-триггером по `description`, а другие AI читают playbook напрямую через `AGENTS.md`.

## Связки

- [playbooks/retro.md](../../../playbooks/retro.md) — источник правды
- [AGENTS.md](../../../AGENTS.md) — общая таблица триггеров
