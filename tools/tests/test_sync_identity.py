"""The app's name in project.godot and export_presets.cfg comes from data/app.json."""
from __future__ import annotations

import json
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "release"))
import make_release  # noqa: E402
import sync_identity  # noqa: E402


class RepoTests(unittest.TestCase):
    def test_checked_in_files_agree(self):
        self.assertEqual(sync_identity.sync(ROOT, check=True), [])

    def test_frozen_identifiers(self):
        ident = sync_identity.identity(ROOT)
        self.assertEqual(ident["user_dir"], "NEC2023JourneymanChallenge")
        self.assertEqual(ident["android_package"], "com.livewire.nec2023.trainer")
        self.assertIn("NEC 2023 Journeyman Challenge", ident["legacy_project_names"])
        self.assertIn("FROZEN", json.loads((ROOT / "data" / "app.json").read_text(encoding="utf-8"))["about"])

    def test_release_texts_have_no_open_placeholders(self):
        ident = sync_identity.identity(ROOT)
        readme = make_release.render("README.txt", ident)
        credits = make_release.render("CREDITS.txt", ident, sounds="(sounds)")
        for text in (readme, credits):
            self.assertNotIn("{", text)
            self.assertTrue(text.startswith(f"{ident['display_name']}  -  version {ident['version']}"))
        self.assertIn(f"%APPDATA%\\{ident['user_dir']}", readme)
        self.assertIn(f"\"{ident['display_name']}.exe\"", readme)
        self.assertIn(f"{make_release.scored_items()}-question exam simulator", readme)


class FixtureTests(unittest.TestCase):
    """A copy of the identity files in a temp folder, switched to another edition."""

    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix="sync_identity_"))
        (self.tmp / "data").mkdir()
        for rel in ("project.godot", "export_presets.cfg", "data/app.json", "data/edition.json"):
            shutil.copyfile(ROOT / rel, self.tmp / rel)

    def tearDown(self):
        shutil.rmtree(self.tmp)

    def set_edition(self, year: int) -> None:
        path = self.tmp / "data" / "edition.json"
        edition = json.loads(path.read_text(encoding="utf-8"))
        edition.update(year=year, short=f"NEC {year}", dir=f"nec/{year}")
        path.write_text(json.dumps(edition), encoding="utf-8")

    def read(self, rel: str) -> str:
        return (self.tmp / rel).read_bytes().decode("utf-8")

    def test_new_edition_renames_and_keeps_identifiers(self):
        self.set_edition(2026)
        self.assertTrue(sync_identity.sync(self.tmp, check=True))
        before = {rel: self.read(rel) for rel in ("project.godot", "export_presets.cfg")}
        sync_identity.sync(self.tmp)
        godot, presets = self.read("project.godot"), self.read("export_presets.cfg")
        self.assertIn('config/name="NEC 2026 Journeyman Challenge"', godot)
        self.assertIn('config/description="NEC 2026 journeyman electrician exam trainer."', godot)
        self.assertIn('config/custom_user_dir_name="NEC2023JourneymanChallenge"', godot)
        self.assertIn('export_path="release/windows/NEC 2026 Journeyman Challenge.exe"', presets)
        self.assertIn('export_path="build/NEC2026JourneymanChallenge_debug.apk"', presets)
        version = sync_identity.project_version(self.tmp)
        self.assertIn(f'export_path="release/android/NEC2026JourneymanChallenge_v{version}_Android.apk"', presets)
        self.assertIn('application/product_name="NEC 2026 Journeyman Challenge"', presets)
        self.assertEqual(presets.count('package/name="NEC 2026 Journeyman Challenge"'), 2)
        self.assertEqual(presets.count('package/unique_name="com.livewire.nec2023.trainer"'), 2)
        self.assertNotIn("NEC 2023 Journeyman", godot + presets)
        # Only the managed lines changed; CRLF / LF endings and comments survive.
        for rel, old in before.items():
            new = self.read(rel)
            self.assertEqual(old.count("\r\n"), new.count("\r\n"))
            changed = [a for a, b in zip(old.splitlines(), new.splitlines()) if a != b]
            self.assertEqual(len(old.splitlines()), len(new.splitlines()))
            self.assertTrue(all("2023" in line for line in changed), changed)
        self.assertEqual(sync_identity.sync(self.tmp, check=True), [])
        after = {rel: self.read(rel) for rel in before}
        sync_identity.sync(self.tmp)
        self.assertEqual(after, {rel: self.read(rel) for rel in before}, "idempotent")

    def test_frozen_mismatch_is_reported_never_written(self):
        path = self.tmp / "data" / "app.json"
        app = json.loads(path.read_text(encoding="utf-8"))
        app["user_dir"] = "SomethingElse"
        app["android_package"] = "com.example.other"
        path.write_text(json.dumps(app), encoding="utf-8")
        before = self.read("project.godot") + self.read("export_presets.cfg")
        report = sync_identity.sync(self.tmp)
        self.assertEqual(sum(r.startswith("FROZEN") for r in report), 3)
        self.assertEqual(before, self.read("project.godot") + self.read("export_presets.cfg"))

    def test_set_value_only_touches_its_section(self):
        text = '[a]\nname="x"\n\n[b]\nname="x"\n'
        self.assertEqual(sync_identity.set_value(text, "b", "name", 'y "q"'), '[a]\nname="x"\n\n[b]\nname="y \\"q\\""\n')
        self.assertEqual(sync_identity.get_value(sync_identity.set_value(text, "b", "name", 'y "q"'), "b", "name"), 'y "q"')
        with self.assertRaises(KeyError):
            sync_identity.set_value(text, "c", "name", "z")


if __name__ == "__main__":
    unittest.main()
