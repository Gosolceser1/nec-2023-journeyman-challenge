"""Circuit schematics: feeder taps, multiwire branch circuits, high-leg systems, parallel sets."""
import math

from nec_style import *  # noqa: F401,F403


def _winding(f, x1, y1, x2, y2, loops, color=TEXT, sw=SW_OBJ):
    """Transformer winding from (x1, y1) to (x2, y2): semicircular turns bulging
    to the right of the direction of travel."""
    r = math.hypot(x2 - x1, y2 - y1) / loops / 2
    dx, dy = (x2 - x1) / loops, (y2 - y1) / loops
    f.path(f"M {x1:.1f} {y1:.1f} " + " ".join(f"a {r:.1f} {r:.1f} 0 0 0 {dx:.1f} {dy:.1f}"
                                              for _ in range(loops)), color, sw)


@figure("feeder_tap_10ft_240-21b1", h=450, nec="240.21(B)(1), 409.21(B)",
        records={"final-exam-#1-032": {"terms": ["1/10", "one-tenth", "10 times"]},
                 "open-book-exam-#10-004": {"when": "after"},
                 "open-book-exam-#3-002": {"like": "final-exam-#1-032"}})
def feeder_tap_10ft(f):
    f.breaker(44, 70, 78, 72, poles=3)
    f.text(83, 52, "feeder OCPD", T_LABEL, TEXT, bold=True)
    f.value(142, 116, "400 A max", 28, anchor="start", label="? A")
    ys = (160, 174, 188)
    for k, y in enumerate(reversed(ys)):
        lx = 44 + 78 * (k + 0.5) / 3
        f.polyline([(lx, 135), (lx, y), (770, y)], WIRE_HOT, SW_WIRE)
    f.text(700, 146, "feeder", T_LABEL, TEXT, bold=True)
    tx = 330
    f.conduit(tx, 196, tx, 330, width=34)
    for dx, y in zip((-10, 0, 10), ys):
        f.line(tx + dx, y, tx + dx, 330, WIRE_HOT, 3)
        f.circle(tx + dx, y, 6, fill=TEXT)
    f.lines(306, 250, ["tap conductors,", "40 A ampacity"], T_NOTE, TEXT, "end", True)
    f.panel(tx - 55, 330, 110, 95, label=None, breakers=3)
    f.lines(tx - 70, 366, ["panelboard, disconnect", "or control device"], T_NOTE, MUTED, "end")
    f.ext(tx + 18, 174, 410, 174)
    f.ext(tx + 58, 330, 410, 330)
    f.dim_v(400, 174, 330)
    f.lines(414, 244, ["10 ft", "max"], 28, DIM, "start", True)
    f.card(492, 206, 288, 194, "10-ft tap checklist")
    x, y = 506, 236
    for i, row in enumerate(("ampacity >= load served", "ends in one panel/disc.", "enclosed in a raceway",
                             "leaves the enclosure:")):
        f.text(x, y + 30 + i * 28, "- " + row, T_MIN, MUTED, "start")
    b = f.text(x + 14, y + 142, "tap >=", T_MIN, MUTED, "start")
    b = f.value(b[0] + b[2] + 8, y + 142, "1/10", T_MIN, anchor="start", pad=5)
    f.text(b[0] + b[2] + 8, y + 142, "of OCPD", T_MIN, MUTED, "start")
    f.tag(f.w - 24, f.h - 14, "NEC 240.21(B)(1)", anchor="end")


@figure("multiwire_branch_circuit_210-4", h=470, nec="210.4(A)-(C)",
        records={"open-book-exam-#1-001": {}, "open-book-exam-#4-008": {"terms": ["line-to-neutral"]},
                 "open-book-exam-#2-002": {}})
