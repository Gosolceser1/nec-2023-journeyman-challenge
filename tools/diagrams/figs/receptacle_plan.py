"""Dwelling receptacle placement 210.52 / 210.50(C), and equipment requiring servicing 210.63."""
from nec_style import *  # noqa: F401,F403


def _wall_receptacle(f, x, y, side, r=12):
    """Plan receptacle on a wall line through (x, y); side = where the wall is: up/down/left/right."""
    dx, dy = {"up": (0, -1), "down": (0, 1), "left": (-1, 0), "right": (1, 0)}[side]
    cx, cy = x - dx * (r + 8), y - dy * (r + 8)
    f.circle(cx, cy, r, fill=BG, stroke=TEXT, sw=SW_OBJ)
    for k in (-4, 4):
        px, py = -dy * k, dx * k
        f.line(cx + dx * r + px, cy + dy * r + py, cx + dx * (r + 7) + px, cy + dy * (r + 7) + py, TEXT, 3)
    return cx, cy


def _wall_no(f, cx, cy, n):
    f.circle(cx, cy, 13, fill=PANEL_2, stroke=MUTED, sw=SW_THIN)
    f.text(cx, cy + 7, str(n), T_MIN, TEXT, bold=True)


def _run_end(f, x, y, horizontal):
    """Amber stop bar where a wall-space run meets a break; `horizontal` = the run's direction."""
    if horizontal:
        f.line(x, y - 9, x, y + 9, AMBER, SW_OBJ)
    else:
        f.line(x - 9, y, x + 9, y, AMBER, SW_OBJ)


@figure("wall_space_210-52a2", h=452, nec="210.52(A)(2)",
        records={"final-exam-#1-011": {}, "open-book-exam-#2-015": {"like": "final-exam-#1-011"}})
