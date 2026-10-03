"""Worked calculation cards: unit loads, Ohm's law, busbars, welders, imaging and motor-group feeders."""
from nec_style import *  # noqa: F401,F403


@figure("office_lighting_220-42a", h=440, nec="Table 220.42(A)", when="after",
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
    f.card(450, 70, 330, 300, "Table 220.42(A) unit load")
    f.text(466, 140, "office:", 26, TEXT, "start", True)
    f.value(570, 140, "1.3 VA per sq ft", 26, anchor="start", pad=6, what="the office unit load")
    f.text(466, 200, "5,000 sq ft x unit load", T_NOTE, TEXT, "start")
    b = f.text(466, 250, "=", 28, TEXT, "start", True)
    f.value(b[0] + b[2] + 12, 250, "6,500 VA", 30, anchor="start")
    f.lines(466, 300, ["125% continuous factor is", "already in the table (Note)"], T_MIN, MUTED, "start", gap=1.15)
    f.tag(f.w - 24, f.h - 14, "NEC Table 220.42(A)", anchor="end")


@figure("ohms_law_letters", h=470, nec="General knowledge (the letters of W = E x I)",
        records=["final-exam-#1-019"])
def ohms_letters(f):
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
    f.card(380, 120, 400, 220, "The letters")
    f.text(396, 190, "E = volts (electromotive force)", T_NOTE, TEXT, "start")
    f.text(396, 230, "I = intensity of current, amps", T_NOTE, TEXT, "start")
    f.text(396, 270, "R = ohms,  P (or W) = watts", T_NOTE, TEXT, "start")
    f.text(396, 312, "W = E x I is the same as P = E x I", T_MIN, MUTED, "start")
    f.mask(388, 164, 384, 166, what="what each letter stands for")
    f.tag(f.w - 24, f.h - 12, "Ohm's law", anchor="end")


@figure("power_current_dc", h=440, nec="General calculation (current from watts and volts)",
        records=["final-exam-#3-033"])
def power_current(f):
    f.title("A 2 W load on a 20 VDC supply", y=34)
    # Battery, conductors and a resistive load in one loop.
    x0, x1, y0, y1 = 110, 520, 100, 300
    f.line(x0, y0, x1, y0, WIRE_HOT, SW_WIRE)
    f.line(x0, y1, x1, y1, WIRE_HOT, SW_WIRE)
    f.line(x0, y0, x0, 172, WIRE_HOT, SW_WIRE)
    f.line(x0, 228, x0, y1, WIRE_HOT, SW_WIRE)
    for k, (w, yy) in enumerate(((60, 176), (34, 190), (60, 206), (34, 220))):
        f.line(x0 - w / 2, yy, x0 + w / 2, yy, TEXT, SW_OBJ + (1 if w > 40 else 2))
    f.text(x0 - 46, 182, "+", T_LABEL, TEXT, bold=True)
    f.text(x0 + 52, 210, "20 VDC", T_NOTE, TEXT, "start", True)
    zig = [(x1, y0)] + [(x1 + (18 if k % 2 else -18), 140 + k * 15) for k in range(8)] + [(x1, y1)]
    f.line(x1, y0, x1, 132, WIRE_HOT, SW_WIRE)
    f.polyline([(x1, 132)] + zig[1:-1] + [(x1, 268)], TEXT, SW_OBJ)
    f.line(x1, 268, x1, y1, WIRE_HOT, SW_WIRE)
    f.text(x1 + 40, 210, "load: 2 W", T_NOTE, TEXT, "start", True)
    f.arrow(250, y0 - 22, 380, y0 - 22, DIM)
    f.text(315, y0 - 34, "I = ?", T_NOTE, DIM, bold=True)
    f.card(40, 330, 720, 90)
    f.value_lines(60, 384, ["P = E x I, so I = P / E = 2 W / 20 V = 0.10 A"], 26, anchor="start", pad=6,
                  what="the working and the current")


@figure("multioutlet_assembly_220-14h", h=480, nec="220.14(H)",
        records={"final-exam-#1-010": {}, "open-book-exam-#2-018": {"like": "final-exam-#1-010"}})
def multioutlet(f):
    f.title("Fixed multioutlet assembly, commercial (elevation)", y=34)
    x0, x1, y = 60, 740, 130
    f.rect(x0, y, x1 - x0, 40, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=6)
    n = 10
    for i in range(n):
        x = x0 + (i + 0.5) * (x1 - x0) / n
        f.nema_face(x, y + 20, 14, "5-15")
    f.line(x0, 200, x1, 200, LINE, SW_THIN)
    for ft in range(13):
        x = x0 + ft * (x1 - x0) / 12
        f.line(x, 192, x, 208 if ft % 4 else 214, LINE, SW_THIN)
        if ft % 4 == 0:
            f.text(x, 240, f"{ft} ft", T_MIN, MUTED)
    f.text(400, 110, "12 ft continuous length", T_NOTE, TEXT, bold=True)
    f.card(30, 262, 360, 150, "Not used at the same time")
    b = f.text(46, 326, "each", T_NOTE, TEXT, "start")
    f.value(b[0] + b[2] + 10, 326, "5 ft or fraction", T_NOTE, anchor="start", pad=5, what="the length per outlet")
    b = f.text(46, 370, "= one outlet of", T_NOTE, TEXT, "start")
    f.value(b[0] + b[2] + 10, 370, "180 VA", T_NOTE, anchor="start", pad=5, what="the VA per outlet")
    f.card(410, 262, 360, 150, "Used at the same time")
    f.lines(426, 326, ["each 1 ft or fraction", "= one outlet of 180 VA"], T_NOTE, MUTED, "start", gap=1.6)
    b = f.text(30, 454, "This assembly:", T_NOTE, TEXT, "start", True)
    f.value(b[0] + b[2] + 12, 454, "3 outlets x 180 VA = 540 VA", T_NOTE, anchor="start", pad=5,
            what="the worked load")
    f.tag(f.w - 24, f.h - 14, "NEC 220.14(H)", anchor="end")


def _bar_density_card(f, y):
    f.card(30, y, 740, 70)
    f.text(46, y + 42, "Continuous current limit: copper 1,000 A, aluminum 700 A per sq in", T_NOTE, TEXT, "start")
    f.mask(40, y + 12, 720, 50, what="the density rule")


@figure("busbar_1-5sqin_366-23a", h=430, nec="366.23(A)", records=["final-exam-#3-063"])
def busbar_area(f):
    f.title("Bare copper busbar, 1 1/2 sq in, unventilated enclosure", y=34)
    f.rect(160, 90, 480, 60, fill=ROD, stroke=AMBER, sw=SW_OBJ)
    f.text(400, 186, "cross-section 1 1/2 sq in", T_LABEL, TEXT, bold=True)
    b = f.text(160, 236, "x", 26, TEXT, "start", True)
    f.value(b[0] + b[2] + 10, 236, "1,000 A per sq in", 26, anchor="start", pad=5, what="the copper density")
    b = f.text(160, 282, "=", 26, TEXT, "start", True)
    f.value(b[0] + b[2] + 12, 282, "1,500 A", 28, anchor="start", pad=6)
    _bar_density_card(f, 304)
    f.tag(f.w - 24, f.h - 12, "NEC 366.23(A)", anchor="end")


@figure("busbar_4x-half_366-23a", h=430, nec="366.23(A)", records=["final-exam-#5-039"])
def busbar_wide(f):
    f.title("Copper busbar, 4 in wide by 1/2 in thick", y=34)
    f.rect(160, 90, 480, 60, fill=ROD, stroke=AMBER, sw=SW_OBJ)
    f.ext(160, 154, 160, 176)
    f.ext(640, 154, 640, 176)
    f.dim_h(160, 640, 172)
    f.text(400, 206, "4 in wide x 1/2 in thick", T_NOTE, DIM, bold=True)
    b = f.text(160, 248, "4 x 1/2 =", 26, TEXT, "start")
    f.value(b[0] + b[2] + 12, 248, "2 sq in", 26, anchor="start", pad=5, what="the bar area")
    f.value_lines(160, 288, ["x 1,000 A per sq in = 2,000 A"], T_NOTE, anchor="start", pad=6, what="the working")
    _bar_density_card(f, 304)
    f.tag(f.w - 24, f.h - 12, "NEC 366.23(A)", anchor="end")


def _welder(f, x, y, w=150, h=170, label="welder"):
    """Welding power source, front view: cabinet, louvers, a dial, two output studs."""
    f.rect(x, y, w, h, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=8)
    for k in range(5):
        f.line(x + 18, y + 22 + k * 12, x + w * 0.45, y + 22 + k * 12, EDGE, 3)
    f.circle(x + w * 0.72, y + 48, 22, fill=BG, stroke=TEXT, sw=SW_THIN)
    f.line(x + w * 0.72, y + 48, x + w * 0.72 + 12, y + 36, AMBER, 3)
    for k, c in enumerate((NO, TEXT)):
        f.circle(x + w * 0.3 + k * w * 0.4, y + h - 34, 12, fill=c, stroke=BG, sw=SW_THIN)
    f.rect(x + 10, y + h, 18, 10, fill=EDGE)
    f.rect(x + w - 28, y + h, 18, 10, fill=EDGE)
    f.text(x + w / 2, y + h + 38, label, T_NOTE, TEXT, bold=True)


@figure("arc_welder_ocpd_630-12", h=470, nec="630.12(A)",
        records={"final-exam-#1-025": {}, "open-book-exam-#3-013": {"like": "final-exam-#1-025"}})
def arc_welder(f):
    f.title("Arc welder: overcurrent device for the supply", y=34)
    _welder(f, 50, 90, label="arc welder")
    f.lines(125, 336, ["nameplate", "I1max = 43 A"], T_NOTE, TEXT, bold=True, gap=1.2)
    f.card(250, 70, 520, 350)
    f.text(270, 116, "OCPD not more than", T_NOTE, TEXT, "start")
    f.value(270, 160, "200% x 43 A = 86 A", 26, anchor="start", pad=6, what="the 200% step")
    f.lines(270, 216, ["not a standard rating (240.6(A)):", "the next higher one is permitted"], T_NOTE, MUTED,
            "start", gap=1.2)
    b = f.text(270, 316, "max OCPD =", 26, TEXT, "start")
    f.value(b[0] + b[2] + 12, 316, "90 A", 30, anchor="start", pad=6)
    f.lines(270, 370, ["I1max: rated supply current", "at maximum rated output"], T_MIN, MUTED, "start", gap=1.1)
    f.tag(f.w - 24, f.h - 12, "NEC 630.12(A)", anchor="end")


@figure("resistance_welder_630-31", h=470, nec="630.31(A)(2)", records=["final-exam-#3-040"])
def resistance_welder(f):
    f.title("Resistance welder: supply conductor ampacity", y=34)
    _welder(f, 50, 90, label="resistance welder")
    f.lines(125, 336, ["21 A primary,", "15% duty cycle"], T_NOTE, TEXT, bold=True, gap=1.2)
    f.card(250, 70, 520, 350, "Duty-cycle multipliers")
    rows = [("50%", "0.71"), ("40%", "0.63"), ("30%", "0.55"), ("25%", "0.50"), ("20%", "0.45"),
            ("15%", "0.39"), ("10%", "0.32")]
    for i, (dc, m) in enumerate(rows):
        x = 280 if i < 4 else 520
        y = 140 + (i if i < 4 else i - 4) * 34
        f.text(x, y, dc, T_NOTE, TEXT, "start")
        if dc == "15%":
            f.value(x + 80, y, m, T_NOTE, anchor="start", pad=4, what="the 15% multiplier")
        else:
            f.text(x + 80, y, m, T_NOTE, DIM, "start", True)
    f.mask(270, 116, 480, 140, what="the multiplier table")
    b = f.text(270, 330, "21 A x multiplier =", 26, TEXT, "start")
    f.value(270, 384, "8.19 A", 30, anchor="start", pad=6)
    f.tag(f.w - 24, f.h - 12, "NEC 630.31(A)(2)", anchor="end")


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
        part = hbar * float(pct[:-1]) / 100
        f.rect(x, base - hbar, 70, hbar, fill=PANEL_2)
        f.rect(x, base - part, 70, part, fill=OK, op=0.45)
        f.line(x, base - part, x + 70, base - part, OK, SW_THIN)
        f.rect(x, base - hbar, 70, hbar, stroke=TEXT, sw=SW_THIN)
        f.text(x + 35, base - hbar - 12, f"{a} A", T_NOTE, TEXT, bold=True)
        f.text(x + 35, base + 30, pct, T_NOTE, DIM, bold=True)
        f.text(x + 35, base + 58, f"= {res:g} A", T_MIN, TEXT)
    b = f.text(x0 - 10, base + 104, "bar height: each unit's", T_NOTE, MUTED, "start")
    v = f.value(b[0] + b[2] + 10, base + 104, "momentary", T_NOTE, TEXT, "start", records=None, pad=5,
                what="the rating used")
    f.text(v[0] + v[2] + 16, base + 104, "demand rating", T_NOTE, MUTED, "start")
    f.card(540, 70, 240, 300, "Feeder minimum")
    f.lines(556, 136, ["largest: 50%", "next: 25%", "each other: 10%"], T_NOTE, TEXT, "start", gap=1.4)
    f.line(554, 222, 766, 222, EDGE, 1)
    f.text(556, 260, "100 + 37.5 + 10 + 8", T_NOTE, TEXT, "start")
    f.text(556, 304, "= 155.5 A", 28, OK, "start", True)
    f.text(556, 346, "(example units)", T_MIN, MUTED, "start")
    f.tag(f.w - 24, f.h - 10, "NEC 517.73(B)", anchor="end")


@figure("motor_group_feeder_430-62a", h=500, nec="430.62(A)",
        records=["final-exam-#3-069"])
def motor_group(f):
    f.title("Feeder to three motors (one-line, example values)", y=34)
    f.line(90, 52, 90, 70, WIRE_HOT, SW_WIRE)
    f.breaker(60, 70, 60, 72, poles=3)
    f.text(132, 112, "feeder OCPD", T_NOTE, TEXT, "start", True)
    f.line(90, 142, 90, 190, WIRE_HOT, SW_WIRE)
    f.line(90, 190, 690, 190, WIRE_HOT, SW_WIRE)
    motors = [(250, "40 A", "100 A"), (450, "20 A", "50 A"), (650, "10 A", "25 A")]
    for x, flc, br in motors:
        f.circle(x, 190, 6, fill=WIRE_HOT)
        f.line(x, 190, x, 220, WIRE_HOT, SW_WIRE)
        f.breaker(x - 28, 220, 56, 62, poles=3)
        f.text(x + 40, 260, br, T_NOTE, TEXT, "start", True)
        f.line(x, 282, x, 320, WIRE_HOT, SW_WIRE)
        f.motor_symbol(x, 352, 32)
        f.text(x, 414, "FLC " + flc, T_NOTE, TEXT, bold=True)
    f.text(420, 176, "feeder", T_MIN, MUTED)
    f.text(160, 248, "branch", T_MIN, MUTED, "end")
    f.text(160, 272, "breakers", T_MIN, MUTED, "end")
    f.value_lines(484, 80, ["feeder OCPD <= 100 A (largest branch", "device) + 20 A + 10 A = 130 A"],
                  T_NOTE, TEXT, bold=False, pad=6, gap=1.2, what="the feeder rule")
    f.value(400, 452, "no rounding up to the next size: use 125 A", T_NOTE, MUTED, bold=False, pad=6,
            what="the rounding note")
    f.tag(f.w - 24, f.h - 10, "NEC 430.62(A)", anchor="end")


def _rows(f, x, y, rows, cols, size=T_MIN, step=30, head=None, fill=TEXT):
    """Small table: rows of strings at column x positions; returns the y of each row."""
    ys = []
    if head:
        for cx, s in zip(cols, head):
            f.text(x + cx, y, s, size, MUTED, "start", True)
        f.line(x, y + 9, x + cols[-1] + 60, y + 9, EDGE, 1)
        y += step
    for r in rows:
        for cx, s in zip(cols, r):
            f.text(x + cx, y, s, size, fill, "start", cx == cols[0])
        ys.append(y)
        y += step
    return ys


BOX_DEVICE = ["final-exam-#2-065", "open-book-exam-#11-023"]


@figure("box_fill_steps_314-16", h=540, nec="314.16", when="after",
        records=BOX_DEVICE + ["final-exam-#4-005", "final-exam-#4-011", "final-exam-#4-021", "final-exam-#4-038",
                              "final-exam-#4-054", "final-exam-#4-064"])
def box_fill_steps(f):
    f.title("Box fill: count, multiply, pick the box", y=34)
    f.card(20, 56, 380, 470, "1. Count (314.16(B))")
    ys = _rows(f, 34, 124, [["each conductor entering", "1"], ["all cable clamps together", "1"],
                            ["each device yoke (switch,", "2"], ["  receptacle): largest wire", ""],
                            ["EGCs, up to four", "1"], ["  each EGC past four", "1/4"]],
               [0, 318], T_MIN, 32)
    f.highlight(28, ys[2] - 24, 364, 70, records=BOX_DEVICE)
    f.highlight(28, ys[4] - 24, 364, 70, records=["final-exam-#4-054"])
    f.highlight(28, ys[0] - 24, 364, 200, records=["final-exam-#4-038"])
    f.text(34, 336, "2. x volume per conductor", T_NOTE, TEXT, "start", True)
    ys = _rows(f, 34, 372, [["14", "2.00"], ["12", "2.25"], ["10", "2.50"], ["8", "3.00"]], [0, 90], T_MIN, 30,
               head=["AWG", "cu in"])
    f.highlight(28, 350, 190, 162, records=["final-exam-#4-064"])
    f.lines(250, 400, ["Table", "314.16(B)(1)"], T_MIN, MUTED, "start", gap=1.1)
    f.card(420, 56, 360, 470, "3. Pick the box (Table 314.16(A))")
    f.text(434, 124, "device box 3 x 2 x depth:", T_MIN, TEXT, "start", True)
    ys = _rows(f, 434, 156, [["2 in deep", "10.0"], ["2 1/4 in", "10.5"], ["2 1/2 in", "12.5"], ["2 3/4 in", "14.0"],
                             ["3 1/2 in", "18.0"]], [0, 200], T_MIN, 30)
    f.highlight(428, 104, 344, 186, records=["final-exam-#4-005", "final-exam-#4-011"])
    f.text(434, 324, "4 in octagon x depth:", T_MIN, TEXT, "start", True)
    ys = _rows(f, 434, 356, [["1 1/4 in", "12.5"], ["1 1/2 in", "15.5"], ["2 1/8 in", "21.5"]], [0, 200], T_MIN, 30)
    f.highlight(428, 304, 344, 126, records=["final-exam-#4-021"])
    f.lines(434, 460, ["cu in; the box must be at least", "the total from steps 1 and 2"], T_MIN, MUTED, "start",
            gap=1.1)


def _table_310_16(f, x, y, w, title):
    """Card: three rows of Table 310.16 copper. Returns the y of each row."""
    f.card(x, y, w, 196, title)
    ys = _rows(f, x + 14, y + 64, [["14", "15", "20", "25"], ["12", "20", "25", "30"], ["10", "30", "35", "40"]],
               [0, 90, 180, 270], T_MIN, 30, head=["AWG", "60 C", "75 C", "90 C"])
    f.text(x + 14, y + 184, "TW 60 C, THW 75 C, THHN or RHH 90 C", T_MIN, MUTED, "start")
    return ys


AMBIENT = [["21-25 C", "69-77 F", "1.08", "1.05", "1.04"], ["26-30 C", "78-86 F", "1.00", "1.00", "1.00"],
           ["31-35 C", "87-95 F", "0.91", "0.94", "0.96"], ["36-40 C", "96-104 F", "0.82", "0.88", "0.91"],
           ["41-45 C", "105-113 F", "0.71", "0.82", "0.87"]]


def _ambient_card(f, y, title):
    f.card(20, y, 760, 270, title)
    return _rows(f, 34, y + 64, AMBIENT, [0, 130, 300, 420, 540], T_MIN, 34, head=["ambient", "", "60 C", "75 C", "90 C"])


AMP_14_6 = ["final-exam-#4-024", "final-exam-#4-033"]


@figure("ampacity_steps_310-15c", h=560, nec="Table 310.15(C)(1)", when="after",
        records=AMP_14_6 + ["final-exam-#4-040", "final-exam-#4-063"])
def ampacity_steps(f):
    f.title("Ampacity = table value x ambient factor x count factor", y=34)
    _table_310_16(f, 20, 56, 400, "1. Table 310.16, copper")
    f.card(440, 56, 340, 196, "3. Over 3 conductors")
    ys = _rows(f, 454, 124, [["4 to 6", "80%"], ["7 to 9", "70%"], ["10 to 20", "50%"]], [0, 170], T_NOTE, 34)
    f.text(454, 234, "EGCs are not counted", T_MIN, MUTED, "start")
    f.highlight(446, ys[0] - 24, 328, 34, records=AMP_14_6)
    f.highlight(446, ys[1] - 24, 328, 34, records=["final-exam-#4-040", "final-exam-#4-063"])
    _ambient_card(f, 270, "2. Ambient correction, based on 30 C (86 F)")


@figure("ampacity_ambient_310-15b", h=550, nec="Table 310.15(B)(1)(1)", when="after",
        records=["final-exam-#4-031", "final-exam-#4-035"])
def ampacity_ambient(f):
    f.title("Ampacity = table value x ambient correction factor", y=34)
    _table_310_16(f, 20, 56, 760, "1. Table 310.16, copper")
    ys = _ambient_card(f, 266, "2. Ambient correction, based on 30 C (86 F)")
    for i, recs in ((0, ["final-exam-#4-031"]), (3, ["final-exam-#4-035"])):
        f.highlight(26, ys[i] - 24, 748, 32, records=recs)


@figure("ampacity_table_310-16", h=330, nec="Table 310.16", when="after", records=["final-exam-#4-041"])
def ampacity_table(f):
    f.title("Allowable ampacity, not more than three conductors", y=34)
    ys = _table_310_16(f, 20, 56, 760, "Table 310.16, copper, 30 C (86 F) ambient")
    f.highlight(26, ys[1] - 22, 748, 30)
    f.text(34, 300, "26-30 C (78-86 F) ambient: correction factor 1.00", T_NOTE, TEXT, "start")


NIPPLE = ["final-exam-#4-060", "final-exam-#4-066"]
HOW_MANY = ["final-exam-#4-062", "final-exam-#4-068"]


@figure("conduit_fill_steps_ch9", h=520, nec="Chapter 9 Table 4", when="after",
        records=NIPPLE + HOW_MANY + ["final-exam-#4-022", "final-exam-#4-050", "final-exam-#4-057",
                                     "final-exam-#4-059", "final-exam-#4-065"])
def conduit_fill_steps(f):
    f.title("Conduit fill in three steps (Chapter 9)", y=34)
    cx, cy, r = 130, 190, 90
    f.circle(cx, cy, r, fill=BG, stroke=STEEL, sw=12)
    for dx, dy in ((-36, -30), (0, -46), (36, -30), (-46, 8), (-10, 0), (26, 10), (-30, 44), (8, 44), (44, 46)):
        f.circle(cx + dx, cy + dy, 17, fill=WIRE_NEU, stroke=BG, sw=SW_THIN)
    f.text(cx, 314, "over 2 wires: 40%", T_NOTE, TEXT, bold=True)
    f.lines(cx, 344, ["nipple 24 in or", "shorter: 60%"], T_NOTE, AMBER, bold=True, gap=1.1)
    f.highlight(30, 322, 200, 64, records=NIPPLE)
    x0 = 270
    steps = [("1. Table 5: one conductor's area", ["by type and size (with insulation);", "area x how many = total"]),
             ("2. Table 4: the raceway column", ["pick the raceway type and trade size,", "read its 40% (or 60%) area"]),
             ("3. Compare, or divide", ["total <= allowed area: it fits", "allowed - used = space left",
                                        "allowed / one area = how many", "(same size: .8 or more rounds up)"])]
    y = 76
    boxes = []
    for title, rows in steps:
        h = 44 + len(rows) * 26
        f.card(x0, y, 510, h, title)
        f.lines(x0 + 14, y + 58, rows, T_MIN, TEXT, "start", gap=1.25)
        boxes.append((y, h))
        y += h + 14
    f.highlight(x0 + 4, boxes[0][0] + 4, 502, boxes[0][1] - 8, records=["final-exam-#4-050", "final-exam-#4-057"])
    f.highlight(x0 + 4, boxes[2][0] + 40, 502, 30, records=["final-exam-#4-022"])
    f.highlight(x0 + 4, boxes[2][0] + 66, 502, 28, records=["final-exam-#4-059"])
    f.highlight(x0 + 4, boxes[2][0] + 90, 502, 56, records=NIPPLE + HOW_MANY)
    f.highlight(x0 + 4, boxes[1][0] + 4, 502, boxes[1][1] - 8, records=["final-exam-#4-065"])
    f.lines(30, 414, ["Example: 10 #12 THHN", "in 3/4 EMT", "10 x 0.0133 = 0.133", "40% col. 0.213: fits"],
            T_MIN, MUTED, "start", gap=1.15)


RANGE_B = ["final-exam-#4-023", "final-exam-#4-045", "final-exam-#4-049", "final-exam-#4-051"]


@figure("cooking_demand_220-55", h=480, nec="Table 220.55", when="after",
        records=RANGE_B + ["final-exam-#4-025", "final-exam-#4-036", "final-exam-#4-069"])
def cooking_demand(f):
    f.title("Household cooking appliance demand", y=34)
    f.card(20, 56, 470, 400, "Table 220.55: pick the column by kW")
    f.lines(34, 118, ["under 3 1/2 kW: Column A (%)", "3 1/2 to 8 3/4 kW: Column B (%)",
                      "up to 12 kW: Column C (kW), the default", "over 12 kW: C + 5% per kW over 12 (Note 1)"],
            T_MIN, TEXT, "start", gap=1.15)
    ys = _rows(f, 34, 232, [["1", "80%", "80%", "8"], ["2", "75%", "65%", "11"], ["3", "70%", "55%", "14"],
                            ["8", "53%", "36%", "23"], ["15", "40%", "32%", "30"],
                            ["26-30", "30%", "24%", "15 + 1 each"]],
               [0, 120, 210, 300], T_MIN, 32, head=["how many", "A", "B", "C kW"])
    for i, recs in ((0, ["final-exam-#4-051"]), (1, ["final-exam-#4-025"]), (2, ["final-exam-#4-045"]),
                    (3, ["final-exam-#4-023"]), (4, ["final-exam-#4-049"]), (5, ["final-exam-#4-069"])):
        f.highlight(26, ys[i] - 24, 458, 32, records=recs)
    f.card(510, 56, 270, 400, "Branch circuit (Note 4)")
    f.lines(524, 118, ["one range: the table", "may be used", "", "one wall oven or one", "cooktop: nameplate",
                       "", "cooktop + up to 2 ovens,", "same room, one circuit:", "add them, treat as", "one range"],
            T_MIN, TEXT, "start", gap=1.2)
    f.highlight(516, 172, 258, 60, records=["final-exam-#4-036"])
    f.highlight(516, 96, 258, 54, records=["final-exam-#4-051"])


def _dryer(f, x, y, w=48, h=60):
    """Front-loading clothes dryer, front view: control strip with a knob, round door."""
    f.rect(x, y, w, h, fill=PANEL_2, stroke=TEXT, sw=SW_THIN, rx=4)
    f.line(x + 2, y + h * 0.22, x + w - 2, y + h * 0.22, EDGE, SW_THIN)
    f.circle(x + w * 0.76, y + h * 0.11, h * 0.055, fill=TEXT)
    f.rect(x + w * 0.14, y + h * 0.07, w * 0.36, h * 0.08, fill=BG, rx=1.5)
    f.circle(x + w / 2, y + h * 0.6, w * 0.3, fill=BG, stroke=TEXT, sw=SW_THIN)
    f.circle(x + w / 2, y + h * 0.6, w * 0.2, fill="none", stroke=EDGE, sw=1.5)


@figure("dryer_neutral_220-54", h=420, nec="Table 220.54", when="after", records=["final-exam-#4-046"])
def dryer_neutral(f):
    f.title("Six 4.5 kW household dryers: feeder neutral demand", y=34)
    for k in range(6):
        _dryer(f, 50 + k * 120, 66, 80, 100)
    f.card(20, 196, 760, 200, "Dryers: 5 kW each or the nameplate, whichever is larger")
    f.text(34, 262, "1-4: 100% | 5: 85% | 6: 75% | 7: 65% | 8: 60%", T_NOTE, TEXT, "start", True)
    f.text(34, 310, "6 x 5 kW = 30 kW x 75% = 22.5 kW", T_NOTE, TEXT, "start")
    f.text(34, 356, "feeder neutral: 70% of that demand (220.61(B)(1))", T_NOTE, MUTED, "start")


def _motor_flc_card(f, y, table):
    f.card(20, y, 760, 84, "Start: motor FLC from the table, not the nameplate (430.6(A)(1))")
    f.text(34, y + 66, table, T_MIN, TEXT, "start")


def _motor_pic(f, x, y):
    f.motor(x, y, 120, 80)


@figure("motor_conductor_1ph_430-248", h=330, nec="Table 430.248", when="after", records=["final-exam-#4-026"])
def motor_conductor_1ph(f):
    f.title("Single-phase motor branch-circuit conductors", y=34)
    _motor_flc_card(f, 56, "single-phase motors: Table 430.248")
    _motor_pic(f, 140, 230)
    f.card(300, 160, 480, 140, "Conductors, one motor")
    f.text(314, 230, "ampacity: 125% of the table FLC", T_NOTE, TEXT, "start", True)
    f.text(314, 270, "FLC x 1.25", T_NOTE, MUTED, "start")


@figure("motor_3ph_430-250", h=400, nec="Table 430.250", when="after",
        records=["final-exam-#4-039", "final-exam-#4-070"])
def motor_3ph(f):
    f.title("Three-phase motor: conductors and load", y=34)
    _motor_flc_card(f, 56, "three-phase motors: Table 430.250")
    _motor_pic(f, 140, 260)
    f.card(300, 160, 480, 100, "Conductors, one motor")
    f.text(314, 228, "ampacity: 125% of the table FLC", T_NOTE, TEXT, "start", True)
    f.highlight(306, 166, 468, 88, records=["final-exam-#4-039"])
    f.card(300, 276, 480, 100, "Load in VA")
    f.text(314, 346, "V x FLC x 1.732", T_NOTE, TEXT, "start", True)
    f.highlight(306, 282, 468, 88, records=["final-exam-#4-070"])


@figure("motor_feeder_430-24", h=330, nec="430.24", when="after", records=["final-exam-#4-030"])
def motor_feeder(f):
    f.title("Feeder supplying two motors", y=34)
    _motor_flc_card(f, 56, "single-phase: Table 430.248, three-phase: Table 430.250")
    _motor_pic(f, 100, 230)
    _motor_pic(f, 250, 230)
    f.card(340, 160, 440, 140, "Feeder conductors")
    f.text(354, 230, "125% of the largest FLC", T_NOTE, TEXT, "start", True)
    f.text(354, 270, "+ the FLC of every other motor", T_NOTE, TEXT, "start")


@figure("motor_scpd_430-52", h=440, nec="Table 430.52(C)(1)", when="after",
        records=["final-exam-#4-032", "final-exam-#4-053", "final-exam-#4-061", "final-exam-#4-067"])
def motor_scpd(f):
    f.title("Motor short-circuit and ground-fault device", y=34)
    _motor_flc_card(f, 56, "single-phase: Table 430.248, three-phase: Table 430.250")
    f.card(20, 156, 760, 266, "Maximum rating, percent of FLC")
    ys = _rows(f, 34, 216, [["nontime-delay fuse", "300%", "150%"], ["dual-element fuse", "175%", "150%"],
                            ["inverse time breaker", "250%", "150%"], ["instantaneous breaker", "800%", "800%"]],
               [0, 330, 520], T_NOTE, 36, head=["", "others", "wound rotor"])
    f.text(34, 400, "not a standard size: the next size up is allowed", T_MIN, MUTED, "start")
    f.highlight(26, ys[1] - 26, 748, 36, records=["final-exam-#4-032", "final-exam-#4-053"])
    f.highlight(26, ys[0] - 26, 748, 36, records=["final-exam-#4-061"])
    f.highlight(26, ys[2] - 26, 748, 36, records=["final-exam-#4-067"])


@figure("motor_overload_430-32", h=380, nec="430.32(C)", when="after",
        records=["final-exam-#4-034", "final-exam-#4-037", "final-exam-#4-056"])
def motor_overload(f):
    f.title("Motor running overload protection", y=34)
    f.card(20, 56, 760, 84, "Start: the motor nameplate current (430.6(A)(2))")
    f.text(34, 122, "overloads are sized from the nameplate, not the FLC tables", T_MIN, TEXT, "start")
    _motor_pic(f, 130, 250)
    f.card(270, 156, 510, 200, "Overload relay, maximum")
    f.lines(284, 226, ["SF 1.15 or more, or 40 C rise: 125%", "all others: 115%"], T_NOTE, TEXT, "start", gap=1.3)
    f.lines(284, 300, ["if the motor will not start (430.32(C)):", "140% / 130%"], T_NOTE, MUTED, "start",
            gap=1.3)


def _water_heater(f, x, y, w=60, h=110):
    """Tank water heater, front view: rounded tank, top pipes, access panel."""
    f.rect(x, y, w, h, fill=PANEL_2, stroke=TEXT, sw=SW_THIN, rx=14)
    f.line(x + w * 0.3, y - 14, x + w * 0.3, y, STEEL, 6)
    f.line(x + w * 0.7, y - 14, x + w * 0.7, y, STEEL, 6)
    f.rect(x + w * 0.25, y + h * 0.55, w * 0.5, h * 0.25, fill=BG, stroke=EDGE, sw=1.5, rx=3)


@figure("lighting_load_220-41", h=420, nec="220.41", when="after",
        records=["final-exam-#4-047", "final-exam-#4-048"])
def lighting_load(f):
    f.title("Dwelling general lighting load", y=34)
    f.rect(40, 86, 300, 200, fill=PANEL, stroke=LINE, sw=SW_STRUCT)
    f.text(190, 170, "living area", T_NOTE, TEXT, bold=True)
    for x, y in ((70, 120), (310, 120), (70, 250), (310, 250), (190, 260)):
        f.plan_receptacle(x, y, 10)
    f.text(190, 320, "measured outside", T_MIN, MUTED)
    f.card(370, 60, 410, 300, "General lighting (220.41)")
    f.text(386, 124, "3 VA per sq ft of living area", T_NOTE, TEXT, "start", True)
    f.lines(386, 170, ["general-use receptacles are", "included: no added load"], T_NOTE, TEXT, "start", gap=1.2)
    f.lines(386, 260, ["circuits = VA / 1,800", "(15 A x 120 V), round up"], T_NOTE, TEXT, "start", gap=1.2)
    f.highlight(376, 146, 398, 66, records=["final-exam-#4-048"])
    f.highlight(376, 232, 398, 70, records=["final-exam-#4-047"])


@figure("small_appliance_load_220-52", h=400, nec="220.52", when="after", records=["final-exam-#4-028"])
def small_appliance_load(f):
    f.title("Dwelling small-appliance and laundry loads", y=34)
    f.rect(40, 150, 300, 20, fill=PANEL_2, stroke=LINE, sw=SW_THIN)
    for x in (80, 190, 300):
        f.receptacle(x, 116, 40)
    f.text(190, 206, "kitchen counter", T_NOTE, MUTED)
    f.rect(120, 236, 86, 100, fill=PANEL_2, stroke=TEXT, sw=SW_THIN, rx=4)
    f.circle(163, 296, 26, fill=BG, stroke=TEXT, sw=SW_THIN)
    f.text(163, 366, "laundry", T_NOTE, MUTED)
    f.card(370, 60, 410, 300, "Service load (220.52)")
    f.lines(386, 130, ["1,500 VA per small-appliance", "circuit (at least 2)"], T_NOTE, TEXT, "start", gap=1.2)
    f.text(386, 220, "+ 1,500 VA laundry circuit", T_NOTE, TEXT, "start")
    f.text(386, 300, "2 x 1,500 + 1,500 = 4,500 VA", T_NOTE, OK, "start", True)


@figure("fastened_appliances_220-53", h=400, nec="220.53", when="after", records=["final-exam-#4-042"])
def fastened_appliances(f):
    f.title("Four or more fastened-in-place appliances", y=34)
    for k in range(4):
        _water_heater(f, 50 + k * 76, 140)
    f.text(190, 300, "water heaters, dishwashers ...", T_MIN, MUTED)
    f.card(370, 60, 410, 300, "Service demand (220.53)")
    f.lines(386, 130, ["4 or more on the same", "service or feeder:"], T_NOTE, TEXT, "start", gap=1.2)
    f.text(386, 210, "75% of the nameplate total", T_NOTE, OK, "start", True)
    f.lines(386, 270, ["not ranges, dryers, space", "heating or A/C"], T_NOTE, MUTED, "start", gap=1.2)
