#!/usr/bin/env python3
"""Recompute every worked solution in the question bank against NEC 2023 values.

Two passes:

1. RECORD CHECKS -- each calculation record is recomputed from the NEC 2023
   table values / factors below and compared with the keyed answer
   (answers[correct_index]). A missing check for a record that carries a
   formula or worked solution is reported, so new calculation records cannot
   slip in unchecked.
2. ARITHMETIC SCAN -- every "a <op> b [<op> c ...] = d" chain found in the
   learner-facing text of all records (formula, worked, reference_text,
   tip_short, choice_notes, info_tip) is re-evaluated and flagged when the
   stated result does not match to the precision it is written with.

Usage:
    python tools/check_worked_solutions.py [bank.json]
Exit 0 = no mismatches.
"""
from __future__ import annotations

import json
import math
import re
import sys
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# --- NEC 2023 values used by the calculation records -------------------------
# Table 220.42(A) General Lighting Loads by Non-Dwelling Occupancy (VA/ft2)
T220_42A = {"office": 1.3}
# 220.14(H)(1): each 5 ft or fraction = one outlet of not less than 180 VA
MULTIOUTLET_FT, MULTIOUTLET_VA = 5, 180
# Table 310.16, copper, (60C, 75C, 90C) ampacities
T310_16_CU = {"12": (20, 25, 30), "10": (30, 35, 40)}
# Table 310.15(B)(1)(1) correction factors (based on 30C), 90C column
T310_15B11_90C = [((105, 113), 0.87)]
# Table 310.15(C)(1) adjustment factors by number of current-carrying conductors
T310_15C1 = [((4, 6), 0.80), ((7, 9), 0.70), ((10, 20), 0.50)]
# Table 220.54 Demand Factors for Household Electric Clothes Dryers (%)
T220_54 = {**{n: 100 for n in range(1, 5)}, 5: 85, 6: 75, 7: 65, 8: 60, 9: 55, 10: 50, 11: 47}
# Table 220.55 Column C, one appliance; Note 1: +5 % per kW (or major fraction) over 12 kW
T220_55_COL_C_ONE = 8.0
# Table 250.122 (rating not exceeding, A) -> copper EGC AWG
T250_122_CU = [(15, "14"), (20, "12"), (60, "10"), (100, "8"), (200, "6")]
# Table 430.250 induction-type, 460 V column
T430_250_460V = {50: 65}
# Table 210.21(B)(2): 15 A receptacle on a 15 or 20 A circuit -> 12 A
T210_21B2 = {(20, 15): 12, (20, 20): 16, (30, 30): 24}
# 240.6(A) standard ampere ratings (subset through 200 A)
STD_240_6A = [15, 20, 25, 30, 35, 40, 45, 50, 60, 70, 80, 90, 100, 110, 125, 150, 175, 200]
# 366.23(A): bare copper bars in sheet metal auxiliary gutters, A per sq in
BUS_CU_A_PER_SQIN = 1000
# Table 630.31(A)(2) resistance-welder duty-cycle multipliers
T630_31A2 = {50: 0.71, 40: 0.63, 30: 0.55, 25: 0.50, 20: 0.45, 15: 0.39, 10: 0.32, 7.5: 0.27, 5: 0.22}
# 630.12(A): welder OCPD not more than 200 % of I1max
WELDER_OCPD_PCT = 200
# Table 348.22, 3/8 FMC, THHN (fittings inside, outside)
T348_22_THHN = {"18": (5, 8), "16": (4, 6), "14": (3, 4), "12": (2, 3), "10": (1, 1)}
# Table 352.30 support spacing (ft) by trade size range
T352_30 = [((0.5, 1.0), 3), ((1.25, 2.0), 5), ((2.5, 3.0), 6), ((3.5, 5.0), 7), ((6.0, 6.0), 8)]
# Chapter 9 Note (4): nipples <= 24 in. may be filled to 60 %
CH9_NOTE4_NIPPLE_PCT = 60
# 310.12(A): 83 % of service rating (100-400 A dwelling)
DWELLING_SERVICE_PCT = 83
# 626.11(A): 11 kVA per electrified truck parking space
TRUCK_SPACE_KVA = 11


def lookup_range(table, value):
    for (lo, hi), factor in table:
        if lo <= value <= hi:
            return factor
    raise KeyError(value)


