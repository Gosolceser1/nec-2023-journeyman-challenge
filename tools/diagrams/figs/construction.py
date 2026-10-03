"""Equipment and wiring-method construction: switchboards, type letters, FCC, cable cutaways, raceway fill."""
from nec_style import *  # noqa: F401,F403


def _mc_armor(f, x, y, w, h, pitch=17):
    """Interlocked metal-tape armor, side view: a tube of overlapping convex
    tape wraps, each rib leaning slightly like the helix it is."""
    f.rect(x, y, w, h, fill=STEEL, stroke=TEXT, sw=SW_OBJ, rx=6)
    k = 0
    while x + 6 + k * pitch < x + w - 4:
        rx = x + 6 + k * pitch
        f.path(f"M {rx + 4} {y + 2} Q {rx + pitch * 0.9} {y + h / 2} {rx - 4} {y + h - 2}", LINE, 3)
        f.path(f"M {rx + 9} {y + 4} Q {rx + pitch * 1.1} {y + h / 2} {rx + 1} {y + h - 4}", EDGE, 1.5)
        k += 1


def _fmc_side(f, x, y, w, h, pitch=11):
    """Flexible metal conduit, side view, with its open end on the left."""
    f.rect(x, y, w, h, fill=STEEL, stroke=TEXT, sw=SW_OBJ, rx=4)
    k = 0
    while x + 12 + k * pitch < x + w - 4:
        rx = x + 12 + k * pitch
        f.line(rx + 3, y + 2, rx - 3, y + h - 2, LINE, 2.5)
        k += 1
    f.path(f"M {x} {y} a {h * 0.22} {h / 2} 0 1 0 0 {h} a {h * 0.22} {h / 2} 0 1 0 0 {-h}", TEXT, SW_OBJ, PANEL_2)
    f.path(f"M {x} {y + 7} a {h * 0.15} {h / 2 - 7} 0 1 0 0 {h - 14} a {h * 0.15} {h / 2 - 7} 0 1 0 0 {14 - h}",
           EDGE, 1.5, BG)


def _rows(f, x, y, rows, size=T_MIN, gap=30):
    for i, (k, v) in enumerate(rows):
        f.text(x, y + i * gap, k, size, TEXT, "start", True)
        f.text(x + 56, y + i * gap, v, size, MUTED, "start")


def _switchboard_plan(f, x0, y0, w, h):
    f.rect(x0, y0, w, h, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ + 1)
    for k in (1, 2):
        f.line(x0 + k * w / 3, y0, x0 + k * w / 3, y0 + h, EDGE, 2)
    f.text(x0 + w / 2, y0 + h / 2 + 8, "sections", T_MIN, TEXT, bold=True)


@figure("switchboard_marking_408-18c", h=470, nec="408.18(C)",
        records={"final-exam-#1-002": {"terms": ["front"]}, "open-book-exam-#1-015": {"terms": ["front"]}})
def switchboard_marking(f):
    mark = ["final-exam-#1-002", "open-book-exam-#1-015"]
    f.title("Switchboard, plan view: field connections from the rear", y=34)
    x0, y0, w, h = 300, 190, 200, 120
    _switchboard_plan(f, x0, y0, w, h)
    f.text(x0 + w / 2, y0 - 70, "wall", T_MIN, MUTED)
    f.line(x0 - 60, y0 - 54, x0 + w + 60, y0 - 54, LINE, SW_STRUCT)
    f.lines(150, 110, ["field connections need", "rear or side access"], T_MIN, AMBER, bold=True, gap=1.1)
    f.leader(150, 130, x0 + 20, y0 - 8)
    sides = [(x0 + w / 2, y0 - 16, "rear"), (x0 - 50, y0 + h / 2 + 7, "left"),
             (x0 + w + 50, y0 + h / 2 + 7, "right"), (x0 + w / 2, y0 + h + 40, "front")]
    for sx, sy, name in sides:
        f.value(sx, sy, name, T_NOTE, MUTED, records=mark, pad=6, what=f"the {name} side")
    f.value(x0 + w / 2, 404, "the marking goes on the front", T_NOTE, records=mark, pad=6,
            what="where the marking goes")
    f.tag(f.w - 24, f.h - 10, "NEC 408.18(C)", anchor="end")


