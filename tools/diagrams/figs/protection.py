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


def _cb(f, x, y, color=TEXT, on=True):
    """Shared breaker drawing, centred on (x, y)."""
    f.breaker(x - 22, y - 27, 44, 54, on=on, color=color)


def _spark(f, x, y, s=14):
    f.polyline([(x - s, y - s), (x + s * 0.2, y - s * 0.1), (x - s * 0.2, y + s * 0.1), (x + s, y + s)], AMBER, 4)


@figure("fault_path_art100", h=420, nec="Article 100 (Ground Fault)",
        records={"final-exam-#1-044": {"terms": ["fault"]}, "open-book-exam-#4-009": {"terms": ["fault"]}})
def fault_path(f):
    f.title("A hot conductor touches a metal enclosure: what is it called?", y=34)
    sx, top, bot = 80, 120, 244
    f.coils(sx, 180)
    f.line(sx, 150, sx, top, WIRE_HOT, SW_WIRE)
    f.line(sx, top, 560, top, WIRE_HOT, SW_WIRE)
    f.breaker(178, top - 27, 44, 54)
    f.text(200, top - 36, "OCPD opens", T_NOTE, OK, bold=True)
    f.line(sx, 210, sx, bot, WIRE_NEU, SW_WIRE)
    f.text(420, bot - 10, "neutral", T_MIN, MUTED)
    f.line(sx, bot, sx, 300, AMBER, SW_WIRE)
    f.line(sx, 300, 640, 300, WIRE_GND, SW_WIRE + 1)
    f.text(sx + 20, 290, "bonded at the source", T_MIN, AMBER, "start")
    f.text(420, 326, "EGC: the return path", T_NOTE, WIRE_GND, bold=True)
    for x in (560, 440, 320):
        f.arrow(x, 300, x - 60, 300, OK, 3)
    f.rect(560, 90, 160, 180, fill=STEEL, stroke=TEXT, sw=SW_OBJ + 1, rx=6)
    f.rect(578, 108, 124, 144, fill=PANEL_2, stroke=EDGE, sw=SW_THIN, rx=4)
    f.text(640, 82, "metal enclosure", T_NOTE, TEXT, bold=True)
    f.line(sx, bot, 664, bot, WIRE_NEU, SW_WIRE - 1)
    f.line(664, bot, 664, 196, WIRE_NEU, SW_WIRE - 1)
    f.motor_symbol(664, 172, 24)
    f.line(664, 148, 664, 136, TEXT, 3)
    f.circle(664, 131, 5, fill=BG, stroke=TEXT, sw=2)
    f.polyline([(560, top), (600, top), (620, 170), (576, 214)], WIRE_HOT, SW_WIRE)
    _spark(f, 572, 220)
    f.line(640, 270, 640, 300, WIRE_GND, SW_WIRE + 1)
    f.lines(654, 298, ["hot touches", "the metal"], T_MIN, TEXT, "start", True, gap=1.1)
    f.value(400, 186, "ground fault", 30, records=None, label="? name", what="the name of this fault")
    f.tag(f.w - 24, f.h - 16, "NEC Article 100", anchor="end")


@figure("selective_coordination_100", h=520, nec="Article 100 (Selective Coordination)",
        records={"final-exam-#3-029": {"terms": ["selective", "coordination"]}})
def selective_coordination(f):
    f.title("A fault on one branch: only its breaker opens", y=34)
    x = 260
    f.line(x, 70, x, 300, WIRE_HOT, SW_WIRE)
    _cb(f, x, 100)
    f.text(x + 34, 108, "service", T_NOTE, TEXT, "start")
    _cb(f, x, 190)
    f.text(x + 34, 198, "feeder", T_NOTE, TEXT, "start")
    f.text(x - 34, 108, "stays on", T_MIN, OK, "end", True)
    f.text(x - 34, 198, "stays on", T_MIN, OK, "end", True)
    f.line(100, 300, 420, 300, WIRE_HOT, SW_WIRE)
    for bx, name, opened in ((100, "lighting", False), (260, "motor", True), (420, "receptacles", False)):
        f.line(bx, 300, bx, 420, WIRE_HOT, SW_WIRE)
        _cb(f, bx, 350, color=NO if opened else TEXT, on=not opened)
        f.text(bx, 450, name, T_MIN, TEXT, bold=True)
    f.text(292, 358, "opens", T_MIN, NO, "start", True)
    _spark(f, 260, 410)
    f.text(284, 418, "fault", T_MIN, AMBER, "start", True)
    f.card(500, 80, 270, 230, "The outage stays local")
    f.lines(516, 150, ["the breakers are chosen", "so the one nearest the", "fault opens first;",
                       "everything upstream", "keeps running"], T_MIN, TEXT, "start", gap=1.2)
    f.value(400, 494, "selective coordination", 28, records=None, label="? term", what="the defined term")
    f.tag(f.w - 24, 360, "NEC Article 100", anchor="end")


