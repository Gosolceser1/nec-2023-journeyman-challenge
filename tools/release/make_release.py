"""Package the exported builds for sharing (docs/RELEASE.md has the full steps).

    python tools/release/make_release.py

Names come from data/app.json (tools/release/sync_identity.py): <app name> is its
display_name, <stem> its file_stem, both filled from data/edition.json.

Expects the release exports to exist (paths from data/app.json "exports"):
  release/windows/<app name>.exe                  (Windows Desktop preset)
  release/android/<stem>_v<ver>_Android.apk       (Android Release, optional)

Writes, all under the gitignored release/:
  <stem>_v<ver>_Windows.zip   one folder: exe, README.txt, CREDITS.txt, THIRD_PARTY_LICENSES.txt
  <stem>_v<ver>_Android.apk   copy of the signed APK (if exported)
  SHA256SUMS.txt              hashes of the zip, the exe inside it and the APK

Runs Godot once (tools/release/dump_licenses.gd), so use a temporary APPDATA.
"""
from __future__ import annotations

import hashlib
import json
import os
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from sync_identity import identity  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
RELEASE = ROOT / "release"


def scored_items(root: Path = ROOT) -> int:
    """The simulator's size: the scored items of data/exam_blueprint.json's areas."""
    blueprint = json.loads((root / "data" / "exam_blueprint.json").read_text(encoding="utf-8"))
    return sum(int(a["items"]) for a in blueprint["areas"])


def render(name: str, ident: dict, **extra) -> str:
    """tools/release/<name> with its {placeholders} filled in."""
    return (HERE / name).read_text(encoding="utf-8").format(
        version=ident["version"], app_name=ident["display_name"], file_stem=ident["file_stem"],
        user_dir=ident["user_dir"], company=ident["company"], edition=ident["edition"]["short"],
        scored_items=scored_items(), **extra)


def sounds_block() -> str:
    """The Pixabay table in assets/sfx/CREDITS.md as plain-text lines."""
    rows = []
    for line in (ROOT / "assets" / "sfx" / "CREDITS.md").read_text(encoding="utf-8").splitlines():
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) == 6 and cells[0].endswith(".wav"):
            file, _when, sound, creator, page, _length = cells
            rows.append(f"  {file:<15} \"{sound}\" by {creator}\n  {'':<15} {page}")
    if not rows:
        sys.exit("no sound rows found in assets/sfx/CREDITS.md")
    return "\n".join(rows)


def dump_licenses(dest: Path) -> None:
    exe = os.environ.get("GODOT") or str(ROOT / "Godot_v4.7.2-stable_win64_console.exe")
    res = subprocess.run([exe, "--headless", "--path", str(ROOT), "--script",
                          "res://tools/release/dump_licenses.gd", "--", str(dest)],
                         capture_output=True, text=True)
    if res.returncode != 0 or not dest.exists():
        sys.exit(f"dump_licenses failed:\n{res.stdout}\n{res.stderr}")


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def crlf(text: str) -> str:
    return text.replace("\r\n", "\n").replace("\n", "\r\n")


def main() -> None:
    ident = identity()
    version, app_name, file_stem = ident["version"], ident["display_name"], ident["file_stem"]
    exe = ROOT / ident["exports"]["Windows Desktop"]
    if not exe.exists():
        sys.exit(f"missing {exe}: export the Windows Desktop preset first")
    apk_src = ROOT / ident["exports"]["Android Release"]

    stage = RELEASE / "staging" / app_name
    if stage.parent.exists():
        shutil.rmtree(stage.parent)
    stage.mkdir(parents=True)
    shutil.copy2(exe, stage / exe.name)
    for name, extra in (("README.txt", {}), ("CREDITS.txt", {"sounds": sounds_block()})):
        text = render(name, ident, **extra)
        (stage / name).write_bytes(crlf(text).encode("utf-8-sig"))
    dump_licenses(stage / "THIRD_PARTY_LICENSES.txt")

    zip_path = RELEASE / f"{file_stem}_v{version}_Windows.zip"
    zip_path.unlink(missing_ok=True)
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for f in sorted(stage.iterdir()):
            z.write(f, f"{app_name}/{f.name}")

    sums = [(sha256(zip_path), zip_path.name), (sha256(exe), exe.name)]
    if apk_src.exists():
        apk = RELEASE / apk_src.name
        shutil.copy2(apk_src, apk)
        sums.append((sha256(apk), apk.name))
    else:
        print(f"note: no APK at {apk_src}, packaging Windows only")
    lines = [f"{h}  {n}" for h, n in sums]
    (RELEASE / "SHA256SUMS.txt").write_bytes(crlf("\n".join(lines) + "\n").encode("utf-8"))

    shutil.rmtree(stage.parent)
    for p in sorted(RELEASE.glob(f"{file_stem}_v{version}_*")) + [RELEASE / "SHA256SUMS.txt"]:
        print(f"{p.stat().st_size / 1e6:9.1f} MB  {p.relative_to(ROOT)}")
    print("\n".join(lines))


if __name__ == "__main__":
    main()