def next_standard(amps):
    return min(r for r in STD_240_6A if r >= amps)


def egc_cu(rating):
    return next(awg for limit, awg in T250_122_CU if rating <= limit)


def range_demand_kw(nameplate_kw):
    over = nameplate_kw - 12
    steps = math.floor(over) + (1 if over - math.floor(over) >= 0.5 else 0)
    return T220_55_COL_C_ONE * (1 + 0.05 * steps)


# record id -> (description, computed value)
CHECKS = {
    "final-exam-#1-004": ("Table 220.42(A): 5,000 ft2 x 1.3 VA", 5000 * T220_42A["office"]),
    "open-book-exam-#1-021": ("Table 220.42(A): 5,000 ft2 x 1.3 VA", 5000 * T220_42A["office"]),
    "final-exam-#1-010": ("220.14(H)(1): ceil(12/5) x 180 VA", math.ceil(12 / MULTIOUTLET_FT) * MULTIOUTLET_VA),
    "final-exam-#1-014": ("Table 310.16 #12 Cu 75C x Table 310.15(C)(1) 4 CCC",
                          T310_16_CU["12"][1] * lookup_range(T310_15C1, 4)),
    "final-exam-#1-027": ("Table 310.16 #10 Cu 90C x Table 310.15(B)(1)(1) 112F",
                          T310_16_CU["10"][2] * lookup_range(T310_15B11_90C, 112)),
    "final-exam-#1-032": ("240.21(B)(1)(4): tap ampacity >= 1/10 OCPD", 40 * 10),
    "final-exam-#1-036": ("310.12(A)", f"{DWELLING_SERVICE_PCT}%"),
    "open-book-exam-#4-022": ("310.12(A)", f"{DWELLING_SERVICE_PCT}%"),
    "final-exam-#1-046": ("40/100 reduced", Fraction(40, 100)),
    "final-exam-#1-001": ("60/100 reduced", Fraction(60, 100)),
    "final-exam-#1-062": ("(125-115)/125 x 100", (125 - 115) / 125 * 100),
    "final-exam-#1-065": ("(90/360) x (1/60)", Fraction(90, 360) * Fraction(1, 60)),
    "final-exam-#1-068": ("Table 250.122, 50 A falls in the 60 A row", egc_cu(50)),
    "final-exam-#1-070": ("Table 430.250 50 hp, 460 V column", T430_250_460V[50]),
    "final-exam-#3-014": ("Table 210.21(B)(2) 20 A circuit, 15 A receptacle", T210_21B2[(20, 15)]),
    "final-exam-#3-026": ("626.11(A)", TRUCK_SPACE_KVA),
    "final-exam-#3-063": ("366.23(A): 1.5 in2 x 1000 A/in2", 1.5 * BUS_CU_A_PER_SQIN),
    "final-exam-#5-039": ("366.23(A): 4 in x 0.5 in x 1000 A/in2", 4 * 0.5 * BUS_CU_A_PER_SQIN),
    "final-exam-#1-040": ("Table 220.54, 5 dryers", f"{T220_54[5]}%"),
    "open-book-exam-#4-015": ("Table 220.54, 5 dryers", f"{T220_54[5]}%"),
    "final-exam-#1-067": ("Chapter 9 Note (4)", f"{CH9_NOTE4_NIPPLE_PCT}%"),
    "final-exam-#1-025": ("630.12(A) 200% x 43 A, next standard 240.6(A)",
                          next_standard(43 * WELDER_OCPD_PCT / 100)),
    "final-exam-#3-033": ("I = P / E", 2 / 20),
    "final-exam-#3-048": ("Table 348.22 largest THHN size listed",
                          min((k for k, v in T348_22_THHN.items() if max(v) > 0), key=int)),
    "final-exam-#1-063": ("3.5 in / (1/4 in per ft)", 3.5 / 0.25),
    "final-exam-#1-021": ("Table 220.55 Col C 8 kW, Note 1 +5%/kW over 12", range_demand_kw(14)),
    "final-exam-#3-055": ("2000 / 2", 2000 / 2),
    "final-exam-#3-040": ("Table 630.31(A)(2): 21 A x 0.39", 21 * T630_31A2[15]),
    "final-exam-#5-070": ("Table 352.30, 1/2 in", lookup_range(T352_30, 0.5)),
    "final-exam-#1-022": ("210.52(G)(1): one per bay x 2 bays", 2),
}
# formula/worked present but nothing numeric to recompute
NON_NUMERIC = {
    "final-exam-#3-069": "430.62(A) rule statement",
    "open-book-exam-#7-004": "517.73(A)(2) rule statement (momentary rating)",
}


