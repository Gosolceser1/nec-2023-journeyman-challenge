"""Motor and A/C circuits: the parts of a motor branch circuit and where the disconnect goes."""
from nec_style import *  # noqa: F401,F403


def _switch(f, x, y, s=40, color=TEXT):
    """One-line disconnect switch between (x, y - s/2) and (x, y + s/2)."""
    f.circle(x, y - s / 2, 5, fill=color)
    f.circle(x, y + s / 2, 5, fill=color)
    f.line(x, y + s / 2, x + s * 0.55, y - s * 0.4, color, SW_OBJ)


@figure("motor_circuit_430", h=640, nec="430.6(A)(1), Table 430.250, 430.52(B), Table 430.37, 430.101",
        records={"final-exam-#1-070": {}, "final-exam-#3-009": {"terms": ["motor and controller"]},
                 "final-exam-#3-038": {"terms": ["starting"]}, "final-exam-#3-052": {},
                 "open-book-exam-#6-010": {"like": "final-exam-#1-070"}})
def motor_circuit(f):
    flc = ["final-exam-#1-070"]
    both = ["final-exam-#3-009"]
    start = ["final-exam-#3-038"]
    ol = ["final-exam-#3-052"]
    f.title("Motor branch circuit, one-line (top to bottom)", y=34)
    x = 250
    f.text(x, 66, "feeder", T_NOTE, MUTED)
    f.line(x, 76, x, 110, WIRE_HOT, SW_WIRE)
    _switch(f, x, 130)
    f.line(x, 150, x, 196, WIRE_HOT, SW_WIRE)
    f.rect(x - 12, 196, 24, 50, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=4)
    f.line(x, 196, x, 246, TEXT, 2)
    f.line(x, 246, x, 290, WIRE_HOT, SW_WIRE)
    # Controller: a box around a normally open contactor contact.
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
    # Labels on the right.
    lx = 320
    f.text(lx, 138, "disconnecting means", T_NOTE, TEXT, "start", True)
    f.text(lx, 216, "short-circuit and ground-fault", T_NOTE, TEXT, "start", True)
    f.text(lx, 240, "protective device (fuses)", T_NOTE, TEXT, "start", True)
    b = f.text(lx, 268, "must carry the", T_MIN, MUTED, "start")
    f.value(b[0] + b[2] + 8, 268, "starting current", T_MIN, anchor="start", records=start, pad=5)
    f.text(lx, 324, "controller (starts, stops)", T_NOTE, TEXT, "start", True)
    f.text(lx, 402, "overload units:", T_NOTE, TEXT, "start", True)
    f.value(lx + 170, 402, "three (one per phase)", T_NOTE, anchor="start", records=ol, pad=5,
            what="how many overload units")
    f.mask(x - 40, 370, 80, 52, records=ol, what="the overload block")
    f.text(lx, 494, "motor", T_NOTE, TEXT, "start", True)
    # Bracket: what the disconnect opens.
    f.line(196, 290, 180, 290, AMBER, 3)
    f.line(180, 290, 180, 522, AMBER, 3)
    f.line(180, 522, 196, 522, AMBER, 3)
    f.line(180, 130, 226, 130, AMBER, 2)
    f.line(180, 130, 180, 290, AMBER, 2)
    f.mask(168, 120, 62, 412, records=both, what="the bracket showing what the disconnect opens")
    f.value_lines(92, 380, ["isolates", "motor and", "controller"], T_NOTE, AMBER, records=both, pad=6,
                  gap=1.15, what="what the disconnect separates from the circuit")
    # Nameplate and the table.
    f.rect(20, 552, 340, 72, fill=PANEL, stroke=EDGE, sw=SW_THIN, rx=8)
    f.text(34, 580, "nameplate: 50 hp, 460 V,", T_MIN, TEXT, "start", True)
    f.text(34, 606, "three-phase, wound rotor", T_MIN, TEXT, "start", True)
    f.rect(400, 440, 380, 184, fill=PANEL, stroke=EDGE, sw=SW_THIN, rx=8)
    f.text(414, 470, "Conductor sizing uses the table FLC,", T_MIN, TEXT, "start", True)
    f.text(414, 494, "not the nameplate (430.6(A)(1))", T_MIN, TEXT, "start", True)
    f.text(414, 530, "480 V system: 460 V column", T_MIN, MUTED, "start")
    f.text(414, 562, "Table 430.250, 50 hp:", T_NOTE, TEXT, "start")
    f.value(414, 600, "65 A", 28, anchor="start", records=flc, what="table FLC")
    f.tag(f.w - 24, 64, "NEC 430", anchor="end")


@figure("in_sight_disconnect_430-102_440-14", h=560, nec="430.102(B)(1), 440.14, Article 100 (In Sight From)",
        records={"final-exam-#3-019": {}, "open-book-exam-#1-025": {},
                 "final-exam-#2-064": {"when": "after"}, "open-book-exam-#11-022": {"when": "after"},
                 "open-book-exam-#6-009": {"when": "after"}})
