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
        records={"final-exam-#1-010": {}, "open-book-exam-#2-018": {"like": "final-exam-#1-010"}})
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
        records={"final-exam-#1-025": {}, "final-exam-#3-040": {},
                 "open-book-exam-#3-013": {"like": "final-exam-#1-025"}})
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


@figure("box_fill_steps_314-16", h=540, nec="314.16(A), 314.16(B), Table 314.16(A), Table 314.16(B)(1)",
        when="after",
        records=BOX_DEVICE + ["final-exam-#4-005", "final-exam-#4-011", "final-exam-#4-021", "final-exam-#4-038",
                              "final-exam-#4-054", "final-exam-#4-064"])
def box_fill_steps(f):
    f.title("Box fill: count, multiply, pick the box", y=34)
    _card(f, 20, 56, 380, 470, "1. Count (314.16(B))")
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
    _card(f, 420, 56, 360, 470, "3. Pick the box (Table 314.16(A))")
    f.text(434, 124, "device box 3 x 2 x depth:", T_MIN, TEXT, "start", True)
    ys = _rows(f, 434, 156, [["2 in deep", "10.0"], ["2 1/4 in", "10.5"], ["2 1/2 in", "12.5"], ["2 3/4 in", "14.0"],
                             ["3 1/2 in", "18.0"]], [0, 200], T_MIN, 30)
    f.highlight(428, 104, 344, 186, records=["final-exam-#4-005", "final-exam-#4-011"])
    f.text(434, 324, "4 in octagon x depth:", T_MIN, TEXT, "start", True)
    ys = _rows(f, 434, 356, [["1 1/4 in", "12.5"], ["1 1/2 in", "15.5"], ["2 1/8 in", "21.5"]], [0, 200], T_MIN, 30)
    f.highlight(428, 304, 344, 126, records=["final-exam-#4-021"])
    f.lines(434, 460, ["cu in; the box must be at least", "the total from steps 1 and 2"], T_MIN, MUTED, "start",
            gap=1.1)


AMP_14_6 = ["final-exam-#4-024", "final-exam-#4-033"]


@figure("ampacity_steps_310-15", h=560, nec="Table 310.16, Table 310.15(B)(1)(1), Table 310.15(C)(1)", when="after",
        records=AMP_14_6 + ["final-exam-#4-031", "final-exam-#4-035", "final-exam-#4-040", "final-exam-#4-041",
                            "final-exam-#4-063"])
def ampacity_steps(f):
    f.title("Ampacity = table value x ambient factor x count factor", y=34)
    _card(f, 20, 56, 400, 196, "1. Table 310.16, copper")
    cols = [0, 90, 180, 270]
    ys = _rows(f, 34, 120, [["14", "15", "20", "25"], ["12", "20", "25", "30"], ["10", "30", "35", "40"]], cols,
               T_MIN, 30, head=["AWG", "60 C", "75 C", "90 C"])
    f.text(34, 240, "TW 60 C, THW 75 C, THHN or RHH 90 C", T_MIN, MUTED, "start")
    f.highlight(26, ys[1] - 22, 388, 30, records=["final-exam-#4-041"])
    _card(f, 440, 56, 340, 196, "3. Over 3 conductors")
    ys = _rows(f, 454, 124, [["4 to 6", "80%"], ["7 to 9", "70%"], ["10 to 20", "50%"]], [0, 170], T_NOTE, 34)
    f.text(454, 234, "EGCs are not counted", T_MIN, MUTED, "start")
    f.highlight(446, ys[0] - 24, 328, 34, records=AMP_14_6)
    f.highlight(446, ys[1] - 24, 328, 34, records=["final-exam-#4-040", "final-exam-#4-063"])
    _card(f, 20, 270, 760, 270, "2. Ambient correction, based on 30 C (86 F)")
    cols = [0, 130, 300, 420, 540]
    ys = _rows(f, 34, 334, [["21-25 C", "69-77 F", "1.08", "1.05", "1.04"], ["26-30 C", "78-86 F", "1.00", "1.00", "1.00"],
                            ["31-35 C", "87-95 F", "0.91", "0.94", "0.96"], ["36-40 C", "96-104 F", "0.82", "0.88", "0.91"],
                            ["41-45 C", "105-113 F", "0.71", "0.82", "0.87"]], cols, T_MIN, 34,
               head=["ambient", "", "60 C", "75 C", "90 C"])
    for i, recs in ((0, ["final-exam-#4-031"]), (3, ["final-exam-#4-035"])):
        f.highlight(26, ys[i] - 24, 748, 32, records=recs)


