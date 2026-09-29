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
        records=["final-exam-#3-055"])
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
    f.text(30, 206, "hot", T_NOTE, MUTED, "start")
    f.line(30, y_hot, 180, y_hot, WIRE_HOT, SW_WIRE)
    f.text(30, y_n - 12, "neutral", T_NOTE, MUTED, "start")
    f.line(30, y_n, 700, y_n, WIRE_NEU, SW_WIRE)
    # Switch 1: common on the left, travelers on the right.
    for (cx, tx, up) in ((180, 290, True), (620, 510, False)):
        f.rect(min(cx, tx) - 30, 130, abs(tx - cx) + 60, 200, fill=PANEL, stroke=EDGE, sw=SW_THIN, rx=8)
        _terminal(f, cx, y_hot)
        _terminal(f, tx, y_t1)
        _terminal(f, tx, y_t2)
        ty = y_t1 if up else y_t2
        f.line(cx, y_hot, tx + (-10 if tx > cx else 10), ty + (6 if up else -6), TEXT, SW_OBJ + 2)
    f.line(290, y_t1, 510, y_t1, WIRE_HOT, SW_WIRE)
    f.line(290, y_t2, 510, y_t2, WIRE_HOT, SW_WIRE)
    f.text(400, y_t1 - 14, "traveler", T_NOTE, MUTED)
    f.text(400, y_t2 - 14, "traveler", T_NOTE, MUTED)
    f.text(180, 360, "common", T_NOTE, TEXT, bold=True)
    f.text(620, 360, "common", T_NOTE, TEXT, bold=True)
    f.leader(180, 340, 180, y_hot + 12)
    f.leader(620, 340, 620, y_hot + 12)
    f.line(620, y_hot, 720, y_hot, WIRE_HOT, SW_WIRE)
    f.line(720, y_hot, 720, y_hot + 40, WIRE_HOT, SW_WIRE)
    lx, ly, r = 720, y_hot + 70, 30
    f.circle(lx, ly, r, fill=BG, stroke=TEXT, sw=SW_OBJ)
    d = r * 0.7
    f.line(lx - d, ly - d, lx + d, ly + d, TEXT, SW_OBJ)
    f.line(lx - d, ly + d, lx + d, ly - d, TEXT, SW_OBJ)
    f.line(lx, ly + r, lx, y_n, WIRE_NEU, SW_WIRE)
    f.line(700, y_n, lx, y_n, WIRE_NEU, SW_WIRE)
    f.text(lx, y_hot - 14, "lamp", T_NOTE, MUTED)
    f.text(235, 114, "3-way", T_LABEL, TEXT, bold=True)
    f.text(565, 114, "3-way", T_LABEL, TEXT, bold=True)
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
    f.text(160, 128, "STOP (NC)", T_NOTE, TEXT, bold=True)
    f.text(330, 128, "START (NO)", T_NOTE, TEXT, bold=True)
    f.text(550, 150, "coil", T_NOTE, MUTED)
    f.text(660, 150, "OL", T_NOTE, MUTED)
    f.text(330, ys + 46, "M seal-in (NO)", T_NOTE, TEXT, bold=True)
    f.text(560, ys + 6, "parallel with START", T_NOTE, MUTED)
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
