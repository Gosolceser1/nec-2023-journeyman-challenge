"""Installation details: single-load circuits, enclosures, cords, batteries, boxes, airflow, signs, RV sites."""
from nec_style import *  # noqa: F401,F403


def _card(f, x, y, w, h, title=""):
    f.rect(x, y, w, h, fill=PANEL, stroke=EDGE, sw=SW_THIN, rx=8)
    if title:
        f.text(x + 14, y + 30, title, T_NOTE, TEXT, "start", True)


def _ocpd(f, x, y, w=56, h=64):
    f.rect(x, y, w, h, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=5)
    f.rect(x + w * 0.3, y + h * 0.25, w * 0.4, h * 0.5, fill=EDGE, stroke=TEXT, sw=SW_THIN, rx=3)


@figure("single_load_circuits_210-11_422-12", h=480, nec="210.11(C)(2), 210.52(F), 422.12",
        records={"open-book-exam-#1-020": {}, "final-exam-#3-039": {"when": "after"}})
def single_load(f):
    laundry = ["open-book-exam-#1-020"]
    f.title("Two dwelling circuits that serve one load each", y=34)
    f.panel(30, 80, 110, 230, label="panel", breakers=0)
    _ocpd(f, 57, 110, 56, 60)
    _ocpd(f, 57, 210, 56, 60)
    # Laundry.
    f.line(113, 140, 470, 140, WIRE_HOT, SW_WIRE)
    f.receptacle(500, 140, 56)
    f.rect(580, 90, 110, 110, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=6)
    f.circle(635, 150, 32, fill="none", stroke=TEXT, sw=SW_OBJ)
    f.text(635, 228, "washer", T_NOTE, MUTED)
    b = f.text(160, 110, "laundry circuit:", T_NOTE, TEXT, "start", True)
    f.value(b[0] + b[2] + 12, 110, "20 A", 26, anchor="start", records=laundry, pad=5)
    f.text(160, 176, "no other outlets", T_MIN, MUTED, "start")
    # Furnace.
    f.line(113, 240, 560, 240, WIRE_HOT, SW_WIRE)
    f.line(560, 240, 560, 280, WIRE_HOT, SW_WIRE)
    f.rect(500, 280, 130, 130, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=6)
    for k in range(4):
        f.line(520, 310 + k * 22, 610, 310 + k * 22, EDGE, 4)
    f.text(565, 440, "gas furnace", T_NOTE, MUTED)
    f.text(160, 226, "furnace circuit:", T_NOTE, TEXT, "start", True)
    f.lines(160, 300, ["individual branch circuit;", "its pump, valve, humidifier,", "air cleaner or A/C may share it"],
            T_MIN, MUTED, "start", gap=1.2)
    f.tag(f.w - 24, f.h - 10, "NEC 210.11(C)(2), 422.12", anchor="end")


@figure("ocpd_vertical_240-33", h=480, when="after", nec="240.33, 240.81",
        records={"final-exam-#3-015": {}, "open-book-exam-#2-001": {"like": "final-exam-#3-015"}})
def ocpd_vertical(f):
    f.title("How an overcurrent device enclosure is mounted", y=34)
    f.dline(400, 70, 400, 370, EDGE, SW_THIN)
    # Vertical fused switch: OK.
    f.rect(80, 90, 130, 200, fill=PANEL, stroke=TEXT, sw=SW_OBJ + 1, rx=5)
    f.line(210, 150, 236, 120, TEXT, 6)
    f.text(145, 320, "vertical", T_LABEL, OK, bold=True)
    f.mark_ok(145, 360)
    # Horizontal fused switch: not OK.
    f.rect(450, 110, 200, 120, fill=PANEL, stroke=TEXT, sw=SW_OBJ + 1, rx=5)
    f.line(650, 150, 676, 124, TEXT, 6)
    f.text(550, 262, "laid on its side", T_LABEL, NO, bold=True)
    f.mark_no(550, 300)
    f.lines(400, 408, ["Exceptions: breaker enclosures may lie horizontal if 'up' is still ON",
                       "(240.81); busway plug-in units follow the busway."], T_MIN, MUTED, gap=1.2)
    f.tag(f.w - 24, f.h - 8, "NEC 240.33", anchor="end")


