"""Equipment installation figures: enclosures, disconnects, raceway entries, devices."""
from nec_style import *  # noqa: F401,F403


def _busway(f, x0, x1, y, th, joint=110):
    """Busway run, side view: housing with joint covers every `joint` units."""
    f.rect(x0, y - th / 2, x1 - x0, th, fill=STEEL, stroke=LINE, sw=SW_THIN, rx=2)
    f.line(x0 + 3, y - th * 0.18, x1 - 3, y - th * 0.18, TEXT, 1.5, op=0.35)
    x = x0 + joint
    while x < x1 - 30:
        f.rect(x - 6, y - th / 2 - 4, 12, th + 8, fill=PANEL_2, stroke=LINE, sw=1.5, rx=2)
        x += joint


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
    f.lines(410, 96, ["FLOOR-STANDING", "SWITCHBOARD"], T_NOTE, MUTED, bold=True, gap=1.15)
    xs = (290, 370, 450)
    for x in xs:
        f.rect(x - 22, 160, 44, 18, fill=TEXT, rx=3)
    f.text(538, 222, "busbars", T_NOTE, TEXT, bold=True)
    f.leader(530, 200, xs[-1] + 14, 172)
    f.concrete(40, ey1, 720, 44)
    f.text(60, ey1 - 12, "floor", T_NOTE, MUTED, "start")
    top = ey1 - 36
    for x in xs:
        f.line(x, top, x, 184, WIRE_HOT, SW_WIRE)
        f.rect(x - 7, 178, 14, 12, fill=CLAMP, stroke=TEXT, sw=1.5, rx=2)
        f.conduit(x, ey1 + 36, x, top + 8, width=22)
        f.rect(x - 17, top, 34, 12, fill=EDGE, stroke=TEXT, sw=SW_THIN, rx=2)
    f.lines(530, 272, ["end", "fitting"], T_NOTE, TEXT, bold=True, gap=1.15)
    f.leader(512, 304, x + 18, top + 4)
    f.ext(xs[-1] + 22, 178, 200, 178)
    f.dim_v(190, 178, ey1)
    f.lines(176, 260, ["busbar", "space:", "Table", "408.5"], T_NOTE, DIM, "end", True)
    f.ext(xs[-1] + 18, top, 640, top)
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
    bot = grade - 2 * ft
    ex0, ex1, top = 200, 300, bot - 110
    f.stud(244, top + 10, 14, grade - top - 10)
    f.conduit(230, bot, 230, grade + 20, width=12)
    f.disconnect(ex0, top, ex1 - ex0, bot - top, on=True, label="disconnect")
    # Handle grip in its highest (ON) position, as f.disconnect draws it.
    gx, hy = ex1 + 2 + (ex1 - ex0) * 0.26, top + (bot - top) * 0.10
    f.conduit(230, grade + 20, 670, grade + 20, width=12)
    f.conduit(670, grade + 20, 670, 350, width=12)
    f.ext(ex0, bot, 150, bot)
    f.dim_v(160, bot, grade)
    f.value_lines(146, bot + 28, ["24 in min", "(600 mm)"], 28, anchor="end", label="? min")
    f.ext(gx + 8, hy, 370, hy)
    f.dim_v(360, hy, grade)
    f.lines(376, hy + 22, ["handle grip,", "highest position:"], T_NOTE, MUTED, "start")
    f.lines(376, hy + 80, ["6 ft 7 in max", "(2.0 m)"], 28, DIM, "start", True)
    f.tag(f.w - 24, f.h - 10, "NEC 550.32(F)", anchor="end")


@figure("se_cable_gooseneck_230-54b", h=450, nec="230.54(B) Exception",
        records={"final-exam-#3-047": {"when": "after", "terms": ["gooseneck"]}})
