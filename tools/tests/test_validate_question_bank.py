"""Regression tests for validator rules that must match learner-visible behavior."""
from __future__ import annotations

import importlib.util
import os
from pathlib import Path
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "validate_question_bank", ROOT / "tools" / "pipeline" / "validate_question_bank.py"
)
assert SPEC is not None and SPEC.loader is not None
validator = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(validator)

PATHS_SPEC = importlib.util.spec_from_file_location(
    "pipeline_paths", ROOT / "tools" / "pipeline" / "pipeline_paths.py"
)
assert PATHS_SPEC is not None and PATHS_SPEC.loader is not None
pipeline_paths = importlib.util.module_from_spec(PATHS_SPEC)
PATHS_SPEC.loader.exec_module(pipeline_paths)

OVERRIDES_SPEC = importlib.util.spec_from_file_location(
    "bank_overrides", ROOT / "tools" / "pipeline" / "bank_overrides.py"
)
assert OVERRIDES_SPEC is not None and OVERRIDES_SPEC.loader is not None
bank_overrides = importlib.util.module_from_spec(OVERRIDES_SPEC)
OVERRIDES_SPEC.loader.exec_module(bank_overrides)


class ValidatorRuleTests(unittest.TestCase):
    def test_curated_overrides_replace_and_add_record_fields(self):
        records = [{"id": "q-001", "prompt": "raw", "answers": ["A", "B"]}]
        bank_overrides.apply_overrides(
            records,
            {"version": 1, "records": {"q-001": {"prompt": "curated", "diagram": "image"}}},
        )
        self.assertEqual(records[0], {"id": "q-001", "prompt": "curated", "answers": ["A", "B"], "diagram": "image"})

    def test_curated_overrides_reject_unknown_record_ids(self):
        with self.assertRaises(ValueError):
            bank_overrides.apply_overrides(
                [{"id": "q-001"}],
                {"version": 1, "records": {"missing-001": {"prompt": "x"}}},
            )

    def test_ocr_input_paths_follow_the_documented_environment_overrides(self):
        with patch.dict(
            os.environ,
            {
                "WIRE_OCR_PATH": "C:/tmp/exam-ocr",
                "WIRE_OCR_KEYS": "C:/tmp/key-ocr",
            },
        ):
            self.assertEqual(pipeline_paths.exam_ocr_dir(), Path("C:/tmp/exam-ocr"))
            self.assertEqual(pipeline_paths.answer_key_ocr_dir(), Path("C:/tmp/key-ocr"))

    def test_existing_gist_takes_precedence_over_info_tip_fallback(self):
        record = {
            "gist": "A safe learner-facing summary.",
            "info_tip": (
                "WHAT THIS QUESTION MEANS\nPLAIN-LANGUAGE BACKGROUND\nContext.\n\n"
                "The fallback task says damage.\n\nLOOKUP FOCUS\nraceway"
            ),
        }
        self.assertEqual(
            validator.pre_answer_visible_text(record),
            "A safe learner-facing summary.",
        )

    def test_info_tip_task_is_used_only_when_gist_is_empty(self):
        task = "Find which rule applies to the installation."
        record = {
            "gist": "  ",
            "info_tip": (
                "WHAT THIS QUESTION MEANS\nPLAIN-LANGUAGE BACKGROUND\nContext.\n\n"
                f"{task}\n\nLOOKUP FOCUS\nraceway"
            ),
        }
        self.assertEqual(validator.pre_answer_visible_text(record), task)

    def test_switch_troubleshooting_is_not_mislabeled_as_a_nec_article(self):
        bank = __import__("json").loads(
            (ROOT / "data" / "question_bank.json").read_text(encoding="utf-8")
        )
        record = next(
            row for row in bank["records"] if row["id"] == "final-exam-#1-005"
        )
        self.assertEqual(record["article"], "General knowledge")
        self.assertEqual(record["article_title"], "General knowledge")
        self.assertTrue(record["reference_text"].startswith("Switch and Lamp Troubleshooting"))

    def test_recognizes_nec_refs_and_explicit_non_code_categories(self):
        accepted = (
            "210.8(A)(2)",
            "NEC 210.52(G)(1)",
            "Article 100",
            "DEF 100",
            "Definition 100",
            "Definitions 100",
            "NFPA 70E",
            "Chapter 9, Note 4",
            "Table 8, Chapter 9",
            "General knowledge",
            "General calculation",
        )
        for value in accepted:
            with self.subTest(value=value):
                self.assertTrue(validator.article_reference_is_recognized(value))
        self.assertFalse(
            validator.article_reference_is_recognized("Final Exam #1, Question 5")
        )

    def _prompt_leak_errors(self, record_id, prompt):
        bank = __import__("json").loads((ROOT / "data" / "question_bank.json").read_text(encoding="utf-8"))
        source = next(r for r in bank["records"] if r["id"] == "final-exam-#3-042")
        target = next(r for r in bank["records"] if r["id"] == record_id)
        target.update(prompt=prompt, answers=list(source["answers"]), correct_index=source["correct_index"])
        rep = validator.Report()
        validator.check_records(bank, rep)
        return [e for e in rep.errors if e.startswith(record_id + ":") and "leaks verbatim into 'prompt'" in e]

    def test_prompt_leak_exception_covers_only_the_pinned_record_and_wording(self):
        pdf_prompt = validator.PROMPT_LEAK_EXCEPTIONS["final-exam-#3-042"]
        self.assertEqual(list(validator.PROMPT_LEAK_EXCEPTIONS), ["final-exam-#3-042"])
        self.assertEqual(self._prompt_leak_errors("final-exam-#3-042", pdf_prompt), [])
        self.assertEqual(len(self._prompt_leak_errors("final-exam-#3-041", pdf_prompt)), 1)
        reworded = pdf_prompt.replace("is permitted", "shall be permitted")
        self.assertEqual(len(self._prompt_leak_errors("final-exam-#3-042", reworded)), 1)

    def test_recognizes_nebraska_state_law_citations(self):
        for value in ("Neb. Rev. Stat. 81-2113(2)", "Neb. Rev. Stat. 81-2108(2) and 81-2113(2)", "Title 100 NAC Rule 13"):
            with self.subTest(value=value):
                self.assertTrue(validator.article_reference_is_recognized(value))
        self.assertFalse(validator.article_reference_is_recognized("Nebraska law"))

    def _section_errors(self, record_id, **fields):
        bank = __import__("json").loads((ROOT / "data" / "question_bank.json").read_text(encoding="utf-8"))
        target = next(r for r in bank["records"] if r["id"] == record_id)
        for key, value in fields.items():
            if value is None:
                target.pop(key, None)
            else:
                target[key] = value
        rep = validator.Report()
        validator.check_records(bank, rep)
        return [e for e in rep.errors if e.startswith(record_id + ":") and "section" in e]

    def test_state_law_records_must_carry_their_section(self):
        self.assertEqual(self._section_errors("ne-state-act-#3-001"), [])
        self.assertEqual(len(self._section_errors("ne-state-act-#3-001", section=None)), 1)
        self.assertEqual(len(self._section_errors("final-exam-#1-001", section="nec_typo")), 1)

    def test_state_law_records_are_built_from_the_curated_sources(self):
        spec = importlib.util.spec_from_file_location(
            "state_law_source", ROOT / "tools" / "pipeline" / "state_law_source.py"
        )
        assert spec is not None and spec.loader is not None
        source = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(source)
        built, manifest = source.load_all()
        bank = __import__("json").loads((ROOT / "data" / "question_bank.json").read_text(encoding="utf-8"))
        shipped = [r for r in bank["records"] if r.get("section") == "ne_state_law"]
        self.assertEqual(built, shipped)
        self.assertEqual(manifest, bank["manifest"][-len(manifest):])
        self.assertEqual(bank["records"][-len(built):], built)

    def test_ragged_table_check_ignores_valid_single_cell_note_rows(self):
        table = [
            ["Column A", "Column B"],
            ["value", "value"],
            ["NOTE 1: explanatory text"],
        ]
        self.assertEqual(validator.ragged_table_rows(table), [])

    def test_ragged_table_check_still_reports_malformed_data_rows(self):
        table = [["Column A", "Column B"], ["value"]]
        self.assertEqual(validator.ragged_table_rows(table), [(1, 1)])


