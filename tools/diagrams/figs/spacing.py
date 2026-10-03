"""Clearances and spacings: nipple fill, box depth, gutter bare parts, extensions,
resistors, fire pump parts, wiring above heated ceilings."""
from nec_style import *  # noqa: F401,F403


def _locknut(f, x, y, h=30):
    """Hex locknut on a raceway where it enters an enclosure wall at x (front view)."""
    f.rect(x - 6, y - h / 2, 12, h, fill=EDGE, stroke=TEXT, sw=1.5, rx=2)
    f.line(x - 6, y - h * 0.18, x + 6, y - h * 0.18, BG, 1)
    f.line(x - 6, y + h * 0.18, x + 6, y + h * 0.18, BG, 1)


def _insulator(f, x, top, bot, w=20):
    """Standoff insulator from `bot` (mounting surface) up to `top`: body with skirts."""
    f.rect(x - w * 0.3, top, w * 0.6, bot - top, fill=PANEL_2, stroke=LINE, sw=1.5, rx=2)
    n = 3
    for k in range(n):
        yy = top + (bot - top) * (k + 0.7) / (n + 0.4)
        f.rect(x - w / 2, yy - 4, w, 8, fill=PANEL_2, stroke=LINE, sw=1.5, rx=4)


@figure("nipple_fill_ch9_note4", h=450, nec="Chapter 9, Note 4",
        records={"final-exam-#1-067": {"when": "after"}, "open-book-exam-#6-014": {"like": "final-exam-#1-067"}})
def nipple_fill(f):
    y = 200
    f.box(130, y, 150)
    f.text(130, y + 75 + 30, "box", T_LABEL, TEXT, bold=True)
    f.panel(560, 90, 160, 256, label="cabinet")
    f.conduit(225, y, 540, y, width=24)
    _locknut(f, 211, y, 36)
    _locknut(f, 554, y, 36)
    f.ext(205, y - 26, 205, 92)
    f.ext(560, y - 26, 560, 92)
    f.dim_h(205, 560, 100)
    f.text(382, 80, "600 mm (24 in) max", 28, DIM, bold=True)
    f.text(382, 166, "nipple", T_LABEL, TEXT, bold=True)
    # Section through the nipple: seven conductors, about 60 percent of the area.
    cx, cy, r = 300, 300, 40
    f.circle(cx, cy, r + 5, fill=STEEL, stroke=LINE, sw=SW_THIN)
    f.circle(cx, cy, r, fill=BG)
    cols = (WIRE_HOT, WIRE_NEU, WIRE_HOT, WIRE_NEU, WIRE_HOT, WIRE_NEU, WIRE_GND)
    for k, col in enumerate(cols):
        if k == 6:
            px, py = cx, cy
        else:
            a = math.radians(30 + 60 * k)
            px, py = cx + 23 * math.cos(a), cy + 23 * math.sin(a)
        f.circle(px, py, 11.5, fill=col, stroke=BG, sw=1.5)
    f.text(cx, cy + r + 34, "section", T_NOTE, MUTED)
    f.value(360, 310, "fill up to 60%", 30, anchor="start", records=None)
    f.text(40, 422, "310.15(C)(1) adjustment factors need not apply", T_NOTE, MUTED, "start")
    f.tag(f.w - 24, f.h - 10, "NEC Chapter 9, Note 4", anchor="end")