WORD_NUMBERS = {"one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6}


def parse_answer(text: str):
    t = text.strip().replace(",", "")
    if t.lower() in WORD_NUMBERS:
        return float(WORD_NUMBERS[t.lower()])
    m = re.fullmatch(r"(\d+)\s*/\s*(\d+)", t)
    if m:
        return Fraction(int(m.group(1)), int(m.group(2)))
    m = re.search(r"#?(\d+(?:\.\d+)?)", t)
    return float(m.group(1)) if m else None


def values_match(computed, answer_text: str) -> bool:
    if isinstance(computed, str):
        return computed.replace(" ", "") == answer_text.replace(" ", "").lstrip("#")
    ans = parse_answer(answer_text)
    if ans is None:
        return False
    if isinstance(computed, Fraction):
        return isinstance(ans, Fraction) and ans == computed
    if isinstance(ans, Fraction):
        return False
    try:
        return math.isclose(float(computed), float(ans), rel_tol=0, abs_tol=0.005)
    except (TypeError, ValueError):
        return str(computed) == str(ans)


# --- arithmetic scan ---------------------------------------------------------
NUM = r"\d[\d,]*(?:\.\d+)?"
OP = r"(?:×|\*|÷|/|\+|−|-|\bx\b|\btimes\b|\bdivided by\b)"
CHAIN = re.compile(rf"(?<![\w.])({NUM}(?:\s*%?)?(?:\s*{OP}\s*{NUM}%?)+)\s*=\s*({NUM})(%?)(?!\s*/)")
OPS = {"×": "*", "*": "*", "x": "*", "times": "*", "÷": "/", "/": "/", "divided by": "/",
       "+": "+", "−": "-", "-": "-"}
TEXT_FIELDS = ["formula", "worked", "reference_text", "tip_short", "info_tip", "choice_notes"]
SCANNED: list[str] = []


def eval_chain(expr: str):
    tokens = re.findall(rf"{NUM}%?|{OP}", expr)
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


UNIT = re.compile(r"(\d)\s*(?:sq\.? ?in\.?|in2|kVA|kW|VA|V|A|W|ohms|amperes|amps|ft|in\.?)(?![\w/])")


def scan_text(rid: str, field: str, text: str, problems: list):
    text = UNIT.sub(r"\1", text.replace("(", " ").replace(")", " "))
    text = re.sub(r"[ \t]+", " ", text)
    for m in CHAIN.finditer(text):
        expr, stated = m.group(1), m.group(2)
        # Section numbers ("210.21 - 3") and ranges ("4-6") are not arithmetic.
        if re.search(r"\d{3}\.\d", expr) or re.fullmatch(rf"{NUM}\s*[-−]\s*{NUM}", expr):
            continue
        try:
            value = eval_chain(expr)
        except (ZeroDivisionError, SyntaxError, KeyError):
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


def main() -> int:
    args = [a for a in sys.argv[1:] if a != "-v"]
    bank_path = Path(args[0]) if args else ROOT / "question_bank.json"
    records = json.loads(bank_path.read_text(encoding="utf-8"))["records"]
    problems: list[str] = []
    checked = 0
    for rec in records:
        rid = rec["id"]
        keyed = str(rec["answers"][rec["correct_index"]])
        if rid in CHECKS:
            desc, computed = CHECKS[rid]
            checked += 1
            if not values_match(computed, keyed):
                problems.append(f"{rid}: {desc} gives {computed!r}, keyed answer is {keyed!r}")
        elif (rec.get("formula") or rec.get("worked")) and rid not in NON_NUMERIC:
            problems.append(f"{rid}: has formula/worked text but no recomputation in CHECKS")
        for field in TEXT_FIELDS:
            val = rec.get(field)
            texts = val if isinstance(val, list) else [val]
            for text in texts:
                if isinstance(text, str) and text:
                    scan_text(rid, field, text, problems)
    print(f"records: {len(records)}  recomputed: {checked}  non-numeric formula records: {len(NON_NUMERIC)}"
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
