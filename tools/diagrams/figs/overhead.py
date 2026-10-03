"""Overhead spans: outside branch circuits, communications, antenna lead-ins."""
from nec_style import *  # noqa: F401,F403


def _span(p0, c, p1, n=24):
    """Sagging span as a quadratic curve: points from p0 to p1 with control point c."""
    pts = []
    for i in range(n + 1):
        t = i / n
        a, b, d = (1 - t) ** 2, 2 * t * (1 - t), t * t
        pts.append((a * p0[0] + b * c[0] + d * p1[0], a * p0[1] + b * c[1] + d * p1[1]))
    return pts


def _y_at(pts, x):
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        if min(x0, x1) <= x <= max(x0, x1) and x0 != x1:
            return y0 + (y1 - y0) * (x - x0) / (x1 - x0)
    return pts[-1][1]


def _pole(f, x, top, bottom, w=14):
    f.rect(x - w / 2, top, w, bottom - top, fill=WOOD, op=0.8, stroke="#ca8a04", sw=SW_THIN)


RAIL = "final-exam-#1-053"
OPENING = "open-book-exam-#10-010"


@figure("building_opening_225-19", h=480, nec="225.19(D)", records=[OPENING])
def building_opening(f):
    grade, ft = 440, 14.0
    y = lambda h: grade - h * ft  # noqa: E731
    f.title("Final span beside a material-handling door", y=34)
    f.grade(grade, 20, 760, label=None)
    bx0, bx1 = 20, 330
    f.rect(bx0, y(24), bx1 - bx0, grade - y(24), fill=PANEL, stroke=EDGE, sw=SW_OBJ)
    f.line(bx0, y(12), bx1, y(12), EDGE, SW_THIN)
    f.text(260, y(3), "BUILDING", T_NOTE, MUTED, bold=True)
    dx0, dx1 = 90, 180
    f.hatch(dx0, y(20), dx1 - dx0, grade - y(20), NO, op=0.14)
    f.mark_no((dx0 + dx1) / 2, y(6))
    f.rect(dx0, y(20), dx1 - dx0, y(12) - y(20), fill=BG, stroke=TEXT, sw=SW_OBJ)
    f.mask(dx0 - 6, y(12) + 2, dx1 - dx0 + 12, grade - y(12) + 2, records=[OPENING],
           what="keep-out zone below the material opening")
    f.text(135, y(20) - 14, "material door", T_NOTE, TEXT, bold=True)
    ax, ay = 222, y(16)
    px = 600
    _pole(f, px, y(22), grade)
    ht = y(22) + 4
    f.line(px, ht + 8, px + 30, ht + 8, STEEL, 5)
    f.poly([(px + 22, ht - 6), (px + 58, ht - 6), (px + 64, ht + 20), (px + 16, ht + 20)], PANEL_2, TEXT, SW_THIN)
    f.line(px + 18, ht + 21, px + 62, ht + 21, AMBER, 4)
    f.text(px - 14, ht + 10, "floodlight", T_NOTE, TEXT, "end", True)
    span = _span((ax, ay), ((ax + px) / 2, y(14)), (px - 7, y(18)))
    f.polyline(span, WIRE_HOT, SW_WIRE)
    f.circle(ax, ay, 6, fill=TEXT)
    f.lines(470, y(14) + 50, ["120 V", "branch circuit"], T_NOTE, TEXT)
    f.ext(dx1, y(20), dx1, y(21) - 10)
    f.ext(ax, ay - 8, ax, y(21) - 10)
    f.dim_h(dx1, ax, y(21))
    f.text((dx1 + ax) / 2 + 30, y(21) - 14, "3 ft", 28, DIM, bold=True)
    f.value_lines(455, 370, ["not beneath the opening", "and not obstructing it"], T_MIN, NO,
                  records=[OPENING], what="the building-opening rule")
    f.tag(f.w - 24, 64, "NEC 225.19(D)", anchor="end")


@figure("clearance_225-18", h=480, nec="225.18",
        records={RAIL: {"when": "after"}, "open-book-exam-#5-014": {"like": RAIL},
                 "open-book-exam-#6-005": {"like": RAIL}, "open-book-exam-#12-025": {"like": RAIL}})
