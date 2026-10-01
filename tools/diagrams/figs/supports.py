"""Raceway and cable securing and supporting: Articles 320, 330, 334, 342, 344, 352, 358, 376, 384."""
from nec_style import *  # noqa: F401,F403


def _strap1(f, x, y, vertical=False, foot=1):
    """One-hole pipe strap at (x, y) on a run: the saddle across the pipe and the
    foot with its screw on one side (foot=+1 below / right, -1 above / left)."""
    if vertical:
        f.rect(x - 13, y - 6, 26, 12, fill=AMBER, stroke=CLAMP, sw=1.5, rx=3)
        fx = x + foot * 21
        f.rect(fx - 9, y - 6, 18, 12, fill=AMBER, stroke=CLAMP, sw=1.5, rx=2)
        f.circle(fx, y, 3.5, fill=BG)
    else:
        f.rect(x - 6, y - 13, 12, 26, fill=AMBER, stroke=CLAMP, sw=1.5, rx=3)
        fy = y + foot * 21
        f.rect(x - 6, fy - 9, 12, 18, fill=AMBER, stroke=CLAMP, sw=1.5, rx=2)
        f.circle(x, fy, 3.5, fill=BG)


def _connector(f, x, y, d, vertical=False):
    """Box connector and locknut where a raceway enters a box edge at (x, y); d = run direction."""
    if vertical:
        f.rect(x - 13, min(y, y + d * 14), 26, 14, fill=PANEL_2, stroke=LINE, sw=SW_THIN, rx=2)
    else:
        f.rect(min(x, x + d * 14), y - 13, 14, 26, fill=PANEL_2, stroke=LINE, sw=SW_THIN, rx=2)


def _run(f, y, straps, couplings=(), x0=70, x1=730, s=50, color=STEEL, label_boxes=True):
    """Horizontal raceway between two boxes, one-hole strapped at `straps` and
    coupled at `couplings` (x positions); returns the box edges."""
    e0, e1 = x0 + s / 2, x1 - s / 2
    f.conduit(e0 + 14, y, e1 - 14, y, color=color, couplings=[(x - e0 - 14) / (e1 - e0 - 28) for x in couplings])
    _connector(f, e0, y, 1)
    _connector(f, e1, y, -1)
    for x in straps:
        _strap1(f, x, y)
    for x in (x0, x1):
        f.box(x, y, s)
        if label_boxes:
            f.text(x, y - s / 2 - 12, "box", T_NOTE, TEXT)
    return e0, e1


def _span(f, xa, xb, y_obj, y_dim, text=None, size=24, color=DIM):
    """Dimension between two points on the run, with extension lines down to it."""
    for x in (xa, xb):
        f.ext(x, y_obj + 32, x, y_dim + 10)
    f.dim_h(xa, xb, y_dim)
    if text:
        f.text((xa + xb) / 2, y_dim + 34, text, size, color, bold=True)


def _bezier(p0, p1, p2, p3, n=24):
    pts = []
    for i in range(n + 1):
        t = i / n
        a, b, c, d = (1 - t) ** 3, 3 * t * (1 - t) ** 2, 3 * t * t * (1 - t), t ** 3
        pts.append((a * p0[0] + b * p1[0] + c * p2[0] + d * p3[0], a * p0[1] + b * p1[1] + c * p2[1] + d * p3[1]))
    return pts


def _armored(f, pts, step=9):
    """Interlocked-armor cable along a polyline: steel band with convolution ticks."""
    f.polyline(pts, LINE, 12)
    f.polyline(pts, STEEL, 8)
    carry = 0.0
    for (xa, ya), (xb, yb) in zip(pts, pts[1:]):
        seg = math.hypot(xb - xa, yb - ya)
        if seg == 0:
            continue
        ux, uy = (xb - xa) / seg, (yb - ya) / seg
        t = step - carry
        while t < seg:
            cx, cy = xa + ux * t, ya + uy * t
            f.line(cx - uy * 5, cy + ux * 5, cx + uy * 5, cy - ux * 5, BG, 1.5)
            t += step
        carry = (carry + seg) % step


@figure("supports_emt_strut_358-30", h=480, nec="358.30(A) incl. Exception No. 1, 384.30(A)",
        records={"final-exam-#3-013": {}, "final-exam-#5-053": {},
                 "open-book-exam-#12-022": {"like": "final-exam-#3-013"}})