@figure("switchboard_sections_408-3a", h=470, nec="408.3(A)(2)", when="after",
        records=["open-book-exam-#1-007"])
def switchboard_sections(f):
    f.title("Switchboard elevation: conductors stay in their own section", y=34)
    sw_, top, bot = 150, 110, 380
    xs = [120 + k * 190 for k in range(3)]
    rows = [176 + j * 66 for j in range(3)]
    for k, sx in enumerate(xs):
        f.rect(sx - 2, bot, sw_ + 4, 12, fill=STEEL, stroke=TEXT, sw=1.5)
        f.rect(sx, top, sw_, bot - top, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ + 1, rx=3)
        f.line(sx, 162, sx + sw_, 162, EDGE, SW_THIN)
        for cx in (sx + 12, sx + sw_ - 12):
            f.circle(cx, top + 12, 3, fill=EDGE)
            f.circle(cx, bot - 12, 3, fill=EDGE)
        if k == 0:
            f.breaker(sx + 14, 190, 80, 130, poles=3)
        else:
            for ry in rows:
                f.breaker(sx + 14, ry, 80, 52, poles=3)
    for sx, ty in ((xs[0], 255), (xs[1], rows[1] + 26), (xs[2], rows[0] + 26)):
        f.polyline([(sx + 124, 80), (sx + 124, ty), (sx + 94, ty)], WIRE_HOT, SW_WIRE)
    f.polyline([(xs[0] + 138, 80), (xs[0] + 138, 140), (xs[1] + 110, 140), (xs[1] + 110, rows[0] + 26),
                (xs[1] + 94, rows[0] + 26)], NO, SW_WIRE)
    f.mark_no(xs[0] + sw_ + 20, 140, 13)
    f.lines(400, 420, ["only the conductors that end in a vertical", "section run in that section"],
            T_MIN, TEXT, gap=1.15)
    f.tag(f.w - 24, 64, "NEC 408.3(A)(2)", anchor="end")


@figure("insulation_letters_310-4", h=450, nec="Table 310.4(1)",
        records={"final-exam-#1-026": {}, "open-book-exam-#3-011": {"like": "final-exam-#1-026"}})
def insulation_letters(f):
    dash2 = ["final-exam-#1-026"]
    f.title("Reading the print on a building wire", y=34)
    f.rect(60, 80, 560, 44, fill="#1f2937", stroke=TEXT, sw=SW_OBJ, rx=22)
    f.rect(620, 92, 70, 20, fill=ROD, stroke=TEXT, sw=1.5, rx=4)
    f.text(340, 110, "RHW-2", T_NOTE, TEXT, bold=True)
    f.card(60, 156, 680, 230)
    _rows(f, 90, 200, [("R", "thermoset insulation"), ("H", "75 C rated"), ("W", "wet locations")], T_NOTE, 40)
    f.text(90, 330, "-2", T_VALUE, TEXT, "start", True)
    f.value(160, 330, "90 C max, wet or dry", T_NOTE, anchor="start", records=dash2, pad=6,
            what="what the -2 means")
    f.tag(f.w - 24, f.h - 10, "NEC Table 310.4(1)", anchor="end")


@figure("cord_letters_400-4", h=470, nec="Table 400.4",
        records={"final-exam-#1-034": {}, "open-book-exam-#4-025": {}})
def cord_letters(f):
    wet = ["final-exam-#1-034", "open-book-exam-#4-025"]
    f.title("Flexible cord type letters", y=34)
    f.rect(60, 76, 520, 50, fill="#111827", stroke=TEXT, sw=SW_OBJ, rx=25)
    for k, color in enumerate((WIRE_HOT, WIRE_NEU, WIRE_GND)):
        y = 88 + k * 13
        f.polyline([(580, 101), (610, y), (660, y)], color, 9)
        f.line(660, y, 690, y, ROD, 4)
    f.text(320, 108, "hard-service cord", T_MIN, MUTED)
    f.card(60, 150, 680, 270)
    _rows(f, 90, 196, [("S", "hard service"), ("J", "junior (lighter duty)"), ("T", "thermoplastic")], T_MIN, 38)
    _rows(f, 420, 196, [("P", "parallel"), ("O", "oil-resistant"), ("OO", "jacket and insulation")], T_MIN, 38)
    f.text(90, 360, "W", T_VALUE, TEXT, "start", True)
    f.value(146, 360, "wet location and sunlight resistant", T_NOTE, anchor="start", records=wet, pad=6,
            what="what the W suffix means")
    f.tag(f.w - 24, f.h - 10, "NEC Table 400.4", anchor="end")