def clearance_225(f):
    grade, ft = 440, 14.0
    y = lambda h: grade - h * ft  # noqa: E731
    f.grade(grade, 20, 760, label=None)
    f.text(250, 40, "Overhead spans, 1000 V max", T_NOTE, MUTED, bold=True)
    for px in (60, 420):
        _pole(f, px, y(27), grade)
        f.line(px - 26, y(26), px + 26, y(26), WOOD, 6)
    span = _span((60, y(26)), (240, y(22)), (420, y(26)))
    f.polyline(span, WIRE_HOT, SW_WIRE)
    lx = 580
    f.line(lx, grade, lx, y(24.5), LINE, SW_STRUCT)
    rows = [(10, "10 ft", "pedestrians, 150 V"), (12, "12 ft", "residential, 300 V"),
            (15, "15 ft", "same, over 300 V"), (18, "18 ft", "streets, trucks"),
            (24.5, "24 1/2 ft", "railroad tracks")]
    for h, val, what in rows:
        yy = y(h)
        f.line(lx - 10, yy, lx + 10, yy, LINE, SW_STRUCT)
        f.dline(440, yy, lx - 12, yy, EDGE, 1.5, 6, 6)
        f.text(lx - 16, yy - 8, val, 26, DIM, "end", True)
        f.text(lx + 18, yy + 8, what, T_NOTE, TEXT, "start")
    f.text(lx + 18, grade - 10, "finished grade", T_NOTE, MUTED, "start")
    f.tag(f.w - 24, f.h - 14, "NEC 225.18", anchor="end")


ROOF = "final-exam-#1-050"
COMM = "final-exam-#3-031"


@figure("communications_overhead_800-44", h=460, nec="800.44",
        records={ROOF: {}, COMM: {"when": "after"}, "open-book-exam-#5-018": {"like": ROOF}})
def communications_800(f):
    grade = 410
    f.grade(grade, 20, 780, label=None)
    # Two-story house with a one-story wing the cable passes over.
    hx0, hx1, eave = 40, 250, 190
    f.rect(hx0, eave, hx1 - hx0, grade - eave, fill=PANEL, stroke=EDGE, sw=SW_OBJ)
    f.poly([(hx0 - 12, eave), ((hx0 + hx1) / 2, 110), (hx1 + 12, eave)], PANEL_2, LINE, SW_OBJ)
    f.text((hx0 + hx1) / 2, 330, "HOUSE", T_LABEL, MUTED, bold=True)
    wx1, roof = 480, 300
    f.rect(hx1, roof, wx1 - hx1, grade - roof, fill=PANEL, stroke=EDGE, sw=SW_OBJ)
    f.rect(hx1 - 4, roof - 12, wx1 - hx1 + 16, 12, fill=PANEL_2, stroke=LINE, sw=SW_THIN)
    f.text(420, 350, "roof", T_NOTE, MUTED)
    # Pole: power on the cross-arm, communications lower on the pole.
    px, arm = 700, 84
    _pole(f, px, 60, grade)
    f.rect(px - 64, arm, 128, 10, fill=WOOD, op=0.9, stroke="#ca8a04", sw=SW_THIN)
    for x in (px - 50, px - 22, px + 22, px + 50):
        f.rect(x - 5, arm - 16, 10, 16, fill=EDGE)
        f.circle(x, arm - 20, 6, fill=WIRE_HOT)
    f.lines(628, 70, ["power", "conductors"], T_NOTE, TEXT, "end", True)
    f.transformer(px + 15, 124, 40, 52, kind="pole")
    ca = 206
    f.rect(px - 19, ca - 6, 12, 12, fill=AMBER, rx=2)
    span = _span((px - 19, ca), (470, 250), (hx1, 204))
    f.polyline(span, AMBER, SW_WIRE)
    f.circle(hx1, 204, 6, fill=AMBER)
    f.text(470, 170, "communications cable", T_NOTE, AMBER, bold=True)
    # 800.44(B): clearance above the roof.
    dx = 300
    cy = _y_at(span, dx)
    f.dim_v(dx, cy, roof - 12)
    f.value(316, 262, "8 ft min", anchor="start", records=[ROOF, COMM], label="? ft")
    b = f.lines(594, 250, ["below power", "if practicable;", "not on the", "power cross-arm"],
                T_NOTE, MUTED, "middle")
    f.mask(b[0] - 8, b[1] - 8, b[2] + 16, b[3] + 16, records=[COMM], what="the 800.44(A) rules")
    f.leader(600, 228, px - 20, ca + 8)
    f.tag(f.w - 24, f.h - 14, "NEC 800.44", anchor="end")


