#!/usr/bin/env python3
"""Build or check data/nec/<year>/tables.json from a local NEC text cache.

The math helpers (Math Trainer, step-by-step solutions, table drills) read
every NEC table value from data/nec/<year>/tables.json. This tool writes that
file from a plain-text copy of the code (one file per article plus ch9.txt,
tab-separated tables, as saved from the UpCodes viewer), so no value is typed
by hand, and `--check` proves the checked-in file still matches the cache.

Only the rows and columns the math helpers use are kept. The cache itself is
never copied into the repo.

    python tools/math/nec_tables_from_cache.py [--cache DIR] [--year 2023] [--check]

The cache folder defaults to $NEC_CACHE, then ~/Documents/nec<year>_cache.
`--check` exits 0 when the file matches, 1 when it differs, and 0 with a
SKIPPED note when no cache is present (fresh clones and CI).
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

# Rules that are single numbers in the text. Each entry: key -> (article file,
# evidence regex, value). --check fails when the evidence is missing, so a
# changed edition cannot keep a stale number silently.
RULES = {
    "220.41.va_per_ft2": ("art_220", r"not less than 33 volt-amperes/m2 \(3 volt-amperes/ft2\)", 3),
    "220.52(A).va_per_circuit": ("art_220", r"calculated at 1500 volt-amperes for each 2-wire small-appliance branch circuit", 1500),
    "220.52(B).va_per_circuit": ("art_220", r"not less than 1500 volt-amperes shall be included for each 2-wire laundry branch circuit", 1500),
    "210.11(C)(1).min_circuits": ("art_210", r"two or more 20-ampere small-appliance branch circuits", 2),
    "220.53.percent": ("art_220", r"demand factor of 75 percent to the nameplate rating load of four or more appliances", 75),
    "220.53.min_count": ("art_220", r"four or more appliances rated 1/4 hp or greater, or 500 watts or greater", 4),
    "220.54.min_watts": ("art_220", r"either 5000 watts \(volt-amperes\) or the nameplate rating, whichever is larger", 5000),
    "220.55.note1_base_kw": ("art_220", r"exceeds 12 kW", 12),
    "220.55.note1_percent_per_kw": ("art_220", r"increased 5 percent for each additional kilowatt of rating or major fraction", 5),
    "220.14(H)(1).feet": ("art_220", r"each 1\.5 m \(5 ft\) or fraction thereof", 5),
    "220.14(H).va_per_outlet": ("art_220", r"one outlet of not less than 180 volt-amperes", 180),
    "220.60.motor_percent": ("art_220", r"125 percent of either the motor load or air-conditioning load", 125),
    "430.22.percent": ("art_430", r"ampacity of not less than 125 percent of the motor full-load current rating", 125),
    "430.32(A)(1).service_factor_percent": ("art_430", r"Motors with a marked service factor 1\.15 or greater\t125%", 125),
    "430.32(A)(1).temp_rise_percent": ("art_430", r"Motors with a marked temperature rise 40°C or less\t125%", 125),
    "430.32(A)(1).other_percent": ("art_430", r"All other motors\t115%", 115),
    "430.32(C).service_factor_percent": ("art_430", r"Motors with marked service factor 1\.15 or greater\t140%", 140),
    "430.32(C).temp_rise_percent": ("art_430", r"Motors with a marked temperature rise 40°C or less\t140%", 140),
    "430.32(C).other_percent": ("art_430", r"All other motors\t130%", 130),
    "430.24.largest_percent": ("art_430", r"125 percent of the full-load current rating of the highest rated motor", 125),
    "220.61(B).neutral_percent": ("art_220", r"additional demand factor of 70 percent applied to the amount in 220\.61\(B\)\(1\)", 70),
    "240.4(D).cu_14": ("art_240", r"\(4\) 14 AWG Copper\n15 amperes", 15),
    "240.4(D).cu_12": ("art_240", r"\(6\) 12 AWG Copper\n20 amperes", 20),
    "240.4(D).cu_10": ("art_240", r"\(8\) 10 AWG Copper\n30 amperes", 30),
    "240.4(D).al_12": ("art_240", r"\(5\) 12 AWG Aluminum and Copper-Clad Aluminum\n15 amperes", 15),
    "240.4(D).al_10": ("art_240", r"\(7\) 10 AWG Aluminum and Copper-Clad Aluminum\n25 amperes", 25),
    "366.23(A).copper_a_per_in2": ("art_366", r"1000 amperes/in\.2", 1000),
    "366.23(A).aluminum_a_per_in2": ("art_366", r"700 amperes/in\.2", 700),
    "630.12(A).percent": ("art_630", r"not more than 200 percent of I1max", 200),
    "240.21(B)(1).tap_ratio": ("art_240", r"not less than one-tenth of the rating of the overcurrent device protecting the feeder", 10),
    "210.52(G)(1).per_bay": ("art_210", r"at least one receptacle outlet shall be installed in each vehicle bay", 1),
    "314.16(B)(5).egc_single": ("art_314", r"Where up to four equipment grounding conductors enter a box, a single volume allowance", 4),
    "314.16(B)(5).extra_egc_fraction": ("art_314", r"A 1/4 volume allowance shall be made for each additional equipment grounding conductor", 0.25),
    "314.16(B)(4).per_yoke": ("art_314", r"a double volume allowance", 2),
    "ch9.note7_round_up_at": ("ch9", r"decimal greater than or equal to 0\.8", 0.8),
    "ch9.note4_nipple_percent": ("ch9", r"filled to 60 percent of their total cross-sectional area", 60),
}

RACEWAYS = {
    "emt": ("Article 358 - Electrical Metallic Tubing (EMT)", "EMT"),
    "imc": ("Article 342 - Intermediate Metal Conduit (IMC)", "IMC"),
    "rmc": ("Article 344 - Rigid Metal Conduit (RMC)", "RMC"),
    "pvc80": ("Article 352 - Rigid PVC Conduit (PVC), Schedule 80", "PVC Schedule 80"),
    "pvc40": ("Articles 352 and 353 - Rigid PVC Conduit (PVC), Schedule 40, and HDPE Conduit (HDPE)", "PVC Schedule 40"),
}
TRADE_SIZES = ["1/2", "3/4", "1", "1-1/4", "1-1/2", "2", "2-1/2", "3", "3-1/2", "4"]
SIZES_AWG = ["14", "12", "10", "8", "6", "4", "3", "2", "1", "1/0", "2/0", "3/0", "4/0",
             "250", "300", "350", "400", "500", "600", "700", "750", "800", "900", "1000"]


def fix_fraction(text: str) -> str:
    """The cache prints mixed numbers without a space: 11/4 = 1-1/4, 71/2 = 7-1/2."""
    text = text.strip().lstrip("l")
    m = re.fullmatch(r"(\d)(\d/\d)", text)
    return f"{m.group(1)}-{m.group(2)}" if m else text


def num(text: str):
    text = text.strip().replace(" ", ".")
    if text in ("-", "—", ""):
        return None
    value = float(text)
    return int(value) if value.is_integer() and "." not in text else value


class Cache:
    def __init__(self, folder: Path):
        self.folder = folder

    def lines(self, name: str) -> list[str]:
        for sub in ("raw", "raw_0927", ""):
            path = self.folder / sub / f"{name}.txt"
            if path.exists():
                return path.read_text(encoding="utf-8").split("\n")
        raise FileNotFoundError(f"{name}.txt not in {self.folder}")

    def text(self, name: str) -> str:
        return "\n".join(self.lines(name))

    def block(self, name: str, heading: str, count: int) -> list[list[str]]:
        """The `count` tab rows after the line that starts with `heading`."""
        lines = self.lines(name)
        start = next(i for i, line in enumerate(lines) if line.startswith(heading))
        return [line.split("\t") for line in lines[start + 1:start + 1 + count]]

    def rows_after(self, name: str, heading: str, first_cell: str, count: int) -> list[list[str]]:
        lines = self.lines(name)
        start = next(i for i, line in enumerate(lines) if line.startswith(heading))
        begin = next(i for i in range(start, len(lines)) if lines[i].split("\t")[0].strip() == first_cell)
        return [lines[i].split("\t") for i in range(begin, begin + count)]


def table(title: str, caption: str, key_label: str, columns: list, rows: list, kind: str = "keyed", **extra) -> dict:
    out = {"title": title, "caption": caption, "kind": kind, "key_label": key_label,
           "columns": [{"id": c, "label": label} for c, label in columns], "rows": rows}
    out.update(extra)
    return out


def build(cache: Cache, year: str) -> dict:
    tables: dict[str, dict] = {}

    # Table 310.16
    rows = []
    for cells in cache.rows_after("art_310", "Table 310.16 Ampacities", "14*", 29):
        size = cells[0].rstrip("*")
        if size not in SIZES_AWG:
            continue
        vals = [num(c) for c in cells[1:7]]
        rows.append({"key": size, "cu60": vals[0], "cu75": vals[1], "cu90": vals[2],
                     "al60": vals[3], "al75": vals[4], "al90": vals[5]})
    tables["t310_16"] = table(
        "Table 310.16", "Allowable ampacities, not more than three current-carrying conductors, 30°C (86°F) ambient",
        "Size (AWG or kcmil)",
        [("cu60", "Copper 60°C"), ("cu75", "Copper 75°C"), ("cu90", "Copper 90°C"),
         ("al60", "Aluminum 60°C"), ("al75", "Aluminum 75°C"), ("al90", "Aluminum 90°C")], rows,
        unit="A")

    # Table 310.15(B)(1)(1)
    rows = []
    for cells in cache.rows_after("art_310", "Table 310.15(B)(1)(1)", "10 or less", 16):
        c_range, f_range = cells[0], cells[4]
        f_lo, f_hi = _range(f_range)
        c_lo, c_hi = _range(c_range)
        rows.append({"lo": f_lo, "hi": f_hi, "key": f_range.replace("—", "–"), "c_lo": c_lo, "c_hi": c_hi,
                     "c60": num(cells[1]), "c75": num(cells[2]), "c90": num(cells[3])})
    tables["t310_15b1_1"] = table(
        "Table 310.15(B)(1)(1)", "Ambient temperature correction factors based on 30°C (86°F)",
        "Ambient (°F)", [("c60", "60°C"), ("c75", "75°C"), ("c90", "90°C")], rows, kind="range")

    # Table 310.15(C)(1)
    rows = []
    for cells in cache.block("art_310", "Table 310.15(C)(1)", 9)[3:9]:
        lo, hi = _range(cells[0])
        rows.append({"lo": lo, "hi": hi, "key": cells[0].replace("—", "–"), "percent": num(cells[1])})
    tables["t310_15c1"] = table(
        "Table 310.15(C)(1)", "Adjustment factors for more than three current-carrying conductors",
        "Number of conductors", [("percent", "Percent of Table 310.16 value")], rows, kind="range")

    # Table 314.16(A)
    rows = []
    for cells in cache.rows_after("art_314", "Table 314.16(A) Metal Boxes", "100 × 32", 24):
        if cells[0].startswith("min."):
            name, cm3, in3, counts = cells[1], cells[2], cells[3], cells[4:11]
            label = re.sub(r"\((\d)(\d/\d)\)", lambda m: f"({m.group(1)}-{m.group(2)} in. deep)", name)
            label = label.replace(" - ", " ")
        else:
            inches, shape, cm3, in3, counts = cells[1], cells[2], cells[3], cells[4], cells[5:12]
            label = f"{_inch_label(inches, cells[0])} {shape}"
        row = {"key": label, "in3": num(in3)}
        for awg, count in zip(["18", "16", "14", "12", "10", "8", "6"], counts):
            row["n" + awg] = num(count)
        rows.append(row)
    tables["t314_16a"] = table(
        "Table 314.16(A)", "Metal boxes: minimum volume and maximum number of conductors",
        "Box trade size", [("in3", "Volume (in³)")] + [("n" + a, f"{a} AWG") for a in ["18", "16", "14", "12", "10", "8", "6"]],
        rows)

    # Table 314.16(B)(1)
    rows = [{"key": c[0], "in3": num(c[2])} for c in cache.block("art_314", "Table 314.16(B)(1)", 9)[2:9]]
    tables["t314_16b1"] = table(
        "Table 314.16(B)(1)", "Volume allowance required per conductor", "Size (AWG)",
        [("in3", "Free space per conductor (in³)")], rows, unit="in³")

    # Chapter 9 Table 1
    rows = [{"key": "1", "percent": 53}, {"key": "2", "percent": 31}, {"key": "over 2", "percent": 40}]
    t1 = cache.block("ch9", "Table 1 Percent of Cross Section", 4)[1:4]
    got = [num(c[1]) for c in t1]
    if got != [53, 31, 40]:
        raise ValueError(f"Chapter 9 Table 1 reads {got}")
    tables["ch9_t1"] = table("Chapter 9, Table 1", "Percent of cross section of conduit and tubing for conductors",
                             "Number of conductors", [("percent", "Fill (%)")], rows)

    # Chapter 9 Table 4 (the raceways the helpers use)
    for rid, (heading, name) in RACEWAYS.items():
        lines = cache.lines("ch9")
        start = next(i for i, line in enumerate(lines) if line.startswith(heading))
        rows = []
        for line in lines[start + 3:start + 20]:
            cells = line.split("\t")
            if len(cells) < 14 or not cells[0].strip().isdigit():
                break
            size = fix_fraction(cells[1])
            if size not in TRADE_SIZES or num(cells[3]) is None:
                continue
            rows.append({"key": size, "a40": num(cells[3]), "a60": num(cells[5]), "a53": num(cells[7]),
                         "a31": num(cells[9]), "a100": num(cells[13])})
        tables[f"ch9_t4_{rid}"] = table(
            "Chapter 9, Table 4", f"{name}: dimensions and percent area", "Trade size",
            [("a40", "Over 2 wires 40% (in²)"), ("a60", "60% (in²)"), ("a53", "1 wire 53% (in²)"),
             ("a31", "2 wires 31% (in²)"), ("a100", "Total area 100% (in²)")], rows, unit="in²", raceway=name)

    # Chapter 9 Table 5
    t5 = {"thhn": ("THHN, THWN, THWN-2", "THHN, THWN, THWN-2\t14"),
          "xhhw": ("XHHW, XHHW-2, XHH", "XHHW, ZW, XHHW-2, XHH\t14")}
    lines = cache.lines("ch9")
    for tid, (name, first) in t5.items():
        start = next(i for i, line in enumerate(lines) if line.startswith(first))
        rows = []
        for line in lines[start:start + 40]:
            cells = line.split("\t")
            if len(cells) == 6:
                cells = cells[1:]
            if len(cells) != 5:
                break
            size = cells[0].strip()
            if size not in SIZES_AWG:
                break
            rows.append({"key": size, "in2": num(cells[2])})
        tables[f"ch9_t5_{tid}"] = table("Chapter 9, Table 5", f"Type {name}: approximate area", "Size (AWG or kcmil)",
                                        [("in2", "Approximate area (in²)")], rows, unit="in²", insulation=name)
    # THW: 14-8 from the first group, 6 and up from the second
    rows = []
    for size, cells in _thw_rows(lines):
        rows.append({"key": size, "in2": num(cells[2])})
    tables["ch9_t5_thw"] = table("Chapter 9, Table 5", "Type THW, THHW, THW-2, TW: approximate area",
                                 "Size (AWG or kcmil)", [("in2", "Approximate area (in²)")], rows, unit="in²",
                                 insulation="THW, THHW, THW-2, TW")

    # Chapter 9 Table 8 (stranded conductors)
    rows = []
    start = next(i for i, line in enumerate(lines) if line.startswith("Table 8 Conductor Properties"))
    for line in lines[start + 1:start + 60]:
        cells = line.split("\t")
        if len(cells) != 16:
            continue
        size, strands = cells[0].strip(), cells[3].strip()
        if size not in SIZES_AWG or strands == "1":
            continue
        cmil = num(cells[2]) if cells[2].strip() not in ("-", "") else int(size) * 1000
        rows.append({"key": size, "cmil": cmil, "cu_ohm_kft": num(cells[11]), "al_ohm_kft": num(cells[15])})
    tables["ch9_t8"] = table("Chapter 9, Table 8", "Conductor properties: area and dc resistance at 75°C (stranded)",
                             "Size (AWG or kcmil)",
                             [("cmil", "Area (circular mils)"), ("cu_ohm_kft", "Copper uncoated (Ω/kFT)"),
                              ("al_ohm_kft", "Aluminum (Ω/kFT)")], rows)

    # Table 220.42(A)
    rows = []
    for cells in cache.block("art_220", "Table 220.42(A)", 31)[2:31]:
        name = re.sub(r"[\d,]+$", "", cells[0]).strip()
        short = name.split(",")[0].lower()
        rows.append({"key": short, "label": name, "va_ft2": num(cells[2])})
    tables["t220_42a"] = table("Table 220.42(A)", "General lighting loads by non-dwelling occupancy", "Occupancy",
                               [("va_ft2", "Unit load (VA/ft²)")], rows)

    # Table 220.45, dwelling units
    block = cache.block("art_220", "Table 220.45", 4)[1:4]
    pct = [num(c[-1]) for c in block]
    tables["t220_45"] = table("Table 220.45", "Lighting load demand factors, dwelling units", "Portion of load (VA)",
                              [("percent", "Demand factor (%)")],
                              [{"lo": 0, "hi": 3000, "key": "First 3,000", "percent": pct[0]},
                               {"lo": 3000, "hi": 120000, "key": "3,001 to 120,000", "percent": pct[1]},
                               {"lo": 120000, "hi": 1000000000, "key": "Over 120,000", "percent": pct[2]}], kind="tiers")

    # Table 220.54
    rows = []
    for cells in cache.block("art_220", "Table 220.54", 12)[1:12]:
        lo, hi = _range(cells[0])
        text = cells[1]
        row = {"lo": lo, "hi": hi, "key": cells[0].replace("—", "–")}
        m = re.fullmatch(r"(\d+)% minus ([\d.]+)% for each dryer exceeding (\d+)", text)
        if m:
            row["expr"] = f"{m.group(1)} - {m.group(2)} * (n - {m.group(3)})"
            row["label"] = text
        else:
            row["percent"] = num(text.rstrip("%"))
        rows.append(row)
    rows[-1]["hi"] = 100000
    tables["t220_54"] = table("Table 220.54", "Demand factors for household electric clothes dryers", "Number of dryers",
                              [("percent", "Demand factor (%)")], rows, kind="range")

    # Table 220.55: 1-25 appliances are single rows; from 26 up Column C is a
    # formula in a merged cell that also covers the blank rows below it.
    rows = []
    for cells in cache.rows_after("art_220", "Table 220.55", "1", 25):
        n = int(cells[0])
        rows.append({"key": cells[0], "lo": n, "hi": n, "col_a": num(cells[1]), "col_b": num(cells[2]),
                     "col_c": num(cells[3])})
    formula = None
    for cells in cache.rows_after("art_220", "Table 220.55", "26—30", 5):
        lo, hi = _range(cells[0])
        text = cells[3].strip() if len(cells) > 3 else ""
        if text:
            m = re.fullmatch(r"(\d+) kW \+ ([\d/]+) kW for each range", text)
            if not m:
                raise ValueError(f"Table 220.55 Column C formula reads {text!r}")
            per = m.group(2)
            per_value = int(per.split("/")[0]) / int(per.split("/")[1]) if "/" in per else int(per)
            formula = (f"{m.group(1)} + {per_value} * n", text)
        rows.append({"key": cells[0].replace("—", "–"), "lo": lo, "hi": hi, "col_a": num(cells[1]),
                     "col_b": num(cells[2]), "col_c_expr": formula[0], "col_c_label": formula[1]})
    tables["t220_55"] = table("Table 220.55", "Household cooking appliances over 1¾ kW: demand factors and loads",
                              "Number of appliances",
                              [("col_a", "Column A, less than 3½ kW (%)"), ("col_b", "Column B, 3½–8¾ kW (%)"),
                               ("col_c", "Column C, not over 12 kW (kW)")], rows)

    # Table 240.6(A)
    ratings = []
    for cells in cache.block("art_240", "Table 240.6(A)", 9)[1:9]:
        ratings += [num(c) for c in cells if num(c) is not None]
    tables["t240_6a"] = table("Table 240.6(A)", "Standard ampere ratings for fuses and inverse time circuit breakers",
                              "Rating (A)", [("amps", "Standard rating (A)")],
                              [{"key": str(r), "amps": r} for r in ratings], kind="list")

    # Table 250.66
    rows = []
    for cells in cache.block("art_250", "Table 250.66", 9)[2:9]:
        rows.append({"key": cells[0], "al_range": cells[1], "cu_gec": cells[2], "al_gec": cells[3]})
    order = ["2 or smaller", "1 or 1/0", "2/0 or 3/0", "Over 3/0 through 350", "Over 350 through 600",
             "Over 600 through 1100", "Over 1100"]
    if [r["key"] for r in rows] != order:
        raise ValueError(f"Table 250.66 rows read {[r['key'] for r in rows]}")
    limits = ["2", "1/0", "3/0", "350", "600", "1100", None]
    for row, limit in zip(rows, limits):
        row["cu_max"] = limit
    tables["t250_66"] = table("Table 250.66", "Grounding electrode conductor for ac systems",
                              "Largest ungrounded conductor, copper (AWG/kcmil)",
                              [("cu_gec", "Copper GEC"), ("al_gec", "Aluminum GEC")], rows)

    # Table 250.122
    rows = []
    for cells in cache.block("art_250", "Table 250.122", 21)[2:21]:
        rows.append({"key": cells[0], "amps": num(cells[0]), "cu": cells[1].strip(), "al": cells[2].strip()})
    tables["t250_122"] = table("Table 250.122", "Minimum size equipment grounding conductors",
                               "Overcurrent device, not exceeding (A)", [("cu", "Copper"), ("al", "Aluminum")], rows,
                               kind="at_most")

    # Table 430.248
    rows = []
    for cells in cache.block("art_430", "Table 430.248", 14)[2:14]:
        rows.append({"key": fix_fraction(cells[0]), "v115": num(cells[1]), "v200": num(cells[2]),
                     "v208": num(cells[3]), "v230": num(cells[4])})
    tables["t430_248"] = table("Table 430.248", "Full-load currents, single-phase ac motors", "Horsepower",
                               [("v115", "115 V"), ("v200", "200 V"), ("v208", "208 V"), ("v230", "230 V")], rows,
                               unit="A")

    # Table 430.250 (induction type)
    rows = []
    for cells in cache.block("art_430", "Table 430.250", 30)[3:30]:
        vals = [num(c) for c in cells[1:8]]
        rows.append({"key": fix_fraction(cells[0]), "v115": vals[0], "v200": vals[1], "v208": vals[2],
                     "v230": vals[3], "v460": vals[4], "v575": vals[5], "v2300": vals[6]})
    tables["t430_250"] = table("Table 430.250", "Full-load current, three-phase ac motors (induction type)", "Horsepower",
                               [("v115", "115 V"), ("v200", "200 V"), ("v208", "208 V"), ("v230", "230 V"),
                                ("v460", "460 V"), ("v575", "575 V"), ("v2300", "2300 V")], rows, unit="A")

    # Table 430.52(C)(1)
    rows = []
    keys = ["single_phase", "polyphase", "squirrel_cage", "design_b_ee", "synchronous", "wound_rotor", "dc"]
    for key, cells in zip(keys, cache.block("art_430", "Table 430.52(C)(1)", 9)[2:9]):
        rows.append({"key": key, "label": re.sub(r"\d$", "", cells[0].strip()), "nontime_fuse": num(cells[1]), "dual_fuse": num(cells[2]),
                     "inst_breaker": num(cells[3]), "inverse_breaker": num(cells[4])})
    tables["t430_52c1"] = table("Table 430.52(C)(1)", "Maximum rating or setting of motor branch-circuit short-circuit and ground-fault protective devices",
                                "Type of motor", [("nontime_fuse", "Nontime-delay fuse (%)"),
                                                  ("dual_fuse", "Dual-element (time-delay) fuse (%)"),
                                                  ("inst_breaker", "Instantaneous-trip breaker (%)"),
                                                  ("inverse_breaker", "Inverse time breaker (%)")], rows)

    # Table 630.31(A)
    rows = []
    for cells in cache.block("art_630", "Table 630.31(A)", 10)[1:10]:
        key = cells[0].replace(" or less", "")
        rows.append({"key": key, "multiplier": num(cells[1])})
    tables["t630_31a"] = table("Table 630.31(A)", "Duty cycle multiplication factors for resistance welders",
                               "Duty cycle (%)", [("multiplier", "Multiplier")], rows)

    values = {}
    for key, (name, pattern, value) in RULES.items():
        if not re.search(pattern, cache.text(name)):
            raise ValueError(f"rule {key}: evidence {pattern!r} not found in {name}")
        values[key] = value

    return {
        "edition": year,
        "code": "NFPA 70",
        "note": "Values only, read from the NFPA 70 text by tools/math/nec_tables_from_cache.py. "
                "Re-verify every value against the new edition before switching.",
        "tables": tables,
        "values": values,
    }


def _range(text: str):
    text = text.replace("—", "-").replace("–", "-").strip()
    if text.endswith("or less"):
        return -1000, int(text.split()[0])
    if "and" in text or "over" in text.lower():
        return int(re.match(r"\d+", text).group(0)), 100000
    if text.isdigit():
        return int(text), int(text)
    lo, hi = text.split("-")
    return int(lo), int(hi)


def _inch_label(inches: str, mm: str) -> str:
    """'(4 × 11/4)' -> '4 x 1-1/4 in.'; the 65 mm device box is 2-1/2 in. deep (the cache misprints it)."""
    parts = [fix_fraction(p) for p in inches.strip("()").replace("× ", "×").replace(" ×", "×").split("×")]
    parts = [re.sub(r"^(\d)(\d)(\d/\d)$", r"\1\2-\3", p) for p in parts]
    parts = [re.sub(r"^(\d)(\d\d/\d\d)$", r"\1-\2", p) for p in parts]
    if mm.strip() == "75 × 50 × 65":
        parts[-1] = "2-1/2"
    return " × ".join(parts) + " in."


def _thw_rows(lines: list[str]):
    small = {"14": "TW, XF, XFF, THHW, THW,", "12": "TW, THHW, THW, THW-2\t12"}
    out = []
    i = next(i for i, line in enumerate(lines) if line.startswith("THW-2\t14"))
    out.append(("14", lines[i].split("\t")[1:]))
    j = next(i for i, line in enumerate(lines) if line.startswith(small["12"]))
    out.append(("12", lines[j].split("\t")[1:]))
    for line in lines[j + 1:j + 3]:
        cells = line.split("\t")
        out.append((cells[0], cells))
    k = next(i for i, line in enumerate(lines) if line.startswith("RHH*, RHW*, RHW-2*\t6"))
    out.append(("6", lines[k].split("\t")[1:]))
    for line in lines[k + 1:k + 30]:
        cells = line.split("\t")
        if len(cells) != 5 or cells[0] not in SIZES_AWG:
            break
        out.append((cells[0], cells))
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--year", default="2023")
    ap.add_argument("--cache")
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()
    folder = Path(args.cache or os.environ.get("NEC_CACHE") or Path.home() / "Documents" / f"nec{args.year}_cache")
    out_path = ROOT / "data" / "nec" / args.year / "tables.json"
    if not folder.exists():
        print(f"SKIPPED: no NEC text cache at {folder}")
        return 0
    data = build(Cache(folder), args.year)
    text = json.dumps(data, indent=1, ensure_ascii=False) + "\n"
    if args.check:
        current = out_path.read_text(encoding="utf-8") if out_path.exists() else ""
        if current != text:
            print(f"DIFFERS: {out_path} does not match the cache; rerun without --check and review the diff")
            return 1
        print(f"OK: {out_path.relative_to(ROOT)} matches the cache ({len(data['tables'])} tables, {len(data['values'])} values)")
        return 0
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(text, encoding="utf-8")
    print(f"wrote {out_path.relative_to(ROOT)}: {len(data['tables'])} tables, {len(data['values'])} values")
    return 0


if __name__ == "__main__":
    sys.exit(main())
