"""Package the exported builds for sharing (docs/RELEASE.md has the full steps).

    python tools/release/make_release.py

Expects the release exports to exist:
  release/windows/NEC 2023 Journeyman Challenge.exe       (Windows Desktop preset)
  release/android/NEC2023JourneymanChallenge_v<ver>_Android.apk   (Android Release, optional)

Writes, all under the gitignored release/:
  NEC2023JourneymanChallenge_v<ver>_Windows.zip   one folder: exe, README.txt, CREDITS.txt, THIRD_PARTY_LICENSES.txt
  NEC2023JourneymanChallenge_v<ver>_Android.apk   copy of the signed APK (if exported)
  SHA256SUMS.txt                                  hashes of the zip, the exe inside it and the APK

Runs Godot once (tools/release/dump_licenses.gd), so use a temporary APPDATA.
"""
from __future__ import annotations

import hashlib
import os
import re
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
RELEASE = ROOT / "release"
APP_NAME = "NEC 2023 Journeyman Challenge"
FILE_STEM = "NEC2023JourneymanChallenge"


def project_version() -> str:
    text = (ROOT / "project.godot").read_text(encoding="utf-8")
    m = re.search(r'^config/version="([^"]+)"', text, re.M)
    if not m:
        sys.exit("project.godot has no application/config/version")
    return m.group(1)


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
    version = project_version()
    exe = RELEASE / "windows" / f"{APP_NAME}.exe"
    if not exe.exists():
        sys.exit(f"missing {exe}: export the Windows Desktop preset first")
    apk_src = RELEASE / "android" / f"{FILE_STEM}_v{version}_Android.apk"

    stage = RELEASE / "staging" / APP_NAME
    if stage.parent.exists():
        shutil.rmtree(stage.parent)
    stage.mkdir(parents=True)
    shutil.copy2(exe, stage / exe.name)
    for name, extra in (("README.txt", {}), ("CREDITS.txt", {"sounds": sounds_block()})):
        text = (HERE / name).read_text(encoding="utf-8").format(version=version, **extra)
        (stage / name).write_bytes(crlf(text).encode("utf-8-sig"))
    dump_licenses(stage / "THIRD_PARTY_LICENSES.txt")

    zip_path = RELEASE / f"{FILE_STEM}_v{version}_Windows.zip"
    zip_path.unlink(missing_ok=True)
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for f in sorted(stage.iterdir()):
            z.write(f, f"{APP_NAME}/{f.name}")

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
    for p in sorted(RELEASE.glob(f"{FILE_STEM}_v{version}_*")) + [RELEASE / "SHA256SUMS.txt"]:
        print(f"{p.stat().st_size / 1e6:9.1f} MB  {p.relative_to(ROOT)}")
    print("\n".join(lines))


if __name__ == "__main__":
    main()