LEADIN = "final-exam-#3-020"


@figure("antenna_leadin_810-13", h=440, nec="810.13", records=[LEADIN])
def antenna_810(f):
    grade = 400
    f.grade(grade, 20, 780, label=None)
    # House with a service mast; the utility pole is on the left.
    hx0, hx1, eave, ridge = 380, 760, 260, (570, 170)
    f.rect(hx0, eave, hx1 - hx0, grade - eave, fill=PANEL, stroke=EDGE, sw=SW_OBJ)
    f.poly([(hx0 - 12, eave), ridge, (hx1 + 12, eave)], PANEL_2, LINE, SW_OBJ)
    f.text((hx0 + hx1) / 2, 340, "HOUSE", T_LABEL, MUTED, bold=True)
    # Service mast with its weatherhead; the drop is held on an insulator below it.
    mx, wh = 440, 150
    f.conduit(mx, 300, mx, wh + 4, 10)
    f.rect(mx - 13, wh - 10, 26, 16, fill=PANEL_2, stroke=TEXT, sw=SW_THIN, rx=7)
    f.rect(mx - 22, wh + 26, 16, 6, fill=STEEL, stroke=TEXT, sw=1)
    f.circle(mx - 22, wh + 29, 5, fill=TEXT)
    # Utility pole: primaries on the cross-arm, a pole-mount transformer feeding the drop.
    px, arm = 60, 80
    _pole(f, px, 60, grade)
    f.rect(px - 40, arm, 80, 10, fill=WOOD, op=0.9, stroke="#ca8a04", sw=SW_THIN)
    for x in (px - 30, px + 30):
        f.rect(x - 4, arm - 12, 8, 12, fill=EDGE)
        f.circle(x, arm - 15, 5, fill=WIRE_HOT)
    f.transformer(px + 15, 124, 40, 52, kind="pole")
    power = _span((px + 55, 150), (260, 230), (mx - 27, wh + 29))
    f.polyline(power, WIRE_HOT, SW_WIRE)
    f.path(f"M {mx - 27} {wh + 29} q 8 26 20 4 L {mx - 7} {wh + 6}", WIRE_HOT, SW_WIRE)
    f.lines(240, 50, ["open service conductors,", "under 250 V between"], T_NOTE, TEXT, "middle", True)
    # Antenna on the roof; its lead-in comes down the mast beside the service mast.
    ax = 620
    roof_y = ridge[1] + (ax - ridge[0]) * (eave - ridge[1]) / (hx1 + 12 - ridge[0])
    f.line(ax, roof_y, ax, 60, STEEL, 8)
    for yy, half in ((64, 40), (80, 32), (96, 24)):
        f.line(ax - half, yy, ax + half, yy, TEXT, SW_OBJ)
    f.text(ax + 52, 86, "antenna", T_LABEL, TEXT, "start", True)
    lx = ax - 8
    f.line(lx, 100, lx, roof_y - 2, AMBER, SW_WIRE)
    f.text(ax + 14, 150, "lead-in", T_LABEL, AMBER, "start", True)
    # Clearance between the open service conductors and the lead-in.
    dy = 124
    f.ext(mx + 8, dy, mx + 8, wh + 16)
    f.dim_h(mx + 8, lx - 4, dy)
    f.value_lines(510, 60, ["600 mm", "(2 ft) min"], 28, label="?")
    f.tag(f.w - 24, f.h - 10, "NEC 810.13", anchor="end")
