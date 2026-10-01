"""Service bonding and the grounding electrode system, Article 250."""
from nec_style import *  # noqa: F401,F403


def _bar(f, x, y0, y1, fill):
    """Terminal bar seen face-on, vertical: bar with a row of terminal screws."""
    f.rect(x - 9, y0, 18, y1 - y0, fill=fill, stroke=TEXT, sw=1.5, rx=3)
    for yy in range(int(y0) + 14, int(y1) - 6, 22):
        f.circle(x, yy, 4.5, fill=PANEL, stroke=EDGE, sw=1)


def _pipe_clamp(f, x, y, color=CLAMP):
    """Bronze ground clamp around a pipe or rebar, centred on (x, y)."""
    f.rect(x - 7, y - 11, 14, 22, fill=color, stroke=TEXT, sw=1.5, rx=3)
    f.line(x - 4, y, x + 4, y, BG, 2)


def _water_meter(f, cx, y):
    """Inline water meter on a horizontal pipe: brass couplings, body, register lid and dial."""
    for ux in (cx - 38, cx + 38):
        f.rect(ux - 6, y - 12, 12, 24, fill=EDGE, stroke=TEXT, sw=1.5, rx=2)
    f.rect(cx - 31, y - 20, 62, 40, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=10)
    f.rect(cx - 20, y - 34, 40, 16, fill=EDGE, stroke=TEXT, sw=SW_THIN, rx=5)
    f.circle(cx, y, 10, fill=BG, stroke=LINE, sw=SW_THIN)
    f.line(cx, y, cx + 6, y - 5, AMBER, 2)


@figure("service_bonding_250-24", h=580, nec="Article 100 (main bonding jumper, GEC), 250.24, 250.28",
        records=["open-book-exam-#1-002", "open-book-exam-#10-024"])
def service_bonding(f):
    mbj = ["open-book-exam-#1-002"]
    gec = ["open-book-exam-#10-024"]
    f.title("Service panel, cover off", y=30)
    f.tag(f.w - 24, 40, "NEC 250.24, 250.28", anchor="end")
    x0, y0, x1, y1 = 250, 96, 550, 496
    # Meter, and the service-entrance conductors in over the top of the can.
    mx, my = 110, 210
    f.meter(mx, my, 30)
    f.text(mx, my + 74, "meter", T_NOTE, MUTED)
    hot1, hot2, nx = 372.5, 427.5, 529
    f.polyline([(mx - 14, my - 47), (mx - 14, 56), (nx, 56), (nx, 236)], WIRE_NEU, SW_WIRE)
    f.polyline([(mx, my - 47), (mx, 70), (hot2, 70), (hot2, 118)], WIRE_HOT, SW_WIRE)
    f.polyline([(mx + 14, my - 47), (mx + 14, 84), (hot1, 84), (hot1, 118)], WIRE_HOT, SW_WIRE)
    f.rect(x0, y0, x1 - x0, y1 - y0, fill=PANEL, stroke=TEXT, sw=SW_OBJ + 1, rx=6)
    f.line(nx, y0 - 4, nx, 236, WIRE_NEU, SW_WIRE)
    for hx in (hot1, hot2):
        f.line(hx, y0 - 4, hx, 118, WIRE_HOT, SW_WIRE)
    # Main breaker on the bus, branch breakers plugged onto the two bus stabs.
    f.breaker(345, 110, 110, 86, poles=2)
    f.text(335, 160, "main", T_NOTE, MUTED, "end")
    for hx in (hot1, hot2):
        f.rect(hx - 6, 192, 12, 228, fill=STEEL, stroke=LINE, sw=1.5, rx=2)
    for i in range(5):
        yy = 214 + i * 40
        f.mini_breaker(300, yy, 66, 28)
        f.mini_breaker(434, yy, 66, 28, handle_left=True)
    # Equipment grounding bar (left), neutral bar (right) and the bonding strap between them.
    _bar(f, 271, 236, 406, WIRE_GND)
    _bar(f, nx, 236, 406, WIRE_NEU)
    f.text(238, 338, "ground bar", T_NOTE, TEXT, "end", True)
    f.leader(240, 330, 266, 330)
    f.text(562, 338, "neutral bar", T_NOTE, TEXT, "start", True)
    f.leader(560, 330, 534, 330)
    f.polyline([(nx, 406), (nx, 446), (271, 446), (271, 406)], AMBER, 8)
    f.value(400, 480, "MAIN BONDING JUMPER", T_NOTE, records=mbj)
    # Grounding electrode conductor from the neutral bar out to the rod.
    grade, gx = 524, 610
    f.grade(grade, 570, f.w - 20, label=None, soil_h=f.h - grade)
    f.polyline([(nx + 9, 384), (gx, 384), (gx, grade + 8)], WIRE_GND, SW_WIRE + 1)
    f.rod(gx, grade, 36)
    f.value_lines(gx + 16, 420, ["GROUNDING", "ELECTRODE", "CONDUCTOR"], T_NOTE, anchor="start",
                  records=gec, gap=1.2)
    f.text(gx - 40, grade + 30, "ground rod", T_NOTE, MUTED, "end")
    f.leader(gx - 34, grade + 22, gx - 6, grade + 22)


