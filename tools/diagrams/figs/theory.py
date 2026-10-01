"""Electrical theory and trade basics: AC cycle, Ohm's law, switching, control, prints."""
import math

from nec_style import *  # noqa: F401,F403


def _resistor_v(f, x, y0, y1, zig=6, amp=16):
    """Vertical zigzag resistor between (x, y0) and (x, y1)."""
    lead = (y1 - y0) * 0.2
    f.line(x, y0, x, y0 + lead, WIRE_HOT, SW_WIRE)
    f.line(x, y1 - lead, x, y1, WIRE_HOT, SW_WIRE)
    a, b = y0 + lead, y1 - lead
    step = (b - a) / (zig * 2)
    pts = [(x, a)]
    for i in range(zig * 2):
        pts.append((x + (amp if i % 2 == 0 else -amp), a + step * (i + 0.5)))
    pts.append((x, b))
    f.polyline(pts, TEXT, SW_OBJ)


def _terminal(f, x, y, r=7):
    f.circle(x, y, r, fill=BG, stroke=TEXT, sw=SW_OBJ)


def _pushbutton(f, x, y, nc=False, half=28):
    """Pushbutton: two terminals, bridging bar above (NO) or below them (NC)."""
    f.line(x - half - 30, y, x - half, y, WIRE_HOT, SW_WIRE)
    f.line(x + half, y, x + half + 30, y, WIRE_HOT, SW_WIRE)
    _terminal(f, x - half, y)
    _terminal(f, x + half, y)
    bar = y + 10 if nc else y - 14
    f.line(x - half - 6, bar, x + half + 6, bar, TEXT, SW_OBJ + 1)
    f.line(x, bar, x, y - 38, TEXT, SW_OBJ)
    f.line(x - 12, y - 38, x + 12, y - 38, TEXT, SW_OBJ + 1)


def _lamp(f, x, y, r=22, label=None):
    """Lamp: circle with an X, the X reaching the circle."""
    f.circle(x, y, r, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ)
    d = r * 0.66
    f.line(x - d, y - d, x + d, y + d, TEXT, SW_OBJ)
    f.line(x - d, y + d, x + d, y - d, TEXT, SW_OBJ)
    if label:
        f.text(x, y - r - 12, label, T_NOTE, TEXT, bold=True)


def _source(f, x, y, label="120 V"):
    """AC source: circle with one sine cycle."""
    f.circle(x, y, 26, fill=PANEL, stroke=TEXT, sw=SW_OBJ)
    f.path(f"M {x - 14} {y} q 7 -14 14 0 t 14 0", TEXT, SW_OBJ)
    f.text(x - 34, y + 8, label, T_NOTE, DIM, "end", True)


def _contact(f, x, y, nc=False, gap=10, h=30):
    f.line(x - gap, y - h / 2, x - gap, y + h / 2, TEXT, SW_OBJ + 1)
    f.line(x + gap, y - h / 2, x + gap, y + h / 2, TEXT, SW_OBJ + 1)
    if nc:
        f.line(x - gap - 10, y + h / 2 + 2, x + gap + 10, y - h / 2 - 2, TEXT, SW_OBJ)


@figure("sine_wave_60hz_quarter_cycle", h=450, nec="General knowledge (AC theory)",
        records={"final-exam-#1-065": {}, "final-exam-#3-045": {"terms": ["frequency", "Hz"]}})
def sine_wave(f):
    x0, x1, cy, amp = 90, 730, 232, 108
    deg = (x1 - x0) / 360
    f.text(410, 50, "1 cycle = 360 degrees = 1/60 s", 28, DIM, bold=True)
    f.dim_h(x0, x1, 70)
    f.line(x0 - 30, cy, x1 + 40, cy, LINE, SW_THIN)
    f.arrow_head(x1 + 46, cy, 1, 0, LINE, 10)
    f.text(772, cy - 14, "time", T_NOTE, MUTED)
    pts = [(x0 + a * deg, cy - amp * math.sin(math.radians(a))) for a in range(0, 361, 3)]
    f.polyline(pts, OK, SW_WIRE + 1)
    for a in (0, 90, 180, 270, 360):
        x = x0 + a * deg
        top = 70 if a in (0, 360) else cy - amp if a == 90 else cy
        f.ext(x, top, x, 368)
        f.line(x, cy - 8, x, cy + 8, TEXT, SW_THIN)
        f.text(x, 400, f"{a} deg", T_LABEL, TEXT, bold=True)
    q = x0 + 90 * deg
    f.dim_h(x0, q, 280)
    f.value((x0 + q) / 2, 322, "1/240 s", 30, records=["final-exam-#1-065"], label="? s")
    f.value_lines(x0 + 270 * deg, 130, ["60 Hz = 60 cycles", "per second (frequency)"], T_NOTE, MUTED,
                  records=["final-exam-#3-045"], pad=6, gap=1.25, what="the name for cycles per second")


