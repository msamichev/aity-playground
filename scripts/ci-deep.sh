#!/usr/bin/env bash
#
# ci-deep.sh — nightly/weekly уровень: mutation testing, SBOM, container/IaC
# scan.
#
# Десятки минут. В команде **основное место запуска — GitLab CI nightly job**
# `security-deep:nightly` (см. .gitlab-ci.yml, правило
# `rules: $CI_PIPELINE_SOURCE == "schedule"`). Локально — opt-in для отладки
# конкретной регрессии перед открытием MR.
#
# Не запускается по умолчанию `/full-ahead` и не входит в pre-push гейт —
# давит психологически на 4-7 разработчиков и пайплайн.
#
# ВНИМАНИЕ: это ШАБЛОН. Команды под конкретный стек подставляются командой
# /adopt-stack. До /adopt-stack — все шаги печатают «нечего проверять».
#
# Запуск (локально, для отладки):
#   scripts/ci-deep.sh
# Или через orchestrator:
#   scripts/local-ci.sh --deep   # ci-push.sh + ci-deep.sh
#
# См. ADR:
# - https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260518-1432-split-local-ci-into-tiers.md
# - https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260522-1400-team-ai-ci-tiers-with-gitlab-nightly-deep.md
#

set -euo pipefail

# ---------------------------------------------------------------------
# Шаг 1: Mutation testing (incremental, на изменённых файлах)
# ---------------------------------------------------------------------
echo "==> 1. Mutation testing"
# /adopt-stack заполнит:
# - Go:        gremlins unleash --tags integration
# - Python:    mutmut run --paths-to-mutate=src/ --runner='pytest'
# - Node:      stryker run --incremental
# - Java:      ./gradlew pitest --info
# - Kotlin:    ./gradlew pitest
# - .NET:      dotnet stryker --since
# Порог: 75% базовый / 85% для критичных модулей
echo "  (нет mutation-тестера — стек не выбран)"

# ---------------------------------------------------------------------
# Шаг 2: SBOM
# ---------------------------------------------------------------------
echo "==> 2. SBOM"
if command -v cyclonedx-bom >/dev/null 2>&1 || command -v syft >/dev/null 2>&1; then
  # /adopt-stack заполнит точную команду
  echo "  (команда зависит от стека — заполняется /adopt-stack)"
else
  echo "  ⚠ SBOM-инструмент не установлен — пропускаем (CI nightly всё равно посчитает)"
fi

# ---------------------------------------------------------------------
# Шаг 3: Container / IaC scan
# ---------------------------------------------------------------------
echo "==> 3. Container / IaC scan"
if [[ -f Dockerfile ]] && command -v hadolint >/dev/null 2>&1; then
  hadolint Dockerfile
fi
if [[ -d infra ]] || [[ -d terraform ]]; then
  if command -v checkov >/dev/null 2>&1; then
    checkov -d . --quiet
  fi
fi
# Image scan: после билда образа
# trivy image <image>:<tag>

echo ""
echo "✓ ci-deep пройден"
