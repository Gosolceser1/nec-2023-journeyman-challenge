"""Special locations and equipment: hazardous classes, antennas, patient beds, signs, busways, burial."""
from nec_style import *  # noqa: F401,F403


def _card(f, x, y, w, h, title=None):
    f.rect(x, y, w, h, fill=PANEL, stroke=EDGE, sw=SW_THIN, rx=8)
    if title:
        f.text(x + w / 2, y + 30, title, T_NOTE, TEXT, bold=True)


@figure("hazardous_classes_500-5", h=576, nec="500.5(B), (C), (D)",
        records={"final-exam-#3-008": {"terms": ["III", "Division 2", "Div. 2"]},
                 "open-book-exam-#10-017": {"terms": ["III"]}, "final-exam-#1-061": {"terms": ["III"]}})
def hazardous_classes(f):
    div = ["final-exam-#3-008"]
    f.title("Hazardous locations: what is in the air decides the class", y=34)
    cards = [(20, "gas or vapor", "I"), (280, "combustible dust", "II"), (540, "ignitible fibers", "III")]
    for x, name, num in cards:
        _card(f, x, 56, 240, 220, name)
        cx, cy = x + 120, 150
        if num == "I":
            for dx, dy, r in ((-30, 6, 26), (0, -12, 32), (32, 4, 24), (4, 22, 22)):
                f.circle(cx + dx, cy + dy, r, fill=PANEL_2, stroke=MUTED, sw=SW_THIN)
        elif num == "II":
            for k in range(26):
                f.circle(cx - 60 + (k * 37) % 120, cy - 34 + (k * 23) % 70, 4, fill=MUTED)
        else:
            for k in range(6):
                f.path(f"M {cx - 70 + k * 10} {cy - 30 + k * 12} q 30 -24 60 0 t 60 0", MUTED, 3)
        b = f.text(cx - 8, 250, "Class", T_LABEL, TEXT, "end", True)
        f.value(cx + 2, 250, num, T_LABEL, anchor="start", records=None, pad=6, what=f"class for {name}")
    # Textile mill plan: processing room next to bale storage.
    f.text(400, 316, "Textile mill (fibers everywhere)", T_NOTE, TEXT, bold=True)
    for x, w, lines_, d in ((20, 370, ["carding and spinning:", "fibers handled while", "being manufactured"],
                             "Division 1"),
                            (410, 370, ["bale storage: fibers", "stored or handled, not", "manufactured"],
                             "Division 2")):
        f.rect(x, 330, w, 200, fill=PANEL, stroke=LINE, sw=SW_STRUCT)
        f.lines(x + w / 2, 368, lines_, T_MIN, TEXT, gap=1.2)
        for k in range(5):
            f.rect(x + 40 + k * 64, 454, 40, 30, fill=PANEL_2, stroke=EDGE, sw=SW_THIN, rx=3)
        f.value(x + w / 2, 516, d, T_NOTE, records=div, pad=5, what=f"'{d}'")
    f.tag(f.w - 24, f.h - 10, "NEC 500.5", anchor="end")


@figure("antenna_power_lines_810-16b", h=520, nec="810.16(B)", records=["open-book-exam-#10-011"])
def antenna_power_lines(f):
    f.title("Receiving antenna near overhead power lines (not to scale)", y=34)
    gy = 460
    f.grade(gy, 20, 780, label=None)
    # House with a mast antenna and a dish.
    f.rect(60, 320, 220, 140, fill=PANEL, stroke=LINE, sw=SW_OBJ)
    f.poly([(40, 320), (170, 240), (300, 320)], PANEL_2, LINE, SW_OBJ)
    mx = 220
    f.line(mx, 272, mx, 110, STEEL, 6)
    for k, w in enumerate((70, 54, 38)):
        f.line(mx - w / 2, 120 + k * 22, mx + w / 2, 120 + k * 22, TEXT, 4)
    f.path(f"M 100 285 a 26 26 0 0 1 36 -26", TEXT, 4)
    f.line(118, 272, 128, 262, TEXT, 3)
    # Fall arc of the mast.
    f.path(f"M {mx} 110 A 162 162 0 0 1 {mx + 162} 272", AMBER, 2)
    f.text(mx + 140, 150, "if it falls", T_MIN, AMBER, "start", True)
    # Pole line.
    px = 640
    f.line(px, gy, px, 120, WOOD, 12)
    f.line(px - 70, 140, px + 70, 140, WOOD, 8)
    for dx in (-60, 0, 60):
        f.circle(px + dx, 130, 6, fill=TEXT)
    f.line(420, 132, 780, 130, WIRE_HOT, 3)
    f.line(420, 132, 400, 134, WIRE_HOT, 3)
    f.lines(px, 196, ["overhead light and", "power conductors"], T_MIN, TEXT, bold=True, gap=1.1)
    f.text(420, 300, "keep well away from lines", T_NOTE, TEXT, "start", True)
    b = f.text(420, 334, "of over", T_NOTE, TEXT, "start", True)
    f.value(b[0] + b[2] + 10, 334, "150 V to ground", T_NOTE, anchor="start", pad=6)
    f.lines(420, 380, ["so a falling antenna or", "lead-in cannot reach them"], T_MIN, MUTED, "start", gap=1.15)
    f.tag(f.w - 24, f.h - 14, "NEC 810.16(B)", anchor="end")


