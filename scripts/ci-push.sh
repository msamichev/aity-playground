#!/usr/bin/env bash
#
# ci-push.sh — pre-push уровень: build & types, SAST + secrets, SCA + license,
# tests + coverage.
#
# Минуты. Запускается перед `git push` в feature-ветку. Это дефолт
# `/full-ahead` и значение `scripts/local-ci.sh` без флагов.
#
# ВНИМАНИЕ: это ШАБЛОН. Команды под конкретный стек подставляются командой
# /adopt-stack. До /adopt-stack — выполняются только базовые шаги (gitleaks,
# trivy fs).
#
# Подразумевается, что pre-commit hook установлен (`pre-commit install`) и
# `ci-fast.sh` зелёный к моменту запуска. Если pre-commit не настроен —
# сначала прогнать `scripts/ci-fast.sh` или `scripts/local-ci.sh --fast`.
#
# Запуск:
#   scripts/ci-push.sh
# Или через orchestrator (это дефолт):
#   scripts/local-ci.sh
#
# Self-review checklist в команде читается **перед `/open-mr`**, а не перед
# каждым feature-checkpoint push — см. playbooks/self-review.md и
# playbooks/open-mr.md.
#
# См. ADR:
# - https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260518-1432-split-local-ci-into-tiers.md
# - https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260522-1400-team-ai-ci-tiers-with-gitlab-nightly-deep.md
#

set -euo pipefail

# ---------------------------------------------------------------------
# Шаг 1: Build & types
# ---------------------------------------------------------------------
echo "==> 1. Build & types"
# /adopt-stack заполнит:
# - Go:      go build ./... && go vet ./...
# - Python:  ruff check && mypy src/
# - Node:    npm run build && npm run typecheck
# - Kotlin:  ./gradlew build -x test
# - .NET:    dotnet build --no-restore -warnaserror
echo "  (нечего собирать — стек не выбран; запусти /adopt-stack)"

# ---------------------------------------------------------------------
# Шаг 2: SAST + Secret Detection
# ---------------------------------------------------------------------
echo "==> 2. SAST + Secret Detection"
if command -v gitleaks >/dev/null 2>&1; then
  gitleaks detect --no-banner --redact || { echo "  ✗ gitleaks нашёл секреты"; exit 1; }
else
  echo "  ⚠ gitleaks не установлен — пропускаем"
fi
# semgrep — кросс-языковой SAST с custom rules, recommended после ADR-1500.
# Конфиги: p/security-audit (общий) + p/insecure-deserialization (точечно
# против pickle/yaml/eval CVE 2025-2026). --severity ERROR — только блокеры.
# В команде semgrep также может бежать в GitLab CI на MR — локально это
# первая линия защиты, server-side — вторая.
if command -v semgrep >/dev/null 2>&1; then
  semgrep --config "p/security-audit" --config "p/insecure-deserialization" \
          --severity ERROR --quiet --error . \
    || { echo "  ✗ semgrep нашёл ERROR-уязвимости"; exit 1; }
else
  echo "  ⚠ semgrep не установлен — пропускаем расширенный SAST"
  echo "    Установка: pip install semgrep (или brew install semgrep)."
fi
# /adopt-stack дополнит стек-специфичный SAST:
# - Go:      gosec ./...
# - Python:  bandit -r src/   (+ semgrep --config p/python)
# - Node:    semgrep --config p/javascript src/
# - Java:    spotbugs (в gradle) + semgrep --config p/java
# - .NET:    встроенные roslyn analyzers + semgrep --config p/csharp

# ---------------------------------------------------------------------
# Шаг 3: SCA + License Scan
# ---------------------------------------------------------------------
echo "==> 3. SCA + License Scan"
if command -v trivy >/dev/null 2>&1; then
  trivy fs --quiet --severity HIGH,CRITICAL .
else
  echo "  ⚠ trivy не установлен — пропускаем"
fi

# ---------------------------------------------------------------------
# Шаг 4: Tests + coverage
# ---------------------------------------------------------------------
echo "==> 4. Tests + coverage"
# /adopt-stack заполнит. Требование: coverage изменённых файлов ≥ 80%.
echo "  (нет тестов — стек не выбран)"

# ---------------------------------------------------------------------
# Шаг 5: Code duplication (AI-induced)
# ---------------------------------------------------------------------
# Защита от документированной AI-патологии (GitClear 2024: 8x рост
# дубликатов от AI, -44% YoY доли рефакторинга). ADR-1530.
# В команде дубликаты особенно вредны: рефакторить чужой код после squash
# merge дороже, чем переиспользовать существующий хелпер сразу.
echo "==> 5. Code duplication"
if command -v jscpd >/dev/null 2>&1; then
  jscpd --threshold 5 --gitignore --silent . \
    || { echo "  ✗ jscpd: превышен порог 5% дубликатов"; exit 1; }
else
  echo "  ⚠ jscpd не установлен — пропускаем code-clone scan"
  echo "    Установка: npm install -g jscpd (или pip install jscpd-py)."
fi
# /adopt-stack заменит на стек-релевантный:
# - Go:     dupl -threshold 50 ./...
# - Java:   ./gradlew check (с CPD task)
# - Python: pylint --disable=all --enable=duplicate-code src/  (или jscpd)
# - JS/TS:  jscpd (как есть — это его родной стек)
# - .NET:   dotnet duplications

echo ""
echo "✓ ci-push пройден"
echo ""
echo "→ Если за этим push следует /open-mr — прочитай playbooks/self-review.md"
echo "  (7-пунктный смысловой чек-лист, дополняет merge-coordinator subagent)."
echo "  Глубокие проверки (mutation, SBOM, container scan) — opt-in:"
echo "  scripts/local-ci.sh --deep  (основное место в команде — GitLab CI"
echo "  nightly job 'security-deep:nightly', см. .gitlab-ci.yml)."
