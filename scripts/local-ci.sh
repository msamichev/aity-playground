#!/usr/bin/env bash
#
# local-ci.sh — orchestrator для трёх уровней локального CI в team+ai.
#
# Уровни:
#   ci-fast.sh — секунды, pre-commit hook (формат, линт, секреты).
#   ci-push.sh — минуты, перед push в feature-ветку (build, types, SAST, SCA, tests).
#   ci-deep.sh — десятки минут, opt-in локально для отладки. **Основное место
#                запуска в команде — GitLab CI nightly job `security-deep:nightly`**
#                (см. .gitlab-ci.yml).
#
# Использование:
#   scripts/local-ci.sh             # = ci-push.sh (дефолт перед push в feature)
#   scripts/local-ci.sh --fast      # = ci-fast.sh (pre-commit уровень)
#   scripts/local-ci.sh --deep      # = ci-push.sh + ci-deep.sh (для отладки)
#
# Self-review checklist — в playbooks/self-review.md, читается перед /open-mr.
#
# См. ADR:
# - https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260518-1432-split-local-ci-into-tiers.md
# - https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260522-1400-team-ai-ci-tiers-with-gitlab-nightly-deep.md
#

set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"

MODE="push"
for arg in "$@"; do
  case "$arg" in
    --fast) MODE="fast" ;;
    --deep) MODE="deep" ;;
    --skip-mutation)
      echo "⚠ --skip-mutation устарел: mutation теперь только в --deep (по умолчанию не запускается; основное место — CI nightly)."
      ;;
    -h|--help)
      sed -n '2,21p' "$0"
      exit 0
      ;;
    *)
      echo "Неизвестный флаг: $arg"
      echo "Использование: $0 [--fast | --deep]"
      exit 2
      ;;
  esac
done

case "$MODE" in
  fast)
    "$DIR/ci-fast.sh"
    ;;
  push)
    "$DIR/ci-push.sh"
    ;;
  deep)
    "$DIR/ci-push.sh"
    "$DIR/ci-deep.sh"
    ;;
esac

echo ""
echo "✓ local-ci ($MODE) пройден"