def in_sight_disconnect(f):
    dm = ["final-exam-#3-019"]
    ra = ["open-book-exam-#1-025"]
    f.title("What must be in sight of the motor and the machine?", y=34)
    fy = 420
    f.floor(fy, 20, 480)
    # Controller in an MCC room, behind a wall: buckets with operating handles.
    f.rect(30, 230, 90, 190, fill=PANEL, stroke=TEXT, sw=SW_OBJ, rx=4)
    for k in range(4):
        by = 242 + k * 43
        f.rect(40, by, 70, 35, fill=PANEL_2, stroke=EDGE, sw=SW_THIN, rx=3)
        f.rect(94, by + 8, 9, 19, fill=EDGE, stroke=TEXT, sw=1, rx=2)
    f.lines(75, 200, ["controller", "(MCC room)"], T_MIN, TEXT, bold=True, gap=1.1)
    f.wall(150, 110, fy, 18)
    # Motor coupled to a pump (the driven machine).
    f.motor(330, 386, 84, 50)
    f.rect(388, 377, 16, 18, fill=EDGE, stroke=TEXT, sw=1.5, rx=2)
    f.rect(412, 408, 40, 12, fill=STEEL, stroke=TEXT, sw=1.5)
    f.rect(436, 316, 18, 44, fill=STEEL, stroke=TEXT, sw=1.5)
    f.rect(430, 310, 30, 8, fill=STEEL, stroke=TEXT, sw=1.5, rx=2)
    f.circle(432, 384, 28, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ)
    f.circle(432, 384, 9, fill=EDGE, stroke=TEXT, sw=1.5)
    f.lines(434, 450, ["driven", "machine"], T_MIN, TEXT, bold=True, gap=1.05)
    # The device on a stand near the motor.
    f.disconnect(200, 236, 48, 64)
    f.line(224, 300, 224, fy, STEEL, 6)
    f.mask(190, 226, 86, 84, records=dm, what="the device in sight")
    f.value_lines(248, 150, ["disconnecting", "means"], T_NOTE, records=dm, pad=6, gap=1.1)
    f.leader(240, 176, 226, 232)
    for tx, ty in ((330, 352), (436, 326)):
        f.dline(268, 276, tx, ty, DIM, 2, 6, 5)
    f.lines(250, 490, ["in sight: visible and", "not more than 50 ft"], T_MIN, DIM, bold=True, gap=1.15)
    f.lines(75, 470, ["out of", "sight"], T_MIN, NO, bold=True, gap=1.1)
    # Rooftop packaged A/C unit on its curb, with the disconnect on a stand beside it.
    rx0 = 500
    f.rect(rx0, 56, 280, 480, fill=PANEL, stroke=EDGE, sw=SW_THIN, rx=8)
    f.text(rx0 + 140, 86, "rooftop A/C", T_NOTE, TEXT, bold=True)
    f.line(rx0 + 16, 400, rx0 + 264, 400, LINE, SW_STRUCT)
    f.rect(rx0 + 26, 386, 160, 14, fill=STEEL, stroke=TEXT, sw=1.5)
    f.path(f"M {rx0 + 58} 262 Q {rx0 + 106} 226 {rx0 + 154} 262 Z", TEXT, SW_THIN, fill=PANEL_2)
    for gx in range(rx0 + 74, rx0 + 140, 16):
        f.line(gx, 250, gx, 260, EDGE, 2)
    f.rect(rx0 + 30, 260, 152, 126, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=4)
    for ly in range(276, 374, 10):
        f.line(rx0 + 42, ly, rx0 + 100, ly, EDGE, 2)
    f.rect(rx0 + 112, 276, 58, 96, fill="none", stroke=EDGE, sw=SW_THIN, rx=3)
    f.rect(rx0 + 158, 316, 6, 18, fill=LINE, rx=2)
    f.disconnect(rx0 + 202, 300, 40, 54)
    f.line(rx0 + 222, 354, rx0 + 222, 400, STEEL, 6)
    f.polyline([(rx0 + 212, 354), (rx0 + 212, 372), (rx0 + 182, 372)], STEEL, 6)
    f.mask(rx0 + 192, 290, 72, 74, records=dm, what="the device at the unit")
    f.value_lines(rx0 + 140, 140, ["disconnecting", "means"], T_NOTE, records=dm, pad=6, gap=1.1)
    f.leader(rx0 + 190, 166, rx0 + 220, 296)
    f.text(rx0 + 140, 440, "within sight, and", T_NOTE, TEXT, bold=True)
    f.value(rx0 + 140, 476, "readily accessible", T_NOTE, records=ra, pad=6)
    f.value(rx0 + 140, 510, "(no ladder or obstacles)", T_MIN, MUTED, bold=False, records=ra, pad=4,
            what="what readily accessible means")
    f.tag(rx0 - 16, f.h - 12, "NEC 430.102, 440.14", anchor="end")
