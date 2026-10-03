"""Receptacle placement along counters and windows: kitchen counter spacing and height, the
small-appliance circuits, bathroom sink counters, front and back outdoor outlets, show windows."""
from nec_style import *  # noqa: F401,F403

WALL_LINE = ["open-book-exam-#2-007"]
HEIGHT = ["open-book-exam-#3-001"]
SABC = ["final-exam-#4-016"]


def _counter_receptacle(f, x, y):
    f.receptacle(x, y, 36)


@figure("kitchen_counter_210-52c", h=510, nec="210.52(C)", records={WALL_LINE[0]: {}, HEIGHT[0]: {}})
def kitchen_counter(f):
    f.title("Kitchen counter receptacles (elevation)", y=34)
    top, floor, x0, x1, ppi = 300, 420, 60, 740, 5.0
    f.rect(x0, 70, x1 - x0, 80, fill=PANEL, stroke=EDGE, sw=SW_THIN)
    for x in (230, 400, 570):
        f.line(x, 70, x, 150, EDGE, SW_THIN)
    f.text((x0 + x1) / 2, 118, "upper cabinets", T_MIN, MUTED)
    f.rect(x0, top, x1 - x0, 14, fill=LINE, stroke=TEXT, sw=SW_THIN)
    f.rect(x0 + 6, top + 14, x1 - x0 - 12, floor - top - 14, fill=PANEL, stroke=EDGE, sw=SW_THIN)
    f.path(f"M 560 {top} q 0 30 30 30 h 60 q 30 0 30 -30", TEXT, SW_THIN)
    f.text(620, top - 10, "sink", T_MIN, MUTED)
    f.floor(floor, 20, f.w - 20)
    ry = top - 60
    xs = [x0 + 24 * ppi, x0 + 72 * ppi, x0 + 120 * ppi]
    for x in xs:
        _counter_receptacle(f, x, ry)
    f.ext(x0, top - 4, x0, 186)
    f.ext(xs[0], ry - 20, xs[0], 186)
    f.dim_h(x0, xs[0], 196)
    f.value((x0 + xs[0]) / 2, 182, "24 in", 26, pad=5, records=WALL_LINE, what="the wall-line distance")
    f.ext(xs[1], ry - 20, xs[1], 186)
    f.dim_h(xs[0], xs[1], 196)
    f.text((xs[0] + xs[1]) / 2, 184, "midpoint", T_MIN, MUTED)
    f.line((xs[0] + xs[1]) / 2, 204, (xs[0] + xs[1]) / 2, top - 4, MUTED, SW_THIN)
    hx = xs[1] + 40
    f.ext(xs[1] + 14, ry, hx + 8, ry)
    f.dim_v(hx, ry, top)
    f.value(hx + 12, ry + 34, "20 in", 26, anchor="start", pad=5, records=HEIGHT, what="the height above the counter")
    f.text(hx + 12, ry + 58, "max", T_MIN, MUTED, "start")
    f.lines(x0, 452, ["No point along the counter wall line is farther than the limit from a receptacle outlet."],
            T_MIN, TEXT, "start")
    f.tag(f.w - 24, f.h - 12, "NEC 210.52(C)", anchor="end")


@figure("small_appliance_circuits_210-52b", h=420, nec="210.52(B)", when="after", records=SABC)
def small_appliance_circuits(f):
    f.title("Small-appliance branch circuits (two or more)", y=34)
    f.panel(40, 90, 110, 170, label="panel", breakers=4)
    rooms = [(200, 90, "kitchen"), (360, 90, "pantry"), (200, 190, "breakfast"), (360, 190, "dining room")]
    for x, y, name in rooms:
        f.rect(x, y, 150, 80, fill=PANEL, stroke=LINE, sw=SW_OBJ, rx=4)
        f.text(x + 75, y + 46, name, T_MIN, TEXT, bold=True)
    f.line(150, 140, 200, 140, WIRE_HOT, SW_WIRE)
    f.line(150, 220, 200, 220, WIRE_HOT, SW_WIRE)
    f.lines(355, 310, ["wall and counter receptacles", "in these rooms"], T_MIN, MUTED, gap=1.2)
    f.card(520, 80, 260, 300, "Other outlets allowed")
    f.lines(534, 140, ["- an electric clock", "  outlet", "- gas range, oven or", "  cooktop accessories"], T_MIN,
            TEXT, "start", gap=1.2)
    f.highlight(526, 116, 248, 116)
    f.text(534, 300, "nothing else", T_NOTE, NO, "start", True)