@figure("box_depth_314-24b5", h=450, nec="314.24(B)(5)", records=["final-exam-#3-034"])
def box_depth(f):
    face, back, wt = 282, 470, 18
    bt, bb = 150, 330
    f.text(40, 50, "side section", T_NOTE, MUTED, "start")
    # Drywall around the box opening; the box front is flush with the wall face.
    for a, b in ((70, bt), (bb, 350)):
        f.rect(face, a, wt, b - a, fill=PANEL_2, stroke=LINE, sw=SW_THIN)
    f.text(face - 50, 100, "wall", T_NOTE, MUTED, "end")
    f.rect(face, bt, back - face, bb - bt, fill=PANEL, stroke=TEXT, sw=SW_OBJ + 1)
    # Device: yoke on the wall face, body in the box, face through the plate.
    f.rect(face - 6, 166, 6, 148, fill=STEEL, stroke=TEXT, sw=1.5)
    f.rect(face - 18, 136, 12, 208, fill=PANEL_2, stroke=TEXT, sw=SW_THIN, rx=3)
    f.text(face - 44, 316, "plate", T_NOTE, MUTED, "end")
    f.rect(face - 32, 206, 26, 68, fill=PANEL_2, stroke=TEXT, sw=SW_THIN, rx=4)
    f.rect(face, 194, 96, 92, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=6)
    f.text(face + 48, 248, "device", T_MIN, TEXT, bold=True)
    for ty in (194, 286):
        f.circle(face + 64, ty, 6, fill=CLAMP, stroke=TEXT, sw=1.5)
    # 14 AWG cable in through a clamp in the back of the box.
    f.rect(back - 14, 222, 14, 36, fill=EDGE, stroke=TEXT, sw=1.5, rx=2)
    f.cable([(720, 112), (600, 112), (back + 40, 228), (back, 234), (face + 104, 234), (face + 70, 194)],
            WIRE_HOT, 5)
    f.cable([(720, 126), (606, 126), (back + 46, 248), (back, 248), (face + 104, 248), (face + 70, 286)],
            WIRE_NEU, 5)
    f.text(720, 92, "14 AWG", T_LABEL, TEXT, "end", True)
    f.text(720, 160, "or smaller", T_NOTE, MUTED, "end")
    f.text(back + 20, 316, "device box", T_LABEL, TEXT, "start", True)
    f.ext(face, 334, face, 382)
    f.ext(back, 334, back, 382)
    f.dim_h(face, back, 372)
    f.text((face + back) / 2, 360, "internal depth", T_NOTE, DIM, bold=True)
    f.value(face - 10, 420, "23.8 mm (15/16 in) min", 30, anchor="start", records=None, label="? min")
    f.tag(40, f.h - 14, "NEC 314.24(B)(5)")


@figure("gutter_bare_parts_366-100e", h=500, nec="366.100(E)", records=["final-exam-#5-048"])
def gutter_bare_parts(f):
    gx0, gx1, gy0, gy1 = 40, 760, 120, 380
    one = 56
    f.text(40, 44, "auxiliary gutter, section", T_NOTE, MUTED, "start")
    f.rect(gx0, gy0, gx1 - gx0, gy1 - gy0, fill=PANEL, stroke=LINE, sw=6)
    inner_b, inner_r = gy1 - 3, gx1 - 3
    # Mounted on the same insulating surface.
    f.rect(80, inner_b - 32, 250, 32, fill=PANEL_2, stroke=EDGE, sw=SW_THIN)
    ax, bx = 120, 120 + 24 + 2 * one
    for x in (ax, bx):
        f.rect(x, inner_b - 112, 24, 80, fill=ROD, stroke=TEXT, sw=SW_THIN)
        f.circle(x + 12, inner_b - 46, 4, fill=CLAMP, stroke=TEXT, sw=1)
    f.dim_h(ax + 24, bx, inner_b - 132)
    f.text((ax + 24 + bx) / 2, inner_b - 150, "50 mm (2 in)", 28, DIM, bold=True)
    f.lines(40, 420, ["on the same surface", "(insulating base)"], T_NOTE, TEXT, "start", True)
    # Held free in the air, on standoff insulators.
    dx = inner_r - one - 24
    cx = dx - one - 24
    top = 196
    for x in (cx, dx):
        _insulator(f, x + 12, top + 80, inner_b)
        f.rect(x, top, 24, 80, fill=ROD, stroke=TEXT, sw=SW_THIN)
    fy = top - 20
    f.dim_h(cx + 24, dx, fy)
    f.text(536, 84, "held free in the air", T_NOTE, TEXT, "end", True)
    f.value(560, 84, "25 mm (1 in)", 28, anchor="start", records=None)
    f.leader(650, 92, (cx + 24 + dx) / 2, fy - 6, DIM)
    my = top + 40
    f.dim_h(dx + 24, inner_r, my)
    f.text(536, 440, "to the metal gutter", T_NOTE, TEXT, "end", True)
    f.value(560, 440, "25 mm (1 in)", 28, anchor="start", records=None)
    f.leader(740, 414, (dx + 24 + inner_r) / 2, my + 6, DIM)
    f.tag(f.w - 24, f.h - 12, "NEC 366.100(E)", anchor="end")


@figure("nm_extension_floor_382-15a", h=450, nec="382.15(A)", records={"final-exam-#5-049": {},
                                                                       "open-book-exam-#11-009": {"like": "final-exam-#5-049"}})
