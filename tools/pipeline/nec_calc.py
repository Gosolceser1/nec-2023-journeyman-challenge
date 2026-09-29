"""NEC 2023 table values and the calculations the question bank relies on.

The table constants were checked against NFPA 70-2023 on UpCodes
(docs/TABLES_FORMULAS_AUDIT.md lists the table, the rows used and the URL).
DWELLING_VA_FT2 (220.41), the 1500 VA circuit loads (220.52) and the K values
were not re-read there. Only the rows a calculation needs are kept.

`evaluate(spec)` turns a declarative check from data/question_requirements.json
into a value, so tools/pipeline/check_requirements.py can recompute a record's
keyed answer without code per record. The box-fill, conduit-fill,
voltage-drop and dwelling-load helpers have no bank record yet; they are unit
tested in tools/tests/test_question_requirements.py so a new calculation
record can be checked the day it is added.
"""
from __future__ import annotations

import math
from fractions import Fraction

# --- Article 220 -------------------------------------------------------------
# Table 220.42(A) General Lighting Loads by Non-Dwelling Occupancy (VA/ft2)
T220_42A_VA_FT2 = {
    "automotive facility": 1.5, "convention center": 1.4, "courthouse": 1.4,
    "dormitory": 1.5, "exercise center": 1.4, "fire station": 1.3,
    "gymnasium": 1.7, "health care clinic": 1.6, "hospital": 1.6,
    "hotel or motel": 1.7, "library": 1.5, "manufacturing facility": 2.2,
    "motion picture theater": 1.6, "museum": 1.6, "office": 1.3,
    "parking garage": 0.3, "penitentiary": 1.2, "performing arts theater": 1.5,
    "police station": 1.3, "post office": 1.6, "religious facility": 2.2,
    "restaurant": 1.5, "retail": 1.9, "school/university": 1.5,
    "sports arena": 1.5, "town hall": 1.4, "transportation": 1.2,
    "warehouse": 1.2, "workshop": 1.7,
}
# 220.41: dwelling units, 3 VA/ft2
DWELLING_VA_FT2 = 3
# Table 220.45, dwelling units: first 3000 VA at 100 %, 3001-120,000 VA at 35 %, rest at 25 %
T220_45_DWELLING = [(3000, 1.00), (120000, 0.35), (math.inf, 0.25)]
# 220.52(A)/(B): small-appliance and laundry circuits, VA each
SMALL_APPLIANCE_VA, LAUNDRY_VA = 1500, 1500
# 220.14(H)(1): each 5 ft (or fraction) of multioutlet assembly = one 180 VA outlet
MULTIOUTLET_FT, MULTIOUTLET_VA = 5, 180
# Table 220.54 Demand Factors for Household Electric Clothes Dryers (%)
T220_54 = {**{n: 100 for n in range(1, 5)}, 5: 85, 6: 75, 7: 65, 8: 60, 9: 55, 10: 50, 11: 47}
DRYER_MIN_W = 5000
# Table 220.55 Column C, one appliance (kW); Note 1: +5 % per kW or major fraction over 12 kW
T220_55_COL_C = {1: 8.0, 2: 11.0, 3: 14.0, 4: 17.0, 5: 20.0}

# --- Article 240 / 250 / 310 -------------------------------------------------
# 240.6(A) standard ampere ratings (through 400 A)
STD_240_6A = [10, 15, 20, 25, 30, 35, 40, 45, 50, 60, 70, 80, 90, 100, 110, 125, 150, 175,
              200, 225, 250, 300, 350, 400]
# Table 250.122 (rating not exceeding, A) -> copper EGC
T250_122_CU = [(15, "14"), (20, "12"), (60, "10"), (100, "8"), (200, "6"), (300, "4"), (400, "3")]
# Table 310.16 copper (60 C, 75 C, 90 C)
T310_16_CU = {"14": (15, 20, 25), "12": (20, 25, 30), "10": (30, 35, 40), "8": (40, 50, 55),
              "6": (55, 65, 75), "4": (70, 85, 95)}
