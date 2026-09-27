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


if __name__ == "__main__":
    unittest.main()
