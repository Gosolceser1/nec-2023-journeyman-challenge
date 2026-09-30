"""tools/godot.env for Python: the Godot version and binary names every script uses."""
from __future__ import annotations

import os
import string
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load(root: Path = ROOT) -> dict[str, str]:
    out: dict[str, str] = {}
    for line in (root / "tools" / "godot.env").read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        out[key.strip()] = string.Template(value.strip()).safe_substitute(out)
    return out


def godot_binary(root: Path = ROOT) -> str:
    """$GODOT, else the console binary named in tools/godot.env at the repo root."""
    return os.environ.get("GODOT") or str(root / load(root)["GODOT_BINARY"])