@figure("parallel_resistors_equal", h=420, nec="General knowledge (Ohm's law, parallel circuits)",
        records={"final-exam-#3-055": {}, "final-exam-#2-036": {"when": "after"}})
def parallel_resistors(f):
    xt, xr, top, bot = 250, 750, 110, 330
    f.title("Two equal resistors in parallel", y=44)
    f.line(xt, top, xr, top, WIRE_HOT, SW_WIRE)
    f.line(xt, bot, xr, bot, WIRE_HOT, SW_WIRE)
    for x, name in ((400, "R1"), (580, "R2")):
        _resistor_v(f, x, top, bot)
        f.circle(x, top, 5, fill=WIRE_HOT)
        f.circle(x, bot, 5, fill=WIRE_HOT)
        f.text(x + 30, 208, name, T_LABEL, TEXT, "start", True)
        f.text(x + 30, 242, "2,000 ohm", T_LABEL, DIM, "start", True)
    f.line(xr, top, xr, bot, WIRE_HOT, SW_WIRE)
    _terminal(f, xt, top)
    _terminal(f, xt, bot)
    f.ext(xt - 8, top, 196, top)
    f.ext(xt - 8, bot, 196, bot)
    f.dim_v(210, top, bot)
    f.lines(104, 196, ["total", "R_T"], T_NOTE, MUTED, bold=True)
    f.value(104, 262, "1,000 ohm", 26, records=None, label="? ohm")
    f.value(450, 390, "equal resistors: R_T = R / N = 2,000 / 2", T_NOTE, OK, records=None, label="?",
            what="the parallel formula worked through")


@figure("three_way_switch_spdt", h=450, nec="General knowledge (switch types)",
        records={"final-exam-#1-033": {"when": "after"}})
def three_way(f):
    y_hot, y_t1, y_t2, y_n = 230, 170, 290, 390
    c1, t1, t2, c2 = 160, 270, 470, 580
    f.text(30, 216, "hot", T_NOTE, MUTED, "start")
    f.line(30, y_hot, c1, y_hot, WIRE_HOT, SW_WIRE)
    f.text(30, y_n - 14, "neutral", T_NOTE, MUTED, "start")
    # Common on the outside, travelers facing each other.
    for (cx, tx, up) in ((c1, t1, True), (c2, t2, False)):
        f.rect(min(cx, tx) - 30, 130, abs(tx - cx) + 60, 200, fill=PANEL, stroke=EDGE, sw=SW_THIN, rx=8)
        ty = y_t1 if up else y_t2
        f.line(cx, y_hot, tx + (-10 if tx > cx else 10), ty + (6 if up else -6), TEXT, SW_OBJ + 1)
        _terminal(f, cx, y_hot)
        _terminal(f, tx, y_t1)
        _terminal(f, tx, y_t2)
        f.text((cx + tx) / 2, 114, "3-way", T_LABEL, TEXT, bold=True)
        f.text(cx, 362, "common", T_NOTE, TEXT, bold=True)
        f.leader(cx, 340, cx, y_hot + 12)
    for yy in (y_t1, y_t2):
        f.line(t1 + 7, yy, t2 - 7, yy, WIRE_HOT, SW_WIRE)
        f.text((t1 + t2) / 2, yy - 14, "traveler", T_NOTE, MUTED)
    lx, ly, r = 690, 300, 28
    f.polyline([(c2 + 7, y_hot), (lx, y_hot), (lx, ly - r)], WIRE_HOT, SW_WIRE)
    f.polyline([(30, y_n), (lx, y_n), (lx, ly + r)], WIRE_NEU, SW_WIRE)
    _lamp(f, lx, ly, r)
    f.text(lx + r + 12, ly + 8, "lamp", T_NOTE, MUTED, "start")
    f.value(400, 52, "3-way switch = SPDT", 30, records=None)
    f.text(400, 84, "single pole, double throw: 1 common, 2 travelers", T_NOTE, MUTED)


