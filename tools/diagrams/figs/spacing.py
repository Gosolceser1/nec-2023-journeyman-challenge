"""Clearances and spacings: nipple fill, box depth, gutter bare parts, extensions,
resistors, fire pump parts, wiring above heated ceilings."""
from nec_style import *  # noqa: F401,F403


@figure("nipple_fill_ch9_note4", h=420, nec="Chapter 9, Notes to Tables, Note (4)",
        records={"final-exam-#1-067": {"when": "after"}})
def nipple_fill(f):
    y0, y1 = 196, 244
    f.rect(50, 120, 210, 210, fill=PANEL, stroke=TEXT, sw=SW_OBJ + 1, rx=6)
    f.text(155, 228, "box", T_LABEL, TEXT, bold=True)
    f.rect(540, 120, 210, 210, fill=PANEL, stroke=TEXT, sw=SW_OBJ + 1, rx=6)
    f.text(645, 228, "cabinet", T_LABEL, TEXT, bold=True)
    f.rect(260, y0, 280, y1 - y0, fill=STEEL, stroke=LINE, sw=SW_THIN)
    for yy in (206, 214, 222, 230, 238):
        f.line(236, yy, 564, yy, WIRE_HOT, 3)
    f.ext(260, y0 - 4, 260, 92)
    f.ext(540, y0 - 4, 540, 92)
    f.dim_h(260, 540, 100)
    f.text(400, 80, "600 mm (24 in) max", 28, DIM, bold=True)
    f.text(400, 170, "not incl. connectors", T_NOTE, MUTED)
    f.text(400, 280, "nipple", T_LABEL, TEXT, bold=True)
    f.value(400, 318, "fill up to 60%", 30, records=None)
    f.text(400, 362, "310.15(C)(1) adjustment factors need not apply", T_NOTE, MUTED)
    f.tag(f.w - 24, f.h - 16, "NEC Chapter 9, Note (4)", anchor="end")


@figure("box_depth_314-24b5", h=450, nec="314.24(B)(5)", records=["final-exam-#3-034"])
def box_depth(f):
    face, back = 300, 470
    f.text(40, 50, "side section", T_NOTE, MUTED, "start")
    f.rect(face - 18, 70, 18, 280, fill=PANEL_2, stroke=LINE, sw=SW_THIN)
    f.text(face - 34, 100, "wall", T_NOTE, MUTED, "end")
    f.rect(face, 150, back - face, 180, fill=PANEL, stroke=TEXT, sw=SW_OBJ + 1)
    f.rect(face - 30, 136, 12, 208, fill=PANEL_2, stroke=TEXT, sw=SW_THIN, rx=3)
    f.text(face - 44, 244, "plate", T_NOTE, MUTED, "end")
    f.rect(face - 18, 196, 84, 88, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=6)
    f.text(face + 24, 247, "device", T_MIN, TEXT, bold=True)
    f.cable([(700, 100), (560, 100), (530, 130), (back - 26, 190), (face + 60, 226)], WIRE_HOT, 5)
    f.cable([(700, 112), (566, 112), (538, 140), (back - 26, 204), (face + 60, 252)], WIRE_NEU, 5)
    f.text(710, 84, "14 AWG", T_LABEL, TEXT, "end", True)
    f.text(710, 146, "or smaller", T_NOTE, MUTED, "end")
    f.text(back + 20, 300, "device box", T_LABEL, TEXT, "start", True)
    f.ext(face, 334, face, 382)
    f.ext(back, 334, back, 382)
    f.dim_h(face, back, 372)
    f.text((face + back) / 2, 352, "depth", T_NOTE, DIM, bold=True)
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
    f.dim_h(ax + 24, bx, inner_b - 132)
    f.text((ax + 24 + bx) / 2, inner_b - 150, "50 mm (2 in)", 28, DIM, bold=True)
    f.lines(40, 420, ["on the same surface", "(insulating base)"], T_NOTE, TEXT, "start", True)
    # Held free in the air, on insulator posts.
    dx = inner_r - one - 24
    cx = dx - one - 24
    top = 196
    for x in (cx, dx):
        f.rect(x + 8, top + 80, 8, inner_b - top - 80, fill=PANEL_2, stroke=EDGE, sw=1)
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


