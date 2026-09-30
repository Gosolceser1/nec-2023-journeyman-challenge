"""Load calculations and circuit sizing: floor area, ampacity, service and branch-circuit ratings, demand."""
from nec_style import *  # noqa: F401,F403


def _card(f, x, y, w, h, title):
    f.rect(x, y, w, h, fill=PANEL, stroke=EDGE, sw=SW_THIN, rx=8)
    f.text(x + 14, y + 30, title, T_NOTE, TEXT, "start", True)


def _ocpd(f, x, y, w=56, h=64, label=None):
    """Breaker/OCPD body with a handle, top-left at (x, y)."""
    f.rect(x, y, w, h, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=5)
    f.rect(x + w * 0.3, y + h * 0.25, w * 0.4, h * 0.5, fill=EDGE, stroke=TEXT, sw=SW_THIN, rx=3)
    if label:
        f.text(x + w / 2, y - 12, label, T_LABEL, TEXT, bold=True)


def _building(f, x, y, w, h, label):
    """Small elevation of a building: walls and a pitched roof."""
    f.rect(x, y, w, h, fill=PANEL, stroke=EDGE, sw=SW_OBJ)
    f.polyline([(x - 8, y), (x + w / 2, y - h * 0.4), (x + w + 8, y)], LINE, SW_OBJ)
    f.text(x + w / 2, y + h + 26, label, T_NOTE, TEXT, bold=True)


@figure("floor_area_220-5c", h=500, nec="220.5(C)",
        records={"open-book-exam-#1-003": {}, "open-book-exam-#10-002": {},
                 "final-exam-#4-052": {"like": "open-book-exam-#1-003"}})
def floor_area(f):
    faces = ["open-book-exam-#1-003"]
    counts = ["open-book-exam-#10-002"]
    f.title("Dwelling floor area for the load calculation (plan, not to scale)", y=34)
    wt = 14
    hx0, hy0, hx1, hy1 = 90, 130, 470, 340
    gx1 = 690
    # Outer walls of the house and the attached garage (drawn as thick bands).
    f.rect(hx0, hy0, gx1 - hx0, hy1 - hy0, fill=PANEL_2, stroke=LINE, sw=SW_THIN)
    f.rect(hx0 + wt, hy0 + wt, hx1 - hx0 - 1.5 * wt, hy1 - hy0 - 2 * wt, fill=PANEL, stroke=LINE, sw=SW_THIN)
    f.rect(hx1 + wt / 2, hy0 + wt, gx1 - hx1 - 1.5 * wt, hy1 - hy0 - 2 * wt, fill=PANEL, stroke=LINE, sw=SW_THIN)
    f.text(300, 236, "living area", T_LABEL, TEXT, bold=True)
    f.text(580, 208, "attached", T_LABEL, TEXT, bold=True)
    f.text(580, 236, "garage", T_LABEL, TEXT, bold=True)
    # Unfinished space in one corner.
    f.hatch(hx0 + wt, hy0 + wt, 130, 90, EDGE, op=0.22)
    f.lines(hx0 + wt + 65, hy0 + wt + 36, ["unfinished,", "not adaptable"], T_MIN, TEXT, bold=True, gap=1.1)
    # Open porch: slab outline, no walls.
    px0, px1, py1 = 210, 420, 410
    f.dline(px0, hy1, px0, py1, LINE, SW_OBJ)
    f.dline(px0, py1, px1, py1, LINE, SW_OBJ)
    f.dline(px1, py1, px1, hy1, LINE, SW_OBJ)
    f.text((px0 + px1) / 2, 384, "open porch", T_LABEL, TEXT, bold=True)
    # Which faces the dimensions run to (the #1-003 answer).
    f.ext(hx0, hy0 - 4, hx0, 72)
    f.ext(gx1, hy0 - 4, gx1, 72)
    f.dim_h(hx0, gx1, 82)
    f.value(390, 112, "outside faces: yes", 26, records=faces, what="dimensions run to the outside faces")
    f.dim_v(440, hy0 + wt, hy1 - wt)
    f.value(428, 300, "inside faces: no", T_NOTE, NO, anchor="end", records=faces, pad=6,
            what="the inside-face dimension marked wrong")
    # What counts toward the dwelling floor area (the #10-002 answer).
    f.value(580, 290, "counted", 26, records=counts, label="?", what="garage counted (2023)")
    f.value(315, 440, "not counted", 26, NO, records=counts, label="?", what="open porch not counted")
    f.value(hx0 + wt + 65, hy0 + wt + 118, "not counted", T_NOTE, NO, records=counts, label="?",
            what="unfinished space not counted")
    f.tag(f.w - 24, f.h - 14, "NEC 220.5(C)", anchor="end")


