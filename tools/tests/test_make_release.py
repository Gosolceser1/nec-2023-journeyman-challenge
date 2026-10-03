"""make_release.py packs the macOS .app without breaking it: the executable bit
survives, the texts sit beside the .app, and nothing is added inside the signed
bundle (check_macos_zip catches each way of getting that wrong)."""
from __future__ import annotations

import hashlib
import plistlib
import shutil
import stat
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "release"))
import make_release  # noqa: E402
import sync_identity  # noqa: E402

APP = "NEC Test App"
EXE_MODE = (stat.S_IFREG | 0o755) << 16
FILE_MODE = (stat.S_IFREG | 0o644) << 16
DIR_MODE = (stat.S_IFDIR | 0o755) << 16 | 0x10


def _entry(z: zipfile.ZipFile, name: str, data: bytes | None, mode: int, system: int = make_release.UNIX) -> None:
    info = zipfile.ZipInfo(name, date_time=(2026, 10, 3, 12, 0, 0))
    info.create_system = system
    info.external_attr = mode
    info.compress_type = zipfile.ZIP_DEFLATED
    z.writestr(info, b"" if data is None else data)


def godot_zip(path: Path, exe_mode: int = EXE_MODE, extra: dict[str, bytes] | None = None,
              tamper: dict[str, bytes] | None = None, system: int = make_release.UNIX) -> None:
    """A zip shaped like Godot's macOS export: <APP>.app with a sealed Resources/."""
    resources = {"Resources/icon.icns": b"icns" * 64, f"Resources/{APP}.pck": b"GDPC" * 4096,
                 "Resources/PrivacyInfo.xcprivacy": b"<plist/>"}
    files2 = {k: {"hash": hashlib.sha1(v).digest(), "hash2": hashlib.sha256(v).digest()} for k, v in resources.items()}
    info_plist = plistlib.dumps({"CFBundleExecutable": APP, "CFBundleIdentifier": "com.example.test"})
    contents = {"Info.plist": info_plist, "PkgInfo": b"APPL????",
                "_CodeSignature/CodeResources": plistlib.dumps({"files": {}, "files2": files2}),
                **resources, **(tamper or {}), **(extra or {})}
    with zipfile.ZipFile(path, "w") as z:
        for d in ("", "Contents/", "Contents/MacOS/", "Contents/Resources/", "Contents/_CodeSignature/"):
            _entry(z, f"{APP}.app/{d}", None, DIR_MODE, system)
        _entry(z, f"{APP}.app/Contents/MacOS/{APP}", b"\xca\xfe\xba\xbe" + b"\0" * 256, exe_mode, system)
        for rel, data in contents.items():
            _entry(z, f"{APP}.app/Contents/{rel}", data, FILE_MODE, system)


class MacPackagingTests(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix="make_release_"))
        self.src = self.tmp / "godot.zip"
        self.out = self.tmp / "out.zip"
        self.texts = {"README.txt": "read me\r\nsecond line\r\n", "CREDITS.txt": "credits\n"}

    def tearDown(self):
        shutil.rmtree(self.tmp)

    def pack(self, **godot) -> list[str]:
        godot_zip(self.src, **godot)
        make_release.package_macos(self.src, self.out, APP, self.texts)
        return make_release.check_macos_zip(self.out, APP, source=self.src)

    def test_clean_export_packs_whole(self):
        self.assertEqual(self.pack(), [])
        with zipfile.ZipFile(self.out) as z, zipfile.ZipFile(self.src) as s:
            names = z.namelist()
            exe = z.getinfo(f"{APP}/{APP}.app/Contents/MacOS/{APP}")
            self.assertEqual(exe.create_system, make_release.UNIX)
            self.assertTrue(exe.external_attr >> 16 & 0o111, "the executable keeps its x bit")
            self.assertIn(f"{APP}/README.txt", names)
            self.assertIn(f"{APP}/CREDITS.txt", names)
            self.assertFalse([n for n in names if n.startswith(f"{APP}/{APP}.app/") and n.endswith(".txt")],
                             "no text inside the .app")
            self.assertTrue(all(n.startswith(f"{APP}/") for n in names))
            self.assertEqual(z.read(f"{APP}/README.txt"), b"read me\nsecond line\n", "Mac texts use LF")
            for info in s.infolist():
                twin = z.getinfo(f"{APP}/{info.filename}")
                self.assertEqual((twin.CRC, twin.external_attr, twin.create_system),
                                 (info.CRC, info.external_attr, info.create_system), info.filename)

    def test_file_added_inside_the_bundle_is_caught(self):
        godot_zip(self.src)
        make_release.package_macos(self.src, self.out, APP, self.texts)
        with zipfile.ZipFile(self.out, "a") as z:
            _entry(z, f"{APP}/{APP}.app/Contents/Resources/README.txt", b"oops", FILE_MODE)
        problems = make_release.check_macos_zip(self.out, APP, source=self.src)
        self.assertTrue(any("added inside the signed bundle" in p for p in problems), problems)
        self.assertTrue(any("not in Godot's export" in p for p in problems), problems)

    def test_unsealed_file_is_caught_without_the_source(self):
        godot_zip(self.src, extra={"Resources/notes.txt": b"x"})
        make_release.package_macos(self.src, self.out, APP, self.texts)
        problems = make_release.check_macos_zip(self.out, APP)
        self.assertEqual(problems, ["Contents/Resources/notes.txt: added inside the signed bundle (not in CodeResources)"])

    def test_lost_executable_bit_is_caught(self):
        problems = self.pack(exe_mode=FILE_MODE)
        self.assertTrue(any("lost its executable bit" in p for p in problems), problems)

    def test_dos_entries_are_caught(self):
        # Python's zipfile on Windows writes create_system 0: macOS then ignores the mode bits.
        problems = self.pack(system=0)
        self.assertTrue(any("lost its executable bit" in p for p in problems), problems)

    def test_changed_resource_is_caught(self):
        problems = self.pack(tamper={f"Resources/{APP}.pck": b"GDPC" * 10})
        self.assertTrue(any("changed after signing" in p for p in problems), problems)

    def test_foreign_entry_in_godots_zip_is_refused(self):
        godot_zip(self.src)
        with zipfile.ZipFile(self.src, "a") as z:
            _entry(z, "stray.txt", b"x", FILE_MODE)
        with self.assertRaises(ValueError):
            make_release.package_macos(self.src, self.out, APP, self.texts)


class MacReadmeTests(unittest.TestCase):
    def test_readme_is_filled_and_gives_the_gatekeeper_steps(self):
        ident = sync_identity.identity(ROOT)
        text = make_release.render("README_macOS.txt", ident)
        self.assertNotIn("{", text)
        self.assertTrue(text.startswith(f"{ident['display_name']}  -  version {ident['version']}  (macOS)"))
        for want in ("Applications", "Privacy & Security", "Open Anyway", "Control-click",
                     f'xattr -dr com.apple.quarantine "/Applications/{ident["display_name"]}.app"',
                     f"~/Library/Application Support/{ident['user_dir']}",
                     f"{ident['file_stem']}_v{ident['version']}_macOS.zip"):
            self.assertIn(want, text)


if __name__ == "__main__":
    unittest.main()
