"""Equipment installation figures: enclosures, disconnects, raceway entries, devices."""
from nec_style import *  # noqa: F401,F403


def _breaker(f, x, y, w=60, h=70):
    """Small breaker/OCPD body with a handle, top-left at (x, y)."""
    f.rect(x, y, w, h, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=5)
    f.rect(x + w * 0.3, y + h * 0.25, w * 0.4, h * 0.5, fill=EDGE, stroke=TEXT, sw=SW_THIN, rx=3)


@figure("fuel_dispenser_shutoff_514-11", h=450, nec="514.11(A)",
        records={"final-exam-#1-028": {}, "open-book-exam-#3-009": {"like": "final-exam-#1-028"}})
def fuel_dispenser_shutoff(f):
    f.title("Emergency shutoff location (plan view, not to scale)", y=40)
    ix0, ix1, iy0, iy1 = 60, 150, 120, 290
    dx = 130
    f.hatch(dx, iy0, 290 - dx, iy1 - iy0, NO, op=0.10)
    f.rect(ix0, iy0, ix1 - ix0, iy1 - iy0, fill=PANEL, stroke=EDGE, sw=SW_OBJ, rx=8)
    for y in (140, 215):
        f.rect(80, y, 50, 55, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=4)
    f.lines(105, 76, ["fuel", "dispensers"], T_NOTE, TEXT, bold=True)
    f.lines(220, 190, ["too", "close"], T_NOTE, NO, bold=True)
    bx0 = 620
    f.rect(bx0, 90, 160, 220, fill=PANEL, stroke=EDGE, sw=SW_OBJ)
    f.text(700, 130, "BUILDING", T_LABEL, MUTED, bold=True)
    f.circle(bx0, 205, 16, fill=NO, stroke=TEXT, sw=SW_OBJ)
    f.lines(520, 150, ["emergency", "shutoff"], T_LABEL, TEXT, bold=True)
    f.leader(520, 180, bx0 - 18, 203)
    f.ext(dx, 272, dx, 400)
    f.ext(290, iy1, 290, 345)
    f.ext(bx0, 225, bx0, 400)
    f.dim_h(dx, 290, 335)
    f.text(304, 345, "20 ft (6 m) min", 28, DIM, "start", True)
    f.dim_h(dx, bx0, 390)
    f.value(385, 425, "100 ft (30 m) max", 30, label="? max")
    f.tag(f.w - 24, f.h - 14, "NEC 514.11(A)", anchor="end")


@figure("conduit_stub_up_408-5", h=470, nec="408.5, Table 408.5",
        records={"final-exam-#1-029": {}, "open-book-exam-#3-008": {"like": "final-exam-#1-029"}})
def conduit_stub_up(f):
    f.title("Section: conduits entering the bottom", y=36)
    ex0, ex1, ey0, ey1 = 220, 600, 60, 380
    f.rect(ex0, ey0, ex1 - ex0, ey1 - ey0, fill=PANEL, stroke=TEXT, sw=SW_OBJ + 1, rx=6)
    f.text(410, 100, "FLOOR-STANDING SWITCHBOARD", T_NOTE, MUTED, bold=True)
    for x in (300, 400, 500):
        f.rect(x - 22, 160, 44, 18, fill=TEXT, rx=3)
    f.text(410, 146, "busbars", T_NOTE, TEXT, bold=True)
    f.concrete(40, ey1, 720, 44)
    f.text(60, ey1 - 12, "floor", T_NOTE, MUTED, "start")
    top = ey1 - 36
    for x in (300, 400, 500):
        f.conduit(x, ey1 + 44, x, top + 8, width=22)
        f.rect(x - 17, top, 34, 12, fill=EDGE, stroke=TEXT, sw=SW_THIN, rx=2)
    f.lines(400, 280, ["conduit end fitting"], T_NOTE, TEXT, bold=True)
    f.leader(400, 290, 400, top - 2)
    f.ext(ex1 - 60, 178, 200, 178)
    f.dim_v(190, 178, ey1)
    f.lines(176, 260, ["busbar", "space:", "Table", "408.5"], T_NOTE, DIM, "end", True)
    f.ext(518, top, 640, top)
    f.dim_v(630, top, ey1)
    f.value_lines(646, 346, ["3 in max", "(75 mm)"], 28, anchor="start", label="? max")
    f.tag(f.w - 24, f.h - 12, "NEC 408.5", anchor="end")