def wall_space(f):
    f.title("Dwelling bedroom: what counts as wall space", x=20, y=30)
    # Plan, interior faces of the walls. Walls are numbered clockwise from the
    # bottom-left corner, the order the strip below unfolds them in.
    x0, y0, x1, y1, t = 190, 66, 610, 266, 12
    f.rect(x0 - t, y0 - t, x1 - x0 + 2 * t, y1 - y0 + 2 * t, fill=PANEL_2, stroke=LINE, sw=SW_THIN)
    f.rect(x0, y0, x1 - x0, y1 - y0, fill=PANEL, stroke=LINE, sw=SW_THIN)
    cab = (y1 - 66, x0 + 36)                 # built-in cabinet on wall 1: top edge y, front x
    win = (420, 540)                         # window in wall 2
    hearth = (y0 + 50, y0 + 130)             # fireplace breast and hearth on wall 3
    clo = (520, 580)                         # closet doorway in wall 4, hinge at clo[1]
    door = (262, 342)                        # entry door in wall 4, hinge at door[0]
    # Window: glass in the wall, the floor line runs on under it.
    f.rect(win[0], y0 - t, win[1] - win[0], t, fill=BG, stroke=TEXT, sw=SW_THIN)
    f.line(win[0], y0 - t / 2, win[1], y0 - t / 2, DIM, SW_THIN)
    # Bed, faint, for scale.
    f.rect(250, y0 + 2, 120, 96, fill="none", stroke=EDGE, sw=SW_THIN, rx=6)
    for px in (258, 314):
        f.rect(px, y0 + 10, 48, 20, fill="none", stroke=EDGE, sw=SW_THIN, rx=6)
    f.text(310, y0 + 70, "bed", T_MIN, EDGE)
    # Built-in cabinet, no countertop.
    f.rect(x0, cab[0], cab[1] - x0, y1 - cab[0], fill=PANEL_2, stroke=TEXT, sw=SW_OBJ)
    f.line(x0 + 6, (cab[0] + y1) / 2, cab[1] - 6, (cab[0] + y1) / 2, EDGE, SW_THIN)
    # Fireplace: breast with the firebox, hearth in front.
    f.rect(x1 - 24, hearth[0] + 8, 24, hearth[1] - hearth[0] - 16, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ)
    f.poly([(x1 - 4, hearth[0] + 20), (x1 - 4, hearth[1] - 20), (x1 - 18, hearth[1] - 26),
            (x1 - 18, hearth[0] + 26)], "#7c2d12", TEXT, SW_THIN)
    f.rect(x1 - 52, hearth[0], 28, hearth[1] - hearth[0], fill=CONCRETE, stroke=TEXT, sw=SW_THIN, op=0.5)
    # Doorways in wall 4: opening through the wall, leaf and swing.
    for a, b, hinge in ((clo[0], clo[1], clo[1]), (door[0], door[1], door[0])):
        f.rect(a, y1, b - a, t, fill=BG)
        f.line(a, y1, a, y1 + t, TEXT, SW_THIN)
        f.line(b, y1, b, y1 + t, TEXT, SW_THIN)
        d = b - a
        free = a if hinge == b else b
        f.line(hinge, y1, hinge, y1 - d, TEXT, SW_OBJ)
        sweep = 0 if hinge == b else 1
        f.path(f"M {hinge} {y1 - d} A {d} {d} 0 0 {sweep} {free} {y1}", EDGE, SW_THIN)
    # Wall-space runs along the floor line, continued around the corners.
    o = 7
    run = dict(stroke=ZONE, sw=6)
    f.polyline([(x0 + o, cab[0]), (x0 + o, y0 + o), (x1 - o, y0 + o), (x1 - o, hearth[0])], **run)
    f.polyline([(x1 - o, hearth[1]), (x1 - o, y1 - o), (clo[1], y1 - o)], **run)
    f.line(door[1], y1 - o, clo[0], y1 - o, ZONE, 6)
    _run_end(f, x0 + o, cab[0], False)
    _run_end(f, x1 - o, hearth[0], False)
    _run_end(f, x1 - o, hearth[1], False)
    for x in (clo[1], clo[0], door[1]):
        _run_end(f, x, y1 - o, True)
    f.hatch(cab[1], y1 - o - 5, door[0] - cab[1], 10, MUTED, step=6, op=0.35)
    # Wall numbers.
    _wall_no(f, x0 - t - 20, (y0 + cab[0]) / 2, 1)
    _wall_no(f, x0 + 30, y0 + 32, 2)
    _wall_no(f, x1 - 32, y0 + 32, 3)
    _wall_no(f, (door[1] + clo[0]) / 2, y1 + t + 18, 4)
    # Callouts.
    f.text((win[0] + win[1]) / 2 - 24, y0 + 36, "window: not a break", T_MIN, MUTED)
    f.leader(x0 - t - 18, 214, x0 + 10, cab[0] + 14)
    f.lines(x0 - t - 22, 196, ["built-in cabinet", "(no countertop)"], T_MIN, TEXT, "end", gap=1.1)
    f.leader(x1 + t + 16, (hearth[0] + hearth[1]) / 2, x1 - 10, (hearth[0] + hearth[1]) / 2)
    f.text(x1 + t + 20, (hearth[0] + hearth[1]) / 2 + 7, "fireplace", T_MIN, TEXT, "start")
    f.leader(x1 + t + 16, y0 - 6, x1 - o, y0 + o)
    f.lines(x1 + t + 20, y0, ["measured", "around corners"], T_MIN, DIM, "start", gap=1.1)
    f.text((clo[0] + clo[1]) / 2, y1 + t + 24, "closet", T_MIN, MUTED)
    f.text((door[0] + door[1]) / 2, y1 + t + 24, "door", T_MIN, MUTED)
    f.leader(x0 - t - 18, y1 + 28, (cab[1] + door[0]) / 2, y1 - o)
    f.text(x0 - t - 22, y1 + 34, "too short:", T_MIN, TEXT, "end", True)
    f.text(x0 - t - 22, y1 + 56, "not wall space", T_MIN, MUTED, "end")
    # Threshold on the shortest run that still counts.
    f.ext(door[1], y1 - 14, door[1], y1 - 36)
    f.ext(clo[0], y1 - 14, clo[0], y1 - 36)
    f.dim_h(door[1], clo[0], y1 - 30)
    f.value_lines((door[1] + clo[0]) / 2, y1 - 80, ["2 ft (24 in)", "or more"], 24, gap=1.1,
                  what="the minimum width")
    f.legend([(ZONE, "wall space"), (AMBER, "break")], x1 + t + 20, y1 - 46, T_MIN)
    # The same walls unfolded along the floor line, 1-2-3-4.
    sx0, sx1, top, fl = 20, 780, 352, 404
    walls = [y1 - y0, x1 - x0, y1 - y0, x1 - x0]
    k = (sx1 - sx0) / sum(walls)
    starts = [sum(walls[:i]) for i in range(4)]

    def sx(wall, d):
        return sx0 + (starts[wall - 1] + d) * k

    f.rect(sx0, top, sx1 - sx0, fl - top, fill=PANEL, stroke=EDGE, sw=SW_THIN)
    for i in range(1, 4):
        f.dline(sx(i + 1, 0), top + 4, sx(i + 1, 0), fl - 2, EDGE, SW_THIN, 6, 5)
    f.line(sx0, fl, sx1, fl, LINE, SW_STRUCT)
    free = [(y1 - cab[0] + y1 - y0) / 2, (win[0] - x0) / 2, (hearth[1] + y1) / 2 - y0,
            (x1 - clo[0] + x1 - door[1]) / 2]
    for i, d in enumerate(free):
        _wall_no(f, sx(i + 1, d), top + 20, i + 1)

    def cabinet(a, b):
        f.rect(a, fl - 28, b - a, 28, fill=PANEL_2, stroke=TEXT, sw=SW_THIN)
        f.line(a + 3, fl - 16, b - 3, fl - 16, EDGE, SW_THIN)

    cabinet(sx(1, 0), sx(1, y1 - cab[0]))
    cabinet(sx(4, x1 - x0 - (cab[1] - x0)), sx(4, x1 - x0))
    wa, wb = sx(2, win[0] - x0), sx(2, win[1] - x0)
    f.rect(wa, top + 8, wb - wa, fl - top - 30, fill=BG, stroke=TEXT, sw=SW_THIN)
    f.line((wa + wb) / 2, top + 8, (wa + wb) / 2, fl - 22, TEXT, SW_THIN)
    ha, hb = sx(3, hearth[0] - y0), sx(3, hearth[1] - y0)
    f.rect(ha + 4, top + 4, hb - ha - 8, fl - top - 4, fill=PANEL_2, stroke=TEXT, sw=SW_THIN)
    f.rect((ha + hb) / 2 - 12, fl - 22, 24, 18, fill="#7c2d12", stroke=TEXT, sw=SW_THIN)
    f.rect(ha, fl - 4, hb - ha, 4, fill=CONCRETE)
    for a, b in ((clo[1], clo[0]), (door[1], door[0])):
        da, db = sx(4, x1 - a), sx(4, x1 - b)
        f.rect(da, top + 6, db - da, fl - top - 6, fill=BG, stroke=TEXT, sw=SW_THIN)
    by = fl + 10
    runs = [(sx(1, y1 - cab[0]), sx(3, hearth[0] - y0)),
            (sx(3, hearth[1] - y0), sx(4, x1 - clo[1])),
            (sx(4, x1 - clo[0]), sx(4, x1 - door[1]))]
    for a, b in runs:
        f.line(a, by, b, by, ZONE, 6)
        _run_end(f, a, by, True)
        _run_end(f, b, by, True)
    sa, sb = sx(4, x1 - door[0]), sx(4, x1 - cab[1])
    f.hatch(sa, by - 5, sb - sa, 10, MUTED, step=6, op=0.35)
    f.text(sx0, fl + 40, "the same walls unfolded along the floor line", T_MIN, MUTED, "start")
    f.leader(sb - 40, fl + 33, (sa + sb) / 2, by + 6)
    f.value(sb - 46, fl + 40, "less than 2 ft (24 in)", T_MIN, TEXT, "end", what="the too-short width")
    f.tag(f.w - 20, 30, "NEC 210.52(A)(2)", anchor="end")


