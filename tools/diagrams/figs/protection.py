"""Overcurrent and shock protection: fault paths, coordination, panelboards, receptacles, AFCI and TR."""
from nec_style import *  # noqa: F401,F403


def _ocpd(f, x, y, w=44, h=54, color=TEXT, fill=PANEL_2):
    """Breaker body centred on (x, y)."""
    f.rect(x - w / 2, y - h / 2, w, h, fill=fill, stroke=color, sw=SW_OBJ, rx=5)
    f.rect(x - w * 0.18, y - h * 0.26, w * 0.36, h * 0.52, fill=EDGE, stroke=color, sw=SW_THIN, rx=3)


def _source(f, x, y, r=18):
    """Transformer source symbol (two coils), centred on (x, y)."""
    f.circle(x, y - r * 0.8, r, stroke=TEXT, sw=SW_OBJ)
    f.circle(x, y + r * 0.8, r, stroke=TEXT, sw=SW_OBJ)


def _spark(f, x, y, s=14):
    f.polyline([(x - s, y - s), (x + s * 0.2, y - s * 0.1), (x - s * 0.2, y + s * 0.1), (x + s, y + s)], AMBER, 4)


@figure("fault_path_art100", h=600, nec="Article 100 (Ground Fault, Effective Ground-Fault Current Path)",
        records={"final-exam-#1-044": {"terms": ["fault"]}, "open-book-exam-#4-009": {"terms": ["fault"]}})
def fault_path(f):
    f.title("Three circuit troubles: name the first one", y=34)
    # (a) Hot conductor touching a metal enclosure; current returns on the EGC.
    f.rect(20, 54, 760, 290, fill=PANEL, stroke=EDGE, sw=SW_THIN, rx=8)
    sx, top, bot = 80, 120, 250
    _source(f, sx, 180)
    f.line(sx, 150, sx, top, WIRE_HOT, SW_WIRE)
    f.line(sx, top, 560, top, WIRE_HOT, SW_WIRE)
    _ocpd(f, 200, top)
    f.text(200, top - 36, "OCPD opens", T_NOTE, OK, bold=True)
    f.line(sx, 210, sx, bot, WIRE_NEU, SW_WIRE)
    f.line(sx, bot, 520, bot, WIRE_NEU, SW_WIRE - 1)
    f.text(420, bot - 10, "neutral", T_MIN, MUTED)
    # Main bonding jumper at the source, EGC back from the enclosure.
    f.line(sx, bot, sx, 300, AMBER, SW_WIRE)
    f.line(sx, 300, 640, 300, WIRE_GND, SW_WIRE + 1)
    f.text(sx + 20, 290, "bonded at the source", T_MIN, AMBER, "start")
    f.text(420, 326, "EGC", T_NOTE, WIRE_GND, bold=True)
    for x in (560, 440, 320):
        f.arrow(x, 300, x - 60, 300, OK, 3)
    # Metal enclosure with the loose hot touching the wall.
    f.rect(560, 90, 160, 180, fill=STEEL, stroke=TEXT, sw=SW_OBJ + 1, rx=6)
    f.rect(578, 108, 124, 144, fill=PANEL_2, stroke=EDGE, sw=SW_THIN, rx=4)
    f.text(640, 82, "metal enclosure", T_NOTE, TEXT, bold=True)
    f.polyline([(560, top), (600, top), (620, 170), (576, 214)], WIRE_HOT, SW_WIRE)
    _spark(f, 572, 220)
    f.line(640, 270, 640, 300, WIRE_GND, SW_WIRE + 1)
    f.lines(756, 160, ["hot", "touches", "the metal"], T_MIN, TEXT, bold=True, gap=1.1)
    f.value(400, 186, "ground fault", 30, records=None, label="? name", what="name of case (a)")
    # (b) Open conductor and (c) hot-to-neutral, small.
    for x0, name in ((20, "open circuit"), (410, "short circuit")):
        f.rect(x0, 360, 370, 180, fill=PANEL, stroke=EDGE, sw=SW_THIN, rx=8)
        _source(f, x0 + 44, 430, 14)
        f.line(x0 + 44, 406, x0 + 44, 394, WIRE_HOT, 3)
        f.line(x0 + 44, 454, x0 + 44, 466, WIRE_NEU, 3)
        f.line(x0 + 44, 466, x0 + 300, 466, WIRE_NEU, 3)
        f.circle(x0 + 320, 430, 26, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ)
        f.text(x0 + 320, 438, "M", T_LABEL, TEXT, bold=True)
        f.line(x0 + 300, 466, x0 + 320, 456, WIRE_NEU, 3)
        if x0 == 20:
            f.line(x0 + 44, 394, x0 + 150, 394, WIRE_HOT, 3)
            f.line(x0 + 180, 394, x0 + 320, 394, WIRE_HOT, 3)
            f.line(x0 + 320, 394, x0 + 320, 404, WIRE_HOT, 3)
            f.circle(x0 + 150, 394, 4, fill=NO)
            f.circle(x0 + 180, 394, 4, fill=NO)
            f.text(x0 + 165, 384, "broken", T_MIN, NO, bold=True)
        else:
            f.line(x0 + 44, 394, x0 + 320, 394, WIRE_HOT, 3)
            f.line(x0 + 320, 394, x0 + 320, 404, WIRE_HOT, 3)
            f.line(x0 + 200, 394, x0 + 200, 466, AMBER, 4)
            _spark(f, x0 + 200, 430, 10)
            f.text(x0 + 210, 384, "hot to neutral", T_MIN, AMBER, "start", True)
        f.value(x0 + 185, 516, name, 26, records=None, label="?", what=f"name of this case ({name})")
    f.tag(f.w - 24, f.h - 12, "NEC Art. 100", anchor="end")
    f.text(f.w - 30, 76, "(a)", T_NOTE, MUTED, "end", True)
    f.text(40, 384, "(b)", T_NOTE, MUTED, "start", True)
    f.text(430, 384, "(c)", T_NOTE, MUTED, "start", True)


