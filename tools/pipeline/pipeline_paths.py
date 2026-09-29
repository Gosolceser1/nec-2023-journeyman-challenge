"""Shared locations for the exam PDFs, exam OCR, answer-key OCR, and bank builder."""
from __future__ import annotations

import os
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_PIPELINE_DIR = Path(tempfile.gettempdir()) / "opencode"


def source_pdf_dir() -> Path:
    return ROOT / "exams_source_pdf"


def exam_ocr_dir() -> Path:
    return Path(os.environ.get("WIRE_OCR_PATH", str(DEFAULT_PIPELINE_DIR / "wire_ocr")))


def answer_key_ocr_dir() -> Path:
    return Path(os.environ.get("WIRE_OCR_KEYS", str(DEFAULT_PIPELINE_DIR / "wire_ocr_keys")))
