"""Text drawn into the splash and the README banner comes from data, not literals."""
from __future__ import annotations

import importlib.util
import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HAS_PIL = importlib.util.find_spec("PIL") is not None
if HAS_PIL:
    sys.path.insert(0, str(ROOT / "tools" / "branding"))
    sys.path.insert(0, str(ROOT / "tools" / "visual"))
    import build_branding  # noqa: E402
    import make_showcase  # noqa: E402


@unittest.skipUnless(HAS_PIL, "Pillow not installed")
class BrandingTextTests(unittest.TestCase):
    def test_splash_text_follows_the_edition(self):
        edition = json.loads((ROOT / "data" / "edition.json").read_text(encoding="utf-8"))
        self.assertEqual(build_branding.EDITION, edition["short"])
        sub = build_branding.splash_subtitle()
        self.assertTrue(sub.startswith(edition["short"] + " EDITION"), sub)
        self.assertNotIn("NFPA", sub, "the splash is brand art, not a code reference")

    def test_banner_facts_come_from_the_data(self):
        facts = make_showcase.hero_facts()
        bank = json.loads((ROOT / "data" / "question_bank.json").read_text(encoding="utf-8"))
        self.assertEqual(facts["questions"], bank["playable"])
        blueprint = json.loads((ROOT / "data" / "exam_blueprint.json").read_text(encoding="utf-8"))
        self.assertEqual(facts["items"], blueprint["scored_items"])
        self.assertTrue(facts["edition"].startswith("NEC "))


if __name__ == "__main__":
    unittest.main()
