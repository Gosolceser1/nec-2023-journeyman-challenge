"""Circuit schematics: feeder taps, multiwire branch circuits, high-leg systems, parallel sets."""
from nec_style import *  # noqa: F401,F403


def _breaker(f, x, y, w=60, h=70):
    """Small breaker/OCPD body with a handle, top-left at (x, y)."""
    f.rect(x, y, w, h, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=5)
    f.rect(x + w * 0.3, y + h * 0.25, w * 0.4, h * 0.5, fill=EDGE, stroke=TEXT, sw=SW_THIN, rx=3)


@figure("feeder_tap_10ft_240-21b1", h=450, nec="240.21(B)(1)",
        records={"final-exam-#1-032": {"terms": ["1/10", "one-tenth", "10 times"]}})
def feeder_tap_10ft(f):
    _breaker(f, 40, 80, 80, 80)
    f.text(80, 62, "feeder OCPD", T_LABEL, TEXT, bold=True)
    f.value(80, 196, "400 A max", 28, label="? A")
    for y in (106, 120, 134):
        f.line(120, y, 770, y, WIRE_HOT, SW_WIRE)
    f.text(700, 94, "feeder", T_LABEL, TEXT, bold=True)
    tx = 330
    for y in (106, 120, 134):
        f.circle(tx, y, 6, fill=TEXT)
    f.conduit(tx, 140, tx, 330, width=30)
    for dx in (-8, 0, 8):
        f.line(tx + dx, 106 + (dx + 8) * 1.75, tx + dx, 330, WIRE_HOT, 3)
    f.lines(310, 222, ["tap conductors,", "40 A ampacity"], T_NOTE, TEXT, "end", True)
    f.panel(tx - 55, 330, 110, 95, label=None, breakers=3)
    f.lines(tx + 70, 370, ["panelboard or", "disconnect"], T_NOTE, MUTED, "start")
    f.ext(tx + 18, 120, 410, 120)
    f.ext(tx + 58, 330, 410, 330)
    f.dim_v(400, 120, 330)
    f.lines(414, 220, ["10 ft", "max"], 28, DIM, "start", True)
    x, y = 494, 176
    f.rect(x - 14, 150, 310, 200, fill=PANEL, stroke=EDGE, sw=SW_THIN, rx=8)
    f.text(x, y, "10-ft tap checklist", T_MIN, TEXT, "start", True)
    for i, row in enumerate(("ampacity >= load served", "ends in one panel/disc.", "enclosed in a raceway",
                             "leaves the enclosure:")):
        f.text(x, y + 30 + i * 28, "- " + row, T_MIN, MUTED, "start")
    b = f.text(x + 14, y + 142, "tap >=", T_MIN, MUTED, "start")
    b = f.value(b[0] + b[2] + 8, y + 142, "1/10", T_MIN, anchor="start", pad=5)
    f.text(b[0] + b[2] + 8, y + 142, "of OCPD", T_MIN, MUTED, "start")
    f.tag(f.w - 24, f.h - 14, "NEC 240.21(B)(1)", anchor="end")


@figure("multiwire_branch_circuit_210-4", h=470, nec="210.4(A)-(C)",
        records={"open-book-exam-#1-001": {}, "open-book-exam-#4-008": {"terms": ["line-to-neutral"]}})
