"""Worked calculation cards: unit loads, Ohm's law, busbars, welders, imaging and motor-group feeders."""
from nec_style import *  # noqa: F401,F403


def _card(f, x, y, w, h, title=""):
    f.rect(x, y, w, h, fill=PANEL, stroke=EDGE, sw=SW_THIN, rx=8)
    if title:
        f.text(x + 14, y + 30, title, T_NOTE, TEXT, "start", True)


def _ocpd(f, x, y, w=56, h=64, label=None):
    f.rect(x, y, w, h, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=5)
    f.rect(x + w * 0.3, y + h * 0.25, w * 0.4, h * 0.5, fill=EDGE, stroke=TEXT, sw=SW_THIN, rx=3)
    if label:
        f.text(x + w / 2, y - 12, label, T_LABEL, TEXT, bold=True)


def _motor(f, cx, cy, r=34, label="M"):
    f.circle(cx, cy, r, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ)
    f.text(cx, cy + 9, label, T_LABEL, TEXT, bold=True)


@figure("office_lighting_220-42a", h=440, nec="220.42, Table 220.42(A), 220.5(C)", when="after",
        records=["final-exam-#1-004", "open-book-exam-#1-021"])
def office_lighting(f):
    f.title("General lighting load of an office (plan, not to scale)", y=34)
    x0, y0, x1, y1 = 60, 90, 420, 290
    f.rect(x0, y0, x1 - x0, y1 - y0, fill=PANEL, stroke=LINE, sw=SW_STRUCT)
    for x in (180, 300):
        f.line(x, y0, x, y0 + 80, LINE, SW_OBJ)
    f.line(180, y0 + 80, 300, y0 + 80, LINE, SW_OBJ)
    for x in (100, 140, 340, 380):
        f.rect(x - 14, 200, 28, 50, fill=PANEL_2, stroke=EDGE, sw=SW_THIN, rx=3)
    f.lines(240, 150, ["offices"], T_LABEL, TEXT, bold=True)
    f.ext(x0, y0 - 4, x0, 62)
    f.ext(x1, y0 - 4, x1, 62)
    f.dim_h(x0, x1, 70)
    f.text(240, 322, "5,000 sq ft", T_VALUE, DIM, bold=True)
    f.text(240, 352, "(outside dimensions, 220.5(C))", T_MIN, MUTED)
    _card(f, 450, 70, 330, 300, "Table 220.42(A) unit load")
    f.text(466, 140, "office:", 26, TEXT, "start", True)
    f.value(570, 140, "1.3 VA per sq ft", 26, anchor="start", pad=6, what="the office unit load")
    f.text(466, 200, "5,000 sq ft x unit load", T_NOTE, TEXT, "start")
    b = f.text(466, 250, "=", 28, TEXT, "start", True)
    f.value(b[0] + b[2] + 12, 250, "6,500 VA", 30, anchor="start")
    f.lines(466, 300, ["125% continuous factor is", "already in the table (Note)"], T_MIN, MUTED, "start", gap=1.15)
    f.tag(f.w - 24, f.h - 14, "NEC Table 220.42(A)", anchor="end")


@figure("ohms_law_wheel", h=470, nec="general electrical theory (W = E x I, Ohm's law)",
        records=["final-exam-#1-019", "final-exam-#3-033"])
