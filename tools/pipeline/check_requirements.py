#!/usr/bin/env python3
"""Check the bank against data/question_requirements.json.

Every record is classified there as table, calc, formula, table+calc or recall.
This gate fails when:

* a record is missing from the classification, or the file names a record the
  bank does not have;
* a table record shows no table (a reference_table, or a tab-separated table in
  its reference_text);
* a calc or formula record has no formula hint, or no "check" to recompute it;
* a record marked pre_answer_table has no pre-answer table, or a record marked
  otherwise shows its reference_table before answering;
* a check does not give the keyed answer, or the last number of the worked
  solution disagrees with it.

Usage:
    python tools/pipeline/check_requirements.py [bank.json]
Exit 0 = pass.
"""
from __future__ import annotations

import json
import math
import re
import sys
from fractions import Fraction
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import nec_calc  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
REQUIREMENTS = ROOT / "data" / "question_requirements.json"
CLASSES = {"table", "calc", "formula", "table+calc", "recall"}
TABLE_CLASSES = {"table", "table+calc"}
HINT_CLASSES = {"calc", "formula", "table+calc"}
WORD_NUMBERS = {"one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6}
LAST_NUMBER = re.compile(r"(\d+)\s*/\s*(\d+)|\d[\d,]*(?:\.\d+)?")


def as_number(value):
    """Number in an answer, a worked result or a computed value; None if there is none."""
    if isinstance(value, (int, float, Fraction)):
        return value
    text = str(value).strip().replace(",", "")
    if text.lower() in WORD_NUMBERS:
        return WORD_NUMBERS[text.lower()]
    m = re.fullmatch(r"(\d+)\s*/\s*(\d+)", text)
    if m:
        return Fraction(int(m.group(1)), int(m.group(2)))
    m = re.search(r"\d+(?:\.\d+)?", text)
    return float(m.group(0)) if m else None


def same_value(a, b) -> bool:
    x, y = as_number(a), as_number(b)
    if x is None or y is None:
        return str(a).strip().casefold() == str(b).strip().casefold()
    if isinstance(x, Fraction) != isinstance(y, Fraction) and not (
            isinstance(x, Fraction) and x.denominator == 1 or isinstance(y, Fraction) and y.denominator == 1):
        return False
    return math.isclose(float(x), float(y), rel_tol=0, abs_tol=0.005)


def worked_result(worked: str):
    """The last number (or fraction) in a worked solution: its stated result."""
    hits = list(LAST_NUMBER.finditer(worked))
    if not hits:
        return None
    m = hits[-1]
    if m.group(1):
        return Fraction(int(m.group(1)), int(m.group(2)))
    return float(m.group(0).replace(",", ""))


def has_tab_table(reference_text: str) -> bool:
    return any("\t" in line for line in reference_text.split("\n")[1:])


def check(bank: dict, requirements: dict) -> list[str]:
    problems: list[str] = []
    reqs = requirements.get("records", {})
    records = bank["records"]
    ids = {r["id"] for r in records}
    for rid in sorted(set(reqs) - ids):
        problems.append(f"{rid}: classified but not in the bank")
    for rec in records:
        rid = rec["id"]
        req = reqs.get(rid)
        if req is None:
            problems.append(f"{rid}: not classified in question_requirements.json")
            continue
        cls = req.get("class")
        if cls not in CLASSES:
            problems.append(f"{rid}: unknown class {cls!r}")
            continue
        if cls == "recall":
            continue
        table = rec.get("reference_table") or []
        after = bool(rec.get("table_after_answer"))
        if cls in TABLE_CLASSES and not table and not has_tab_table(rec.get("reference_text", "")):
            problems.append(f"{rid}: class {cls} but no table (reference_table or a tabbed provision)")
        if cls in HINT_CLASSES and not str(rec.get("formula", "")).strip():
            problems.append(f"{rid}: class {cls} but no formula hint")
        if not req.get("tables") and not req.get("steps"):
            problems.append(f"{rid}: class {cls} lists no tables or steps")
        pre = req.get("pre_answer_table")
        if pre is True and (not table or after):
            problems.append(f"{rid}: needs a pre-answer lookup table")
        if pre is False and table and not after:
            problems.append(f"{rid}: shows its table before answering, but the table gives the answer away")
        spec = req.get("check")
        if cls in HINT_CLASSES and not spec:
            problems.append(f"{rid}: class {cls} has no check to recompute it")
        if not spec:
            continue
        keyed = rec["answers"][rec["correct_index"]]
        try:
            computed = nec_calc.evaluate(spec)
        except (KeyError, ValueError) as err:
            problems.append(f"{rid}: check {spec} failed: {err!r}")
            continue
        if not same_value(computed, keyed):
            problems.append(f"{rid}: check {spec['kind']} gives {computed!r}, keyed answer is {keyed!r}")
        worked = str(rec.get("worked", "")).strip()
        if worked:
            stated = worked_result(worked)
            if stated is None or not same_value(computed, stated):
                problems.append(f"{rid}: worked solution ends at {stated!r}, the check gives {computed!r}")
    return problems


def main() -> int:
    bank_path = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "data" / "question_bank.json"
    bank = json.loads(bank_path.read_text(encoding="utf-8"))
    requirements = json.loads(REQUIREMENTS.read_text(encoding="utf-8"))
    problems = check(bank, requirements)
    counts: dict[str, int] = {}
    for req in requirements["records"].values():
        counts[req["class"]] = counts.get(req["class"], 0) + 1
    checked = sum(1 for req in requirements["records"].values() if req.get("check"))
    print("classes: " + ", ".join(f"{k} {v}" for k, v in sorted(counts.items())) + f"  recomputed: {checked}")
    for p in problems:
        print("  PROBLEM", p)
    print("RESULT:", "PASS" if not problems else f"FAIL ({len(problems)})")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
