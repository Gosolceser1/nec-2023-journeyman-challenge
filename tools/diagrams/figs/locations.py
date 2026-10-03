"""Special locations and equipment: hazardous classes, antennas, patient beds, signs, busways, burial."""
from nec_style import *  # noqa: F401,F403


def _card(f, x, y, w, h, title=None):
    f.card(x, y, w, h, title, align="middle")


def _scatter(n, x, y, w, h, seed=7):
    """Deterministic, evenly spread pseudo-random points in a box."""
    pts, s = [], seed
    for _ in range(n):
        s = (s * 1103515245 + 12345) % 2147483648
        u = s / 2147483648
        s = (s * 1103515245 + 12345) % 2147483648
        v = s / 2147483648
        pts.append((x + u * w, y + v * h))
    return pts


def _duplex(f, x, y, s, red=False):
    """Hospital-grade duplex: green dot on each face; red body for the critical branch."""
    w = s * 0.64
    f.rect(x - w / 2, y - s / 2, w, s, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=s * 0.1)
    if red:
        f.rect(x - w / 2, y - s / 2, w, s, fill=NO, op=0.75, stroke=TEXT, sw=SW_OBJ, rx=s * 0.1)
    r = min(w * 0.37, s * 0.2)
    for fy in (y - s * 0.23, y + s * 0.23):
        f.nema_face(x, fy, r, "5-20")
        f.circle(x + r * 0.62, fy - r * 0.62, max(2.5, r * 0.14), fill=OK)
    f.circle(x, y, max(2.0, s * 0.035), fill=LINE)


@figure("hazardous_classes_500-5", h=360, nec="500.5",
        records={"open-book-exam-#10-017": {"terms": ["III"]}, "final-exam-#1-061": {"terms": ["III"]}})
def hazardous_classes(f):
    f.title("Hazardous locations: what is in the air decides the class", y=34)
    cards = [(20, "gas or vapor", "I"), (280, "combustible dust", "II"), (540, "ignitible fibers", "III")]
    for x, name, num in cards:
        _card(f, x, 56, 240, 250, name)
        cx, cy = x + 120, 160
        if num == "I":
            for dx, dy, r in ((-30, 6, 26), (0, -12, 32), (32, 4, 24), (4, 22, 22)):
                f.circle(cx + dx, cy + dy, r, fill=PANEL_2, stroke=MUTED, sw=SW_THIN)
        elif num == "II":
            for k, (px, py) in enumerate(_scatter(34, cx - 70, cy - 40, 140, 80)):
                f.circle(px, py, 3 + k % 3, fill=MUTED)
        else:
            for k in range(6):
                f.path(f"M {cx - 70 + k * 10} {cy - 30 + k * 12} q 30 -24 60 0 t 60 0", MUTED, 3)
        f.text(cx - 8, 270, "Class", T_LABEL, TEXT, "end", True)
        f.value(cx + 2, 270, num, T_LABEL, anchor="start", pad=6, what=f"class for {name}")
    f.tag(f.w - 24, f.h - 12, "NEC 500.5", anchor="end")


