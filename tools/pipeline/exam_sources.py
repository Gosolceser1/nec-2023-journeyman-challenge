"""The practice exams, discovered from the PDFs in exams_source_pdf/.

Adding an exam means adding its two PDFs (the exam and its answer key); nothing
here lists exams by name. Each exam PDF must be named
``Journeyman open book exam #N.pdf`` or ``Journeyman open book final exam #N.pdf``
with an answer key ``<same name> answer key.pdf`` (any letter case).

* label: ``Open Book Exam #N`` / ``Final Exam #N``; record ids are the label
  lower-cased with spaces as dashes plus the number (``final-exam-#2-007``).
* question count: from the reviewed transcript when there is one, else from the
  cover page of the OCR text ("25 QUESTIONS").
* transcript: ``sources/exams/<pdf stem>.json``, the exam and its key as
  reviewed text (see docs/ADDING_EXAMS.md): ``question_count``, ``questions``
  (number, prompt, answers, correct_index, reference) and optional ``key_only``
  entries (number, correct_index) for key lines whose question page is missing.
  When present it replaces the OCR parse for that exam, so the build does not
  depend on Tesseract output. Every shipped exam has one.
"""
from __future__ import annotations

import json
import re
from dataclasses import dataclass
from pathlib import Path

from pipeline_paths import answer_key_ocr_dir, exam_ocr_dir, source_pdf_dir

TRANSCRIPT_DIR = Path(__file__).resolve().parent / "sources" / "exams"
EXAM_NAME = re.compile(r"^Journeyman open book (?P<final>final )?exam #(?P<number>\d+)$", re.I)
KEY_SUFFIX = " answer key"
COVER_COUNT = re.compile(r"(\d+)\s*QUESTIONS\b", re.I)


@dataclass(frozen=True)
class ExamSource:
    stem: str            # PDF file name without ".pdf"
    label: str           # "Final Exam #2"
    final: bool
    number: int
    key_stem: str        # answer-key PDF name without ".pdf"

    @property
    def transcript_path(self) -> Path:
        return TRANSCRIPT_DIR / f"{self.stem}.json"

    def transcript(self) -> dict | None:
        path = self.transcript_path
        return json.loads(path.read_text(encoding="utf-8")) if path.exists() else None

    def ocr_path(self, ocr_dir: Path | None = None) -> Path:
        return (ocr_dir or exam_ocr_dir()) / f"{self.stem}.txt"

    def key_ocr_path(self, keys_dir: Path | None = None) -> Path:
        return (keys_dir or answer_key_ocr_dir()) / f"{self.key_stem}.txt"

    def question_count(self, ocr_dir: Path | None = None) -> int:
        transcript = self.transcript()
        if transcript is not None:
            return int(transcript["question_count"])
        text = self.ocr_path(ocr_dir).read_text(encoding="utf-8", errors="replace")
        match = COVER_COUNT.search(text)
        if not match:
            raise ValueError(f"{self.stem}: no 'NN QUESTIONS' on the OCR cover page and no transcript")
        return int(match.group(1))


def label_for(stem: str) -> tuple[str, bool, int]:
    match = EXAM_NAME.match(stem)
    if not match:
        raise ValueError(f"exam PDF name {stem!r} does not match {EXAM_NAME.pattern}")
    final = bool(match.group("final"))
    number = int(match.group("number"))
    return ("Final Exam #%d" if final else "Open Book Exam #%d") % number, final, number


def discover(pdf_dir: Path | None = None) -> list[ExamSource]:
    """Every exam with its answer key, finals first, then open book, by number."""
    folder = pdf_dir or source_pdf_dir()
    pdfs = {p.stem: p for p in folder.glob("*.pdf")}
    keys = {stem.lower(): stem for stem in pdfs if stem.lower().endswith(KEY_SUFFIX)}
    exams = []
    for stem in pdfs:
        if stem.lower().endswith(KEY_SUFFIX):
            continue
        label, final, number = label_for(stem)
        key_stem = keys.get((stem + KEY_SUFFIX).lower())
        if key_stem is None:
            raise ValueError(f"{stem}.pdf has no answer key PDF ('{stem}{KEY_SUFFIX}.pdf')")
        exams.append(ExamSource(stem, label, final, number, key_stem))
    orphans = set(keys.values()) - {e.key_stem for e in exams}
    if orphans:
        raise ValueError(f"answer keys without an exam PDF: {sorted(orphans)}")
    return sorted(exams, key=lambda e: (not e.final, e.number))


def record_id(label: str, number: int) -> str:
    return "%s-%03d" % (label.lower().replace(" ", "-"), number)
