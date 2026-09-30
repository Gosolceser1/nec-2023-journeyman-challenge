"""Receptacle placement along counters and windows: kitchen counter spacing and height, the
small-appliance circuits, bathroom sink counters, front and back outdoor outlets, show windows."""
from nec_style import *  # noqa: F401,F403

WALL_LINE = ["open-book-exam-#2-007"]
HEIGHT = ["open-book-exam-#3-001"]
SABC = ["final-exam-#4-016"]


def _counter_receptacle(f, x, y):
    f.receptacle(x, y, 36)


@figure("kitchen_counter_210-52c", h=500, nec="210.52(B)(1), 210.52(B)(2), 210.52(C)(1), 210.52(C)(3)",
        records={WALL_LINE[0]: {}, HEIGHT[0]: {}, SABC[0]: {"when": "after"}})
def kitchen_counter(f):
    f.title("Kitchen counter receptacles (elevation)", y=34)
    top, floor, x0, x1, ppi = 300, 420, 40, 480, 3.5
    f.rect(x0, 70, x1 - x0, 80, fill=PANEL, stroke=EDGE, sw=SW_THIN)
    for x in (150, 260, 370):
        f.line(x, 70, x, 150, EDGE, SW_THIN)
    f.text((x0 + x1) / 2, 118, "upper cabinets", T_MIN, MUTED)
    f.rect(x0, top, x1 - x0, 14, fill=LINE, stroke=TEXT, sw=SW_THIN)
    f.rect(x0 + 6, top + 14, x1 - x0 - 12, floor - top - 14, fill=PANEL, stroke=EDGE, sw=SW_THIN)
    f.path(f"M 200 {top} q 0 30 30 30 h 50 q 30 0 30 -30", TEXT, SW_THIN)
    f.text(255, top - 10, "sink", T_MIN, MUTED)
    f.floor(floor, 20, 500)
    ry = top - 60
    xs = [x0 + 24 * ppi, x0 + 72 * ppi, x0 + 114 * ppi]
    for x in xs:
        _counter_receptacle(f, x, ry)
    # Wall line: every point within the limit of a receptacle.
    f.ext(x0, top - 4, x0, 186)
    f.ext(xs[0], ry - 20, xs[0], 186)
    f.dim_h(x0, xs[0], 196)
    f.value((x0 + xs[0]) / 2, 182, "24 in", 26, pad=5, records=WALL_LINE, what="the wall-line distance")
    f.ext(xs[1], ry - 20, xs[1], 186)
    f.dim_h(xs[0], xs[1], 196)
    f.text((xs[0] + xs[1]) / 2, 184, "midpoint", T_MIN, MUTED)
    f.line((xs[0] + xs[1]) / 2, 204, (xs[0] + xs[1]) / 2, top - 4, MUTED, SW_THIN)
    # Height above the counter.
    hx = xs[1] + 40
    f.ext(xs[1] + 14, ry, hx + 8, ry)
    f.dim_v(hx, ry, top)
    f.value(hx + 12, ry + 34, "20 in", 26, anchor="start", pad=5, records=HEIGHT, what="the height above the counter")
    f.text(hx + 12, ry + 58, "max", T_MIN, MUTED, "start")
    f.lines(x0, 452, ["No point along the counter wall line is farther", "than the limit from a receptacle outlet."],
            T_MIN, TEXT, "start", gap=1.1)
    # Small-appliance circuits.
    cx = 520
    f.rect(cx, 60, 260, 380, fill=PANEL, stroke=EDGE, sw=SW_THIN, rx=8)
    f.text(cx + 14, 92, "Small-appliance", T_NOTE, TEXT, "start", True)
    f.text(cx + 14, 118, "circuits (two or more)", T_NOTE, TEXT, "start", True)
    f.lines(cx + 14, 156, ["serve the counters and", "the walls of the kitchen,", "pantry, breakfast room", "and dining room"],
            T_MIN, TEXT, "start", gap=1.15)
    f.line(cx + 14, 256, cx + 246, 256, EDGE, 1)
    f.text(cx + 14, 286, "Other outlets allowed:", T_MIN, OK, "start", True)
    f.lines(cx + 14, 316, ["- an electric clock outlet", "- gas range, oven or", "  cooktop accessories"], T_MIN,
            TEXT, "start", gap=1.15)
    f.text(cx + 14, 414, "nothing else", T_MIN, NO, "start", True)
    f.highlight(cx + 6, 266, 248, 106, records=SABC)
    f.tag(f.w - 24, f.h - 10, "NEC 210.52(B), (C)", anchor="end")


BATH = ["final-exam-#4-010"]
FRONT_BACK = ["final-exam-#4-015"]