@figure("motor_stop_start_control", h=450, nec="General knowledge (3-wire motor control)",
        records={"final-exam-#1-041": {"when": "after"}})
def motor_control(f):
    l1, l2, y, ys = 50, 750, 190, 300
    for x, name in ((l1, "L1"), (l2, "L2")):
        f.line(x, 110, x, 350, WIRE_HOT, SW_WIRE + 1)
        f.text(x, 98, name, T_LABEL, TEXT, bold=True)
    # Rung: L1 - STOP (NC) - START (NO) - coil M - OL - L2.
    f.line(l1, y, 102, y, WIRE_HOT, SW_WIRE)
    _pushbutton(f, 160, y, nc=True)
    f.line(218, y, 272, y, WIRE_HOT, SW_WIRE)
    _pushbutton(f, 330, y)
    f.line(388, y, 522, y, WIRE_HOT, SW_WIRE)
    f.circle(550, y, 28, fill=PANEL, stroke=TEXT, sw=SW_OBJ + 1)
    f.text(550, y + 9, "M", T_LABEL, TEXT, bold=True)
    f.line(578, y, 640, y, WIRE_HOT, SW_WIRE)
    _contact(f, 660, y, nc=True)
    f.line(680, y, l2, y, WIRE_HOT, SW_WIRE)
    # Seal-in contact across START.
    f.line(250, y, 250, ys, WIRE_HOT, SW_WIRE)
    f.line(410, y, 410, ys, WIRE_HOT, SW_WIRE)
    f.line(250, ys, 320, ys, WIRE_HOT, SW_WIRE)
    f.line(340, ys, 410, ys, WIRE_HOT, SW_WIRE)
    _contact(f, 330, ys)
    for jx in (250, 410):
        f.circle(jx, y, 6, fill=WIRE_HOT)
    f.text(160, 128, "STOP (NC)", T_NOTE, TEXT, bold=True)
    f.text(330, 128, "START (NO)", T_NOTE, TEXT, bold=True)
    f.text(550, 150, "coil", T_NOTE, TEXT, bold=True)
    f.text(660, 150, "OL", T_NOTE, TEXT, bold=True)
    f.text(330, ys + 46, "M seal-in (NO)", T_NOTE, TEXT, bold=True)
    f.text(428, ys + 8, "in parallel with START", T_NOTE, MUTED, "start")
    f.value(400, 408, "STOP is in SERIES with the coil", 30, records=None)
    f.text(400, 440, "opening any stop drops out the coil", T_NOTE, MUTED)


@figure("voltage_drop_percent", h=480, nec="General knowledge (voltage drop), 647.4(D)",
        records=["final-exam-#1-062", "final-exam-#3-044"])
def voltage_drop(f):
    f.panel(60, 120, 110, 170, label="panel")
    f.rect(630, 140, 120, 130, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=8)
    f.text(690, 214, "load", T_LABEL, TEXT, bold=True)
    for yy in (180, 230):
        f.line(170, yy, 630, yy, WIRE_HOT if yy == 180 else WIRE_NEU, SW_WIRE)
    f.text(115, 70, "125 V", 30, DIM, bold=True)
    f.text(115, 100, "at the panel", T_NOTE, MUTED)
    f.text(690, 90, "115 V", 30, DIM, bold=True)
    f.text(690, 120, "at the load", T_NOTE, MUTED)
    f.text(400, 160, "circuit conductors", T_NOTE, MUTED)
    f.text(400, 290, "drop = 125 V - 115 V = 10 V", 28, TEXT, bold=True)
    f.text(400, 340, "percent drop = ?", T_LABEL, MUTED, bold=True)
    f.value(400, 386, "10 V / 125 V = 0.08 = 8%", 30, records=["final-exam-#1-062"], label="?",
            what="the percent worked out (base voltage and result)")
    b = f.text(24, 450, "Sensitive electronics, fixed equipment (647.4(D)): branch", T_MIN, MUTED, "start")
    f.value(b[0] + b[2] + 8, 450, "1.5%, feeder + branch 2.5%", T_MIN, anchor="start",
            records=["final-exam-#3-044"], pad=5, what="the sensitive-electronics limits")


@figure("drawing_scale_quarter_inch", h=420, nec="General knowledge (reading plans)",
        records=["final-exam-#1-063"])
