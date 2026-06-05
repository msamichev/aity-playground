#!/usr/bin/env bash
#
# gen-claude-deny.sh — генерирует .claude/settings.json из security/dangerous-commands.md.
#
# Этот скрипт запускается:
#   1) на pre-commit, если изменился security/dangerous-commands.md или .claude/settings.json
#   2) вручную при необходимости
#   3) на CI (в режиме --check), для проверки что produced-файл синхронизирован с источником
#
# Использование:
#   scripts/gen-claude-deny.sh             # сгенерировать (обновить если изменилось)
#   scripts/gen-claude-deny.sh --check     # проверить актуальность без записи; exit 1 если не синхронизирован
#

set -euo pipefail

# Pre-check: python3 ≥ 3.8 (нужен для embedded-скрипта генерации JSON).
if ! command -v python3 >/dev/null 2>&1; then
  echo "✗ gen-claude-deny: требуется python3 (не найден в PATH)." >&2
  echo "  Установка: macOS — 'brew install python3' или Xcode Command Line Tools;" >&2
  echo "             Linux — пакет 'python3' из репозитория дистрибутива." >&2
  exit 127
fi
if ! python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 8) else 1)' 2>/dev/null; then
  PY_VER="$(python3 --version 2>&1 || echo unknown)"
  echo "✗ gen-claude-deny: требуется Python 3.8+ (найден: $PY_VER)." >&2
  exit 1
fi

# Корень методологии — родитель scripts/ — всегда корректен независимо от CWD
# и от того, является ли проект отдельным git-репо или подкаталогом мета-репо.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

SRC="security/dangerous-commands.md"
DST=".claude/settings.json"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

MODE="${1:-generate}"

if [[ ! -f "$SRC" ]]; then
  echo "✗ Источник не найден: $SRC" >&2
  exit 1
fi

# -----------------------------------------------------------------------------
# Генерация через Python (для нормального JSON и парсинга)
# -----------------------------------------------------------------------------

python3 - "$SRC" > "$TMP" <<'PY'
from __future__ import annotations
import re
import json
import sys
from pathlib import Path

src_path = sys.argv[1]
content = Path(src_path).read_text(encoding="utf-8")


def extract_between(marker_start: str, marker_end: str) -> list[str]:
    """Возвращает список паттернов в обратных кавычках между маркерами."""
    m = re.search(
        rf"<!-- {marker_start} -->(.*?)<!-- {marker_end} -->",
        content,
        re.DOTALL,
    )
    if not m:
        return []
    block = m.group(1)
    # Извлекаем содержимое каждых обратных кавычек
    return re.findall(r"`([^`]+)`", block)


deny = extract_between("claude-deny-start", "claude-deny-end")
ask = extract_between("claude-ask-start", "claude-ask-end")

if not deny:
    print(
        "✗ Не найдены маркеры claude-deny-start..claude-deny-end в источнике",
        file=sys.stderr,
    )
    sys.exit(1)

settings = {
    "$schema": "https://json.schemastore.org/claude-code-settings.json",
    "_comment": (
        "АВТОГЕНЕРИРОВАН из security/dangerous-commands.md. "
        "НЕ редактировать руками — изменения будут перезаписаны. "
        "Правь источник в security/dangerous-commands.md."
    ),
    "permissions": {
        "deny": deny,
        "ask": ask,
    },
    "_skills_note": (
        "Skills этого проекта — в .claude/skills/ (тонкие обёртки над playbooks/). "
        "Установка глобальных skills — в personal config (~/.claude/), не сюда."
    ),
    "_mcp_servers_note": (
        "MCP-серверы (только context7 по умолчанию) подключаются в personal config либо "
        "через `claude mcp add`. Сюда не добавляем — это меняет окружение коллабораторов."
    ),
}

print(json.dumps(settings, indent=2, ensure_ascii=False))
PY

# -----------------------------------------------------------------------------
# Сравнение со старой версией (нормализуя JSON для устойчивости к whitespace)
# -----------------------------------------------------------------------------

if [[ -f "$DST" ]]; then
  # Используем python для нормализации сравнения
  if python3 -c "
import json, sys
new = json.load(open('$TMP'))
old = json.load(open('$DST'))
sys.exit(0 if new == old else 1)
" 2>/dev/null; then
    # Идентичны
    if [[ "$MODE" == "--check" ]]; then
      echo "  ✓ .claude/settings.json синхронизирован с security/dangerous-commands.md"
    fi
    exit 0
  fi
fi

# Файлы различаются
if [[ "$MODE" == "--check" ]]; then
  echo "✗ .claude/settings.json РАЗОШЁЛСЯ с security/dangerous-commands.md" >&2
  echo "  Запусти: scripts/gen-claude-deny.sh" >&2
  exit 1
fi

# Регенерация
mkdir -p "$(dirname "$DST")"
mv "$TMP" "$DST"
trap - EXIT

# Если в git, добавляем в стейджинг
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git add "$DST" 2>/dev/null || true
fi

echo "  ✓ .claude/settings.json регенерирован из $SRC"