@figure("textile_divisions_500-5d", h=400, nec="500.5(D)", records={"final-exam-#3-008": {"terms": ["III", "Division 2", "Div. 2"]}})
def textile_divisions(f):
    f.title("Textile mill: fibers being made vs. fibers in storage", y=34)
    for x, w, lines_, d in ((20, 370, ["carding and spinning:", "fibers handled while", "being manufactured"],
                             "Class III, Division 1"),
                            (410, 370, ["bale storage: fibers", "stored or handled, not", "manufactured"],
                             "Class III, Division 2")):
        f.rect(x, 70, w, 260, fill=PANEL, stroke=LINE, sw=SW_STRUCT)
        f.lines(x + w / 2, 112, lines_, T_NOTE, TEXT, gap=1.2)
        if d.endswith("1"):
            for k in range(3):
                mx = x + 40 + k * 104
                f.rect(mx, 220, 84, 46, fill=PANEL_2, stroke=EDGE, sw=SW_THIN, rx=4)
                for rx_ in (mx + 22, mx + 62):
                    f.circle(rx_, 243, 13, fill=BG, stroke=LINE, sw=SW_THIN)
        else:
            for k in range(5):
                bx = x + 40 + k * 64
                f.rect(bx, 220, 44, 46, fill=PANEL_2, stroke=EDGE, sw=SW_THIN, rx=3)
                for sx in (bx + 13, bx + 31):
                    f.line(sx, 221, sx, 265, LINE, 2)
        f.value(x + w / 2, 306, d, T_NOTE, pad=5, what=f"'{d}'")
    f.tag(f.w - 24, f.h - 12, "NEC 500.5(D)", anchor="end")


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
    # Small dish on a wall bracket.
    f.line(102, 384, 102, 420, STEEL, 5)
    f.rect(92, 418, 20, 10, fill=STEEL, stroke=TEXT, sw=1, rx=2)
    f.path("M 110 352 Q 88 384 110 416", TEXT, 5)
    f.line(110, 352, 136, 384, LINE, 2)
    f.line(110, 416, 136, 384, LINE, 2)
    f.rect(132, 379, 10, 10, fill=LINE, rx=2)
    # Fall arc of the mast.
    f.path(f"M {mx} 110 A 162 162 0 0 1 {mx + 162} 272", AMBER, 2)
    f.text(mx + 140, 150, "if it falls", T_MIN, AMBER, "start", True)
    # Pole line.
    px = 710
    f.line(px, gy, px, 120, WOOD, 12)
    f.line(px - 70, 140, px + 70, 140, WOOD, 8)
    for dx in (-60, 0, 60):
        f.rect(px + dx - 6, 116, 12, 20, fill=LINE, stroke=TEXT, sw=1, rx=3)
        f.circle(px + dx, 112, 7, fill=WIRE_HOT, stroke=BG, sw=2)
    f.lines(px - 20, 196, ["overhead light and", "power conductors", "(end view)"], T_MIN, TEXT, "end", True,
            gap=1.1)
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
        _duplex(f, x, 170, 80, red=k in (0, 3))
    f.mask(90, 112, 190, 116, what="receptacles on this side")
    f.mask(520, 112, 190, 116, what="receptacles on this side")
    # Hospital bed seen from its foot, head against the wall.
    f.floor(440, 270, 530)
    f.rect(304, 226, 192, 110, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=12)
    f.rect(340, 292, 120, 28, fill=LINE, rx=13)
    f.rect(286, 326, 228, 38, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=8)
    f.text(400, 352, "bed", T_NOTE, TEXT, bold=True)
    f.rect(296, 364, 208, 16, fill=STEEL, stroke=TEXT, sw=SW_THIN, rx=3)
    for lx in (318, 482):
        f.line(lx, 380, lx, 418, STEEL, 8)
        f.circle(lx, 428, 10, fill=BG, stroke=TEXT, sw=SW_THIN)
    f.legend([(NO, "critical branch (red)", "box"), (PANEL_2, "normal system", "box")], 40, 300, T_MIN)
    f.lines(40, 380, ["at least two branch circuits:", "critical branch + normal"], T_MIN, TEXT, "start", gap=1.15)
    f.lines(536, 300, ["all hospital grade,", "green dot (517.18(B)(2))"], T_MIN, TEXT, "start", gap=1.15)
    f.value_lines(640, 380, ["minimum eight", "receptacles", "(4 duplex here)"], T_NOTE, pad=6, gap=1.15,
                  what="receptacle count per bed")
    f.tag(f.w - 24, f.h - 14, "NEC 517.18", anchor="end")


@figure("plaques_225-37", h=520, nec="225.37",
        records={"open-book-exam-#7-025": {"terms": ["disconnect"]},
                 "final-exam-#2-008": {"like": "open-book-exam-#7-025"}})
def plaques(f):
    f.title("Building B has several supplies: a plaque at each", y=34)
    rows = [(120, "service (utility)"), (230, "feeder from building A"), (340, "branch circuit from building A")]
    for y, name in rows:
        f.line(40, y, 380, y, WIRE_HOT, SW_WIRE)
        f.text(44, y - 12, name, T_NOTE, TEXT, "start", True)
        f.disconnect(380, y - 32, 48, 64)
        f.rect(460, y - 36, 120, 72, fill=TEXT, stroke=LINE, sw=SW_THIN, rx=3)
        for k in range(4):
            f.line(472, y - 20 + k * 14, 568 - (k % 2) * 28, y - 20 + k * 14, BG, 3)
    f.mask(372, 80, 64, 300, what="the switch at each plaque")
    f.text(620, 120, "plaque", T_NOTE, TEXT, "start", True)
    f.lines(620, 150, ["lists every other", "supply and the", "area it serves"], T_MIN, MUTED, "start", gap=1.15)
    b = f.text(40, 440, "a plaque at each feeder and branch-circuit", T_NOTE, TEXT, "start", True)
    b = f.value(b[0] + b[2] + 10, 440, "disconnect", T_NOTE, anchor="start", pad=5, what="where the plaques go")
    f.text(b[0] + b[2] + 10, 440, "location", T_NOTE, TEXT, "start", True)
    f.tag(f.w - 24, f.h - 12, "NEC 225.37", anchor="end")


