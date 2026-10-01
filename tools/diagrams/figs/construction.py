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


@figure("switchboard_sections_408", h=536, nec="408.18(C), 408.3(A)(2)",
        records={"final-exam-#1-002": {"terms": ["front"]}, "open-book-exam-#1-015": {"terms": ["front"]},
                 "open-book-exam-#1-007": {"when": "after"}})
def switchboard_sections(f):
    mark = ["final-exam-#1-002", "open-book-exam-#1-015"]
    f.title("Switchboard: access marking and section wiring", y=34)
    # Plan view (looking down) with all four sides hidden.
    f.card(20, 56, 330, 432, "plan, looking down", align="middle")
    x0, y0, w, h = 90, 214, 190, 120
    f.rect(x0, y0, w, h, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ + 1)
    for k in (1, 2):
        f.line(x0 + k * w / 3, y0, x0 + k * w / 3, y0 + h, EDGE, 2)
    f.text(x0 + w / 2, y0 + h / 2 + 8, "sections", T_MIN, TEXT, bold=True)
    f.lines(185, 116, ["field connections need", "rear or side access"], T_MIN, AMBER, bold=True, gap=1.1)
    sides = [(x0 + w / 2, y0 - 36, "rear", NO), (x0 - 38, y0 + h / 2 + 7, "left", NO),
             (x0 + w + 36, y0 + h / 2 + 7, "right", NO), (x0 + w / 2, y0 + h + 44, "front", OK)]
    for sx, sy, name, color in sides:
        f.value(sx, sy, name, T_NOTE, color, records=mark, pad=6, what=f"the {name} side")
    f.value_lines(185, 440, ["marking goes on the", "side seen before opening"], T_MIN, TEXT, records=mark,
                  pad=6, gap=1.15, what="where the marking goes")
    # Elevation: conductors stay in the section where they terminate.
    f.card(370, 56, 410, 432, "elevation: three sections", align="middle")
    sw_, top, bot = 116, 120, 400
    xs = [396 + k * 126 for k in range(3)]
    rows = [186 + j * 68 for j in range(3)]
    for k, sx in enumerate(xs):
        f.rect(sx - 2, bot, sw_ + 4, 12, fill=STEEL, stroke=TEXT, sw=1.5)
        f.rect(sx, top, sw_, bot - top, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ + 1, rx=3)
        f.line(sx, 172, sx + sw_, 172, EDGE, SW_THIN)
        for cx in (sx + 12, sx + sw_ - 12):
            f.circle(cx, top + 12, 3, fill=EDGE)
            f.circle(cx, bot - 12, 3, fill=EDGE)
        if k == 0:
            f.breaker(sx + 10, 200, 70, 130, poles=3)
        else:
            for ry in rows:
                f.breaker(sx + 10, ry, 70, 54, poles=3)
    # Each section's own feed drops down its side gutter to the device it serves.
    for sx, ty in ((xs[0], 265), (xs[1], rows[1] + 27), (xs[2], rows[0] + 27)):
        f.polyline([(sx + 96, 96), (sx + 96, ty), (sx + 80, ty)], WIRE_HOT, SW_WIRE)
    f.polyline([(xs[0] + 108, 96), (xs[0] + 108, 150), (xs[1] + 86, 150), (xs[1] + 86, rows[0] + 27),
                (xs[1] + 80, rows[0] + 27)], NO, SW_WIRE)
    f.mark_no(xs[0] + sw_ + 5, 150, 13)
    f.lines(575, 446, ["only the conductors that end in a", "vertical section run in that section"],
            T_MIN, TEXT, gap=1.15)
    f.tag(f.w - 24, f.h - 10, "NEC 408.18(C), 408.3(A)(2)", anchor="end")


@figure("type_letters_decoder", h=516, nec="Table 310.4(1), 338.100, Table 400.4",
        records={"final-exam-#1-026": {}, "final-exam-#1-034": {}, "open-book-exam-#4-025": {},
                 "final-exam-#5-022": {"terms": ["USE"]}, "open-book-exam-#3-011": {"like": "final-exam-#1-026"}})
