#!/usr/bin/env bash
#
# validate-links.sh — тонкий wrapper над validate-links.py.
#
# Логика валидации перенесена в Python (см. ADR replace-bash-link-validator):
# bash 4-зависимые конструкции (mapfile, declare -A) не работают на стоковом
# macOS с bash 3.2. Python 3 есть на всех современных macOS/Linux.
#
# Использование (полная совместимость со старым API):
#   scripts/validate-links.sh             # полный обход
#   scripts/validate-links.sh --changed   # только изменённые файлы
#   scripts/validate-links.sh --report    # отчёт по графу
#

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if ! command -v python3 >/dev/null 2>&1; then
  echo "✗ validate-links: требуется python3 (не найден в PATH)." >&2
  echo "  Установка: macOS — 'brew install python3'; Linux — пакет 'python3' из репо дистрибутива." >&2
  exit 127
fi

exec python3 "$SCRIPT_DIR/validate-links.py" "$@"