@figure("series_breakers_708-54", h=500, nec="708.54 Ex.", records=["open-book-exam-#7-007"])
def series_breakers(f):
    f.title("Two breakers in series: when must they coordinate?", y=34)
    for cx, tapped in ((220, False), (580, True)):
        f.rect(cx - 170, 56, 340, 390, fill=PANEL, stroke=EDGE, sw=SW_THIN, rx=8)
        f.line(cx, 90, cx, 340, WIRE_HOT, SW_WIRE)
        _cb(f, cx, 130)
        f.text(cx - 34, 138, "upstream", T_MIN, MUTED, "end")
        _cb(f, cx, 260)
        f.text(cx - 34, 268, "downstream", T_MIN, MUTED, "end")
        f.rect(cx - 40, 340, 80, 12, fill=PANEL_2, stroke=TEXT, sw=SW_THIN)
        f.text(cx, 374, "equipment", T_MIN, TEXT, bold=True)
        if tapped:
            f.line(cx, 196, cx + 70, 196, WIRE_HOT, SW_WIRE)
            f.line(cx + 70, 196, cx + 70, 226, WIRE_HOT, SW_WIRE)
            f.rect(cx + 50, 226, 40, 24, fill=PANEL_2, stroke=TEXT, sw=SW_THIN)
            f.value(cx + 70, 278, "load", T_MIN, AMBER, pad=5, what="the load tapped between the breakers")
    f.value_lines(220, 410, ["no loads in parallel:", "coordination not required"], T_MIN, OK, pad=6, gap=1.2,
                  what="nothing tapped in parallel with the downstream breaker")
    f.lines(580, 410, ["something tapped in parallel:", "they must coordinate"], T_MIN, NO, bold=True, gap=1.2)
    f.tag(f.w - 24, f.h - 12, "NEC 708.54 Ex.", anchor="end")


@figure("transformer_panel_408-36b", h=470, nec="408.36(B)",
        records={"open-book-exam-#7-021": {"terms": ["secondary", "primary"]}},
        keep=[r"^(feeder OCPD )?\(?480 V\)?$", r"^feeder OCPD$", r"^208Y/120 V$"])
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
    f.value_lines(500, 352, ["panel OCPD", "on this side"], T_NOTE, records=rid, gap=1.15,
                  what="panel OCPD between transformer and panel")
    f.panel(620, 110, 150, 200, label="panelboard", breakers=5)
    f.value_lines(24, f.h - 18 - T_MIN * 1.2,
                  ["Ex.: 240.21(C)(1) a single-phase 2-wire or a delta-delta 3-wire",
                   "(single-voltage) secondary may be protected on the primary."],
                  T_MIN, MUTED, anchor="start", bold=False, records=rid, pad=5, what="the exception note")
    f.tag(f.w - 24, 64, "NEC 408.36(B)", anchor="end")


@figure("unused_openings_408-7", h=480, nec="408.7",
        records={"final-exam-#3-046": {}, "open-book-exam-#11-002": {"like": "final-exam-#3-046"}})
def unused_openings(f):
    f.title("Panelboard dead front: an unused breaker opening", y=34)
    f.panel(40, 60, 286, 380, label=None, breakers=0)
    f.rect(174, 84, 18, 332, fill=BG, op=0.6, rx=2)
    for i in range(6):
        y = 92 + i * 56
        for x in (74, 194):
            if i == 2 and x == 194:
                f.rect(x, y, 98, 40, fill=BG, stroke=NO, sw=SW_OBJ, rx=3)
                f.rect(x + 6, y + 12, 30, 16, fill=LINE, stroke=TEXT, sw=1.5, rx=2)
            elif i == 4 and x == 194:
                f.rect(x, y, 98, 40, fill=STEEL, stroke=TEXT, sw=SW_THIN, rx=3)
                for tx in (x + 10, x + 88):
                    f.line(tx, y + 10, tx, y + 30, TEXT, 2)
            else:
                f.mini_breaker(x, y, 98, 40, handle_left=x > 183)
    f.mark_no(354, 224, 16)
    f.mark_ok(354, 336, 16)
    f.leader(380, 212, 400, 160)
    f.card(400, 90, 370, 110, "Left open", title_fill=NO)
    f.text(416, 160, "the bus stab and live parts show", T_MIN, TEXT, "start")
    f.leader(380, 336, 400, 300)
    f.card(400, 250, 370, 140, "Closed", title_fill=OK)
    f.text(416, 316, "unused opening closed with:", T_MIN, TEXT, "start")
    f.value(416, 360, "identified closures", T_NOTE, anchor="start", pad=6, what="the closure type")
    f.tag(f.w - 24, f.h - 16, "NEC 408.7", anchor="end")


