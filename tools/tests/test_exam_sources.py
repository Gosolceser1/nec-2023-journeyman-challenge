"""Exams are discovered from exams_source_pdf/, not listed in code."""
from __future__ import annotations

import json
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "pipeline"))
import exam_parser  # noqa: E402
import exam_sources  # noqa: E402
import pipeline_paths  # noqa: E402
from pipeline_paths import answer_key_ocr_dir  # noqa: E402


def make_pdfs(folder: Path, names: list[str]) -> None:
    for name in names:
        (folder / f"{name}.pdf").write_bytes(b"%PDF-1.4\n")


class LabelTests(unittest.TestCase):
    def test_open_book_and_final_names(self):
        self.assertEqual(exam_sources.label_for("Journeyman open book exam #11"), ("Open Book Exam #11", False, 11))
        self.assertEqual(exam_sources.label_for("Journeyman open book final exam #2"), ("Final Exam #2", True, 2))
        self.assertEqual(exam_sources.record_id("Final Exam #2", 7), "final-exam-#2-007")

    def test_unknown_pdf_name_is_an_error(self):
        with self.assertRaises(ValueError):
            exam_sources.label_for("Master exam #1")


class DiscoverTests(unittest.TestCase):
    def test_keys_match_in_any_case_and_finals_come_first(self):
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            make_pdfs(folder, [
                "Journeyman open book exam #10", "Journeyman open book exam #10 Answer key",
                "Journeyman open book exam #2", "Journeyman open book exam #2 answer KEY",
                "Journeyman open book final exam #4", "Journeyman open book final exam #4 answer key",
            ])
            exams = exam_sources.discover(folder)
        self.assertEqual([e.label for e in exams], ["Final Exam #4", "Open Book Exam #2", "Open Book Exam #10"])
        self.assertEqual(exams[1].key_stem, "Journeyman open book exam #2 answer KEY")

    def test_exam_without_key_or_key_without_exam_fails(self):
        for names in (["Journeyman open book exam #3"],
                      ["Journeyman open book exam #3", "Journeyman open book exam #3 answer key",
                       "Journeyman open book exam #8 answer key"]):
            with self.subTest(names=names), tempfile.TemporaryDirectory() as tmp:
                make_pdfs(Path(tmp), names)
                with self.assertRaises(ValueError):
                    exam_sources.discover(Path(tmp))

    def test_cover_page_gives_the_question_count(self):
        with tempfile.TemporaryDirectory() as tmp:
            ocr = Path(tmp)
            exam = exam_sources.ExamSource("Journeyman open book exam #99", "Open Book Exam #99", False, 99, "k")
            (ocr / f"{exam.stem}.txt").write_text("=== PAGE 1 ===\nEXAM #99\n25 QUESTIONS |\n", encoding="utf-8")
            self.assertEqual(exam.question_count(ocr), 25)


class ParserTests(unittest.TestCase):
    """The OCR parsers keep every question up to the exam's own count (no fixed cap)."""

    @staticmethod
    def exam_text(count: int) -> str:
        return "".join(f"{n}. Question {n} asks something?\n(a) one (b) two (c) three (d) four\n"
                       for n in range(1, count + 1))

    def test_questions_past_seventy_are_kept(self):
        for count in (25, 80, 120):
            with self.subTest(count=count):
                found = exam_parser.parse_questions(self.exam_text(count), count)
                self.assertEqual(sorted(found), list(range(1, count + 1)))
                self.assertEqual(found[count]["choices"], ["one", "two", "three", "four"])

    def test_key_entries_past_seventy_are_kept(self):
        text = "".join(f"{n}. ({'abcd'[n % 4]}) 210.8(A)\n" for n in range(1, 81))
        answers, refs = exam_parser.parse_key(text, 80)
        self.assertEqual(sorted(answers), list(range(1, 81)))
        self.assertEqual(answers[80], 0)
        self.assertEqual(refs[80], "210.8(A)")

    def test_numbers_beyond_the_count_are_not_questions(self):
        text = self.exam_text(2).replace("asks something?\n", "asks per\n408.36 shall be what?\n", 1)
        found = exam_parser.parse_questions(text, 70)
        self.assertEqual(sorted(found), [1, 2])
        self.assertIn("408.36", found[1]["prompt"])
        self.assertEqual(exam_parser.parse_key("71. (b) 110.26\n", 70), ({}, {}))

    def test_ocr_fixes_from_data_repair_a_sample_page(self):
        page = ("=== PAGE 2 ===\nJourneyman Final Exam #3 TH 12\nThe voitage of a dwel-\nling "
                "sevices | is ___.\n")
        self.assertEqual(exam_parser.normalize(page), "The voltage of a dwelling services is ___.")
        found = exam_parser.parse_questions("1. Pick one.\n(a) 4 (b} 5 () 6 M7\n", 80)
        self.assertEqual(found[1]["choices"], ["4", "5", "6", "7"])