def ohms_wheel(f):
    letter = ["final-exam-#1-019"]
    f.title("Ohm's law and the power formula", y=34)
    cx, cy, r = 190, 250, 150
    f.circle(cx, cy, r, fill=PANEL, stroke=LINE, sw=SW_STRUCT)
    f.line(cx - r, cy, cx + r, cy, LINE, SW_OBJ)
    f.line(cx, cy - r, cx, cy + r, LINE, SW_OBJ)
    f.circle(cx, cy, 56, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ)
    f.text(cx, cy + 10, "E I R P", T_NOTE, TEXT, bold=True)
    quads = [(cx - 78, cy - 70, "E", ["I x R", "P / I"]), (cx + 78, cy - 70, "I", ["E / R", "P / E"]),
             (cx - 78, cy + 62, "R", ["E / I", "E2 / P"]), (cx + 78, cy + 62, "P", ["E x I", "I2 x R"])]
    for x, y, k, rows in quads:
        f.text(x, y - 16, k + " =", T_LABEL, DIM, bold=True)
        f.lines(x, y + 14, rows, T_MIN, TEXT, gap=1.15)
    f.text(cx, cy + r + 34, "E2 = E squared, I2 = I squared", T_MIN, MUTED)
    _card(f, 380, 60, 400, 176, "The letters")
    f.text(396, 120, "E = volts (electromotive force)", T_NOTE, TEXT, "start")
    f.text(396, 154, "I = intensity of current, amps", T_NOTE, TEXT, "start")
    f.text(396, 188, "R = ohms,  P (or W) = watts", T_NOTE, TEXT, "start")
    f.text(396, 220, "W = E x I is the same as P = E x I", T_MIN, MUTED, "start")
    f.mask(388, 98, 384, 132, records=letter, what="what each letter stands for")
    _card(f, 380, 256, 400, 170, "Example: 2 W load on 20 V DC")
    f.text(396, 322, "P = 2 W,  E = 20 V", T_NOTE, TEXT, "start")
    b = f.text(396, 370, "I = P / E = 2 / 20 =", 26, TEXT, "start")
    f.value(b[0] + b[2] + 12, 370, "0.10 A", 28, anchor="start", pad=6, what="the example current")
    f.tag(f.w - 24, f.h - 12, "Ohm's law", anchor="end")


@figure("multioutlet_assembly_220-14h", h=480, nec="220.14(H)",
        records=["final-exam-#1-010"])
def multioutlet(f):
    f.title("Fixed multioutlet assembly, commercial (elevation)", y=34)
    x0, x1, y = 60, 740, 130
    f.rect(x0, y, x1 - x0, 40, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=6)
    n = 10
    for i in range(n):
        x = x0 + (i + 0.5) * (x1 - x0) / n
        f.rect(x - 12, y + 8, 24, 24, fill=PANEL, stroke=TEXT, sw=SW_THIN, rx=3)
        f.line(x - 4, y + 15, x - 4, y + 25, TEXT, 3)
        f.line(x + 4, y + 15, x + 4, y + 25, TEXT, 3)
    f.line(x0, 200, x1, 200, LINE, SW_THIN)
    for ft in range(13):
        x = x0 + ft * (x1 - x0) / 12
        f.line(x, 192, x, 208 if ft % 4 else 214, LINE, SW_THIN)
        if ft % 4 == 0:
            f.text(x, 240, f"{ft} ft", T_MIN, MUTED)
    f.text(400, 110, "12 ft continuous length", T_NOTE, TEXT, bold=True)
    _card(f, 30, 262, 360, 150, "Not used at the same time")
    b = f.text(46, 326, "each", T_NOTE, TEXT, "start")
    f.value(b[0] + b[2] + 10, 326, "5 ft or fraction", T_NOTE, anchor="start", pad=5, what="the length per outlet")
    b = f.text(46, 370, "= one outlet of", T_NOTE, TEXT, "start")
    f.value(b[0] + b[2] + 10, 370, "180 VA", T_NOTE, anchor="start", pad=5, what="the VA per outlet")
    _card(f, 410, 262, 360, 150, "Used at the same time")
    f.lines(426, 326, ["each 1 ft or fraction", "= one outlet of 180 VA"], T_NOTE, MUTED, "start", gap=1.6)
    b = f.text(30, 454, "This assembly:", T_NOTE, TEXT, "start", True)
    f.value(b[0] + b[2] + 12, 454, "3 outlets x 180 VA = 540 VA", T_NOTE, anchor="start", pad=5,
            what="the worked load")
    f.tag(f.w - 24, f.h - 14, "NEC 220.14(H)", anchor="end")


@figure("busbar_ampacity_366-23a", h=430, nec="366.23(A)",
        records=["final-exam-#3-063", "final-exam-#5-039"])