@figure("direct_burial_cable_338", h=430, nec="338.100", records={"final-exam-#5-022": {"terms": ["USE"]}})
def direct_burial_cable(f):
    burial = ["final-exam-#5-022"]
    f.title("Service-entrance cable buried directly in earth (section)", y=34)
    g = 150
    f.grade(g, soil_h=200, label="grade")
    f.polyline([(120, g - 60), (120, g + 140), (680, g + 140)], "#111827", 16)
    f.polyline([(120, g - 60), (120, g + 140), (680, g + 140)], EDGE, 2)
    f.text(140, g - 70, "cable, no raceway", T_MIN, TEXT, "start", True)
    f.text(400, g + 186, "in the earth", T_MIN, TEXT, bold=True)
    f.text(560, 80, "type:", T_NOTE, TEXT, "end", True)
    f.value(572, 80, "USE", T_VALUE, anchor="start", records=burial, pad=6, what="the cable type")
    f.text(560, 120, "U = underground", T_MIN, MUTED, "end")
    f.tag(f.w - 24, f.h - 10, "NEC 338.100", anchor="end")


def _fcc_layer(f, y, color):
    f.poly([(60, y + 24), (120, y), (440, y), (380, y + 24)], color, TEXT, SW_THIN, 0.85)


def _fcc_cable(f, y):
    _fcc_layer(f, y, WIRE_NEU)
    for t in (7, 12, 17):
        f.line(120 - 60 * t / 24 + 26, y + t, 440 - 60 * t / 24 - 26, y + t, ROD, 3)


@figure("fcc_adhesive_324-41", h=420, nec="324.41",
        records={"final-exam-#5-001": {"terms": ["release", "adhesive"]}})
def fcc_adhesive(f):
    glue = ["final-exam-#5-001"]
    f.title("Carpet square over flat conductor cable (exploded)", y=34)
    _fcc_layer(f, 90, "#6d28d9")
    f.text(460, 108, "carpet square", T_MIN, TEXT, "start", True)
    _fcc_layer(f, 160, AMBER)
    f.value(460, 178, "release-type adhesive", T_MIN, TEXT, anchor="start", records=glue, pad=5,
            what="how the square is held down")
    _fcc_cable(f, 230)
    f.text(460, 248, "FCC system", T_MIN, TEXT, "start", True)
    _fcc_layer(f, 300, CONCRETE)
    f.text(460, 318, "floor", T_MIN, TEXT, "start", True)
    f.text(300, 380, "the square can be lifted to reach the cable", T_MIN, MUTED)
    f.tag(f.w - 24, 70, "NEC 324.41", anchor="end")


@figure("fcc_bottom_shield_100", h=440, nec="Article 100 (Bottom Shield)",
        records={"final-exam-#5-007": {"terms": ["bottom", "shield"]}})
def fcc_bottom_shield(f):
    bot = ["final-exam-#5-007"]
    f.title("Flat conductor cable layers (exploded, not to scale)", y=34)
    _fcc_layer(f, 90, STEEL)
    f.value(460, 108, "top shield (metal)", T_MIN, TEXT, anchor="start", records=bot, pad=5,
            what="the layer above the cable")
    _fcc_cable(f, 170)
    f.text(460, 188, "FCC cable", T_MIN, TEXT, "start", True)
    _fcc_layer(f, 250, STEEL)
    f.value(460, 268, "bottom shield", T_MIN, TEXT, anchor="start", records=bot, pad=5,
            what="the layer between floor and cable")
    _fcc_layer(f, 330, CONCRETE)
    f.text(460, 348, "floor", T_MIN, TEXT, "start", True)
    f.text(300, 404, "protects the cable from damage at the floor", T_MIN, MUTED)
    f.tag(f.w - 24, 70, "NEC Article 100", anchor="end")