BATH = ["final-exam-#4-010"]
FRONT_BACK = ["final-exam-#4-015"]


@figure("bath_counter_210-52d", h=480, nec="210.52(D)", records=BATH)
def bath_counter(f):
    f.title("Bathroom counter with a sink (elevation)", y=34)
    top, floor, x0, x1, ppf = 280, 390, 60, 610, 78.0
    f.rect(x0, top, x1 - x0, 12, fill=LINE, stroke=TEXT, sw=SW_THIN)
    f.rect(x0 + 6, top + 12, x1 - x0 - 12, floor - top - 12, fill=PANEL, stroke=EDGE, sw=SW_THIN)
    f.floor(floor, 20, f.w - 20)
    sx0, sx1 = 260, 380
    f.path(f"M {sx0} {top} q 0 34 34 34 h 52 q 34 0 34 -34", TEXT, SW_THIN)
    f.text((sx0 + sx1) / 2, top - 10, "sink", T_MIN, MUTED)
    f.ext(x0, top + 16, x0, floor + 30)
    f.ext(x1, top + 16, x1, floor + 30)
    f.dim_h(x0, x1, floor + 22)
    f.text((x0 + x1) / 2, floor + 50, "counter: seven feet", T_NOTE, DIM, bold=True)
    zx0, zx1 = sx0 - 3 * ppf, sx1 + 3 * ppf
    zl, zr = max(x0, zx0), min(x1, zx1)
    f.rect(zl, 130, zr - zl, top - 130, fill=ZONE, op=0.10)
    for a, b in (((zl, 130), (zr, 130)), ((zl, 130), (zl, top)), ((zr, 130), (zr, top))):
        f.dline(a[0], a[1], b[0], b[1], ZONE, SW_THIN, 8, 6)
    f.lines(x0 + 10, 158, ["receptacle within 3 ft of the", "outside edge of each sink"], T_MIN, DIM, "start",
            gap=1.1)
    f.receptacle(500, 230, 44, gfci=True)
    f.mask(470, 200, 60, 62, what="the receptacle drawn on the wall")
    f.card(630, 120, 150, 120, "Required")
    f.value(705, 200, "one outlet", T_NOTE, pad=5, what="how many receptacles")
    f.tag(f.w - 24, f.h - 12, "NEC 210.52(D)", anchor="end")


@figure("outdoor_receptacles_210-52e1", h=430, nec="210.52(E)(1)", records=FRONT_BACK)
def outdoor_receptacles(f):
    f.title("Outdoor receptacles at the front and back (plan view)", y=34)
    hx0, hy0, hx1, hy1 = 120, 120, 420, 290
    f.rect(hx0, hy0, hx1 - hx0, hy1 - hy0, fill=PANEL, stroke=LINE, sw=SW_STRUCT)
    f.text((hx0 + hx1) / 2, (hy0 + hy1) / 2 + 8, "dwelling", T_LABEL, TEXT, bold=True)
    f.text((hx0 + hx1) / 2, hy0 - 44, "BACK", T_NOTE, MUTED, bold=True)
    f.text((hx0 + hx1) / 2, hy1 + 64, "FRONT", T_NOTE, MUTED, bold=True)
    f.plan_receptacle(220, hy0 - 16, gfci=True)
    f.plan_receptacle(330, hy1 + 16, gfci=True)
    f.card(460, 90, 320, 200)
    f.lines(476, 130, ["one at the front and one", "at the back, readily", "accessible from grade"], T_MIN, TEXT,
            "start", gap=1.2)
    f.text(476, 214, "6 1/2 ft or less above grade", T_MIN, MUTED, "start")
    f.text(476, 260, "required on:", T_MIN, MUTED, "start", True)
    f.value(400, 396, "one- and two-family dwellings", T_NOTE, pad=6, what="which buildings the rule covers")
    f.tag(f.w - 24, 64, "NEC 210.52(E)(1)", anchor="end")


