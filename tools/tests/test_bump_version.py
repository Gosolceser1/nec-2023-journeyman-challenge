"""The version is set in project.godot; bump_version.py rewrites every copy."""
from __future__ import annotations

import shutil
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "release"))
import bump_version  # noqa: E402
import sync_identity  # noqa: E402


class RepoTests(unittest.TestCase):
    def test_checked_in_copies_agree(self):
        self.assertEqual(bump_version.check(ROOT), [])

    def test_every_copy_is_found(self):
        wheres = [w for w, _ in bump_version.copies(ROOT)]
        self.assertEqual(sum("file_version" in w or "product_version" in w for w in wheres), 2)
        self.assertEqual(sum("version/name" in w for w in wheres), 2)
        self.assertEqual(len(bump_version.android_codes(ROOT)), 2)


class FixtureTests(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix="bump_version_"))
        (self.tmp / "data").mkdir()
        for rel in ("project.godot", "export_presets.cfg", "data/app.json", "data/edition.json"):
            shutil.copyfile(ROOT / rel, self.tmp / rel)
        self.old = sync_identity.project_version(self.tmp)
        self.code = bump_version.android_codes(self.tmp)[0]

    def tearDown(self):
        shutil.rmtree(self.tmp)

    def read(self, rel: str) -> str:
        return (self.tmp / rel).read_bytes().decode("utf-8")

    def test_bump_rewrites_every_copy_and_the_code(self):
        before = self.read("project.godot") + self.read("export_presets.cfg")
        bump_version.bump("9.8.7", self.tmp)
        self.assertEqual(sync_identity.project_version(self.tmp), "9.8.7")
        self.assertEqual(bump_version.check(self.tmp), [])
        self.assertTrue(all(v == "9.8.7" for _, v in bump_version.copies(self.tmp)))
        self.assertEqual(bump_version.android_codes(self.tmp), [self.code + 1] * 2)
        after = self.read("project.godot") + self.read("export_presets.cfg")
        self.assertIn("_v9.8.7_Android.apk", after)
        self.assertNotIn(self.old, after)
        self.assertEqual(before.count("\r\n"), after.count("\r\n"))
        self.assertEqual(len(before.splitlines()), len(after.splitlines()))

    def test_same_version_keeps_the_code(self):
        self.assertEqual(bump_version.bump(self.old, self.tmp), [])
        self.assertEqual(bump_version.android_codes(self.tmp), [self.code] * 2)

    def test_check_finds_a_stale_copy(self):
        path = self.tmp / "export_presets.cfg"
        text = self.read("export_presets.cfg")
        path.write_bytes(text.replace(f'application/file_version="{self.old}"', 'application/file_version="0.0.1"').encode("utf-8"))
        problems = bump_version.check(self.tmp)
        self.assertEqual(len(problems), 1)
        self.assertIn("file_version", problems[0])

    def test_rejects_a_bad_version(self):
        for bad in ("1.0", "v1.0.5", "1.0.5-rc1", ""):
            with self.assertRaises(ValueError):
                bump_version.bump(bad, self.tmp)


if __name__ == "__main__":
    unittest.main()
