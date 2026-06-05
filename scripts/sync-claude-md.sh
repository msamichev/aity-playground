#!/usr/bin/env bash
#
# sync-claude-md.sh — Windows fallback для AGENTS.md ↔ CLAUDE.md.
#
# На Linux/macOS CLAUDE.md — симлинк на AGENTS.md, и этот скрипт не нужен.
#
# На Windows (если симлинки в git отключены):
#   - CLAUDE.md существует как ОТДЕЛЬНАЯ копия AGENTS.md
#   - Этот скрипт регистрируется как pre-commit hook
#   - При коммите проверяет хеши:
#       - если совпадают → ok
#       - если AGENTS.md новее и хеши разные → копирует AGENTS → CLAUDE, добавляет в коммит
#       - если CLAUDE.md новее → ошибка: «редактировали не тот файл»
#
# Использование (вручную):
#   scripts/sync-claude-md.sh           # проверка + синхронизация
#   scripts/sync-claude-md.sh --check   # только проверка (exit 1 если разъехались)
#
# В .pre-commit-config.yaml:
#   - id: sync-claude-md
#     name: sync CLAUDE.md from AGENTS.md
#     entry: scripts/sync-claude-md.sh
#     language: system
#     files: ^(AGENTS|CLAUDE)\.md$
#

set -euo pipefail

MODE="${1:-sync}"

if [[ ! -f AGENTS.md ]]; then
  echo "✗ AGENTS.md не найден в корне" >&2
  exit 1
fi

# Если CLAUDE.md — симлинк, ничего делать не нужно
if [[ -L CLAUDE.md ]]; then
  target="$(readlink CLAUDE.md)"
  if [[ "$target" == "AGENTS.md" ]]; then
    # Симлинк, всё ок
    exit 0
  else
    echo "✗ CLAUDE.md — симлинк, но не на AGENTS.md (а на $target)" >&2
    exit 1
  fi
fi

# CLAUDE.md — обычный файл (Windows-режим)
if [[ ! -f CLAUDE.md ]]; then
  cp AGENTS.md CLAUDE.md
  echo "✓ CLAUDE.md создан как копия AGENTS.md"
  git add CLAUDE.md 2>/dev/null || true
  exit 0
fi

# Сравниваем хеши (sha256sum на Linux, shasum на macOS)
hash_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}
agents_hash="$(hash_file AGENTS.md)"
claude_hash="$(hash_file CLAUDE.md)"

if [[ "$agents_hash" == "$claude_hash" ]]; then
  # Идентичны
  exit 0
fi

# Разные. Кто изменился последним?
agents_mtime="$(stat -c %Y AGENTS.md 2>/dev/null || stat -f %m AGENTS.md)"
claude_mtime="$(stat -c %Y CLAUDE.md 2>/dev/null || stat -f %m CLAUDE.md)"

if [[ "$MODE" == "--check" ]]; then
  echo "✗ AGENTS.md и CLAUDE.md разошлись" >&2
  echo "  AGENTS.md mtime=$agents_mtime hash=$agents_hash" >&2
  echo "  CLAUDE.md mtime=$claude_mtime hash=$claude_hash" >&2
  exit 1
fi

if [[ "$agents_mtime" -ge "$claude_mtime" ]]; then
  # AGENTS.md новее или одинаково — копируем в CLAUDE.md
  cp AGENTS.md CLAUDE.md
  echo "✓ CLAUDE.md синхронизирован из AGENTS.md"
  git add CLAUDE.md 2>/dev/null || true
  exit 0
else
  # CLAUDE.md новее — это ошибка, AGENTS.md — источник истины
  cat >&2 <<EOF
✗ CLAUDE.md новее чем AGENTS.md — но AGENTS.md источник истины.

Похоже, ты редактировал CLAUDE.md напрямую. Это запрещено правилами:
редактируем только AGENTS.md, CLAUDE.md — копия.

Что делать:
  1) Перенеси изменения из CLAUDE.md в AGENTS.md.
  2) Скопируй обратно: cp AGENTS.md CLAUDE.md
  3) Закоммить заново.
EOF
  exit 1
fi
