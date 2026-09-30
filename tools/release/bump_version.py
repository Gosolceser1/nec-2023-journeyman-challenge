"""Set the app version everywhere it is written; project.godot is the source.

    python tools/release/bump_version.py 1.0.5    new version, Android version code + 1
    python tools/release/bump_version.py --check  exit 1 if a copy disagrees

The version lives in project.godot (application/config/version; the app shows
it via Main.version_label()). Copies rewritten here:
  export_presets.cfg  Windows file_version / product_version, Android version/name,
                      Android version/code (one number for both presets, +1 per
                      new version: Android refuses to upgrade to a lower or equal code),
                      the release APK export_path (through sync_identity.py)
Setting the current version again rewrites the copies without a new code.
CHANGELOG.md, README.md and docs/ are written by hand at release time.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import sync_identity  # noqa: E402
from sync_identity import get_value, presets, set_value  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
VERSION_RE = re.compile(r"^\d+\.\d+\.\d+$")
WINDOWS_KEYS = ("application/file_version", "application/product_version")


def _read(root: Path, name: str) -> str:
    return (root / name).read_bytes().decode("utf-8")


def _write(root: Path, name: str, text: str) -> None:
    if _read(root, name) != text:
        (root / name).write_bytes(text.encode("utf-8"))


def copies(root: Path = ROOT) -> list[tuple[str, str]]:
    """(where, value) for every version copy in export_presets.cfg."""
    text = _read(root, "export_presets.cfg")
    out = []
    for section, name, platform in presets(text):
        opts = section + ".options"
        keys = WINDOWS_KEYS if platform == "Windows Desktop" else ("version/name",) if platform == "Android" else ()
        for key in keys:
            out.append((f"export_presets.cfg {name}: {key}", get_value(text, opts, key) or ""))
    return out


def android_codes(root: Path = ROOT) -> list[int]:
    text = _read(root, "export_presets.cfg")
    codes = []
    for section, _name, platform in presets(text):
        if platform == "Android":
            m = re.search(r"^version/code=(\d+)\r?$", _section_text(text, section + ".options"), re.M)
            codes.append(int(m.group(1)) if m else 0)
    return codes


def _section_text(text: str, section: str) -> str:
    m = re.search(r"^\[" + re.escape(section) + r"\]\r?$", text, re.M)
    if not m:
        return ""
    nxt = re.search(r"^\[", text[m.end():], re.M)
    return text[m.end():m.end() + nxt.start()] if nxt else text[m.end():]


def check(root: Path = ROOT) -> list[str]:
    version = sync_identity.project_version(root)
    problems = [f"{where} is {value!r}, project.godot says {version!r}" for where, value in copies(root) if value != version]
    codes = android_codes(root)
    if len(set(codes)) > 1:
        problems.append(f"Android presets disagree on version/code: {codes}")
    problems += [p for p in sync_identity.sync(root, check=True) if "export_path" in p]
    return problems


def bump(new: str, root: Path = ROOT) -> list[str]:
    """Writes new everywhere; returns what changed."""
    if not VERSION_RE.match(new):
        raise ValueError(f"version must look like 1.2.3, got {new!r}")
    old = sync_identity.project_version(root)
    changes = []
    godot = _read(root, "project.godot")
    if old != new:
        _write(root, "project.godot", set_value(godot, "application", "config/version", new))
        changes.append(f"project.godot config/version: {old} -> {new}")
    text = _read(root, "export_presets.cfg")
    codes = android_codes(root)
    code = max(codes, default=0) + (1 if old != new else 0)
    for section, name, platform in presets(text):
        opts = section + ".options"
        keys = WINDOWS_KEYS if platform == "Windows Desktop" else ("version/name",) if platform == "Android" else ()
        for key in keys:
            if get_value(text, opts, key) != new:
                text = set_value(text, opts, key, new)
                changes.append(f"{name}: {key} -> {new}")
        if platform == "Android":
            body = _section_text(text, opts)
            new_body = re.sub(r"^version/code=\d+(\r?)$", rf"version/code={code}\g<1>", body, count=1, flags=re.M)
            if new_body != body:
                text = text.replace(body, new_body, 1)
                changes.append(f"{name}: version/code -> {code}")
    _write(root, "export_presets.cfg", text)
    changes += [c for c in sync_identity.sync(root) if "export_path" in c]
    return changes


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("version", nargs="?", help="new version, x.y.z")
    ap.add_argument("--check", action="store_true", help="report copies that disagree, change nothing")
    args = ap.parse_args()
    if args.check == bool(args.version):
        ap.error("give a version or --check")
    if args.check:
        problems = check()
        for p in problems:
            print(p)
        if not problems:
            print(f"version: every copy is {sync_identity.project_version()} (Android code {android_codes()[0] if android_codes() else '-'})")
        return 1 if problems else 0
    try:
        changes = bump(args.version)
    except ValueError as e:
        ap.error(str(e))
    for c in changes:
        print(c)
    problems = check()
    for p in problems:
        print("still differs:", p)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
