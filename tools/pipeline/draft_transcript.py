#!/usr/bin/env python3
"""Draft the transcript of every exam that has none, from its OCR text.

    python tools/pipeline/draft_transcript.py            all exams without a transcript
    python tools/pipeline/draft_transcript.py --ocr      run Tesseract first where the OCR text is missing

Writes tools/pipeline/sources/exams/<pdf stem>.json in the transcript format
(exam_sources.py) with "provenance" starting "UNREVIEWED OCR DRAFT". A draft is
a starting point: check every stem, choice, key letter and reference against the
PDF page images, add questions the OCR missed, then replace the provenance line
with who reviewed it and when. tools/tests/test_exam_sources.py fails while a
draft is unreviewed, so it cannot ship by accident (docs/ADDING_EXAMS.md).
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from exam_parser import read_key, read_questions  # noqa: E402
from exam_sources import discover  # noqa: E402
from pipeline_paths import answer_key_ocr_dir, exam_ocr_dir, source_pdf_dir  # noqa: E402

DRAFT_MARK = "UNREVIEWED OCR DRAFT"


def draft(exam) -> tuple[dict, list[int]]:
    """(transcript, question numbers the OCR did not yield)."""
    count = exam.question_count()
    questions = read_questions(exam.ocr_path(), count)
    answers, refs = read_key(exam.key_ocr_path(), count)
    rows, gaps = [], []
    for number in range(1, count + 1):
        if number not in questions or number not in answers:
            gaps.append(number)
            continue
        rows.append({"number": number, "prompt": questions[number]["prompt"],
                     "answers": questions[number]["choices"], "correct_index": answers[number],
                     "reference": refs.get(number, "")})
    transcript = {
        "question_count": count,
        "provenance": f"{DRAFT_MARK} from {exam.stem}.pdf and its key (tools/pipeline/draft_transcript.py); "
                      "review every question against the PDF page images, then replace this line.",
        "questions": rows,
    }
    return transcript, gaps


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--ocr", action="store_true", help="OCR the PDFs whose text is missing first (needs Tesseract)")
    args = ap.parse_args(argv)
    pending = [e for e in discover() if e.transcript() is None]
    if not pending:
        print("every exam has a transcript")
        return 0
    if args.ocr:
        from ocr_pdfs_tesseract import ocr_pdf
        for exam in pending:
            exam_ocr_dir().mkdir(parents=True, exist_ok=True)
            answer_key_ocr_dir().mkdir(parents=True, exist_ok=True)
            ocr_pdf(source_pdf_dir() / f"{exam.stem}.pdf", exam_ocr_dir())
            ocr_pdf(source_pdf_dir() / f"{exam.key_stem}.pdf", answer_key_ocr_dir())
    for exam in pending:
        if not exam.ocr_path().exists() or not exam.key_ocr_path().exists():
            print(f"{exam.stem}: no OCR text in {exam_ocr_dir()} / {answer_key_ocr_dir()}; run with --ocr")
            continue
        transcript, gaps = draft(exam)
        exam.transcript_path.write_text(json.dumps(transcript, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
        print(f"{exam.transcript_path.name}: {len(transcript['questions'])} of {transcript['question_count']} drafted"
              + (f"; type these from the PDF: {gaps}" if gaps else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
