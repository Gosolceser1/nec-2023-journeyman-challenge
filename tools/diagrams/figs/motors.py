"""Motor and A/C circuits: the parts of a motor branch circuit and where the disconnect goes."""
from nec_style import *  # noqa: F401,F403


def _switch(f, x, y, s=40, color=TEXT):
    """One-line disconnect switch between (x, y - s/2) and (x, y + s/2)."""
    f.circle(x, y - s / 2, 5, fill=color)
    f.circle(x, y + s / 2, 5, fill=color)
    f.line(x, y + s / 2, x + s * 0.55, y - s * 0.4, color, SW_OBJ)


def _oneline(f, x):
    """Motor branch circuit one-line, top to bottom: disconnect, fuses, controller, overloads, motor."""
    f.text(x, 66, "feeder", T_NOTE, MUTED)
    f.line(x, 76, x, 110, WIRE_HOT, SW_WIRE)
    _switch(f, x, 130)
    f.line(x, 150, x, 196, WIRE_HOT, SW_WIRE)
    f.rect(x - 12, 196, 24, 50, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=4)
    f.line(x, 196, x, 246, TEXT, 2)
    f.line(x, 246, x, 290, WIRE_HOT, SW_WIRE)
    f.rect(x - 44, 290, 88, 52, fill=PANEL, stroke=TEXT, sw=SW_OBJ, rx=6)
    f.line(x, 290, x, 308, WIRE_HOT, SW_WIRE)
    f.line(x - 18, 308, x + 18, 308, TEXT, SW_OBJ + 1)
    f.line(x - 18, 324, x + 18, 324, TEXT, SW_OBJ + 1)
    f.line(x, 324, x, 342, WIRE_HOT, SW_WIRE)
    f.line(x, 342, x, 376, WIRE_HOT, SW_WIRE)
    f.rect(x - 34, 376, 68, 40, fill=PANEL_2, stroke=AMBER, sw=SW_OBJ, rx=5)
    f.path(f"M {x - 20} 396 q 6 -12 12 0 t 12 0 t 12 0", AMBER, 3)
    f.line(x, 416, x, 450, WIRE_HOT, SW_WIRE)
    f.motor_symbol(x, 486, 36)


@figure("motor_flc_430-250", h=420, nec="Table 430.250",
        records={"final-exam-#1-070": {}, "open-book-exam-#6-010": {"like": "final-exam-#1-070"}},
        keep=[r"^480 V system: 460 V column$"])
def motor_flc(f):
    flc = ["final-exam-#1-070"]
    f.title("Motor full-load current comes from the table", y=34)
    f.motor(170, 170, 180, 100)
    f.rect(20, 260, 340, 76, fill=PANEL, stroke=EDGE, sw=SW_THIN, rx=8)
    f.text(34, 290, "nameplate: 50 hp, 480 V,", T_MIN, TEXT, "start", True)
    f.text(34, 318, "three-phase, wound rotor", T_MIN, TEXT, "start", True)
    f.rect(400, 80, 380, 260, fill=PANEL, stroke=EDGE, sw=SW_THIN, rx=8)
    f.text(414, 116, "Conductor sizing uses the table", T_MIN, TEXT, "start", True)
    f.text(414, 142, "FLC, not the nameplate", T_MIN, TEXT, "start", True)
    f.text(414, 190, "480 V system: 460 V column", T_MIN, MUTED, "start")
    f.text(414, 236, "three-phase table, 50 hp:", T_NOTE, TEXT, "start")
    f.value(414, 286, "65 A", T_VALUE, anchor="start", records=flc, what="table FLC")
    f.tag(f.w - 24, f.h - 12, "NEC Table 430.250", anchor="end")


@figure("motor_disconnect_430-101", h=560, nec="430.101",
        records={"final-exam-#3-009": {"terms": ["motor and controller"]}})