@figure("selective_coordination_700-32", h=600, nec="Article 100 (Selective Coordination), 700.32, 701.32, 708.54",
        records={"final-exam-#3-029": {"terms": ["selective", "coordination"]}, "open-book-exam-#7-007": {}})
def selective_coordination(f):
    term = ["final-exam-#3-029"]
    loads = ["open-book-exam-#7-007"]
    f.title("Only the device nearest the problem opens", y=34)
    # Left: one-line with a fault on one branch.
    x = 190
    f.line(x, 70, x, 320, WIRE_HOT, SW_WIRE)
    _ocpd(f, x, 100)
    f.text(x + 34, 108, "service", T_NOTE, TEXT, "start")
    _ocpd(f, x, 190)
    f.text(x + 34, 198, "feeder", T_NOTE, TEXT, "start")
    f.text(x - 34, 108, "stays on", T_MIN, OK, "end", True)
    f.text(x - 34, 198, "stays on", T_MIN, OK, "end", True)
    f.line(70, 320, 310, 320, WIRE_HOT, SW_WIRE)
    for bx, name, opened in ((70, "lighting", False), (190, "motor", True), (310, "receptacles", False)):
        f.line(bx, 320, bx, 440, WIRE_HOT, SW_WIRE)
        _ocpd(f, bx, 370, color=NO if opened else TEXT)
        f.text(bx, 470, name, T_MIN, TEXT, bold=True)
    f.text(222, 378, "opens", T_MIN, NO, "start", True)
    _spark(f, 190, 430)
    f.text(214, 438, "fault", T_MIN, AMBER, "start", True)
    f.value(190, 520, "selective coordination", 26, records=term, label="? term", what="the defined term")
    # Right: the series exception.
    f.rect(390, 56, 390, 490, fill=PANEL, stroke=EDGE, sw=SW_THIN, rx=8)
    f.text(585, 86, "Two devices in series", T_NOTE, TEXT, bold=True)
    for cx, tapped in ((480, False), (680, True)):
        f.line(cx, 110, cx, 380, WIRE_HOT, SW_WIRE)
        _ocpd(f, cx, 150)
        _ocpd(f, cx, 290)
        f.text(cx, 412, "equipment", T_MIN, TEXT, bold=True)
        f.rect(cx - 40, 380, 80, 12, fill=PANEL_2, stroke=TEXT, sw=SW_THIN)
        if tapped:
            f.line(cx, 220, cx + 60, 220, WIRE_HOT, SW_WIRE)
            f.line(cx + 60, 220, cx + 60, 250, WIRE_HOT, SW_WIRE)
            f.rect(cx + 40, 250, 40, 24, fill=PANEL_2, stroke=TEXT, sw=SW_THIN)
            f.value(cx + 40, 206, "load", T_MIN, AMBER, anchor="end", records=loads, pad=5,
                    what="the load tapped between the devices")
    f.value_lines(480, 452, ["no loads", "in parallel"], T_MIN, TEXT, records=loads, pad=6, gap=1.1,
                  what="nothing tapped in parallel with the downstream device")
    f.value_lines(480, 508, ["coordination", "not required"], T_MIN, OK, records=term, pad=5, gap=1.1,
                  what="caption naming the term")
    f.lines(680, 452, ["something tapped", "in parallel"], T_MIN, TEXT, gap=1.1)
    f.value_lines(680, 508, ["must", "coordinate"], T_MIN, NO, records=term, pad=5, gap=1.1,
                  what="caption naming the term")
    f.tag(f.w - 24, f.h - 12, "NEC 700.32, 701.32, 708.54", anchor="end")


