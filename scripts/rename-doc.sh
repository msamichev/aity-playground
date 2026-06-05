#!/usr/bin/env bash
#
# rename-doc.sh — переименовать md-файл и автоматически обновить все ссылки
# на него во всём репо.
#
# Использование:
#   scripts/rename-doc.sh OLD_PATH NEW_PATH
#
# Пример:
#   scripts/rename-doc.sh docs/idea/03-principles.md docs/idea/03-values.md
#
# Что делает:
#   1) Проверяет что OLD_PATH существует и это .md.
#   2) Проверяет что NEW_PATH не существует.
#   3) git mv OLD_PATH NEW_PATH (если есть git) или mv (если нет).
#   4) Находит все ссылки на OLD_PATH во всех .md (с учётом разных способов
#      относительной адресации) и заменяет на NEW_PATH.
#   5) Запускает scripts/validate-links.sh.
#
# НЕ обрабатывает:
#   - якорь после #, если изменилось имя секции (это рядом стоящая задача).
#   - ссылки в коде / комментариях кода — только md.
#

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Использование: $0 OLD_PATH NEW_PATH"
  exit 2
fi

OLD="$1"
NEW="$2"

if [[ ! -f "$OLD" ]]; then
  echo "✗ $OLD: не существует" >&2
  exit 1
fi

if [[ "${OLD##*.}" != "md" ]]; then
  echo "✗ $OLD: ожидался .md файл" >&2
  exit 1
fi

if [[ -e "$NEW" ]]; then
  echo "✗ $NEW: уже существует" >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Нормализуем пути относительно корня репо
old_rel="${OLD#"$REPO_ROOT"/}"
new_rel="${NEW#"$REPO_ROOT"/}"

echo "==> Переименование: $old_rel → $new_rel"

# --- Шаг 1: создать целевую папку, если нужно
mkdir -p "$(dirname "$NEW")"

# --- Шаг 2: перенести файл
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git mv "$OLD" "$NEW"
else
  mv "$OLD" "$NEW"
fi

# --- Шаг 3: для каждого md-файла в репо обновить ссылки
echo "==> Обновление ссылок..."

old_basename="$(basename "$old_rel")"
new_basename="$(basename "$new_rel")"

# Находим все md в репо (без mapfile — он требует bash 4+, на стоковом macOS bash 3.2)
ALL_MD=()
while IFS= read -r line; do
  ALL_MD+=("$line")
done < <(find "$REPO_ROOT" -type f -name '*.md' \
  -not -path '*/node_modules/*' \
  -not -path '*/.git/*' \
  -not -path '*/inbox/*')

updated_count=0

for f in "${ALL_MD[@]}"; do
  f_dir="$(dirname "$f")"

  # Стратегия: для каждой ссылки в файле смотрим, разрешается ли она в OLD.
  # Если да — заменяем на относительный путь к NEW.

  # Используем python — bash тут слишком сложно
  if python3 - "$f" "$REPO_ROOT" "$old_rel" "$new_rel" "$f_dir" <<'PY'
import os, re, sys, pathlib

f, repo_root, old_rel, new_rel, f_dir = sys.argv[1:6]

with open(f, 'r', encoding='utf-8') as fp:
    text = fp.read()

old_abs = os.path.realpath(os.path.join(repo_root, old_rel))
new_abs = os.path.realpath(os.path.join(repo_root, new_rel))

# Парсим Markdown-ссылки [text](target)
pattern = re.compile(r'(\[[^\]]+\]\()([^)\s#]+)([^)]*\))')

# Игнорируем fenced code blocks
lines = text.split('\n')
in_code = False
out_lines = []
changed = False

for line in lines:
    if re.match(r'^[`~]{3,}', line):
        in_code = not in_code
        out_lines.append(line)
        continue
    if in_code:
        out_lines.append(line)
        continue

    def replace(m):
        global changed
        prefix, target, suffix = m.group(1), m.group(2), m.group(3)
        if target.startswith(('http://', 'https://', 'mailto:', 'ftp://', '#')):
            return m.group(0)
        # Резолвим target относительно файла
        resolved = os.path.realpath(os.path.join(f_dir, target))
        if resolved == old_abs:
            # Заменяем на относительный путь к new
            new_target = os.path.relpath(new_abs, start=f_dir)
            changed = True
            return f"{prefix}{new_target}{suffix}"
        return m.group(0)

    out_lines.append(pattern.sub(replace, line))

if changed:
    with open(f, 'w', encoding='utf-8') as fp:
        fp.write('\n'.join(out_lines))
    sys.exit(0)
else:
    sys.exit(42)  # ничего не изменилось
PY
  then
    echo "  ↳ $f"
    updated_count=$((updated_count + 1))
  fi
done

echo "==> Обновлено файлов: $updated_count"

# --- Шаг 4: валидация
if [[ -x "$REPO_ROOT/scripts/validate-links.sh" ]]; then
  echo "==> Валидация..."
  "$REPO_ROOT/scripts/validate-links.sh"
fi

echo "✓ Готово. Закоммить изменения: git add -A && git commit -m \"docs: rename $old_basename → $new_basename\""
