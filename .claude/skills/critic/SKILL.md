---
name: critic
description: Critique the current plan or proposal from multiple adversarial perspectives. Use when the user says "/critic", "раскритикуй", "критика плана", "найди дыры", "давай раскатаем по швам", or when a major plan/ADR is drafted and needs stress-testing before commitment. The skill produces 3-4 critiques from distinct adversarial roles (skeptic, security-paranoid, devil's advocate, ruthless simplifier) and then synthesizes the most actionable concerns. Do NOT use this for tiny edits — only for plans, ADRs, or architectural proposals worth the friction.
---

# Critic (Claude Code skill wrapper)

Это **тонкая обёртка** для Claude Code. Полная процедура — в общем playbook'е, который читается любым AI:

→ **[playbooks/critic.md](../../../playbooks/critic.md)**

## Что делать

1. Открой `playbooks/critic.md` (через инструмент чтения файлов).
2. Выполни описанную там процедуру пошагово.
3. Не отклоняйся от шагов playbook'а — если что-то непонятно, спроси пользователя.

## Почему так

См. [METHODOLOGY.md §6](../../../METHODOLOGY.md#6-agentsmd-и-команды-помощники) — двухуровневая архитектура команд.
Контент один, но Claude Code получает skill с авто-триггером по `description`, а другие AI читают playbook напрямую через `AGENTS.md`.

## Связки

- [playbooks/critic.md](../../../playbooks/critic.md) — источник правды
- [AGENTS.md](../../../AGENTS.md) — общая таблица триггеров