def type_letters(f):
    dash2 = ["final-exam-#1-026"]
    wet = ["final-exam-#1-034", "open-book-exam-#4-025"]
    burial = ["final-exam-#5-022"]
    f.title("Type letters decoder", y=34)
    f.card(20, 56, 250, 412, "building wire", align="middle")
    _rows(f, 34, 116, [("T", "thermoplastic"), ("R", "thermoset"), ("H", "75 C"), ("HH", "high heat,"),
                        ("", "dry or damp")])
    # On the cord questions the building-wire W and -2 rows would answer (or
    # mislead on SPT-2) by analogy, so they are masked there too.
    f.text(34, 266, "W", T_MIN, TEXT, "start", True)
    f.value(90, 266, "wet", T_MIN, MUTED, anchor="start", bold=False, records=wet, pad=5,
            what="what W means on building wire")
    _rows(f, 34, 296, [("N", "nylon jacket")])
    f.text(34, 340, "-2", T_NOTE, TEXT, "start", True)
    f.value_lines(90, 340, ["90 C, wet", "or dry"], T_MIN, anchor="start", records=dash2 + wet, pad=6, gap=1.15,
                  what="what the -2 means")
    f.text(34, 440, "e.g. RHW-2, THWN-2", T_MIN, MUTED, "start")
    f.card(285, 56, 230, 412, "cable", align="middle")
    _rows(f, 299, 116, [("NM", "dry, inside"), ("UF", "wet, direct"), ("", "burial")])
    f.text(299, 230, "service entrance:", T_MIN, MUTED, "start")
    _rows(f, 299, 262, [("SE", "above grade")])
    f.value_lines(299, 310, ["U = underground:", "USE, direct burial"], T_MIN, anchor="start", records=burial,
                  pad=6, gap=1.15, what="the underground service-entrance cable")
    f.card(530, 56, 250, 412, "flexible cord", align="middle")
    _rows(f, 544, 116, [("S", "hard service"), ("J", "junior (300 V)"), ("T", "thermoplastic"),
                         ("P", "parallel"), ("O", "oil-resistant"), ("OO", "jacket and")])
    f.text(600, 296, "insulation", T_MIN, MUTED, "start")
    f.text(544, 340, "W", T_NOTE, TEXT, "start", True)
    f.value_lines(600, 340, ["wet location,", "sunlight", "resistant"], T_MIN, anchor="start", records=wet,
                  pad=6, gap=1.15, what="what the W suffix means")
    f.tag(f.w - 24, f.h - 10, "NEC 310.4, 338, 400.4", anchor="end")


@figure("fcc_layers_324", h=540, nec="Article 100 (Bottom Shield, Top Shield, Transition Assembly), 324.40, 324.41",
        records={"final-exam-#5-001": {"terms": ["release", "adhesive"]},
                 "final-exam-#5-004": {"terms": ["transition"]},
                 "final-exam-#5-007": {"terms": ["bottom", "shield"]}})
