"""Outdoor and site rules: electrode sizes and rock bottom, fair structures near lines, fence bonding,
therapeutic tub GFCI zone, conductors emerging from grade and luminaires under roof decking."""
from nec_style import *  # noqa: F401,F403

RODS = ["final-exam-#2-003", "open-book-exam-#6-003"]
TRENCHES = ["final-exam-#2-005", "open-book-exam-#6-006"]
PIPE = ["open-book-exam-#5-021"]
RING = ["open-book-exam-#11-020"]


def _rock(f, x0, x1, y):
    pts = [(x0, y + 10), (x0 + 40, y - 6), (x0 + 110, y + 4), (x0 + 180, y - 10), (x0 + 250, y + 2),
           (x1, y - 4), (x1, y + 50), (x0, y + 50)]
    f.poly(pts, "#57534e", EDGE, SW_THIN)


@figure("rod_rock_bottom_250-53a4", h=470, nec="250.53(A)(4)",
        records={TRENCHES[0]: {}, TRENCHES[1]: {"like": TRENCHES[0]}})
def rod_rock_bottom(f):
    f.title("Driving a ground rod: three ways in (section view)", y=34)
    grade, ft = 150, 28.0
    f.grade(grade, 20, f.w - 20, label=None, soil_h=f.h - grade - 70)
    _rock(f, 260, 780, 350)
    f.text(640, 392, "rock bottom", T_NOTE, TEXT, bold=True)
    for x, cap in ((100, "vertical"), (330, "at an angle"), (620, "in a trench")):
        f.text(x, 110, cap, T_NOTE, TEXT, bold=True)
    rlen = 7 * ft
    f.rod(100, grade, rlen)
    f.ext(110, grade + rlen, 158, grade + rlen)
    f.dim_v(150, grade, grade + rlen)
    f.lines(160, 260, ["8 ft", "in soil"], T_NOTE, DIM, "start", True, gap=1.1)
    ax, run = 270, rlen * 0.7071
    f.dline(ax, grade, ax, grade + 170, MUTED, SW_THIN)
    f.line(ax, grade, ax + run, grade + run, ROD, 9)
    f.poly([(ax + run + 2, grade + run - 6), (ax + run - 6, grade + run + 2), (ax + run + 8, grade + run + 8)], ROD)
    f.path(f"M {ax} {grade + 80} A 80 80 0 0 0 {ax + 56.6:.1f} {grade + 56.6:.1f}", DIM, SW_THIN)
    f.lines(ax + 44, grade + 122, ["45 deg", "max"], T_MIN, DIM, bold=True, gap=1.0)
    tx0, tx1, depth = 520, 720, 2.5 * ft
    f.rect(tx0, grade, tx1 - tx0, depth, fill=TRENCH, stroke=EDGE, sw=SW_THIN)
    f.line(tx0 + 12, grade + depth - 8, tx1 - 12, grade + depth - 8, ROD, 9)
    f.ext(tx1 + 2, grade + depth, 746, grade + depth)
    f.dim_v(740, grade, grade + depth)
    f.value(620, grade + depth + 40, "30 in", what="the trench depth")
    f.text(620, grade + depth + 70, "deep, or more", T_MIN, MUTED)
    f.tag(24, f.h - 14, "NEC 250.53(A)(4)")


@figure("rod_pipe_size_250-52a5", h=420, nec="250.52(A)(5)",
        records={RODS[0]: {}, RODS[1]: {"like": RODS[0]}, PIPE[0]: {}})
def rod_pipe_size(f):
    f.title("Rod and pipe electrodes: minimum sizes", y=34)
    f.rect(120, 80, 30, 280, fill=ROD, stroke=AMBER, sw=SW_THIN, rx=4)
    f.poly([(120, 360), (150, 360), (135, 392)], ROD, AMBER, SW_THIN)
    f.lines(190, 116, ["rod: copper-coated steel", "or stainless"], T_NOTE, TEXT, "start", True, gap=1.1)
    f.value(190, 186, "5/8 in diameter", 28, anchor="start", pad=6, records=RODS, what="the rod diameter")
    f.rect(520, 80, 60, 300, fill=STEEL, stroke=LINE, sw=SW_OBJ, rx=3)
    f.rect(532, 80, 36, 300, fill=PANEL_2, stroke=LINE, sw=SW_THIN)
    f.lines(600, 116, ["pipe or conduit", "electrode"], T_NOTE, TEXT, "start", True, gap=1.1)
    f.value(600, 186, "trade size 3/4", 28, anchor="start", pad=6, records=PIPE, what="the pipe trade size")
    f.lines(600, 240, ["steel: galvanized or", "metal-coated"], T_MIN, MUTED, "start", gap=1.1)
    f.tag(f.w - 24, f.h - 14, "NEC 250.52(A)(5)", anchor="end")