class LocationRuleTests(unittest.TestCase):
    ARTICLES = validator.load_nec_articles()
    BOX_TITLE = "Outlet, Device, Pull, and Junction Boxes; Conduit Bodies; Fittings; and Handhole Enclosures"

    def record(self, **fields):
        rec = {
            "id": "q-001",
            "article": "314.23(E)",
            "article_title": self.BOX_TITLE,
            "reference_text": "314.23(E) Raceway-Supported Enclosure, With Devices, Luminaires, or Lampholders\nText.",
            "lookup_summary": "Start with 314.23(E), then read the matching subsection and exceptions.",
            "answers": ["a", "b"],
            "correct_index": 1,
            "choice_notes": ["", "Correct: 314.23(E) requires hubs."],
            "tip_short": "Correct: B — hubs. 314.23(E) requires it. Not A: no.",
        }
        rec.update(fields)
        return validator.location_problems(rec, self.ARTICLES)

    def test_consistent_record_passes(self):
        self.assertEqual(self.record(), [])

    def test_canonical_table_uses_nec_2023_titles(self):
        self.assertEqual(self.ARTICLES[314], self.BOX_TITLE)
        self.assertEqual(self.ARTICLES[210], "Branch Circuits Not Over 1000 Volts AC, 1500 Volts DC, Nominal")
        self.assertNotIn(311, self.ARTICLES)

    def test_stale_or_short_title_is_reported(self):
        problems = self.record(article_title="Outlet, Device, Pull, and Junction Boxes")
        self.assertTrue(any("article_title" in p for p in problems), problems)

    def test_heading_in_another_article_is_reported(self):
        problems = self.record(reference_text="430.9(C) Torque Requirements\nText.")
        self.assertTrue(any("not in Article 314" in p for p in problems), problems)

    def test_heading_naming_a_different_subsection_is_reported(self):
        problems = self.record(article="344.10(A)(4)", article_title=self.ARTICLES[344],
                               reference_text="344.10(A)(3) Corrosive Environments\nText.",
                               lookup_summary="Start with 344.10(A)(4).",
                               choice_notes=["", ""], tip_short="")
        self.assertTrue(any("different subsections" in p for p in problems), problems)

    def test_lookup_hint_pointing_elsewhere_is_reported(self):
        self.assertTrue(self.record(lookup_summary="Start with DEF 100, then read on."))
        self.assertTrue(self.record(lookup_summary="Start with 314.23(F), then read on."))
        self.assertEqual(self.record(lookup_summary="Start with 314.23, then read on."), [])

    def test_rationale_citing_a_neighbouring_subsection_is_reported(self):
        problems = self.record(choice_notes=["", "Correct: 314.23(F) requires hubs."])
        self.assertTrue(any("rationale cites 314.23(F)" in p for p in problems), problems)

    def test_citation_of_an_article_missing_from_nec_2023_is_reported(self):
        problems = self.record(info_tip="See 311.10 for medium voltage.")
        self.assertTrue(any("311" in p for p in problems), problems)

    def test_pre_2023_number_is_reported_unless_called_old(self):
        self.assertTrue(self.record(gist="Use Table 310.15(B)(16) for ampacity."))
        self.assertEqual(self.record(gist="Table 310.15(B)(16) is the old numbering of Table 310.16."), [])

    def test_state_law_records_claim_no_nec_location(self):
        self.assertEqual(validator.location_problems(
            {"section": "ne_state_law", "article": "Neb. Rev. Stat. 81-2108", "article_title": "x"},
            self.ARTICLES), [])


