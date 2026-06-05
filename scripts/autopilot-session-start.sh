#!/usr/bin/env bash
#
# autopilot-session-start.sh — Claude Code SessionStart hook для autopilot (методология team+ai).
#
# Если идёт незавершённый прогон autopilot — возвращает additionalContext с инструкцией
# восстановиться (прочитать план + журнал + git, продолжить с первой невыполненной фазы).
# Срабатывает в т.ч. после /clear и авто-компакта (source=clear|compact) — закрывает потерю
# контекста на длинных прогонах.
#
# Признак «прогон в процессе»: существует .claude/autopilot-checkpoint.md И у активного плана
# есть невыполненные пункты "## Критерий приёмки". Иначе — молча выходит (exit 0).
#
# stdin: JSON хука (source). Вывод: один валидный JSON-объект с additionalContext (без jq —
# сообщение однострочное, без кавычек/переносов). Регистрируется в .claude/settings.local.json.
#

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
CHECKPOINT="$REPO_ROOT/.claude/autopilot-checkpoint.md"

cat >/dev/null 2>&1 || true   # поглотить stdin хука

# Нет активного прогона — не вмешиваемся.
[[ -f "$CHECKPOINT" ]] || exit 0

# Активный план = самый свежий plans/YYYY-MM-DD-*.md, не TEMPLATE/README, не помеченный done.
ACTIVE_PLAN=""
if [[ -d "$REPO_ROOT/plans" ]]; then
  # shellcheck disable=SC2012
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    case "$(basename "$f")" in TEMPLATE.md|README.md) continue ;; esac
    if head -20 "$f" | grep -qiE '(статус|status):[[:space:]]*(выполнено|completed|done|закрыт)'; then
      continue
    fi
    ACTIVE_PLAN="$f"
    break
  done < <(ls -t "$REPO_ROOT/plans"/*.md 2>/dev/null || true)
fi
[[ -n "$ACTIVE_PLAN" ]] || exit 0

# Считаем невыполненные пункты критерия приёмки.
UNCHECKED=0
if grep -qE '^##[[:space:]]+Критерий приёмки' "$ACTIVE_PLAN"; then
  UNCHECKED="$(awk '
    /^##[[:space:]]+Критерий приёмки/ {s=1; next}
    /^##[[:space:]]+/ && s {s=0}
    s && /^[[:space:]]*-[[:space:]]*\[ \]/ {c++}
    END {print c+0}
  ' "$ACTIVE_PLAN")"
fi
[[ "$UNCHECKED" -gt 0 ]] || exit 0

PLAN_REL="${ACTIVE_PLAN#"$REPO_ROOT"/}"
MSG="Autopilot: похоже, идёт незавершённый автономный прогон по плану ${PLAN_REL} (невыполнено пунктов критерия приёмки: ${UNCHECKED}). Прежде чем действовать — прочитай этот план (Фазы, Критерий приёмки, Журнал автономного прогона) и git log, восстанови состояние и продолжи с первой невыполненной фазы в своей feature-ветке; не начинай заново. Для продолжения: /autopilot --resume."

printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$MSG"

exit 0