@figure("ampacity_derating_310-15", h=520, nec="310.15(B), 310.15(C)(1), 310.15(F), Table 310.16",
        records={"final-exam-#1-014": {}, "final-exam-#1-027": {}, "final-exam-#3-057": {"terms": ["not counted"]},
                 "open-book-exam-#2-012": {"like": "final-exam-#1-014"},
                 "open-book-exam-#3-010": {"like": "final-exam-#1-027"}})
def ampacity_derating(f):
    calc = ["final-exam-#1-014", "final-exam-#1-027"]
    egc = ["final-exam-#3-057"]
    f.title("Ampacity: table value, then the two factors", y=34)
    # Raceway cross-section.
    cx, cy, r = 150, 200, 96
    f.circle(cx, cy, r, fill=PANEL, stroke=LINE, sw=SW_STRUCT)
    for dx, dy in ((-38, -34), (22, -44), (-44, 26), (18, 16)):
        f.circle(cx + dx, cy + dy, 22, fill=WIRE_NEU, stroke=BG, sw=SW_THIN)
    f.circle(cx + 50, cy + 52, 14, fill=WIRE_GND, stroke=BG, sw=SW_THIN)
    f.text(cx, 68, "raceway, cut open", T_NOTE, MUTED)
    f.lines(cx, 330, ["circuit conductors:", "count them"], T_NOTE, TEXT, bold=True)
    f.text(cx - 76, 398, "EGC:", T_NOTE, WIRE_GND, "start", True)
    f.value(cx - 18, 398, "not counted", T_NOTE, anchor="start", records=egc, pad=6,
            what="EGC not counted (310.15(F))")
    f.leader(cx + 20, 380, cx + 50, cy + 66, WIRE_GND)
    # Two worked columns.
    x0, x1, xa, xb = 290, 785, 540, 690
    f.rect(x0, 60, x1 - x0, 420, fill=PANEL, stroke=EDGE, sw=SW_THIN, rx=8)
    f.lines(xa, 92, ["#12 THWN", "86 F, 4 CCC"], T_NOTE, TEXT, bold=True, gap=1.15)
    f.lines(xb, 92, ["#10 THWN-2", "112 F, 3 CCC"], T_NOTE, TEXT, bold=True, gap=1.15)
    rows = [("column", ["75 C", "90 C"], False), ("Table 310.16", ["25 A", "40 A"], True),
            ("x ambient factor", ["1.00", "0.87"], True), ("x count factor", ["0.80", "1.00"], True),
            ("= ampacity", ["20 A", "34.8 A"], True)]
    for i, (name, vals, hide) in enumerate(rows):
        y = 170 + i * 56
        f.line(x0 + 10, y - 34, x1 - 10, y - 34, EDGE, 1)
        f.text(x0 + 14, y, name, T_NOTE, MUTED, "start", i == 4)
        for x, v in zip((xa, xb), vals):
            if hide:
                f.value(x, y, v, 26, records=calc, pad=6)
            else:
                f.text(x, y, v, 26, DIM, bold=True)
    f.text(x0 + 14, 428, "ambient: Table 310.15(B)(1)(1)", T_MIN, MUTED, "start")
    f.text(x0 + 14, 456, "count: Table 310.15(C)(1)", T_MIN, MUTED, "start")
    f.tag(f.w - 24, f.h - 10, "NEC 310.15, Table 310.16", anchor="end")


@figure("dwelling_service_310-12", h=450, nec="310.12, 310.12(A)",
        records={"final-exam-#1-036": {}, "open-book-exam-#4-022": {},
                 "final-exam-#3-065": {"terms": ["single-phase", "120/240"]}})
