"""Crop question figures out of the source PDFs.

    python tools/extract_diagrams.py            # writes diagrams/*.png + diagrams/diagrams.json
    python tools/extract_diagrams.py --preview  # also writes .audit_tmp/diagram_crops/*_page.png with boxes drawn

Every figure is a region of a scanned page, so it is rendered at DPI and cropped,
never redrawn. Boxes are fractions of the page (x0, y0, x1, y1) so they do not
depend on DPI. "mask" boxes are whited out before trimming: they remove question
or choice text that shares the figure's bounding rectangle. "highlight" boxes
(page fractions) mark the part the answer key points at; the app outlines them
only after the question is answered.
"""
import json
import sys
from pathlib import Path

import numpy as np
import pymupdf
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
PDF_DIR = ROOT / "exams_source_pdf"
OUT_DIR = ROOT / "diagrams"
DPI = 300
PAD_PX = 14
INK_THRESHOLD = 200

FINAL_1 = "Journeyman open book final exam #1.pdf"

# page is 1-based, as printed by a PDF viewer.
FIGURES = {
    "final-exam-#1-005": {
        "pdf": FINAL_1, "page": 3,
        "crop": (0.550, 0.5440, 0.905, 0.760),
        "mask": [(0.0, 0.0, 0.5875, 0.6620)],
        "highlight": (0.669, 0.680, 0.790, 0.743),
    },
    "final-exam-#1-013": {
        "pdf": FINAL_1, "page": 4,
        "crop": (0.310, 0.6060, 0.735, 0.664),
        "mask": [],
        "highlight": (0.449, 0.619, 0.502, 0.646),
    },
    "final-exam-#1-047": {
        "pdf": FINAL_1, "page": 8,
        "crop": (0.140, 0.775, 0.590, 0.862),
        "mask": [],
        "highlight": (0.171, 0.789, 0.235, 0.860),
    },
}


def safe_name(qid: str) -> str:
    return qid.replace("#", "")


def render(spec):
    doc = pymupdf.open(PDF_DIR / spec["pdf"])
    page = doc[spec["page"] - 1]
    pix = page.get_pixmap(dpi=DPI, colorspace=pymupdf.csGRAY)
    img = Image.frombytes("L", (pix.width, pix.height), pix.samples)
    return img


def frac_box(box, w, h):
    return (int(box[0] * w), int(box[1] * h), int(box[2] * w), int(box[3] * h))


def extract(qid, spec, preview_dir=None):
    page = render(spec)
    w, h = page.size
    work = page.copy()
    draw = ImageDraw.Draw(work)
    for m in spec.get("mask", []):
        draw.rectangle(frac_box(m, w, h), fill=255)
    cx0, cy0, cx1, cy1 = frac_box(spec["crop"], w, h)
    region = np.asarray(work.crop((cx0, cy0, cx1, cy1)))
    ink = np.argwhere(region < INK_THRESHOLD)
    if ink.size == 0:
        raise SystemExit(f"{qid}: crop box holds no ink")
    (y0, x0), (y1, x1) = ink.min(0).tolist(), ink.max(0).tolist()
    x0 = max(0, cx0 + x0 - PAD_PX)
    y0 = max(0, cy0 + y0 - PAD_PX)
    x1 = min(w, cx0 + x1 + PAD_PX + 1)
    y1 = min(h, cy0 + y1 + PAD_PX + 1)
    fig = work.crop((x0, y0, x1, y1))
    out = OUT_DIR / f"{safe_name(qid)}.png"
    fig.save(out, optimize=True)

    entry = {
        "file": f"res://diagrams/{out.name}",
        "pdf": spec["pdf"],
        "page": spec["page"],
        "crop_px_at_dpi": [x0, y0, x1, y1],
        "dpi": DPI,
        "size": [fig.width, fig.height],
    }
    if spec.get("highlight"):
        hx0, hy0, hx1, hy1 = frac_box(spec["highlight"], w, h)
        fw, fh = fig.size
        entry["highlight"] = [
            round((hx0 - x0) / fw, 4), round((hy0 - y0) / fh, 4),
            round((hx1 - hx0) / fw, 4), round((hy1 - hy0) / fh, 4),
        ]
    if preview_dir:
        prev = page.convert("RGB")
        d = ImageDraw.Draw(prev)
        d.rectangle((x0, y0, x1, y1), outline=(0, 160, 255), width=6)
        for m in spec.get("mask", []):
            d.rectangle(frac_box(m, w, h), outline=(255, 0, 0), width=4)
        if spec.get("highlight"):
            d.rectangle(frac_box(spec["highlight"], w, h), outline=(0, 200, 80), width=4)
        prev.save(preview_dir / f"{safe_name(qid)}_page.png")
    return entry


def main():
    OUT_DIR.mkdir(exist_ok=True)
    preview_dir = None
    if "--preview" in sys.argv:
        preview_dir = ROOT / ".audit_tmp" / "diagram_crops"
        preview_dir.mkdir(parents=True, exist_ok=True)
    mapping = {}
    for qid, spec in FIGURES.items():
        mapping[qid] = extract(qid, spec, preview_dir)
        print(f"{qid}: page {spec['page']} -> {mapping[qid]['file']} {mapping[qid]['size']}")
    (OUT_DIR / "diagrams.json").write_text(json.dumps(mapping, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
