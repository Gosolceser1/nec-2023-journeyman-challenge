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


def _door_gap(f, x0, x1, y):
    """Doorway in a horizontal wall: gap plus a door leaf hinged at x0, swung open into the room above."""
    d = x1 - x0
    f.line(x0, y, x1, y, BG, SW_STRUCT + 4)
    f.line(x0, y, x0, y - d, TEXT, SW_OBJ)
    f.path(f"M {x0} {y - d} A {d} {d} 0 0 1 {x1} {y}", EDGE, SW_THIN)


@figure("wall_space_210-52a", h=420, nec="210.52(A)",
        records={"final-exam-#1-011": {}, "open-book-exam-#2-015": {"like": "final-exam-#1-011"}})
def wall_space(f):
    f.title("Dwelling bedroom: what counts as wall space (plan view)", y=34)
    x0, y0, x1, y1 = 80, 90, 720, 330
    f.rect(x0, y0, x1 - x0, y1 - y0, fill=PANEL, op=0.6)
    for a, b in (((x0, y0), (x1, y0)), ((x0, y0), (x0, y1)), ((x1, y0), (x1, y1)), ((x0, y1), (x1, y1))):
        f.line(a[0], a[1], b[0], b[1], LINE, SW_STRUCT)
    f.text(400, 150, "BEDROOM", T_LABEL, TEXT, bold=True)
    d0, d1 = 110, 190
    _door_gap(f, d0, d1, y1)
    f.text(d0 + 8, y1 - 12, "door", T_MIN, MUTED, "start")
    _wall_receptacle(f, 520, y1, "down")
    f.ext(d1, y1 + 6, d1, 380)
    f.ext(x1 - 2, y1 + 6, x1 - 2, 380)
    f.dim_h(d1, x1 - 2, 370)
    f.text((d1 + x1) / 2, 404, "wall space: unbroken along the floor line", T_NOTE, MUTED)
    f.value_lines(400, 220, ["2 ft (24 in)", "or more wide"], 26, label="? in", what="the minimum width")
    f.tag(f.w - 24, 64, "NEC 210.52(A)", anchor="end")


@figure("garage_receptacles_210-52g", h=430, nec="210.52(G)",
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
    f.tag(f.w - 24, f.h - 12, "NEC 210.52(G)", anchor="end")


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
