"""Raceway and cable securing and supporting: Articles 320, 330, 334, 342, 344, 352, 358, 376, 384."""
from nec_style import *  # noqa: F401,F403


def _run(f, y, straps, couplings=(), x0=70, x1=730, s=50, color=STEEL, label_boxes=True):
    """Horizontal raceway between two boxes, strapped at `straps`; returns the box edges."""
    e0, e1 = x0 + s / 2, x1 - s / 2
    f.conduit(e0, y, e1, y, color=color)
    for x in couplings:
        f.rect(x - 9, y - 12, 18, 24, fill=PANEL_2, stroke=TEXT, sw=SW_THIN, rx=2)
    for x in straps:
        f.strap(x, y, size=30)
    for x in (x0, x1):
        f.box(x, y, s)
        if label_boxes:
            f.text(x, y - s / 2 - 12, "box", T_NOTE, TEXT)
    return e0, e1


def _span(f, xa, xb, y_obj, y_dim, text=None, size=24, color=DIM):
    """Dimension between two points on the run, with extension lines down to it."""
    for x in (xa, xb):
        f.ext(x, y_obj + 18, x, y_dim + 10)
    f.dim_h(xa, xb, y_dim)
    if text:
        f.text((xa + xb) / 2, y_dim + 34, text, size, color, bold=True)


@figure("supports_emt_strut_358-30", h=470, nec="358.30(A) incl. Exception No. 1, 384.30(A)",
        records={"final-exam-#3-013": {}, "final-exam-#5-053": {},
                 "open-book-exam-#12-022": {"like": "final-exam-#3-013"}})
def emt_strut(f):
    exc_rec = ["final-exam-#3-013"]
    every_rec = ["final-exam-#5-053"]
    y = 130
    f.title("EMT or surface strut-type channel raceway", y=40)
    e0, e1 = _run(f, y, (200, 600))
    _span(f, e0, 200, y, 180, "within 3 ft")
    _span(f, 600, e1, y, 180, "within 3 ft")
    _span(f, 200, 600, y, 180)
    f.value(400, 216, "every 10 ft max", 30, records=every_rec, label="? ft")
    # EMT Exception No. 1.
    y2 = 350
    f.line(30, 262, f.w - 30, 262, EDGE, SW_THIN)
    f.text(40, 296, "EMT only, Exception No. 1: framing does not permit 3 ft", T_NOTE, MUTED, "start", True)
    f.stud(330, y2 - 34, 30, 68)
    f.conduit(95, y2, f.w - 40, y2)
    f.box(70, y2, 50)
    f.strap(345, y2, size=30)
    f.text(560, y2 - 22, "unbroken length", T_NOTE, TEXT)
    f.text(620, y2 + 44, "first framing member", T_NOTE, MUTED)
    f.leader(470, y2 + 38, 360, y2 + 20)
    _span(f, 95, 345, y2, 400)
    f.value(220, 440, "within 5 ft", 30, records=exc_rec, label="? ft")
    f.tag(f.w - 20, f.h - 16, "NEC 358.30(A), 384.30(A)", anchor="end")


@figure("supports_rmc_344-30", h=400, nec="344.30(A), 344.30(B)(1)-(2), Table 344.30(B)",
        records=["final-exam-#3-053"])
def rmc(f):
    y = 150
    f.title("RMC, trade size 1, straight run, threaded couplings", y=40)
    e0, e1 = _run(f, y, (200, 600), couplings=(330, 470))
    f.text(400, y - 26, "threaded couplings", T_NOTE, TEXT)
    _span(f, e0, 200, y, 200, "within 3 ft")
    _span(f, 600, e1, y, 200, "within 3 ft")
    _span(f, 200, 600, y, 200)
    f.value(400, 236, "every 12 ft max", 30, label="? ft")
    f.text(400, 300, "general rule, any coupling: every 10 ft", T_NOTE, MUTED)
    f.tag(f.w - 20, f.h - 16, "NEC Table 344.30(B)", anchor="end")


