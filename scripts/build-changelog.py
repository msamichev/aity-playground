#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build-changelog.py — собирает CHANGELOG.md из фрагментов в changelogs/unreleased/.

Зачем: в team+ai команда из нескольких разработчиков параллельно дописывает
в CHANGELOG.md, что порождает постоянные merge-конфликты. Паттерн
«один файл = одна запись» от GitLab:
https://about.gitlab.com/blog/solving-gitlabs-changelog-conflict-crisis/

Каждый MR кладёт `changelogs/unreleased/<ID-NNN>-slug.md` со своими
записями. Скрипт читает все эти файлы, группирует по подсекциям
Keep a Changelog (Added/Changed/Fixed/Removed/Deprecated/Security),
вставляет блок `## [X.Y.Z] — DATE` в CHANGELOG.md под `## [Unreleased]`,
затем удаляет исходные фрагменты (через `git rm`, чтобы попало в индекс).

Использование:
    python3 scripts/build-changelog.py --version 0.2.0 --date 2026-05-22
"""
from __future__ import annotations

import argparse
import re
import subprocess
import sys
from collections import OrderedDict
from pathlib import Path

CHANGELOG = Path("CHANGELOG.md")
UNRELEASED_DIR = Path("changelogs/unreleased")
KEEPACHANGELOG_SECTIONS = (
    "Added",
    "Changed",
    "Fixed",
    "Removed",
    "Deprecated",
    "Security",
)

SECTION_HEADER_RE = re.compile(r"^### (Added|Changed|Fixed|Removed|Deprecated|Security)\s*$")


def parse_fragment(path: Path) -> dict[str, list[str]]:
    """Parse one fragment file into {section_name: [bullet_lines]}.

    Bullets are kept as-is (including leading '- ').
    """
    sections: dict[str, list[str]] = OrderedDict()
    current: str | None = None
    for line in path.read_text(encoding="utf-8").splitlines():
        m = SECTION_HEADER_RE.match(line)
        if m:
            current = m.group(1)
            sections.setdefault(current, [])
            continue
        if current is None:
            # Skip content before any known section (titles, frontmatter, etc.)
            continue
        if line.strip().startswith("-"):
            sections[current].append(line.rstrip())
        elif line.strip() == "":
            # Empty line — keep bullet groups separated; only inside section.
            continue
        else:
            # Continuation of a multi-line bullet — append to the last bullet.
            if sections[current]:
                sections[current][-1] += " " + line.strip()
    return sections


def merge_fragments(fragments: list[dict[str, list[str]]]) -> dict[str, list[str]]:
    merged: dict[str, list[str]] = OrderedDict((s, []) for s in KEEPACHANGELOG_SECTIONS)
    for frag in fragments:
        for section, bullets in frag.items():
            if section not in merged:
                continue
            merged[section].extend(bullets)
    return merged


def render_block(version: str, date: str, merged: dict[str, list[str]]) -> str:
    out = [f"## [{version}] — {date}", ""]
    has_any = False
    for section in KEEPACHANGELOG_SECTIONS:
        bullets = merged.get(section) or []
        if not bullets:
            continue
        has_any = True
        out.append(f"### {section}")
        out.append("")
        out.extend(bullets)
        out.append("")
    if not has_any:
        out.append("_No notable changes recorded._")
        out.append("")
    return "\n".join(out)


def insert_after_unreleased(changelog_text: str, new_block: str) -> str:
    """Find `## [Unreleased]` and insert new_block right after its section
    (leaving an empty [Unreleased] for future entries)."""
    # Match: ## [Unreleased] line, then everything up to (but not including) the
    # next `## [` heading or EOF.
    pattern = re.compile(
        r"(## \[Unreleased\]\s*\n)(.*?)(?=\n## \[|\Z)", re.DOTALL
    )
    m = pattern.search(changelog_text)
    if not m:
        print(
            "error: '## [Unreleased]' section not found in CHANGELOG.md. "
            "Add it manually first.",
            file=sys.stderr,
        )
        sys.exit(2)
    replacement = (
        m.group(1)  # '## [Unreleased]\n'
        + "\n"  # empty body for future entries
        + new_block
    )
    return changelog_text[: m.start()] + replacement + changelog_text[m.end():]


def git_rm(paths: list[Path]) -> None:
    if not paths:
        return
    subprocess.run(
        ["git", "rm", "--quiet", *(str(p) for p in paths)],
        check=True,
    )


def main() -> int:
    parser = argparse.ArgumentParser(description="Assemble CHANGELOG.md from unreleased fragments.")
    parser.add_argument("--version", required=True, help="New version, e.g. 0.2.0")
    parser.add_argument("--date", required=True, help="ISO date, e.g. 2026-05-22")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print rendered block but do not modify CHANGELOG.md or remove fragments.",
    )
    args = parser.parse_args()

    if not CHANGELOG.is_file():
        print(f"error: {CHANGELOG} not found", file=sys.stderr)
        return 2

    if not UNRELEASED_DIR.is_dir():
        print(
            f"warning: {UNRELEASED_DIR} not found — assuming no fragments.",
            file=sys.stderr,
        )
        fragment_paths: list[Path] = []
    else:
        fragment_paths = sorted(UNRELEASED_DIR.glob("*.md"))
        # Skip placeholder/readme files.
        fragment_paths = [p for p in fragment_paths if p.name.lower() not in {"readme.md", ".gitkeep"}]

    fragments = [parse_fragment(p) for p in fragment_paths]
    merged = merge_fragments(fragments)
    block = render_block(args.version, args.date, merged)

    if args.dry_run:
        print(block)
        return 0

    new_text = insert_after_unreleased(CHANGELOG.read_text(encoding="utf-8"), block)
    CHANGELOG.write_text(new_text, encoding="utf-8")
    print(f"updated {CHANGELOG} (version {args.version}, {len(fragment_paths)} fragment(s))")

    if fragment_paths:
        git_rm(fragment_paths)
        print(f"git rm'd {len(fragment_paths)} fragment(s) from {UNRELEASED_DIR}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