class TesseractTests(unittest.TestCase):
    def test_env_names_the_executable(self):
        with tempfile.TemporaryDirectory() as tmp:
            exe = Path(tmp) / "tesseract.exe"
            exe.write_bytes(b"")
            with patch.dict(os.environ, {"WIRE_TESSERACT": str(exe)}):
                self.assertEqual(pipeline_paths.tesseract_exe(), exe)

    def test_missing_tesseract_is_a_clear_error(self):
        with tempfile.TemporaryDirectory() as tmp, \
                patch.dict(os.environ, {"WIRE_TESSERACT": "", "ProgramFiles": tmp}), \
                patch.object(pipeline_paths.shutil, "which", return_value=None):
            with self.assertRaisesRegex(FileNotFoundError, "WIRE_TESSERACT"):
                pipeline_paths.tesseract_exe()

    def test_scratch_folder_is_named_for_the_project(self):
        self.assertEqual(pipeline_paths.DEFAULT_PIPELINE_DIR.name, "wire_pipeline")


class RepositoryTests(unittest.TestCase):
    def setUp(self):
        self.exams = exam_sources.discover()
        self.bank = json.loads((ROOT / "data" / "question_bank.json").read_text(encoding="utf-8"))

    def test_every_source_pdf_is_an_exam_in_the_bank_manifest(self):
        manifest_exams = {m["source"] for m in self.bank["manifest"]}
        for exam in self.exams:
            with self.subTest(exam=exam.label):
                self.assertIn(exam.label, manifest_exams)
        nec_exams = {r["exam"] for r in self.bank["records"] if r.get("section") is None}
        self.assertEqual(nec_exams, {e.label for e in self.exams})

    def test_manifest_size_per_exam_matches_its_transcript(self):
        for exam in self.exams:
            transcript = exam.transcript()
            if transcript is None:
                continue
            with self.subTest(exam=exam.label):
                slots = [m for m in self.bank["manifest"] if m["source"] == exam.label]
                self.assertEqual(len(slots), transcript["question_count"])

    def key_numbers(self, exam) -> set[int] | None:
        transcript = exam.transcript()
        if transcript is not None:
            return {q["number"] for q in transcript["questions"]} | {k["number"] for k in transcript.get("key_only", [])}
        path = exam.key_ocr_path(answer_key_ocr_dir())
        if not path.exists():
            return None
        # Generous bound: a key entry past the exam's count would expose a dropped question.
        answers, _ = exam_parser.read_key(path, 999)
        return set(answers)

    def test_every_answer_key_entry_reaches_the_bank(self):
        checked = 0
        for exam in self.exams:
            keys = self.key_numbers(exam)
            if keys is None:
                continue
            checked += 1
            with self.subTest(exam=exam.label):
                built = {r["question_number"] for r in self.bank["records"] if r.get("exam") == exam.label}
                missing = {m["number"] for m in self.bank["missing_source_items"] if m["source"] == exam.label}
                slots = [m for m in self.bank["manifest"] if m["source"] == exam.label]
                self.assertFalse(built & missing)
                self.assertEqual(len(built | missing), len(slots))
                self.assertLessEqual(keys, built | missing, "answer-key entries missing from the bank")
                if exam.transcript() is not None:
                    self.assertEqual(len(built | missing), len(keys))
        if not checked:
            self.skipTest("no transcripts and no answer-key OCR cache")

    def test_every_exam_has_a_transcript(self):
        # The build needs no OCR output for the shipped exams (a fresh machine
        # without Tesseract rebuilds the bank).
        for exam in self.exams:
            with self.subTest(exam=exam.label):
                self.assertIsNotNone(exam.transcript(), f"add {exam.transcript_path.name}")

    def test_transcripts_are_well_formed(self):
        allowed = {"question_count", "questions", "provenance", "key_only", "key_only_note"}
        for exam in self.exams:
            transcript = exam.transcript()
            if transcript is None:
                continue
            with self.subTest(exam=exam.label):
                self.assertLessEqual(set(transcript), allowed)
                numbers = [q["number"] for q in transcript["questions"]]
                key_only = [k["number"] for k in transcript.get("key_only", [])]
                self.assertEqual(len(numbers + key_only), len(set(numbers + key_only)))
                self.assertTrue(all(1 <= n <= transcript["question_count"] for n in numbers + key_only))
                for q in transcript["questions"]:
                    self.assertLessEqual({"number", "prompt", "answers", "correct_index", "reference"}, set(q))
                    self.assertLessEqual(set(q), {"number", "prompt", "answers", "correct_index", "reference", "key_note"})
                    self.assertGreaterEqual(len(q["answers"]), 2)
                    self.assertIn(q["correct_index"], range(len(q["answers"])))
                    self.assertTrue(q["prompt"].strip() and q["reference"].strip())


if __name__ == "__main__":
    unittest.main()