@figure("room_ac_cord_440-64", h=460, nec="440.64, 440.65",
        records=["final-exam-#3-018"])
def room_ac(f):
    f.title("Cord-connected room air conditioner (elevation)", y=34)
    f.wall(420, 60, 420, thick=20)
    f.floor(420, 40, 780)
    f.rect(330, 120, 180, 110, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=6)
    for k in range(5):
        f.line(345, 140 + k * 16, 420, 140 + k * 16, EDGE, 3)
    f.text(440, 108, "room A/C", T_NOTE, TEXT, "start", True)
    f.path("M 400 230 C 390 300, 300 300, 260 350", TEXT, 5)
    f.receptacle(240, 370, 50)
    f.rect(252, 342, 26, 22, fill=AMBER, rx=3)
    b = f.text(40, 150, "cord, 120 V unit:", T_NOTE, TEXT, "start", True)
    f.value(40, 190, "10 ft max", 28, anchor="start", pad=6)
    f.text(40, 230, "208 or 240 V unit: 6 ft max", T_NOTE, MUTED, "start")
    f.lines(540, 300, ["plug has LCDI, AFCI or", "HDCI protection within", "12 in of the plug (440.65)"],
            T_MIN, MUTED, "start", gap=1.2)
    f.leader(536, 294, 280, 352, AMBER)
    f.tag(f.w - 24, f.h - 8, "NEC 440.64", anchor="end")


@figure("battery_ventilation_480-10a", h=450, nec="480.10(A)",
        records={"final-exam-#3-060": {"terms": ["explosive"]},
                 "open-book-exam-#6-018": {"like": "final-exam-#3-060"}})
def battery_vent(f):
    f.title("Battery room: gas must not build up (section)", y=34)
    f.ceiling(70, 40, 760)
    f.floor(380, 40, 760)
    f.wall(40, 70, 380, thick=14)
    f.wall(760, 70, 380, thick=14)
    f.rect(140, 300, 360, 16, fill=STEEL, stroke=LINE, sw=SW_THIN)
    for k in range(6):
        x = 150 + k * 58
        f.rect(x, 250, 48, 50, fill=PANEL_2, stroke=TEXT, sw=SW_THIN, rx=3)
        f.rect(x + 8, 242, 10, 8, fill=NO)
        f.rect(x + 30, 242, 10, 8, fill=TEXT)
    f.line(160, 316, 160, 380, STEEL, 8)
    f.line(480, 316, 480, 380, STEEL, 8)
    for k, (x, y) in enumerate(((190, 210), (260, 180), (330, 150), (400, 120), (300, 110), (450, 98))):
        f.circle(x, y, 7 + k % 3, fill="none", stroke=DIM, sw=SW_THIN)
    f.text(250, 236, "gas from the cells (some types)", T_MIN, MUTED, "start")
    f.rect(740, 84, 34, 60, fill=BG, stroke=TEXT, sw=SW_OBJ)
    f.arrow(700, 110, 790, 110, OK)
    f.text(690, 170, "high exhaust", T_NOTE, OK, "end", True)
    f.rect(26, 320, 34, 50, fill=BG, stroke=TEXT, sw=SW_OBJ)
    f.arrow(10, 345, 100, 345, OK)
    f.text(64, 406, "low inlet", T_NOTE, OK, "start", True)
    b = f.text(40, 436, "Ventilation prevents an", T_NOTE, TEXT, "start")
    v = f.value(b[0] + b[2] + 10, 436, "explosive", T_NOTE, anchor="start", pad=5, what="the mixture type")
    m = f.text(v[0] + v[2] + 16, 436, "mixture", T_NOTE, TEXT, "start")
    f.mask(m[0] - 5, m[1] - 5, m[2] + 10, m[3] + 10, records=["open-book-exam-#6-018"], what="the word mixture")
    f.tag(f.w - 24, f.h - 8, "NEC 480.10(A)", anchor="end")


@figure("box_screws_314-27d", h=440, nec="314.27(D) Exception, 314.27(A)",
        records={"open-book-exam-#4-019": {"terms": ["No. 6"]}})
