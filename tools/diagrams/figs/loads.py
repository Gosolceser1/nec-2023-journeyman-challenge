"""Load calculations and circuit sizing: floor area, ampacity, service and branch-circuit ratings, demand."""
from nec_style import *  # noqa: F401,F403


def _building(f, x, y, w, h, label):
    """Small elevation of a building: walls and a pitched roof."""
    f.rect(x, y, w, h, fill=PANEL, stroke=EDGE, sw=SW_OBJ)
    f.polyline([(x - 8, y), (x + w / 2, y - h * 0.4), (x + w + 8, y)], LINE, SW_OBJ)
    f.text(x + w / 2, y + h + 26, label, T_NOTE, TEXT, bold=True)


@figure("floor_area_220-5c", h=500, nec="220.5(C)",
        records={"open-book-exam-#1-003": {}, "open-book-exam-#10-002": {},
                 "final-exam-#4-052": {"like": "open-book-exam-#1-003"},
                 "final-exam-#4-027": {"when": "after"}})
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
    f.text(330, 236, "living area", T_LABEL, TEXT, bold=True)
    f.text(580, 208, "attached", T_LABEL, TEXT, bold=True)
    f.text(580, 236, "garage", T_LABEL, TEXT, bold=True)
    # Unfinished space in one corner.
    f.hatch(hx0 + wt, hy0 + wt, 146, 90, EDGE, op=0.22)
    f.lines(hx0 + wt + 73, hy0 + wt + 36, ["unfinished,", "not adaptable"], T_MIN, TEXT, bold=True, gap=1.1)
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
    f.value(hx0 + wt + 73, hy0 + wt + 118, "not counted", T_NOTE, NO, records=counts, label="?",
            what="unfinished space not counted")
    f.tag(f.w - 24, f.h - 14, "NEC 220.5(C)", anchor="end")


def _raceway_section(f, cx, cy, r, ccc, egc=True):
    """Raceway cut open: `ccc` circuit conductors (3 or 4) and, optionally, a green EGC.
    Returns the EGC's centre."""
    spots = {3: ((-34, -30), (30, -30), (-2, 26)), 4: ((-38, -34), (22, -44), (-44, 26), (18, 16))}[ccc]
    k = r / 96
    f.circle(cx, cy, r, fill=PANEL, stroke=LINE, sw=SW_STRUCT)
    for dx, dy in spots:
        f.circle(cx + dx * k, cy + dy * k, 22 * k, fill=WIRE_NEU, stroke=BG, sw=SW_THIN)
    gx, gy = cx + 50 * k, cy + 52 * k
    if egc:
        f.circle(gx, gy, 14 * k, fill=WIRE_GND, stroke=BG, sw=SW_THIN)
    return gx, gy


def _ampacity_card(f, heading, rows, tag):
    """One worked ampacity column beside a raceway: rows of (step, value, hidden)."""
    x0, x1, xv = 300, 780, 690
    f.card(x0, 60, x1 - x0, 340)
    f.text(x0 + 16, 96, heading, T_LABEL, TEXT, "start", True)
    for i, (name, v, hide) in enumerate(rows):
        y = 160 + i * 54
        f.line(x0 + 10, y - 34, x1 - 10, y - 34, EDGE, 1)
        f.text(x0 + 16, y, name, T_NOTE, MUTED, "start", i == len(rows) - 1)
        if hide:
            f.value(xv, y, v, 26, pad=6)
        else:
            f.text(xv, y, v, 26, DIM, bold=True)
    f.tag(f.w - 24, f.h - 12, tag, anchor="end")


@figure("ampacity_12thwn_310-16", h=470, nec="Table 310.16",
        records={"final-exam-#1-014": {}, "open-book-exam-#2-012": {"like": "final-exam-#1-014"}})
def ampacity_12thwn(f):
    f.title("#12 THWN, 86 F, four current-carrying conductors", y=34)
    gx, gy = _raceway_section(f, 150, 210, 96, 4)
    f.text(150, 84, "raceway, cut open", T_NOTE, MUTED)
    f.lines(150, 360, ["4 circuit", "conductors"], T_NOTE, TEXT, bold=True)
    _ampacity_card(f, "#12 THWN", [("column", "75 C", False), ("table ampacity", "25 A", True),
                                   ("x ambient factor", "1.00", True), ("x count factor", "0.80", True),
                                   ("= ampacity", "20 A", True)], "NEC Table 310.16")


