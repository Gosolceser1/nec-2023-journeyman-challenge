import json
import re
from pathlib import Path

from exam_sources import discover

ROOT = Path(__file__).resolve().parents[2]

bank = json.loads((ROOT / "data" / "question_bank.json").read_text(encoding="utf-8"))
recs = {(r["exam"], r["question_number"]): r for r in bank["records"]}

total = 0
mismatches = []
unparsed = []
for exam in discover():
    source = exam.label
    text = exam.key_ocr_path().read_text(encoding="utf-8", errors="replace")
    answers = {}
    for m in re.finditer(
        r"(?m)^\s*[_|:;]*\s*(\d{1,2})[\.,]?\s*\(([a-d])\)",
        text,
        re.I,
    ):
        n = int(m.group(1))
        if n not in answers:
            answers[n] = ord(m.group(2).lower()) - ord("a")
    for number in range(1, exam.question_count() + 1):
        rec = recs.get((source, number))
        if number not in answers:
            unparsed.append(f"{source} Q{number}: key not parsed")
            continue
        if rec is None:
            unparsed.append(
                f"{source} Q{number}: key={answers[number]} but no bank record"
            )
            continue
        total += 1
        if rec["correct_index"] != answers[number]:
            mismatches.append(
                f"{source} Q{number}: bank={rec['correct_index']} "
                f"({rec['answers'][rec['correct_index']]}) "
                f"key={answers[number]}"
            )

print(f"compared={total} mismatches={len(mismatches)} unparsed={len(unparsed)}")
for line in mismatches:
    print("MISMATCH " + line)
for line in unparsed:
    print("UNPARSED " + line)