def emt_strut(f):
    exc_rec = ["final-exam-#3-013"]
    every_rec = ["final-exam-#5-053"]
    y = 120
    f.title("EMT or surface strut-type channel raceway", y=40)
    e0, e1 = _run(f, y, (200, 600), couplings=(470,))
    _span(f, e0, 200, y, 186, "within 3 ft")
    _span(f, 600, e1, y, 186, "within 3 ft")
    _span(f, 200, 600, y, 186)
    f.value(400, 222, "every 10 ft max", 30, records=every_rec, label="? ft")
    # EMT Exception No. 1.
    y2 = 356
    f.line(30, 266, f.w - 30, 266, EDGE, SW_THIN)
    f.text(40, 300, "EMT only, Exception No. 1: framing does not permit 3 ft", T_NOTE, MUTED, "start", True)
    f.stud(330, y2 - 40, 30, 80)
    f.conduit(109, y2, f.w + 10, y2)
    _connector(f, 95, y2, 1)
    f.box(70, y2, 50)
    _strap1(f, 345, y2, foot=-1)
    f.text(580, y2 - 26, "unbroken length", T_NOTE, TEXT)
    f.text(620, y2 + 50, "first framing member", T_NOTE, MUTED)
    f.leader(480, y2 + 44, 362, y2 + 30)
    _span(f, 95, 345, y2, 408)
    f.value(220, 448, "within 5 ft", 30, records=exc_rec, label="? ft")
    f.tag(f.w - 20, f.h - 16, "NEC 358.30(A), 384.30(A)", anchor="end")


@figure("supports_rmc_344-30", h=400, nec="344.30(A), 344.30(B)(1)-(2), Table 344.30(B)",
        records=["final-exam-#3-053"])
def rmc(f):
    y = 150
    f.title("RMC, trade size 1, straight run, threaded couplings", y=40)
    e0, e1 = _run(f, y, (200, 600), couplings=(330, 470))
    f.text(400, y - 30, "threaded couplings", T_NOTE, TEXT)
    _span(f, e0, 200, y, 210, "within 3 ft")
    _span(f, 600, e1, y, 210, "within 3 ft")
    _span(f, 200, 600, y, 210)
    f.value(400, 246, "every 12 ft max", 30, label="? ft")
    f.text(400, 310, "general rule, any coupling: every 10 ft", T_NOTE, MUTED)
    f.tag(f.w - 20, f.h - 16, "NEC Table 344.30(B)", anchor="end")


@figure("supports_pvc_352-30", h=470, nec="352.30(A), Table 352.30(B)",
        records={"final-exam-#5-070": {"when": "after"},
                 "open-book-exam-#5-024": {"like": "final-exam-#5-070"}, "open-book-exam-#6-016": {}})
