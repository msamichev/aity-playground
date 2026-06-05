---
name: release
description: Bump the project VERSION and finalize the CHANGELOG for a release. Use when the user says "/release", "делаем релиз", "bump версии", "выкатываем новую версию", "зарелизим". Reads changelogs/unreleased/*.md fragments (one per MR — GitLab CHANGELOG-conflict pattern) + git log since last bump, proposes MAJOR/MINOR/PATCH with reasoning, waits for user confirmation. Then bumps VERSION, runs scripts/build-changelog.py to assemble changelogs/unreleased/*.md into a `## [X.Y.Z] — DATE` block in CHANGELOG.md (and `git rm`s the fragments), creates an annotated local tag `vX.Y.Z` (never deleted, never rewritten — protected by security/dangerous-commands.md), creates a release commit. For MINOR/MAJOR — drafts a migration guide. Does NOT push (push of main + tag is a manual Maintainer step, see playbook).
---

# Release (Claude Code skill wrapper)

Это **тонкая обёртка** для Claude Code. Полная процедура — в общем playbook'е, который читается любым AI:

→ **[playbooks/release.md](../../../playbooks/release.md)**

## Что делать

1. Открой `playbooks/release.md` (через инструмент чтения файлов).
2. Выполни описанную там процедуру пошагово.
3. Шаг 3 (уровень bump'а) — **обязательно подтверждение пользователя**. Не двигай VERSION молча.
4. Не отклоняйся от шагов playbook'а — если что-то непонятно, спроси.

## Почему так

См. [METHODOLOGY.md §6](../../../METHODOLOGY.md#6-agentsmd-и-команды-помощники) — двухуровневая архитектура команд.
Контент один, но Claude Code получает skill с авто-триггером по `description`, а другие AI читают playbook напрямую через `AGENTS.md`.

## Связки

- [playbooks/release.md](../../../playbooks/release.md) — источник правды
- [VERSION](../../../VERSION), [CHANGELOG.md](../../../CHANGELOG.md), [migrations/](../../../migrations/)
- [AGENTS.md](../../../AGENTS.md) — общая таблица триггеров
