"""The Godot version is written once, in tools/godot.env."""
from __future__ import annotations

import re
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
import godot_env  # noqa: E402


class GodotEnvTests(unittest.TestCase):
    def test_names_expand_from_the_version(self):
        env = godot_env.load(ROOT)
        version = env["GODOT_VERSION"]
        self.assertRegex(version, r"^\d+\.\d+(\.\d+)?$")
        self.assertEqual(env["GODOT_BINARY"], f"Godot_v{version}-stable_win64_console.exe")
        self.assertEqual(env["GODOT_EDITOR"], f"Godot_v{version}-stable_win64.exe")

    def test_scripts_do_not_repeat_the_version(self):
        version = re.escape(godot_env.load(ROOT)["GODOT_VERSION"])
        for rel in ("tools/verify.sh", ".github/workflows/verify.yml", "tools/release/make_release.py",
                    "tools/branding/build_branding.py"):
            code = [line for line in (ROOT / rel).read_text(encoding="utf-8").splitlines()
                    if not line.lstrip().startswith("#")]
            self.assertFalse([line for line in code if re.search(version, line)], rel)
        bqb = (ROOT / "tools" / "pipeline" / "build_question_bank.sh").read_text(encoding="utf-8")
        self.assertIn("tools/godot.env", next(line for line in bqb.splitlines() if line.startswith("GODOT=")))


if __name__ == "__main__":
    unittest.main()
