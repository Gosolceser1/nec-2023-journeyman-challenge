"""Shared locations for the exam PDFs, exam OCR, answer-key OCR, and bank builder.

The NEC edition comes from data/edition.json (the one place the year is
written); edition-specific data lives under data/<edition dir>/.
"""
from __future__ import annotations

import json
import os
import shutil
import tempfile
from functools import lru_cache
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_PIPELINE_DIR = Path(tempfile.gettempdir()) / "wire_pipeline"
EDITION_PATH = ROOT / "data" / "edition.json"


def source_pdf_dir() -> Path:
    return ROOT / "exams_source_pdf"


def exam_ocr_dir() -> Path:
    return Path(os.environ.get("WIRE_OCR_PATH", str(DEFAULT_PIPELINE_DIR / "wire_ocr")))


def answer_key_ocr_dir() -> Path:
    return Path(os.environ.get("WIRE_OCR_KEYS", str(DEFAULT_PIPELINE_DIR / "wire_ocr_keys")))


def tesseract_exe() -> Path:
    """Tesseract for the OCR stage: WIRE_TESSERACT, else `tesseract` on PATH, else the Windows installer's folder."""
    candidates = [os.environ.get("WIRE_TESSERACT"), shutil.which("tesseract")]
    if os.environ.get("ProgramFiles"):
        candidates.append(str(Path(os.environ["ProgramFiles"]) / "Tesseract-OCR" / "tesseract.exe"))
    for candidate in candidates:
        if candidate and Path(candidate).is_file():
            return Path(candidate)
    raise FileNotFoundError(
        "Tesseract not found. Install it (https://github.com/tesseract-ocr/tesseract), put it on PATH "
        "or set WIRE_TESSERACT to tesseract(.exe). Exams with a transcript in "
        "tools/pipeline/sources/exams/ need no OCR.")


@lru_cache(maxsize=None)
def edition(path: Path = EDITION_PATH) -> dict:
    """data/edition.json: year, short ("NEC 2023"), long, dir ("nec/2023")."""
    return json.loads(path.read_text(encoding="utf-8"))


def nec_data(name: str, edition_info: dict | None = None) -> Path:
    """Path of an edition data file: nec_data("articles.json") -> data/nec/2023/articles.json."""
    return ROOT / "data" / (edition_info or edition())["dir"] / name
