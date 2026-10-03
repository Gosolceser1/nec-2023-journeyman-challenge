"""Installation details: single-load circuits, enclosures, cords, batteries, boxes, airflow, signs, RV sites."""
from nec_style import *  # noqa: F401,F403


def _plug_cap(f, cx, cy, s):
    """Attachment plug seen from the cord end, inserted in the face at (cx, cy)."""
    f.rect(cx - s * 0.42, cy - s * 0.48, s * 0.84, s, fill=EDGE, stroke=TEXT, sw=SW_THIN, rx=s * 0.2)
    return cx, cy + s * 0.52


def _washer(f, x, y, w=110, h=124):
    """Front-load washer: cabinet, control strip with a dial, door and its glass."""
    f.rect(x, y, w, h, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=6)
    f.line(x + 3, y + h * 0.2, x + w - 3, y + h * 0.2, EDGE, SW_THIN)
    f.rect(x + w * 0.1, y + h * 0.06, w * 0.4, h * 0.08, fill=BG, rx=2)
    f.circle(x + w * 0.78, y + h * 0.1, max(4.0, h * 0.05), fill=LINE)
    cx, cy, r = x + w / 2, y + h * 0.6, min(w, h) * 0.3
    f.circle(cx, cy, r, fill=EDGE, stroke=TEXT, sw=SW_OBJ)
    f.circle(cx, cy, r * 0.7, fill=BG, stroke=LINE, sw=SW_THIN)


@figure("laundry_circuit_210-11c2", h=400, nec="210.11(C)(2)", records=["open-book-exam-#1-020"])
def laundry_circuit(f):
    f.title("Dwelling laundry: its own branch circuit", y=34)
    f.panel(30, 90, 110, 200, label="panel", breakers=0)
    f.breaker(57, 150, 56, 64)
    f.line(113, 182, 472, 182, WIRE_HOT, SW_WIRE)
    f.receptacle(500, 182, 70)
    px, py = _plug_cap(f, 500, 198, 30)
    f.cable([(px, py), (px + 6, py + 30), (580, py + 40), (620, py + 24)], TEXT, 4)
    _washer(f, 610, 120, 130, 150)
    f.text(675, 300, "washer", T_NOTE, MUTED)
    b = f.text(170, 150, "laundry circuit:", T_NOTE, TEXT, "start", True)
    f.value(b[0] + b[2] + 12, 150, "20 A", 26, anchor="start", pad=5, what="the circuit rating")
    f.text(170, 220, "no other outlets on it", T_NOTE, MUTED, "start")
    f.text(170, 248, "(in addition to the other circuits)", T_MIN, MUTED, "start")
    f.tag(24, f.h - 12, "NEC 210.11(C)(2)")


@figure("furnace_circuit_422-12", h=400, nec="422.12", when="after", records=["final-exam-#3-039"])
def furnace_circuit(f):
    f.title("Central heating equipment: its own branch circuit", y=34)
    f.panel(30, 90, 110, 200, label="panel", breakers=0)
    f.breaker(57, 150, 56, 64)
    fx, fy, fw, fh = 560, 150, 130, 170
    f.line(113, 182, fx, 182, WIRE_HOT, SW_WIRE)
    f.rect(fx + 90, fy - 40, 26, 42, fill=STEEL, stroke=LINE, sw=SW_THIN)
    f.rect(fx, fy, fw, fh, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=5)
    f.rect(fx + 8, fy + 10, fw - 16, fh * 0.42, fill="none", stroke=EDGE, sw=SW_THIN, rx=3)
    f.rect(fx + 8, fy + 18 + fh * 0.42, fw - 16, fh * 0.48 - 26, fill="none", stroke=EDGE, sw=SW_THIN, rx=3)
    for k in range(4):
        f.line(fx + 20, fy + 24 + k * 12, fx + fw - 20, fy + 24 + k * 12, EDGE, 3)
    f.text(fx + fw / 2, fy + fh + 30, "gas furnace", T_NOTE, MUTED)
    f.text(170, 160, "individual branch circuit", T_NOTE, OK, "start", True)
    f.highlight(160, 132, 310, 40)
    f.lines(170, 240, ["its pump, valve, humidifier,", "air cleaner or A/C", "may share it"], T_MIN, MUTED, "start",
            gap=1.2)
    f.tag(24, f.h - 12, "NEC 422.12")