def multiwire_branch_circuit(f):
    q1, q2 = ["open-book-exam-#1-001"], ["open-book-exam-#4-008"]
    h1, nn, h2 = 130, 260, 400
    f.rect(30, 80, 250, 360, fill=PANEL, stroke=TEXT, sw=SW_OBJ + 1, rx=8)
    f.text(80, 430, "panel", T_NOTE, MUTED, bold=True)
    for x, y0, lab in ((80, 110, "L1"), (120, 150, "L2")):
        f.line(x, y0, x, 220, WIRE_HOT, 7)
        f.text(x, 248, lab, T_MIN, TEXT, bold=True)
    f.rect(170, 112, 60, 36, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=4)
    f.rect(170, 152, 60, 36, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=4)
    f.line(80, h1, 170, h1, WIRE_HOT, SW_WIRE)
    f.line(120, 170, 170, 170, WIRE_HOT, SW_WIRE)
    f.line(215, 118, 215, 182, AMBER, 8)
    f.mask(200, 104, 30, 92, records=q1, what="handle tie across both poles")
    f.value_lines(530, 40, ["handle tie: all ungrounded", "conductors open together"], T_LABEL, records=q1)
    f.rect(212, nn - 20, 36, 40, fill=WIRE_NEU, rx=4)
    b = f.text(194, nn + 8, "N", T_LABEL, TEXT, "end", True)
    f.mask(b[0] - 12, b[1] - 8, b[2] + 24, b[3] + 16, records=q2, what="'N' bar label")
    f.line(230, h1, 470, h1, WIRE_HOT, SW_WIRE)
    f.polyline([(230, 170), (250, 170), (250, 200), (190, 200), (190, h2), (650, h2)], WIRE_HOT, SW_WIRE)
    f.line(248, nn, 650, nn, WIRE_NEU, SW_WIRE)
    f.text(360, h1 - 12, "L1 (hot)", T_NOTE, TEXT, bold=True)
    f.text(420, h2 - 12, "L2 (hot)", T_NOTE, TEXT, bold=True)
    b = f.text(300, nn + 28, "shared grounded conductor", T_NOTE, WIRE_NEU, "start", True)
    f.mask(b[0] - 8, b[1] - 6, b[2] + 16, b[3] + 12, records=q2, what="'shared grounded conductor'")
    for x, ya, yb, lx, anchor in ((470, h1, nn, 505, "start"), (650, nn, h2, 615, "end")):
        f.line(x, ya, x, yb, WIRE_HOT if ya == h1 else WIRE_NEU, SW_WIRE)
        f.line(x, (ya + yb) / 2, x, yb, WIRE_NEU if ya == h1 else WIRE_HOT, SW_WIRE)
        f.rect(x - 32, (ya + yb) / 2 - 30, 64, 60, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=6)
        f.text(x, (ya + yb) / 2 + 8, "120 V", T_MIN, TEXT, bold=True)
        f.value_lines(lx, (ya + yb) / 2 - 4, ["line-to-neutral", "load"], T_NOTE, anchor=anchor, records=q2)
    f.tag(f.w - 24, f.h - 12, "NEC 210.4", anchor="end")


@figure("high_leg_marking_408-3f1", h=470, nec="408.3(F)(1), 408.3(E)(1), 110.15",
        records={"open-book-exam-#7-024": {"terms": ["delta", "high leg", "208"]}})
