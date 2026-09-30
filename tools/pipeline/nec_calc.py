"""NEC table values and the calculations the question bank relies on.

Every table row and code value comes from the edition's tables.json
(data/<edition dir>/tables.json, the file the in-app math helpers read), so a
new edition changes numbers in one data file. docs/TABLES_FORMULAS_AUDIT.md
lists the tables and rows the bank's calculations use.

`evaluate(spec)` turns a declarative check from data/question_requirements.json
into a value, so tools/pipeline/check_requirements.py can recompute a record's
keyed answer without code per record. The box-fill, conduit-fill,
voltage-drop and dwelling-load helpers have no bank record yet; they are unit
tested in tools/tests/test_question_requirements.py so a new calculation
record can be checked the day it is added.
"""
from __future__ import annotations

import json
import math
import re
import sys
from fractions import Fraction
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pipeline_paths import nec_data  # noqa: E402

NEC = json.loads(nec_data("tables.json").read_text(encoding="utf-8"))
VALUES = NEC["values"]


def rows(table_id: str) -> list[dict]:
    return NEC["tables"][table_id]["rows"]


def column(table_id: str, col: str, key=str) -> dict:
    return {key(r["key"]): r[col] for r in rows(table_id)}


# --- Article 220 -------------------------------------------------------------
T220_42A_VA_FT2 = column("t220_42a", "va_ft2")
DWELLING_VA_FT2 = VALUES["220.41.va_per_ft2"]
T220_45_DWELLING = [(r["hi"], r["percent"] / 100) for r in rows("t220_45")]
T220_45_DWELLING[-1] = (math.inf, T220_45_DWELLING[-1][1])
SMALL_APPLIANCE_VA = VALUES["220.52(A).va_per_circuit"]
LAUNDRY_VA = VALUES["220.52(B).va_per_circuit"]
MULTIOUTLET_FT = VALUES["220.14(H)(1).feet"]
MULTIOUTLET_VA = VALUES["220.14(H).va_per_outlet"]
T220_54_ROWS = rows("t220_54")
DRYER_MIN_W = VALUES["220.54.min_watts"]
T220_55_COL_C = {int(r["key"]): float(r["col_c"]) for r in rows("t220_55") if r["key"].isdigit()}
RANGE_NOTE1_BASE_KW = VALUES["220.55.note1_base_kw"]
RANGE_NOTE1_PCT_PER_KW = VALUES["220.55.note1_percent_per_kw"]

# --- Article 240 / 250 / 310 -------------------------------------------------
STD_240_6A = [r["amps"] for r in rows("t240_6a")]
T250_122_CU = [(r["amps"], r["cu"]) for r in rows("t250_122")]
T310_16_CU = {r["key"]: (r["cu60"], r["cu75"], r["cu90"]) for r in rows("t310_16")}
T310_15B11 = [((r["lo"], r["hi"]), (r["c60"], r["c75"], r["c90"])) for r in rows("t310_15b1_1")]
# Table 310.15(C)(1) starts at four current-carrying conductors; fewer need no adjustment.
T310_15C1 = [((1, 3), 1.0)] + [((r["lo"], r["hi"]), r["percent"] / 100) for r in rows("t310_15c1")]

# --- Box fill and Chapter 9 --------------------------------------------------
T314_16B_IN3 = column("t314_16b1", "in3")
CH9_T1 = {(int(k) if k.isdigit() else k): v for k, v in column("ch9_t1", "percent").items()}
CH9_T4_EMT_IN2 = column("ch9_t4_emt", "a100")
CH9_T5_THHN_IN2 = column("ch9_t5_thhn", "in2")
CH9_T8_CMIL = column("ch9_t8", "cmil")
CH9_T8_CU_OHM_KFT = column("ch9_t8", "cu_ohm_kft")
CH9_NOTE7_ROUND_UP_AT = VALUES["ch9.note7_round_up_at"]
# Approximate K (ohm-cmil/ft) used with VD = 2KIL/CM (a textbook constant, not an NEC table)
K_COPPER, K_ALUMINUM = 12.9, 21.2

# --- Other code values used by calculation records ---------------------------
BUS_A_PER_IN2 = {"copper": VALUES["366.23(A).copper_a_per_in2"],
                 "aluminum": VALUES["366.23(A).aluminum_a_per_in2"]}
T630_31A = column("t630_31a", "multiplier", float)
WELDER_OCPD_PCT = VALUES["630.12(A).percent"]
TAP_10FT_RATIO = VALUES["240.21(B)(1).tap_ratio"]
# Table 220.54 rows above 11 dryers are written as "A - B * (n - C)".
SLIDING_PERCENT = re.compile(r"([\d.]+) - ([\d.]+) \* \(n - (\d+)\)")


def lookup_range(table, value):
    for (lo, hi), factor in table:
        if lo <= value <= hi:
            return factor
    raise KeyError(value)


def next_standard(amps: float) -> int:
    return min(r for r in STD_240_6A if r >= amps)


def egc_cu(rating: float) -> str:
    return next(awg for limit, awg in T250_122_CU if rating <= limit)


def ampacity(base: float, temp_factor: float = 1.0, ccc: int = 3) -> float:
    return base * temp_factor * lookup_range(T310_15C1, ccc)


def range_demand_kw(nameplate_kw: float) -> float:
    """Table 220.55 Column C for one range, with Note 1 above 12 kW."""
    over = max(0.0, nameplate_kw - RANGE_NOTE1_BASE_KW)
    steps = math.floor(over) + (1 if over - math.floor(over) > 0.5 else 0)
    return T220_55_COL_C[1] * (1 + RANGE_NOTE1_PCT_PER_KW / 100 * steps)