@figure("patient_bed_receptacles_517-18", h=520, nec="517.18(A), 517.18(B)",
        records={"open-book-exam-#10-019": {}, "final-exam-#2-048": {"like": "open-book-exam-#10-019"}})
def patient_bed(f):
    f.title("Category 2 space: one patient bed location", y=34)
    # Headwall.
    f.rect(40, 70, 720, 190, fill=PANEL, stroke=LINE, sw=SW_OBJ, rx=6)
    f.text(60, 98, "headwall", T_MIN, MUTED, "start")
    xs = (140, 230, 570, 660)
    for k, x in enumerate(xs):
        red = k in (0, 3)
        f.rect(x - 26, 130, 52, 80, fill="#7f1d1d" if red else PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=6)
        for dy in (150, 190):
            f.line(x - 8, dy - 6, x - 8, dy + 6, TEXT, 3)
            f.line(x + 8, dy - 6, x + 8, dy + 6, TEXT, 3)
    f.mask(90, 112, 190, 116, what="receptacles on this side")
    f.mask(520, 112, 190, 116, what="receptacles on this side")
    # Bed (plan-ish elevation).
    f.rect(300, 200, 200, 240, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=10)
    f.rect(330, 214, 140, 44, fill=LINE, rx=10)
    f.text(400, 360, "bed", T_LABEL, TEXT, bold=True)
    f.legend([("#7f1d1d", "critical branch", "box"), (PANEL_2, "normal system", "box")], 40, 300, T_MIN)
    f.lines(40, 380, ["at least two branch circuits:", "critical branch + normal"], T_MIN, TEXT, "start", gap=1.15)
    f.lines(520, 300, ["all hospital grade", "(517.18(B)(2))"], T_MIN, TEXT, "start", gap=1.15)
    f.value_lines(640, 380, ["minimum eight", "receptacles", "(4 duplex here)"], T_NOTE, pad=6, gap=1.15,
                  what="receptacle count per bed")
    f.tag(f.w - 24, f.h - 14, "NEC 517.18", anchor="end")


@figure("multiple_supplies_225-37_700-7", h=576, nec="225.37, 230.2(E), 700.7(A)",
        records={"open-book-exam-#7-016": {"terms": ["location"]},
                 "open-book-exam-#7-025": {"terms": ["disconnect"]},
                 "final-exam-#2-008": {"like": "open-book-exam-#7-025"}})
def multiple_supplies(f):
    loc = ["open-book-exam-#7-016"]
    disc = ["open-book-exam-#7-025"]
    f.title("One building, several supplies: plaques and signs", y=34)
    _card(f, 20, 56, 460, 480, "Building B is supplied by")
    rows = [(130, "service (utility)"), (250, "feeder from bldg A"), (370, "branch circuit from bldg A")]
    for y, name in rows:
        f.line(40, y, 290, y, WIRE_HOT, SW_WIRE)
        f.text(44, y - 12, name, T_MIN, TEXT, "start", True)
        f.rect(290, y - 30, 46, 60, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=5)
        f.line(336, y - 14, 348, y - 28, TEXT, 5)
        f.rect(360, y - 34, 104, 68, fill="#e2e8f0", stroke=TEXT, sw=SW_THIN, rx=3)
        for k in range(4):
            f.line(370, y - 20 + k * 14, 454 - (k % 2) * 24, y - 20 + k * 14, BG, 3)
    f.lines(250, 440, ["each plaque lists every other", "supply and the area it serves"], T_MIN, MUTED, gap=1.15)
    f.text(40, 490, "a plaque at each feeder and", T_MIN, TEXT, "start", True)
    b = f.text(40, 518, "branch-circuit", T_MIN, TEXT, "start", True)
    b = f.value(b[0] + b[2] + 10, 518, "disconnect", T_MIN, anchor="start", records=disc, pad=5,
                what="where the plaques go")
    f.text(b[0] + b[2] + 10, 518, "spot", T_MIN, TEXT, "start", True)
    f.mask(282, 90, 74, 320, records=disc, what="the switch at each plaque")
    # Emergency source sign at the service entrance.
    _card(f, 500, 56, 280, 480, "Service entrance")
    f.rect(530, 110, 90, 140, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=6)
    f.text(575, 190, "SE", T_LABEL, TEXT, bold=True)
    f.rect(520, 280, 240, 150, fill="#7f1d1d", stroke=TEXT, sw=SW_OBJ, rx=6)
    f.text(640, 312, "EMERGENCY SOURCE", T_MIN, TEXT, bold=True)
    f.text(536, 350, "type: standby generator", T_MIN, TEXT, "start")
    f.value(536, 386, "at: rear yard, east side", T_MIN, TEXT, anchor="start", bold=False, records=loc, pad=5,
            what="where the source is")
    f.text(640, 470, "sign: type and", T_MIN, MUTED)
    f.value(640, 496, "place of each source", T_MIN, MUTED, bold=False, records=loc, pad=5,
            what="the second item on the sign")
    f.tag(f.w - 24, f.h - 10, "NEC 225.37, 700.7(A)", anchor="end")


