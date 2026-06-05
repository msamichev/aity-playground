#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build-adr-index.py — генератор docs/adr/INDEX.md из директории docs/adr/.

Зачем: в team+ai команда из нескольких разработчиков создаёт ADR параллельно,
и ручная таблица-индекс в AGENTS.md постоянно конфликтует на merge.
Паттерн «один файл = одна запись» из GitLab CHANGELOG conflict crisis:
https://about.gitlab.com/blog/solving-gitlabs-changelog-conflict-crisis/

Запускается на pre-commit и вручную (см. .pre-commit-config.yaml).

Использование:
    python3 scripts/build-adr-index.py             # сгенерировать INDEX.md
    python3 scripts/build-adr-index.py --check     # exit 1 если INDEX.md устарел
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ADR_DIR = Path("docs/adr")
INDEX_FILE = ADR_DIR / "INDEX.md"
EXCLUDE = {"template.md", "README.md", "INDEX.md"}

FILENAME_RE = re.compile(r"^(\d{8})-(\d{4})-(.+)\.md$")
STATUS_RE = re.compile(r"^## Status\s*\n+([^\n]+)", re.MULTILINE)
DECISION_RE = re.compile(r"^## Decision\s*\n+(.+?)(?=\n## |\Z)", re.MULTILINE | re.DOTALL)


def parse_adr(path: Path) -> dict | None:
    """Return dict(date, slug, status, summary) or None if name doesn't match."""
    m = FILENAME_RE.match(path.name)
    if not m:
        return None
    date_part, _time_part, slug = m.groups()
    date_iso = f"{date_part[0:4]}-{date_part[4:6]}-{date_part[6:8]}"

    text = path.read_text(encoding="utf-8")

    status_m = STATUS_RE.search(text)
    status = status_m.group(1).strip() if status_m else "Unknown"

    summary = ""
    decision_m = DECISION_RE.search(text)
    if decision_m:
        body = decision_m.group(1).strip()
        # First non-empty, non-comment line, trimmed.
        for line in body.splitlines():
            line = line.strip()
            if line and not line.startswith("<!--"):
                summary = line
                break
    summary = summary.rstrip(".")
    if len(summary) > 160:
        summary = summary[:157].rstrip() + "..."

    return {"date": date_iso, "slug": slug, "status": status, "summary": summary, "file": path.name}


def build_index(adrs: list[dict]) -> str:
    """Render the INDEX.md content."""
    header = (
        "# Индекс ADR\n\n"
        "> **Генерируется автоматически** скриптом `scripts/build-adr-index.py` "
        "на pre-commit. Не редактируется вручную. Чтобы добавить запись — "
        "создай новый ADR командой `/adr`.\n\n"
        "Шаблон ADR — [`template.md`](template.md). Обоснование автогенерации — "
        "[AGENTS.md §3](../../AGENTS.md#3-индекс-adr).\n\n"
    )

    if not adrs:
        return header + "_Пока ни одного ADR._\n"

    # Sort by date desc, then by slug.
    adrs_sorted = sorted(adrs, key=lambda a: (a["date"], a["slug"]), reverse=True)

    rows = ["| Дата | Slug | Статус | Резюме |", "|---|---|---|---|"]
    for adr in adrs_sorted:
        link = f"[{adr['slug']}]({adr['file']})"
        rows.append(f"| {adr['date']} | {link} | {adr['status']} | {adr['summary']} |")

    return header + "\n".join(rows) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Build docs/adr/INDEX.md from ADR files.")
    parser.add_argument(
        "--check",
        action="store_true",
        help="Exit 1 if INDEX.md is out of date (used in pre-commit/CI).",
    )
    args = parser.parse_args()

    if not ADR_DIR.is_dir():
        print(f"error: directory not found: {ADR_DIR}", file=sys.stderr)
        return 2

    adrs: list[dict] = []
    for path in sorted(ADR_DIR.glob("*.md")):
        if path.name in EXCLUDE:
            continue
        parsed = parse_adr(path)
        if parsed is None:
            print(
                f"warning: skipping {path.name} (filename does not match "
                "'YYYYMMDD-HHmm-<slug>.md')",
                file=sys.stderr,
            )
            continue
        adrs.append(parsed)

    new_content = build_index(adrs)

    if args.check:
        if not INDEX_FILE.exists():
            print(
                f"error: {INDEX_FILE} does not exist. Run "
                "`python3 scripts/build-adr-index.py` to generate it.",
                file=sys.stderr,
            )
            return 1
        current = INDEX_FILE.read_text(encoding="utf-8")
        if current != new_content:
            print(
                f"error: {INDEX_FILE} is out of date. Run "
                "`python3 scripts/build-adr-index.py` to regenerate.",
                file=sys.stderr,
            )
            return 1
        return 0

    INDEX_FILE.write_text(new_content, encoding="utf-8")
    print(f"wrote {INDEX_FILE} ({len(adrs)} ADR(s))")
    return 0


if __name__ == "__main__":
    sys.exit(main())
