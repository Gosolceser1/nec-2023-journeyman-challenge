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


@figure("emt_supports_358-30", h=330, nec="358.30(A)",
        records={"final-exam-#3-013": {}, "open-book-exam-#12-022": {"like": "final-exam-#3-013"}})
def emt_supports(f):
    exc_rec = ["final-exam-#3-013"]
    y2 = 170
    f.title("EMT where the framing does not permit fastening within 3 ft", y=40)
    f.stud(330, y2 - 40, 30, 80)
    f.conduit(109, y2, f.w + 10, y2)
    _connector(f, 95, y2, 1)
    f.box(70, y2, 50)
    f.text(70, y2 - 37, "box", T_NOTE, TEXT)
    _strap1(f, 345, y2, foot=-1)
    f.text(580, y2 - 26, "unbroken length", T_NOTE, TEXT)
    f.text(620, y2 + 50, "first framing member", T_NOTE, MUTED)
    f.leader(480, y2 + 44, 362, y2 + 30)
    _span(f, 95, 345, y2, 222)
    f.value(220, 262, "within 5 ft", 30, records=exc_rec, label="? ft")
    f.tag(f.w - 20, f.h - 16, "NEC 358.30(A)", anchor="end")


@figure("strut_supports_384-30", h=300, nec="384.30(A)", records=["final-exam-#5-053"])
def strut_supports(f):
    every_rec = ["final-exam-#5-053"]
    y = 120
    f.title("Surface strut-type channel raceway between two boxes", y=40)
    e0, e1 = _run(f, y, (200, 600))
    _span(f, e0, 200, y, 186, "within 3 ft")
    _span(f, 600, e1, y, 186, "within 3 ft")
    _span(f, 200, 600, y, 186)
    f.value(400, 222, "every 10 ft max", 30, records=every_rec, label="? ft")
    f.tag(f.w - 20, f.h - 16, "NEC 384.30(A)", anchor="end")