@figure("mobile_home_disconnect_550-32f", h=470, nec="550.32(F)",
        records={"final-exam-#1-052": {}, "final-exam-#3-051": {},
                 "open-book-exam-#5-015": {"like": "final-exam-#1-052"}})
def mobile_home_disconnect(f):
    grade, ft = 400, 36.0
    f.title("Outdoor mobile home disconnecting means", y=40)
    f.rect(560, 150, 220, 200, fill=PANEL, stroke=EDGE, sw=SW_OBJ)
    f.text(670, 200, "MOBILE HOME", T_LABEL, MUTED, bold=True)
    for x in (580, 760):
        f.rect(x - 8, 350, 16, grade - 350, fill=PANEL_2, stroke=EDGE, sw=SW_THIN)
    f.grade(grade, label=None, soil_h=32)
    f.text(396, grade - 10, "finished grade", T_NOTE, MUTED, "start")
    f.stud(244, 170, 14, grade - 170)
    bot = grade - 2 * ft
    ex0, ex1, top = 200, 300, bot - 110
    f.rect(ex0, top, ex1 - ex0, bot - top, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ + 1, rx=5)
    f.text(250, top - 14, "disconnect", T_LABEL, TEXT, bold=True)
    hy = top + 22
    f.line(ex1, hy + 30, ex1 + 22, hy, TEXT, 7)
    f.circle(ex1 + 22, hy, 6, fill=TEXT)
    f.conduit(230, bot, 230, grade + 20, width=12)
    f.conduit(230, grade + 20, 670, grade + 20, width=12)
    f.conduit(670, grade + 20, 670, 350, width=12)
    f.ext(ex0, bot, 150, bot)
    f.dim_v(160, bot, grade)
    f.value_lines(146, bot + 28, ["24 in min", "(600 mm)"], 28, anchor="end", label="? min")
    f.ext(ex1 + 28, hy, 370, hy)
    f.dim_v(360, hy, grade)
    f.lines(376, hy + 22, ["handle grip,", "highest position:"], T_NOTE, MUTED, "start")
    f.lines(376, hy + 80, ["6 ft 7 in max", "(2.0 m)"], 28, DIM, "start", True)
    f.tag(f.w - 24, f.h - 10, "NEC 550.32(F)", anchor="end")


@figure("se_cable_gooseneck_230-54b", h=450, nec="230.54(B) Exception, 230.54(C), 230.51(A)",
        records={"final-exam-#3-047": {"when": "after", "terms": ["gooseneck"]}})