def dwelling_service(f):
    pct = ["final-exam-#1-036", "open-book-exam-#4-022"]
    where = ["final-exam-#3-065"]
    f.title("Service conductor sizing (one-line)", y=34)
    y = 170
    # Utility transformer.
    for dy in (-18, 18):
        f.circle(70, y + dy, 20, fill="none", stroke=TEXT, sw=SW_OBJ)
    f.text(70, y + 72, "utility", T_NOTE, MUTED)
    for k, yy in enumerate((y - 10, y, y + 10)):
        f.line(92, yy, 280, yy, WIRE_NEU if k == 1 else WIRE_HOT, SW_WIRE - 1)
    f.value_lines(186, 92, ["120/240 V,", "single-phase, 3-wire"], T_NOTE, TEXT, records=where, pad=6,
                  what="the system the table is for")
    # Meter and 200 A service disconnect.
    f.circle(305, y, 26, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ)
    f.text(305, y + 60, "meter", T_NOTE, MUTED)
    for yy in (y - 10, y, y + 10):
        f.line(331, yy, 420, yy, WIRE_HOT, SW_WIRE - 1)
    _ocpd(f, 420, y - 34, 64, 68, "200 A")
    f.text(452, y + 62, "service", T_NOTE, MUTED)
    f.line(484, y, 560, y, WIRE_HOT, SW_WIRE)
    _building(f, 560, y - 60, 180, 150, "")
    f.value_lines(650, y + 20, ["individual", "dwelling unit"], T_NOTE, TEXT, records=where, pad=6,
                  what="the occupancy the table is for")
    # The 83 percent rule.
    _card(f, 30, 290, 740, 126, "Service conductors carrying the entire load, 100-400 A")
    b = f.text(44, 360, "ampacity not less than", 26, TEXT, "start")
    f.value(b[0] + b[2] + 12, 360, "83% x 200 A = 166 A", 26, anchor="start", records=pct, pad=6)
    f.text(44, 398, "size from Table 310.12(A) when no correction or adjustment applies", T_MIN, MUTED, "start")
    f.tag(f.w - 24, f.h - 10, "NEC 310.12(A)", anchor="end")


@figure("branch_circuit_rating_210", h=500, nec="210.18, 210.19(B), Table 210.21(B)(2)",
        records={"final-exam-#1-059": {"terms": ["OCPD rating"]}, "final-exam-#3-014": {},
                 "open-book-exam-#7-011": {"terms": ["not less than", ">="]},
                 "open-book-exam-#6-024": {"like": "final-exam-#1-059"},
                 "final-exam-#2-038": {"like": "final-exam-#1-059"},
                 "open-book-exam-#9-012": {"like": "final-exam-#1-059"},
                 "open-book-exam-#9-018": {"when": "after"}})
def branch_circuit_rating(f):
    rating = ["final-exam-#1-059"]
    cord = ["final-exam-#3-014"]
    wire = ["open-book-exam-#7-011"]
    f.title("20 A multioutlet circuit, 15 A duplex receptacles", y=34)
    f.panel(30, 70, 120, 190, label="", breakers=0)
    f.text(90, 286, "panel", T_NOTE, MUTED)
    _ocpd(f, 62, 150, 56, 64)
    f.text(90, 136, "20 A", T_LABEL, TEXT, bold=True)
    y = 182
    f.line(118, y, 700, y, WIRE_HOT, SW_WIRE)
    f.line(118, y + 16, 700, y + 16, WIRE_NEU, SW_WIRE)
    for x in (330, 500, 670):
        f.line(x - 8, y, x - 8, y + 44, WIRE_HOT, 3)
        f.line(x + 8, y + 16, x + 8, y + 44, WIRE_NEU, 3)
        f.receptacle(x, y + 70, 56)
        f.text(x, y + 132, "15 A", T_NOTE, TEXT, bold=True)
    # Cord-and-plug load on the last receptacle.
    f.path(f"M 684 {y + 80} C 730 {y + 110}, 740 {y + 130}, 740 {y + 170}", TEXT, 4)
    f.rect(716, y + 170, 48, 34, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=5)
    f.text(708, y + 194, "tool", T_MIN, MUTED, "end")
    f.text(420, y - 18, "#12 Cu conductors", T_NOTE, TEXT, bold=True)
    # Three tags.
    f.value_lines(100, 350, ["circuit rating =", "OCPD rating"], T_NOTE, records=rating, pad=6, gap=1.15)
    f.leader(100, 328, 90, 300)
    f.value_lines(230, 404, ["conductor ampacity", ">= 20 A rating"], T_NOTE, records=wire, pad=6, gap=1.15)
    f.leader(230, 382, 250, y + 18)
    f.value(560, 412, "cord-and-plug load: 12 A max", T_NOTE, records=cord, pad=6)
    f.leader(640, 392, 716, y + 200)
    f.tag(f.w - 24, f.h - 10, "NEC 210.18, 210.19, 210.21", anchor="end")


