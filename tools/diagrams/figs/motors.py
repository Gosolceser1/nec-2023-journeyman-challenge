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
    f.rect(x - 44, 290, 88, 52, fill=PANEL, stroke=TEXT, sw=SW_OBJ, rx=6)
    f.line(x, 342, x, 376, WIRE_HOT, SW_WIRE)
    f.rect(x - 34, 376, 68, 40, fill=PANEL_2, stroke=AMBER, sw=SW_OBJ, rx=5)
    f.path(f"M {x - 20} 396 q 6 -12 12 0 t 12 0 t 12 0", AMBER, 3)
    f.line(x, 416, x, 450, WIRE_HOT, SW_WIRE)
    f.circle(x, 486, 36, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ + 1)
    f.text(x, 496, "M", T_LABEL, TEXT, bold=True)
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
    # Controller in an MCC room, behind a wall.
    f.rect(30, 230, 90, 190, fill=PANEL, stroke=TEXT, sw=SW_OBJ, rx=4)
    for k in range(4):
        f.rect(40, 244 + k * 42, 70, 32, fill=PANEL_2, stroke=EDGE, sw=SW_THIN, rx=3)
    f.lines(75, 200, ["controller", "(MCC room)"], T_MIN, TEXT, bold=True, gap=1.1)
    f.wall(150, 110, fy, 18)
    # Motor and driven machine.
    f.rect(300, 340, 70, 60, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=8)
    f.text(335, 377, "M", T_LABEL, TEXT, bold=True)
    f.rect(300, 400, 70, 20, fill=STEEL)
    f.line(370, 370, 396, 370, TEXT, 8)
    f.rect(396, 320, 76, 100, fill=PANEL, stroke=TEXT, sw=SW_OBJ, rx=6)
    f.lines(434, 440 + 10, ["driven", "machine"], T_MIN, TEXT, bold=True, gap=1.05)
    # The device on a stand near the motor.
    f.rect(206, 250, 50, 64, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=5)
    f.line(256, 270, 270, 256, TEXT, 5)
    f.line(231, 314, 231, fy, STEEL, 6)
    f.mask(196, 240, 84, 84, records=dm, what="the device in sight")
    f.value_lines(231, 150, ["disconnecting", "means"], T_NOTE, records=dm, pad=6, gap=1.1)
    f.leader(231, 176, 231, 246)
    for tx, ty in ((320, 340), (430, 320)):
        f.dline(256, 282, tx, ty, DIM, 2, 6, 5)
    f.lines(250, 490, ["in sight: visible and", "not more than 50 ft"], T_MIN, DIM, bold=True, gap=1.15)
    f.lines(75, 470, ["out of", "sight"], T_MIN, NO, bold=True, gap=1.1)
    # Rooftop A/C unit.
    rx0 = 500
    f.rect(rx0, 56, 280, 480, fill=PANEL, stroke=EDGE, sw=SW_THIN, rx=8)
    f.text(rx0 + 140, 86, "rooftop A/C", T_NOTE, TEXT, bold=True)
    f.line(rx0 + 16, 400, rx0 + 264, 400, LINE, SW_STRUCT)
    f.rect(rx0 + 30, 250, 140, 150, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=6)
    f.circle(rx0 + 100, 310, 40, stroke=TEXT, sw=SW_THIN)
    for a in range(4):
        f.line(rx0 + 100, 310, rx0 + 100 + 34 * (1 if a % 2 else -1) * (a < 2),
               310 + 34 * (1 if a % 2 else -1) * (a >= 2), TEXT, 3)
    f.rect(rx0 + 200, 290, 44, 56, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=5)
    f.line(rx0 + 244, 306, rx0 + 256, 294, TEXT, 5)
    f.line(rx0 + 222, 346, rx0 + 222, 400, STEEL, 6)
    f.value_lines(rx0 + 140, 140, ["disconnecting", "means"], T_NOTE, records=dm, pad=6, gap=1.1)
    f.leader(rx0 + 190, 166, rx0 + 222, 286)
    f.text(rx0 + 140, 440, "within sight, and", T_NOTE, TEXT, bold=True)
    f.value(rx0 + 140, 476, "readily accessible", T_NOTE, records=ra, pad=6)
    f.value(rx0 + 140, 510, "(no ladder or obstacles)", T_MIN, MUTED, bold=False, records=ra, pad=4,
            what="what readily accessible means")
    f.tag(rx0 - 16, f.h - 12, "NEC 430.102, 440.14", anchor="end")