def se_cable_gooseneck(f):
    wall = 520
    f.rect(wall, 60, f.w - 20 - wall, 370, fill=PANEL, stroke=EDGE, sw=SW_OBJ)
    f.line(wall, 60, wall, 430, LINE, SW_STRUCT + 1)
    f.text(650, 100, "BUILDING", T_LABEL, MUTED, bold=True)
    f.text(650, 128, "(side view)", T_NOTE, MUTED)
    cx = wall - 30
    f.rect(wall - 55, 320, 50, 80, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=6)
    f.text(wall - 66, 372, "meter", T_NOTE, TEXT, "end", True)
    f.line(cx, 320, cx, 140, TEXT, 12)
    f.path(f"M {cx} 140 C {cx} 70 {cx - 90} 70 {cx - 90} 140", TEXT, 12)
    f.rect(cx - 104, 118, 28, 14, fill=EDGE, stroke=TEXT, sw=SW_THIN, rx=3)
    for dx in (-8, 0, 8):
        f.line(cx - 90 + dx, 140, cx - 90 + dx * 2, 162, WIRE_HOT, 3)
    f.strap(cx, 172, horizontal=False, size=26)
    f.lines(wall + 16, 180, ["strap within", "12 in"], T_NOTE, TEXT, "start")
    f.leader(wall + 12, 176, cx + 14, 172)
    ax, ay = cx - 48, 235
    f.line(ax, ay, cx - 6, ay, LINE, 4)
    f.circle(ax, ay, 8, fill=BG, stroke=TEXT, sw=SW_OBJ)
    for dy in (-6, 0, 6):
        f.line(40, 160 + dy, ax - 8, ay + dy, WIRE_HOT, 3)
    f.path(f"M {ax - 6} {ay + 6} C {ax - 20} 300, {ax - 90} 290, {cx - 96} 166", WIRE_HOT, 3)
    f.text(50, 146, "service drop", T_NOTE, MUTED, "start")
    f.lines(190, 262, ["drip loop; attachment", "below the head end"], T_NOTE, MUTED)
    f.text(cx - 22, 318, "Type SE cable", T_NOTE, TEXT, "end", True)
    f.value_lines(210, 64, ["gooseneck, taped"], T_LABEL, OK, records=["final-exam-#3-047"])
    f.leader(300, 72, cx - 70, 96, OK)
    f.lines(36, 380, ["tape: self-sealing weather-resistant", "thermoplastic (no service head)"],
            T_NOTE, MUTED, "start")
    f.tag(f.w - 24, f.h - 14, "NEC 230.54(B) Ex.", anchor="end")


@figure("busway_reduction_368-17b", h=470, nec="368.17(B) and its Exception",
        records=["final-exam-#5-052"])
def busway_reduction(f):
    rid = ["final-exam-#5-052"]
    f.title("Commercial warehouse: 300 ft busway run", y=40)
    y = 170
    _breaker(f, 30, y - 35)
    f.text(60, y - 50, "800 A", T_LABEL, TEXT, bold=True)
    f.line(90, y, 540, y, STEEL, 30)
    f.line(90, y - 15, 540, y - 15, LINE, 2)
    f.line(90, y + 15, 540, y + 15, LINE, 2)
    f.text(315, y - 30, "800 A busway", T_LABEL, TEXT, bold=True)
    _breaker(f, 545, y - 30, 50, 60)
    f.line(600, y, 770, y, STEEL, 16)
    f.line(600, y - 8, 770, y - 8, LINE, 2)
    f.line(600, y + 8, 770, y + 8, LINE, 2)
    f.text(685, y - 30, "200 A bus", T_LABEL, TEXT, bold=True)
    f.value_lines(620, 72, ["overcurrent", "protection required"], T_LABEL, OK, records=rid)
    f.mask(537, y - 38, 66, 76, records=rid, what="device drawn at the reduction")
    f.ext(90, y + 20, 90, 320)
    f.ext(770, y + 20, 770, 320)
    f.ext(600, y + 20, 600, 262)
    f.dim_h(600, 770, 252)
    f.text(685, 290, "last 20 ft", 28, DIM, bold=True)
    f.dim_h(90, 770, 312)
    f.text(345, 302, "300 ft", 28, DIM, bold=True)
    f.rect(30, 336, 570, 122, fill=PANEL, stroke=EDGE, sw=SW_THIN, rx=8)
    f.lines(44, 362, ["Exception, industrial establishments only: smaller bus",
                      "no longer than 50 ft (15 m) and at least 1/3 of the",
                      "rating of the device next back on the line.",
                      "A warehouse is not industrial: 200 A < 800/3"], T_NOTE, MUTED, "start")
    f.mask(30, 336, 570, 122, records=rid, what="industrial-only exception box")
    f.mark_no(566, 436)
    f.tag(f.w - 24, f.h - 12, "NEC 368.17(B)", anchor="end")


@figure("raceway_supported_box_314-23e", h=450, nec="314.23(E)",
        records={"open-book-exam-#10-013": {}, "final-exam-#2-044": {"like": "open-book-exam-#10-013"}})
