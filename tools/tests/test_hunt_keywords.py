"""Hunt keywords (data/nec/<year>/hunt_keywords.json) are fresh and never give the answer away.

tools/pipeline/hunt_keywords.py --check regenerates the file in memory and fails
when it is stale or when any record breaks a rule; these tests also pin the leak
rules on hand-made records and walk every bank record directly.
"""
import json
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "pipeline"))
import hunt_keywords  # noqa: E402
import pipeline_paths  # noqa: E402


def load(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))


class HuntKeywordsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.bank = load(hunt_keywords.BANK_PATH)
        cls.data = load(hunt_keywords.output_path())
        cls.articles = load(pipeline_paths.nec_data("articles.json"))["articles"]

    def test_check_passes(self):
        run = subprocess.run([sys.executable, str(ROOT / "tools" / "pipeline" / "hunt_keywords.py"), "--check"],
                             capture_output=True, text=True, cwd=ROOT)
        self.assertEqual(run.returncode, 0, run.stdout + run.stderr)

    def test_every_record_is_listed_once(self):
        ids = [r["id"] for r in self.bank["records"]]
        records, no_lookup = set(self.data["records"]), set(self.data["no_lookup"])
        self.assertFalse(records & no_lookup)
        self.assertEqual(set(ids), records | no_lookup)

    def test_every_keyword_is_safe(self):
        by_id = {r["id"]: r for r in self.bank["records"]}
        for rid, entry in self.data["records"].items():
            record = by_id[rid]
            prompt, answer = record["prompt"], hunt_keywords.correct_text(record)
            with self.subTest(rid=rid):
                self.assertTrue(entry["keywords"] or entry.get("none"))
                for kw in entry["keywords"]:
                    self.assertIn(kw["text"], prompt)
                    self.assertFalse(hunt_keywords.contains_phrase(kw["text"], answer), kw)
                    self.assertFalse(hunt_keywords.contains_phrase(kw["index"], answer), kw)
                    self.assertTrue(kw["article"] == "Chapter 9" or kw["article"] in self.articles, kw)
        self.assertEqual(hunt_keywords.problems(self.data, self.bank, self.articles), [])

    def test_leak_rules(self):
        rec = {"prompt": "Where installed in a wet location, the box shall be ___.",
               "answers": ["weatherproof", "listed", "raintight", "a wet location box"], "correct_index": 3}
        self.assertEqual(hunt_keywords.leaks(rec, "wet location", "Wet locations", []), "keyword is part of the correct choice")
        rec["correct_index"] = 0
        self.assertEqual(hunt_keywords.leaks(rec, "wet location", "Wet locations", []), "")
        self.assertEqual(hunt_keywords.leaks(rec, "box", "Boxes, weatherproof", []), "Index heading names the correct choice")
        grc = {"prompt": "Which raceway may be used here?", "answers": ["EMT", "RMC", "ENT", "FMC"], "correct_index": 1}
        self.assertEqual(hunt_keywords.leaks(grc, "raceway", "Raceways", ["rigid metal conduit", "RMC"]),
                         "correct choice is a synonym of the keyword")
        shared = {"prompt": "A copper conductor shall be ___.",
                  "answers": ["copper, 6 AWG", "copper, 4 AWG", "copper, 2 AWG", "copper, 1 AWG"], "correct_index": 0}
        self.assertEqual(hunt_keywords.leaks(shared, "copper", "Copper", []), "")
        plural = {"prompt": "Separately installed pressure connectors shall be rated for the ___.",
                  "answers": ["connector", "equipment", "system", "conductors"], "correct_index": 0}
        self.assertEqual(hunt_keywords.leaks(plural, "pressure connectors", "Terminals", []), "keyword contains the correct choice")
        self.assertEqual(hunt_keywords.leaks(plural, "installed", "Lockable disconnects", []), "")

    def test_no_keyword_points_at_any_choice(self):
        # Coloring 'rear or side access' put the distractor 'rear' in amber.
        rec = {"prompt": "Each section that requires rear or side access to make field connections shall be marked on the ___.",
               "answers": ["front", "right side", "left side", "rear"], "correct_index": 0}
        self.assertEqual(hunt_keywords.leaks(rec, "rear or side access", "Switchboards and switchgear", []),
                         "keyword holds the choice 'rear'")
        self.assertEqual(hunt_keywords.leaks(rec, "field connections", "Switchboards and switchgear", []), "")
        sup = {"prompt": "x", "answers": ["Supplementary", "Tap", "By-pass", "Branch circuit"], "correct_index": 3}
        self.assertEqual(hunt_keywords.leaks(sup, "process heating", "Supplementary overcurrent protection", []),
                         "Index heading names the choice 'Supplementary'")
        by_id = {r["id"]: r for r in self.bank["records"]}
        for rid, entry in self.data["records"].items():
            choices = [str(a) for a in by_id[rid].get("answers", []) if hunt_keywords.norm(str(a))]
            for kw in entry["keywords"]:
                for choice in choices:
                    if all(hunt_keywords.contains_phrase(c, choice) for c in choices):
                        continue
                    with self.subTest(rid=rid, keyword=kw["text"], choice=choice):
                        self.assertNotEqual(hunt_keywords.norm(kw["text"]), hunt_keywords.norm(choice))
                        self.assertFalse(hunt_keywords.contains_phrase(kw["text"], choice))
                        self.assertFalse(hunt_keywords.contains_phrase(kw["index"], choice))

    def test_article_answers_hide_the_article(self):
        rec = {"prompt": "Which article covers swimming pools?", "answers": ["680", "682", "690", "547"],
               "correct_index": 0}
        self.assertFalse(hunt_keywords.show_article(rec, ["680"]))
        self.assertFalse(hunt_keywords.show_article({"prompt": "See Table ___ for fill.", "answers": ["1"],
                                                     "correct_index": 0}, ["Chapter 9"]))
        self.assertTrue(hunt_keywords.show_article({"prompt": "Pool lights need ___.", "answers": ["GFCI"],
                                                    "correct_index": 0}, ["680"]))

    def test_cited_articles(self):
        self.assertEqual(hunt_keywords.cited_articles("352.100, 352.12(B), and 352.60", self.articles), ["352"])
        self.assertEqual(hunt_keywords.cited_articles("Table 4, Chapter 9", self.articles), ["Chapter 9"])
        self.assertEqual(hunt_keywords.cited_articles("Neb. Rev. Stat. 81-2117", self.articles), [])

    def test_overlapping_keywords_are_refused(self):
        self.assertTrue(hunt_keywords.overlaps("a motor control circuit", "motor control", "control circuit"))
        self.assertFalse(hunt_keywords.overlaps("a motor and a circuit", "motor", "circuit"))


if __name__ == "__main__":
    unittest.main()