@figure("transformer_panel_408-36b", h=470, nec="408.36(B), 240.21(C)(1)",
        records={"open-book-exam-#7-021": {"terms": ["secondary", "primary"]}})
def transformer_panel(f):
    rid = ["open-book-exam-#7-021"]
    f.title("Panelboard fed through a transformer: where is its OCPD?", y=34)
    y = 200
    f.line(40, y, 180, y, WIRE_HOT, SW_WIRE)
    _ocpd(f, 110, y)
    f.lines(110, y + 60, ["feeder OCPD", "(480 V)"], T_MIN, MUTED, gap=1.1)
    f.line(180, y, 230, y, WIRE_HOT, SW_WIRE)
    # Transformer.
    f.rect(260, 110, 170, 180, fill=PANEL, stroke=TEXT, sw=SW_OBJ + 1, rx=6)
    for k in range(4):
        f.path(f"M 310 {140 + k * 30} a 14 14 0 0 1 0 28", TEXT, 3)
        f.path(f"M 380 {140 + k * 30} a 14 14 0 0 0 0 28", TEXT, 3)
    f.line(345, 130, 345, 270, EDGE, 2)
    f.text(282, 316, "480 V", T_NOTE, TEXT, bold=True)
    f.text(418, 316, "208Y/120 V", T_NOTE, TEXT, bold=True)
    f.line(230, y, 260, y, WIRE_HOT, SW_WIRE)
    f.line(430, y, 620, y, WIRE_HOT, SW_WIRE)
    # Candidate spots on both sides, both hidden until answered.
    f.mark_no(230, y, 20)
    _ocpd(f, 500, y)
    for cx, what in ((230, "the 480 V side marked wrong"), (500, "panel OCPD between transformer and panel")):
        f.mask(cx - 30, y - 40, 60, 80, records=rid, what=what)
    f.value(230, 380, "no", 28, NO, records=rid, what="OCPD for the panel not on the 480 V side")
    f.value_lines(500, 372, ["panel OCPD", "on this side"], T_NOTE, records=rid, gap=1.15,
                  what="panel OCPD between transformer and panel")
    f.panel(620, 110, 150, 200, label="panelboard", breakers=5)
    f.value(24, f.h - 18, "Ex.: 240.21(C)(1) two-wire secondary may be protected on the primary.",
            T_MIN, MUTED, anchor="start", bold=False, records=rid, pad=5, what="the exception note")
    f.tag(f.w - 24, 64, "NEC 408.36(B)", anchor="end")

@figure("panelboard_interior_408", h=530, nec="408.7, 408.41",
        records={"final-exam-#3-046": {}, "open-book-exam-#1-009": {}})