def fcc_layers(f):
    glue = ["final-exam-#5-001"]
    trans = ["final-exam-#5-004"]
    bot = ["final-exam-#5-007"]
    f.title("Flat conductor cable under carpet squares (exploded, not to scale)", y=34)
    layers = [(90, "#6d28d9", "carpet square, 1.0 m (39.37 in) max", None, None),
              (150, AMBER, "release-type adhesive", glue, "how the square is held down"),
              (210, STEEL, "top shield (metal)", bot, "the layer above the cable"),
              (270, WIRE_NEU, "FCC cable (flat conductors)", None, None),
              (330, STEEL, "bottom shield", bot, "the layer between floor and cable"),
              (390, CONCRETE, "floor", None, None)]
    for y, color, name, recs, what in layers:
        f.poly([(60, y + 24), (120, y), (440, y), (380, y + 24)], color, TEXT, SW_THIN, 0.85)
        if recs:
            f.value(460, y + 18, name, T_MIN, TEXT, anchor="start", records=recs, pad=5, what=what)
        else:
            f.text(460, y + 18, name, T_MIN, TEXT, "start", True)
    # Flat copper conductors run the length of the cable layer.
    for t in (7, 12, 17):
        f.line(120 - 60 * t / 24 + 26, 270 + t, 440 - 60 * t / 24 - 26, 270 + t, ROD, 3)
    # Transition to other wiring at the wall.
    f.wall(760, 360, 520, 20)
    f.rect(620, 440, 120, 50, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=5)
    f.rect(628, 448, 104, 34, fill="none", stroke=EDGE, sw=1.5, rx=3)
    for sx, sy in ((636, 456), (724, 474)):
        f.circle(sx, sy, 3, fill=LINE)
    f.rect(440, 459, 180, 12, fill=WIRE_NEU, stroke=TEXT, sw=1)
    for yy in (462.5, 465, 467.5):
        f.line(446, yy, 614, yy, ROD, 1.5)
    f.line(740, 465, 750, 465, WIRE_HOT, SW_WIRE)
    f.value(600, 522, "transition assembly", T_MIN, records=trans, pad=5, what="where FCC meets other wiring")
    f.mask(612, 432, 136, 66, records=trans, what="the box at the wall")
    f.lines(300, 470, ["power feed and grounding", "connections to other wiring:"], T_MIN, MUTED, gap=1.15)
    f.tag(f.w - 24, 70, "NEC 324", anchor="end")


@figure("cable_cutaways_332_310", h=536, nec="332.104, 332.108, 332.116, Article 100 (MC), 310.3(B)",
        records={"final-exam-#5-020": {}, "open-book-exam-#10-015": {}, "final-exam-#5-003": {"terms": ["MC"]},
                 "final-exam-#2-045": {"like": "open-book-exam-#10-015"}})
def cable_cutaways(f):
    mi = ["final-exam-#5-020"]
    ccal = ["open-book-exam-#10-015"]
    mc = ["final-exam-#5-003"]
    f.title("Cable and conductor cross-sections (not to scale)", y=34)
    # MI cable.
    f.card(20, 56, 250, 432, "Type MI", align="middle")
    cx, cy = 145, 180
    f.circle(cx, cy, 68, fill=ROD, stroke=TEXT, sw=SW_OBJ)
    f.circle(cx, cy, 58, fill=TEXT, stroke=CLAMP, sw=1.5)
    for dx, dy in ((-22, -14), (22, -14), (0, 24)):
        f.circle(cx + dx, cy + dy, 13, fill=ROD, stroke=CLAMP, sw=SW_THIN)
    f.text(cx, 278, "mineral insulation", T_MIN, MUTED)
    f.value_lines(cx, 318, ["solid copper", "conductors"], T_MIN, records=mi, pad=5, gap=1.1)
    f.value_lines(cx, 378, ["sheath: mechanical", "protection"], T_MIN, records=mi, pad=5, gap=1.1)
    f.value_lines(cx, 438, ["sheath: grounding", "path"], T_MIN, records=mi, pad=5, gap=1.1)
    # MC cable.
    f.card(285, 56, 230, 432)
    b = f.text(390, 86, "Type", T_NOTE, TEXT, "end", True)
    f.value(398, 86, "MC", T_NOTE, anchor="start", records=mc, pad=5, what="the cable type")
    _mc_armor(f, 302, 148, 136, 64)
    for k, color in enumerate((NO, WIRE_NEU, WIRE_GND)):
        y = 166 + k * 14
        f.polyline([(438, 180), (452, y), (488, y)], color, 10)
        f.line(488, y, 502, y, ROD, 5)
    f.path("M 438 148 a 10 32 0 1 1 0 64 a 10 32 0 1 1 0 -64", TEXT, SW_THIN, PANEL)
    for k, color in enumerate((NO, WIRE_NEU, WIRE_GND)):
        f.circle(438, 168 + k * 12, 5, fill=color)
    f.lines(400, 290, ["interlocking metal", "tape armor (or smooth /", "corrugated sheath)"], T_MIN, TEXT,
            gap=1.15)
    f.lines(400, 390, ["insulated conductors", "inside"], T_MIN, MUTED, gap=1.15)
    # Copper-clad aluminum.
    f.card(530, 56, 250, 432, "copper-clad aluminum", align="middle")
    cx = 640
    f.circle(cx, cy, 64, fill=ROD, stroke=TEXT, sw=SW_OBJ)
    f.circle(cx, cy, 55, fill=CONCRETE, stroke=CLAMP, sw=1.5)
    f.text(cx, cy + 8, "aluminum", T_MIN, BG, bold=True)
    f.text(742, 134, "copper", T_MIN, TEXT, "middle", True)
    f.leader(714, 140, cx + 42, cy - 42)
    f.text(655, 278, "copper bonded to", T_MIN, MUTED)
    f.text(655, 302, "an aluminum core", T_MIN, MUTED)
    f.text(cx, 360, "copper share of area:", T_MIN, TEXT, bold=True)
    f.value(cx, 400, "at least 10%", T_NOTE, records=ccal, pad=6, what="minimum copper share")
    f.tag(f.w - 24, f.h - 10, "NEC 332, 310.3(B)", anchor="end")