@figure("garage_receptacles_210-52g", h=430, nec="210.52(G)(1)",
        records={"final-exam-#1-022": {}, "open-book-exam-#3-017": {"like": "final-exam-#1-022"}})
def garage_receptacles(f):
    f.title("Attached two-car garage (plan view)", y=34)
    gx0, top, gx1, gy1 = 160, 80, 640, 360
    f.rect(gx0, top, gx1 - gx0, gy1 - top, fill=PANEL, op=0.6)
    for a, b in (((gx0, top), (gx1, top)), ((gx0, top), (gx0, gy1)), ((gx1, top), (gx1, gy1))):
        f.line(a[0], a[1], b[0], b[1], LINE, SW_STRUCT)
    f.dline(gx0 + 14, gy1, gx1 - 14, gy1, EDGE, SW_OBJ, 16, 8)
    f.text((gx0 + gx1) / 2, gy1 + 30, "garage door", T_NOTE, MUTED)
    bay_x = (gx0 + gx1) / 2
    f.dline(bay_x, 200, bay_x, gy1 - 8, MUTED, SW_THIN)
    for cx in ((gx0 + bay_x) / 2, (bay_x + gx1) / 2):
        f.rect(cx - 50, 180, 100, 170, fill=PANEL_2, stroke=EDGE, sw=SW_OBJ, rx=18)
        f.text(cx, 272, "car", T_NOTE, MUTED)
        _wall_receptacle(f, cx, top, "up")
    f.mask(gx0 + 6, top - 4, gx1 - gx0 - 12, 44, what="the receptacles drawn in each bay")
    f.value(bay_x, 150, "one in each vehicle bay", T_NOTE, what="the one-per-bay rule")
    f.tag(f.w - 24, f.h - 12, "NEC 210.52(G)(1)", anchor="end")