@figure("ground_ring_250-52a4", h=420, nec="250.52(A)(4)", records=RING)
def ground_ring(f):
    f.title("Ground ring around a building (plan view)", y=34)
    f.rect(160, 110, 300, 200, fill=PANEL, stroke=LINE, sw=SW_STRUCT)
    f.text(310, 218, "building", T_LABEL, TEXT, bold=True)
    f.rect(120, 76, 380, 268, stroke=ROD, sw=6, rx=10)
    f.text(310, 376, "bare copper ring in contact with the earth", T_NOTE, MUTED)
    f.text(540, 130, "ring conductor:", T_NOTE, TEXT, "start", True)
    f.value(540, 172, "2 AWG or larger", T_LABEL, anchor="start", pad=6, what="the ring size")
    f.text(540, 236, "20 ft or more", T_NOTE, TEXT, "start", True)
    f.text(540, 264, "of conductor", T_NOTE, MUTED, "start")
    f.tag(f.w - 24, f.h - 14, "NEC 250.52(A)(4)", anchor="end")


FAIR = ["final-exam-#2-001", "open-book-exam-#5-001"]


def _zone_circle(f, cx, cy, r):
    f.add(f'<circle cx="{cx:.1f}" cy="{cy:.1f}" r="{r:.1f}" fill="{ZONE}" fill-opacity="0.12" '
          f'stroke="{ZONE}" stroke-width="{SW_OBJ}"/>')


def _ride(f, x, ground, w=70, h=64):
    f.poly([(x, ground), (x + w / 2, ground - h), (x + w, ground)], PANEL_2, TEXT, SW_OBJ)
    f.line(x + w / 2, ground - h, x + w / 2, ground - h - 16, TEXT, SW_THIN)
    f.poly([(x + w / 2, ground - h - 16), (x + w / 2 + 16, ground - h - 10), (x + w / 2, ground - h - 4)], AMBER)


@figure("fair_structures_lines_525-5b", h=470, nec="525.5(B)(2)",
        records={FAIR[0]: {}, FAIR[1]: {"like": FAIR[0]}})
def fair_structures(f):
    f.title("Rides and tents near overhead lines (elevation)", y=34)
    ground = 410
    f.grade(ground, 20, f.w - 20, label=None, soil_h=40)
    tx, ty, half, oc = 330, 160, 110, 40
    f.line(tx, ty - 10, tx, ground, STEEL, 12)
    f.line(tx - 60, ty, tx + 60, ty, STEEL, 8)
    f.hatch(tx - oc - half, ty, 2 * (oc + half), ground - ty)
    f.rect(tx - oc - half, ty, 2 * (oc + half), ground - ty, stroke=ZONE, sw=SW_OBJ)
    for dx in (-oc, 0, oc):
        f.circle(tx + dx, ty, 8, fill=WIRE_HOT, stroke=BG, sw=SW_THIN)
    f.ext(tx + oc, ty + 10, tx + oc, ty + 52)
    f.ext(tx + oc + half, ty + 10, tx + oc + half, ty + 52)
    f.dim_h(tx + oc, tx + oc + half, ty + 40)
    f.text(tx + oc + half / 2, ty + 72, "15 ft", T_LABEL, DIM, bold=True)
    b = f.text(40, 86, "conductors over", 26, TEXT, "start", True)
    f.value(b[0] + b[2] + 12, 86, "600 V", 26, anchor="start", pad=5, what="the voltage limit")
    _ride(f, tx - 60, ground)
    f.mark_no(tx - 25, ground - 110)
    _ride(f, tx + oc + half + 40, ground)
    f.mark_ok(tx + oc + half + 75, ground - 110)
    f.text(tx + oc + half + 124, ground - 8, "ride or tent", T_MIN, TEXT, "start")
    f.card(600, 120, 180, 200, "Keep out")
    f.lines(614, 186, ["not under the lines,", "nor within 15 ft", "sideways, all the", "way to grade"], T_MIN,
            TEXT, "start", gap=1.2)
    f.tag(f.w - 24, f.h - 10, "NEC 525.5(B)(2)", anchor="end")


