"""Service bonding and the grounding electrode system, Article 250."""
from nec_style import *  # noqa: F401,F403


@figure("service_bonding_250-24", h=450, nec="Article 100 (main bonding jumper, GEC), 250.24, 250.28",
        records=["open-book-exam-#1-002", "open-book-exam-#10-024"])
def service_bonding(f):
    mbj = ["open-book-exam-#1-002"]
    gec = ["open-book-exam-#10-024"]
    ex0, ey0, ex1, ey1 = 250, 58, 610, 350
    f.text(430, 42, "SERVICE PANEL", T_LABEL, MUTED, bold=True)
    f.rect(ex0, ey0, ex1 - ex0, ey1 - ey0, fill=PANEL, stroke=TEXT, sw=4, rx=10)
    f.text(40, 86, "from meter", T_NOTE, MUTED, "start")
    for y in (100, 136):
        f.line(40, y, 270, y, WIRE_HOT, SW_WIRE)
    f.line(40, 118, 262, 118, WIRE_NEU, SW_WIRE)
    f.rect(270, 80, 70, 70, fill=PANEL_2, stroke=LINE, sw=3, rx=5)
    f.text(305, 124, "MAIN", T_MIN, TEXT, bold=True)
    f.line(262, 118, 262, 181, WIRE_NEU, SW_WIRE)
    f.line(262, 181, 380, 181, WIRE_NEU, SW_WIRE)
    f.rect(380, 170, 180, 22, fill=WIRE_NEU, rx=4)
    for x in range(396, 560, 20):
        f.circle(x, 181, 4, fill=PANEL)
    f.text(470, 160, "neutral bar", T_NOTE, TEXT, bold=True)
    f.rect(380, 280, 180, 22, fill=WIRE_GND, rx=4)
    f.text(470, 330, "ground bar", T_NOTE, TEXT, bold=True)
    f.line(560, 291, ex1, 291, WIRE_GND, SW_WIRE)
    f.rect(60, 225, 110, 95, fill=PANEL_2, stroke=LINE, sw=3, rx=8)
    f.text(115, 282, "load", T_LABEL, TEXT, bold=True)
    f.line(170, 245, 305, 245, WIRE_HOT, SW_WIRE)
    f.line(305, 245, 305, 150, WIRE_HOT, SW_WIRE)
    f.line(170, 268, 355, 268, WIRE_NEU, SW_WIRE)
    f.line(355, 268, 355, 187, WIRE_NEU, SW_WIRE)
    f.line(355, 187, 380, 187, WIRE_NEU, SW_WIRE)
    f.line(170, 291, 380, 291, WIRE_GND, SW_WIRE)
    f.text(236, 312, "EGC", T_MIN, WIRE_GND, bold=True)
    jx = 400
    f.line(jx, 192, jx, 280, AMBER, 8)
    f.value_lines(jx + 18, 228, ["MAIN BONDING", "JUMPER"], T_LABEL, OK, "start", records=mbj)
    grade, gx = 400, 626
    f.line(560, 181, gx, 181, WIRE_GND, 5)
    f.line(gx, 181, gx, grade, WIRE_GND, 5)
    f.grade(grade, 20, f.w - 20, label=None)
    f.rod(gx, grade, 34)
    f.value_lines(gx + 16, 232, ["GROUNDING", "ELECTRODE", "CONDUCTOR"], T_NOTE, OK, "start", records=gec)
    f.text(gx + 16, grade + 40, "electrode", T_NOTE, MUTED, "start")


@figure("electrode_system_250-52_250-53", h=470,
        nec="250.52(A)(2), 250.52(A)(5), 250.53(A)(3), 250.53(A)(4), 250.53(A)(5)",
        records=["final-exam-#1-020", "open-book-exam-#1-008", "final-exam-#1-035", "open-book-exam-#4-024"])
