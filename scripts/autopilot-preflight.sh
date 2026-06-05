#!/usr/bin/env bash
#
# autopilot-preflight.sh — детерминированный pre-flight для автономного режима /autopilot
# (методология team+ai). Запускается на Шаге 0 playbooks/autopilot.md ДО любой работы.
#
# Что проверяет (по приоритету):
#   1. Это git-репозиторий.
#   2. Текущая ветка — НЕ main/master/защищённая и соответствует паттерну
#      <тип>/<...> из AGENTS.md §4.3 (feature|bugfix|hotfix|chore|docs).
#      Нарушение → exit 2 (autopilot не пишет в main и чужие ветки).
#   3. git-tree ЧИСТЫЙ — обязательное условие автономного прогона (точка отката).
#      Грязное дерево → exit 2.
#   4. Фиксирует базовый commit SHA (точка отката) и печатает его для журнала прогона.
#      С флагом --tag дополнительно ставит аннотированный тег autopilot-checkpoint-<ts>.
#   5. Готовность авто-режима (warning, не блокер): .claude/agents/ содержит
#      merge-coordinator и прочих субагентов, scripts/stop-checklist.sh исполняемый.
#
# Предохранители: скрипт НИЧЕГО не удаляет, не коммитит, не пушит. Только читает и
# (опционально) ставит локальный тег. См. security/dangerous-commands.md.
#
# Использование:
#   scripts/autopilot-preflight.sh          # проверка + печать базового SHA
#   scripts/autopilot-preflight.sh --tag    # то же + аннотированный чекпоинт-тег
#

set -euo pipefail

MAKE_TAG=0
for arg in "$@"; do
  case "$arg" in
    --tag) MAKE_TAG=1 ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "autopilot-preflight: неизвестный аргумент '$arg' (см. --help)" >&2
      exit 64
      ;;
  esac
done

# -----------------------------------------------------------------------------
# 1. git-репозиторий
# -----------------------------------------------------------------------------

if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "❌ autopilot-preflight: это не git-репозиторий. Автономный режим требует git (точки отката)." >&2
  exit 2
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

WARNINGS=()

# -----------------------------------------------------------------------------
# 2. Ветка — своя feature-ветка, не main/master/защищённая
# -----------------------------------------------------------------------------

CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"

case "$CURRENT_BRANCH" in
  main|master|develop|release|HEAD)
    {
      echo "❌ autopilot-preflight: текущая ветка '$CURRENT_BRANCH' — защищённая/основная."
      echo "   В team+ai autopilot работает ТОЛЬКО в собственной feature-ветке и не пишет в main."
      echo "   Создай ветку: git switch -c feature/<ID>-slug  (см. AGENTS.md §4.3) и запусти снова."
    } >&2
    exit 2
    ;;
esac

if ! echo "$CURRENT_BRANCH" | grep -qE '^(feature|bugfix|hotfix|chore|docs)/'; then
  {
    echo "❌ autopilot-preflight: имя ветки '$CURRENT_BRANCH' не соответствует паттерну AGENTS.md §4.3."
    echo "   Ожидается: feature/<ID>-slug | bugfix/<ID>-slug | hotfix/<ID>-slug | chore/<slug> | docs/<slug>."
  } >&2
  exit 2
fi

# -----------------------------------------------------------------------------
# 3. Чистое дерево — обязательный инвариант
# -----------------------------------------------------------------------------

if [[ -n "$(git status --porcelain)" ]]; then
  {
    echo "❌ autopilot-preflight: git-tree не чистый."
    echo "   Автономный режим требует чистой базы, чтобы каждая фаза была атомарной точкой отката."
    echo "   Закоммить или спрячь (git stash) текущие изменения и запусти снова."
    echo ""
    echo "   Незакоммиченное:"
    git status --short | sed 's/^/     /'
  } >&2
  exit 2
fi

# -----------------------------------------------------------------------------
# 4. Базовый commit SHA (точка отката) + опциональный тег
# -----------------------------------------------------------------------------

