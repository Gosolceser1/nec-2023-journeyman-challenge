"""The practice exams, discovered from the PDFs in exams_source_pdf/.

Adding an exam means adding its two PDFs (the exam and its answer key); nothing
here lists exams by name. Each exam PDF name must match a family in
``sources/exams/families.json`` (today ``Journeyman open book exam #N.pdf`` and
``Journeyman open book final exam #N.pdf``), with an answer key
``<same name> answer key.pdf`` (any letter case).

* label and id prefix: from the family (``Final Exam #2``, ``final-exam-#2``);
  record ids are the frozen prefix plus the question number (``final-exam-#2-007``).
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
FAMILIES_PATH = TRANSCRIPT_DIR / "families.json"
KEY_SUFFIX = " answer key"
COVER_COUNT = re.compile(r"(\d+)\s*QUESTIONS\b", re.I)


@dataclass(frozen=True)
class ExamSource:
    stem: str            # PDF file name without ".pdf"
    label: str           # "Final Exam #2"
    final: bool
    number: int
    key_stem: str        # answer-key PDF name without ".pdf"
    id_prefix: str = ""  # "final-exam-#2" (frozen, see families.json)
    family: int = 0      # position in families.json, the bank's exam order

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


def families(path: Path = FAMILIES_PATH) -> list[dict]:
    return json.loads(path.read_text(encoding="utf-8"))["families"]


def match_family(stem: str, path: Path = FAMILIES_PATH) -> dict:
    """label, final, number, id_prefix and family index for an exam PDF name."""
    for index, family in enumerate(families(path)):
        match = re.match(family["pattern"], stem, re.I)
        if match:
            number = int(match.group("number"))
            return {"label": family["label"].format(number=number), "final": bool(family["final"]),
                    "number": number, "id_prefix": family["id_prefix"].format(number=number),
                    "family": index}
    raise ValueError(f"exam PDF name {stem!r} matches no pattern in {path}; "
                     "rename the PDF or add a family there (docs/ADDING_EXAMS.md)")


def label_for(stem: str) -> tuple[str, bool, int]:
    info = match_family(stem)
    return info["label"], info["final"], info["number"]


def discover(pdf_dir: Path | None = None) -> list[ExamSource]:
    """Every exam with its answer key, in families.json order, then by number."""
    folder = pdf_dir or source_pdf_dir()
    pdfs = {p.stem: p for p in folder.glob("*.pdf")}
    keys = {stem.lower(): stem for stem in pdfs if stem.lower().endswith(KEY_SUFFIX)}
    exams = []
    for stem in pdfs:
        if stem.lower().endswith(KEY_SUFFIX):
            continue
        info = match_family(stem)
        key_stem = keys.get((stem + KEY_SUFFIX).lower())
        if key_stem is None:
            raise ValueError(f"{stem}.pdf has no answer key PDF ('{stem}{KEY_SUFFIX}.pdf')")
        exams.append(ExamSource(stem, info["label"], info["final"], info["number"], key_stem,
                                info["id_prefix"], info["family"]))
    orphans = set(keys.values()) - {e.key_stem for e in exams}
    if orphans:
        raise ValueError(f"answer keys without an exam PDF: {sorted(orphans)}")
    return sorted(exams, key=lambda e: (e.family, e.number))


def record_id(id_prefix: str, number: int) -> str:
    return "%s-%03d" % (id_prefix, number)
