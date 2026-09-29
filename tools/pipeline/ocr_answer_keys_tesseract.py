from exam_sources import discover
from ocr_pdfs_tesseract import ocr_pdf
from pipeline_paths import answer_key_ocr_dir, source_pdf_dir

OUT = answer_key_ocr_dir()

if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for exam in discover():
        ocr_pdf(source_pdf_dir() / f"{exam.key_stem}.pdf", OUT)