def busbar(f):
    wide = ["final-exam-#5-039"]
    f.title("Bare copper bars in a gutter: amps from the cross-section", y=34)
    # Bar 1: 1 1/2 sq in (drawn as 3 in x 1/2 in).
    f.text(200, 86, "Bar A", T_LABEL, TEXT, bold=True)
    f.rect(80, 110, 240, 40, fill=ROD, stroke=AMBER, sw=SW_OBJ)
    f.text(200, 184, "cross-section 1 1/2 sq in", T_NOTE, TEXT)
    b = f.text(80, 226, "x", 26, TEXT, "start", True)
    f.value(b[0] + b[2] + 10, 226, "1,000 A per sq in", 26, anchor="start", pad=5, what="the copper density")
    b = f.text(80, 272, "=", 26, TEXT, "start", True)
    f.value(b[0] + b[2] + 12, 272, "1,500 A", 28, anchor="start", pad=6)
    # Bar 2: 4 in x 1/2 in.
    f.text(600, 86, "Bar B", T_LABEL, TEXT, bold=True)
    f.rect(440, 110, 320, 40, fill=ROD, stroke=AMBER, sw=SW_OBJ)
    f.dim_h(440, 760, 170)
    f.text(600, 200, "4 in wide x 1/2 in thick", T_NOTE, DIM, bold=True)
    b = f.text(440, 244, "4 x 1/2 =", 26, TEXT, "start")
    f.value(b[0] + b[2] + 12, 244, "2 sq in", 26, anchor="start", records=wide, pad=5, what="the bar area")
    f.value_lines(440, 290, ["x 1,000 A per sq in = 2,000 A"], T_NOTE, anchor="start", pad=6,
                  what="the bar B working")
    _card(f, 30, 318, 740, 70)
    f.text(46, 360, "Continuous current limit: copper 1,000 A, aluminum 700 A per sq in", T_NOTE, TEXT, "start")
    f.mask(40, 330, 720, 50, records=None, what="the density rule")
    f.tag(f.w - 24, f.h - 10, "NEC 366.23(A)", anchor="end")


@figure("welder_supply_630", h=500, nec="630.12, 630.12(A), 240.6(A), 630.31(A), Table 630.31(A)",
        records=["final-exam-#1-025", "final-exam-#3-040"])
def welders(f):
    arc = ["final-exam-#1-025"]
    res = ["final-exam-#3-040"]
    f.title("Welder supply: two worked cards", y=34)
    _card(f, 20, 56, 370, 400, "Arc welder: overcurrent device")
    f.text(34, 110, "nameplate I1max = 43 A", T_NOTE, TEXT, "start", True)
    b = f.text(34, 160, "OCPD not more than", T_NOTE, TEXT, "start")
    f.value(34, 200, "200% x 43 A = 86 A", 26, anchor="start", records=arc, pad=6, what="the 200% step")
    f.lines(34, 256, ["not a standard rating (240.6(A)):", "the next higher one is permitted"], T_NOTE,
            MUTED, "start", gap=1.2)
    b = f.text(34, 350, "max OCPD =", 26, TEXT, "start")
    f.value(b[0] + b[2] + 12, 350, "90 A", 30, anchor="start", records=arc, pad=6)
    f.lines(34, 404, ["I1max: rated supply current", "at maximum rated output"], T_MIN, MUTED, "start", gap=1.1)
    _card(f, 410, 56, 370, 400, "Resistance welder: conductors")
    f.text(424, 110, "21 A primary, 15% duty cycle", T_NOTE, TEXT, "start", True)
    f.text(424, 150, "Table 630.31(A) multipliers:", T_NOTE, MUTED, "start")
    rows = [("50%", "0.71"), ("40%", "0.63"), ("30%", "0.55"), ("25%", "0.50"), ("20%", "0.45"),
            ("15%", "0.39"), ("10%", "0.32")]
    for i, (dc, m) in enumerate(rows):
        x = 440 if i < 4 else 610
        y = 184 + (i if i < 4 else i - 4) * 32
        f.text(x, y, dc, T_MIN, TEXT, "start")
        if dc == "15%":
            f.value(x + 70, y, m, T_MIN, anchor="start", records=res, pad=4, what="the 15% multiplier")
        else:
            f.text(x + 70, y, m, T_MIN, DIM, "start", True)
    b = f.text(424, 350, "21 A x multiplier =", 26, TEXT, "start")
    f.value(424, 396, "8.19 A", 30, anchor="start", records=res, pad=6)
    f.tag(f.w - 24, f.h - 12, "NEC 630.12, 630.31", anchor="end")


