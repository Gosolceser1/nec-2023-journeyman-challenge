"""Shared locations for the exam PDFs, exam OCR, answer-key OCR, and bank builder.

The NEC edition comes from data/edition.json (the one place the year is
written); edition-specific data lives under data/<edition dir>/.
"""
from __future__ import annotations

import json
import os
import tempfile
from functools import lru_cache
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_PIPELINE_DIR = Path(tempfile.gettempdir()) / "opencode"
EDITION_PATH = ROOT / "data" / "edition.json"


def source_pdf_dir() -> Path:
    return ROOT / "exams_source_pdf"


def exam_ocr_dir() -> Path:
    return Path(os.environ.get("WIRE_OCR_PATH", str(DEFAULT_PIPELINE_DIR / "wire_ocr")))


def answer_key_ocr_dir() -> Path:
    return Path(os.environ.get("WIRE_OCR_KEYS", str(DEFAULT_PIPELINE_DIR / "wire_ocr_keys")))


@lru_cache(maxsize=None)
def edition(path: Path = EDITION_PATH) -> dict:
    """data/edition.json: year, short ("NEC 2023"), long, dir ("nec/2023")."""
    return json.loads(path.read_text(encoding="utf-8"))


def nec_data(name: str, edition_info: dict | None = None) -> Path:
    """Path of an edition data file: nec_data("articles.json") -> data/nec/2023/articles.json."""
    return ROOT / "data" / (edition_info or edition())["dir"] / name