@figure("supports_rmc_344-30", h=400, nec="344.30(B)(2)",
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
    f.tag(f.w - 20, f.h - 16, "NEC 344.30(B)(2)", anchor="end")


@figure("supports_pvc_352-30", h=470, nec="352.30",
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
    f.tag(f.w - 20, f.h - 14, "NEC 352.30", anchor="end")


def _ceiling_run(f, kind):
    """Cable from its last support down to a lay-in luminaire in an accessible ceiling."""
    deck, ceil = 90, 300
    f.line(30, deck, f.w - 30, deck, LINE, SW_STRUCT)
    f.text(40, deck - 14, "structure", T_NOTE, MUTED, "start")
    sx, lx0, lx1, cx = 160, 470, 690, 580
    jt = ceil - 58
    pts = [(30, deck + 16), (sx, deck + 16)] + _bezier((sx, deck + 16), (sx + 200, deck + 16), (cx - 90, jt - 110),
                                                        (cx, jt))[1:]
    if kind == "armored":
        _armored(f, pts)
    else:
        f.polyline(pts, TEXT, 7)
    f.strap(sx, deck + 16, size=30)
    f.text(sx - 30, deck + 66, "last support", T_NOTE, TEXT, "start")
    f.line(30, ceil, f.w - 30, ceil, EDGE, SW_OBJ)
    for x in (80, 220, 360, 760):
        f.line(x, ceil, x, ceil - 10, EDGE, SW_THIN)
    f.poly([(lx0, ceil), (lx0 + 18, ceil - 36), (lx1 - 18, ceil - 36), (lx1, ceil)], PANEL_2, TEXT, SW_OBJ)
    f.rect(lx0 + 4, ceil - 3, lx1 - lx0 - 8, 9, fill=LINE, stroke=TEXT, sw=1.5, rx=2)
    f.rect(cx - 18, jt, 36, 22, fill=PANEL_2, stroke=TEXT, sw=SW_THIN, rx=3)
    f.text((lx0 + lx1) / 2, ceil + 34, "luminaire", T_NOTE, TEXT, bold=True)
    f.text(40, ceil + 34, "accessible ceiling", T_NOTE, MUTED, "start")
    f.text(250, 196, "unsupported", T_NOTE, DIM, "start", True)


@figure("mc_unsupported_330-30", h=440, nec="330.30(D)(2)",
        records={"final-exam-#1-066": {}, "open-book-exam-#6-022": {"like": "final-exam-#1-066"}})
def mc_unsupported(f):
    mc = ["final-exam-#1-066"]
    f.title("Type MC cable to a luminaire in an accessible ceiling", y=40)
    _ceiling_run(f, "armored")
    f.text(400, 390, "max unsupported length:", T_NOTE, TEXT, "end", True)
    f.value(414, 390, "6 ft", 30, anchor="start", records=mc, label="? ft")
    f.tag(f.w - 20, f.h - 14, "NEC 330.30(D)(2)", anchor="end")


@figure("nm_unsupported_334-30", h=440, nec="334.30(B)(2)", records=["final-exam-#5-069"])
def nm_unsupported(f):
    nm = ["final-exam-#5-069"]
    f.title("Type NM cable to a luminaire in an accessible ceiling", y=40)
    _ceiling_run(f, "sheathed")
    f.text(400, 390, "max unsupported length:", T_NOTE, TEXT, "end", True)
    f.value(414, 390, "4 1/2 ft", 30, anchor="start", records=nm, label="? ft")
    f.tag(f.w - 20, f.h - 14, "NEC 334.30(B)(2)", anchor="end")


@figure("ac_unsupported_320-30", h=440, nec="320.30(D)(2)", records=["final-exam-#5-006"])
def ac_unsupported(f):
    ac_term = ["final-exam-#5-006"]
    f.title("Type AC cable at a terminal where flexibility is necessary", y=40)
    mx, my, mw, mh = 520, 340, 180, 84
    tb = my - mh / 2 - mh * 0.24
    f.motor(mx, my, mw, mh)
    f.floor(my + mh / 2 + 14, 300, 740)
    sx = 300
    _armored(f, [(sx, 70), (sx, 180)] + _bezier((sx, 180), (sx, 250), (mx, 230), (mx, tb))[1:])
    f.strap(sx, 170, horizontal=False, size=30)
    f.text(sx - 20, 170, "last support", T_NOTE, TEXT, "end")
    f.text(640, 170, "cable length", T_NOTE, DIM, "start", True)
    f.leader(636, 176, 470, 232, DIM)
    f.value(640, 214, "2 ft max", 30, anchor="start", records=ac_term, label="? ft")
    f.tag(f.w - 20, f.h - 14, "NEC 320.30(D)(2)", anchor="end")


@figure("wireway_vertical_376-30", h=470, nec="376.30(B)", records=["final-exam-#5-065"])
def wireway_vertical(f):
    ww = ["final-exam-#5-065"]
    ceil, floor = 70, 440
    f.ceiling(ceil)
    f.floor(floor)
    f.title("Vertical metal wireway on a wall", y=44)
    wall_x, wx0, wx1 = 260, 292, 352
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
    f.text(wx1 + 14, jy - 14, "one joint", T_NOTE, TEXT, "start")
    f.text(wx1 + 14, sy0 - 16, "support", T_NOTE, AMBER, "start")
    f.text(wx1 + 14, sy1 + 32, "support", T_NOTE, AMBER, "start")
    f.ext(wx1 + 8, sy0, 486, sy0)
    f.ext(wx1 + 8, sy1, 486, sy1)
    f.dim_v(476, sy0, sy1)
    f.value(492, 312, "15 ft max", 30, anchor="start", records=ww, label="? ft")
    f.tag(f.w - 20, f.h - 40, "NEC 376.30(B)", anchor="end")


@figure("imc_riser_342-30", h=470, nec="342.30(B)(3)", records=["final-exam-#5-067"])
def imc_riser(f):
    imc = ["final-exam-#5-067"]
    ceil, floor = 70, 440
    f.ceiling(ceil)
    f.floor(floor)
    f.title("Exposed IMC riser from industrial machinery", y=44)
    rx = 400
    f.rect(320, 366, 200, 66, fill=PANEL, stroke=TEXT, sw=SW_OBJ, rx=6)
    f.rect(332, 432, 22, 8, fill=STEEL, stroke=TEXT, sw=1.5)
    f.rect(486, 432, 22, 8, fill=STEEL, stroke=TEXT, sw=1.5)
    f.lines(462, 394, ["industrial", "machine"], T_NOTE, TEXT, bold=True, gap=1.05)
    f.rect(rx - 26, 340, 52, 28, fill=PANEL_2, stroke=TEXT, sw=SW_THIN, rx=3)
    f.conduit(rx, ceil, rx, 326, couplings=(0.43, 0.74))
    _connector(f, rx, 340, -1, vertical=True)
    ty0, ty1 = 100, 316
    for yy in (ty0, ty1):
        _strap1(f, rx, yy, vertical=True, foot=-1)
    f.lines(rx + 26, 194, ["threaded", "couplings"], T_NOTE, TEXT, "start", gap=1.0)
    f.text(rx + 26, ty0 + 8, "fastened top", T_NOTE, AMBER, "start")
    f.text(rx + 26, ty1 + 8, "and bottom", T_NOTE, AMBER, "start")
    f.ext(rx - 34, ty0, 330, ty0)
    f.ext(rx - 34, ty1, 330, ty1)
    f.dim_v(340, ty0, ty1)
    f.value(326, 220, "20 ft max", 30, anchor="end", records=imc, label="? ft")
    f.lines(650, 250, ["no other", "intermediate support", "readily available"], T_NOTE, MUTED, gap=1.1)
    f.tag(f.w - 20, f.h - 40, "NEC 342.30(B)(3)", anchor="end")
