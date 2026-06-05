#!/usr/bin/env bash
#
# stop-checklist.sh — Claude Code Stop hook для autonomous mode методологии team+ai.
#
# Срабатывает на событии Stop (когда Claude собирается завершить ответ).
# Если autonomous mode НЕ включён — выходит с 0 (не вмешивается).
# Если включён — проверяет финальные инварианты:
#   1. Текущая ветка — НЕ main/защищённая (autonomous mode пишет только в feature-ветку).
#   2. Граф связок зелёный (scripts/validate-links.sh).
#   3. В staged-файлах нет секретов (gitleaks).
#   4. Все пункты "## Критерий приёмки" в активном плане отмечены [x].
#
# Если что-то красное и autonomous mode активен — exit 2 (Claude Code трактует это
# как «продолжить работу с этим фидбеком в stderr»). Иначе — exit 0.
#
# НЕ запускает полный local-ci.sh — это работа /full-ahead Шаг 2. Здесь только
# быстрые инварианты, выполняемые за секунды.
#
# Регистрируется в .claude/settings.local.json (НЕ в settings.json — settings.json
# автогенерируется). См. playbooks/autonomous-mode.md.
#

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

AGENTS_MD="$REPO_ROOT/AGENTS.md"
ERRORS=()

# -----------------------------------------------------------------------------
# 1. Активирован ли autonomous mode
# -----------------------------------------------------------------------------

if [[ ! -f "$AGENTS_MD" ]]; then
  exit 0
fi

if ! grep -qE '^\*\*Фаза:\*\*.*autonomous_mode:\s*enabled' "$AGENTS_MD" 2>/dev/null; then
  # Autonomous mode не включён — hook не вмешивается.
  exit 0
fi

# -----------------------------------------------------------------------------
# 2. Защищённая ветка — autonomous mode пишет только в feature-ветку, не в main
# -----------------------------------------------------------------------------

CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')"
case "$CURRENT_BRANCH" in
  main|master|develop|release)
    ERRORS+=("ветка '$CURRENT_BRANCH' — защищённая: autonomous mode пишет только в feature-ветку (<тип>/<ID>-slug), не в main")
    ;;
esac

# -----------------------------------------------------------------------------
# 3. Граф связок
# -----------------------------------------------------------------------------

if [[ -x "$REPO_ROOT/scripts/validate-links.sh" ]]; then
  if ! "$REPO_ROOT/scripts/validate-links.sh" >/dev/null 2>&1; then
    ERRORS+=("validate-links.sh: граф знаний красный — есть битые ссылки или orphan-файлы")
  fi
fi

# -----------------------------------------------------------------------------
# 4. Секреты в staged-файлах
# -----------------------------------------------------------------------------

if command -v gitleaks >/dev/null 2>&1; then
  if ! gitleaks protect --staged --no-banner --redact >/dev/null 2>&1; then
    ERRORS+=("gitleaks: обнаружены секреты в staged-файлах")
  fi
fi

# -----------------------------------------------------------------------------
# 5. Активный план: все пункты критерия приёмки отмечены
# -----------------------------------------------------------------------------

# Активный план = самый свежий plans/YYYY-MM-DD-*.md, у которого в шапке нет
# отметки "выполнено" / "completed" / "done".

ACTIVE_PLAN=""
if [[ -d "$REPO_ROOT/plans" ]]; then
  while IFS= read -r plan_file; do
    [[ -z "$plan_file" ]] && continue
    # Пропускаем шаблоны и README
    case "$(basename "$plan_file")" in
      TEMPLATE.md|README.md) continue ;;
    esac
    # Пропускаем уже выполненные
    if head -20 "$plan_file" | grep -qiE '(статус|status):\s*(выполнено|completed|done|закрыт)'; then
      continue
    fi
    ACTIVE_PLAN="$plan_file"
    break
  done < <(ls -t "$REPO_ROOT/plans"/*.md 2>/dev/null || true)
fi

if [[ -n "$ACTIVE_PLAN" ]]; then
  # Ищем секцию "## Критерий приёмки"
  if grep -qE '^##\s+Критерий приёмки' "$ACTIVE_PLAN"; then
    # Считаем невыполненные пункты [ ] (с пробелом) после этого заголовка
    UNCHECKED=$(awk '
      /^##\s+Критерий приёмки/ {in_section=1; next}
      /^##\s+/ && in_section {in_section=0}
      in_section && /^[[:space:]]*-[[:space:]]*\[ \]/ {count++}
      END {print count+0}
    ' "$ACTIVE_PLAN")

    if [[ "$UNCHECKED" -gt 0 ]]; then
      ERRORS+=("план $(basename "$ACTIVE_PLAN"): не выполнено $UNCHECKED пунктов критерия приёмки")
    fi
  fi
fi

# -----------------------------------------------------------------------------
# Финал
# -----------------------------------------------------------------------------

if [[ ${#ERRORS[@]} -eq 0 ]]; then
  exit 0
fi

{
  echo "⚠️  Stop hook чеклист (autonomous mode) — не зелёный:"
  for err in "${ERRORS[@]}"; do
    echo "  - $err"
  done
  echo ""
  echo "Цикл /full-ahead не считается завершённым. Поправь и попробуй снова."
  echo "Чтобы выйти из autonomous mode разово — убери 'autonomous_mode: enabled' из AGENTS.md §0."
} >&2

exit 2
