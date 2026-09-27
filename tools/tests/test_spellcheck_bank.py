from __future__ import annotations

import importlib.util
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("spellcheck_bank", ROOT / "tools" / "spellcheck_bank.py")
spellcheck = importlib.util.module_from_spec(spec)
spec.loader.exec_module(spellcheck)


def checks(text: str) -> set[str]:
    return {check for check, _ in spellcheck.mechanical(text)}


class MechanicalChecks(unittest.TestCase):
    def test_flags_doubled_word_on_one_line_only(self):
        self.assertIn("doubled", checks("install the the cable"))
        self.assertNotIn("doubled", checks("547.30 Motors\nMotors and other machinery"))

    def test_flags_spacing_slips(self):
        self.assertIn("spacing", checks("the conductor,which is bare"))
        self.assertIn("spacing", checks("is designated as ."))
        self.assertIn("spacing", checks("rated  20 amperes"))
        self.assertNotIn("spacing", checks("See 314.27(D) Ex., then read 210.8(A)(2)."))

    def test_flags_unit_case(self):
        self.assertIn("unit-case", checks("a 15 kva transformer"))
        self.assertNotIn("unit-case", checks("a 15 kVA transformer on 4/0 AWG"))

    def test_brackets_ignore_inch_and_foot_marks(self):
        self.assertNotIn("brackets", checks('6\'6"'))
        self.assertNotIn("brackets", checks("36\u201d"))
        self.assertIn("brackets", checks("see 210.8(A for details"))
        self.assertIn("brackets", checks('the sign reads "DANGER'))


class Dictionary(unittest.TestCase):
    def test_offline_lexicon_rejects_known_bank_typos(self):
        allow, _ = spellcheck.load_allowlist()
        known, _ = spellcheck.make_known(True, allow)
        for typo in ("sevices", "sheated", "electrcal", "dewelling", "srating"):
            self.assertFalse(known(typo), typo)
        for word in ("ampacity", "luminaire", "services", "kcmil"):
            self.assertTrue(known(word), word)

    def test_current_bank_is_clean_offline(self):
        self.assertEqual(spellcheck.main(["--offline"]), 0)


if __name__ == "__main__":
    unittest.main()