WINDOW = ["open-book-exam-#2-009"]
WINDOW_VA = ["final-exam-#4-012"]


def _show_window(f, x0=50, x1=466, wtop=200, wbot=380):
    f.rect(20, 120, x1 + 30, 280, fill=PANEL, op=0.5, stroke=LINE, sw=SW_THIN)
    f.rect(x0, wtop, x1 - x0, wbot - wtop, fill=WATER, stroke=WATER_EDGE, sw=SW_OBJ)
    f.text((x0 + x1) / 2, (wtop + wbot) / 2 + 8, "show window", T_LABEL, TEXT, bold=True)


@figure("show_window_receptacle_210-62", h=440, nec="210.62", records=WINDOW)
def show_window_receptacle(f):
    f.title("Store show window: receptacle above it (elevation)", y=34)
    ppf, x0, x1, wtop, wbot = 26.0, 50, 466, 200, 380
    _show_window(f, x0, x1, wtop, wbot)
    ry = wtop - 40
    xs = [x0 + 6 * ppf, x1 - 6 * ppf]
    for x in xs:
        f.receptacle(x, ry, 32)
    f.ext(x0, wtop - 4, x0, 86)
    f.ext(xs[0], ry - 18, xs[0], 86)
    f.dim_h(x0, xs[0], 96)
    f.text((x0 + xs[0]) / 2, 84, "6 ft max", T_NOTE, DIM, bold=True)
    f.ext(x1, wtop - 4, x1, 86)
    f.ext(xs[1], ry - 18, xs[1], 86)
    f.dim_h(xs[1], x1, 96)
    f.text((xs[1] + x1) / 2, 84, "6 ft max", T_NOTE, DIM, bold=True)
    hx = xs[0] - 34
    f.ext(xs[0] - 12, ry, hx - 8, ry)
    f.dim_v(hx, ry, wtop)
    f.value(hx - 12, ry + 30, "18 in", 26, anchor="end", pad=5, what="the distance from the top")
    f.card(530, 120, 250, 170)
    f.lines(546, 160, ["at least one 125 V,", "15 or 20 A receptacle", "within this distance", "of the window top"],
            T_MIN, TEXT, "start", gap=1.2)
    f.tag(f.w - 24, f.h - 14, "NEC 210.62", anchor="end")


@figure("show_window_load_220-14g", h=470, nec="220.14(G)", records=WINDOW_VA)
def show_window_load(f):
    f.title("Store show window: lighting load (elevation)", y=34)
    x0, x1, wtop, wbot = 50, 466, 200, 380
    _show_window(f, x0, x1, wtop, wbot)
    f.ext(x0, wbot + 4, x0, 420)
    f.ext(x1, wbot + 4, x1, 420)
    f.dim_h(x0, x1, 412)
    f.text((x0 + x1) / 2, 450, "16 ft along the base", T_NOTE, DIM, bold=True)
    cx = 516
    f.rect(cx, 110, 264, 290, fill=PANEL, stroke=EDGE, sw=SW_THIN, rx=8)
    f.text(cx + 14, 144, "Show window load", T_NOTE, TEXT, "start", True)
    f.value(cx + 14, 194, "200 VA", 30, anchor="start", pad=6, what="the load per foot")
    f.text(cx + 14, 226, "per linear foot,", T_MIN, TEXT, "start")
    f.text(cx + 14, 250, "measured along the base", T_MIN, TEXT, "start")
    f.text(cx + 14, 300, "this window:", T_MIN, MUTED, "start", True)
    f.value(cx + 14, 336, "16 ft x 200 VA", T_NOTE, anchor="start", pad=5, what="the worked load")
    f.value(cx + 14, 372, "= 3,200 VA", T_NOTE, anchor="start", pad=5, what="the worked load")
    f.tag(24, 64, "NEC 220.14(G)")