def nm_extension(f):
    floor, band, run = 400, 50, 322
    f.floor(floor, 20, 780)
    f.line(40, 70, 40, floor, LINE, SW_STRUCT)
    f.text(56, 60, "wall (elevation)", T_NOTE, MUTED, "start")
    f.hatch(60, floor - band, 700, band, NO, op=0.12)
    # Existing flush outlet with its plate; the extension leaves the plate's bottom.
    f.rect(160 - 26, 210 - 40, 52, 80, fill=PANEL, stroke=LINE, sw=SW_THIN, rx=5)
    f.receptacle(160, 210, 56)
    f.text(160, 154, "existing outlet", T_NOTE, TEXT, bold=True)
    f.rect(152, 250, 16, run - 250, fill=PANEL_2, stroke=TEXT, sw=SW_THIN, rx=3)
    f.rect(152, run - 8, 534, 16, fill=PANEL_2, stroke=TEXT, sw=SW_THIN, rx=3)
    f.line(160, 254, 160, run - 4, EDGE, 1.5)
    f.line(160, run, 682, run, EDGE, 1.5)
    # Surface-mounted receptacle at the far end.
    ex, ey = 712, run - 22
    f.rect(ex - 26, ey - 40, 52, 80, fill=PANEL, stroke=LINE, sw=SW_THIN, rx=6)
    f.receptacle(ex, ey, 56)
    f.text(420, run - 24, "nonmetallic surface extension", T_LABEL, TEXT, bold=True)
    f.mark_ok(640, run - 34, 16)
    f.mark_no(250, floor - band / 2, 15)
    f.text(280, floor - 17, "not on the floor or in this band", T_NOTE, NO, "start", True)
    f.ext(600, floor - band, 640, floor - band)
    f.dim_v(630, floor - band, floor)
    f.value(620, floor + 38, "50 mm (2 in)", 28, anchor="end", records=None, label="?")
    f.tag(f.w - 24, 50, "NEC 382.15(A)", anchor="end")


@figure("resistor_thermal_barrier_470-11", h=450, nec="470.11 (Part II, 1000 V or less)",
        records=["final-exam-#5-064"])
def thermal_barrier(f):
    wood_x, res_x0, res_x1 = 150, 450, 680
    floor = 360
    f.floor(floor, 20, 780)
    f.stud(70, 110, wood_x - 70, floor - 110)
    f.lines(110, 60, ["combustible", "material"], T_NOTE, TEXT, bold=True)
    # Open resistor bank: frame on feet, grid elements between end insulators.
    top, bot = 150, 316
    for x in (res_x0 + 16, res_x1 - 36):
        f.rect(x, bot, 20, floor - bot - 2, fill=STEEL, stroke=TEXT, sw=1.5)
    f.rect(res_x0, top, res_x1 - res_x0, bot - top, fill=PANEL, stroke=TEXT, sw=SW_OBJ + 1, rx=6)
    for k in range(4):
        y = 184 + k * 34
        f.rect(res_x0 + 12, y - 8, 14, 16, fill=PANEL_2, stroke=LINE, sw=1.5, rx=3)
        f.rect(res_x1 - 26, y - 8, 14, 16, fill=PANEL_2, stroke=LINE, sw=1.5, rx=3)
        pts = [(res_x0 + 30 + i * 21, y + (8 if i % 2 else -8)) for i in range(9)]
        f.polyline(pts, AMBER, SW_OBJ)
    f.lines((res_x0 + res_x1) / 2, 100, ["resistor or", "reactor"], T_LABEL, TEXT, bold=True)
    f.rect(260, 130, 14, floor - 132, fill=EDGE, stroke=TEXT, sw=SW_THIN)
    f.lines(300, 180, ["thermal", "barrier"], T_NOTE, TEXT, "start", True)
    f.leader(296, 190, 276, 200)
    f.ext(wood_x, floor + 2, wood_x, 402)
    f.ext(res_x0, bot + 2, res_x0, 402)
    f.dim_h(wood_x, res_x0, 392)
    f.text((wood_x + res_x0) / 2, 382, "barrier if less than", T_NOTE, DIM, bold=True)
    f.value((wood_x + res_x0) / 2, 432, "305 mm (12 in)", 30, records=None, label="?")
    f.tag(f.w - 24, f.h - 14, "NEC 470.11", anchor="end")