@figure("fcc_transition_324-40d", h=420, nec="324.40(D)",
        records={"final-exam-#5-004": {"terms": ["transition"]}})
def fcc_transition(f):
    trans = ["final-exam-#5-004"]
    f.title("Where flat conductor cable meets other wiring", y=34)
    f.floor(300, 20, 600, label="floor")
    f.wall(600, 70, 360, 24)
    f.rect(470, 240, 120, 56, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=5)
    f.rect(478, 248, 104, 40, fill="none", stroke=EDGE, sw=1.5, rx=3)
    for sx, sy in ((486, 256), (574, 280)):
        f.circle(sx, sy, 3, fill=LINE)
    f.rect(80, 286, 390, 12, fill=WIRE_NEU, stroke=TEXT, sw=1)
    for yy in (289.5, 292, 294.5):
        f.line(86, yy, 464, yy, ROD, 1.5)
    f.text(240, 274, "FCC cable under carpet", T_MIN, MUTED)
    f.conduit(600, 268, 760, 268, width=16)
    f.lines(300, 120, ["power feed, grounding and shield", "connections to other wiring are in a:"],
            T_MIN, TEXT, gap=1.15)
    f.value(300, 196, "transition assembly", T_NOTE, records=trans, pad=6, what="where FCC meets other wiring")
    f.mask(462, 232, 136, 72, records=trans, what="the box at the wall")
    f.tag(f.w - 24, f.h - 10, "NEC 324.40(D)", anchor="end")


@figure("cca_conductor_310-3b", h=440, nec="310.3(B)(3)",
        records={"open-book-exam-#10-015": {}, "final-exam-#2-045": {"like": "open-book-exam-#10-015"}})
def cca_conductor(f):
    ccal = ["open-book-exam-#10-015"]
    f.title("Copper-clad aluminum conductor (cross-section)", y=34)
    cx, cy = 240, 230
    f.circle(cx, cy, 120, fill=ROD, stroke=TEXT, sw=SW_OBJ)
    f.circle(cx, cy, 104, fill=CONCRETE, stroke=CLAMP, sw=1.5)
    f.text(cx, cy + 8, "aluminum core", T_NOTE, BG, bold=True)
    f.text(470, 110, "copper layer", T_NOTE, TEXT, "start", True)
    f.leader(466, 104, cx + 88, cy - 82)
    f.lines(470, 180, ["copper bonded to", "the aluminum core"], T_MIN, MUTED, "start", gap=1.15)
    f.text(470, 290, "copper share of area:", T_MIN, TEXT, "start", True)
    f.value(470, 334, "at least 10%", T_VALUE, anchor="start", records=ccal, pad=6, what="minimum copper share")
    f.tag(f.w - 24, f.h - 10, "NEC 310.3(B)(3)", anchor="end")


@figure("mc_cable_100", h=420, nec="Article 100 (Metal-Clad Cable)",
        records={"final-exam-#5-003": {"terms": ["MC"]}})
def mc_cable(f):
    mc = ["final-exam-#5-003"]
    f.title("Factory cable in interlocking metal tape armor", y=34)
    _mc_armor(f, 80, 130, 400, 90)
    for k, color in enumerate((NO, WIRE_NEU, WIRE_GND)):
        y = 154 + k * 20
        f.polyline([(480, 175), (510, y), (600, y)], color, 13)
        f.line(600, y, 630, y, ROD, 6)
    f.path("M 480 130 a 14 45 0 1 1 0 90 a 14 45 0 1 1 0 -90", TEXT, SW_THIN, PANEL)
    for k, color in enumerate((NO, WIRE_NEU, WIRE_GND)):
        f.circle(480, 157 + k * 18, 7, fill=color)
    f.text(280, 270, "interlocking metal tape armor", T_MIN, TEXT, bold=True)
    f.text(560, 250, "insulated conductors", T_MIN, MUTED)
    f.text(390, 340, "Type", T_VALUE, TEXT, "end", True)
    f.value(402, 340, "MC", T_VALUE, anchor="start", records=mc, pad=6, what="the cable type")
    f.tag(f.w - 24, f.h - 10, "NEC Article 100", anchor="end")


