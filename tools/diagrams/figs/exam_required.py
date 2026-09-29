"""The figures three Final Exam #1 questions cannot be answered without.

Drawn from the question and its key (not from the printed page): the lamp
circuit with its two voltage readings, the three meter hookups, and the four
sensing-switch symbols. Nothing here names the answer; after answering the
keyed part is outlined (Fig.highlight).
"""
import math

from nec_style import *  # noqa: F401,F403


def _terminal(f, x, y, r=8):
    f.circle(x, y, r, fill=BG, stroke=TEXT, sw=SW_OBJ)


def _meter(f, x, y, label, r=28, size=T_LABEL):
    f.circle(x, y, r, fill=PANEL, stroke=TEXT, sw=SW_OBJ + 1)
    f.text(x, y + size * 0.36, label, size, TEXT, bold=True)


def _dot(f, x, y):
    f.circle(x, y, 6, fill=WIRE_HOT)


def _readout(f, x, y, s, w=86):
    """Meter display reading s, top-left at (x, y)."""
    f.rect(x, y, w, 40, fill=BG, stroke=DIM, sw=SW_THIN, rx=6)
    f.text(x + w / 2, y + 29, s, 26, DIM, bold=True)


@figure("lamp_switch_meter_readings", h=470, nec="General knowledge (troubleshooting with a voltmeter)",
        records=["final-exam-#1-005"])
def lamp_switch_readings(f):
    xs, xl, yt, yb = 90, 560, 170, 400
    s0, s1 = 260, 340
    # Loop: supply on the left, switch in the top conductor, lamp on the right.
    f.line(xs, yt, s0, yt, WIRE_HOT, SW_WIRE)
    f.line(s1, yt, xl, yt, WIRE_HOT, SW_WIRE)
    f.line(xl, yt, xl, 244, WIRE_HOT, SW_WIRE)
    f.line(xl, 316, xl, yb, WIRE_NEU, SW_WIRE)
    f.line(xl, yb, xs, yb, WIRE_NEU, SW_WIRE)
    f.line(xs, yt, xs, 247, WIRE_HOT, SW_WIRE)
    f.line(xs, 323, xs, yb, WIRE_NEU, SW_WIRE)
    # 120 V AC supply.
    f.circle(xs, 285, 38, fill=PANEL, stroke=TEXT, sw=SW_OBJ + 1)
    f.path(f"M {xs - 22} 285 q 11 -22 22 0 t 22 0", TEXT, SW_OBJ)
    f.text(xs + 52, 278, "120 V", T_LABEL, TEXT, "start", True)
    f.text(xs + 52, 306, "supply", T_NOTE, MUTED, "start")
    # Switch S1, closed (ON).
    _terminal(f, s0, yt)
    _terminal(f, s1, yt)
    f.line(s0 + 6, yt - 4, s1 - 3, yt - 7, TEXT, SW_OBJ + 2)
    f.text((s0 + s1) / 2, yt + 44, "S1", T_LABEL, TEXT, bold=True)
    f.text((s0 + s1) / 2, yt + 72, "switch ON (closed)", T_NOTE, MUTED)
    # Voltmeter across S1.
    mx, my = (s0 + s1) / 2, 70
    _dot(f, s0 - 24, yt)
    _dot(f, s1 + 24, yt)
    f.polyline([(s0 - 24, yt), (s0 - 24, my), (mx - 28, my)], DIM, SW_THIN + 1)
    f.polyline([(s1 + 24, yt), (s1 + 24, my), (mx + 28, my)], DIM, SW_THIN + 1)
    _meter(f, mx, my, "V")
    _readout(f, s1 + 44, my - 20, "0 V")
    # Lamp L1 with an unbroken filament.
    cy, r = 280, 40
    f.circle(xl, cy, r, fill=BG, stroke=TEXT, sw=SW_OBJ)
    f.line(xl, cy - r, xl - 16, cy - 2, TEXT, SW_OBJ)
    f.line(xl, cy + r, xl + 16, cy - 2, TEXT, SW_OBJ)
    pts = [(xl - 16 + 32 * k / 24, cy - 2 - 9 * abs(math.sin(math.pi * 3 * k / 24))) for k in range(25)]
    f.polyline(pts, AMBER, SW_OBJ)
    f.text(xl - 56, cy - 4, "L1", T_LABEL, TEXT, "end", True)
    f.text(xl - 56, cy + 24, "lamp", T_NOTE, MUTED, "end")
    # Voltmeter across L1.
    mx = 690
    _dot(f, xl, 214)
    _dot(f, xl, 346)
    f.polyline([(xl, 214), (mx, 214), (mx, cy - 28)], DIM, SW_THIN + 1)
    f.polyline([(xl, 346), (mx, 346), (mx, cy + 28)], DIM, SW_THIN + 1)
    _meter(f, mx, cy, "V")
    _readout(f, mx - 43, cy + 84, "120 V")
    f.text(400, 446, "Switch is ON, but the lamp does not light.", T_NOTE, MUTED, bold=True)
    f.highlight(xl - 100, cy - 58, 154, 116)