def multiwire_branch_circuit(f):
    q1, q2 = ["open-book-exam-#1-001"], ["open-book-exam-#4-008"]
    h1, nn, h2 = 130, 260, 400
    f.rect(30, 80, 270, 360, fill=PANEL, stroke=TEXT, sw=SW_OBJ + 1, rx=8)
    f.text(80, 430, "panel", T_NOTE, MUTED, bold=True)
    for x, y0, lab in ((80, 110, "L1"), (120, 150, "L2")):
        f.rect(x - 5, y0, 10, 220 - y0, fill=STEEL, stroke=LINE, sw=1.5, rx=2)
        f.text(x, 248, lab, T_MIN, TEXT, bold=True)
    f.line(85, h1, 150, h1, WIRE_HOT, SW_WIRE)
    f.line(125, 170, 150, 170, WIRE_HOT, SW_WIRE)
    for yy in (112, 152):
        f.mini_breaker(150, yy, 80, 36, handle_left=True)
    f.line(173, 120, 173, 180, AMBER, 7)
    f.mask(157, 104, 32, 92, records=q1, what="handle tie across both poles")
    f.value_lines(530, 40, ["handle tie: all ungrounded", "conductors open together"], T_LABEL, records=q1)
    f.rect(264, nn - 26, 22, 52, fill=WIRE_NEU, stroke=TEXT, sw=1.5, rx=3)
    for yy in (nn - 13, nn, nn + 13):
        f.circle(275, yy, 4, fill=PANEL, stroke=EDGE, sw=1)
    b = f.text(275, nn - 38, "N", T_LABEL, TEXT, bold=True)
    f.mask(b[0] - 12, b[1] - 8, b[2] + 24, b[3] + 16, records=q2, what="'N' bar label")
    f.line(230, h1, 470, h1, WIRE_HOT, SW_WIRE)
    f.polyline([(230, 170), (248, 170), (248, h2), (650, h2)], WIRE_HOT, SW_WIRE)
    f.line(286, nn, 650, nn, WIRE_NEU, SW_WIRE)
    f.text(360, h1 - 12, "L1 (hot)", T_NOTE, TEXT, bold=True)
    f.text(420, h2 - 12, "L2 (hot)", T_NOTE, TEXT, bold=True)
    b = f.text(310, nn + 30, "shared grounded conductor", T_NOTE, WIRE_NEU, "start", True)
    f.mask(b[0] - 8, b[1] - 6, b[2] + 16, b[3] + 12, records=q2, what="'shared grounded conductor'")
    for x, ya, yb, lx, anchor, vx, va in ((470, h1, nn, 505, "start", 444, "end"),
                                         (650, nn, h2, 615, "end", 676, "start")):
        cy = (ya + yb) / 2
        f.line(x, ya, x, yb, WIRE_HOT if ya == h1 else WIRE_NEU, SW_WIRE)
        f.line(x, cy, x, yb, WIRE_NEU if ya == h1 else WIRE_HOT, SW_WIRE)
        f.receptacle(x, cy, 64)
        f.text(vx, cy + 8, "120 V", T_MIN, TEXT, va, True)
        f.value_lines(lx, cy - 4, ["line-to-neutral", "load"], T_NOTE, anchor=anchor, records=q2)
    f.tag(f.w - 24, f.h - 12, "NEC 210.4", anchor="end")


@figure("high_leg_marking_408-3f1", h=470, nec="408.3(F)(1), 408.3(E)(1), 110.15",
        records={"open-book-exam-#7-024": {"terms": ["delta", "high leg", "208"]},
                 "open-book-exam-#5-007": {"when": "after"}, "open-book-exam-#12-010": {}})
def high_leg_marking(f):
    rid = ["open-book-exam-#7-024"]
    f.title("4-wire system, midpoint of one winding grounded", y=40)
    ya, yn, yc, yb = 140, 220, 300, 350
    ax, bx = 250, 90
    f.text(170, 96, "transformer secondary", T_NOTE, MUTED, bold=True)
    _winding(f, ax, ya, ax, yn, 3)
    _winding(f, ax, yn, ax, yc, 3)
    _winding(f, ax, yc, bx, yn, 6)
    _winding(f, bx, yn, ax, ya, 6)
    for xy in ((ax, ya), (ax, yc), (bx, yn)):
        f.circle(xy[0], xy[1], 6, fill=TEXT)
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
    for tx in (446, 470):
        f.rect(tx, yb - 8, 16, 16, fill=ORANGE, rx=2)
    f.mask(436, yb - 20, 60, 40, records=rid, what="orange marking on the B conductor")
    for y, lab in ((ya, "A"), (yn, "N"), (yc, "C"), (yb, "B")):
        f.text(320, y - 10, lab, T_NOTE, TEXT, bold=True)
    b = f.text(322, yb + 46, "high leg (orange)", T_NOTE, ORANGE, "start", True)
    f.mask(b[0] - 8, b[1] - 6, b[2] + 16, b[3] + 12, records=rid, what="'high leg (orange)'")
    f.text(430, (ya + yn) / 2 + 8, "120 V", T_NOTE, DIM, bold=True)
    f.text(430, (yn + yc) / 2 + 8, "120 V", T_NOTE, DIM, bold=True)
    f.panel(px, 110, 250, 270, label="panelboard", breakers=0)
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
        records={"final-exam-#1-023": {}, "open-book-exam-#3-016": {"like": "final-exam-#1-023"}})
def parallel_egc(f):
    f.title("Parallel sets in two raceways", x=40, y=40)
    f.breaker(30, 150, 80, 150, poles=3)
    f.text(70, 136, "feeder OCPD", T_NOTE, TEXT, bold=True)
    f.panel(400, 150, 90, 150, label=None, breakers=3)
    f.text(445, 136, "panel", T_NOTE, TEXT, bold=True)
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
