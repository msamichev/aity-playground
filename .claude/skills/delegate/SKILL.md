---
name: delegate
description: Maintainer-side fan-out — decompose a LARGE task into disjoint narrow subtasks and hand them to a fleet of cheap headless bots (agent-aity Docker sandboxes, DeepSeek/Qwen) that each open a PR. Use for "/delegate", "раздай ботам", "делегируй команде", "запусти ботов на …". team+ai model "боты = команда, ты = мейнтейнер". Core is the DECOMPOSITION RUBRIC: contract-first (fix interfaces between subtasks before start) → file-ownership map (subtasks sharing files are NOT parallelized — sequence them; file disjointness is the only defense against merge conflicts) → parallelism cap 3–5 workers per repo → explicit scale rule (trivial → do it yourself; narrow independent chunks → 2–5 bots; intertwined → sequence or don't split) → self-contained prompt per subtask (bot does NOT inherit the main session's context: goal, files touched, contract, done-criterion). Localizes the tool via env AITY_HOME (never hardcodes the path); launch contract: QUEUE_CONCURRENCY=<n> "$AITY_HOME/scripts/queue.sh" <repo> <backend> <task-files|dir> (parallel dispatch), "$AITY_HOME/scripts/run.sh" <repo> "<task>" <backend> (single), "$AITY_HOME/scripts/dashboard.sh" (verdicts/cost/PR links). Flow: clarify → plan/ADR with contracts + file map → SHOW the plan and WAIT for confirmation (an expensive fan-out is never launched silently) → write task files → queue.sh → dashboard. Guardrails: merge into protected main is HUMAN-only (the bot cannot merge; full issue→PR→auto-merge is not considered safe in 2026); CI/gates are ground-truth, not the bot's prose; cheap models are weak on long loops → narrow tasks + maintainer final gate are critical. /delegate stops at PR — review and merge stay with the maintainer (/open-mr, /self-review, gh pr merge). Do NOT use for a trivial one-file change, for intertwined subtasks that share files (sequence instead), or when AITY_HOME is unset.
---

# Delegate (Claude Code skill wrapper)

Это **тонкая обёртка** для Claude Code. Полная процедура — в общем playbook'е, который читается любым AI:

→ **[playbooks/delegate.md](../../../playbooks/delegate.md)**

## Что делать

1. Открой `playbooks/delegate.md` (через инструмент чтения файлов).
2. Выполни описанную там процедуру пошагово: рубрика декомпозиции (контракт-first → карта владения файлами → потолок 3–5 → правило масштаба → самодостаточный промпт) → поток (уточни → план/ADR → **подтверждение** → task-файлы → `queue.sh` через `AITY_HOME` → `dashboard.sh`).
3. Не отклоняйся от шагов: дорогой fan-out запускай **только после подтверждения**; подзадачи, делящие файлы, — **секвенс**, не параллель; путь к инструменту — через `AITY_HOME`, не хардкод; **ревью и мерж PR ботов оставляй мейнтейнеру** — `/delegate` доводит до PR, не дальше и не мержит.

## Почему так

См. [METHODOLOGY.md §6](../../../METHODOLOGY.md#6-agentsmd-и-команды-помощники) — двухуровневая архитектура команд.
Контент один, но Claude Code получает skill с авто-триггером по `description`, а другие AI читают playbook напрямую через `AGENTS.md`.

## Связки

- [playbooks/delegate.md](../../../playbooks/delegate.md) — источник правды
- [playbooks/plan.md](../../../playbooks/plan.md) — план + контракты между подзадачами
- [playbooks/open-mr.md](../../../playbooks/open-mr.md) — ревью PR ботов мейнтейнером (за человеком)
- [playbooks/autopilot.md](../../../playbooks/autopilot.md) — контраст: одно-агентная автономия в своей ветке
- [AGENTS.md](../../../AGENTS.md) — общая таблица триггеров
