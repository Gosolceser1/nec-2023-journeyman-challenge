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


@figure("service_bonding_250-24", h=580, nec="Article 100 (Main Bonding Jumper, Grounding Electrode Conductor)",
        records=["open-book-exam-#1-002", "open-book-exam-#10-024"])
def service_bonding(f):
    mbj = ["open-book-exam-#1-002"]
    gec = ["open-book-exam-#10-024"]
    f.title("Service panel, cover off", y=30)
    f.tag(f.w - 24, 40, "NEC Article 100", anchor="end")
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


@figure("inground_steel_250-52a2", h=460, nec="250.52(A)(2)",
        records=["final-exam-#1-035", "open-book-exam-#4-024"])
def inground_steel(f):
    grade, ft = 150, 24.0
    f.title("In-ground metal support structure (section view, not to scale)", y=36)
    f.grade(grade, 20, f.w - 20, label=None, soil_h=f.h - grade - 20)
    f.text(f.w - 26, grade - 12, "grade", T_NOTE, MUTED, "end")
    cx0, cx1, cbot = 200, 236, grade + 10.8 * ft
    f.rect(cx0, 64, cx1 - cx0, cbot - 64, fill=STEEL, stroke=LINE, sw=SW_THIN)
    for wx in (cx0 + 7, cx1 - 7):
        f.line(wx, 66, wx, cbot - 2, LINE, 1.5)
    f.rect(cx0 - 10, 58, cx1 - cx0 + 20, 9, fill=STEEL, stroke=LINE, sw=SW_THIN, rx=1)
    f.lines(250, 86, ["steel column", "of the building"], T_NOTE, TEXT, "start", True)
    f.ext(cx0 - 2, cbot, 120, cbot)
    f.ext(cx0 - 2, grade, 120, grade)
    f.dim_v(132, grade, cbot)
    f.value_lines(120, 280, ["10 ft", "or more"], anchor="end", what="the minimum length in the earth")
    f.text(256, 300, "in direct contact", T_NOTE, TEXT, "start", True)
    f.text(256, 328, "with the earth", T_NOTE, TEXT, "start", True)
    f.card(470, 190, 300, 170, "Permitted electrode")
    f.lines(486, 252, ["vertical, in the earth,", "with or without", "concrete encasement"], T_MIN, TEXT, "start",
            gap=1.25)
    f.tag(f.w - 24, f.h - 30, "NEC 250.52(A)(2)", anchor="end")


@figure("rod_spacing_250-53a3", h=420, nec="250.53(A)(3)",
        records={"final-exam-#1-020": {}, "open-book-exam-#3-020": {"like": "final-exam-#1-020"}})
def rod_spacing(f):
    grade, ft = 150, 28.0
    f.title("Two driven ground rods (section view, not to scale)", y=36)
    f.grade(grade, 20, f.w - 20, label=None, soil_h=f.h - grade - 20)
    f.text(f.w - 26, grade - 12, "grade", T_NOTE, MUTED, "end")
    r1, r2, rlen = 220, 520, 6.3 * ft
    f.line(r1, grade + 14, r2, grade + 14, WIRE_GND, SW_WIRE)
    f.text((r1 + r2) / 2, grade + 50, "bonding jumper", T_NOTE, MUTED)
    for x in (r1, r2):
        f.rod(x, grade, rlen, label="rod")
    f.ext(r2 + 6, grade + rlen, 588, grade + rlen)
    f.dim_v(580, grade, grade + rlen)
    f.text(594, 262, "8 ft rods", T_LABEL, DIM, "start", True)
    for x in (r1, r2):
        f.ext(x, grade - 4, x, 92)
    f.dim_h(r1, r2, 100)
    f.value((r1 + r2) / 2, 86, "6 ft min", what="the minimum spacing")
    f.tag(f.w - 24, f.h - 30, "NEC 250.53(A)(3)", anchor="end")


