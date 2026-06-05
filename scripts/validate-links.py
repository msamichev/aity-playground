#!/usr/bin/env python3
"""
validate-links.py — валидатор графа знаний.

Проверяет три вещи:
  1) Все Markdown-ссылки на локальные .md-файлы указывают на существующие файлы.
  2) Каждый md в смысловых папках (docs/architecture/, docs/idea/, docs/adr/,
     docs/product/) содержит секцию `## Связки`
     (whitelist для README/INDEX/TEMPLATE).
  3) Orphan-файлы (нет входящих ссылок) — warning, не fail.

Использование:
  scripts/validate-links.py             # полный обход
  scripts/validate-links.py --changed   # только изменённые файлы (для pre-commit)
  scripts/validate-links.py --report    # подробный отчёт по графу
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from pathlib import Path

REQUIRE_LINKS_DIRS = (
    "docs/architecture",
    "docs/idea",
    "docs/adr",
    "docs/product",
)

EXEMPT_FILES = re.compile(r"^(README\.md|INDEX\.md|TEMPLATE\.md|template\.md)$")
EXCLUDE_DIRS = {".git", "node_modules", "experiments", "inbox"}

LINK_RE = re.compile(r"\[[^\]]+\]\(([^)\s]+)\)")
FENCE_RE = re.compile(r"^[`~]{3,}")
# Внутри inline code: убираем только backticks-обёртку, текст оставляем
# (иначе ссылки вида `[`path`](path)` теряют текстовый блок и не парсятся).
INLINE_CODE_RE = re.compile(r"`+([^`\n]+)`+")
SVYAZKI_RE = re.compile(r"^#{2,}\s+Связки", re.MULTILINE)


def find_repo_root() -> Path:
    # Используем CWD как корень — симметрично оригинальной bash-логике
    # ('find . -type f -name *.md'). Это позволяет валидировать конкретную
    # методологию изнутри её каталога, не подтягивая родительские артефакты.
    return Path.cwd()


def list_all_md(root: Path) -> list[Path]:
    files: list[Path] = []
    for path in root.rglob("*.md"):
        rel = path.relative_to(root)
        if any(seg in EXCLUDE_DIRS for seg in rel.parts):
            continue
        files.append(rel)
    return sorted(files)


def list_changed_md(root: Path) -> list[Path]:
    try:
        out = subprocess.check_output(
            ["git", "diff", "--cached", "--name-only", "--diff-filter=ACMR"],
            cwd=root,
            stderr=subprocess.DEVNULL,
        ).decode().splitlines()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return []
    result: list[Path] = []
    for raw in out:
        if not raw.endswith(".md"):
            continue
        p = Path(raw)
        if any(seg in EXCLUDE_DIRS for seg in p.parts):
            continue
        if (root / p).exists():
            result.append(p)
    return result


def strip_code(text: str) -> str:
    lines = text.splitlines()
    out: list[str] = []
    in_code = False
    for line in lines:
        if FENCE_RE.match(line):
            in_code = not in_code
            continue
        if in_code:
            continue
        out.append(INLINE_CODE_RE.sub(r"\1", line))
    return "\n".join(out)


def extract_links(file: Path, root: Path) -> list[str]:
    try:
        text = (root / file).read_text(encoding="utf-8", errors="replace")
    except OSError:
        return []
    return LINK_RE.findall(strip_code(text))


def is_external(target: str) -> bool:
    return target.startswith(("http://", "https://", "mailto:", "ftp://", "#"))


def has_placeholder(target: str) -> bool:
    # Шаблонные имена в угловых скобках: [link](<path>) или [link](path-<x>.md).
    if "<" in target or ">" in target:
        return True
    # Кириллица и другой non-ASCII в URL — это пример-образец синтаксиса
    # (имена файлов в методологии всегда английский kebab-case).
    if any(ord(c) > 127 for c in target):
        return True
    return False


def resolve(file: Path, target: str, root: Path) -> Path | None:
    path_str = target.split("#", 1)[0]
    if not path_str:
        return None
    if path_str.startswith("/"):
        candidate = root / path_str.lstrip("/")
    else:
        candidate = (root / file).parent / path_str
    return Path(os.path.normpath(str(candidate)))


def relpath_to_root(p: Path, root: Path) -> str | None:
    try:
        return str(p.relative_to(root))
    except ValueError:
        return None


def check_broken_links(files: list[Path], root: Path) -> list[str]:
    errors: list[str] = []
    for f in files:
        for raw in extract_links(f, root):
            if is_external(raw) or has_placeholder(raw):
                continue
            resolved = resolve(f, raw, root)
            if resolved is None:
                continue
            if not resolved.exists():
                errors.append(f"{f}: битая ссылка → {raw}")
    return errors


def check_svyazki(files: list[Path], root: Path) -> list[str]:
    errors: list[str] = []
    for f in files:
        if EXEMPT_FILES.match(f.name):
            continue
        rel = str(f)
        require = any(rel.startswith(d + "/") for d in REQUIRE_LINKS_DIRS)
        if not require:
            continue
        try:
            text = (root / f).read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        if not SVYAZKI_RE.search(text):
            errors.append(f"{f}: отсутствует секция '## Связки'")
    return errors


def check_orphans(all_md: list[Path], root: Path) -> list[str]:
    referenced: set[str] = set()
    for f in all_md:
        for raw in extract_links(f, root):
            if is_external(raw) or has_placeholder(raw):
                continue
            resolved = resolve(f, raw, root)
            if resolved is None:
                continue
            rel = relpath_to_root(resolved, root)
            if rel is not None:
                referenced.add(rel)

    warnings: list[str] = []
    for f in all_md:
        if EXEMPT_FILES.match(f.name):
            continue
        if f.name in ("AGENTS.md", "CLAUDE.md", "METHODOLOGY.md"):
            continue
        if f.parts and f.parts[0] in ("experiments", "inbox"):
            continue
        if str(f) not in referenced:
            warnings.append(f"orphan: {f} (нет входящих ссылок)")
    return warnings


def count_links(all_md: list[Path], root: Path) -> int:
    return sum(len(extract_links(f, root)) for f in all_md)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Валидатор графа знаний.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--changed", action="store_true",
        help="только staged md-файлы (для pre-commit)",
    )
    parser.add_argument(
        "--report", action="store_true",
        help="подробный отчёт по графу",
    )
    parser.add_argument("--full", action="store_true", help="полный обход (default)")
    args = parser.parse_args()

    if args.changed:
        mode = "changed"
    elif args.report:
        mode = "report"
    else:
        mode = "full"

    root = find_repo_root()
    all_md = list_all_md(root)

    if mode == "changed":
        target_files = list_changed_md(root)
        if not target_files:
            print("validate-links: нет изменённых md, пропускаем.")
            return 0
    else:
        target_files = all_md

    tty = sys.stdout.isatty()
    RED = "\033[0;31m" if tty else ""
    YEL = "\033[0;33m" if tty else ""
    GRN = "\033[0;32m" if tty else ""
    CYN = "\033[0;36m" if tty else ""
    RST = "\033[0m" if tty else ""

    print(f"{CYN}==> Проверка 1: битые ссылки{RST}")
    broken = check_broken_links(target_files, root)
    for e in broken:
        print(f"{RED}  ✗{RST} {e}", file=sys.stderr)

    print(f"{CYN}==> Проверка 2: секция '## Связки' в смысловых папках{RST}")
    missing_svyazki = check_svyazki(target_files, root)
    for e in missing_svyazki:
        print(f"{RED}  ✗{RST} {e}", file=sys.stderr)

    orphans: list[str] = []
    if mode != "changed":
        print(f"{CYN}==> Проверка 3: orphan-файлы (warning){RST}")
        orphans = check_orphans(all_md, root)
        for w in orphans:
            print(f"{YEL}  ⚠{RST}  {w}")

    errors_count = len(broken) + len(missing_svyazki)
    warnings_count = len(orphans)

    if mode == "report":
        print()
        print(f"{CYN}==> Статистика графа{RST}")
        print(f"  Всего md-файлов:      {len(all_md)}")
        print(f"  Всего ссылок:         {count_links(all_md, root)}")
        print(f"  Ошибок:               {errors_count}")
        print(f"  Warnings (orphan'ы):  {warnings_count}")

    print()
    if errors_count > 0:
        print(f"{RED}✗ validate-links: {errors_count} ошибок, {warnings_count} warnings{RST}")
        return 1
    if warnings_count > 0:
        print(f"{YEL}⚠ validate-links: 0 ошибок, {warnings_count} warnings (orphan'ы){RST}")
    else:
        print(f"{GRN}✓ validate-links: всё в порядке{RST}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
