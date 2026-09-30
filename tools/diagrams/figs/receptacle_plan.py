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
    """Doorway in a horizontal wall: gap plus a quarter swing into the room below."""
    f.line(x0, y, x1, y, BG, SW_STRUCT + 4)
    f.line(x0, y, x0, y + (x1 - x0), EDGE, SW_THIN)
    f.path(f"M {x0} {y + (x1 - x0)} A {x1 - x0} {x1 - x0} 0 0 0 {x1} {y}", EDGE, SW_THIN)


@figure("dwelling_receptacles_210-52", h=500, nec="210.52(A)(2), 210.52(G)(1), 210.52(H), 210.50(C)",
        records={"final-exam-#1-011": {}, "final-exam-#1-022": {}, "final-exam-#1-031": {}, "final-exam-#3-035": {},
                 "open-book-exam-#1-022": {}, "open-book-exam-#2-015": {"like": "final-exam-#1-011"},
                 "open-book-exam-#3-003": {"like": "final-exam-#1-031"},
                 "open-book-exam-#3-017": {"like": "final-exam-#1-022"}})
def dwelling_plan(f):
    wall_rec = ["final-exam-#1-011"]
    garage_rec = ["final-exam-#1-022"]
    hall_rec = ["final-exam-#1-031"]
    appl_rec = ["final-exam-#3-035", "open-book-exam-#1-022"]
    top, gx0, hx0, lx0, hx1 = 60, 30, 300, 540, 780
    hall_y0, hall_y1, garage_y1 = 280, 360, 400
    # Rooms.
    f.rect(gx0, top, hx0 - gx0, garage_y1 - top, fill=PANEL, op=0.6)
    f.rect(hx0, top, hx1 - hx0, hall_y1 - top, fill=PANEL, op=0.6)
    for x0, y0, x1, y1 in ((gx0, top, hx1, top), (gx0, top, gx0, garage_y1), (hx0, top, hx0, garage_y1),
                           (hx1, top, hx1, hall_y1), (hx0, hall_y1, hx1, hall_y1),
                           (hx0, hall_y0, hx1, hall_y0), (lx0, top, lx0, hall_y0)):
        f.line(x0, y0, x1, y1, LINE, SW_STRUCT)
    # Garage: two bays, door along the bottom.
    f.dline(gx0 + 14, garage_y1, hx0 - 14, garage_y1, EDGE, SW_OBJ, 16, 8)
    f.text((gx0 + hx0) / 2, garage_y1 + 30, "garage door", T_NOTE, MUTED)
    bay_x = (gx0 + hx0) / 2
    f.dline(bay_x, 200, bay_x, garage_y1 - 8, MUTED, SW_THIN)
    for cx in ((gx0 + bay_x) / 2, (bay_x + hx0) / 2):
        f.rect(cx - 38, 222, 76, 150, fill=PANEL_2, stroke=EDGE, sw=SW_OBJ, rx=16)
        f.text(cx, 304, "car", T_NOTE, MUTED)
    f.lines(bay_x, 202, ["ATTACHED", "GARAGE"], T_LABEL, TEXT, bold=True, gap=1.0)
    for cx in ((gx0 + bay_x) / 2, (bay_x + hx0) / 2):
        _wall_receptacle(f, cx, top, "up")
    f.lines(bay_x, 128, ["one in each", "vehicle bay"], T_NOTE, OK, bold=True, gap=1.1)
    f.mask(gx0 + 6, top - 14, hx0 - gx0 - 12, 130, records=garage_rec,
           what="receptacles drawn one per bay, and the one-per-bay rule")
    # Bedroom: wall space between the doorway and the corner.
    f.text((hx0 + lx0) / 2, 100, "BEDROOM", T_LABEL, TEXT, bold=True)
    d0, d1 = 316, 372
    _door_gap(f, d0, d1, hall_y0)
    f.line(d0, hall_y0 - 1, d0, hall_y0 - (d1 - d0), EDGE, SW_THIN)
    _wall_receptacle(f, 490, hall_y0, "down")
    f.ext(d1, hall_y0 - 6, d1, 196)
    f.ext(lx0 - 4, hall_y0 - 6, lx0 - 4, 196)
    f.dim_h(d1, lx0 - 4, 206)
    f.text((d1 + lx0) / 2 - 20, 240, "wall space", T_NOTE, MUTED)
    f.value_lines((d1 + lx0) / 2, 148, ["2 ft (24 in)", "or more"], 26, records=wall_rec, label="? in")
    f.text(344, 268, "door", T_MIN, MUTED)
    # Laundry: appliance outlet near the washer.
    f.text(lx0 + 120, 264, "LAUNDRY", T_LABEL, TEXT, bold=True)
    wx0, wx1 = lx0 + 16, lx0 + 96
    f.rect(wx0, top + 10, wx1 - wx0, 74, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=6)
    f.text((wx0 + wx1) / 2, top + 54, "washer", T_MIN, TEXT, bold=True)
    rx, ry = _wall_receptacle(f, 730, top, "up")
    f.ext(wx1, top + 90, wx1, 180)
    f.ext(rx, ry + 16, rx, 180)
    f.dim_h(wx1, rx, 170)
    f.value_lines((wx1 + rx) / 2 - 4, 200, ["within", "6 ft (72 in)"], 26, records=appl_rec, label="? ft")
    _door_gap(f, lx0 + 20, lx0 + 76, hall_y0)
    # Hallway: length along the centerline.
    cy = (hall_y0 + hall_y1) / 2
    f.dline(hx0 + 10, cy + 14, hx1 - 10, cy + 14, MUTED, SW_THIN, 12, 8)
    f.text(hx0 + 150, cy + 2, "HALLWAY", T_LABEL, TEXT, bold=True)
    f.text(hx0 + 330, cy + 2, "(centerline)", T_NOTE, MUTED)
    _wall_receptacle(f, 720, hall_y1, "down")
    f.ext(hx0 + 2, hall_y1 + 6, hx0 + 2, 396)
    f.ext(hx1 - 2, hall_y1 + 6, hx1 - 2, 396)
    f.dim_h(hx0 + 2, hx1 - 2, 386)
    f.value((hx0 + hx1) / 2, 424, "10 ft or more", 28, records=hall_rec, label="? ft")
    f.tag(f.w - 20, f.h - 18, "NEC 210.52, 210.50(C)", anchor="end")


@figure("equipment_receptacle_210-63", h=450, nec="210.63, 210.63(A), 210.63(B)(1), 210.63(B)(2)",
        records={"final-exam-#3-049": {}, "open-book-exam-#1-005": {}, "final-exam-#1-003": {},
                 "open-book-exam-#1-016": {}, "open-book-exam-#1-018": {"when": "after"}})
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
    rx, ry = 620, 264
    f.receptacle(rx, ry, 52, gfci=True)
    f.lines(rx, ry + 58, ["125 V, 15/20 A", "GFCI 210.8(E)"], T_NOTE, TEXT, gap=1.1)
    f.text(rx, floor + 30, "accessible location", T_NOTE, MUTED)
    f.ext(ex1 + 4, 200, ex1 + 4, 232)
    f.ext(rx - 20, ry - 30, rx - 20, 232)
    f.dim_h(ex1 + 4, rx - 20, 222)
    f.value_lines((ex1 + rx - 20) / 2, 204, ["within 25 ft", "(7.5 m)"], 28, records=dist_rec + room_rec,
                  label="?", gap=1.25)
    f.text(400, 346, "HVAC/R: same level (A)", T_NOTE, MUTED)
    f.tag(f.w - 20, f.h - 14, "NEC 210.63", anchor="end")