@figure("raceway_fill_ch9_348-22", h=536, nec="Chapter 9 Table 1, 348.22, Table 348.22, 356.22",
        records={"final-exam-#5-032": {}, "final-exam-#3-048": {}, "final-exam-#5-066": {},
                 "final-exam-#4-003": {"like": "final-exam-#5-066"}})
def raceway_fill(f):
    big = ["final-exam-#5-032", "final-exam-#3-048"]
    tab = ["final-exam-#5-066"]
    f.title("Raceway fill: which table?", y=34)
    f.card(20, 56, 470, 432)
    b = f.text(200, 86, "Chapter 9,", T_NOTE, TEXT, "end", True)
    f.value(210, 86, "Table 1", T_NOTE, anchor="start", records=tab, pad=5, what="the fill table")
    f.text(255, 116, "percent of raceway area", T_MIN, MUTED)
    for k, (cx, n, pct, label) in enumerate(((100, 1, "53%", "one"), (255, 2, "31%", "two"),
                                             (410, 4, "40%", "over two"))):
        f.circle(cx, 220, 62, fill=BG, stroke=LINE, sw=SW_STRUCT)
        spots = {1: [(0, 0, 34)], 2: [(-24, 0, 22), (24, 0, 22)],
                 4: [(-20, -20, 17), (20, -20, 17), (-20, 20, 17), (20, 20, 17)]}[n]
        for dx, dy, r in spots:
            f.circle(cx + dx, 220 + dy, r, fill=WIRE_NEU, stroke=BG, sw=SW_THIN)
        f.text(cx, 322, label, T_NOTE, TEXT, bold=True)
        f.text(cx, 356, pct, T_VALUE, DIM, bold=True)
    f.text(34, 410, "LFNC:", T_NOTE, TEXT, "start", True)
    f.value(112, 410, "356.22 sends you to Table 1", T_MIN, anchor="start", records=tab, pad=5,
            what="where LFNC fill comes from")
    f.text(34, 450, "(most raceways work the same way)", T_MIN, MUTED, "start")
    f.card(510, 56, 270, 432, "trade size 3/8 FMC", align="middle")
    _fmc_side(f, 560, 164, 180, 52)
    f.text(524, 290, "too small for", T_MIN, TEXT, "start")
    f.text(524, 316, "Chapter 9: own table", T_MIN, TEXT, "start")
    f.text(524, 348, "Table 348.22", T_NOTE, DIM, "start", True)
    f.text(524, 392, "largest THHN:", T_MIN, TEXT, "start", True)
    f.value(645, 440, "10 AWG", T_VALUE, records=big, pad=6, what="largest conductor")
    f.tag(f.w - 24, f.h - 10, "NEC Ch. 9, 348.22", anchor="end")