@figure("supports_pvc_352-30", h=400, nec="352.30(A), Table 352.30(B)",
        records={"final-exam-#5-070": {"when": "after"},
                 "open-book-exam-#5-024": {"like": "final-exam-#5-070"}, "open-book-exam-#6-016": {}})
def pvc(f):
    y = 150
    f.title("PVC conduit, trade size 1/2 to 1", y=40)
    xs = (190, 330, 470, 610)
    e0, e1 = _run(f, y, xs, color=EDGE)
    _span(f, e0, xs[0], y, 200)
    f.lines((e0 + xs[0]) / 2 + 10, 234, ["within", "3 ft"], T_NOTE, DIM, bold=True, gap=1.1)
    for a, b in zip(xs, xs[1:]):
        _span(f, a, b, y, 200)
        f.value((a + b) / 2, 236, "3 ft", 30)
    f.text(400, 316, "larger trade sizes: wider spacing, Table 352.30(B)", T_NOTE, MUTED)
    f.tag(f.w - 20, f.h - 16, "NEC Table 352.30(B)", anchor="end")


@figure("supports_unsupported_cable_320-330-334", h=480,
        nec="320.30(D)(2)-(3), 330.30(D)(2), 334.30(B)(2)",
        records={"final-exam-#1-066": {}, "final-exam-#5-069": {}, "final-exam-#5-006": {},
                 "open-book-exam-#6-022": {"like": "final-exam-#1-066"}})
def unsupported_cable(f):
    mc = ["final-exam-#1-066"]
    nm = ["final-exam-#5-069"]
    ac_term = ["final-exam-#5-006"]
    deck, ceil = 76, 262
    # Left: accessible ceiling, last support to a luminaire.
    f.line(30, deck, 500, deck, LINE, SW_STRUCT)
    f.text(40, deck - 14, "structure", T_NOTE, MUTED, "start")
    sx, lx0, lx1 = 110, 350, 480
    cx = 380
    f.path(f"M 30 {deck + 16} L {sx} {deck + 16} C {sx + 120} {deck + 16} {cx - 60} {ceil - 110} {cx} {ceil - 30}",
           TEXT, 5)
    f.strap(sx, deck + 16, size=30)
    f.text(sx - 20, deck + 64, "last support", T_NOTE, TEXT, "start")
    f.line(30, ceil, 500, ceil, EDGE, SW_OBJ)
    for x in range(60, 500, 70):
        f.line(x, ceil - 6, x, ceil + 6, EDGE, SW_THIN)
    f.rect(lx0, ceil - 14, lx1 - lx0, 22, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=3)
    f.rect(cx - 16, ceil - 34, 32, 22, fill=PANEL_2, stroke=TEXT, sw=SW_THIN, rx=3)
    f.text((lx0 + lx1) / 2, ceil + 34, "luminaire", T_NOTE, TEXT, bold=True)
    f.text(40, ceil + 34, "accessible ceiling", T_NOTE, MUTED, "start")
    f.text(40, 336, "max unsupported cable length:", T_NOTE, MUTED, "start", True)
    rows = (("Type MC", "6 ft", mc), ("Type AC", "6 ft", mc), ("Type NM", "4 1/2 ft", nm))
    for i, (name, val, recs) in enumerate(rows):
        yy = 376 + i * 40
        f.text(40, yy, name, T_LABEL, TEXT, "start", True)
        f.value(160, yy, val, 28, anchor="start", records=recs, label="? ft")
    f.text(290, 456, "(dwellings)", T_NOTE, MUTED, "start")
    f.text(300, 118, "unsupported", T_NOTE, DIM, "start", True)
    # Right: AC cable at a terminal where flexibility is necessary.
    f.dline(520, 30, 520, f.h - 60, EDGE, SW_THIN)
    f.lines(650, 44, ["Type AC at a terminal,", "flexibility necessary"], T_NOTE, MUTED, bold=True, gap=1.1)
    tx, ty = 640, 318
    f.rect(600, 340, 150, 80, fill=PANEL, stroke=TEXT, sw=SW_OBJ, rx=8)
    f.text(675, 390, "motor", T_LABEL, TEXT, bold=True)
    f.rect(tx - 22, ty - 4, 44, 26, fill=PANEL_2, stroke=TEXT, sw=SW_THIN, rx=3)
    f.line(556, 100, 556, 200, TEXT, 5)
    f.path(f"M 556 200 C 556 260 {tx} 250 {tx} {ty - 4}", TEXT, 5)
    f.strap(556, 190, horizontal=False, size=30)
    f.text(572, 180, "last support", T_NOTE, TEXT, "start")
    f.text(770, 244, "cable length", T_NOTE, DIM, "end", True)
    f.leader(636, 252, 606, 254, DIM)
    f.value(770, 284, "2 ft max", 28, anchor="end", records=ac_term, label="? ft")
    f.tag(f.w - 20, f.h - 16, "NEC 320.30, 330.30, 334.30", anchor="end")