@figure("ocpd_vertical_240-33", h=480, when="after", nec="240.33", records=["final-exam-#3-015"])
def ocpd_vertical(f):
    f.title("How an overcurrent device enclosure is mounted", y=34)
    f.dline(400, 70, 400, 370, EDGE, SW_THIN)
    f.disconnect(80, 90, 130, 200, on=True)
    f.text(145, 320, "vertical", T_LABEL, OK, bold=True)
    f.mark_ok(145, 360)
    cx, cy = 550, 180
    f.add(f'<g transform="rotate(-90 {cx} {cy})">')
    f.disconnect(cx - 60, cy - 100, 120, 200, on=True)
    f.add("</g>")
    f.text(550, 272, "laid on its side", T_LABEL, NO, bold=True)
    f.mark_no(550, 312)
    f.lines(400, 408, ["Exceptions: breaker enclosures may lie horizontal if 'up' is still ON",
                       "(240.81); busway plug-in units follow the busway."], T_MIN, MUTED, gap=1.2)
    f.tag(f.w - 24, f.h - 8, "NEC 240.33", anchor="end")


@figure("panelboard_faceup_408-43", h=420, when="after", nec="408.43", records=["open-book-exam-#2-001"])
def panelboard_faceup(f):
    f.title("Panelboard mounting position", y=34)
    f.dline(400, 70, 400, 330, EDGE, SW_THIN)
    f.wall(60, 70, 330, thick=18)
    f.panel(100, 90, 130, 200, label=None, breakers=4)
    f.text(165, 320, "on a wall", T_LABEL, OK, bold=True)
    f.mark_ok(165, 362)
    f.floor(260, 440, 780)
    f.poly([(470, 260), (500, 232), (720, 232), (690, 260)], PANEL_2, TEXT, SW_OBJ)
    f.poly([(500, 232), (520, 222), (700, 222), (720, 232)], PANEL, EDGE, SW_THIN)
    f.text(595, 300, "face-up on the floor", T_LABEL, NO, bold=True)
    f.mark_no(595, 346)
    f.tag(f.w - 24, f.h - 10, "NEC 408.43", anchor="end")


@figure("room_ac_cord_440-64", h=460, nec="440.64",
        records=["final-exam-#3-018"])
def room_ac(f):
    f.title("Cord-connected room air conditioner (elevation)", y=34)
    f.wall(420, 60, 420, thick=20)
    f.floor(420, 40, 780)
    f.rect(330, 120, 180, 110, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=6)
    for k in range(5):
        f.line(345, 140 + k * 16, 420, 140 + k * 16, EDGE, 3)
    f.text(440, 108, "room A/C", T_NOTE, TEXT, "start", True)
    f.path("M 400 230 C 390 300, 250 270, 250 340", TEXT, 5)
    f.receptacle(250, 380, 70)
    # LCDI plug head over the upper face: TEST and RESET buttons.
    f.rect(226, 338, 48, 44, fill=EDGE, stroke=TEXT, sw=SW_THIN, rx=8)
    f.rect(232, 356, 16, 10, fill=TEXT, rx=2)
    f.rect(252, 356, 16, 10, fill=OK, rx=2)
    b = f.text(40, 150, "cord, 120 V unit:", T_NOTE, TEXT, "start", True)
    f.value(40, 190, "10 ft max", 28, anchor="start", pad=6)
    f.text(40, 230, "208 or 240 V unit: 6 ft max", T_NOTE, MUTED, "start")
    f.lines(540, 300, ["plug has LCDI, AFCI or", "HDCI protection within", "12 in of the plug (440.65)"],
            T_MIN, MUTED, "start", gap=1.2)
    f.leader(536, 294, 276, 350)
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


@figure("box_screws_314-27d", h=440, nec="314.27(D)",
        records={"open-book-exam-#4-019": {"terms": ["No. 6"]}})