NIPPLE = ["final-exam-#4-060", "final-exam-#4-066"]
HOW_MANY = ["final-exam-#4-062", "final-exam-#4-068"]


@figure("conduit_fill_steps_ch9", h=520, nec="Chapter 9 Table 1, Notes 4 and 7, Table 4, Table 5", when="after",
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
        _card(f, x0, y, 510, h, title)
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


@figure("cooking_dryer_demand_220-54_220-55", h=540, nec="Table 220.54, Table 220.55 and Notes 1-4, 220.61(B)(1)",
        when="after",
        records=RANGE_B + ["final-exam-#4-025", "final-exam-#4-036", "final-exam-#4-046", "final-exam-#4-069"])
def cooking_dryer_demand(f):
    f.title("Household cooking and dryer demand", y=34)
    _card(f, 20, 56, 470, 316, "Table 220.55: pick the column by kW")
    f.lines(34, 112, ["under 3 1/2 kW: Column A (%)", "3 1/2 to 8 3/4 kW: Column B (%)",
                      "up to 12 kW: Column C (kW), the default", "over 12 kW: C + 5% per kW over 12 (Note 1)"],
            T_MIN, TEXT, "start", gap=1.15)
    ys = _rows(f, 34, 214, [["1", "80%", "80%", "8"], ["2", "75%", "65%", "11"], ["3", "70%", "55%", "14"],
                            ["8", "53%", "36%", "23"], ["15", "40%", "32%", "30"],
                            ["26-30", "30%", "24%", "15 + 1 each"]],
               [0, 120, 210, 300], T_MIN, 24, head=["how many", "A", "B", "C kW"])
    for i, recs in ((0, ["final-exam-#4-051"]), (1, ["final-exam-#4-025"]), (2, ["final-exam-#4-045"]),
                    (3, ["final-exam-#4-023"]), (4, ["final-exam-#4-049"]), (5, ["final-exam-#4-069"])):
        f.highlight(26, ys[i] - 19, 458, 24, records=recs)
    _card(f, 510, 56, 270, 316, "Branch circuit (Note 4)")
    f.lines(524, 118, ["one range: the table", "may be used", "", "one wall oven or one", "cooktop: nameplate",
                       "", "cooktop + up to 2 ovens,", "same room, one circuit:", "add them, treat as", "one range"],
            T_MIN, TEXT, "start", gap=1.2)
    f.highlight(516, 172, 258, 60, records=["final-exam-#4-036"])
    f.highlight(516, 96, 258, 54, records=["final-exam-#4-051"])
    _card(f, 20, 386, 760, 140, "Dryers (220.54): 5 kW or the nameplate, whichever is larger")
    f.text(34, 450, "1-4: 100% | 5: 85% | 6: 75% | 7: 65% | 8: 60%", T_NOTE, TEXT, "start", True)
    f.text(34, 494, "feeder neutral: 70% of the dryer and range demand (220.61(B)(1))", T_MIN, MUTED, "start")
    f.highlight(26, 424, 748, 96, records=["final-exam-#4-046"])


MOTOR_BC = ["final-exam-#4-026", "final-exam-#4-039"]
MOTOR_OL = ["final-exam-#4-034", "final-exam-#4-037", "final-exam-#4-056"]
MOTOR_SC = ["final-exam-#4-032", "final-exam-#4-053", "final-exam-#4-061", "final-exam-#4-067"]


@figure("motor_percentages_430", h=560, nec="430.6(A)(1), 430.22, 430.24, 430.32, Table 430.52(C)(1), Tables 430.248 and 430.250",
        when="after", records=MOTOR_BC + MOTOR_OL + MOTOR_SC + ["final-exam-#4-030", "final-exam-#4-070"])
def motor_percentages(f):
    f.title("Motor circuits by the percentages (Article 430)", y=34)
    _card(f, 20, 56, 760, 84, "Start: FLC from the tables, not the nameplate (430.6(A)(1))")
    f.text(34, 122, "single-phase: Table 430.248, three-phase: Table 430.250", T_MIN, TEXT, "start")
    _card(f, 20, 152, 370, 110, "Conductors")
    f.text(34, 214, "one motor: 125% of FLC", T_MIN, TEXT, "start")
    f.text(34, 244, "feeder: 125% of largest + rest", T_MIN, TEXT, "start")
    f.highlight(26, 194, 358, 28, records=MOTOR_BC)
    f.highlight(26, 224, 358, 30, records=["final-exam-#4-030"])
    _card(f, 410, 152, 370, 110, "3-phase VA")
    f.text(424, 214, "V x FLC x 1.732", T_NOTE, TEXT, "start", True)
    f.text(424, 244, "(single-phase: V x FLC)", T_MIN, MUTED, "start")
    f.highlight(416, 190, 358, 32, records=["final-exam-#4-070"])
    _card(f, 20, 274, 470, 266, "Short-circuit device, max % of FLC")
    ys = _rows(f, 34, 334, [["nontime-delay fuse", "300%", "150%"], ["dual-element fuse", "175%", "150%"],
                            ["inverse time breaker", "250%", "150%"], ["instantaneous breaker", "800%", "800%"]],
               [0, 230, 330], T_MIN, 32, head=["", "others", "wound rotor"])
    f.text(34, 500, "not a standard size: next size up allowed", T_MIN, MUTED, "start")
    f.text(34, 526, "Table 430.52(C)(1)", T_MIN, MUTED, "start")
    f.highlight(26, ys[1] - 22, 458, 30, records=["final-exam-#4-032", "final-exam-#4-053"])
    f.highlight(26, ys[0] - 22, 458, 30, records=["final-exam-#4-061"])
    f.highlight(26, ys[2] - 22, 458, 30, records=["final-exam-#4-067"])
    _card(f, 510, 274, 270, 266, "Overloads (430.32)")
    f.lines(524, 334, ["SF 1.15+ or 40 C rise:", "125%, others 115%"], T_MIN, TEXT, "start", gap=1.2)
    f.lines(524, 414, ["if the motor will not", "start (430.32(C)), max:", "SF 1.15+ or 40 C: 140%",
                       "others: 130%"], T_MIN, TEXT, "start", gap=1.2)
    f.highlight(516, 390, 258, 140, records=MOTOR_OL)


@figure("dwelling_loads_220-41_220-53", h=500, nec="220.5(C), 220.41, 220.52, 220.53", when="after",
        records=["final-exam-#4-027", "final-exam-#4-028", "final-exam-#4-047", "final-exam-#4-048",
                 "final-exam-#4-042"])
def dwelling_loads(f):
    f.title("Dwelling loads: lighting, small appliance, appliances", y=34)
    f.rect(40, 86, 240, 150, fill=PANEL, stroke=LINE, sw=SW_STRUCT)
    f.rect(280, 150, 90, 86, fill="none", stroke=EDGE, sw=SW_THIN)
    f.text(160, 170, "living area", T_NOTE, TEXT, bold=True)
    f.lines(325, 186, ["open", "porch"], T_MIN, MUTED, gap=1.0)
    f.text(160, 270, "measured outside", T_MIN, MUTED)
    f.text(325, 270, "not counted", T_MIN, MUTED)
    _card(f, 400, 56, 380, 200, "General lighting (220.41)")
    f.text(414, 118, "3 VA per sq ft of living area", T_MIN, TEXT, "start", True)
    f.lines(414, 150, ["general-use receptacles are", "included: no added load"], T_MIN, TEXT, "start", gap=1.15)
    f.lines(414, 212, ["circuits = VA / 1,800 (15 A x 120 V),", "round up"], T_MIN, TEXT, "start", gap=1.15)
    f.highlight(406, 96, 368, 32, records=["final-exam-#4-027"])
    f.highlight(406, 128, 368, 50, records=["final-exam-#4-048"])
    f.highlight(406, 190, 368, 56, records=["final-exam-#4-047"])
    _card(f, 20, 296, 370, 180, "Small appliance, laundry (220.52)")
    f.lines(34, 360, ["1,500 VA per small-appliance", "circuit (at least 2)", "+ 1,500 VA laundry circuit"],
            T_MIN, TEXT, "start", gap=1.2)
    f.highlight(26, 336, 358, 96, records=["final-exam-#4-028"])
    _card(f, 410, 296, 370, 180, "Fastened in place (220.53)")
    f.lines(424, 360, ["4 or more (water heaters,", "dishwashers...): 75% of", "the nameplates",
                       "not ranges, dryers, heat, A/C"], T_MIN, TEXT, "start", gap=1.2)
    f.highlight(416, 336, 358, 130, records=["final-exam-#4-042"])