def dryer_demand_pct(count: int) -> float:
    for row in T220_54_ROWS:
        if row["lo"] <= count <= row["hi"]:
            if "percent" in row:
                return row["percent"]
            start, step, past = SLIDING_PERCENT.fullmatch(row["expr"]).groups()
            return float(start) - float(step) * (count - int(past))
    raise KeyError(count)


def multioutlet_va(length_ft: float, simultaneous: bool = False) -> float:
    """220.14(H): 180 VA per 5 ft or fraction, or per foot (1 ft = 180 VA) when simultaneous."""
    if simultaneous:
        return math.ceil(length_ft) * MULTIOUTLET_VA
    return math.ceil(length_ft / MULTIOUTLET_FT) * MULTIOUTLET_VA


def dwelling_lighting_demand_va(area_ft2: float, small_appliance: int = 2, laundry: int = 1) -> float:
    """220.41 + 220.52 loads with the Table 220.45 dwelling demand tiers."""
    total = area_ft2 * DWELLING_VA_FT2 + small_appliance * SMALL_APPLIANCE_VA + laundry * LAUNDRY_VA
    demand, floor = 0.0, 0.0
    for ceiling, factor in T220_45_DWELLING:
        part = min(total, ceiling) - floor
        if part <= 0:
            break
        demand += part * factor
        floor = ceiling
    return demand


def box_fill_in3(conductors: dict, devices: int = 0, clamps: bool = False,
                 support_fittings: int = 0, egc: bool = False) -> float:
    """314.16(B): conductor volume in in3.

    conductors: AWG -> count of conductors counted under 314.16(B)(1).
    devices: yokes/straps, each two volume allowances of the largest conductor
    connected to the device (the largest conductor size is used here).
    clamps / egc: one allowance of the largest conductor (egc: all EGCs together).
    support_fittings: one allowance each of the largest conductor.
    """
    largest = min(conductors, key=lambda awg: int(awg))
    total = sum(T314_16B_IN3[awg] * n for awg, n in conductors.items())
    total += T314_16B_IN3[largest] * (2 * devices + (1 if clamps else 0) + support_fittings + (1 if egc else 0))
    return total


def box_max_conductors(box_in3: float, awg: str) -> int:
    return math.floor(box_in3 / T314_16B_IN3[awg] + 1e-9)


def conduit_fill_percent(conduit_in2: float, conductor_areas: list[float]) -> float:
    return 100 * sum(conductor_areas) / conduit_in2


def conduit_max_conductors(conduit_in2: float, wire_in2: float) -> int:
    """Chapter 9 Table 1 (over 2 wires, 40 %); Note 7 rounds up at 0.8 or more."""
    raw = conduit_in2 * CH9_T1["over 2"] / 100 / wire_in2
    whole = math.floor(raw)
    return whole + 1 if raw - whole >= CH9_NOTE7_ROUND_UP_AT else whole


def voltage_drop(amps: float, length_ft: float, awg: str | None = None, *, phases: int = 1,
                 cmil: float | None = None, k: float | None = None) -> float:
    """One-way length. Single-phase 2 x R x I x L; three-phase 1.732 x R x I x L.

    With awg and no k: Chapter 9 Table 8 copper resistance. With k: VD = mult x K x I x L / CM.
    """
    mult = 2 if phases == 1 else math.sqrt(3)
    if k is not None:
        cm = cmil if cmil is not None else CH9_T8_CMIL[awg]
        return mult * k * amps * length_ft / cm
    return mult * CH9_T8_CU_OHM_KFT[awg] * amps * length_ft / 1000


def evaluate(spec: dict):
    """Value of a declarative check (data/question_requirements.json, "check")."""
    kind = spec["kind"]
    if kind == "product":
        value = 1.0
        for f in spec["factors"]:
            value *= f
        return value
    if kind == "quotient":
        return spec["a"] / spec["b"]
    if kind == "fraction":
        return Fraction(spec["numerator"], spec["denominator"])
    if kind == "percent_drop":
        return (spec["source_v"] - spec["load_v"]) / spec["source_v"] * 100
    if kind == "phase_time":
        return Fraction(spec["degrees"], 360) * Fraction(1, spec["hertz"])
    if kind == "multioutlet":
        return multioutlet_va(spec["length_ft"], spec.get("simultaneous", False))
    if kind == "ampacity":
        col = {60: 0, 75: 1, 90: 2}[spec["column_c"]]
        temp = lookup_range(T310_15B11, spec["ambient_f"])[col]
        return ampacity(T310_16_CU[spec["awg"]][col], temp, spec["ccc"])
    if kind == "range_demand":
        return range_demand_kw(spec["kw"])
    if kind == "dryer_demand":
        return f"{dryer_demand_pct(spec['count']):g}%"
    if kind == "welder_ocpd":
        return next_standard(spec["i1max"] * WELDER_OCPD_PCT / 100)
    if kind == "welder_duty":
        return spec["primary_a"] * T630_31A[spec["duty_pct"]]
    if kind == "busbar":
        area = spec["area_in2"] if "area_in2" in spec else spec["width_in"] * spec["thickness_in"]
        return area * BUS_A_PER_IN2[spec.get("metal", "copper")]
    if kind == "tap_10ft_ocpd":
        return spec["tap_ampacity"] * TAP_10FT_RATIO
    if kind == "unit_load":
        return spec["area_ft2"] * T220_42A_VA_FT2[spec["occupancy"]]
    if kind == "egc":
        return egc_cu(spec["rating"])
    if kind == "parallel_equal":
        return spec["ohms"] / spec["count"]
    if kind == "value":
        return spec["value"]
    raise ValueError(f"unknown check kind {kind!r}")
