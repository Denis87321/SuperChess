"""Rewrite imports inside packages/super_chess_engine/lib/src."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path("packages/super_chess_engine/lib/src")

REPLACEMENTS = [
    (r"package:flutter/foundation\.dart", "package:meta/meta.dart"),
    (r"import '\.\./l10n/models/([^']+)';", r"import '../models/\1';"),
    (r'import "\.\./l10n/models/([^"]+)";', r'import "../models/\1";'),
    (r"import '\.\./models/([^']+)';", r"import '../models/\1';"),
    (r'import "\.\./models/([^"]+)";', r'import "../models/\1";'),
]


def fix_file(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    orig = text
    for pat, repl in REPLACEMENTS:
        text = re.sub(pat, repl, text)
    if text != orig:
        path.write_text(text, encoding="utf-8")
        print("fixed", path)


def main() -> None:
    for path in ROOT.rglob("*.dart"):
        fix_file(path)


if __name__ == "__main__":
    main()