@figure("ampacity_10thwn2_310-15b", h=470, nec="Table 310.15(B)(1)(1)",
        records={"final-exam-#1-027": {}, "open-book-exam-#3-010": {"like": "final-exam-#1-027"}})
def ampacity_10thwn2(f):
    f.title("Three #10 THWN-2 conductors, 112 F ambient", y=34)
    _raceway_section(f, 150, 210, 96, 3, egc=False)
    f.text(150, 84, "raceway, cut open", T_NOTE, MUTED)
    f.lines(150, 360, ["3 circuit", "conductors"], T_NOTE, TEXT, bold=True)
    _ampacity_card(f, "#10 THWN-2", [("column", "90 C", False), ("table ampacity", "40 A", True),
                                     ("x ambient factor", "0.87", True), ("x count factor", "1.00", True),
                                     ("= ampacity", "34.8 A", True)], "NEC Table 310.15(B)(1)(1)")


@figure("ccc_count_310-15f", h=450, nec="310.15(F)",
        records={"final-exam-#3-057": {"terms": ["not counted"]}})
def ccc_count(f):
    f.title("Raceway cut open: which conductors are counted?", y=34)
    gx, gy = _raceway_section(f, 300, 230, 140, 4)
    f.lines(600, 150, ["circuit conductors:", "count them"], T_LABEL, TEXT, bold=True)
    f.leader(520, 170, 300 - 38 * 140 / 96 + 22, 230 - 34 * 140 / 96)
    f.text(560, 340, "EGC:", T_LABEL, WIRE_GND, "start", True)
    f.value(626, 340, "not counted", T_LABEL, anchor="start", pad=6, what="EGC not counted")
    f.leader(552, 332, gx + 18, gy + 6, WIRE_GND)
    f.tag(f.w - 24, f.h - 12, "NEC 310.15(F)", anchor="end")


@figure("dwelling_service_310-12", h=450, nec="310.12(A)",
        records={"final-exam-#1-036": {}, "open-book-exam-#4-022": {},
                 "final-exam-#3-065": {"terms": ["single-phase", "120/240"]}})
def dwelling_service(f):
    pct = ["final-exam-#1-036", "open-book-exam-#4-022"]
    where = ["final-exam-#3-065"]
    f.title("Service conductor sizing (elevation, not to scale)", y=34)
    gy = 272
    f.grade(gy, 20, 780, label=None)
    # Utility pole with its pole-top transformer.
    px = 60
    f.line(px, gy, px, 64, WOOD, 12)
    f.line(px - 30, 78, px + 30, 78, WOOD, 7)
    f.transformer(px + 14, 110, 44, 62, kind="pole")
    f.text(px + 36, 206, "utility", T_NOTE, MUTED)
    # House: roof, wall, service mast with weatherhead.
    hx0, hx1, wtop = 420, 770, 160
    f.rect(hx0, wtop, hx1 - hx0, gy - wtop, fill=PANEL, stroke=LINE, sw=SW_OBJ)
    f.polyline([(hx0 - 14, wtop), ((hx0 + hx1) / 2, 74), (hx1 + 10, wtop)], LINE, SW_OBJ)
    mx, my = 462, 104
    f.conduit(mx, my + 8, mx, 186, 10, couplings=())
    f.path(f"M {mx - 9} {my + 10} Q {mx} {my - 6} {mx + 13} {my + 4}", TEXT, 5)
    # Service drop, three conductors sagging from the transformer to the weatherhead.
    for k, dy in enumerate((-6, 0, 6)):
        f.path(f"M {px + 58} {128 + dy} Q 270 {176 + dy} {mx - 6} {my + 8 + dy * 0.5}",
               WIRE_NEU if k == 1 else WIRE_HOT, 3)
    f.value_lines(256, 214, ["120/240 V,", "single-phase, 3-wire"], T_NOTE, TEXT, records=where, pad=6,
                  what="the system the table is for")
    # Meter on the outside wall, 200 A main inside.
    f.meter(mx, 218, 18)
    f.text(mx, 266, "meter", T_MIN, MUTED)
    f.panel(536, 168, 64, 96, label=None, breakers=2, main=True)
    f.line(mx + 21, 214, 536, 214, WIRE_HOT, SW_WIRE - 1)
    f.text(568, 156, "200 A main", T_NOTE, TEXT, bold=True)
    f.value_lines(690, 206, ["individual", "dwelling unit"], T_NOTE, TEXT, records=where, pad=6,
                  what="the occupancy the table is for")
    # The 83 percent rule.
    f.card(30, 290, 740, 126, "Service conductors carrying the entire load, 100-400 A")
    b = f.text(44, 360, "ampacity not less than", 26, TEXT, "start")
    f.value(b[0] + b[2] + 12, 360, "83% x 200 A = 166 A", 26, anchor="start", records=pct, pad=6)
    f.text(44, 398, "size from Table 310.12(A) when no correction or adjustment applies", T_MIN, MUTED, "start")
    f.tag(f.w - 24, f.h - 10, "NEC 310.12(A)", anchor="end")