def drawing_scale(f):
    x0, per_in = 100, 160
    x1 = x0 + 3.5 * per_in
    f.rect(40, 84, 720, 316, fill=PANEL, stroke=EDGE, sw=SW_THIN, rx=6)
    f.rect(470, 20, 290, 46, fill=PANEL_2, stroke=LINE, sw=SW_THIN, rx=4)
    f.text(615, 52, "SCALE: 1/4 in = 1 ft", T_LABEL, TEXT, bold=True)
    f.text(60, 52, "plan drawing", T_NOTE, MUTED, "start")
    f.text((x0 + x1) / 2, 128, "real length", T_NOTE, MUTED)
    f.value((x0 + x1) / 2, 170, "3 1/2 x 4 = 14 ft", 30, records=None, label="? ft")
    f.line(x0, 204, x1, 204, TEXT, 10)
    f.line(x0, 188, x0, 220, TEXT, SW_OBJ)
    f.line(x1, 188, x1, 220, TEXT, SW_OBJ)
    f.ext(x0, 222, x0, 256)
    f.ext(x1, 222, x1, 256)
    f.dim_h(x0, x1, 246)
    f.text((x0 + x1) / 2, 284, "3 1/2 in on the drawing", 28, DIM, bold=True)
    ry = 310
    f.rect(x0 - 16, ry, x1 - x0 + 72, 70, fill=PANEL_2, stroke=LINE, sw=SW_THIN, rx=3)
    for k in range(0, 16):
        x = x0 + k * per_in / 4
        if x > x1 + per_in / 4 + 1:
            break
        ln = 30 if k % 4 == 0 else 20 if k % 2 == 0 else 12
        f.line(x, ry, x, ry + ln, TEXT, SW_THIN)
        if k % 4 == 0:
            f.text(x, ry + 60, str(k // 4), T_NOTE, TEXT, bold=True)
    f.text(x1 + 30, ry + 60, "in", T_NOTE, MUTED)


@figure("delta_generator_symbol", h=420, nec="General knowledge (electrical symbols)",
        records={"final-exam-#3-070": {"when": "after"}})
def delta_symbol(f):
    cx, cy, r = 260, 200, 100
    f.circle(cx, cy, r, fill=PANEL, stroke=TEXT, sw=SW_OBJ + 1)
    s = r * 0.72
    tri = [(cx, cy - s), (cx + s * 0.866, cy + s * 0.5), (cx - s * 0.866, cy + s * 0.5)]
    f.poly(tri, "none", OK, SW_OBJ + 2)
    f.mask(cx - r * 0.7, cy - r * 0.78, r * 1.4, r * 1.25, what="the triangle inside the circle")
    f.text(cx, 346, "3-phase delta generator", T_LABEL, TEXT, bold=True)
    f.value(cx, 386, "circle + triangle", 30, records=None)
    wx, wy, wr = 580, 200, 70
    f.circle(wx, wy, wr, fill=PANEL, stroke=MUTED, sw=SW_OBJ)
    k = wr * 0.6
    f.line(wx, wy, wx, wy + k, MUTED, SW_OBJ + 1)
    f.line(wx, wy, wx - k * 0.866, wy - k * 0.5, MUTED, SW_OBJ + 1)
    f.line(wx, wy, wx + k * 0.866, wy - k * 0.5, MUTED, SW_OBJ + 1)
    f.text(wx, 316, "compare: wye (star)", T_NOTE, MUTED, bold=True)
    f.text(wx, 344, "Y inside the circle", T_NOTE, MUTED)


@figure("series_vs_parallel", h=500, nec="General knowledge (series and parallel circuits)", when="after",
        records=["final-exam-#2-013", "final-exam-#2-014", "final-exam-#2-016"])
def series_vs_parallel(f):
    f.title("Series shares the current, parallel shares the voltage", y=34)
    # Series: lamp and heater in one loop.
    f.card(20, 56, 370, 424, "SERIES")
    l, r, t, b = 120, 330, 140, 290
    f.polyline([(l, 190), (l, t), (r, t), (r, b), (l, b), (l, 240)], WIRE_HOT, SW_WIRE)
    _source(f, l, 215)
    _lamp(f, 220, t, label="bulb")
    _resistor_v(f, r, 170, 260)
    f.text(r - 26, 222, "heater", T_NOTE, TEXT, "end", True)
    f.arrow(160, b + 18, 280, b + 18, OK)
    f.text(220, b + 50, "same current", T_NOTE, OK, bold=True)
    f.lines(34, 376, ["voltages add up to 120 V", "60 W bulb -> 25 W bulb:", "more ohms, less current,",
                      "heater puts out less heat"], T_MIN, TEXT, "start", gap=1.15)
    f.highlight(26, 352, 358, 118, records=["final-exam-#2-014"])
    # Parallel: two unequal branches.
    f.card(410, 56, 370, 424, "PARALLEL")
    l, t, b = 504, 140, 290
    f.polyline([(l, 190), (l, t), (680, t)], WIRE_HOT, SW_WIRE)
    f.polyline([(l, 240), (l, b), (680, b)], WIRE_HOT, SW_WIRE)
    _source(f, l, 215)
    for x, name in ((556, "10 ohm"), (680, "30 ohm")):
        _resistor_v(f, x, t, b)
        f.circle(x, t, 5, fill=WIRE_HOT)
        f.circle(x, b, 5, fill=WIRE_HOT)
        f.text(x + 22, 222, name, T_MIN, TEXT, "start", True)
    f.text(620, b + 50, "120 V across each branch", T_NOTE, OK, bold=True)
    f.lines(424, 376, ["each branch = source voltage", "currents differ: 12 A and 4 A",
                       "total current = 16 A"], T_MIN, TEXT, "start", gap=1.15)
    f.highlight(416, b + 24, 358, 36, records=["final-exam-#2-013", "final-exam-#2-016"])


@figure("ac_wave_values_phase", h=500, nec="General knowledge (AC theory)", when="after",
        records=["final-exam-#2-018", "final-exam-#2-034", "final-exam-#2-017", "final-exam-#2-056"])
def ac_wave_values(f):
    f.title("AC values and lead / lag", y=34)
    # One cycle with peak, effective and one alternation.
    x0, x1, cy, amp = 60, 430, 190, 100
    deg = (x1 - x0) / 360
    f.line(x0 - 10, cy, x1 + 20, cy, LINE, SW_THIN)
    f.polyline([(x0 + a * deg, cy - amp * math.sin(math.radians(a))) for a in range(0, 361, 3)], OK, SW_WIRE)
    f.dline(x0, cy - amp, x1, cy - amp, TEXT, SW_THIN, 6, 5)
    f.text(x1 + 6, cy - amp + 6, "peak", T_MIN, TEXT, "start", True)
    f.dline(x0, cy - amp * 0.707, x1, cy - amp * 0.707, DIM, SW_THIN, 6, 5)
    f.lines(x1 + 6, cy - amp * 0.707 + 18, ["effective", "(RMS)"], T_MIN, DIM, "start", True, gap=1.0)
    half = x0 + 180 * deg
    f.dim_h(x0, half, cy + 40)
    f.text((x0 + half) / 2, cy + 72, "1 alternation", T_NOTE, AMBER, bold=True)
    f.text((x0 + half) / 2, cy + 98, "= half a cycle", T_MIN, AMBER)
    f.highlight(x0, cy + 50, 190, 56, records=["final-exam-#2-034"])
    f.lines(560, 110, ["effective = 0.707 x peak", "the value meters read", "and ratings use"], T_MIN, TEXT,
            "start", gap=1.15)
    f.highlight(550, 88, 230, 86, records=["final-exam-#2-018"])
    # Lead and lag.
    y2, a2 = 400, 56
    f.line(x0 - 10, y2, x1 + 20, y2, LINE, SW_THIN)
    f.polyline([(x0 + a * deg, y2 - a2 * math.sin(math.radians(a))) for a in range(0, 361, 3)], WIRE_HOT, SW_WIRE)
    f.polyline([(x0 + a * deg, y2 - a2 * 0.7 * math.sin(math.radians(a - 60))) for a in range(0, 361, 3)],
               AMBER, SW_WIRE)
    f.text(x0 + 90 * deg, y2 - a2 - 12, "E", T_NOTE, WIRE_HOT, bold=True)
    f.text(x0 + 150 * deg + 8, y2 - a2 * 0.7 - 12, "I", T_NOTE, AMBER, "start", True)
    f.lines(520, 330, ["current peaks later:", "current LAGS voltage", "= inductive circuit",
                       "(XL bigger than XC)"], T_MIN, TEXT, "start", gap=1.15)
    f.text(520, 440, "ELI: E leads I in L", T_NOTE, AMBER, "start", True)
    f.text(520, 470, "ICE: I leads E in C", T_MIN, MUTED, "start")
    f.highlight(510, 308, 270, 144, records=["final-exam-#2-017", "final-exam-#2-056"])


@figure("transformer_turns_ratio", h=450, nec="General knowledge (transformers)", when="after",
        records=["final-exam-#2-012", "final-exam-#2-015"])
def transformer_turns(f):
    f.title("Turns ratio sets the voltage ratio", y=34)
    core_x0, core_x1, top, bot = 250, 550, 90, 330
    f.rect(core_x0 - 11, top - 11, core_x1 - core_x0 + 22, bot - top + 22, fill=STEEL, stroke=LINE, sw=SW_THIN)
    f.rect(core_x0 + 11, top + 11, core_x1 - core_x0 - 22, bot - top - 22, fill=BG, stroke=LINE, sw=SW_THIN)
    for k in range(10):
        y = top + 24 + k * 20
        f.path(f"M {core_x0 - 26} {y} q 26 -10 52 0", AMBER, SW_OBJ)
    for k in range(2):
        y = top + 100 + k * 36
        f.path(f"M {core_x1 - 26} {y} q 26 -10 52 0", OK, SW_OBJ)
    f.line(120, top + 24, core_x0 - 26, top + 24, AMBER, SW_WIRE)
    f.line(120, top + 204, core_x0 - 26, top + 204, AMBER, SW_WIRE)
    f.line(core_x1 + 26, top + 100, 680, top + 100, OK, SW_WIRE)
    f.line(core_x1 + 26, top + 136, 680, top + 136, OK, SW_WIRE)
    f.lines(104, top - 16, ["primary", "many turns"], T_NOTE, AMBER, "start", True, gap=1.0)
    f.text(120, bot + 34, "2,400 V in", T_LABEL, AMBER, "start", True)
    f.lines(600, top + 30, ["secondary", "fewer turns"], T_NOTE, OK, "start", True, gap=1.0)
    f.text(600, bot + 34, "120 V out", T_LABEL, OK, "start", True)
    f.rect(90, 384, 620, 52, fill=PANEL, stroke=EDGE, sw=SW_THIN, rx=8)
    f.text(400, 418, "20:1 = 20 primary turns per secondary turn = 1/20 the voltage", T_MIN, TEXT, bold=True)
    f.text(400, 212, "step-down", T_NOTE, TEXT, bold=True)
    f.highlight(86, 380, 628, 60, records=["final-exam-#2-012"])
    f.highlight(94, 50, 170, 70, records=["final-exam-#2-015"])


@figure("resistance_factors", h=460, nec="General knowledge (conductor resistance)", when="after",
        records=["final-exam-#2-019", "final-exam-#2-055"])
def resistance_factors(f):
    f.title("What sets a conductor's resistance", y=34)
    f.rect(40, 90, 200, 30, fill=ROD, stroke=AMBER, sw=SW_THIN, rx=6)
    f.text(250, 112, "5 ohm", T_LABEL, TEXT, "start", True)
    f.text(40, 76, "original wire", T_MIN, MUTED, "start")
    f.rect(40, 186, 600, 15, fill=ROD, stroke=AMBER, sw=SW_THIN, rx=4)
    f.text(40, 172, "3 x as long, half the area", T_MIN, MUTED, "start")
    f.text(650, 200, "?", T_LABEL, TEXT, "start", True)
    f.lines(40, 250, ["length x 3 -> ohms x 3", "area x 1/2 -> ohms x 2", "5 x 3 x 2 = 30 ohm"], T_NOTE, TEXT,
            "start", gap=1.25)
    f.highlight(30, 226, 300, 96, records=["final-exam-#2-019"])
    f.card(400, 230, 380, 210, "Changes resistance:", title_fill=OK)
    f.lines(414, 292, ["length, cross-section area", "(diameter), material,", "temperature"], T_MIN, TEXT,
            "start", gap=1.15)
    f.text(414, 384, "Does not:", T_NOTE, NO, "start", True)
    f.text(414, 414, "the insulation around it", T_MIN, TEXT, "start")
    f.highlight(406, 362, 368, 66, records=["final-exam-#2-055"])