def box_screws(f):
    f.title("Light equipment on an ordinary box (section)", y=34)
    f.wall(185, 60, 400, thick=110)
    f.rect(160, 150, 60, 140, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ)
    f.text(130, 138, "box", T_NOTE, MUTED, "end")
    f.rect(220, 140, 22, 160, fill=EDGE, stroke=TEXT, sw=SW_THIN)
    f.text(250, 128, "plaster ring", T_NOTE, MUTED, "start")
    f.rect(242, 150, 16, 140, fill=STEEL, stroke=TEXT, sw=SW_THIN)
    f.rect(258, 170, 150, 100, fill=PANEL, stroke=TEXT, sw=SW_OBJ, rx=10)
    f.text(333, 228, "equipment", T_NOTE, TEXT, bold=True)
    for y in (170, 270):
        f.line(200, y, 262, y, AMBER, 6)
        f.circle(262, y, 7, fill=AMBER)
    f.text(420, 330, "6 lb or less", T_LABEL, TEXT, "start", True)
    b = f.text(420, 150, "yoke held by two", T_NOTE, TEXT, "start")
    f.value(420, 190, "No. 6 or larger", 26, anchor="start", pad=6, what="the screw size")
    f.text(420, 228, "screws", T_NOTE, TEXT, "start")
    f.leader(416, 184, 268, 170, AMBER)
    f.lines(420, 380, ["heavier: the box must support it", "like a luminaire (314.27(A))"], T_MIN, MUTED, "start",
            gap=1.2)
    f.tag(24, f.h - 8, "NEC 314.27(D) Ex.")


@figure("equipment_airflow_110-13b", h=430, nec="110.13(B)",
        records={"open-book-exam-#7-008": {"terms": ["ventilating"]}})
def airflow(f):
    f.title("Equipment with side openings (plan view)", y=34)
    for x0, ok in ((40, False), (430, True)):
        f.line(x0, 90, x0, 330, LINE, SW_STRUCT + 6)
        gap = 70 if ok else 0
        bx = x0 + 10 + gap
        f.rect(bx, 150, 180, 120, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=5)
        for k in range(4):
            f.line(bx + 4, 170 + k * 24, bx + 16, 170 + k * 24, TEXT, 3)
            f.line(bx + 164, 170 + k * 24, bx + 176, 170 + k * 24, TEXT, 3)
        if ok:
            f.arrow(x0 + 20, 210, bx + 20, 210, OK)
            f.arrow(bx + 180, 210, bx + 250, 210, OK)
            f.mark_ok(bx + 90, 310)
            f.text(bx + 90, 362, "air flows through", T_NOTE, OK, bold=True)
        else:
            f.arrow(bx + 180, 210, bx + 250, 210, NO)
            f.mark_no(bx + 90, 310)
            f.text(bx + 90, 362, "wall blocks the openings", T_NOTE, NO, bold=True)
        f.text(x0 + 8, 80, "wall", T_MIN, MUTED, "start")
    b = f.text(40, 408, "Equipment with", T_NOTE, TEXT, "start")
    v = f.value(b[0] + b[2] + 10, 408, "ventilating", T_NOTE, anchor="start", pad=5, what="the opening type")
    f.text(v[0] + v[2] + 16, 408, "openings: keep the air path clear", T_NOTE, TEXT, "start")
    f.tag(f.w - 24, 80, "NEC 110.13(B)", anchor="end")


@figure("disconnect_relay_control_art100", h=440, nec="Article 100, 645.10",
        records={"open-book-exam-#10-006": {"terms": ["Remote Disconnect Control"]}})