def _drill(f, x, y):
    """Corded drill, side view, chuck to the left: (x, y) is the top-left of the chuck end."""
    f.line(x - 14, y + 14, x + 6, y + 14, LINE, 3)
    f.rect(x + 2, y + 6, 18, 16, fill=STEEL, stroke=TEXT, sw=1.5, rx=3)
    f.poly([(x + 50, y + 24), (x + 72, y + 24), (x + 70, y + 64), (x + 52, y + 64)], PANEL_2, TEXT, SW_THIN)
    f.rect(x + 18, y, 74, 28, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=10)
    for k in range(3):
        f.line(x + 72 + k * 6, y + 7, x + 72 + k * 6, y + 21, EDGE, 2)
    f.rect(x + 44, y + 30, 6, 12, fill=TEXT, rx=2)


def _multioutlet_circuit(f, rating=None, receptacle=None, drill=True):
    """A panel feeding three duplex receptacles; `rating` labels the breaker,
    `receptacle` each receptacle. Returns the run's y."""
    f.panel(30, 70, 120, 190, label=None, breakers=0)
    f.breaker(66, 136, 48, 70)
    if rating:
        f.text(90, 124, rating, T_LABEL, TEXT, bold=True)
    f.rect(48, 230, 84, 12, fill=STEEL, stroke=TEXT, sw=1.5, rx=2)
    for k in range(5):
        f.circle(58 + k * 16, 236, 3, fill=CLAMP)
    y = 171
    f.line(114, y, 700, y, WIRE_HOT, SW_WIRE)
    f.polyline([(132, 236), (140, 236), (140, y + 16), (700, y + 16)], WIRE_NEU, SW_WIRE)
    for x in (330, 500, 670):
        f.line(x - 8, y, x - 8, y + 42, WIRE_HOT, 3)
        f.line(x + 8, y + 16, x + 8, y + 42, WIRE_NEU, 3)
        f.receptacle(x, y + 76, 68)
        if receptacle:
            f.text(x, y + 138, receptacle, T_NOTE, TEXT, bold=True)
    if drill:
        py = y + 76 + 68 * 0.23
        f.plug(694, py - 12, 30, 24, facing="left")
        f.path(f"M 724 {py} C 776 {py}, 784 300, 784 350 C 784 392, 762 404, 752 396", TEXT, 5)
        _drill(f, 690, 334)
    return y


@figure("branch_circuit_rating_210-18", h=440, nec="210.18",
        records={"final-exam-#1-059": {"terms": ["OCPD rating"]},
                 "open-book-exam-#6-024": {"like": "final-exam-#1-059"},
                 "final-exam-#2-038": {"like": "final-exam-#1-059"},
                 "open-book-exam-#9-012": {"like": "final-exam-#1-059"},
                 "open-book-exam-#9-018": {"when": "after"}})
def branch_circuit_rating(f):
    f.title("A branch circuit and the device that protects it", y=34)
    _multioutlet_circuit(f, drill=False)
    f.value_lines(90, 318, ["circuit rating =", "OCPD rating"], T_NOTE, pad=6, gap=1.15)
    f.leader(90, 296, 90, 210)
    f.text(500, 330, "receptacles, conductors and loads", T_NOTE, MUTED)
    f.text(500, 358, "on the circuit", T_NOTE, MUTED)
    f.tag(f.w - 24, f.h - 12, "NEC 210.18", anchor="end")


@figure("branch_conductors_210-19", h=470, nec="210.19(B)",
        records={"open-book-exam-#7-011": {"terms": ["not less than", ">="]}})
