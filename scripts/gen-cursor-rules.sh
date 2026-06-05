#!/usr/bin/env bash
#
# gen-cursor-rules.sh — генерирует .cursor/rules/*.mdc из .claude/skills/*/SKILL.md.
#
# Cursor использует формат rules-файлов с YAML frontmatter (description + alwaysApply).
# Логика та же что и у .claude/skills/: тонкая обёртка с указанием на playbook.
# Контент playbook'ов не дублируется — обёртка ссылается на playbooks/<name>.md.
#
# Использование:
#   scripts/gen-cursor-rules.sh             # сгенерировать / обновить
#   scripts/gen-cursor-rules.sh --check     # проверить актуальность без записи; exit 1 если расходится
#
# После генерации Cursor подхватит команды по тому же принципу, что Claude Code:
# триггерные фразы — в description, тело — ссылка на playbook.
#

set -euo pipefail

# Pre-check: python3 ≥ 3.8.
if ! command -v python3 >/dev/null 2>&1; then
  echo "✗ gen-cursor-rules: требуется python3 (не найден в PATH)." >&2
  echo "  Установка: macOS — 'brew install python3'; Linux — пакет 'python3'." >&2
  exit 127
fi
if ! python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 8) else 1)' 2>/dev/null; then
  PY_VER="$(python3 --version 2>&1 || echo unknown)"
  echo "✗ gen-cursor-rules: требуется Python 3.8+ (найден: $PY_VER)." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

MODE="${1:-generate}"

SKILLS_DIR=".claude/skills"
RULES_DIR=".cursor/rules"

if [[ ! -d "$SKILLS_DIR" ]]; then
  echo "✗ Не найдена папка $SKILLS_DIR — нет skill'ов для конвертации." >&2
  exit 1
fi

python3 - "$SKILLS_DIR" "$RULES_DIR" "$MODE" <<'PY'
from __future__ import annotations
import re
import sys
from pathlib import Path

skills_dir = Path(sys.argv[1])
rules_dir = Path(sys.argv[2])
mode = sys.argv[3]

FRONTMATTER_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.DOTALL)


def parse_frontmatter(text: str) -> dict[str, str]:
    """Извлекает простые `key: value` пары из YAML frontmatter.
    Поддерживает многострочный value через продолжение (отступ-пробел)."""
    m = FRONTMATTER_RE.match(text)
    if not m:
        return {}
    block = m.group(1)
    result: dict[str, str] = {}
    current_key: str | None = None
    for raw in block.splitlines():
        if not raw.strip():
            continue
        # Простая пара "key: value" в начале строки (без отступа).
        match = re.match(r"^([A-Za-z_][\w-]*):\s*(.*)$", raw)
        if match and not raw.startswith(("  ", "\t")):
            current_key = match.group(1)
            result[current_key] = match.group(2).strip()
        elif current_key and raw.startswith((" ", "\t")):
            # Продолжение многострочного значения.
            result[current_key] = (result[current_key] + " " + raw.strip()).strip()
    return result


def render_rule(name: str, description: str) -> str:
    # Description должен быть в одной строке — Cursor парсит как простой scalar.
    desc_one_line = " ".join(description.split())
    return (
        "---\n"
        f"description: {desc_one_line}\n"
        "alwaysApply: false\n"
        "---\n\n"
        f"См. процедуру в [playbooks/{name}.md](../../playbooks/{name}.md). "
        "Выполни её пошагово.\n"
    )


skills: list[tuple[str, str]] = []
for skill_dir in sorted(skills_dir.iterdir()):
    if not skill_dir.is_dir():
        continue
    skill_md = skill_dir / "SKILL.md"
    if not skill_md.exists():
        continue
    fm = parse_frontmatter(skill_md.read_text(encoding="utf-8"))
    name = fm.get("name") or skill_dir.name
    description = fm.get("description", "")
    if not description:
        print(f"⚠ Пропущен {skill_md} — нет description в frontmatter.", file=sys.stderr)
        continue
    skills.append((name, description))

if not skills:
    print("✗ Не найдено ни одного skill с валидным frontmatter.", file=sys.stderr)
    sys.exit(1)

# Сравниваем с существующими .mdc файлами.
diverged: list[str] = []
created: list[str] = []
updated: list[str] = []
ok: list[str] = []

for name, description in skills:
    target = rules_dir / f"{name}.mdc"
    new_content = render_rule(name, description)
    if target.exists():
        old_content = target.read_text(encoding="utf-8")
        if old_content == new_content:
            ok.append(name)
            continue
        if mode == "--check":
            diverged.append(name)
            continue
        target.write_text(new_content, encoding="utf-8")
        updated.append(name)
    else:
        if mode == "--check":
            diverged.append(name)
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(new_content, encoding="utf-8")
        created.append(name)

# Орфаны: .mdc-файлы без соответствующего skill — это not our problem, не трогаем.

if mode == "--check":
    if diverged:
        print(f"✗ .cursor/rules расходится с .claude/skills: {len(diverged)} файлов нужно обновить.", file=sys.stderr)
        for n in diverged:
            print(f"  - {n}.mdc", file=sys.stderr)
        print("  Запусти: scripts/gen-cursor-rules.sh", file=sys.stderr)
        sys.exit(1)
    print(f"  ✓ .cursor/rules синхронизирован с .claude/skills ({len(ok)} файлов)")
    sys.exit(0)

total = len(skills)
print(f"  ✓ Cursor rules: {len(created)} создано, {len(updated)} обновлено, "
      f"{len(ok)} без изменений (всего {total}).")
PY