@figure("emergency_sign_700-7", h=440, nec="700.7(A)", records={"open-book-exam-#7-016": {"terms": ["location"]}})
def emergency_sign(f):
    f.title("Sign at the service entrance: on-site emergency source", y=34)
    f.panel(60, 90, 120, 200, label="service equipment", breakers=3, main=True)
    f.rect(240, 100, 400, 200, fill=NO, op=0.45, stroke=NO, sw=SW_OBJ, rx=6)
    f.text(440, 140, "EMERGENCY SOURCE", T_NOTE, TEXT, bold=True)
    f.text(260, 190, "type: standby generator", T_NOTE, TEXT, "start")
    f.value(260, 240, "location: rear yard, east side", T_NOTE, TEXT, anchor="start", bold=False, pad=5,
            what="where the source is")
    f.text(440, 350, "the sign gives the type and", T_NOTE, MUTED)
    f.value(440, 384, "location of each source", T_NOTE, MUTED, bold=False, pad=5,
            what="the second item on the sign")
    f.tag(f.w - 24, f.h - 12, "NEC 700.7(A)", anchor="end")


@figure("sign_body_100", h=460, nec="Article 100 (Sign Body)",
        records={"open-book-exam-#7-020": {"terms": ["body"]}, "final-exam-#2-006": {"like": "open-book-exam-#7-020"}})
def sign_body(f):
    f.title("Electric sign, cut open", y=34)
    f.rect(80, 80, 640, 250, fill="none", stroke=AMBER, sw=SW_STRUCT + 2, rx=10)
    f.rect(120, 130, 170, 110, fill=STEEL, stroke=TEXT, sw=SW_OBJ, rx=4)
    f.lines(205, 178, ["electrical", "enclosure"], T_NOTE, TEXT, bold=True, gap=1.1)
    for x in (400, 500, 600):
        f.rect(x - 14, 160, 28, 46, fill=PANEL_2, stroke=TEXT, sw=SW_THIN, rx=3)
        f.circle(x, 148, 14, fill=AMBER)
    f.line(290, 186, 600, 186, WIRE_HOT, 3)
    f.text(500, 240, "lampholders", T_NOTE, TEXT, bold=True)
    f.text(400, 310, "outer shell: weather cover only", T_NOTE, AMBER, bold=True)
    f.text(400, 380, "not an electrical enclosure; the defined term:", T_NOTE, TEXT)
    f.value(400, 430, "sign body", T_LABEL, pad=6)
    f.tag(f.w - 24, f.h - 12, "NEC Art. 100", anchor="end")


@figure("sign_wood_600-9c", h=420, nec="600.9(C)", records=["final-exam-#1-069"])
def sign_wood(f):
    f.title("Wood near a sign lampholder", y=34)
    f.stud(160, 70, 80, 300)
    f.text(200, 400, "wood", T_NOTE, MUTED)
    f.rect(360, 190, 50, 74, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=4)
    f.circle(446, 227, 32, fill=AMBER)
    f.text(400, 300, "lampholder", T_NOTE, TEXT, bold=True)
    f.ext(240, 130, 240, 176)
    f.ext(360, 130, 360, 186)
    f.dim_h(240, 360, 150)
    f.value_lines(330, 96, ["2 in (50 mm)", "min"], T_NOTE, DIM, pad=6, gap=1.1, what="the gap")
    f.lines(520, 200, ["wood enclosures are", "allowed with this", "gap to lampholders"], T_NOTE, TEXT, "start",
            gap=1.2)
    f.lines(520, 320, ["combustibles: never", "above 90 C (194 F)"], T_MIN, MUTED, "start", gap=1.15)
    f.tag(f.w - 24, f.h - 12, "NEC 600.9(C)", anchor="end")


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
    f.lines(120, 116, ["interior", "fire wall"], T_MIN, MUTED, gap=1.1)
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


