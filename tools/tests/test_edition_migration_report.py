"""The 2023 -> 2026 migration report: dry run is empty, a renumbering fixture is found."""
from __future__ import annotations

import copy
import json
import re
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "pipeline"))
import edition_migration_report as migration  # noqa: E402
import pipeline_paths  # noqa: E402

BANK = json.loads((ROOT / "data" / "question_bank.json").read_text(encoding="utf-8"))
BLUEPRINT = json.loads((ROOT / "data" / "exam_blueprint.json").read_text(encoding="utf-8"))
CURRENT = migration.load_edition(ROOT / "data" / pipeline_paths.edition()["dir"])


def next_edition() -> dict:
    """A made-up next edition: 220.42 moves to Chapter 1, 210 is retitled, the office load changes."""
    target = copy.deepcopy({k: v for k, v in CURRENT.items() if k not in ("folder", "renumbered")})
    target["folder"] = Path("nec/2026")
    target["renumbered"] = CURRENT["renumbered"] + [(re.compile(r"\b220\.42\b"), "Table 120.42(A)")]
    target["audit"] = {}
    target["articles"][210] = "Branch Circuits (retitled)"
    for row in target["tables"]["tables"]["t220_42a"]["rows"]:
        if row["key"] == "office":
            row["va_ft2"] = 1.4
    return target


class MigrationReportTests(unittest.TestCase):
    def test_dry_run_against_the_current_edition_reports_nothing(self):
        result = migration.report(BANK["records"], CURRENT, CURRENT, BLUEPRINT)
        self.assertEqual(result["flagged"], {})
        self.assertEqual(result["changed_tables"], [])

    def test_renumbering_retitle_and_table_change_are_reported(self):
        result = migration.report(BANK["records"], CURRENT, next_edition(), BLUEPRINT)
        office = result["flagged"]["final-exam-#1-004"]
        self.assertTrue(any("-> Table 120.42(A)" in r and "wiring_protection -> general" in r for r in office), office)
        self.assertIn("Table 220.42(A) values changed", office)
        self.assertIn("no content audit entry for the target edition", office)
        retitled = [rid for rid, reasons in result["flagged"].items() if any("Article 210 retitled" in r for r in reasons)]
        self.assertTrue(retitled)
        self.assertTrue(all(r["id"] in result["flagged"] for r in BANK["records"] if r.get("section") is None))

    def test_a_missing_edition_folder_is_a_clear_error(self):
        with self.assertRaisesRegex(FileNotFoundError, "EDITION_MIGRATION"):
            migration.load_edition(ROOT / "data" / "nec" / "1999")

    def test_chapter_of_matches_the_app(self):
        self.assertEqual(migration.chapter_of("Table 310.16"), 3)
        self.assertEqual(migration.chapter_of("Chapter 9, Table 4"), 9)
        self.assertEqual(migration.chapter_of("NFPA 70E 130.2"), 0)
        self.assertEqual(migration.chapter_of("90.2"), 0)


class BlueprintEditionTests(unittest.TestCase):
    def test_blueprint_names_the_current_edition(self):
        import validate_question_bank as validator
        self.assertEqual(validator.blueprint_edition_problems(BLUEPRINT), [])
        self.assertTrue(validator.blueprint_edition_problems({**BLUEPRINT, "edition": 2020}))
        self.assertTrue(validator.blueprint_edition_problems({k: v for k, v in BLUEPRINT.items() if k != "edition"}))


if __name__ == "__main__":
    unittest.main()