# Table 310.15(B)(1)(1) correction factors based on 30 C: (lo F, hi F) -> (60 C, 75 C, 90 C)
T310_15B11 = [((69, 77), (1.08, 1.05, 1.04)),
              ((78, 86), (1.00, 1.00, 1.00)), ((87, 95), (0.91, 0.94, 0.96)),
              ((96, 104), (0.82, 0.88, 0.91)), ((105, 113), (0.71, 0.82, 0.87))]
# Table 310.15(C)(1) adjustment by number of current-carrying conductors
T310_15C1 = [((1, 3), 1.00), ((4, 6), 0.80), ((7, 9), 0.70), ((10, 20), 0.50),
             ((21, 30), 0.45), ((31, 40), 0.40), ((41, 10**6), 0.35)]

# --- Box fill: Table 314.16(B) volume allowance per conductor (in3) -----------
T314_16B_IN3 = {"18": 1.50, "16": 1.75, "14": 2.00, "12": 2.25, "10": 2.50, "8": 3.00, "6": 5.00}

# --- Chapter 9 ---------------------------------------------------------------
# Table 1: percent fill by number of conductors
CH9_T1 = {1: 53, 2: 31, "over 2": 40}
# Table 4, Article 358 EMT, total area 100 % (in2)
CH9_T4_EMT_IN2 = {"1/2": 0.304, "3/4": 0.533, "1": 0.864, "1-1/4": 1.496, "1-1/2": 2.036, "2": 3.356}
# Table 5, THHN/THWN/THWN-2 approximate area (in2)
CH9_T5_THHN_IN2 = {"14": 0.0097, "12": 0.0133, "10": 0.0211, "8": 0.0366, "6": 0.0507,
                   "4": 0.0824, "3": 0.0973, "2": 0.1158, "1": 0.1562}
# Table 8: circular mils and uncoated copper dc resistance at 75 C (ohm/kFT), stranded
CH9_T8_CMIL = {"14": 4110, "12": 6530, "10": 10380, "8": 16510, "6": 26240, "4": 41740,
               "3": 52620, "2": 66360, "1": 83690}
CH9_T8_CU_OHM_KFT = {"14": 3.14, "12": 1.98, "10": 1.24, "8": 0.778, "6": 0.491, "4": 0.308,
                     "3": 0.245, "2": 0.194, "1": 0.154}
# Approximate K (ohm-cmil/ft) used with VD = 2KIL/CM
K_COPPER, K_ALUMINUM = 12.9, 21.2

# --- Other code values used by calculation records ---------------------------
# 366.23(A): bare bars in sheet metal auxiliary gutters, A per in2
BUS_A_PER_IN2 = {"copper": 1000, "aluminum": 700}
# Table 630.31(A) resistance-welder duty-cycle multipliers
T630_31A = {50: 0.71, 40: 0.63, 30: 0.55, 25: 0.50, 20: 0.45, 15: 0.39, 10: 0.32, 7.5: 0.27, 5: 0.22}
# 630.12(A): arc-welder OCPD not more than 200 % of I1max
WELDER_OCPD_PCT = 200
# 240.21(B)(1)(1)(d): field-installed 10 ft tap ampacity >= 1/10 of the feeder OCPD
TAP_10FT_RATIO = 10


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
    over = max(0.0, nameplate_kw - 12)
    steps = math.floor(over) + (1 if over - math.floor(over) > 0.5 else 0)
    return T220_55_COL_C[1] * (1 + 0.05 * steps)


def dryer_demand_pct(count: int) -> float:
    if count in T220_54:
        return T220_54[count]
    if count <= 23:
        return 47 - (count - 11)
    if count <= 42:
        return 35 - 0.5 * (count - 23)
    return 25


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
    return whole + 1 if raw - whole >= 0.8 else whole


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
