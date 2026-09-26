"""Follow-up to fix_literal_language.py: keyed replacement for the 14 duplicate-text
gists it had to skip, plus corrected texts for 8 gist/answer leak flags."""

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from fix_literal_language import GIST_V2, _contains_answer

ROOT = Path(__file__).resolve().parents[1]
BANK = ROOT / "question_bank.json"
GISTS_PY = ROOT / "tools" / "gists.py"

CORRECTED = {
    ("Open Book Exam #1", 1): "Opening only part of the circuit leaves the neutral energized from the other side. The question asks which wires the disconnect must open together.",
    ("Open Book Exam #1", 9): "Each grounded conductor requires its own terminal, with no doubling under one screw. The question asks how the Code says each one must land.",
    ("Open Book Exam #4", 8): "In a multiwire circuit, all conductors must originate from the same equipment. The question asks what that equipment must contain.",
    ("Open Book Exam #7", 4): "X-ray equipment operates in brief high-current pulses, so conductors follow the pulse-based rating rather than the continuous one. The question asks which demand rating that is.",
    ("Open Book Exam #7", 5): "Floodplain measurements reference how high water can rise before spilling over. The question asks the name of that level.",
    ("Open Book Exam #7", 12): "Thin paint-type coatings do not qualify as outdoor corrosion protection. The question asks which coating is indoor-only.",
    ("Open Book Exam #7", 24): "One 4-wire system includes a high leg with elevated voltage to ground, requiring identification. The question asks what that system is called.",
    ("Open Book Exam #10", 4): "Conductors leaving an industrial panel fall into two classifications, each with its own rules. The question asks which one these supply wires count as.",
}

PAIRS14 = [
    ("Final Exam #1", 34), ("Final Exam #1", 36), ("Final Exam #1", 37),
    ("Final Exam #1", 39), ("Final Exam #1", 40), ("Final Exam #1", 44),
    ("Final Exam #1", 61), ("Open Book Exam #4", 9), ("Open Book Exam #4", 15),
    ("Open Book Exam #4", 16), ("Open Book Exam #4", 20), ("Open Book Exam #4", 22),
    ("Open Book Exam #4", 25), ("Open Book Exam #10", 17),
]


def main():
    lines = GISTS_PY.read_text(encoding="utf-8").split("\n")

    def set_keyed(key, newtext):
        pref = '    ("%s", %d): ' % (key[0], key[1])
        idx = [i for i, line in enumerate(lines) if line.startswith(pref)]
        assert len(idx) == 1, (key, len(idx))
        lines[idx[0]] = pref + json.dumps(newtext, ensure_ascii=False) + ","

    for key in PAIRS14:
        set_keyed(key, GIST_V2[key])
    for key, txt in CORRECTED.items():
        set_keyed(key, txt)
    GISTS_PY.write_text("\n".join(lines), encoding="utf-8")

    data = json.loads(BANK.read_text(encoding="utf-8"))
    recs = {(r["exam"], r["question_number"]): r for r in data.get("records", [])}
    for key in PAIRS14:
        recs[key]["gist"] = GIST_V2[key]
    for key, txt in CORRECTED.items():
        recs[key]["gist"] = txt
    BANK.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")

    leaks = []
    for r in data.get("records", []):
        g = str(r.get("gist", ""))
        a = str(r["answers"][int(r["correct_index"])])
        if g and _contains_answer(g, a):
            leaks.append(r.get("id"))
    print("keyed gists fixed:", len(PAIRS14) + len(CORRECTED),
          "| remaining leaks:", len(leaks), leaks)


if __name__ == "__main__":
    main()