def panelboard_interior(f):
    closure = ["final-exam-#3-046"]
    term = ["open-book-exam-#1-009"]
    f.title("Panelboard: unused spaces and the neutral bar", y=34)
    # Dead front with breaker spaces.
    f.rect(30, 60, 300, 380, fill=PANEL, stroke=TEXT, sw=SW_OBJ + 1, rx=6)
    for i in range(6):
        y = 90 + i * 58
        for x in (60, 190):
            if i == 2 and x == 190:
                f.rect(x, y, 110, 40, fill=BG, stroke=NO, sw=SW_OBJ, rx=3)
            elif i == 4 and x == 190:
                f.rect(x, y, 110, 40, fill=STEEL, stroke=TEXT, sw=SW_THIN, rx=3)
                f.circle(x + 55, y + 20, 5, fill=TEXT)
            else:
                f.rect(x, y, 110, 40, fill=PANEL_2, stroke=TEXT, sw=SW_THIN, rx=3)
                f.rect(x + 40, y + 10, 30, 20, fill=EDGE, rx=3)
    f.mark_no(318, 226, 16)
    f.mark_ok(318, 342, 16)
    f.text(30, 474, "open space: live parts exposed", T_MIN, NO, "start", True)
    b = f.text(30, 510, "closed with:", T_MIN, TEXT, "start", True)
    f.value(b[0] + b[2] + 10, 510, "identified closure", T_NOTE, anchor="start", records=closure, pad=5,
            what="the closure plate type")
    # Neutral bar close-up.
    f.rect(360, 60, 420, 380, fill=PANEL, stroke=EDGE, sw=SW_THIN, rx=8)
    f.text(570, 92, "neutral terminal bar (close-up)", T_NOTE, TEXT, bold=True)
    f.rect(400, 200, 340, 44, fill=STEEL, stroke=TEXT, sw=SW_OBJ, rx=4)
    for k, x in enumerate((440, 520, 600, 690)):
        f.circle(x, 222, 12, fill=LINE, stroke=TEXT, sw=SW_THIN)
        f.line(x - 8, 222, x + 8, 222, BG, 3)
        if k < 2:
            f.line(x, 244, x, 330, WIRE_NEU, SW_WIRE)
        elif k == 3:
            f.line(x - 6, 244, x - 20, 330, WIRE_NEU, SW_WIRE)
            f.line(x + 6, 244, x + 20, 330, WIRE_NEU, SW_WIRE)
    f.mark_ok(480, 362, 18)
    f.mark_no(690, 362, 18)
    f.lines(480, 410, ["one conductor", "per terminal"], T_MIN, TEXT, bold=True, gap=1.1)
    f.lines(690, 410, ["two under", "one screw"], T_MIN, TEXT, bold=True, gap=1.1)
    b = f.text(380, 150, "each grounded conductor:", T_NOTE, TEXT, "start")
    f.value(b[0] + b[2] + 10, 150, "individual", T_NOTE, anchor="start", records=term, pad=5,
            what="its own terminal")
    f.text(380, 178, "terminal, not shared", T_NOTE, TEXT, "start")
    f.tag(f.w - 24, f.h - 12, "NEC 408.7, 408.41", anchor="end")


@figure("receptacle_markings_406", h=496, nec="406.3(E), 406.10(C)",
        records={"open-book-exam-#4-007": {"terms": ["orange", "triangle"]},
                 "open-book-exam-#10-003": {"terms": ["EGC", "equipment"]},
                 "open-book-exam-#10-018": {"terms": ["orange", "triangle"]}})
def receptacle_markings(f):
    ig = ["open-book-exam-#4-007", "open-book-exam-#10-018"]
    gnd = ["open-book-exam-#10-003"]
    f.title("Receptacle: face marking and back terminals", y=34)
    # Face of an isolated-ground receptacle.
    f.rect(40, 60, 320, 390, fill=PANEL, stroke=EDGE, sw=SW_THIN, rx=8)
    f.text(200, 92, "isolated ground receptacle", T_NOTE, TEXT, bold=True)
    cx = 200
    f.rect(cx - 70, 120, 140, 280, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=14)
    for cy in (190, 330):
        f.rect(cx - 46, cy - 42, 92, 84, fill=BG, stroke=TEXT, sw=SW_THIN, rx=40)
        f.line(cx - 18, cy - 18, cx - 18, cy + 4, TEXT, 5)
        f.line(cx + 18, cy - 18, cx + 18, cy + 4, TEXT, 5)
        f.path(f"M {cx - 8} {cy + 26} a 8 8 0 0 1 16 0 v 8 h -16 z", TEXT, 3)
    f.poly([(cx, 246), (cx - 16, 274), (cx + 16, 274)], ORANGE)
    f.mask(cx - 30, 236, 60, 48, records=ig, what="the face marking")
    f.value(200, 432, "orange triangle", T_NOTE, ORANGE, records=ig, pad=5)
    # Back of any receptacle: the three terminal colors.
    f.rect(400, 60, 380, 390, fill=PANEL, stroke=EDGE, sw=SW_THIN, rx=8)
    f.text(590, 92, "back: terminal screws", T_NOTE, TEXT, bold=True)
    rows = [(160, "#d4a017", "brass", "ungrounded (hot)"), (250, "#cbd5e1", "silver", "grounded (neutral)")]
    for y, color, name, use in rows:
        f.circle(440, y, 16, fill=color, stroke=TEXT, sw=SW_THIN)
        f.text(470, y - 6, name, T_NOTE, TEXT, "start", True)
        f.text(470, y + 20, use, T_MIN, MUTED, "start")
    f.circle(440, 340, 16, fill="#16a34a", stroke=TEXT, sw=SW_THIN)
    f.text(470, 334, "green", T_NOTE, TEXT, "start", True)
    f.value_lines(470, 362, ["EGC only", "(equipment grounding)"], T_MIN, anchor="start", records=gnd, pad=5,
                  gap=1.1, what="the only conductor on the green screw")
    f.text(420, 430, "one conductor type per screw color", T_MIN, MUTED, "start")
    f.tag(f.w - 24, f.h - 10, "NEC 406.3(E), 406.10", anchor="end")


