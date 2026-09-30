#!/usr/bin/env python3
"""Check that every worked solution in the question bank is recomputed and adds up.

Two passes:

1. COVERAGE -- a record that carries a formula or worked solution must have a
   declarative `check` in data/question_requirements.json (recomputed by
   check_requirements.py from the edition's tables.json) or be a table lookup
   there, so new calculation records cannot slip in unchecked.
2. ARITHMETIC SCAN -- every "a <op> b [<op> c ...] = d" chain found in the
   learner-facing text of all records (formula, worked, reference_text,
   tip_short, choice_notes, info_tip) is re-evaluated and flagged when the
   stated result does not match to the precision it is written with.

Usage:
    python tools/pipeline/check_worked_solutions.py [bank.json]
Exit 0 = no mismatches.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
REQUIREMENTS = ROOT / "data" / "question_requirements.json"

# formula/worked present but nothing numeric to recompute
NON_NUMERIC = {
    "final-exam-#3-069": "430.62(A) rule statement",
    "open-book-exam-#7-004": "517.73(A)(2) rule statement (momentary rating)",
}


NUM = r"\d[\d,]*(?:\.\d+)?"
OP = r"(?:×|\*|÷|/|\+|−|-|\bx\b|\btimes\b|\bdivided by\b)"
TERM = rf"\(*\s*{NUM}\s*%?\s*\)*"
# The right side is only looked at, so in "a × b = c + d = e" the second chain starts at c.
RHS = rf"({NUM})(%?)((?:\s*{OP}\s*{NUM}%?)*)"
CHAIN = re.compile(rf"(?<![\w.])({TERM}(?:\s*{OP}\s*{TERM})+)\s*=\s*(?={RHS}(?!\s*/))")
OPS = {"×": "*", "*": "*", "x": "*", "times": "*", "÷": "/", "/": "/", "divided by": "/",
       "+": "+", "−": "-", "-": "-", "(": "(", ")": ")"}
TEXT_FIELDS = ["formula", "worked", "reference_text", "tip_short", "info_tip", "choice_notes"]
SCANNED: list[str] = []


def eval_chain(expr: str):
    if expr.count("(") != expr.count(")"):
        expr = expr.replace("(", " ").replace(")", " ")
    tokens = re.findall(rf"{NUM}%?|{OP}|[()]", expr)
    py = []
    for tok in tokens:
        tok = tok.strip()
        if re.fullmatch(rf"{NUM}%?", tok):
            val = float(tok.rstrip("%").replace(",", ""))
            py.append(repr(val / 100 if tok.endswith("%") else val))
        else:
            py.append(OPS[tok])
    return eval(" ".join(py), {"__builtins__": {}})  # noqa: S307 - digits/operators only


def decimals(num_text: str) -> int:
    return len(num_text.split(".")[1]) if "." in num_text else 0


UNIT = re.compile(r"([\d)])\s*(?:sq\.? ?in\.?|in2|kVA|kW|VA|V|A|W|ohms|amperes|amps|ft|in\.?)(?![\w/])")


def scan_text(rid: str, field: str, text: str, problems: list):
    text = UNIT.sub(r"\1", text)
    text = re.sub(r"[ \t]+", " ", text)
    for m in CHAIN.finditer(text):
        expr, stated, rest = m.group(1).strip(), m.group(2), m.group(4)
        # Section numbers ("210.21 - 3") and ranges ("4-6") are not arithmetic.
        if re.search(r"\d{3}\.\d", expr) or re.fullmatch(rf"{NUM}\s*[-−]\s*{NUM}", expr):
            continue
        try:
            value = eval_chain(expr)
        except (ZeroDivisionError, SyntaxError, KeyError):
            continue
        if rest:
            try:
                target = eval_chain(stated + m.group(3) + rest)
            except (ZeroDivisionError, SyntaxError, KeyError):
                continue
            SCANNED.append(f"{rid}: {expr} = {stated}{m.group(3)}{rest}")
            numbers = re.findall(NUM, stated + rest)
            # Whole numbers on the right ("= 3 / 5") are exact, not rounded.
            tol = 1e-9 if not any(decimals(n) for n in numbers) else \
                sum(0.5 * 10 ** (-decimals(n)) for n in numbers) + 1e-9
            # "4 × 0.5 = 2 × 1,000 = 2,000" carries the result on; the next chain checks the rest.
            carried = abs(value - float(stated.replace(",", ""))) <= 0.5 * 10 ** (-decimals(stated)) + 1e-9
            if abs(value - target) > tol and not carried:
                problems.append(f"{rid} [{field}] '{expr} = {stated}{m.group(3)}{rest}' evaluates to {value:.4g}")
            continue
        SCANNED.append(f"{rid}: {expr} = {stated}{m.group(3)}")
        target = float(stated.replace(",", ""))
        places = decimals(stated)
        tol = 0.5 * 10 ** (-places) + 1e-9
        if m.group(3) == "%" and abs(value - target) > tol:
            # "2 × 5% = 10%" states a fraction; "(10 / 125) × 100 = 8%" states the number.
            target, tol = target / 100, tol / 100
        if abs(value - target) > tol:
            problems.append(f"{rid} [{field}] '{expr} = {stated}' evaluates to {value:.4g}")


def covered_by_requirements(requirements: dict) -> set[str]:
    """Records check_requirements.py recomputes (a `check`) or that are plain table lookups."""
    return {rid for rid, req in requirements.get("records", {}).items()
            if req.get("check") or req.get("class") == "table"}


def main_for(records: list[dict], requirements: dict | None = None) -> list[str]:
    """Both passes over `records`; returns the mismatches."""
    if requirements is None:
        requirements = json.loads(REQUIREMENTS.read_text(encoding="utf-8"))
    covered = covered_by_requirements(requirements)
    SCANNED.clear()
    problems: list[str] = []
    for rec in records:
        rid = rec["id"]
        if (rec.get("formula") or rec.get("worked")) and rid not in NON_NUMERIC and rid not in covered:
            problems.append(f"{rid}: has formula/worked text but no check in question_requirements.json")
        for field in TEXT_FIELDS:
            val = rec.get(field)
            texts = val if isinstance(val, list) else [val]
            for text in texts:
                if isinstance(text, str) and text:
                    scan_text(rid, field, text, problems)
    return problems


def main() -> int:
    args = [a for a in sys.argv[1:] if a != "-v"]
    bank_path = Path(args[0]) if args else ROOT / "data" / "question_bank.json"
    records = json.loads(bank_path.read_text(encoding="utf-8"))["records"]
    problems = main_for(records)
    covered = covered_by_requirements(json.loads(REQUIREMENTS.read_text(encoding="utf-8")))
    print(f"records: {len(records)}  covered by question_requirements: "
          f"{sum(1 for rec in records if rec['id'] in covered)}"
          f"  non-numeric formula records: {len(NON_NUMERIC)}"
          f"  arithmetic chains evaluated: {len(SCANNED)}")
    if "-v" in sys.argv:
        for line in SCANNED:
            print("  chain", line)
    for p in problems:
        print("  MISMATCH", p)
    print("RESULT:", "PASS" if not problems else f"FAIL ({len(problems)})")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