@figure("sign_construction_600", h=536, nec="Article 100 (Sign Body), 600.9(C)",
        records={"open-book-exam-#7-020": {"terms": ["body"]}, "final-exam-#1-069": {},
                 "final-exam-#2-006": {"like": "open-book-exam-#7-020"}})
def sign_construction(f):
    body = ["open-book-exam-#7-020"]
    gap = ["final-exam-#1-069"]
    f.title("Electric sign: the parts, and wood near lampholders", y=34)
    _card(f, 20, 56, 420, 440, "Sign, cut open")
    f.rect(50, 110, 360, 250, fill="none", stroke=AMBER, sw=SW_STRUCT + 2, rx=10)
    f.rect(80, 150, 130, 90, fill=STEEL, stroke=TEXT, sw=SW_OBJ, rx=4)
    f.lines(145, 186, ["electrical", "enclosure"], T_MIN, TEXT, bold=True, gap=1.1)
    for x in (260, 320, 380):
        f.rect(x - 12, 170, 24, 40, fill=PANEL_2, stroke=TEXT, sw=SW_THIN, rx=3)
        f.circle(x, 160, 12, fill="#fde68a")
    f.line(210, 196, 380, 196, WIRE_HOT, 3)
    f.lines(320, 250, ["lampholders"], T_MIN, TEXT, bold=True)
    f.text(230, 330, "outer shell: weather cover only", T_MIN, AMBER, bold=True)
    f.lines(230, 400, ["not an electrical enclosure;", "the defined term:"], T_MIN, TEXT, gap=1.15)
    f.value(230, 460, "sign body", T_LABEL, records=body, pad=6)
    # Wood near a lampholder.
    _card(f, 460, 56, 320, 440, "Wood nearby")
    f.stud(500, 110, 60, 330)
    f.rect(620, 240, 40, 60, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=4)
    f.circle(690, 270, 26, fill="#fde68a")
    f.text(640, 330, "lampholder", T_MIN, TEXT, bold=True)
    f.ext(560, 190, 560, 226)
    f.ext(620, 190, 620, 236)
    f.dim_h(560, 620, 200)
    f.value_lines(640, 140, ["2 in (50 mm)", "min"], T_NOTE, DIM, records=gap, pad=6, gap=1.1)
    f.lines(672, 400, ["combustibles: never", "above 90 C (194 F)"], T_MIN, MUTED, gap=1.15)
    f.tag(f.w - 24, f.h - 10, "NEC 600.9(C)", anchor="end")


@figure("busway_wall_368-234", h=480, nec="368.234(A), 368.234(B)",
        records={"final-exam-#5-050": {"terms": ["vapor", "seal"]}})
