#!/usr/bin/env bash
#
# ci-fast.sh — pre-commit уровень: формат, линт, секреты, conventional commits.
#
# Секунды. Запускается чаще всего: каждый commit (через git hook после
# `pre-commit install`) либо вручную перед `git add` на свежесгенерированных
# изменениях.
#
# Запуск:
#   scripts/ci-fast.sh
# Или через orchestrator:
#   scripts/local-ci.sh --fast
#
# См. ADR:
# - https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260518-1432-split-local-ci-into-tiers.md
# - https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260522-1400-team-ai-ci-tiers-with-gitlab-nightly-deep.md
#

set -euo pipefail

echo "==> ci-fast: Pre-commit"
if command -v pre-commit >/dev/null 2>&1; then
  pre-commit run --all-files
else
  echo "  ⚠ pre-commit не установлен."
  echo "    Установка: pip install pre-commit  (или brew install pre-commit)."
  echo "    После установки: pre-commit install --hook-type pre-commit --hook-type commit-msg"
  echo "    Подробнее — /doctor."
  exit 1
fi

echo ""
echo "✓ ci-fast пройден"