@figure("neutral_terminals_408-41", h=440, nec="408.41", records={"open-book-exam-#1-009": {}})
def neutral_terminals(f):
    f.title("Panelboard neutral terminal bar (close-up)", y=34)
    f.rect(130, 120, 540, 50, fill=STEEL, stroke=TEXT, sw=SW_OBJ, rx=4)
    for k, x in enumerate((200, 300, 400, 560)):
        f.circle(x, 145, 14, fill=LINE, stroke=TEXT, sw=SW_THIN)
        f.line(x - 9, 145, x + 9, 145, BG, 3)
        if k < 3:
            f.line(x, 170, x, 270, WIRE_NEU, SW_WIRE)
        else:
            f.line(x - 6, 170, x - 24, 270, WIRE_NEU, SW_WIRE)
            f.line(x + 6, 170, x + 24, 270, WIRE_NEU, SW_WIRE)
    f.text(400, 100, "neutral (grounded) conductors land here", T_NOTE, MUTED)
    f.mark_ok(300, 302, 18)
    f.mark_no(560, 302, 18)
    f.lines(300, 346, ["one conductor", "per terminal"], T_NOTE, TEXT, bold=True, gap=1.1)
    f.lines(560, 346, ["two under", "one screw"], T_NOTE, TEXT, bold=True, gap=1.1)
    b = f.text(40, 416, "each grounded conductor gets an", T_NOTE, TEXT, "start")
    f.value(b[0] + b[2] + 10, 416, "individual", T_NOTE, anchor="start", pad=5, what="its own terminal")
    f.tag(f.w - 24, f.h - 12, "NEC 408.41", anchor="end")


@figure("ig_receptacle_406-3e", h=460, nec="406.3(E)",
        records={"open-book-exam-#4-007": {"terms": ["orange", "triangle"]},
                 "open-book-exam-#10-018": {"terms": ["orange", "triangle"]},
                 "final-exam-#2-047": {"like": "open-book-exam-#10-018"}})
def ig_receptacle(f):
    f.title("Isolated ground receptacle: the face marking", y=34)
    cx = 220
    f.rect(cx - 90, 70, 180, 330, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=16)
    for cy in (150, 320):
        f.nema_face(cx, cy, 52, "5-15")
    f.poly([(cx, 218), (cx - 20, 252), (cx + 20, 252)], ORANGE)
    f.mask(cx - 34, 206, 68, 58, what="the face marking")
    f.value(cx, 436, "orange triangle", T_NOTE, ORANGE, pad=5)
    f.card(380, 90, 390, 250, "What makes it different")
    f.lines(396, 160, ["its grounding terminal is", "insulated from the yoke", "and the box"], T_MIN, TEXT,
            "start", gap=1.2)
    f.lines(396, 264, ["used to cut electrical noise", "on sensitive equipment"], T_MIN, MUTED, "start", gap=1.2)
    f.tag(f.w - 24, f.h - 12, "NEC 406.3(E)", anchor="end")


@figure("grounding_terminal_406-10c", h=420, nec="406.10(C)",
        records={"open-book-exam-#10-003": {"terms": ["EGC", "equipment"]}})
def grounding_terminal(f):
    f.title("Back of a receptacle: what lands on each screw", y=34)
    f.rect(60, 70, 180, 300, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=16)
    f.text(150, 400, "receptacle (back)", T_NOTE, MUTED)
    rows = [(130, "#d4a017", "brass", "hot conductor"), (230, "#cbd5e1", "silver", "neutral (white)")]
    for y, color, name, use in rows:
        f.circle(240, y, 16, fill=color, stroke=TEXT, sw=SW_THIN)
        f.text(290, y - 6, name, T_NOTE, TEXT, "start", True)
        f.text(290, y + 20, use, T_MIN, MUTED, "start")
    f.circle(240, 330, 16, fill="#16a34a", stroke=TEXT, sw=SW_THIN)
    f.text(290, 324, "green", T_NOTE, TEXT, "start", True)
    f.value(290, 356, "EGC only (equipment grounding conductor)", T_MIN, anchor="start", pad=5,
            what="the only conductor on the green screw")
    f.tag(f.w - 24, f.h - 12, "NEC 406.10(C)", anchor="end")