FENCE = ["final-exam-#2-059", "open-book-exam-#11-007"]


@figure("fence_bonding_250-194a", h=470, nec="250.194(A)",
        records={FENCE[0]: {}, FENCE[1]: {"like": FENCE[0]}})
def fence_bonding(f):
    f.title("Metal fence around exposed live equipment (plan)", y=34)
    x0, y0, x1, y1 = 60, 80, 520, 420
    f.rect(x0, y0, x1 - x0, y1 - y0, fill=PANEL, op=0.35)
    for a, b in (((x0, y0), (x1, y0)), ((x1, y0), (x1, y1)), ((x0, y1), (x0, y0))):
        f.dline(a[0], a[1], b[0], b[1], LINE, SW_OBJ + 1, 6, 5)
    f.dline(x0, y1, 250, y1, LINE, SW_OBJ + 1, 6, 5)
    f.dline(330, y1, x1, y1, LINE, SW_OBJ + 1, 6, 5)
    f.path(f"M 250 {y1} A 80 80 0 0 1 330 {y1 - 6}", EDGE, SW_THIN)
    f.text(290, y1 + 34, "gate", T_NOTE, MUTED)
    # Exposed equipment.
    ex0, ey0, ex1, ey1 = 200, 170, 380, 290
    f.rect(ex0, ey0, ex1 - ex0, ey1 - ey0, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=6)
    for k in range(3):
        f.circle(ex0 + 45 + k * 45, ey0 + 36, 12, fill=BG, stroke=AMBER, sw=SW_OBJ)
    f.lines(290, ey0 + 84, ["exposed live", "parts"], T_NOTE, TEXT, bold=True, gap=1.05)
    # Distance to the fence.
    f.ext(ex1 + 4, 230, x1 - 4, 230)
    f.dim_h(ex1, x1, 230)
    f.value((ex1 + x1) / 2, 214, "16 ft", 28, pad=6, what="the bonding distance")
    f.text((ex1 + x1) / 2, 262, "or less", T_MIN, MUTED)
    # Grounding electrode system and jumpers at the corners and gate posts.
    f.dline(x0 + 26, y0 + 26, x1 - 26, y0 + 26, WIRE_GND, SW_THIN, 8, 6)
    f.dline(x1 - 26, y0 + 26, x1 - 26, y1 - 26, WIRE_GND, SW_THIN, 8, 6)
    f.dline(x0 + 26, y1 - 26, x1 - 26, y1 - 26, WIRE_GND, SW_THIN, 8, 6)
    f.dline(x0 + 26, y0 + 26, x0 + 26, y1 - 26, WIRE_GND, SW_THIN, 8, 6)
    for px, py, qx, qy in ((x0, y0, x0 + 26, y0 + 26), (x1, y0, x1 - 26, y0 + 26), (x1, y1, x1 - 26, y1 - 26),
                           (x0, y1, x0 + 26, y1 - 26), (250, y1, 250, y1 - 26), (330, y1, 330, y1 - 26)):
        f.line(px, py, qx, qy, WIRE_GND, SW_WIRE)
        f.circle(px, py, 7, fill=AMBER)
    f.line(250, y1 + 6, 330, y1 + 6, WIRE_GND, SW_THIN)
    # Legend and rules.
    lx = 548
    f.rect(lx - 8, 70, 248, 350, fill=PANEL, stroke=EDGE, sw=SW_THIN, rx=8)
    f.legend([(LINE, "metal fence", "dash"), (WIRE_GND, "bonding jumper"), (WIRE_GND, "grounding grid", "dash")],
             lx + 6, 104)
    f.lines(lx + 6, 222, ["jumpers at every", "corner, and every", "160 ft along the", "fence or less"], T_MIN, TEXT,
            "start", gap=1.15)
    f.lines(lx + 6, 330, ["gate posts bonded,", "buried jumper", "across the gate"], T_MIN, TEXT, "start", gap=1.15)
    f.tag(f.w - 24, f.h - 10, "NEC 250.194(A)", anchor="end")