def raceway_supported_box(f):
    rid = ["open-book-exam-#10-013"]
    cy, ceil = 210, 120
    f.ceiling(ceil, 40, 760)
    f.text(46, ceil - 12, "structure", T_NOTE, MUTED, "start")
    f.conduit(40, cy, 350, cy, width=16)
    f.conduit(450, cy, 760, cy, width=16)
    for x in (150, 650):
        f.line(x, ceil, x, cy - 12, LINE, 3)
        f.strap(x, cy, horizontal=True, size=30)
    f.box(400, cy, 90, fill=PANEL_2)
    for x0 in (338, 446):
        f.rect(x0, cy - 16, 16, 32, fill=EDGE, stroke=TEXT, sw=SW_THIN, rx=2)
        for k in range(4):
            f.line(x0 + 3 + k * 3.5, cy - 14, x0 + 3 + k * 3.5, cy + 14, BG, 1)
    f.mask(328, cy - 26, 36, 52, records=rid, what="threaded hub at the box entry")
    f.mask(436, cy - 26, 36, 52, records=rid, what="threaded hub at the box entry")
    f.value_lines(400, 50, ["threaded wrenchtight into the", "box or identified hubs"], 26, records=rid)
    f.lines(400, 285, ["box not over 100 in3 (1650 cm3)", "no devices or luminaires"], T_NOTE, TEXT, bold=True)
    for x0, x1 in ((150, 355), (445, 650)):
        f.ext(x0, cy + 16, x0, 360)
        f.ext(x1, cy + 45, x1, 360)
        f.dim_h(x0, x1, 350)
        f.text((x0 + x1) / 2, 388, "secured within 3 ft", 24, DIM, bold=True)
    f.text(30, 432, "(within 18 in if all entries are on one side)", T_NOTE, MUTED, "start")
    f.tag(f.w - 24, f.h - 14, "NEC 314.23(E)", anchor="end")


@figure("nm_cable_sleeve_312-5c", h=470, nec="312.5(C) Exception No. 1",
        records=["open-book-exam-#4-018"])
def nm_cable_sleeve(f):
    rx, rtop, px0, px1, ptop = 280, 110, 200, 360, 300
    f.panel(px0, ptop, px1 - px0, 150, label=None)
    f.lines(190, 350, ["surface-", "mounted", "enclosure"], T_NOTE, TEXT, "end", True)
    f.conduit(rx, ptop, rx, rtop, width=24)
    for y in (ptop - 6, rtop):
        f.rect(rx - 19, y - 4, 38, 12, fill=EDGE, stroke=TEXT, sw=SW_THIN, rx=2)
    f.rect(rx - 15, rtop - 10, 30, 8, fill=AMBER, rx=2)
    for dx, yy in ((-5, 58), (5, 72)):
        f.cable([(rx + dx, ptop + 20), (rx + dx, yy + 26), (rx + dx + 26, yy), (780, yy)], WIRE_NEU, 5)
    f.strap(400, 65, horizontal=True, size=34)
    f.text(560, 108, "nonmetallic-sheathed cables", T_NOTE, TEXT, bold=True)
    f.ext(rx, 42, rx, rtop - 14)
    f.ext(400, 30, 400, 46)
    f.dim_h(rx, 400, 30)
    f.text(415, 40, "12 in max along sheath", 26, DIM, "start", True)
    f.ext(rx + 20, rtop, 340, rtop)
    f.dim_v(330, rtop, ptop)
    f.value_lines(346, 170, ["18 in min", "(450 mm)"], 28, anchor="start", label="? min")
    f.lines(346, 256, ["to 10 ft max (3.0 m)"], 26, DIM, "start", True)
    f.lines(390, 330, ["fitting on each end", "outer end sealed or plugged", "raceway directly above,",
                       "no structural ceiling penetrated"], T_NOTE, MUTED, "start")
    f.tag(f.w - 24, f.h - 10, "NEC 312.5(C) Ex. 1", anchor="end")


@figure("wet_location_receptacle_406-9b", h=450, nec="406.9(B)(1)",
        records={"final-exam-#1-042": {"terms": ["WR"]}, "open-book-exam-#4-014": {"terms": ["WR"]}})