def high_leg_marking(f):
    rid = ["open-book-exam-#7-024"]
    f.title("4-wire system, midpoint of one winding grounded", y=40)
    ya, yn, yc, yb = 140, 220, 300, 350
    ax, bx = 250, 90
    f.text(170, 96, "transformer secondary", T_NOTE, MUTED, bold=True)
    f.polyline([(ax, ya), (ax, yc), (bx, yn), (ax, ya)], ROD, 7)
    f.circle(ax, yn, 7, fill=TEXT)
    for xy, lab in (((ax + 14, ya - 8), "A"), ((ax + 14, yc + 22), "C"), ((bx - 14, yn - 12), "B")):
        f.text(xy[0], xy[1], lab, T_LABEL, TEXT, bold=True)
    f.line(ax, yn, 215, yn, WIRE_NEU, 4)
    f.line(215, yn, 215, 240, WIRE_NEU, 4)
    for i, w in enumerate((28, 18, 8)):
        f.line(215 - w / 2, 240 + i * 7, 215 + w / 2, 240 + i * 7, WIRE_GND, 3)
    f.mask(56, 106, 250, 270, records=rid, what="the transformer winding connection")
    px = 520
    f.line(ax, ya, px, ya, WIRE_HOT, SW_WIRE)
    f.line(ax, yn, px, yn, WIRE_NEU, SW_WIRE)
    f.line(ax, yc, px, yc, WIRE_HOT, SW_WIRE)
    f.polyline([(bx, yn), (bx, yb), (px, yb)], WIRE_HOT, SW_WIRE)
    f.rect(452, yb - 9, 26, 18, fill=AMBER, rx=3)
    f.mask(442, yb - 20, 46, 40, records=rid, what="orange marking on the B conductor")
    for y, lab in ((ya, "A"), (yn, "N"), (yc, "C"), (yb, "B")):
        f.text(320, y - 10, lab, T_NOTE, TEXT, bold=True)
    b = f.text(322, yb + 46, "high leg (orange)", T_NOTE, AMBER, "start", True)
    f.mask(b[0] - 8, b[1] - 6, b[2] + 16, b[3] + 12, records=rid, what="'high leg (orange)'")
    f.text(430, (ya + yn) / 2 + 8, "120 V", T_NOTE, DIM, bold=True)
    f.text(430, (yn + yc) / 2 + 8, "120 V", T_NOTE, DIM, bold=True)
    f.rect(px, 110, 250, 270, fill=PANEL, stroke=TEXT, sw=SW_OBJ + 1, rx=8)
    f.text(645, 404, "panelboard", T_LABEL, TEXT, bold=True)
    f.rect(px + 20, 140, 210, 150, fill=BG, stroke=AMBER, sw=SW_OBJ, rx=6)
    f.text(px + 125, 176, "CAUTION", T_NOTE, AMBER, bold=True)
    b = f.value(px + 50, 206, "B", T_NOTE, AMBER, "start", pad=6, records=rid, what="'B' phase on the sign")
    f.text(b[0] + b[2] + 12, 206, "PHASE HAS", T_NOTE, AMBER, "start", True)
    b = f.value(px + 62, 236, "208", T_NOTE, AMBER, "start", pad=6, records=rid, what="'208' volts on the sign")
    f.text(b[0] + b[2] + 12, 236, "VOLTS", T_NOTE, AMBER, "start", True)
    f.text(px + 125, 266, "TO GROUND", T_NOTE, AMBER, bold=True)
    f.text(px + 125, 330, "(example values)", T_MIN, MUTED)
    f.tag(f.w - 24, f.h - 12, "NEC 408.3(F)(1)", anchor="end")


@figure("parallel_egc_250-122f", h=450, nec="250.122(F)(1)(b)",
        records=["final-exam-#1-023"])
def parallel_egc(f):
    f.title("Parallel sets in two raceways", x=40, y=40)
    _breaker(f, 30, 150, 80, 150)
    f.text(70, 136, "feeder OCPD", T_NOTE, TEXT, bold=True)
    f.rect(400, 150, 80, 150, fill=PANEL, stroke=TEXT, sw=SW_OBJ, rx=5)
    f.text(440, 136, "panel", T_NOTE, TEXT, bold=True)
    for y, lab in ((190, "raceway 1"), (262, "raceway 2")):
        f.conduit(110, y, 400, y, width=26)
        f.text(255, y - 22, lab, T_NOTE, MUTED, bold=True)
    f.lines(255, 350, ["one full set (A, B, C)", "in each raceway"], T_NOTE, MUTED)
    f.text(655, 110, "section view", T_NOTE, MUTED, bold=True)
    for cx, lab in ((590, "raceway 1"), (720, "raceway 2")):
        cy = 200
        f.circle(cx, cy, 56, fill=PANEL, stroke=LINE, sw=SW_OBJ + 2)
        for dx, dy, t in ((-19, -17, "A"), (19, -17, "B"), (-19, 19, "C")):
            f.circle(cx + dx, cy + dy, 16, fill=PANEL_2, stroke=WIRE_HOT, sw=SW_THIN)
            f.text(cx + dx, cy + dy + 7, t, T_MIN, TEXT, bold=True)
        f.circle(cx + 19, cy + 20, 11, fill=WIRE_GND)
        f.mask(cx + 3, cy + 4, 32, 32, what="EGC drawn in this raceway")
        f.text(cx, 290, lab, T_NOTE, TEXT, bold=True)
    f.value_lines(655, 336, ["wire-type EGC in each", "raceway, in parallel"], T_LABEL)
    f.tag(f.w - 24, f.h - 14, "NEC 250.122(F)(1)", anchor="end")