def box_screws(f):
    f.title("Light equipment on an ordinary box (section)", y=34)
    dw0, dw1 = 226, 242
    f.rect(dw0, 60, dw1 - dw0, 98, fill=PANEL_2, stroke=LINE, sw=SW_THIN)
    f.rect(dw0, 282, dw1 - dw0, 118, fill=PANEL_2, stroke=LINE, sw=SW_THIN)
    f.text(dw0 - 10, 86, "wall", T_NOTE, MUTED, "end")
    # Box: open toward the room, the plaster ring on its front edge.
    f.poly([(220, 150), (120, 150), (120, 290), (220, 290)], PANEL)
    f.polyline([(220, 150), (120, 150), (120, 290), (220, 290)], TEXT, SW_OBJ + 1)
    f.text(170, 138, "box", T_NOTE, MUTED)
    f.rect(218, 140, 8, 160, fill=STEEL, stroke=TEXT, sw=SW_THIN)
    for y in (158, 276):
        f.rect(226, y, dw1 - dw0, 6, fill=STEEL, stroke=TEXT, sw=1)
    for y in (164, 270):
        f.rect(226, y - 1, 12, 14, fill=STEEL, stroke=TEXT, sw=1)
    f.text(150, 330, "plaster ring", T_NOTE, MUTED)
    f.leader(206, 320, 222, 300)
    # Equipment on its yoke, held to the ring ears by two screws.
    f.rect(dw1, 154, 10, 132, fill=STEEL, stroke=TEXT, sw=SW_THIN)
    f.rect(dw1 + 10, 176, 150, 88, fill=PANEL, stroke=TEXT, sw=SW_OBJ, rx=10)
    f.text(dw1 + 85, 228, "equipment", T_NOTE, TEXT, bold=True)
    for y in (170, 276):
        f.line(228, y, dw1 + 14, y, AMBER, 5)
        f.rect(dw1 + 10, y - 7, 8, 14, fill=AMBER, rx=2)
    f.text(420, 330, "6 lb or less", T_LABEL, TEXT, "start", True)
    f.text(420, 150, "yoke held by two", T_NOTE, TEXT, "start")
    f.value(420, 190, "No. 6 or larger", 26, anchor="start", pad=6, what="the screw size")
    f.text(420, 228, "screws", T_NOTE, TEXT, "start")
    f.leader(412, 144, dw1 + 18, 168, AMBER)
    f.lines(420, 366, ["heavier: the box must support it", "like a luminaire (314.27(A))"], T_MIN, MUTED, "start",
            gap=1.2)
    f.tag(f.w - 24, f.h - 8, "NEC 314.27(D) Ex.", anchor="end")


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


@figure("disconnect_relay_control_art100", h=440, nec="Article 100 (Remote Disconnect Control)",
        records={"open-book-exam-#10-006": {"terms": ["Remote Disconnect Control"]}})
def relay_control(f):
    f.title("Pushbutton that opens a disconnecting means through a relay", y=34)
    # Pushbutton station: mushroom head on its collar.
    f.rect(46, 112, 100, 124, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=6)
    for sx, sy in ((58, 124), (134, 124), (58, 224), (134, 224)):
        f.circle(sx, sy, 3, fill=EDGE)
    f.circle(96, 174, 26, fill=EDGE, stroke=TEXT, sw=SW_THIN)
    f.circle(96, 174, 20, fill=NO, stroke=TEXT, sw=SW_OBJ)
    f.lines(96, 272, ["pushbutton", "(e.g. at the door)"], T_MIN, MUTED, gap=1.15)
    # Control circuit to the relay coil; the relay contact operates the switch.
    f.line(146, 160, 330, 160, AMBER, SW_WIRE - 1)
    f.line(146, 190, 330, 190, AMBER, SW_WIRE - 1)
    f.text(238, 146, "pushbutton circuit", T_MIN, AMBER)
    f.rect(330, 124, 110, 102, fill=PANEL, stroke=TEXT, sw=SW_OBJ, rx=6)
    f.line(330, 160, 356, 160, TEXT, 2)
    f.line(330, 190, 356, 190, TEXT, 2)
    f.path("M 356 160 a 7.5 7.5 0 0 1 0 15 a 7.5 7.5 0 0 1 0 15", TEXT, 3)
    f.dline(366, 175, 418, 175, MUTED, SW_THIN, 5, 4)
    f.circle(420, 160, 3, fill=TEXT)
    f.circle(420, 190, 3, fill=TEXT)
    f.line(420, 190, 432, 164, TEXT, 3)
    f.line(420, 160, 440, 160, TEXT, 2)
    f.line(420, 190, 440, 190, TEXT, 2)
    f.text(385, 256, "relay", T_NOTE, MUTED)
    f.line(440, 160, 580, 160, AMBER, SW_WIRE - 1)
    f.line(440, 190, 580, 190, AMBER, SW_WIRE - 1)
    # Disconnecting means, operated from the control signal.
    f.disconnect(580, 92, 120, 170, on=True)
    f.text(645, 300, "disconnecting means", T_NOTE, TEXT, bold=True)
    f.text(645, 326, "(opens the power)", T_MIN, MUTED)
    b = f.text(40, 396, "The device and circuit together:", T_NOTE, TEXT, "start")
    f.value(b[0] + b[2] + 12, 396, "Remote Disconnect Control", T_NOTE, anchor="start", pad=5,
            what="the defined term")
    f.tag(f.w - 24, f.h - 8, "NEC Article 100", anchor="end")