@figure("supports_vertical_376-30_342-30", h=500, nec="376.30(B), 342.30(B)(3)",
        records=["final-exam-#5-065", "final-exam-#5-067"])
def vertical(f):
    ww = ["final-exam-#5-065"]
    imc = ["final-exam-#5-067"]
    ceil, floor = 70, 440
    f.ceiling(ceil)
    f.floor(floor)
    # Left: vertical metal wireway on a wall.
    f.text(195, 44, "VERTICAL METAL WIREWAY", T_LABEL, TEXT, bold=True)
    wall_x, wx0, wx1 = 60, 90, 140
    f.wall(wall_x, ceil, floor)
    f.rect(wx0, ceil, wx1 - wx0, floor - ceil, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ)
    sy0, sy1, jy = 110, 390, 250
    for yy in (sy0, sy1):
        f.rect(wall_x + 8, yy - 6, wx1 - wall_x - 2, 12, fill=AMBER, rx=2)
    f.line(wx0, jy, wx1, jy, TEXT, SW_OBJ)
    f.text(wx1 + 14, jy - 14, "1 joint", T_NOTE, TEXT, "start")
    f.text(wx1 + 14, sy0 - 16, "support", T_NOTE, AMBER, "start")
    f.text(wx1 + 14, sy1 + 32, "support", T_NOTE, AMBER, "start")
    f.ext(wx1 + 4, sy0, 256, sy0)
    f.ext(wx1 + 4, sy1, 256, sy1)
    f.dim_v(246, sy0, sy1)
    f.value(262, 312, "15 ft max", 30, anchor="start", records=ww, label="? ft")
    # Right: IMC riser from industrial machinery.
    f.text(610, 44, "IMC RISER FROM MACHINERY", T_LABEL, TEXT, bold=True)
    rx = 640
    f.rect(560, 360, 200, 80, fill=PANEL, stroke=TEXT, sw=SW_OBJ, rx=8)
    f.lines(660, 394, ["industrial", "machine"], T_NOTE, TEXT, bold=True, gap=1.0)
    f.conduit(rx, ceil, rx, 360)
    ty0, ty1 = 100, 330
    for yy in (ty0, ty1):
        f.strap(rx, yy, horizontal=False, size=30)
    for yy in (180, 260):
        f.rect(rx - 12, yy - 9, 24, 18, fill=PANEL_2, stroke=TEXT, sw=SW_THIN, rx=2)
    f.lines(rx + 26, 214, ["threaded", "couplings"], T_NOTE, TEXT, "start", gap=1.0)
    f.text(rx + 26, ty0 + 8, "fastened top", T_NOTE, AMBER, "start")
    f.text(rx + 26, ty1 + 8, "and bottom", T_NOTE, AMBER, "start")
    f.ext(rx - 18, ty0, 570, ty0)
    f.ext(rx - 18, ty1, 570, ty1)
    f.dim_v(580, ty0, ty1)
    f.value(566, 226, "20 ft max", 30, anchor="end", records=imc, label="? ft")
    f.lines(390, 370, ["IMC: no other", "intermediate support", "readily available"], T_NOTE, MUTED, gap=1.1)
    f.tag(f.w - 20, f.h - 12, "NEC 376.30(B), 342.30(B)", anchor="end")
