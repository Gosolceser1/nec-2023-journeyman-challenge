import subprocess
from pathlib import Path

import fitz

from exam_sources import discover
from pipeline_paths import exam_ocr_dir, source_pdf_dir, tesseract_exe

OUT = exam_ocr_dir()


def ocr_pdf(pdf_path: Path, out_dir: Path) -> None:
    output_path = out_dir / f"{pdf_path.stem}.txt"
    if output_path.exists():
        return
    tesseract = tesseract_exe()
    document = fitz.open(pdf_path)
    chunks = []
    for page_number, page in enumerate(document, 1):
        pixmap = page.get_pixmap(matrix=fitz.Matrix(2.0, 2.0), alpha=False)
        image_path = out_dir / f"{pdf_path.stem}__page_{page_number:03d}.png"
        pixmap.save(image_path)
        result = subprocess.run(
            [str(tesseract), str(image_path), "stdout", "--psm", "6"],
            capture_output=True,
            text=True,
            check=True,
        )
        chunks.append(f"=== PAGE {page_number} ===\n{result.stdout}")
        image_path.unlink(missing_ok=True)
    output_path.write_text("\n".join(chunks), encoding="utf-8")
    print(f"OCR complete: {pdf_path.name} -> {output_path}")


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    # An exam with a reviewed transcript needs no OCR.
    for exam in discover():
        if exam.transcript() is None:
            ocr_pdf(source_pdf_dir() / f"{exam.stem}.pdf", OUT)