def se_cable_gooseneck(f):
    wall = 420
    f.rect(wall, 60, f.w - 20 - wall, 370, fill=PANEL, stroke=EDGE, sw=SW_OBJ)
    f.text(680, 100, "BUILDING WALL", T_LABEL, MUTED, bold=True)
    f.text(680, 128, "(elevation)", T_NOTE, MUTED)
    cx, my, mr = 560, 362, 26
    f.line(cx, my - mr * 1.55, cx, 140, TEXT, 12)
    f.path(f"M {cx} 140 C {cx} 70 {cx - 90} 70 {cx - 90} 140", TEXT, 12)
    f.rect(cx - 98, 126, 16, 16, fill=EDGE, stroke=TEXT, sw=SW_THIN, rx=3)
    for dx in (-8, 0, 8):
        f.line(cx - 90 + dx, 142, cx - 90 + dx * 2, 162, WIRE_HOT, 3)
    f.meter(cx, my, mr, label="meter")
    f.strap(cx, 172, horizontal=False, size=26)
    f.lines(cx + 30, 172, ["strap within", "12 in"], T_NOTE, TEXT, "start")
    ax, ay = cx - 48, 235
    f.rect(ax - 4, ay - 14, 8, 28, fill=EDGE, stroke=TEXT, sw=1.5, rx=2)
    f.circle(ax, ay, 8, fill=BG, stroke=TEXT, sw=SW_OBJ)
    for dy in (-6, 0, 6):
        f.line(40, 160 + dy, ax - 8, ay + dy, WIRE_HOT, 3)
    f.path(f"M {ax - 6} {ay + 6} C {ax - 20} 300, {ax - 90} 290, {cx - 96} 166", WIRE_HOT, 3)
    f.text(50, 146, "service drop", T_NOTE, MUTED, "start")
    f.lines(190, 262, ["drip loop; attachment", "below the head end"], T_NOTE, MUTED)
    f.text(cx + 24, 286, "Type SE cable", T_NOTE, TEXT, "start", True)
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
    f.breaker(24, y - 42, 66, 84, poles=3)
    f.text(57, y - 54, "800 A", T_LABEL, TEXT, bold=True)
    _busway(f, 90, 540, y, 32)
    f.text(315, y - 34, "800 A busway", T_LABEL, TEXT, bold=True)
    f.breaker(542, y - 34, 58, 68, poles=3)
    _busway(f, 600, 770, y, 18, joint=90)
    f.text(685, y - 30, "200 A bus", T_LABEL, TEXT, bold=True)
    f.value_lines(620, 72, ["overcurrent", "protection required"], T_LABEL, OK, records=rid)
    f.mask(534, y - 42, 74, 84, records=rid, what="device drawn at the reduction")
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
    for x0, x1 in ((150, 355), (445, 650)):
        f.ext(x0, cy + 16, x0, 300)
        f.ext(x1, cy + 45, x1, 300)
        f.dim_h(x0, x1, 290)
        f.text((x0 + x1) / 2, 326, "secured within 3 ft", 24, DIM, bold=True)
    f.text(400, 376, "box not over 100 in3 (1650 cm3), no devices or luminaires", T_NOTE, TEXT, bold=True)
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
    f.receptacle(190, 198, 150, blank_center=True)
    f.value(190, 205, "WR", T_MIN, TEXT, what="WR marking on the face", pad=6)
    f.value_lines(190, 362, ["listed weather-", "resistant type"], 28)
    wall = 440
    f.rect(wall - 22, 70, 22, 330, fill=PANEL_2, stroke=LINE, sw=SW_THIN)
    f.rect(wall - 52, 178, 52, 110, fill=PANEL, stroke=TEXT, sw=SW_THIN)
    f.text(500, 104, "side", T_NOTE, MUTED)
    # Bubble hood, hinged at the top, translucent so the plug shows through.
    x2 = wall + 128
    f.path(f"M {wall} 140 L {x2 - 30} 150 Q {x2} 154 {x2} 184 L {x2} 300 Q {x2} 318 {x2 - 18} 320 "
           f"L {wall} 330 Z", TEXT, SW_OBJ, PANEL_2)
    f.add(f'<path d="M {wall + 4} 146 L {x2 - 30} 155 Q {x2 - 5} 159 {x2 - 5} 184 L {x2 - 5} 298 '
          f'Q {x2 - 5} 313 {x2 - 20} 315 L {wall + 4} 325 Z" fill="{BG}" fill-opacity="0.55" stroke="none"/>')
    f.rect(wall, 186, 12, 94, fill=PANEL_2, stroke=TEXT, sw=SW_THIN, rx=2)
    f.plug(wall + 30, 212, 40, 34, facing="left")
    f.cable([(wall + 70, 229), (wall + 92, 238), (wall + 104, 270), (wall + 106, 330),
             (wall + 112, 400)], WIRE_HOT, 6)
    f.circle(wall + 4, 142, 6, fill=EDGE, stroke=TEXT, sw=1.5)
    f.rect(wall + 94, 314, 24, 12, fill=BG, stroke=TEXT, sw=1.5, rx=3)
    f.lines(x2 + 16, 176, ["extra-duty", "in-use cover", "(outlet box hood)"], T_NOTE, TEXT, "start", True)
    f.lines(x2 + 16, 276, ["weatherproof with", "the plug inserted"], T_NOTE, MUTED, "start")
    f.text(wall + 50, 204, "plug", T_MIN, TEXT)
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
    f.path("M 230 300 C 230 410, 360 410, 400 366", TEXT, 5)
    f.rect(386, 340, 28, 34, fill=EDGE, stroke=TEXT, sw=SW_THIN, rx=6)
    f.text(300, 416, "cord", T_NOTE, TEXT, bold=True)
    f.floor(floor, 40, 450)
    x0, x18, x36, cy = 490, 610, 730, 205
    f.text(620, 70, "flexible cord, straightened", T_NOTE, MUTED, bold=True)
    f.rect(x0 - 12, cy - 8, 14, 16, fill=EDGE, stroke=TEXT, sw=1.5, rx=2)
    f.cable([(x0, cy), (x36, cy)], TEXT, 5)
    f.plug(x36, cy - 15, 34, 30, facing="right")
    f.ext(x0, cy - 6, x0, 150)
    f.ext(x36, cy - 12, x36, 150)
    f.dim_h(x0, x36, 160)
    f.value(610, 128, "36 in max (900 mm)", 28, label="? max")
    f.ext(x0, cy + 6, x0, 250)
    f.ext(x18, cy + 6, x18, 250)
    f.dim_h(x0, x18, 240)
    f.text(622, 249, "18 in min", 28, DIM, "start", True)
    f.text(622, 276, "(450 mm)", T_NOTE, DIM, "start")
    f.lines(476, 336, ["receptacle accessible,", "cord protected,", "grounding-type plug"], T_NOTE, MUTED, "start")
    f.tag(f.w - 24, f.h - 12, "NEC 422.16(B)(1)", anchor="end")
