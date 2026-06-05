#!/usr/bin/env bash
#
# autopilot-precompact.sh — Claude Code PreCompact hook для autopilot (методология team+ai).
#
# Срабатывает ПЕРЕД компактификацией контекста (авто или /compact). Компакт отменить
# НЕ может (и не пытается) — только фиксирует хлебную крошку в .claude/autopilot-checkpoint.md,
# ЕСЛИ идёт прогон autopilot (checkpoint-файл существует). Так после компакта видно, что
# прогон прерывался, и было ли незакоммиченное.
#
# stdin: JSON хука (используем поле trigger: auto|manual). Без jq — грубый парс.
# Регистрируется в .claude/settings.local.json (НЕ в settings.json — он автогенерируется).
# См. playbooks/autopilot.md, раздел «Управление контекстом».
#

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
CHECKPOINT="$REPO_ROOT/.claude/autopilot-checkpoint.md"

# Нет активного прогона autopilot — не вмешиваемся.
[[ -f "$CHECKPOINT" ]] || exit 0

INPUT="$(cat 2>/dev/null || true)"
TRIGGER="manual"
case "$INPUT" in
  *'"trigger"'*'"auto"'*) TRIGGER="auto" ;;
esac

TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
BRANCH="$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
HEAD_SHORT="$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo '?')"
DIRTY="$(git -C "$REPO_ROOT" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"

printf -- '- %s precompact(%s): ветка %s, HEAD %s, незакоммичено=%s\n' \
  "$TS" "$TRIGGER" "$BRANCH" "$HEAD_SHORT" "$DIRTY" >> "$CHECKPOINT"

# Информационное сообщение пользователю (компакт всё равно произойдёт).
printf '{"hookSpecificOutput":{"hookEventName":"PreCompact","systemMessage":"autopilot: контекст компактится (%s). Состояние — в журнале плана и .claude/autopilot-checkpoint.md; после компакта продолжай по плану, не начиная заново."}}\n' "$TRIGGER"

exit 0
