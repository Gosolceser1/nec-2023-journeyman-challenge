"""Package the exported builds for sharing (docs/RELEASE.md has the full steps).

    python tools/release/make_release.py

Names come from data/app.json (tools/release/sync_identity.py): <app name> is its
display_name, <stem> its file_stem, both filled from data/edition.json.

Expects the release exports to exist (paths from data/app.json "exports"):
  release/windows/<app name>.exe                  (Windows Desktop preset)
  release/android/<stem>_v<ver>_Android.apk       (Android Release, optional)
  release/macos/<stem>_v<ver>_macOS.zip           (macOS preset, optional)

Writes, all under the gitignored release/:
  <stem>_v<ver>_Windows.zip   one folder: exe, README.txt, CREDITS.txt, THIRD_PARTY_LICENSES.txt
  <stem>_v<ver>_Android.apk   copy of the signed APK (if exported)
  <stem>_v<ver>_macOS.zip     one folder: <app name>.app, README.txt (README_macOS.txt),
                              CREDITS.txt, THIRD_PARTY_LICENSES.txt (if exported)
  SHA256SUMS.txt              hashes of the zips, the exe inside the Windows zip and the APK

The .app is copied entry by entry from Godot's zip with its Unix mode bits, and
nothing is ever written inside it: the executable bit and the ad-hoc signature
must survive (check_macos_zip fails the run otherwise).

Runs Godot once (tools/release/dump_licenses.gd), so use a temporary APPDATA.
"""
from __future__ import annotations

import hashlib
import json
import plistlib
import shutil
import stat
import subprocess
import sys
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from godot_env import godot_binary  # noqa: E402
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
    exe = godot_binary(ROOT)
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


def lf(text: str) -> str:
    return text.replace("\r\n", "\n")


UNIX = 3  # ZipInfo.create_system: macOS reads the mode bits only from Unix entries
# Inside Contents/: covered by the code signature itself, not by CodeResources' files2.
SIGNED_OUTSIDE_FILES2 = ("Info.plist", "PkgInfo", "_CodeSignature/CodeResources")


def _copy_info(info: zipfile.ZipInfo, name: str) -> zipfile.ZipInfo:
    out = zipfile.ZipInfo(name, date_time=info.date_time)
    out.create_system = info.create_system
    out.external_attr = info.external_attr
    out.compress_type = zipfile.ZIP_DEFLATED
    return out