def branch_conductors(f):
    f.title("Several receptacles for portable tools on one circuit", y=34)
    y = _multioutlet_circuit(f)
    f.text(90, 124, "rating", T_NOTE, TEXT, bold=True)
    f.text(420, y - 18, "branch-circuit conductors", T_NOTE, TEXT, bold=True)
    f.value_lines(256, 400, ["conductor ampacity: not", "less than the rating"], T_NOTE, pad=6, gap=1.15)
    f.leader(256, 378, 256, y + 18)
    f.tag(f.w - 24, f.h - 12, "NEC 210.19(B)", anchor="end")


@figure("receptacle_cord_load_210-21b2", h=470, nec="Table 210.21(B)(2)",
        records=["final-exam-#3-014"])
def receptacle_cord_load(f):
    f.title("20 A multioutlet circuit, 15 A duplex receptacles", y=34)
    _multioutlet_circuit(f, rating="20 A", receptacle="15 A")
    f.value(470, 436, "cord-and-plug load: 12 A max", T_NOTE, pad=6)
    f.leader(620, 416, 700, 370)
    f.tag(30, f.h - 12, "NEC Table 210.21(B)(2)")


def _fed_outbuilding(f, link):
    """Main building on the left feeding a second building on the right through `link`
    (drawn between them); the second building's disconnect is just inside its wall.
    Returns the disconnect's centre."""
    gy = 330
    f.grade(gy, 20, 780, label=None)
    _building(f, 50, 170, 220, gy - 170, "")
    _building(f, 520, 200, 220, gy - 200, "")
    f.text(200, 318, "main building", T_NOTE, TEXT, bold=True)
    f.text(670, 318, "outbuilding", T_NOTE, TEXT, bold=True)
    f.panel(80, 200, 56, 90, label=None, breakers=3)
    f.disconnect(548, 226, 50, 66)
    link(f, 136, 245, 548, 259)
    return 573, 226


def _rating_callout(f, dx, dy, value):
    f.text(640, 398, "building disconnect rating:", T_NOTE, TEXT)
    f.value(640, 440, value, 28, pad=6)
    f.leader(dx, 378, dx, dy + 66)


@figure("outbuilding_one_circuit_225-39a", h=470, nec="225.39(A)", records=["final-exam-#3-056"])
def outbuilding_one_circuit(f):
    f.title("Building supplied by one branch circuit (limited loads)", y=34)

    def link(f, x0, y0, x1, y1):
        f.polyline([(x0, y0), (x0 + 60, y0), (x0 + 60, y1), (x1, y1)], WIRE_HOT, SW_WIRE - 1)
        f.text((x0 + x1) / 2 + 30, y1 - 14, "one branch circuit", T_NOTE, TEXT, bold=True)
    _rating_callout(f, *_fed_outbuilding(f, link), "15 A min")
    f.tag(30, f.h - 12, "NEC 225.39(A)")


@figure("outbuilding_two_circuits_225-39b", h=470, nec="225.39(B)", records=["final-exam-#3-024"])
def outbuilding_two_circuits(f):
    f.title("Building supplied by two 2-wire branch circuits", y=34)

    def link(f, x0, y0, x1, y1):
        for k, dy in enumerate((-10, 10)):
            f.polyline([(x0, y0 + dy), (x0 + 60 + k * 14, y0 + dy), (x0 + 60 + k * 14, y1 + dy), (x1, y1 + dy)],
                       WIRE_HOT, SW_WIRE - 1)
        f.text((x0 + x1) / 2 + 40, y1 - 24, "two 2-wire circuits", T_NOTE, TEXT, bold=True)
    _rating_callout(f, *_fed_outbuilding(f, link), "30 A min")
    f.tag(30, f.h - 12, "NEC 225.39(B)")


@figure("outbuilding_rating_225-39", h=470, nec="225.39", records=["open-book-exam-#7-009"])
def outbuilding_rating(f):
    f.title("Disconnect for a building fed from another building", y=34)

    def link(f, x0, y0, x1, y1):
        f.polyline([(x0, y0), (x0 + 60, y0), (x0 + 60, y1), (x1, y1)], WIRE_HOT, SW_WIRE + 1)
        f.text((x0 + x1) / 2 + 30, y1 - 14, "feeder", T_NOTE, TEXT, bold=True)
    dx, dy = _fed_outbuilding(f, link)
    f.text(640, 398, "rating not less than the", T_NOTE, TEXT)
    v = f.value(548, 436, "calculated", 26, anchor="start", pad=6)
    f.text(v[0] + v[2] + 10, 436, "load", 26, TEXT, "start")
    f.leader(dx, 378, dx, dy + 66)
    f.tag(30, f.h - 12, "NEC 225.39")