class ContentAuditTests(unittest.TestCase):
    def records(self):
        return [{"id": f"q-{n:03d}", "reference_text": f"210.8(A) Dwelling Units\nText {n}.",
                 "reference_table": [], "correct_index": 1} for n in range(1, 4)]

    def audit(self, records):
        return {"records": {r["id"]: {"status": "verified", "verified_on": "2026-09-28",
                                      "provision": validator.provision_digest(r),
                                      "correct_index": r["correct_index"]} for r in records}}

    def test_audited_bank_passes(self):
        recs = self.records()
        self.assertEqual(validator.content_audit_problems(recs, self.audit(recs)), ([], []))

    def test_changed_provision_or_key_is_an_error(self):
        recs = self.records()
        audit = self.audit(recs)
        recs[0]["reference_text"] += " Edited."
        recs[1]["correct_index"] = 2
        errors, _ = validator.content_audit_problems(recs, audit)
        self.assertTrue(any("q-001" in e and "provision" in e for e in errors), errors)
        self.assertTrue(any("q-002" in e and "correct_index" in e for e in errors), errors)

    def test_unaudited_record_in_a_real_bank_is_reported(self):
        recs = self.records()
        audit = self.audit(recs[:2])
        _, warnings = validator.content_audit_problems(recs, audit)
        self.assertEqual(len(warnings), 1)
        self.assertIn("q-003", warnings[0])

    def test_state_law_records_are_not_audited(self):
        recs = self.records() + [{"id": "ne-001", "section": "ne_state_law", "reference_text": "x",
                                  "reference_table": [], "correct_index": 0}]
        self.assertEqual(validator.content_audit_problems(recs, self.audit(recs[:3])), ([], []))

    def test_checked_in_audit_covers_every_nec_record(self):
        bank = __import__("json").loads((ROOT / "data" / "question_bank.json").read_text(encoding="utf-8"))
        audit = validator.load_content_audit()
        nec = [r["id"] for r in bank["records"] if r.get("section") is None]
        self.assertEqual(sorted(audit["records"]), sorted(nec))
        self.assertEqual(validator.content_audit_problems(bank["records"], audit), ([], []))


if __name__ == "__main__":
    unittest.main()