@figure("therapeutic_tub_gfci_680-62e", h=420, nec="680.62(E)", records=["open-book-exam-#2-023"])
def therapeutic_tub(f):
    f.title("Therapy room with a hydrotherapy tub (plan)", y=34)
    x0, y0, x1, y1 = 40, 70, 520, 400
    f.rect(x0, y0, x1 - x0, y1 - y0, fill=PANEL, op=0.4, stroke=LINE, sw=SW_STRUCT)
    tx, ty, tw, th = 152, 190, 160, 96
    d = 108
    # The zone: 6 ft out from the tub edge all around, measured horizontally.
    f.rect(tx - d, ty - d, tw + 2 * d, th + 2 * d, fill=ZONE, op=0.12, stroke=ZONE, sw=SW_OBJ, rx=26 + d)
    f.rect(tx, ty, tw, th, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=26)
    f.rect(tx + 12, ty + 12, tw - 24, th - 24, fill=WATER, stroke=WATER_EDGE, sw=SW_THIN, rx=18)
    f.text(tx + tw / 2, ty + th / 2 + 8, "tub", T_LABEL, TEXT, bold=True)
    # Receptacles on the walls: one inside the zone, one outside.
    f.plan_receptacle(x0 + 22, 268, gfci=True)
    f.text(x0 + 46, 275, "GFCI", T_NOTE, OK, "start", True)
    f.plan_receptacle(x1 - 18, 250)
    f.lines(x1 - 46, 150, ["outside:", "no rule", "here"], T_MIN, MUTED, gap=1.1)
    ay = ty + th / 2
    f.ext(tx + tw - 4, ay, tx + tw + 4, ay)
    f.dim_h(tx + tw, tx + tw + d, ay)
    f.value(tx + tw + d / 2, ay - 18, "6 ft", 28, pad=6, what="the GFCI radius")
    f.rect(546, 70, 234, 250, fill=PANEL, stroke=EDGE, sw=SW_THIN, rx=8)
    f.lines(560, 110, ["Every receptacle", "within the zone", "(measured from the", "tub edge) has GFCI", "protection."],
            T_NOTE, TEXT, "start", gap=1.2)
    f.plan_receptacle(572, 290, gfci=True)
    f.text(596, 297, "= GFCI", T_NOTE, TEXT, "start")
    f.tag(f.w - 24, f.h - 10, "NEC 680.62(E)", anchor="end")


EMERGE = ["open-book-exam-#6-008"]
LOOPS = ["open-book-exam-#5-020"]


@figure("emerging_grade_300-5d1", h=480, nec="300.5(D)(1)", records=EMERGE)
def emerging_grade(f):
    f.title("Direct-buried conductors rising up a pole (section view)", y=34)
    grade, ft = 330, 26.0
    f.grade(grade, 20, f.w - 20, label=None, soil_h=f.h - grade - 20)
    f.text(f.w - 26, grade - 10, "finished grade", T_NOTE, MUTED, "end")
    px = 260
    f.line(px, 60, px, grade + 20, WOOD, 20)
    rx, top = px + 22, grade - 8 * ft
    f.conduit(rx, top, rx, grade + 60, 12)
    f.cable([(rx, grade + 60), (rx, grade + 100), (rx + 380, grade + 100)], TEXT, 5)
    f.text(rx + 200, grade + 128, "buried at the cover depth", T_MIN, MUTED)
    f.ext(rx + 10, top, 140, top)
    f.dim_v(150, top, grade)
    f.value(136, (top + grade) / 2 + 8, "8 ft", 28, anchor="end", pad=6, what="the protected height")
    f.lines(rx + 24, 140, ["raceway or", "enclosure"], T_NOTE, TEXT, "start", True, gap=1.1)
    f.leader(rx + 60, 166, rx + 8, 200)
    f.lines(500, 170, ["protected from", "finished grade up", "to the marked height"], T_NOTE, MUTED, "start",
            gap=1.15)
    f.tag(f.w - 24, 64, "NEC 300.5(D)(1)", anchor="end")