@figure("nm_extension_floor_382-15a", h=450, nec="382.15(A)", records=["final-exam-#5-049"])
def nm_extension(f):
    floor, band, run = 400, 50, 318
    f.floor(floor, 20, 780)
    f.line(40, 70, 40, floor, LINE, SW_STRUCT)
    f.text(56, 60, "wall (elevation)", T_NOTE, MUTED, "start")
    f.hatch(60, floor - band, 700, band, NO, op=0.12)
    f.receptacle(160, 210, 50)
    f.text(160, 160, "existing outlet", T_NOTE, TEXT, bold=True)
    f.rect(146, 236, 28, run - 236, fill=PANEL_2, stroke=TEXT, sw=SW_THIN, rx=4)
    f.rect(146, run - 14, 560, 28, fill=PANEL_2, stroke=TEXT, sw=SW_THIN, rx=4)
    f.receptacle(720, run - 30, 46)
    f.text(430, run - 26, "nonmetallic surface extension", T_LABEL, TEXT, bold=True)
    f.mark_ok(650, run - 36, 16)
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
    f.floor(360, 20, 780)
    f.stud(70, 110, wood_x - 70, 250)
    f.lines(110, 60, ["combustible", "material"], T_NOTE, TEXT, bold=True)
    f.rect(res_x0, 150, res_x1 - res_x0, 170, fill=PANEL, stroke=TEXT, sw=SW_OBJ + 1, rx=6)
    for k in range(4):
        y = 184 + k * 34
        pts = [(res_x0 + 24 + i * 22, y + (8 if i % 2 else -8)) for i in range(9)]
        f.polyline(pts, AMBER, SW_OBJ)
    f.lines((res_x0 + res_x1) / 2, 100, ["resistor or", "reactor"], T_LABEL, TEXT, bold=True)
    f.rect(260, 130, 14, 220, fill=EDGE, stroke=TEXT, sw=SW_THIN)
    f.lines(300, 180, ["thermal", "barrier"], T_NOTE, TEXT, "start", True)
    f.leader(296, 190, 276, 200)
    f.ext(wood_x, 362, wood_x, 402)
    f.ext(res_x0, 322, res_x0, 402)
    f.dim_h(wood_x, res_x0, 392)
    f.text((wood_x + res_x0) / 2, 382, "barrier if less than", T_NOTE, DIM, bold=True)
    f.value((wood_x + res_x0) / 2, 432, "305 mm (12 in)", 30, records=None, label="?")
    f.tag(f.w - 24, f.h - 14, "NEC 470.11", anchor="end")


@figure("fire_pump_parts_695-12d", h=450, nec="695.12(D)", records=["open-book-exam-#10-021"])
def fire_pump(f):
    floor, wall = 400, 70
    f.floor(floor, 20, 780)
    f.line(wall, 40, wall, floor, LINE, SW_STRUCT + 2)
    f.rect(wall + 4, floor - 12, 700, 10, fill=WATER, stroke=WATER_EDGE, sw=1)
    f.rect(130, 110, 170, 190, fill=PANEL, stroke=TEXT, sw=SW_OBJ + 1, rx=6)
    f.line(wall, 170, 130, 170, LINE, 6)
    f.line(wall, 260, 130, 260, LINE, 6)
    f.rect(150, 272, 130, 16, fill=AMBER, rx=3)
    f.lines(215, 58, ["fire pump", "controller"], T_LABEL, TEXT, bold=True)
    f.text(215, 330, "lowest energized part", T_NOTE, AMBER, bold=True)
    f.ext(282, 288, 360, 288)
    f.dim_v(350, 288, floor)
    f.value_lines(370, 340, ["300 mm", "(12 in) min"], 30, anchor="start", records=None, label="? min")
    f.rect(580, 300, 170, 88, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=8)
    f.text(665, 352, "pump", T_LABEL, TEXT, bold=True)
    f.conduit(665, 300, 665, 200, width=20)
    f.text(665, 180, "water discharge", T_NOTE, MUTED)
    f.text(760, floor + 38, "water on the floor", T_NOTE, WATER_EDGE, "end")
    f.tag(40, f.h - 14, "NEC 695.12(D)")


@figure("heated_ceiling_wiring_424-36", h=450, nec="424.36", records=["open-book-exam-#7-010"])
def heated_ceiling(f):
    cy0, cy1, cab = 320, 344, 262
    for x in (60, 390, 730):
        f.stud(x, 120, 30, cy0 - 120)
    f.rect(20, cy0, 760, cy1 - cy0, fill=PANEL_2, stroke=LINE, sw=SW_THIN)
    for x in range(40, 780, 36):
        f.circle(x, (cy0 + cy1) / 2, 5, fill=AMBER)
    f.text(400, cy1 + 34, "heated ceiling (heating cables)", T_LABEL, TEXT, bold=True)
    f.cable([(20, cab), (780, cab)], WIRE_HOT, 8)
    f.text(200, cab - 18, "wiring above the ceiling", T_NOTE, TEXT, bold=True)
    f.ext(480, cab + 4, 480, cy0)
    f.dim_v(460, cab + 4, cy0)
    f.value(480, cab + 44, "50 mm (2 in) min", 28, anchor="start", records=None, label="? min")
    f.lines(400, 50, ["ampacity: ambient of not less than", "50 deg C (122 deg F), 310.15(B)(1)"],
            T_NOTE, MUTED)
    f.tag(f.w - 24, f.h - 14, "NEC 424.36", anchor="end")
