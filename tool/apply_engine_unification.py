"""Fix package imports after sync and replace Flutter duplicates with re-exports."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PKG_SRC = ROOT / "packages" / "super_chess_engine" / "lib" / "src"

CHESS_SHIMS = [
    "ability_fx_map.dart",
    "board_cataclysm_state.dart",
    "board_labels.dart",
    "board_vfx_event.dart",
    "chess_game.dart",
    "computer_player.dart",
    "fen_export.dart",
    "fx_skin.dart",
    "move.dart",
    "move_codec.dart",
    "move_history.dart",
]
MODEL_SHIMS = [
    "ability_catalog.dart",
    "ability_effects.dart",
    "ability_group.dart",
    "game_ability.dart",
    "piece.dart",
    "square.dart",
    "stockfish_ability_filter.dart",
]


def fix_package_imports() -> None:
    for path in PKG_SRC.rglob("*.dart"):
        text = path.read_text(encoding="utf-8")
        orig = text
        text = text.replace("import '../../chess/", "import '../chess/")
        text = text.replace('import "../../chess/', 'import "../chess/')
        text = text.replace(
            "package:flutter/foundation.dart",
            "package:meta/meta.dart",
        )
        text = re.sub(
            r"import '\.\./l10n/models/",
            "import '../models/",
            text,
        )
        text = re.sub(
            r'import "\.\./l10n/models/',
            'import "../models/',
            text,
        )
        if text != orig:
            path.write_text(text, encoding="utf-8")
            print("fixed", path.relative_to(ROOT))


def write_shims() -> None:
    for name in CHESS_SHIMS:
        path = ROOT / "lib" / "chess" / name
        path.write_text(
            f"export 'package:super_chess_engine/src/chess/{name}';\n",
            encoding="utf-8",
        )
        print("shim", path.relative_to(ROOT))
    for name in MODEL_SHIMS:
        path = ROOT / "lib" / "l10n" / "models" / name
        path.write_text(
            f"export 'package:super_chess_engine/src/models/{name}';\n",
            encoding="utf-8",
        )
        print("shim", path.relative_to(ROOT))


def main() -> None:
    fix_package_imports()
    write_shims()
    print("unification applied")


if __name__ == "__main__":
    main()