@figure("electrode_system_250-52_250-53", h=470,
        nec="250.52(A)(2), 250.52(A)(5), 250.53(A)(3), 250.53(A)(4), 250.53(A)(5)",
        records={"final-exam-#1-020": {}, "open-book-exam-#1-008": {}, "final-exam-#1-035": {},
                 "open-book-exam-#4-024": {}, "open-book-exam-#3-020": {"like": "final-exam-#1-020"}})
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
    for wx in (cx0 + 6, cx1 - 6):
        f.line(wx, 62, wx, cbot - 2, LINE, 1.5)
    f.rect(cx0 - 8, 56, cx1 - cx0 + 16, 8, fill=STEEL, stroke=LINE, sw=SW_THIN, rx=1)
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


@figure("gec_water_bond_250-66_250-68", h=500,
        nec="250.50 Ex., 250.52(A)(1), 250.52(A)(3), 250.66(B), 250.68(B)",
        records={"final-exam-#3-027": {}, "final-exam-#3-050": {},
                 "final-exam-#3-066": {"terms": ["existing"]}})
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
    f.line(505, 385, 505, 312, STEEL, 7)
    f.lines(705, 306, ["concrete-encased", "electrode (rebar)"], T_NOTE, TEXT)
    f.leader(705, 340, 598, 384)
    # Metal underground water pipe, meter and bonding jumper.
    f.conduit(f.w - 20, pipe_y, 200, pipe_y, width=10, color=WATER, edge=WATER_EDGE)
    f.conduit(200, pipe_y + 7, 200, 150, width=10, color=WATER, edge=WATER_EDGE)
    f.text(668, pipe_y - 16, "metal water pipe", T_NOTE, TEXT)
    _water_meter(f, 335, pipe_y)
    f.text(335, pipe_y + 50, "water meter", T_NOTE, TEXT)
    f.polyline([(258, pipe_y - 11), (258, 200), (412, 200), (412, pipe_y - 11)], AMBER, 6)
    for x in (258, 412):
        _pipe_clamp(f, x, pipe_y)
    f.text(335, 146, "bonding jumper", T_NOTE, MUTED)
    f.value(335, 184, "sufficient length", T_LABEL, records=bond)
    # Service panel and its grounding electrode conductors.
    f.panel(30, 90, 90, 130, label=None, breakers=3)
    f.lines(75, 50, ["service", "panel"], T_NOTE, TEXT, bold=True)
    f.polyline([(120, 100), (480, 100), (480, pipe_y - 11)], WIRE_GND, SW_WIRE)
    _pipe_clamp(f, 480, pipe_y)
    f.polyline([(75, 220), (75, 318), (497, 318)], WIRE_GND, SW_WIRE)
    _pipe_clamp(f, 505, 318)
    f.text(96, 306, "GEC to the rebar", T_MIN, MUTED, "start")
    f.value(260, 376, "need not exceed 4 AWG Cu", T_LABEL, records=cee)
    b = f.text(30, 462, "250.50 Ex.: in", T_MIN, TEXT, "start", True)
    b = f.value(b[0] + b[2] + 8, 462, "existing buildings", T_MIN, anchor="start", records=["final-exam-#3-066"],
                pad=4, what="where unreachable rebar may be left out")
    f.text(b[0] + b[2] + 8, 462, "rebar you can not reach", T_MIN, TEXT, "start", True)
    f.text(30, 488, "without disturbing the concrete may be left out", T_MIN, TEXT, "start", True)
    f.tag(f.w - 24, 44, "NEC 250.66(B), 250.68(B)", anchor="end")