def _dryer(f, x, y, w=48, h=60):
    """Front-loading clothes dryer, front view: control strip with a knob, round door."""
    f.rect(x, y, w, h, fill=PANEL_2, stroke=TEXT, sw=SW_THIN, rx=4)
    f.line(x + 2, y + h * 0.22, x + w - 2, y + h * 0.22, EDGE, SW_THIN)
    f.circle(x + w * 0.76, y + h * 0.11, h * 0.055, fill=TEXT)
    f.rect(x + w * 0.14, y + h * 0.07, w * 0.36, h * 0.08, fill=BG, rx=1.5)
    f.circle(x + w / 2, y + h * 0.6, w * 0.3, fill=BG, stroke=TEXT, sw=SW_THIN)
    f.circle(x + w / 2, y + h * 0.6, w * 0.2, fill="none", stroke=EDGE, sw=1.5)


def _range(f, x, y, w=72, h=84):
    """Freestanding electric range, front view: backguard with knobs, cooktop, oven door."""
    f.rect(x, y, w, h * 0.16, fill=PANEL_2, stroke=TEXT, sw=SW_THIN, rx=3)
    for k in range(4):
        f.circle(x + w * (0.2 + 0.2 * k), y + h * 0.08, h * 0.035, fill=TEXT)
    f.rect(x - 2, y + h * 0.16, w + 4, h * 0.06, fill=EDGE, stroke=TEXT, sw=1.5, rx=1.5)
    f.rect(x, y + h * 0.22, w, h * 0.78, fill=PANEL_2, stroke=TEXT, sw=SW_THIN, rx=3)
    f.rect(x + w * 0.16, y + h * 0.3, w * 0.68, h * 0.04, fill=TEXT, rx=1.5)
    f.rect(x + w * 0.14, y + h * 0.42, w * 0.72, h * 0.36, fill=BG, stroke=EDGE, sw=1.5, rx=3)
    f.line(x + 4, y + h * 0.88, x + w - 4, y + h * 0.88, EDGE, 1.5)


@figure("dryer_demand_220-54", h=440, nec="Table 220.54",
        records={"final-exam-#1-040": {}, "open-book-exam-#4-015": {"like": "final-exam-#1-040"}})
def dryer_demand(f):
    f.title("Five household clothes dryers, multifamily dwelling", y=34)
    for k in range(5):
        _dryer(f, 70 + k * 136, 70, 84, 104)
    f.card(40, 210, 720, 190)
    f.lines(60, 250, ["5 dryers x 5 kW = 25 kW", "(5 kW each, or the nameplate if larger)"], T_NOTE, TEXT,
            "start", gap=1.3)
    f.text(60, 336, "demand factor, 5 dryers:", T_NOTE, MUTED, "start")
    f.value(330, 336, "85%", 30, anchor="start")
    f.value(60, 380, "25 kW x 0.85 = 21.25 kW", 26, anchor="start")
    f.tag(f.w - 24, f.h - 12, "NEC Table 220.54", anchor="end")


@figure("range_demand_220-55", h=440, nec="Table 220.55",
        records={"final-exam-#1-021": {}, "open-book-exam-#3-019": {"like": "final-exam-#1-021"}})
def range_demand(f):
    f.title("One 14 kW household range in a dwelling", y=34)
    _range(f, 70, 70, 120, 150)
    f.text(230, 110, "14 kW range", T_LABEL, TEXT, "start", True)
    f.text(230, 141, "Column C: 8 kW", T_LABEL, TEXT, "start", True)
    f.lines(230, 186, ["Note 1: over 12 kW, add 5%", "per kW (or major fraction)"], T_NOTE, TEXT, "start",
            gap=1.25)
    f.card(40, 250, 720, 150)
    f.text(60, 292, "14 - 12 = 2 kW over:", T_NOTE, MUTED, "start")
    f.value(300, 292, "+10%", 30, anchor="start")
    f.value(60, 360, "8 kW x 1.10 = 8.8 kW", 26, anchor="start")
    f.tag(f.w - 24, f.h - 12, "NEC Table 220.55", anchor="end")