@figure("mi_cable_332", h=440, nec="Article 332", records=["final-exam-#5-020"])
def mi_cable(f):
    mi = ["final-exam-#5-020"]
    f.title("Type MI cable (cross-section)", y=34)
    cx, cy = 200, 220
    f.circle(cx, cy, 110, fill=ROD, stroke=TEXT, sw=SW_OBJ)
    f.circle(cx, cy, 94, fill=TEXT, stroke=CLAMP, sw=1.5)
    for dx, dy in ((-36, -22), (36, -22), (0, 38)):
        f.circle(cx + dx, cy + dy, 22, fill=ROD, stroke=CLAMP, sw=SW_THIN)
    f.text(cx, 370, "mineral insulation packed around them", T_MIN, MUTED)
    f.leader(400, 112, cx + 50, cy - 30)
    f.value(410, 118, "solid copper conductors", T_MIN, anchor="start", records=mi, pad=5, what="the conductors")
    f.leader(400, 210, cx + 104, cy - 10)
    f.value_lines(410, 206, ["copper sheath: mechanical", "protection"], T_MIN, anchor="start", records=mi,
                  pad=5, gap=1.1, what="what the sheath does")
    f.value_lines(410, 296, ["copper sheath: grounding", "path"], T_MIN, anchor="start", records=mi, pad=5,
                  gap=1.1, what="what else the sheath does")
    f.tag(f.w - 24, f.h - 10, "NEC Article 332", anchor="end")


@figure("fmc_3-8_348-22", h=420, nec="348.22", records=["final-exam-#5-032", "final-exam-#3-048"])
def fmc_3_8(f):
    big = ["final-exam-#5-032", "final-exam-#3-048"]
    f.title("Trade size 3/8 flexible metal conduit", y=34)
    _fmc_side(f, 120, 110, 460, 70)
    f.text(350, 230, "too small for Chapter 9: it has its own table,", T_MIN, TEXT)
    f.text(350, 262, "Table 348.22", T_NOTE, DIM, bold=True)
    f.text(350, 320, "largest conductor allowed:", T_NOTE, TEXT, bold=True)
    f.value(350, 372, "10 AWG", T_VALUE, records=big, pad=6, what="largest conductor")
    f.tag(f.w - 24, f.h - 10, "NEC 348.22", anchor="end")


@figure("lfnc_fill_356-22", h=470, nec="356.22",
        records={"final-exam-#5-066": {}, "final-exam-#4-003": {"like": "final-exam-#5-066"}})
def lfnc_fill(f):
    tab = ["final-exam-#5-066"]
    f.title("LFNC fill: the percent-of-area table", y=34)
    b = f.text(390, 86, "Chapter 9,", T_NOTE, TEXT, "end", True)
    f.value(400, 86, "Table 1", T_NOTE, anchor="start", records=tab, pad=5, what="the fill table")
    f.text(400, 120, "percent of raceway area", T_MIN, MUTED)
    for cx, n, pct, label in ((200, 1, "53%", "one"), (400, 2, "31%", "two"), (600, 4, "40%", "over two")):
        f.circle(cx, 220, 62, fill=BG, stroke=LINE, sw=SW_STRUCT)
        spots = {1: [(0, 0, 34)], 2: [(-24, 0, 22), (24, 0, 22)],
                 4: [(-20, -20, 17), (20, -20, 17), (-20, 20, 17), (20, 20, 17)]}[n]
        for dx, dy, r in spots:
            f.circle(cx + dx, 220 + dy, r, fill=WIRE_NEU, stroke=BG, sw=SW_THIN)
        f.text(cx, 322, label, T_NOTE, TEXT, bold=True)
        f.text(cx, 356, pct, T_VALUE, DIM, bold=True)
    f.text(400, 412, "LFNC conductor count stays within these limits", T_MIN, MUTED)
    f.tag(f.w - 24, f.h - 10, "NEC 356.22", anchor="end")