BASE_SHA="$(git rev-parse HEAD)"
BASE_SHA_SHORT="$(git rev-parse --short HEAD)"

CHECKPOINT_TAG=""
if [[ "$MAKE_TAG" -eq 1 ]]; then
  CHECKPOINT_TAG="autopilot-checkpoint-$(date -u +%Y%m%d-%H%M%S)"
  git tag -a "$CHECKPOINT_TAG" -m "autopilot rollback checkpoint" "$BASE_SHA"
fi

# -----------------------------------------------------------------------------
# 5. Готовность авто-режима (warning, не блокер)
# -----------------------------------------------------------------------------

if [[ ! -d "$REPO_ROOT/.claude/agents" ]] || [[ -z "$(ls -A "$REPO_ROOT/.claude/agents" 2>/dev/null || true)" ]]; then
  WARNINGS+=(".claude/agents/ пуст или отсутствует — four-gate review будет деградирован")
elif [[ ! -f "$REPO_ROOT/.claude/agents/merge-coordinator.md" ]]; then
  WARNINGS+=(".claude/agents/merge-coordinator.md отсутствует — четвёртый гейт (структурные проверки ветки) не сработает")
fi

if [[ ! -x "$REPO_ROOT/scripts/stop-checklist.sh" ]]; then
  WARNINGS+=("scripts/stop-checklist.sh отсутствует или не исполняемый — финальный Stop hook чеклист не сработает")
fi

# Напоминание про rebase (не блокер: origin может быть недоступен офлайн)
if git rev-parse --verify --quiet origin/main >/dev/null 2>&1; then
  BEHIND="$(git rev-list --count "HEAD..origin/main" 2>/dev/null || echo 0)"
  if [[ "$BEHIND" -gt 0 ]]; then
    WARNINGS+=("ветка отстаёт от origin/main на $BEHIND коммит(ов) — рекомендуется git rebase origin/main до старта")
  fi
fi

# -----------------------------------------------------------------------------
# Личный checkpoint-файл прогона (.claude/autopilot-checkpoint.md, gitignored).
# Его существование = «прогон autopilot в процессе» — сигнал для хуков
# autopilot-precompact.sh / autopilot-session-start.sh. autopilot удаляет файл
# на чистом финале (см. playbooks/autopilot.md, Шаг 5).
# -----------------------------------------------------------------------------

CHECKPOINT_FILE="$REPO_ROOT/.claude/autopilot-checkpoint.md"
mkdir -p "$REPO_ROOT/.claude"
{
  echo "# autopilot checkpoint (личный, в .gitignore — не коммитить)"
  echo "run_started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "branch: $CURRENT_BRANCH"
  echo "base_sha: $BASE_SHA"
  echo "rollback: git reset --hard $BASE_SHA_SHORT"
  echo ""
  echo "## события"
  echo "- $(date -u +%Y-%m-%dT%H:%M:%SZ) preflight: base $BASE_SHA_SHORT on $CURRENT_BRANCH"
} > "$CHECKPOINT_FILE"

# -----------------------------------------------------------------------------
# Сводка для журнала прогона
# -----------------------------------------------------------------------------

echo "✅ autopilot pre-flight пройден."
echo "   Ветка:        $CURRENT_BRANCH"
echo "   Базовый SHA:  $BASE_SHA_SHORT  ($BASE_SHA)"
echo "   Откат:        git reset --hard $BASE_SHA_SHORT"
echo "   Checkpoint:   .claude/autopilot-checkpoint.md (личный)"
if [[ -n "$CHECKPOINT_TAG" ]]; then
  echo "   Чекпоинт-тег: $CHECKPOINT_TAG"
fi

if [[ ${#WARNINGS[@]} -gt 0 ]]; then
  echo ""
  echo "⚠️  Предупреждения готовности (autopilot может стартовать, но гейты/база деградированы):"
  for w in "${WARNINGS[@]}"; do
    echo "   - $w"
  done
fi

exit 0