def wet_location_receptacle(f):
    f.title("Wet location: 15 or 20 A, 125 or 250 V nonlocking receptacle", y=40)
    f.rect(40, 70, 300, 250, fill=PANEL, stroke=EDGE, sw=SW_OBJ, rx=6)
    f.text(190, 104, "front", T_NOTE, MUTED)
    f.receptacle(190, 200, 120)
    f.value(190, 208, "WR", T_MIN, TEXT, what="WR marking on the face", pad=6)
    f.value_lines(190, 362, ["listed weather-", "resistant type"], 28)
    wall = 470
    f.line(wall, 70, wall, 400, LINE, SW_STRUCT + 1)
    f.rect(wall, 70, 290, 330, fill=PANEL, op=0.0)
    f.text(560, 104, "side", T_NOTE, MUTED)
    f.poly([(wall, 140), (560, 160), (560, 320), (wall, 330)], PANEL_2, TEXT, SW_OBJ, op=0.8)
    f.rect(wall + 18, 215, 36, 34, fill=EDGE, stroke=TEXT, sw=SW_THIN, rx=4)
    f.cable([(wall + 36, 249), (wall + 50, 322), (wall + 66, 400)], WIRE_HOT, 6)
    f.text(wall + 36, 204, "plug", T_MIN, TEXT)
    f.lines(575, 190, ["extra-duty", "in-use cover", "(outlet box hood)"], T_NOTE, TEXT, "start", True)
    f.lines(575, 290, ["weatherproof with", "the plug inserted"], T_NOTE, MUTED, "start")
    f.tag(f.w - 24, f.h - 14, "NEC 406.9(B)(1)", anchor="end")


@figure("disposer_cord_422-16b1", h=470, nec="422.16(B)(1)",
        records=["final-exam-#1-045", "open-book-exam-#4-006"])
def disposer_cord(f):
    top, floor = 110, 430
    f.rect(50, top, 390, floor - top, fill=PANEL, stroke=EDGE, sw=SW_OBJ)
    f.line(40, top, 450, top, LINE, 10)
    f.text(60, top - 16, "sink base cabinet", T_NOTE, MUTED, "start")
    f.rect(140, top, 180, 70, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=10)
    f.text(230, top + 44, "sink", T_NOTE, TEXT, bold=True)
    f.line(230, top + 70, 230, 200, STEEL, 16)
    f.rect(190, 200, 80, 100, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=12)
    f.text(180, 262, "disposer", T_NOTE, TEXT, "end", True)
    f.receptacle(400, 340, 44)
    f.path("M 230 300 C 230 400, 340 400, 380 350", TEXT, 5)
    f.text(300, 416, "cord", T_NOTE, TEXT, bold=True)
    f.floor(floor, 40, 450)
    x0, x18, x36, cy = 490, 620, 750, 205
    f.text(620, 70, "flexible cord, straightened", T_NOTE, MUTED, bold=True)
    f.cable([(x0, cy), (x36, cy)], TEXT, 5)
    f.rect(x36 - 4, cy - 10, 20, 20, fill=EDGE, stroke=TEXT, sw=SW_THIN, rx=3)
    f.ext(x0, cy - 6, x0, 150)
    f.ext(x36, cy - 12, x36, 150)
    f.dim_h(x0, x36, 160)
    f.value(620, 128, "36 in max (900 mm)", 28, label="? max")
    f.ext(x0, cy + 6, x0, 250)
    f.ext(x18, cy + 6, x18, 250)
    f.dim_h(x0, x18, 240)
    f.text(632, 249, "18 in min", 28, DIM, "start", True)
    f.text(632, 276, "(450 mm)", T_NOTE, DIM, "start")
    f.lines(476, 336, ["receptacle accessible,", "cord protected,", "grounding-type plug"], T_NOTE, MUTED, "start")
    f.tag(f.w - 24, f.h - 12, "NEC 422.16(B)(1)", anchor="end")