def motor_disconnect(f):
    both = ["final-exam-#3-009"]
    f.title("What the disconnecting means opens", y=34)
    x = 400
    _oneline(f, x)
    lx = 470
    f.text(lx, 138, "disconnecting means", T_NOTE, TEXT, "start", True)
    f.text(lx, 228, "fuses", T_NOTE, TEXT, "start", True)
    f.text(lx, 324, "starter (contactor)", T_NOTE, TEXT, "start", True)
    bx = x - 80
    f.line(bx + 18, 290, bx, 290, AMBER, 3)
    f.line(bx, 290, bx, 522, AMBER, 3)
    f.line(bx, 522, bx + 18, 522, AMBER, 3)
    f.dline(bx, 130, bx + 18, 130, AMBER, 2, 4, 3)
    f.dline(bx, 130, bx, 290, AMBER, 2, 6, 5)
    f.mask(bx - 10, 120, 40, 412, records=both, what="the bracket showing what the disconnect opens")
    f.value_lines(210, 380, ["isolates", "motor and", "controller"], T_NOTE, AMBER, records=both, pad=6,
                  gap=1.15, what="what the disconnect separates from the circuit")
    f.tag(f.w - 24, f.h - 12, "NEC 430.101", anchor="end")


@figure("motor_scgf_430-52", h=560, nec="430.52(B)", records={"final-exam-#3-038": {"terms": ["starting"]}})
def motor_scgf(f):
    start = ["final-exam-#3-038"]
    f.title("Motor branch-circuit short-circuit and ground-fault device", y=34)
    x = 250
    _oneline(f, x)
    lx = 320
    f.text(lx, 138, "disconnecting means", T_NOTE, MUTED, "start")
    f.text(lx, 216, "short-circuit and ground-fault", T_NOTE, TEXT, "start", True)
    f.text(lx, 240, "protective device (fuses)", T_NOTE, TEXT, "start", True)
    b = f.text(lx, 272, "must carry the", T_NOTE, TEXT, "start")
    f.value(b[0] + b[2] + 8, 272, "starting current", T_NOTE, anchor="start", records=start, pad=5)
    f.text(lx, 324, "controller", T_NOTE, MUTED, "start")
    f.text(lx, 494, "motor", T_NOTE, MUTED, "start")
    f.tag(f.w - 24, f.h - 12, "NEC 430.52(B)", anchor="end")


@figure("motor_overloads_430-37", h=470, nec="Table 430.37", records=["final-exam-#3-052"])
def motor_overloads(f):
    ol = ["final-exam-#3-052"]
    f.title("Overload units on a three-phase motor", y=34)
    xs = (240, 340, 440)
    for k, x in enumerate(xs):
        f.text(x, 80, f"L{k + 1}", T_NOTE, TEXT, bold=True)
        f.line(x, 92, x, 190, WIRE_HOT, SW_WIRE)
        f.line(x, 250, x, 330, WIRE_HOT, SW_WIRE)
    for x in xs:
        f.rect(x - 30, 190, 60, 60, fill=PANEL_2, stroke=AMBER, sw=SW_OBJ, rx=5)
        f.path(f"M {x - 18} 220 q 6 -12 12 0 t 12 0 t 12 0", AMBER, 3)
    f.mask(196, 182, 288, 76, records=ol, what="the overload units")
    f.motor_symbol(340, 380, 50)
    f.polyline([(240, 330), (310, 342)], WIRE_HOT, SW_WIRE)
    f.polyline([(440, 330), (370, 342)], WIRE_HOT, SW_WIRE)
    f.text(530, 210, "overload units:", T_NOTE, TEXT, "start", True)
    f.value(530, 250, "three (one per phase)", T_NOTE, anchor="start", records=ol, pad=5,
            what="how many overload units")
    f.tag(f.w - 24, f.h - 12, "NEC Table 430.37", anchor="end")


@figure("motor_in_sight_430-102", h=540, nec="430.102(B)",
        records={"final-exam-#3-019": {}, "final-exam-#2-064": {"when": "after"},
                 "open-book-exam-#11-022": {"when": "after"}, "open-book-exam-#6-009": {"when": "after"}})