@figure("afci_tr_dwelling_210-12_406-12", h=560, nec="210.12(A)-(D), 406.12",
        records={"final-exam-#1-048": {"terms": ["TR", "tamper"]},
                 "open-book-exam-#4-005": {"terms": ["TR", "tamper"]},
                 "open-book-exam-#4-012": {"terms": ["branch"]},
                 "open-book-exam-#4-023": {"when": "after"}})
def afci_tr_dwelling(f):
    tr = ["final-exam-#1-048", "open-book-exam-#4-005"]
    extent = ["open-book-exam-#4-012"]
    f.title("Dwelling plan: AFCI rooms and receptacle type (not to scale)", y=34)
    rooms = [(30, 60, 170, 130, "bedroom", True), (200, 60, 150, 130, "bedroom", True),
             (350, 60, 100, 130, "bath", False), (30, 190, 170, 140, "living room", True),
             (200, 190, 250, 50, "hallway", True), (200, 240, 140, 90, "kitchen", True),
             (340, 240, 110, 90, "laundry", True), (450, 60, 140, 270, "garage", False)]
    for x, y, w, h, name, afci in rooms:
        if afci:
            f.rect(x, y, w, h, fill=ZONE, op=0.22, stroke="none")
        f.rect(x, y, w, h, fill="none", stroke=LINE, sw=SW_OBJ)
        f.text(x + w / 2, y + (h / 2 + 8 if h > 60 else 32), name, T_MIN, TEXT, bold=True)
    f.plan_receptacle(420, 222, 11)
    f.legend([(ZONE, "AFCI required", "box")], 604, 80, T_MIN)
    f.lines(604, 124, ["also 210.12(C), (D):", "dorm units, guest", "rooms and suites,", "nursing patient",
                       "sleeping rooms"], T_MIN, MUTED, "start", gap=1.15)
    f.value_lines(690, 270, ["TR", "(tamper-", "resistant)"], T_NOTE, records=tr, pad=6, gap=1.1,
                  what="hallway receptacle type")
    f.leader(640, 262, 432, 222)
    f.value_lines(604, 348, ["406.12: all 15/20 A,", "125/250 V dwelling", "receptacles"], T_MIN, MUTED,
                  anchor="start", bold=False, records=tr, pad=5, gap=1.15, what="the 406.12 rule")
    # Strip: panel to the last outlet.
    y = 470
    f.panel(30, y - 50, 80, 100, label="", breakers=0)
    _ocpd(f, 70, y, 40, 50)
    f.text(70, y + 72, "AFCI", T_MIN, TEXT, bold=True)
    f.line(90, y, 740, y, WIRE_HOT, SW_WIRE)
    for x in (300, 500, 700):
        f.plan_receptacle(x, y + 30, 11)
        f.line(x, y, x, y + 19, WIRE_HOT, 3)
    f.dim_h(70, 740, y - 36)
    f.mask(56, y - 48, 700, 26, records=extent, what="the reach arrow")
    f.value(420, y - 50, "protects the entire branch circuit", T_NOTE, records=extent, pad=6,
            what="how far AFCI protection reaches")
    f.tag(f.w - 24, f.h - 10, "NEC 210.12, 406.12", anchor="end")