@figure("bath_counter_outdoor_210-52d_e1", h=480, nec="210.52(D), 210.52(E)(1)", records=BATH + FRONT_BACK)
def bath_outdoor(f):
    f.title("Bathroom counter and outdoor receptacles", y=34)
    # Bathroom counter, elevation.
    top, floor, x0, x1, ppf = 250, 360, 30, 380, 50.0
    f.rect(x0, top, x1 - x0, 12, fill=LINE, stroke=TEXT, sw=SW_THIN)
    f.rect(x0 + 6, top + 12, x1 - x0 - 12, floor - top - 12, fill=PANEL, stroke=EDGE, sw=SW_THIN)
    f.floor(floor, 20, 400)
    sx0, sx1 = 150, 250
    f.path(f"M {sx0} {top} q 0 34 34 34 h 32 q 34 0 34 -34", TEXT, SW_THIN)
    f.text((sx0 + sx1) / 2, top - 10, "sink", T_MIN, MUTED)
    f.ext(x0, top + 16, x0, floor + 30)
    f.ext(x1, top + 16, x1, floor + 30)
    f.dim_h(x0, x1, floor + 22)
    f.text((x0 + x1) / 2, floor + 56, "7 ft counter", T_NOTE, DIM, bold=True)
    zx0, zx1 = sx0 - 3 * ppf, sx1 + 3 * ppf
    f.add(f'<rect x="{max(x0, zx0):.1f}" y="120" width="{min(x1, zx1) - max(x0, zx0):.1f}" height="{top - 120}" '
          f'fill="{ZONE}" fill-opacity="0.10" stroke="{ZONE}" stroke-width="2" stroke-dasharray="8 6"/>')
    f.lines(x0 + 6, 146, ["within 3 ft of the outside", "edge of each sink"], T_MIN, DIM, "start", gap=1.1)
    f.receptacle(310, 208, 38)
    f.value(310, 104, "one outlet", T_NOTE, pad=5, records=BATH, what="how many receptacles")
    f.mask(284, 180, 52, 56, records=BATH, what="the receptacle drawn on the wall")
    # Outdoor: front and back, plan view.
    hx0, hy0, hx1, hy1 = 470, 110, 740, 270
    f.rect(hx0, hy0, hx1 - hx0, hy1 - hy0, fill=PANEL, stroke=LINE, sw=SW_STRUCT)
    f.text((hx0 + hx1) / 2, (hy0 + hy1) / 2 + 8, "house", T_LABEL, TEXT, bold=True)
    f.text((hx0 + hx1) / 2, hy0 - 44, "BACK", T_NOTE, MUTED, bold=True)
    f.text((hx0 + hx1) / 2, hy1 + 56, "FRONT", T_NOTE, MUTED, bold=True)
    f.plan_receptacle(560, hy0 - 16, gfci=True)
    f.plan_receptacle(650, hy1 + 16, gfci=True)
    f.lines(430, 362, ["one at the front and one at the back,", "readily accessible from grade,",
                       "6 1/2 ft or less above grade"], T_MIN, TEXT, "start", gap=1.1)
    f.value(605, 442, "one- and two-family dwellings", T_MIN, pad=5, records=FRONT_BACK,
            what="which buildings the rule covers")
    f.tag(24, f.h - 10, "NEC 210.52(D) and (E)")


WINDOW = ["open-book-exam-#2-009"]
WINDOW_VA = ["final-exam-#4-012"]


@figure("show_window_210-62_220-14g", h=470, nec="210.62, 220.14(G)", records=WINDOW + WINDOW_VA)
def show_window(f):
    f.title("Store show window (elevation)", y=34)
    ppf, x0, x1, wtop, wbot = 26.0, 50, 466, 200, 380
    f.rect(20, 120, 476, 280, fill=PANEL, op=0.5, stroke=LINE, sw=SW_THIN)
    f.rect(x0, wtop, x1 - x0, wbot - wtop, fill=WATER, stroke=WATER_EDGE, sw=SW_OBJ)
    f.text((x0 + x1) / 2, 300, "show window", T_LABEL, TEXT, bold=True)
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
    f.value(hx - 12, ry + 30, "18 in", 26, anchor="end", pad=5, records=WINDOW, what="the distance from the top")
    f.ext(x0, wbot + 4, x0, 420)
    f.ext(x1, wbot + 4, x1, 420)
    f.dim_h(x0, x1, 412)
    f.text((x0 + x1) / 2, 446, "16 ft along the base", T_NOTE, DIM, bold=True)
    # Load card.
    cx = 516
    f.rect(cx, 110, 264, 290, fill=PANEL, stroke=EDGE, sw=SW_THIN, rx=8)
    f.text(cx + 14, 144, "Show window load", T_NOTE, TEXT, "start", True)
    f.value(cx + 14, 194, "200 VA", 30, anchor="start", pad=6, records=WINDOW_VA, what="the load per foot")
    f.text(cx + 14, 226, "per linear foot,", T_MIN, TEXT, "start")
    f.text(cx + 14, 250, "measured along the base", T_MIN, TEXT, "start")
    f.text(cx + 14, 300, "this window:", T_MIN, MUTED, "start", True)
    f.value(cx + 14, 336, "16 ft x 200 VA", T_NOTE, anchor="start", pad=5, records=WINDOW_VA, what="the worked load")
    f.value(cx + 14, 372, "= 3,200 VA", T_NOTE, anchor="start", pad=5, records=WINDOW_VA, what="the worked load")
    f.tag(f.w - 24, f.h - 10, "NEC 210.62, 220.14(G)", anchor="end")
