import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
KEYS = Path(r"C:\Users\vadim\AppData\Local\Temp\opencode\wire_tesseract_keys")

STEMS = {
    "Journeyman open book final exam #1 answer key": "Final Exam #1",
    "Journeyman open book final exam #3 answer key": "Final Exam #3",
    "Journeyman open book final exam #5 answer key": "Final Exam #5",
    "Journeyman open book exam #1 Answer key": "Open Book Exam #1",
    "Journeyman open book exam #4 Answer key": "Open Book Exam #4",
    "Journeyman open book exam #7 Answer key": "Open Book Exam #7",
    "Journeyman open book exam #10 Answer key": "Open Book Exam #10",
}

bank = json.loads((ROOT / "question_bank.json").read_text(encoding="utf-8"))
recs = {(r["exam"], r["question_number"]): r for r in bank["records"]}

total = 0
mismatches = []
unparsed = []
for stem, source in STEMS.items():
    text = (KEYS / f"{stem}.txt").read_text(encoding="utf-8", errors="replace")
    answers = {}
    for m in re.finditer(
        r"(?m)^\s*[_|:;]*\s*(\d{1,2})[\.,]?\s*\(([a-d])\)",
        text,
        re.I,
    ):
        n = int(m.group(1))
        if n not in answers:
            answers[n] = ord(m.group(2).lower()) - ord("a")
    count = 70 if "Final" in source else 25
    for number in range(1, count + 1):
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
