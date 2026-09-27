"""Find every picture on every page of the source PDFs.

    python tools/pipeline/scan_pdf_figures.py   # writes .audit_tmp/figscan/*.png + candidates.json

The PDFs are scans: each page is one full-page raster, with no text layer and
no vector drawings, so page.get_images()/get_drawings() cannot isolate figures.
Instead each page is rendered and split into horizontal ink bands; text lines
are short, uniform bands, so a band much taller than the page's typical line,
or one whose ink is mostly thin strokes spread across a wide area, is a
figure candidate. Every candidate is saved with context above it (to read the
question number) for manual review; tools/pipeline/extract_diagrams.py holds the final,
hand-checked crop per question.
"""
import json
from pathlib import Path

import numpy as np
import pymupdf
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
PDF_DIR = ROOT / "exams_source_pdf"
OUT = ROOT / ".audit_tmp" / "figscan"
DPI = 100
INK = 160
TALL_FACTOR = 2.0


def bands(mask, max_gap=2):
    rows = mask.any(1)
    out, start, gap = [], None, 0
    for y, on in enumerate(rows):
        if on:
            if start is None:
                start = y
            gap = 0
        elif start is not None:
            gap += 1
            if gap > max_gap:
                out.append((start, y - gap + 1))
                start, gap = None, 0
    if start is not None:
        out.append((start, len(rows)))
    return out


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    found = []
    for pdf in sorted(PDF_DIR.glob("*.pdf")):
        doc = pymupdf.open(pdf)
        for pno, page in enumerate(doc, start=1):
            pix = page.get_pixmap(dpi=DPI, colorspace=pymupdf.csGRAY)
            img = np.frombuffer(pix.samples, np.uint8).reshape(pix.height, pix.width)
            h, w = img.shape
            mask = img < INK
            # Scanner edge shadows and page-edge specks are not content.
            mx, my = int(w * 0.04), int(h * 0.03)
            mask[:, :mx] = False
            mask[:, w - mx:] = False
            mask[:my, :] = False
            mask[h - my:, :] = False
            bs = [b for b in bands(mask) if b[1] - b[0] >= 3]
            if not bs:
                continue
            heights = sorted(b[1] - b[0] for b in bs)
            line_h = heights[len(heights) // 2]
            for (y0, y1) in bs:
                bh = y1 - y0
                cols = np.where(mask[y0:y1].any(0))[0]
                x0, x1 = int(cols.min()), int(cols.max()) + 1
                if bh < line_h * TALL_FACTOR:
                    continue
                entry = {
                    "pdf": pdf.name, "page": pno,
                    "bbox_frac": [round(x0 / w, 4), round(y0 / h, 4), round(x1 / w, 4), round(y1 / h, 4)],
                    "height_lines": round(bh / line_h, 1),
                    "ink_density": round(float(mask[y0:y1, x0:x1].mean()), 3),
                }
                name = f"{pdf.stem.replace(' ', '_').replace('#', '')}_p{pno:02d}_y{y0:04d}.png"
                ctx0 = max(0, y0 - int(line_h * 4))
                Image.fromarray(img[ctx0:min(h, y1 + 6), :]).save(OUT / name)
                entry["preview"] = name
                found.append(entry)
    (OUT / "candidates.json").write_text(json.dumps(found, indent=1), encoding="utf-8")
    for e in found:
        print(f"{e['pdf']:48s} p{e['page']:<3d} lines={e['height_lines']:<5} dens={e['ink_density']:<6} {e['bbox_frac']}  {e['preview']}")
    print(len(found), "candidates")


if __name__ == "__main__":
    main()
