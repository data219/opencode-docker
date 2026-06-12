#!/usr/bin/env python3
"""Validate bundled OpenCode/Agent Skills layout and frontmatter."""

from __future__ import annotations

import re
import sys
from pathlib import Path

NAME_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
FRONTMATTER_RE = re.compile(r"^---\n(?P<body>.*?)\n---\n", re.DOTALL)
FIELD_RE = re.compile(r"^(?P<key>[A-Za-z0-9_-]+):\s*(?P<value>.*)$")


def parse_frontmatter(path: Path) -> dict[str, str]:
    text = path.read_text(encoding="utf-8")
    match = FRONTMATTER_RE.match(text)
    if not match:
        return {}

    values: dict[str, str] = {}
    for line in match.group("body").splitlines():
        field = FIELD_RE.match(line)
        if not field:
            continue
        values[field.group("key")] = field.group("value").strip().strip('"\'')
    return values


def validate_root(root: Path) -> list[str]:
    errors: list[str] = []
    seen: dict[str, Path] = {}

    if not root.is_dir():
        return [f"{root}: skill root does not exist or is not a directory"]

    for skill_file in sorted(root.rglob("SKILL.md")):
        rel_parent = skill_file.parent.relative_to(root)
        rel = rel_parent.as_posix()
        parent_name = skill_file.parent.name
        metadata = parse_frontmatter(skill_file)
        name = metadata.get("name", "")
        description = metadata.get("description", "")

        if len(rel_parent.parts) != 1:
            errors.append(f"{root}:{rel}: SKILL.md must be directly under the skill root")
        if not name:
            errors.append(f"{root}:{rel}: missing frontmatter name")
        elif not NAME_RE.fullmatch(name):
            errors.append(f"{root}:{rel}: invalid name {name!r}; expected lowercase hyphenated identifier")
        elif name != parent_name:
            errors.append(f"{root}:{rel}: name {name!r} must match parent directory {parent_name!r}")
        if not description:
            errors.append(f"{root}:{rel}: missing frontmatter description")
        if name:
            previous = seen.get(name)
            if previous is not None:
                errors.append(f"{root}:{rel}: duplicate skill name {name!r}; first seen at {previous.relative_to(root).as_posix()}")
            else:
                seen[name] = skill_file.parent

    return errors


def main(argv: list[str]) -> int:
    roots = [Path(arg) for arg in argv[1:]]
    if not roots:
        roots = [Path("bootstrap/skills")]

    errors: list[str] = []
    for root in roots:
        errors.extend(validate_root(root))

    if errors:
        print("Skill validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("Skill validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