@figure("imaging_feeder_517-73b", h=470, nec="517.73(B)",
        records={"open-book-exam-#7-004": {"terms": ["momentary"]}})
def imaging_feeder(f):
    f.title("Feeder for several imaging units (example ratings)", y=34)
    base, x0 = 330, 90
    units = [(200, "50%", 100), (150, "25%", 37.5), (100, "10%", 10), (80, "10%", 8)]
    f.line(x0 - 10, base, 520, base, LINE, SW_OBJ)
    for i, (a, pct, res) in enumerate(units):
        x = x0 + i * 110
        hbar = a * 1.1
        f.rect(x, base - hbar, 70, hbar, fill=PANEL_2, stroke=TEXT, sw=SW_THIN, rx=3)
        f.rect(x, base - hbar * float(pct[:-1]) / 100, 70, hbar * float(pct[:-1]) / 100, fill=OK, op=0.45)
        f.text(x + 35, base - hbar - 12, f"{a} A", T_NOTE, TEXT, bold=True)
        f.text(x + 35, base + 30, pct, T_NOTE, DIM, bold=True)
        f.text(x + 35, base + 58, f"= {res:g} A", T_MIN, TEXT)
    b = f.text(x0 - 10, base + 104, "bar height: each unit's", T_NOTE, MUTED, "start")
    v = f.value(b[0] + b[2] + 10, base + 104, "momentary", T_NOTE, TEXT, "start", records=None, pad=5,
            what="the rating used")
    f.text(v[0] + v[2] + 16, base + 104, "demand rating", T_NOTE, MUTED, "start")
    _card(f, 540, 70, 240, 300, "Feeder minimum")
    f.lines(556, 130, ["largest: 50%", "next: 25%", "each other: 10%"], T_NOTE, TEXT, "start", gap=1.4)
    f.text(556, 262, "100 + 37.5 + 10 + 8", T_NOTE, TEXT, "start")
    f.text(556, 306, "= 155.5 A", 28, OK, "start", True)
    f.text(556, 346, "(example units)", T_MIN, MUTED, "start")
    f.tag(f.w - 24, f.h - 10, "NEC 517.73(B)", anchor="end")


@figure("motor_group_feeder_430-62a", h=500, nec="430.62(A), Table 430.52",
        records=["final-exam-#3-069"])
def motor_group(f):
    f.title("Feeder to three motors (one-line, example values)", y=34)
    _ocpd(f, 60, 70, 60, 70, "")
    f.text(90, 64, "feeder OCPD", T_NOTE, TEXT, bold=True)
    f.line(90, 140, 90, 190, WIRE_HOT, SW_WIRE)
    f.line(90, 190, 690, 190, WIRE_HOT, SW_WIRE)
    motors = [(250, "40 A", "100 A"), (450, "20 A", "50 A"), (650, "10 A", "25 A")]
    for x, flc, br in motors:
        f.line(x, 190, x, 222, WIRE_HOT, SW_WIRE)
        _ocpd(f, x - 28, 222, 56, 58)
        f.text(x + 38, 260, br, T_NOTE, TEXT, "start", True)
        f.line(x, 280, x, 320, WIRE_HOT, SW_WIRE)
        _motor(f, x, 352)
        f.text(x, 414, "FLC " + flc, T_NOTE, TEXT, bold=True)
    f.text(420, 176, "feeder", T_MIN, MUTED)
    f.text(160, 258, "branch", T_MIN, MUTED, "end")
    f.text(160, 280, "breakers", T_MIN, MUTED, "end")
    f.value_lines(430, 80, ["feeder OCPD <= 100 A (largest branch", "device) + 20 A + 10 A = 130 A"],
                  T_NOTE, TEXT, bold=False, pad=6, gap=1.2, what="the feeder rule")
    f.value(400, 452, "no rounding up to the next size: use 125 A", T_NOTE, MUTED, bold=False, pad=6,
            what="the rounding note")
    f.tag(f.w - 24, f.h - 10, "NEC 430.62(A)", anchor="end")