@figure("hallway_receptacle_210-52h", h=360, nec="210.52(H)",
        records={"final-exam-#1-031": {}, "open-book-exam-#3-003": {"like": "final-exam-#1-031"}})
def hallway_receptacle(f):
    f.title("Dwelling hallway (plan view)", y=34)
    hx0, hx1, y0, y1 = 80, 720, 120, 220
    f.rect(hx0, y0, hx1 - hx0, y1 - y0, fill=PANEL, op=0.6)
    f.line(hx0, y0, hx1, y0, LINE, SW_STRUCT)
    f.line(hx0, y1, hx1, y1, LINE, SW_STRUCT)
    cy = (y0 + y1) / 2
    f.dline(hx0 + 10, cy + 14, hx1 - 10, cy + 14, MUTED, SW_THIN, 12, 8)
    f.text(hx0 + 160, cy + 2, "HALLWAY", T_LABEL, TEXT, bold=True)
    f.text(hx0 + 400, cy + 2, "(length on the centerline)", T_NOTE, MUTED)
    _wall_receptacle(f, 600, y1, "down")
    f.ext(hx0 + 2, y1 + 6, hx0 + 2, 276)
    f.ext(hx1 - 2, y1 + 6, hx1 - 2, 276)
    f.dim_h(hx0 + 2, hx1 - 2, 266)
    f.value(400, 306, "10 ft or more: one receptacle", 26, label="? ft", what="the hallway length")
    f.tag(f.w - 24, 70, "NEC 210.52(H)", anchor="end")


@figure("appliance_outlet_210-50c", h=380, nec="210.50(C)",
        records=["final-exam-#3-035", "open-book-exam-#1-022"])
def appliance_outlet(f):
    f.title("Laundry: appliance receptacle outlet (plan view)", y=34)
    x0, top, x1, y1 = 80, 80, 720, 320
    f.rect(x0, top, x1 - x0, y1 - top, fill=PANEL, op=0.6)
    for a, b in (((x0, top), (x1, top)), ((x0, top), (x0, y1)), ((x1, top), (x1, y1))):
        f.line(a[0], a[1], b[0], b[1], LINE, SW_STRUCT)
    wx0, wx1 = 120, 240
    f.rect(wx0, top + 10, wx1 - wx0, 110, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=6)
    f.circle((wx0 + wx1) / 2, top + 65, 40, fill="none", stroke=EDGE, sw=SW_THIN)
    f.text((wx0 + wx1) / 2, top + 72, "washer", T_NOTE, TEXT, bold=True)
    rx, ry = _wall_receptacle(f, 560, top, "up")
    f.ext(wx1, top + 126, wx1, 240)
    f.ext(rx, ry + 16, rx, 240)
    f.dim_h(wx1, rx, 230)
    f.value((wx1 + rx) / 2, 270, "within 6 ft (72 in)", 26, label="? ft", what="the distance to the appliance")
    f.text(80, 350, "measured from the intended appliance location", T_MIN, MUTED, "start")
    f.tag(f.w - 24, f.h - 10, "NEC 210.50(C)", anchor="end")