def relay_control(f):
    f.title("Pushbutton that opens a disconnecting means through a relay", y=34)
    # Pushbutton station.
    f.rect(40, 110, 110, 130, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=6)
    f.circle(95, 175, 30, fill=NO, stroke=TEXT, sw=SW_OBJ)
    f.lines(95, 276, ["pushbutton", "(e.g. at the door)"], T_MIN, MUTED, gap=1.15)
    # Control circuit to relay.
    f.line(150, 160, 330, 160, AMBER, SW_WIRE - 1)
    f.line(150, 190, 330, 190, AMBER, SW_WIRE - 1)
    f.text(240, 146, "pushbutton circuit", T_MIN, AMBER)
    f.rect(330, 130, 110, 90, fill=PANEL, stroke=TEXT, sw=SW_OBJ, rx=6)
    f.path("M 350 175 q 10 -20 20 0 t 20 0 t 20 0 t 20 0", TEXT, 3)
    f.text(385, 250, "relay", T_NOTE, MUTED)
    f.line(440, 175, 560, 175, AMBER, SW_WIRE - 1)
    # Disconnect.
    f.rect(560, 90, 170, 190, fill=PANEL, stroke=TEXT, sw=SW_OBJ + 1, rx=6)
    f.rect(590, 120, 110, 60, fill=PANEL_2, stroke=TEXT, sw=SW_THIN, rx=4)
    f.text(645, 158, "operator", T_MIN, TEXT)
    for k in range(3):
        x = 600 + k * 45
        f.line(x, 200, x, 225, TEXT, 4)
        f.line(x, 225, x + 22, 250, TEXT, 4)
    f.text(645, 310, "disconnecting means", T_NOTE, TEXT, bold=True)
    f.text(645, 336, "(opens the power)", T_MIN, MUTED)
    b = f.text(40, 396, "The device and circuit together:", T_NOTE, TEXT, "start")
    f.value(b[0] + b[2] + 12, 396, "Remote Disconnect Control", T_NOTE, anchor="start", pad=5,
            what="the defined term")
    f.tag(f.w - 24, f.h - 8, "NEC Article 100", anchor="end")


@figure("welding_tray_signs_630-42c", h=400, when="after", nec="630.42(A), 630.42(C)",
        records=["open-book-exam-#10-008"])
def welding_tray(f):
    f.title("Dedicated cable tray for welding cables (elevation)", y=34)
    y = 150
    f.rect(40, y, 720, 40, fill="none", stroke=LINE, sw=SW_OBJ)
    for x in range(56, 760, 24):
        f.line(x, y, x, y + 40, EDGE, 3)
    for x in (90, 490):
        f.rect(x, y + 56, 260, 70, fill=AMBER, stroke=TEXT, sw=SW_THIN, rx=4)
        f.lines(x + 130, y + 84, ["CABLE TRAY FOR", "WELDING CABLES ONLY"], T_MIN, BG, bold=True, gap=1.15)
        f.line(x + 130, y + 40, x + 130, y + 56, TEXT, 3)
    f.ext(220, y + 130, 220, 304)
    f.ext(620, y + 130, 620, 304)
    f.dim_h(220, 620, 296)
    f.text(420, 330, "20 ft or less between signs", T_VALUE, DIM, bold=True)
    f.text(400, 372, "tray supports the cables at 6 in or less (630.42(A))", T_MIN, MUTED)
    f.tag(24, 100, "NEC 630.42(C)")


@figure("max_water_level_art100", h=420, nec="Article 100, 680.9, 680.22(B), 680.43(B)",
        records={"open-book-exam-#7-005": {"terms": ["Maximum Water Level"]},
                 "final-exam-#2-009": {"like": "open-book-exam-#7-005"}})
def max_water(f):
    f.title("Hot tub (section)", y=34)
    f.floor(320, 30, 770)
    x0, x1, top, bot = 180, 560, 150, 320
    f.rect(x0, top, x1 - x0, bot - top, fill=PANEL_2, stroke=LINE, sw=SW_OBJ)
    f.rect(x0 + 16, top, x1 - x0 - 32, bot - top - 16, fill=WATER, stroke=WATER_EDGE, sw=SW_THIN)
    f.path(f"M {x1 - 10} {top} q 30 10 30 60 q 0 40 10 110", WATER_EDGE, 4)
    f.text(x1 + 60, 250, "spills over", T_MIN, MUTED, "start")
    f.dline(60, top, 740, top, OK, SW_OBJ)
    f.value(70, top - 14, "Maximum Water Level", 26, anchor="start", pad=6, what="the defined term")
    f.lines(400, 364, ["the highest water can reach before it spills out;",
                       "Article 680 clearances and heights are measured from it"], T_MIN, MUTED, gap=1.2)
    f.tag(f.w - 24, 90, "NEC Article 100", anchor="end")


@figure("holiday_lighting_trees_590-4j", h=440, nec="590.4(J) Exception, 590.3(B)",
        records={"final-exam-#1-016": {"terms": ["strain relief"]},
                 "open-book-exam-#2-008": {"like": "final-exam-#1-016"}})