@figure("frost_s_loop_300-5j", h=440, nec="300.5(J)", records=LOOPS)
def frost_s_loop(f):
    f.title("Direct-buried cable where frost moves the soil (section view)", y=34)
    grade = 230
    f.grade(grade, 20, f.w - 20, label=None, soil_h=f.h - grade - 20)
    f.text(f.w - 26, grade - 10, "grade", T_NOTE, MUTED, "end")
    sx = 460
    f.rect(sx + 34, grade - 170, 16, 190, fill=WOOD, op=0.8, stroke="#ca8a04", sw=SW_THIN)
    f.conduit(sx, grade - 70, sx, grade + 50, 12)
    f.disconnect(sx - 38, grade - 170, 76, 100)
    f.text(sx - 52, grade - 112, "disconnect", T_NOTE, TEXT, "end", True)
    loop = f"M {sx} {grade + 50} c 0 30 -70 20 -70 50 s 70 20 70 50 s -70 20 -40 30 L {sx - 300} {grade + 180}"
    f.path(loop, TEXT, 5)
    f.mask(sx - 90, grade + 44, 110, 120, what="the slack loop in the cable")
    f.lines(sx + 60, grade + 60, ["frost heave and", "settling soil:", "leave slack"], T_NOTE, MUTED, "start",
            gap=1.15)
    f.value(sx + 60, grade + 164, "S loop", T_NOTE, anchor="start", pad=5, what="the name of the loop")
    for k in range(4):
        f.arrow(100 + k * 60, grade + 40, 100 + k * 60, grade + 8, AMBER, SW_THIN)
    f.text(190, grade + 70, "frost", T_NOTE, AMBER, bold=True)
    f.tag(f.w - 24, 64, "NEC 300.5(J)", anchor="end")


@figure("luminaire_roof_decking_410-10f", h=450, nec="410.10(F)", records=["open-book-exam-#3-021"])
def roof_decking(f):
    f.title("Luminaire under metal roof decking (section)", y=34)
    y_top, pitch, rib = 110, 80, 30
    pts = []
    for k in range(9):
        x = 40 + k * pitch
        pts += [(x, y_top), (x + 20, y_top), (x + 30, y_top + rib), (x + 60, y_top + rib), (x + 70, y_top)]
    f.polyline(pts, STEEL, 6)
    f.rect(40, y_top - 26, 720, 26, fill=PANEL, stroke=EDGE, sw=SW_THIN)
    f.text(400, y_top - 36, "roofing on corrugated metal decking", T_NOTE, MUTED)
    for x in (330, 470):
        f.line(x, y_top - 20, x, y_top + rib + 24, AMBER, 4)
        f.poly([(x - 5, y_top + rib + 24), (x + 5, y_top + rib + 24), (x, y_top + rib + 36)], AMBER)
    f.lines(640, 230, ["roofing screws can", "come through"], T_MIN, AMBER, gap=1.1)
    f.leader(566, 214, 476, y_top + rib + 30, AMBER)
    low = y_top + rib
    lum_top = low + 1.5 * 36
    # Strip luminaire on two hangers: channel, end caps, lens below.
    f.line(300, lum_top, 300, low, LINE, 3)
    f.line(500, lum_top, 500, low, LINE, 3)
    for hx in (300, 500):
        f.rect(hx - 10, low - 2, 20, 6, fill=STEEL, stroke=TEXT, sw=1)
    f.rect(260, lum_top, 280, 40, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=4)
    f.rect(252, lum_top + 4, 10, 44, fill=EDGE, stroke=TEXT, sw=1.5, rx=2)
    f.rect(538, lum_top + 4, 10, 44, fill=EDGE, stroke=TEXT, sw=1.5, rx=2)
    f.path(f"M 264 {lum_top + 40} Q 400 {lum_top + 64} 536 {lum_top + 40} Z", TEXT, 1.5, LINE)
    f.text(400, lum_top + 28, "luminaire", T_NOTE, TEXT, bold=True)
    f.ext(250, low, 150, low)
    f.ext(256, lum_top, 150, lum_top)
    f.dim_v(160, low, lum_top)
    f.value(146, lum_top + 50, "1 1/2 in", 28, anchor="middle", pad=6, what="the clearance")
    f.text(146, lum_top + 80, "or more", T_MIN, MUTED)
    f.lines(40, lum_top + 116, ["measured from the lowest surface", "of the decking to the top of the luminaire"],
            T_MIN, TEXT, "start", gap=1.1)
    f.lines(40, lum_top + 196, ["Not required if the decking is covered", "with 2 in or more of concrete."], T_MIN,
            MUTED, "start", gap=1.1)
    f.tag(f.w - 24, f.h - 10, "NEC 410.10(F)", anchor="end")