@figure("welding_tray_signs_630-42c", h=400, when="after", nec="630.42(C)",
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


@figure("max_water_level_art100", h=420, nec="Article 100 (Maximum Water Level)",
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


@figure("holiday_lighting_trees_590-4j", h=440, nec="590.4(J)",
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


def _pedestal(f, px=60, pw=130):
    """RV site supply pedestal: head with three receptacles under flip covers, on its post."""
    f.rect(px + 40, 380, pw - 80, 50, fill=STEEL, stroke=LINE, sw=SW_THIN)
    f.line(px - 20, 430, px + pw + 20, 430, LINE, SW_STRUCT)
    f.rect(px, 104, pw, 278, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=10)
    f.rect(px - 4, 98, pw + 8, 14, fill=EDGE, stroke=TEXT, sw=SW_THIN, rx=4)
    cx = px + pw / 2
    for k, (cy, r) in enumerate(((146, 20), (232, 26), (322, 30))):
        f.rect(cx - r - 12, cy - r - 16, 2 * r + 24, 2 * r + 30, fill=PANEL, stroke=EDGE, sw=SW_THIN, rx=5)
        f.line(cx - r - 6, cy - r - 10, cx + r + 6, cy - r - 10, LINE, 3)
        if k == 0:
            f.nema_face(cx, cy + 4, r, "5-20")
        else:
            f.circle(cx, cy + 4, r, fill=PANEL_2, stroke=TEXT, sw=2)
            f.circle(cx, cy + 4, r * 0.76, fill=BG, stroke=EDGE, sw=SW_THIN)


@figure("rv_receptacles_551-71", h=470, nec="551.71", records=["open-book-exam-#10-023"])
def rv_receptacles(f):
    f.title("RV park site supply pedestal", y=34)
    _pedestal(f)
    tx = 230
    f.text(tx, 140, "20 A, 125 V", T_NOTE, TEXT, "start", True)
    f.text(tx, 166, "every site", T_NOTE, MUTED, "start")
    f.text(tx, 226, "30 A, 125 V", T_NOTE, TEXT, "start", True)
    b = f.text(tx, 254, "at least", T_NOTE, MUTED, "start")
    f.value(b[0] + b[2] + 10, 254, "70%", 26, anchor="start", pad=5, what="the share of sites")
    f.text(tx, 282, "of the sites", T_NOTE, MUTED, "start")
    f.text(tx, 316, "50 A, 125/250 V", T_NOTE, TEXT, "start", True)
    f.lines(tx, 342, ["40% of new sites,", "20% of existing"], T_NOTE, MUTED, "start", gap=1.15)
    f.text(tx, 430, "all weather-resistant", T_MIN, MUTED, "start")
    f.tag(f.w - 24, f.h - 12, "NEC 551.71", anchor="end")


@figure("rv_feeder_551-72", h=420, nec="551.72(B)", records={"final-exam-#3-002": {"terms": ["two ungrounded"]}})
def rv_feeder(f):
    f.title("RV park feeder from a 208Y/120 V, 3-phase system", y=34)
    cx, cy = 220, 220
    f.circle(cx, cy, 110, fill=PANEL, stroke=LINE, sw=SW_STRUCT)
    f.text(cx, 362, "feeder raceway (section)", T_NOTE, MUTED)
    for (dx, dy), c in zip(((-40, -40), (40, -40), (-40, 40), (40, 40)), (WIRE_HOT, WIRE_HOT, "#f8fafc", WIRE_GND)):
        f.circle(cx + dx, cy + dy, 28, fill=c, stroke=BG, sw=SW_THIN)
    f.mask(100, 100, 240, 240, what="the feeder conductors")
    f.card(400, 90, 380, 220, "Permitted feeder")
    f.value_lines(416, 160, ["2 ungrounded: permitted", "1 grounded conductor and", "1 EGC: both required"],
                  T_MIN, TEXT, anchor="start", bold=False, pad=6, gap=1.3, what="the feeder conductors")
    f.tag(f.w - 24, f.h - 12, "NEC 551.72(B)", anchor="end")