def motor_in_sight(f):
    dm = ["final-exam-#3-019"]
    f.title("What must be in sight of the motor and the machine?", y=34)
    fy = 420
    f.floor(fy, 20, 780)
    f.rect(60, 230, 110, 190, fill=PANEL, stroke=TEXT, sw=SW_OBJ, rx=4)
    for k in range(4):
        by = 242 + k * 43
        f.rect(72, by, 86, 35, fill=PANEL_2, stroke=EDGE, sw=SW_THIN, rx=3)
        f.rect(140, by + 8, 9, 19, fill=EDGE, stroke=TEXT, sw=1, rx=2)
    f.lines(115, 196, ["motor control", "center room"], T_MIN, TEXT, bold=True, gap=1.1)
    f.wall(220, 110, fy, 18)
    f.lines(115, 470, ["out of", "sight"], T_MIN, NO, bold=True, gap=1.1)
    f.motor(500, 386, 84, 50)
    f.rect(558, 377, 16, 18, fill=EDGE, stroke=TEXT, sw=1.5, rx=2)
    f.rect(582, 408, 40, 12, fill=STEEL, stroke=TEXT, sw=1.5)
    f.rect(606, 316, 18, 44, fill=STEEL, stroke=TEXT, sw=1.5)
    f.rect(600, 310, 30, 8, fill=STEEL, stroke=TEXT, sw=1.5, rx=2)
    f.circle(602, 384, 28, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ)
    f.circle(602, 384, 9, fill=EDGE, stroke=TEXT, sw=1.5)
    f.lines(500, 450, ["motor"], T_MIN, TEXT, bold=True)
    f.lines(640, 450, ["driven", "machine"], T_MIN, TEXT, bold=True, gap=1.05)
    f.disconnect(320, 236, 48, 64)
    f.line(344, 300, 344, fy, STEEL, 6)
    f.mask(310, 226, 86, 84, records=dm, what="the device in sight")
    f.value_lines(380, 150, ["disconnecting", "means"], T_NOTE, records=dm, pad=6, gap=1.1)
    f.leader(370, 176, 346, 232)
    for tx, ty in ((500, 352), (606, 326)):
        f.dline(388, 276, tx, ty, DIM, 2, 6, 5)
    f.lines(560, 250, ["in sight: visible and", "not more than 50 ft"], T_MIN, DIM, bold=True, gap=1.15)
    f.tag(f.w - 24, f.h - 12, "NEC 430.102(B)", anchor="end")


@figure("ac_disconnect_440-14", h=500, nec="440.14", records=["open-book-exam-#1-025"])
def ac_disconnect(f):
    ra = ["open-book-exam-#1-025"]
    f.title("Disconnect for a rooftop air-conditioning unit", y=34)
    rx0 = 200
    f.line(rx0 - 120, 400, rx0 + 400, 400, LINE, SW_STRUCT)
    f.text(rx0 - 110, 390, "roof", T_NOTE, MUTED, "start")
    f.rect(rx0 + 26, 386, 160, 14, fill=STEEL, stroke=TEXT, sw=1.5)
    f.path(f"M {rx0 + 58} 262 Q {rx0 + 106} 226 {rx0 + 154} 262 Z", TEXT, SW_THIN, fill=PANEL_2)
    for gx in range(rx0 + 74, rx0 + 140, 16):
        f.line(gx, 250, gx, 260, EDGE, 2)
    f.rect(rx0 + 30, 260, 152, 126, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=4)
    for ly in range(276, 374, 10):
        f.line(rx0 + 42, ly, rx0 + 100, ly, EDGE, 2)
    f.rect(rx0 + 112, 276, 58, 96, fill="none", stroke=EDGE, sw=SW_THIN, rx=3)
    f.rect(rx0 + 158, 316, 6, 18, fill=LINE, rx=2)
    f.text(rx0 + 106, 230, "A/C unit", T_NOTE, TEXT, bold=True)
    f.disconnect(rx0 + 232, 300, 40, 54)
    f.line(rx0 + 252, 354, rx0 + 252, 400, STEEL, 6)
    f.polyline([(rx0 + 242, 354), (rx0 + 242, 372), (rx0 + 182, 372)], STEEL, 6)
    f.text(rx0 + 290, 300, "disconnect", T_NOTE, TEXT, "start", True)
    f.text(400, 446, "within sight, and", T_NOTE, TEXT, bold=True)
    f.value(400, 480, "readily accessible", T_NOTE, records=ra, pad=6)
    f.value(400, 120, "(no ladder or obstacles to reach it)", T_MIN, MUTED, bold=False, records=ra, pad=4,
            what="what readily accessible means")
    f.tag(f.w - 24, 64, "NEC 440.14", anchor="end")
