"""DEPRECATED direction.

`lib/chess/*` and `lib/l10n/models/*` shared files are now re-exports of
`packages/super_chess_engine`. Edit the package, then (if needed) regenerate
nothing — Flutter imports the shims.

To pull Flutter-only experiments back into the package, copy manually from git
history, not via this script.
"""
from __future__ import annotations

import sys


def main() -> None:
    print(
        "Refusing to sync: lib/ engine files are shims.\n"
        "Edit packages/super_chess_engine/lib/src/ instead.",
        file=sys.stderr,
    )
    raise SystemExit(1)


if __name__ == "__main__":
    main()