def busway_wall(f):
    rid = ["final-exam-#5-050"]
    f.title("Busway over 1000 V passing out of a building (section)", y=34)
    y = 230
    f.text(160, 90, "inside", T_LABEL, TEXT, bold=True)
    f.text(540, 90, "outside", T_LABEL, TEXT, bold=True)
    f.wall(330, 70, 440, 28, CONCRETE)
    f.text(330, 464, "exterior wall", T_MIN, MUTED)
    f.wall(120, 150, 440, 18)
    f.lines(120, 132, ["interior", "fire wall"], T_MIN, MUTED, gap=1.1)
    f.rect(20, y - 24, 760, 48, fill=STEEL, stroke=TEXT, sw=SW_OBJ, rx=4)
    for x in range(60, 780, 90):
        f.line(x, y - 24, x, y + 24, EDGE, 2)
    f.text(560, y + 8, "busway", T_NOTE, TEXT, bold=True)
    f.rect(108, y - 36, 24, 72, fill=NO, op=0.6, stroke=TEXT, sw=SW_THIN)
    f.text(120, 300, "fire barrier", T_MIN, TEXT, bold=True)
    f.rect(310, y - 40, 40, 80, fill=AMBER, op=0.7, stroke=TEXT, sw=SW_THIN, rx=3)
    f.mask(300, y - 48, 60, 96, records=rid, what="the device at the exterior wall")
    f.value(580, 330, "vapor seal", T_LABEL, records=rid, pad=6)
    f.value_lines(580, 376, ["stops air interchange between", "the inside and outside sections"], T_MIN,
                  TEXT, bold=False, records=rid, pad=5, gap=1.15, what="what the wall device does")
    f.leader(510, 322, 350, y + 30)
    f.value(580, 440, "Ex.: forced-cooled busway", T_MIN, MUTED, bold=False, records=rid, pad=5,
            what="the exception")
    f.tag(f.w - 24, 64, "NEC 368.234", anchor="end")


@figure("cinder_backfill_344-10c_300-5f", h=560, nec="344.10(C), 300.5(F), 305.15(E)",
        records={"final-exam-#5-068": {}, "open-book-exam-#10-005": {"terms": ["corrosion"]},
                 "open-book-exam-#10-025": {"terms": ["damage"]},
                 "final-exam-#2-043": {"like": "open-book-exam-#10-005"}})
def cinder_backfill(f):
    rmc = ["final-exam-#5-068"]
    cor = ["open-book-exam-#10-005"]
    dmg = ["open-book-exam-#10-025"]
    f.title("What surrounds a buried raceway", y=34)
    # RMC in cinder fill.
    _card(f, 20, 56, 370, 460, "RMC in wet cinder fill")
    f.rect(40, 100, 330, 260, fill="#3b3b3b", stroke=LINE, sw=SW_THIN)
    for k in range(60):
        f.circle(52 + (k * 53) % 310, 112 + (k * 31) % 236, 4, fill="#6b6b6b")
    f.concrete(125, 170, 160, 110)
    f.circle(205, 225, 24, fill=STEEL, stroke=TEXT, sw=SW_OBJ)
    f.circle(205, 225, 15, fill=BG)
    f.ext(181, 225, 181, 266)
    f.dim_h(125, 181, 262)
    f.value(153, 158, "2 in min", T_MIN, DIM, records=rmc, pad=4, what="concrete thickness")
    f.leader(153, 164, 153, 256, DIM)
    f.text(205, 396, "noncinder concrete, all sides", T_MIN, TEXT, bold=True)
    f.lines(205, 434, ["or conduit 18 in below the fill,", "or approved protection"], T_MIN, MUTED, gap=1.15)
    # Backfill in a trench.
    _card(f, 410, 56, 370, 460, "Backfill over a raceway")
    for x0, bad in ((430, True), (610, False)):
        f.rect(x0, 110, 150, 200, fill=SOIL, op=0.8)
        f.circle(x0 + 75, 270, 16, fill=STEEL, stroke=TEXT, sw=SW_THIN)
        if bad:
            for cx, cy, r in ((470, 170, 18), (530, 150, 14), (500, 220, 20), (550, 210, 12)):
                f.poly([(cx - r, cy), (cx - r * 0.3, cy - r), (cx + r, cy - r * 0.4), (cx + r * 0.6, cy + r)],
                       "#78716c", TEXT, SW_THIN)
            f.poly([(492, 250), (505, 262), (488, 262)], "#a8a29e", TEXT, SW_THIN)
            f.mark_no(505, 334)
        else:
            for k in range(20):
                f.circle(x0 + 12 + (k * 29) % 130, 124 + (k * 17) % 120, 3, fill=SOIL_DOT)
            f.mark_ok(685, 334)
    f.lines(505, 376, ["rocks, cinders,", "sharp or", "corrosive fill"], T_MIN, TEXT, bold=True, gap=1.1)
    f.lines(685, 376, ["clean,", "compacted fill"], T_MIN, TEXT, bold=True, gap=1.1)
    b = f.text(424, 462, "bad fill can", T_MIN, TEXT, "start")
    b = f.value(b[0] + b[2] + 10, 462, "damage", T_MIN, NO, anchor="start", records=dmg, pad=4)
    f.text(b[0] + b[2] + 10, 462, "the raceway", T_MIN, TEXT, "start")
    b = f.text(424, 494, "and add to its", T_MIN, TEXT, "start")
    f.value(b[0] + b[2] + 10, 494, "corrosion", T_MIN, NO, anchor="start", records=cor, pad=4)
    f.tag(f.w - 24, f.h - 10, "NEC 344.10(C), 300.5(F)", anchor="end")