@figure("equipment_receptacle_210-63", h=450, nec="210.63",
        records={"final-exam-#3-049": {}, "open-book-exam-#1-005": {}, "final-exam-#1-003": {},
                 "open-book-exam-#1-016": {}})
def equipment_receptacle(f):
    dist_rec = ["final-exam-#3-049", "open-book-exam-#1-005"]
    room_rec = ["final-exam-#1-003", "open-book-exam-#1-016"]
    ceil, floor, x0, x1 = 80, 380, 40, 760
    f.zone(x0 + 8, ceil + 8, x1 - x0 - 16, floor - ceil - 16, ZONE, 0.06)
    f.ceiling(ceil, x0, x1)
    f.floor(floor, x0, x1)
    f.wall(x0, ceil, floor)
    f.wall(x1, ceil, floor)
    f.text(400, 40, "EQUIPMENT ROOM (other than a 1- or 2-family dwelling)", T_NOTE, MUTED, bold=True)
    f.value(400, 124, "same room or area", 28, records=room_rec, label="?")
    ex0, ex1 = 90, 250
    f.panel(ex0, 170, ex1 - ex0, floor - 170, label=None, breakers=5)
    f.lines((ex0 + ex1) / 2, floor + 30, ["service equipment", "or MCC"], T_NOTE, TEXT, bold=True, gap=1.1)
    rx, ry = 530, 264
    f.receptacle(rx, ry, 52, gfci=True)
    f.lines(rx, ry + 58, ["125 V, 15/20 A", "GFCI", "accessible location"], T_MIN, TEXT, gap=1.15)
    f.ext(ex1 + 4, 200, ex1 + 4, 232)
    f.ext(rx - 20, ry - 30, rx - 20, 232)
    f.dim_h(ex1 + 4, rx - 20, 222)
    f.value_lines((ex1 + rx - 20) / 2, 204, ["within 25 ft", "(7.5 m)"], 28, records=dist_rec + room_rec,
                  label="?", gap=1.25)
    # HVAC air handler: (A) wants its receptacle on the same level.
    ux0, ux1, uy0 = 636, 740, 236
    f.rect(ux0, uy0, ux1 - ux0, floor - uy0, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=4)
    f.rect(ux0 + 10, uy0 + 12, ux1 - ux0 - 20, 56, fill=BG, stroke=EDGE, sw=SW_THIN, rx=3)
    for k in range(1, 6):
        f.line(ux0 + 14, uy0 + 12 + k * 9.3, ux1 - 14, uy0 + 12 + k * 9.3, EDGE, 2)
    f.line(ux0 + 6, uy0 + 82, ux1 - 6, uy0 + 82, EDGE, SW_THIN)
    f.rect(ux1 - 30, uy0 + 92, 14, 20, fill=EDGE, rx=2)
    f.lines(ux1 - 6, 178, ["HVAC unit:", "same level (A)"], T_MIN, MUTED, "end", True, gap=1.15)
    f.tag(f.w - 20, f.h - 14, "NEC 210.63", anchor="end")


@figure("gfci_service_210-8e", h=400, nec="210.8(E)", when="after", records=["open-book-exam-#1-018"])
def gfci_service(f):
    f.title("Receptacle for equipment requiring servicing", y=34)
    f.floor(340, 20, f.w - 20)
    ux0, ux1, uy0 = 120, 320, 140
    f.rect(ux0, uy0, ux1 - ux0, 340 - uy0, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=4)
    f.rect(ux0 + 14, uy0 + 16, ux1 - ux0 - 28, 80, fill=BG, stroke=EDGE, sw=SW_THIN, rx=3)
    for k in range(1, 7):
        f.line(ux0 + 18, uy0 + 16 + k * 11.4, ux1 - 18, uy0 + 16 + k * 11.4, EDGE, 2)
    f.text((ux0 + ux1) / 2, uy0 - 14, "HVAC unit", T_NOTE, TEXT, bold=True)
    f.receptacle(420, 240, 60, gfci=True)
    f.text(420, 300, "service receptacle", T_NOTE, TEXT, bold=True)
    f.card(500, 110, 280, 170)
    f.lines(516, 160, ["receptacles for", "equipment requiring", "servicing: GFCI"], T_NOTE, OK, "start", True,
            gap=1.25)
    f.highlight(506, 116, 268, 158)