@figure("meter_hookups_three_meters", h=380, nec="General knowledge (meter connections)",
        records=["final-exam-#1-013"])
def meter_hookups(f):
    yt, yb, x0, xl = 120, 290, 60, 700
    # Supply terminals, two conductors, the load.
    for y in (yt, yb):
        _terminal(f, x0, y)
    f.text(x0, 340, "supply", T_NOTE, MUTED, bold=True)
    f.line(x0 + 8, yt, 152, yt, WIRE_HOT, SW_WIRE)
    f.line(208, yt, 332, yt, WIRE_HOT, SW_WIRE)
    f.line(388, yt, xl, yt, WIRE_HOT, SW_WIRE)
    f.line(x0 + 8, yb, xl, yb, WIRE_NEU, SW_WIRE)
    f.line(xl, yt, xl, 161, WIRE_HOT, SW_WIRE)
    f.line(xl, 249, xl, yb, WIRE_NEU, SW_WIRE)
    f.circle(xl, (yt + yb) / 2, 44, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ + 1)
    f.text(xl, (yt + yb) / 2 + 8, "LOAD", T_MIN, TEXT, bold=True)
    # Meter I: in the conductor, and a lead across to the other conductor.
    _meter(f, 180, yt, "I")
    f.line(180, yt + 28, 180, yb, DIM, SW_THIN + 1)
    _dot(f, 180, yb)
    # Meter II: in the conductor only.
    _meter(f, 360, yt, "II")
    # Meter III: across the two conductors, beside the load.
    x3 = 540
    _dot(f, x3, yt)
    _dot(f, x3, yb)
    f.line(x3, yt, x3, 177, DIM, SW_THIN + 1)
    f.line(x3, 233, x3, yb, DIM, SW_THIN + 1)
    _meter(f, x3, (yt + yb) / 2, "III")
    f.text(400, 52, "Three meters connected three ways", T_NOTE, MUTED, bold=True)
    f.highlight(318, yt - 46, 84, 92)


def _sensing_switch(f, cx, y, kind):
    """Normally open sensing switch: two terminals, the blade, and the actuator under it."""
    a, b = cx - 46, cx + 46
    _terminal(f, a, y)
    _terminal(f, b, y)
    f.line(a + 7, y - 4, b + 8, y - 38, TEXT, SW_OBJ + 1)
    top = y - 20
    if kind == "temperature":
        f.polyline([(cx, top), (cx, y + 44), (cx + 20, y + 44), (cx + 20, y + 64),
                    (cx - 20, y + 64), (cx - 20, y + 84)], TEXT, SW_OBJ + 1)
    elif kind == "flow":
        f.line(cx, top, cx, y + 86, TEXT, SW_OBJ + 1)
        f.poly([(cx, y + 50), (cx + 34, y + 64), (cx, y + 78)], TEXT)
    elif kind == "pressure":
        f.line(cx, top, cx, y + 56, TEXT, SW_OBJ + 1)
        f.path(f"M {cx - 26} {y + 56} A 26 26 0 0 0 {cx + 26} {y + 56} Z", TEXT, SW_OBJ + 1, fill=PANEL_2)
    elif kind == "level":
        f.line(cx, top, cx, y + 54, TEXT, SW_OBJ + 1)
        f.circle(cx, y + 74, 20, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ + 1)


@figure("switch_symbols_a_to_d", h=320, nec="General knowledge (control symbols)",
        records=["final-exam-#1-047"])
def switch_symbols(f):
    y = 120
    for cx, kind, lab in ((110, "temperature", "(a)"), (300, "flow", "(b)"),
                          (490, "pressure", "(c)"), (680, "level", "(d)")):
        _sensing_switch(f, cx, y, kind)
        f.text(cx, 270, lab, 30, TEXT, bold=True)
    f.text(400, 44, "Four switch contacts, each with a different actuator", T_NOTE, MUTED, bold=True)
    f.highlight(40, 62, 140, 232)