@figure("outbuilding_disconnect_225-39", h=490, nec="225.39, 225.39(A)-(D)",
        records=["final-exam-#3-024", "final-exam-#3-056", "open-book-exam-#7-009"])
def outbuilding_disconnect(f):
    calc = ["open-book-exam-#7-009"]
    f.title("Building disconnect fed from another building: minimum rating", y=34)
    cols = [(20, "one branch circuit,", "limited loads", "15 A min"),
            (280, "two 2-wire", "branch circuits", "30 A min")]
    for x, t1, t2, v in cols:
        _card(f, x, 60, 240, 320, "")
        f.lines(x + 120, 94, [t1, t2], T_NOTE, TEXT, bold=True, gap=1.15)
        _building(f, x + 70, 190, 100, 80, "")
        f.rect(x + 100, 212, 40, 44, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=4)
        f.line(x + 140, 222, x + 154, 206, TEXT, 5)
        f.value(x + 120, 330, v, 28, what=f"'{v}'")
    _card(f, 540, 60, 240, 320, "")
    f.lines(660, 94, ["feeder"], T_NOTE, TEXT, bold=True)
    _building(f, 610, 190, 100, 80, "")
    f.rect(640, 212, 40, 44, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=4)
    f.line(680, 222, 694, 206, TEXT, 5)
    f.text(660, 318, "60 A min", 28, DIM, bold=True)
    f.lines(660, 342, ["one-family", "dwelling: 100 A"], T_MIN, MUTED, gap=1.05)
    b = f.text(30, 424, "Every case: rating not less than the", 26, TEXT, "start")
    f.value(b[0] + b[2] + 10, 424, "calculated", 26, anchor="start", records=calc, pad=6)
    f.text(30, 460, "load (Article 220)", 26, TEXT, "start")
    f.tag(f.w - 24, f.h - 12, "NEC 225.39", anchor="end")


def _dryer(f, x, y, s=44):
    f.rect(x, y, s, s, fill=PANEL_2, stroke=TEXT, sw=SW_THIN, rx=4)
    f.circle(x + s / 2, y + s * 0.58, s * 0.28, fill="none", stroke=TEXT, sw=SW_THIN)


def _range(f, x, y, s=64):
    f.rect(x, y, s, s, fill=PANEL_2, stroke=TEXT, sw=SW_THIN, rx=4)
    for dx in (0.3, 0.7):
        for dy in (0.3, 0.62):
            f.circle(x + s * dx, y + s * dy, s * 0.12, fill="none", stroke=TEXT, sw=SW_THIN)


@figure("appliance_demand_220-54_220-55", h=486, nec="Table 220.54, Table 220.55 and Note 1",
        records={"final-exam-#1-040": {}, "open-book-exam-#4-015": {}, "final-exam-#1-021": {},
                 "open-book-exam-#3-019": {"like": "final-exam-#1-021"}})
def appliance_demand(f):
    f.title("Dwelling appliance demand (worked cards)", y=34)
    _card(f, 20, 56, 370, 390, "Clothes dryers, Table 220.54")
    for k in range(5):
        _dryer(f, 40 + k * 66, 110)
    f.lines(34, 200, ["5 dryers x 5 kW = 25 kW", "(5 kW each, or the nameplate", "if larger)"], T_NOTE,
            TEXT, "start", gap=1.2)
    f.text(34, 306, "demand factor, 5 dryers:", T_NOTE, MUTED, "start")
    f.value(34, 346, "85%", 30, anchor="start")
    f.value(34, 408, "25 kW x 0.85 = 21.25 kW", 26, anchor="start")
    _card(f, 410, 56, 370, 390, "One range, Table 220.55")
    _range(f, 430, 100)
    f.lines(510, 124, ["14 kW range", "Column C: 8 kW"], T_NOTE, TEXT, "start", bold=True, gap=1.2)
    f.lines(424, 212, ["Note 1: over 12 kW, add 5%", "per kW (or major fraction)"], T_NOTE, TEXT,
            "start", gap=1.2)
    f.text(424, 306, "14 - 12 = 2 kW over:", T_NOTE, MUTED, "start")
    f.value(424, 346, "+10%", 30, anchor="start")
    f.value(424, 408, "8 kW x 1.10 = 8.8 kW", 26, anchor="start")
    f.tag(f.w - 24, f.h - 10, "NEC 220.54, 220.55", anchor="end")