@figure("fire_pump_parts_695-12d", h=450, nec="695.12(D)", records=["open-book-exam-#10-021"])
def fire_pump(f):
    floor = 400
    f.floor(floor, 20, 780)
    f.rect(24, floor - 12, 752, 10, fill=WATER, stroke=WATER_EDGE, sw=1)
    # Floor-stand fire pump controller: door, handle, pilot lights, and
    # (seen through the door) the lowest energized terminals.
    x0, y0, w, h = 110, 100, 180, 190
    for lx in (x0 + 14, x0 + w - 26):
        f.rect(lx, y0 + h, 12, floor - 12 - y0 - h, fill=STEEL, stroke=TEXT, sw=1.5)
    f.rect(x0, y0, w, h, fill=PANEL, stroke=TEXT, sw=SW_OBJ + 1, rx=6)
    f.rect(x0 + 10, y0 + 10, w - 20, h - 20, fill="none", stroke=EDGE, sw=SW_THIN, rx=4)
    f.rect(x0 + 26, y0 + 26, 64, 30, fill=BG, stroke=LINE, sw=1.5, rx=3)
    for i, col in enumerate((OK, AMBER, NO)):
        f.circle(x0 + 112 + i * 20, y0 + 41, 6, fill=col)
    f.rect(x0 + w - 2, y0 + 70, 10, 36, fill=EDGE, stroke=TEXT, sw=1.5, rx=2)
    f.line(x0 + w + 6, y0 + 88, x0 + w + 30, y0 + 64, TEXT, 7)
    f.circle(x0 + w + 30, y0 + 64, 6, fill=TEXT)
    f.rect(x0 + 24, y0 + h - 30, w - 48, 16, fill=AMBER, rx=3)
    for k in range(5):
        f.circle(x0 + 38 + k * 26, y0 + h - 22, 3, fill=BG)
    f.lines(x0 + w / 2, 50, ["fire pump", "controller"], T_LABEL, TEXT, bold=True, gap=1.05)
    low = y0 + h - 14
    f.ext(x0 + w - 22, low, 372, low)
    f.dim_v(362, low, floor - 12)
    f.lines(384, 250, ["lowest", "energized part"], T_NOTE, AMBER, "start", True, gap=1.1)
    f.value_lines(384, 338, ["300 mm", "(12 in) min"], 30, anchor="start", records=None, label="? min")
    # Fire pump: volute casing on a skid, coupled to its motor.
    f.rect(540, floor - 34, 230, 20, fill=STEEL, stroke=TEXT, sw=1.5)
    vx, vy = 600, 316
    f.rect(vx - 22, vy + 20, 44, floor - 34 - vy - 20, fill=PANEL_2, stroke=TEXT, sw=1.5)
    f.conduit(vx, vy - 30, vx, 190, width=24)
    f.circle(vx, vy, 38, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ)
    f.circle(vx, vy, 12, fill=EDGE, stroke=TEXT, sw=1.5)
    f.motor(704, floor - 34 - 9.5 - 30, 116, 60, label=None, shaft="left")
    f.text(632, 214, "discharge", T_NOTE, MUTED, "start")
    f.text(704, 252, "fire pump", T_LABEL, TEXT, bold=True)
    f.text(760, floor + 38, "water on the floor", T_NOTE, WATER_EDGE, "end")
    f.tag(40, f.h - 14, "NEC 695.12(D)")


@figure("heated_ceiling_wiring_424-36", h=450, nec="424.36", records=["open-book-exam-#7-010"])
def heated_ceiling(f):
    cy0, cy1, cab = 320, 344, 262
    joists = (60, 390, 730)
    for x in joists:
        f.stud(x, 120, 30, cy0 - 120)
    f.rect(20, cy0, 760, cy1 - cy0, fill=PANEL_2, stroke=LINE, sw=SW_THIN)
    for x in range(40, 780, 36):
        f.circle(x, (cy0 + cy1) / 2, 5, fill=AMBER)
    f.text(400, cy1 + 34, "heated ceiling (heating cables)", T_LABEL, TEXT, bold=True)
    for x in joists:
        f.circle(x + 15, cab, 9, fill=BG, stroke="#ca8a04", sw=1.5)
    f.cable([(20, cab), (780, cab)], WIRE_HOT, 8)
    f.text(245, cab - 18, "wiring above the ceiling", T_NOTE, TEXT, bold=True)
    f.dim_v(480, cab + 5, cy0)
    f.value(500, cab + 42, "50 mm (2 in) min", 28, anchor="start", records=None, label="? min")
    f.lines(400, 50, ["ampacity: ambient of not less than", "50 deg C (122 deg F), 310.15(B)(1)"],
            T_NOTE, MUTED)
    f.tag(f.w - 24, f.h - 14, "NEC 424.36", anchor="end")