def holiday_trees(f):
    f.title("Holiday lighting span supported by a tree (elevation)", y=34)
    f.grade(390, 20, 780, label=None)
    # Tree.
    f.rect(96, 220, 30, 170, fill=WOOD, stroke="#ca8a04", sw=SW_THIN)
    f.circle(111, 160, 90, fill="#14532d", stroke="#166534", sw=SW_OBJ)
    # Pole.
    f.rect(680, 110, 20, 280, fill=STEEL, stroke=LINE, sw=SW_THIN)
    # Span with lamps.
    f.path("M 160 190 Q 420 290 680 140", TEXT, 3)
    for t in (0.2, 0.35, 0.5, 0.65, 0.8):
        x = (1 - t) ** 2 * 160 + 2 * (1 - t) * t * 420 + t * t * 680
        y = (1 - t) ** 2 * 190 + 2 * (1 - t) * t * 290 + t * t * 140
        f.circle(x, y + 12, 7, fill=AMBER)
    # Spring take-up at the tree.
    f.line(126, 190, 136, 190, TEXT, 3)
    f.path("M 136 190 l 4 -8 l 4 16 l 4 -16 l 4 16 l 4 -8", AMBER, 3)
    f.lines(230, 104, ["tension take-up device"], T_NOTE, TEXT, "start", True)
    f.leader(230, 112, 146, 186, AMBER)
    b = f.text(230, 150, "or", T_NOTE, MUTED, "start")
    f.value(b[0] + b[2] + 10, 150, "strain relief devices", T_NOTE, anchor="start", pad=5,
            what="the other permitted device")
    f.lines(400, 356, ["the tree moves and grows; the wiring must give",
                       "(holiday lighting only, 90 days max, 590.3(B))"], T_MIN, MUTED, gap=1.2)
    f.tag(f.w - 24, f.h - 10, "NEC 590.4(J) Ex.", anchor="end")


@figure("rv_park_supply_551-71_551-72", h=500, nec="551.71(A)-(C), 551.72(B)",
        records={"open-book-exam-#10-023": {}, "final-exam-#3-002": {"terms": ["two ungrounded"]}})
def rv_park(f):
    pct = ["open-book-exam-#10-023"]
    feeder = ["final-exam-#3-002"]
    f.title("RV park: receptacles per site and a 3-phase feeder", y=34)
    _card(f, 20, 56, 440, 400, "Sites with electrical supply")
    for k in range(6):
        x = 60 + (k % 3) * 130
        y = 110 + (k // 3) * 100
        f.rect(x, y, 90, 56, fill=PANEL_2, stroke=EDGE, sw=SW_THIN, rx=6)
        f.rect(x + 36, y + 14, 18, 28, fill=AMBER, stroke=TEXT, sw=SW_THIN, rx=2)
    f.text(36, 330, "every site: 20 A, 125 V", T_NOTE, TEXT, "start")
    b = f.text(36, 368, "30 A, 125 V: at least", T_NOTE, TEXT, "start")
    f.value(b[0] + b[2] + 10, 368, "70%", 26, anchor="start", records=pct, pad=5)
    f.text(36, 406, "50 A, 125/250 V: 40% new, 20% existing", T_NOTE, TEXT, "start")
    f.text(36, 438, "(all weather-resistant)", T_MIN, MUTED, "start")
    _card(f, 480, 56, 300, 400, "208Y/120 V 3-phase feeder")
    cx, cy = 630, 220
    f.circle(cx, cy, 86, fill=PANEL, stroke=LINE, sw=SW_STRUCT)
    for (dx, dy), c in zip(((-30, -30), (30, -30), (-30, 30), (30, 30)), (WIRE_HOT, WIRE_HOT, "#f8fafc", WIRE_GND)):
        f.circle(cx + dx, cy + dy, 22, fill=c, stroke=BG, sw=SW_THIN)
    f.lines(496, 350, ["2 ungrounded: permitted", "1 grounded conductor and", "1 EGC: both required"],
            T_MIN, TEXT, "start", gap=1.25)
    f.mask(490, 120, 280, 330, records=feeder, what="the feeder conductors")
    f.tag(24, f.h - 12, "NEC 551.71, 551.72(B)")