def package_macos(godot_zip: Path, out_zip: Path, app_name: str, texts: dict[str, str]) -> None:
    """Godot's macOS zip under one <app name>/ folder, with texts beside the .app."""
    out_zip.unlink(missing_ok=True)
    with zipfile.ZipFile(godot_zip) as zin, \
            zipfile.ZipFile(out_zip, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as zout:
        for info in zin.infolist():
            if not info.filename.startswith(f"{app_name}.app/"):
                raise ValueError(f"{godot_zip.name}: unexpected entry {info.filename!r}")
            out = _copy_info(info, f"{app_name}/{info.filename}")
            if info.is_dir():
                zout.writestr(out, b"")
                continue
            with zin.open(info) as src, zout.open(out, "w", force_zip64=info.file_size >= zipfile.ZIP64_LIMIT) as dst:
                shutil.copyfileobj(src, dst, 1 << 20)
        for name, text in texts.items():
            info = zipfile.ZipInfo(f"{app_name}/{name}", date_time=zin.infolist()[0].date_time)
            info.create_system = UNIX
            info.external_attr = (stat.S_IFREG | 0o644) << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            zout.writestr(info, lf(text).encode("utf-8"))


def _sha256_entry(z: zipfile.ZipFile, name: str) -> bytes:
    h = hashlib.sha256()
    with z.open(name) as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.digest()


def check_macos_zip(zip_path: Path, app_name: str, source: Path | None = None) -> list[str]:
    """Problems with a packaged macOS zip; [] when the .app will launch as signed.

    The main executable must keep its executable bit (a Unix entry), every file
    in the bundle must be the one its CodeResources manifest hashed (nothing
    added, removed or changed after signing), and with source (Godot's own zip)
    every bundle entry must be byte-identical to it, mode bits included.
    """
    prefix = f"{app_name}/{app_name}.app/"
    problems = []
    with zipfile.ZipFile(zip_path) as z:
        entries = {i.filename: i for i in z.infolist()}
        problems += [f"{n}: outside the {app_name}/ folder" for n in entries if not n.startswith(f"{app_name}/")]
        bundle = {n[len(prefix):]: i for n, i in entries.items() if n.startswith(prefix)}
        try:
            exe = plistlib.loads(z.read(prefix + "Contents/Info.plist"))["CFBundleExecutable"]
            files2 = plistlib.loads(z.read(prefix + "Contents/_CodeSignature/CodeResources"))["files2"]
        except (KeyError, plistlib.InvalidFileException) as e:
            return problems + [f"bundle has no readable Info.plist or CodeResources ({e})"]
        exe_info = bundle.get(f"Contents/MacOS/{exe}")
        mode = exe_info.external_attr >> 16 if exe_info else 0
        if exe_info is None:
            problems.append(f"Contents/MacOS/{exe} is missing")
        elif exe_info.create_system != UNIX or not stat.S_ISREG(mode) or not mode & 0o111:
            problems.append(f"Contents/MacOS/{exe} lost its executable bit (mode {oct(mode)}, system {exe_info.create_system})")
        covered = set(SIGNED_OUTSIDE_FILES2) | {f"MacOS/{exe}"}
        for rel, info in sorted(bundle.items()):
            if info.is_dir():
                continue
            inner = rel.removeprefix("Contents/")
            if inner in covered:
                continue
            sealed = files2.get(inner)
            digest = sealed.get("hash2") if isinstance(sealed, dict) else None
            if digest is None:
                problems.append(f"{rel}: added inside the signed bundle (not in CodeResources)")
            elif _sha256_entry(z, info.filename) != digest:
                problems.append(f"{rel}: changed after signing (hash differs from CodeResources)")
        problems += [f"Contents/{k}: in CodeResources but missing from the bundle"
                     for k in files2 if f"Contents/{k}" not in bundle]
        if source is not None:
            with zipfile.ZipFile(source) as s:
                original = {i.filename.removeprefix(f"{app_name}.app/"): i for i in s.infolist()}
            for rel in sorted(set(original) | set(bundle)):
                a, b = original.get(rel), bundle.get(rel)
                if a is None:
                    problems.append(f"{rel}: added inside the .app (not in Godot's export)")
                elif b is None:
                    problems.append(f"{rel}: missing from the .app")
                elif (a.CRC, a.file_size, a.external_attr, a.create_system) != (b.CRC, b.file_size, b.external_attr, b.create_system):
                    problems.append(f"{rel}: differs from Godot's export (content or mode bits)")
    return problems


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
        print(f"note: no APK at {apk_src}, packaging without Android")
    mac_src = ROOT / ident["exports"]["macOS"]
    if mac_src.exists():
        mac_zip = RELEASE / mac_src.name
        package_macos(mac_src, mac_zip, app_name, {
            "README.txt": render("README_macOS.txt", ident),
            "CREDITS.txt": render("CREDITS.txt", ident, sounds=sounds_block()),
            "THIRD_PARTY_LICENSES.txt": (stage / "THIRD_PARTY_LICENSES.txt").read_text(encoding="utf-8"),
        })
        problems = check_macos_zip(mac_zip, app_name, source=mac_src)
        if problems:
            sys.exit(f"{mac_zip.name} is broken:\n  " + "\n  ".join(problems))
        sums.append((sha256(mac_zip), mac_zip.name))
    else:
        print(f"note: no macOS zip at {mac_src}, packaging without macOS")
    lines = [f"{h}  {n}" for h, n in sums]
    (RELEASE / "SHA256SUMS.txt").write_bytes(crlf("\n".join(lines) + "\n").encode("utf-8"))

    shutil.rmtree(stage.parent)
    for p in sorted(RELEASE.glob(f"{file_stem}_v{version}_*")) + [RELEASE / "SHA256SUMS.txt"]:
        print(f"{p.stat().st_size / 1e6:9.1f} MB  {p.relative_to(ROOT)}")
    print("\n".join(lines))


if __name__ == "__main__":
    main()