@figure("rmc_cinder_344-10c", h=470, nec="344.10(C)", records=["final-exam-#5-068"])
def rmc_cinder(f):
    f.title("RMC in cinder fill subject to permanent moisture (section)", y=34)
    f.rect(40, 70, 440, 340, fill=PANEL_2, stroke=LINE, sw=SW_THIN)
    cx, cy, r, c = 260, 240, 30, 64
    for k, (px, py) in enumerate(_scatter(110, 48, 78, 424, 324, seed=11)):
        if not (cx - r - c - 8 < px < cx + r + c + 8 and cy - r - c - 8 < py < cy + r + c + 8):
            f.circle(px, py, 3 + k % 3, fill=EDGE)
    f.concrete(cx - r - c, cy - r - c, 2 * (r + c), 2 * (r + c))
    f.circle(cx, cy, r, fill=STEEL, stroke=TEXT, sw=SW_OBJ)
    f.circle(cx, cy, r - 9, fill=BG)
    f.dim_v(cx, cy - r - c, cy - r)
    f.value(cx + 12, cy - r - c / 2 + 8, "2 in min", T_NOTE, BG, anchor="start", pad=4, what="concrete thickness")
    f.text(260, 440, "cinder fill", T_NOTE, MUTED)
    f.card(510, 90, 270, 260, "Protect it with")
    f.lines(526, 156, ["noncinder concrete", "on all sides,"], T_NOTE, TEXT, "start", True, gap=1.2)
    f.lines(526, 236, ["or 18 in or more under", "the fill, or approved", "corrosion protection"], T_MIN, MUTED,
            "start", gap=1.2)
    f.tag(f.w - 24, f.h - 12, "NEC 344.10(C)", anchor="end")


def _backfill(f):
    """Two trench sections side by side: rocky fill (wrong) and clean fill (right)."""
    for x0, bad in ((60, True), (440, False)):
        f.rect(x0, 70, 300, 240, fill=SOIL, op=0.8)
        f.circle(x0 + 150, 270, 20, fill=STEEL, stroke=TEXT, sw=SW_THIN)
        if bad:
            for cx, cy, r in ((120, 130, 24), (220, 110, 18), (170, 200, 26), (290, 180, 16), (100, 230, 14)):
                f.poly([(cx - r, cy), (cx - r * 0.3, cy - r), (cx + r, cy - r * 0.4), (cx + r * 0.6, cy + r)],
                       EDGE, TEXT, SW_THIN)
            f.poly([(232, 250), (248, 264), (226, 264)], LINE, TEXT, SW_THIN)
            f.mark_no(210, 340)
        else:
            for px, py in _scatter(40, x0 + 14, 84, 270, 150, seed=5):
                f.circle(px, py, 3, fill=SOIL_DOT)
            f.mark_ok(590, 340)
    f.text(210, 384, "rocks, cinders, sharp or corrosive fill", T_MIN, TEXT, bold=True)
    f.text(590, 384, "clean, compacted fill", T_MIN, TEXT, bold=True)


@figure("backfill_300-5f", h=480, nec="300.5(F)",
        records={"open-book-exam-#10-005": {"terms": ["corrosion"]},
                 "final-exam-#2-043": {"like": "open-book-exam-#10-005"}})
def backfill_300(f):
    f.title("Backfill over a buried raceway (section)", y=34)
    _backfill(f)
    b = f.text(60, 440, "bad fill can harm the raceway and add to its", T_NOTE, TEXT, "start")
    f.value(b[0] + b[2] + 10, 440, "corrosion", T_NOTE, NO, anchor="start", pad=4, what="what bad fill adds to")
    f.tag(f.w - 24, 64, "NEC 300.5(F)", anchor="end")


@figure("backfill_305-15e", h=480, nec="305.15(E)", records={"open-book-exam-#10-025": {"terms": ["damage"]}})
def backfill_305(f):
    f.title("Backfill over a buried raceway, over 1000 V (section)", y=34)
    _backfill(f)
    b = f.text(60, 440, "bad fill can", T_NOTE, TEXT, "start")
    b = f.value(b[0] + b[2] + 10, 440, "damage", T_NOTE, NO, anchor="start", pad=4, what="what bad fill can do")
    f.text(b[0] + b[2] + 10, 440, "the raceway and add to its corrosion", T_NOTE, TEXT, "start")
    f.tag(f.w - 24, 64, "NEC 305.15(E)", anchor="end")