def pvc(f):
    big = ["open-book-exam-#6-016"]
    y = 130
    f.title("PVC conduit, trade size 1/2 to 1", y=40)
    xs = (190, 330, 470, 610)
    e0, e1 = _run(f, y, xs, couplings=(400,), color=EDGE)
    _span(f, e0, xs[0], y, 190)
    f.lines((e0 + xs[0]) / 2 + 10, 224, ["within", "3 ft"], T_NOTE, DIM, bold=True, gap=1.1)
    for a, b in zip(xs, xs[1:]):
        _span(f, a, b, y, 190)
        f.value((a + b) / 2, 226, "3 ft", 30)
    # Table 352.30(B), the next sizes up.
    f.card(60, 290, 680, 130, "Table 352.30(B): max spacing between supports")
    cols = (("1/2 - 1", "3 ft", None), ("1 1/4 - 2", "5 ft", big), ("2 1/2 - 3", "6 ft", ()),
            ("3 1/2 - 5", "7 ft", ()))
    for i, (size, val, recs) in enumerate(cols):
        cx = 145 + i * 170
        f.text(cx, 360, size, T_NOTE, MUTED)
        if recs == ():
            f.text(cx, 400, val, 28, TEXT, bold=True)
        else:
            f.value(cx, 400, val, 28, records=recs, label="? ft")
    f.tag(f.w - 20, f.h - 14, "NEC Table 352.30(B)", anchor="end")


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
    sx, lx0, lx1 = 110, 330, 480
    cx = 380
    jt = ceil - 58
    f.path(f"M 30 {deck + 16} L {sx} {deck + 16} C {sx + 120} {deck + 16} {cx - 60} {jt - 90} {cx} {jt}",
           TEXT, 5)
    f.strap(sx, deck + 16, size=30)
    f.text(sx - 20, deck + 64, "last support", T_NOTE, TEXT, "start")
    # Suspended ceiling: grid tees, and a lay-in troffer resting in the grid.
    f.line(30, ceil, 500, ceil, EDGE, SW_OBJ)
    for x in (60, 170, 280, 500 - 10):
        f.line(x, ceil, x, ceil - 10, EDGE, SW_THIN)
    f.poly([(lx0, ceil), (lx0 + 18, ceil - 36), (lx1 - 18, ceil - 36), (lx1, ceil)], PANEL_2, TEXT, SW_OBJ)
    f.rect(lx0 + 4, ceil - 3, lx1 - lx0 - 8, 9, fill=LINE, stroke=TEXT, sw=1.5, rx=2)
    f.rect(cx - 18, jt, 36, 22, fill=PANEL_2, stroke=TEXT, sw=SW_THIN, rx=3)
    f.text((lx0 + lx1) / 2, ceil + 34, "luminaire", T_NOTE, TEXT, bold=True)
    f.text(40, ceil + 34, "accessible ceiling", T_NOTE, MUTED, "start")
    f.text(40, 336, "max unsupported cable length:", T_NOTE, MUTED, "start", True)
    rows = (("Type MC", "6 ft", mc), ("Type AC", "6 ft", mc), ("Type NM", "4 1/2 ft", nm))
    for i, (name, val, recs) in enumerate(rows):
        yy = 376 + i * 40
        f.text(40, yy, name, T_LABEL, TEXT, "start", True)
        f.value(160, yy, val, 28, anchor="start", records=recs, label="? ft")
    f.text(290, 456, "(dwellings)", T_NOTE, MUTED, "start")
    f.text(290, 118, "unsupported", T_NOTE, DIM, "start", True)
    # Right: AC cable at a motor terminal box where flexibility is necessary.
    f.dline(520, 30, 520, f.h - 60, EDGE, SW_THIN)
    f.lines(650, 44, ["Type AC at a terminal,", "flexibility necessary"], T_NOTE, MUTED, bold=True, gap=1.1)
    mx, my, mw, mh = 668, 376, 140, 66
    tb = my - mh / 2 - mh * 0.24
    f.motor(mx, my, mw, mh)
    _armored(f, [(556, 100), (556, 200)] + _bezier((556, 200), (556, 262), (mx, 252), (mx, tb))[1:])
    f.strap(556, 190, horizontal=False, size=30)
    f.text(574, 180, "last support", T_NOTE, TEXT, "start")
    f.text(770, 236, "cable length", T_NOTE, DIM, "end", True)
    f.leader(640, 242, 620, 262, DIM)
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
    # Left: vertical metal wireway on a wall: screw cover, one bolted joint.
    f.text(195, 44, "VERTICAL METAL WIREWAY", T_LABEL, TEXT, bold=True)
    wall_x, wx0, wx1 = 60, 92, 142
    f.wall(wall_x, ceil, floor)
    sy0, sy1, jy = 110, 390, 250
    for a, b in ((ceil, jy), (jy, floor)):
        f.rect(wx0, a, wx1 - wx0, b - a, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ)
        f.rect(wx0 + 7, a + 8, wx1 - wx0 - 14, b - a - 16, fill="none", stroke=EDGE, sw=1.5, rx=2)
        for yy in (a + 22, b - 22):
            f.circle((wx0 + wx1) / 2, yy, 3, fill=LINE)
    f.rect(wx0 - 4, jy - 5, wx1 - wx0 + 8, 10, fill=EDGE, stroke=TEXT, sw=1.5, rx=2)
    for yy in (sy0, sy1):
        f.rect(wall_x + 8, yy - 7, wx1 - wall_x - 2, 14, fill=AMBER, stroke=CLAMP, sw=1.5, rx=2)
        f.circle(wall_x + 17, yy, 3.5, fill=BG)
    f.text(wx1 + 14, jy - 14, "1 joint", T_NOTE, TEXT, "start")
    f.text(wx1 + 14, sy0 - 16, "support", T_NOTE, AMBER, "start")
    f.text(wx1 + 14, sy1 + 32, "support", T_NOTE, AMBER, "start")
    f.ext(wx1 + 8, sy0, 256, sy0)
    f.ext(wx1 + 8, sy1, 256, sy1)
    f.dim_v(246, sy0, sy1)
    f.value(262, 312, "15 ft max", 30, anchor="start", records=ww, label="? ft")
    # Right: IMC riser from industrial machinery.
    f.text(610, 44, "IMC RISER FROM MACHINERY", T_LABEL, TEXT, bold=True)
    rx = 640
    f.rect(560, 366, 200, 66, fill=PANEL, stroke=TEXT, sw=SW_OBJ, rx=6)
    f.rect(572, 432, 22, 8, fill=STEEL, stroke=TEXT, sw=1.5)
    f.rect(726, 432, 22, 8, fill=STEEL, stroke=TEXT, sw=1.5)
    f.lines(702, 394, ["industrial", "machine"], T_NOTE, TEXT, bold=True, gap=1.05)
    f.rect(rx - 26, 340, 52, 28, fill=PANEL_2, stroke=TEXT, sw=SW_THIN, rx=3)
    f.conduit(rx, ceil, rx, 326, couplings=(0.43, 0.74))
    _connector(f, rx, 340, -1, vertical=True)
    ty0, ty1 = 100, 316
    for yy in (ty0, ty1):
        _strap1(f, rx, yy, vertical=True, foot=-1)
    f.lines(rx + 26, 194, ["threaded", "couplings"], T_NOTE, TEXT, "start", gap=1.0)
    f.text(rx + 26, ty0 + 8, "fastened top", T_NOTE, AMBER, "start")
    f.text(rx + 26, ty1 + 8, "and bottom", T_NOTE, AMBER, "start")
    f.ext(rx - 34, ty0, 570, ty0)
    f.ext(rx - 34, ty1, 570, ty1)
    f.dim_v(580, ty0, ty1)
    f.value(566, 220, "20 ft max", 30, anchor="end", records=imc, label="? ft")
    f.lines(390, 370, ["IMC: no other", "intermediate support", "readily available"], T_NOTE, MUTED, gap=1.1)
    f.tag(f.w - 20, f.h - 12, "NEC 376.30(B), 342.30(B)", anchor="end")