@figure("plate_depth_250-53a5", h=380, nec="250.53(A)(5)", records=["open-book-exam-#1-008"])
def plate_depth(f):
    grade, ft = 130, 56.0
    f.title("Plate electrode (section view, not to scale)", y=36)
    f.grade(grade, 20, f.w - 20, label=None, soil_h=f.h - grade - 20)
    f.text(f.w - 26, grade - 12, "grade", T_NOTE, MUTED, "end")
    ptop = grade + 2.5 * ft
    f.line(400, 70, 400, ptop, WIRE_GND, SW_WIRE)
    f.text(414, 92, "GEC", T_NOTE, TEXT, "start", True)
    f.rect(320, ptop, 160, 12, fill=STEEL, stroke=TEXT, sw=SW_THIN)
    f.text(400, ptop + 46, "plate (edge view)", T_NOTE, TEXT, bold=True)
    f.ext(318, ptop, 270, ptop)
    f.dim_v(282, grade, ptop)
    f.value(266, (grade + ptop) / 2 + 10, "30 in", anchor="end", what="the minimum depth")
    f.text(500, (grade + ptop) / 2 + 8, "below the surface", T_NOTE, MUTED, "start")
    f.tag(f.w - 24, f.h - 30, "NEC 250.53(A)(5)", anchor="end")


@figure("concrete_encased_gec_250-66b", h=480, nec="250.66(B)", records=["final-exam-#3-027"])
def concrete_encased_gec(f):
    f.title("GEC to a concrete-encased electrode (section view)", y=36)
    grade, floor = 170, 300
    f.soil(20, floor, f.w - 40, f.h - floor - 20)
    f.floor(floor, 20, f.w - 20)
    f.panel(80, 80, 100, 150, label="service panel", breakers=3)
    f.concrete(470, 330, 230, 60)
    f.line(486, 360, 684, 360, STEEL, 7)
    f.line(520, 360, 520, 282, STEEL, 7)
    f.lines(600, 418, ["footing with rebar:", "concrete-encased electrode"], T_MIN, TEXT, gap=1.1)
    f.polyline([(130, 230), (130, 270), (512, 270)], WIRE_GND, SW_WIRE)
    _pipe_clamp(f, 520, 270)
    f.text(220, 258, "grounding electrode conductor", T_NOTE, TEXT, "start", True)
    f.card(230, 90, 540, 110, "Largest GEC required")
    f.value(250, 170, "4 AWG copper", T_LABEL, anchor="start", pad=6, what="the largest size required")
    f.tag(36, f.h - 12, "NEC 250.66(B)")


@figure("existing_building_rebar_250-50", h=420, nec="250.50", records={"final-exam-#3-066": {"terms": ["existing"]}})
def existing_building_rebar(f):
    f.title("Rebar you cannot reach without disturbing the concrete", y=36)
    grade = 150
    f.grade(grade, 20, f.w - 20, label=None, soil_h=f.h - grade - 20)
    f.text(f.w - 26, grade - 12, "grade", T_NOTE, MUTED, "end")
    f.rect(180, 60, 40, grade + 120 - 60, fill=PANEL_2, stroke=LINE, sw=SW_THIN)
    f.text(240, 90, "foundation wall", T_NOTE, TEXT, "start", True)
    f.concrete(120, grade + 120, 160, 60)
    f.line(134, grade + 150, 266, grade + 150, STEEL, 7)
    f.lines(300, grade + 150, ["rebar sealed in the footing:", "not part of the electrode system"], T_NOTE,
            TEXT, "start", gap=1.2)
    b = f.text(40, f.h - 30, "allowed where the building is", T_NOTE, TEXT, "start", True)
    f.value(b[0] + b[2] + 10, f.h - 30, "an existing building", T_NOTE, anchor="start", pad=5,
            what="where unreachable rebar may be left out")
    f.tag(f.w - 24, 64, "NEC 250.50", anchor="end")


@figure("water_meter_bond_250-68b", h=380, nec="250.68(B)", records=["final-exam-#3-050"])
def water_meter_bond(f):
    f.title("Bonding around a water meter", y=36)
    pipe_y = 230
    f.conduit(f.w - 40, pipe_y, 40, pipe_y, width=12, color=WATER, edge=WATER_EDGE)
    f.text(660, pipe_y + 44, "metal water pipe (electrode)", T_NOTE, TEXT)
    _water_meter(f, 400, pipe_y)
    f.text(400, pipe_y + 56, "water meter", T_NOTE, TEXT)
    f.polyline([(300, pipe_y - 13), (300, 150), (500, 150), (500, pipe_y - 13)], AMBER, 6)
    for x in (300, 500):
        _pipe_clamp(f, x, pipe_y)
    f.text(400, 136, "bonding jumper", T_NOTE, MUTED)
    f.value(400, 100, "sufficient length", T_LABEL, what="how long the jumper must be")
    f.lines(40, 320, ["the meter can be removed", "while the bond stays connected"], T_MIN, MUTED, "start",
            gap=1.2)
    f.tag(f.w - 24, f.h - 14, "NEC 250.68(B)", anchor="end")