def electrode_system(f):
    spacing = ["final-exam-#1-020"]
    plate = ["open-book-exam-#1-008"]
    column = ["final-exam-#1-035", "open-book-exam-#4-024"]
    grade, ft = 140, 28.0
    f.grade(grade, 20, f.w - 20, label=None, soil_h=f.h - grade - 20)
    f.text(f.w - 26, grade - 12, "grade", T_NOTE, MUTED, "end")
    f.title("Electrodes in the earth (section view, not to scale)", y=36)
    # In-ground metal support structure.
    cx0, cx1, cbot = 70, 96, grade + 6.9 * ft
    f.rect(cx0, 60, cx1 - cx0, cbot - 60, fill=STEEL, stroke=LINE, sw=SW_THIN)
    f.lines(108, 80, ["in-ground metal", "support structure"], T_NOTE, TEXT, "start")
    f.ext(cx1 + 2, cbot, 128, cbot)
    f.dim_v(120, grade, cbot)
    f.value_lines(132, 300, ["10 ft", "or more"], anchor="start", records=column)
    # Two rods.
    r1, r2, rlen = 300, 468, 6.3 * ft
    f.line(r1, grade + 14, r2, grade + 14, WIRE_GND, SW_WIRE)
    f.text((r1 + r2) / 2, grade + 50, "bonding jumper", T_NOTE, MUTED)
    for x in (r1, r2):
        f.rod(x, grade, rlen, label="rod")
    f.ext(r2 + 6, grade + rlen, 508, grade + rlen)
    f.dim_v(500, grade, grade + rlen)
    f.text(512, 252, "8 ft", T_VALUE, DIM, "start", True)
    for x in (r1, r2):
        f.ext(x, grade - 4, x, 92)
    f.dim_h(r1, r2, 100)
    f.value((r1 + r2) / 2, 86, "6 ft min", records=spacing)
    # Plate electrode (edge view).
    px0, px1, ptop = 650, 710, grade + 1.8 * ft
    f.line(680, grade, 680, ptop, WIRE_GND, SW_WIRE)
    f.rect(px0, ptop, px1 - px0, 9, fill=STEEL, stroke=TEXT, sw=SW_THIN)
    f.text(680, ptop + 44, "plate", T_NOTE, MUTED)
    f.ext(px0 - 2, ptop, 622, ptop)
    f.dim_v(630, grade, ptop)
    f.value(618, 176, "30 in", anchor="end", records=plate)
    f.tag(f.w - 24, f.h - 24, "NEC 250.52(A), 250.53(A)", anchor="end")


@figure("gec_water_bond_250-66_250-68", h=450, nec="250.52(A)(1), 250.52(A)(3), 250.66(B), 250.68(B)",
        records=["final-exam-#3-027", "final-exam-#3-050"])
def gec_water_bond(f):
    cee = ["final-exam-#3-027"]
    bond = ["final-exam-#3-050"]
    grade, floor, pipe_y = 180, 330, 250
    f.grade(grade, 552, f.w - 20, label=None, soil_h=f.h - grade - 20)
    f.text(f.w - 26, grade - 12, "grade", T_NOTE, MUTED, "end")
    f.soil(20, floor, 508, f.h - floor - 20)
    f.floor(floor, 20, 528)
    f.wall(540, 72, 360, thick=24)
    # Footing with rebar: the concrete-encased electrode.
    f.concrete(470, 360, 150, 50)
    f.line(482, 385, 608, 385, STEEL, 7)
    f.lines(705, 306, ["concrete-encased", "electrode (rebar)"], T_NOTE, TEXT)
    f.leader(705, 340, 598, 384)
    # Metal underground water pipe, meter and bonding jumper.
    f.conduit(f.w - 20, pipe_y, 200, pipe_y, width=10, color=WATER, edge=WATER_EDGE)
    f.conduit(200, pipe_y + 7, 200, 150, width=10, color=WATER, edge=WATER_EDGE)
    f.text(668, pipe_y - 16, "metal water pipe", T_NOTE, TEXT)
    f.rect(300, pipe_y - 24, 70, 48, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=6)
    f.text(335, pipe_y + 58, "water meter", T_NOTE, TEXT)
    f.polyline([(270, pipe_y), (270, 200), (400, 200), (400, pipe_y)], AMBER, 6)
    for x in (270, 400):
        f.circle(x, pipe_y, 7, fill=AMBER)
    f.text(335, 146, "bonding jumper", T_NOTE, MUTED)
    f.value(335, 184, "sufficient length", T_LABEL, records=bond)
    # Service panel and its grounding electrode conductors.
    f.panel(30, 90, 90, 130, label=None, breakers=3)
    f.lines(75, 50, ["service", "panel"], T_NOTE, TEXT, bold=True)
    f.polyline([(120, 100), (480, 100), (480, pipe_y)], WIRE_GND, SW_WIRE)
    f.circle(480, pipe_y, 7, fill=WIRE_GND)
    f.polyline([(75, 220), (75, 345), (500, 345), (500, 382)], WIRE_GND, SW_WIRE)
    f.value(270, 394, "need not exceed 4 AWG Cu", T_LABEL, records=cee)
    f.tag(f.w - 24, 44, "NEC 250.66(B), 250.68(B)", anchor="end")