@figure("afci_dwelling_210-12", h=560, nec="210.12",
        records={"open-book-exam-#4-012": {"terms": ["branch"]},
                 "open-book-exam-#4-023": {"when": "after"}, "open-book-exam-#2-011": {"when": "after"}})
def afci_dwelling(f):
    f.title("Dwelling plan: rooms that need AFCI (not to scale)", y=34)
    rooms = [(30, 60, 170, 130, "bedroom", True), (200, 60, 150, 130, "bedroom", True),
             (350, 60, 100, 130, "bath", False), (30, 190, 170, 140, "living room", True),
             (200, 190, 250, 50, "hallway", True), (200, 240, 140, 90, "kitchen", True),
             (340, 240, 110, 90, "laundry", True), (450, 60, 140, 270, "garage", False)]
    for x, y, w, h, name, afci in rooms:
        if afci:
            f.rect(x, y, w, h, fill=ZONE, op=0.22, stroke="none")
        f.rect(x, y, w, h, fill="none", stroke=LINE, sw=SW_OBJ)
        f.text(x + w / 2, y + (h / 2 + 8 if h > 60 else 32), name, T_MIN, TEXT, bold=True)
    f.legend([(ZONE, "AFCI required", "box")], 604, 80, T_MIN)
    f.lines(604, 124, ["also dorm units,", "guest rooms and", "suites, nursing", "patient sleeping",
                       "rooms"], T_MIN, MUTED, "start", gap=1.15)
    f.lines(604, 270, ["not required:", "bathrooms,", "garages"], T_MIN, NO, "start", True, gap=1.15)
    f.highlight(596, 248, 180, 88)
    y = 470
    f.panel(30, y - 50, 80, 100, label="", breakers=0)
    f.breaker(50, y - 25, 40, 50)
    f.text(70, y + 72, "AFCI", T_MIN, TEXT, bold=True)
    f.line(90, y, 740, y, WIRE_HOT, SW_WIRE)
    for x in (300, 500, 700):
        f.plan_receptacle(x, y + 30, 11)
        f.line(x, y, x, y + 19, WIRE_HOT, 3)
    f.dim_h(70, 740, y - 36)
    f.mask(56, y - 48, 700, 26, records=["open-book-exam-#4-012"], what="the reach arrow")
    f.value(420, y - 50, "protects the entire branch circuit", T_NOTE, records=["open-book-exam-#4-012"], pad=6,
            what="how far AFCI protection reaches")
    f.tag(f.w - 24, f.h - 10, "NEC 210.12", anchor="end")


@figure("tr_receptacle_406-12", h=460, nec="406.12",
        records={"final-exam-#1-048": {"terms": ["TR", "tamper"]},
                 "open-book-exam-#4-005": {"terms": ["TR", "tamper"]},
                 "open-book-exam-#11-021": {"when": "after"}})
def tr_receptacle(f):
    tr = ["final-exam-#1-048", "open-book-exam-#4-005"]
    f.title("Dwelling hallway: 125 V, 15 A receptacle", y=34)
    f.rect(40, 60, 360, 360, fill=PANEL, stroke=EDGE, sw=SW_THIN)
    f.floor(420, 40, 400)
    f.text(220, 90, "hallway wall", T_NOTE, MUTED)
    f.receptacle(200, 300, 150, blank_center=True)
    f.leader(300, 298, 246, 298)
    f.value(310, 306, "TR", T_LABEL, TEXT, "start", records=tr, pad=6, what="the TR marking")
    f.value_lines(220, 140, ["listed tamper-resistant", "(shutters behind the slots)"], T_NOTE, records=tr,
                  pad=6, gap=1.15, what="the receptacle type")
    f.card(440, 90, 330, 300, "Where the rule applies")
    f.lines(456, 160, ["nonlocking 15 and 20 A,", "125 V through 250 V, in:", "- dwelling units",
                       "- accessory buildings", "- multifamily common areas", "- and other listed places"],
            T_MIN, TEXT, "start", gap=1.3)
    f.mask(446, 130, 318, 254, records=tr, what="the tamper-resistant rule")
    f.highlight(446, 130, 318, 254, records=["open-book-exam-#11-021"])
    f.tag(f.w - 24, f.h - 12, "NEC 406.12", anchor="end")
