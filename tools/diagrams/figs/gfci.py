"""Where GFCI protection is required, 210.8."""
from nec_style import *  # noqa: F401,F403

TUB = ["open-book-exam-#1-010"]
CRAWL = ["final-exam-#3-006", "open-book-exam-#1-014"]
OUTDOOR = ["open-book-exam-#4-002"]


@figure("gfci_dwelling_210-8a", h=470, nec="210.8(A)",
        records={"open-book-exam-#1-010": {},
                 "final-exam-#1-012": {"when": "after"}, "final-exam-#3-064": {"when": "after"},
                 "open-book-exam-#4-021": {"when": "after"},
                 "open-book-exam-#2-013": {"like": "final-exam-#1-012"}, "open-book-exam-#3-004": {"when": "after"},
                 "open-book-exam-#5-016": {"when": "after"}})
def gfci_dwelling(f):
    roof, floor = 150, 400
    hx0, gx1, lx1, hx1 = 30, 230, 430, 700
    f.title("Dwelling: GFCI receptacles (section)", x=30, y=40)
    f.line(hx0 - 12, roof, hx1 + 50, roof, LINE, SW_STRUCT + 2)
    for x in (hx0, gx1, hx1):
        f.wall(x, roof, floor)
    f.wall(lx1, roof, floor, thick=10)
    f.floor(floor, 20, f.w - 20)
    f.text((hx0 + gx1) / 2, 196, "GARAGE", T_NOTE, TEXT, bold=True)
    f.receptacle(130, 300, 50, gfci=True)
    f.text((gx1 + lx1) / 2, 196, "LAUNDRY", T_NOTE, TEXT, bold=True)
    f.rect(258, 314, 84, 86, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=5)
    f.line(261, 332, 339, 332, EDGE, SW_THIN)
    f.circle(328, 323, 3, fill=LINE)
    f.circle(300, 366, 24, fill=EDGE, stroke=TEXT, sw=SW_THIN)
    f.circle(300, 366, 16, fill=BG, stroke=LINE, sw=1.5)
    f.receptacle(390, 300, 46, gfci=True)
    f.text((lx1 + hx1) / 2, 196, "BATHROOM", T_NOTE, TEXT, bold=True)
    tx0, tx1 = 444, 560
    f.rect(tx0, 350, tx1 - tx0, 50, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=8)
    f.rect(tx0 + 8, 356, tx1 - tx0 - 16, 16, fill=WATER, stroke=WATER_EDGE, sw=SW_THIN, rx=4)
    f.text((tx0 + tx1) / 2, 430, "tub", T_NOTE, MUTED)
    rx = 656
    f.receptacle(rx, 330, 46, gfci=True)
    f.ext(tx1, 348, tx1, 240)
    f.ext(rx, 304, rx, 240)
    f.dim_h(tx1, rx, 250)
    f.value((tx1 + rx) / 2, 236, "6 ft", 28, records=TUB, label="? ft")
    f.text((tx1 + rx) / 2, 284, "from the tub edge", T_MIN, MUTED)
    sx, sy = hx1 + 34, roof + 40
    f.receptacle(sx, sy, 36)
    f.line(sx, sy - 18, sx, roof + 4, TEXT, 3)
    f.lines(440, 72, ["snow-melt receptacle, not readily", "accessible, own circuit: exempt"], T_MIN, MUTED,
            "start", gap=1.15)
    f.leader(700, 104, sx - 10, sy - 12)
    f.tag(f.w - 24, f.h - 12, "NEC 210.8(A)", anchor="end")


@figure("crawl_space_light_210-8c", h=420, nec="210.8(C)",
        records={"final-exam-#3-006": {}, "open-book-exam-#1-014": {},
                 "open-book-exam-#2-004": {"like": "final-exam-#3-006"}})
def crawl_space_light(f):
    f.title("Lighting outlet in a crawl space (section view)", y=36)
    floor, grade = 170, 360
    f.rect(40, floor - 16, 720, 16, fill=WOOD, op=0.8, stroke="#ca8a04", sw=SW_THIN)
    f.text(400, floor - 30, "house floor", T_NOTE, MUTED)
    f.wall(40, floor, grade, thick=24)
    f.wall(760, floor, grade, thick=24)
    f.soil(20, grade, f.w - 40, f.h - grade - 10)
    f.line(20, grade, f.w - 20, grade, LINE, SW_STRUCT)
    f.text(400, grade - 20, "crawl space", T_LABEL, MUTED, bold=True)
    f.box(300, floor + 4, 30)
    f.circle(300, floor + 44, 14, fill=AMBER, stroke=TEXT, sw=SW_THIN)
    f.text(330, floor + 52, "lighting outlet", T_NOTE, TEXT, "start", True)
    f.text(330, floor + 82, "GFCI protected when", T_NOTE, OK, "start", True)
    f.value(330, floor + 120, "120 V or less", 26, anchor="start", label="? V", what="the voltage limit")
    f.tag(f.w - 24, f.h - 14, "NEC 210.8(C)", anchor="end")


@figure("nondwelling_sink_210-8b", h=420, nec="210.8(B)", when="after", records=["open-book-exam-#1-012"])
def nondwelling_sink(f):
    f.title("Not a dwelling: a sink with food or beverage prep (elevation)", y=36)
    top, floor = 260, 380
    f.rect(60, top, 520, 16, fill=LINE)
    f.rect(70, top + 16, 500, floor - top - 16, fill=PANEL_2, stroke=EDGE, sw=SW_THIN)
    f.floor(floor, 20, f.w - 20)
    f.rect(130, top - 2, 110, 20, fill=WATER, stroke=WATER_EDGE, sw=SW_THIN, rx=3)
    f.polyline([(200, top - 2), (200, top - 50), (170, top - 50), (170, top - 38)], TEXT, 5)
    f.text(185, top + 50, "sink", T_NOTE, TEXT, bold=True)
    f.rect(420, top - 80, 70, 80, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=5)
    f.rect(432, top - 44, 46, 36, fill=WATER, stroke=WATER_EDGE, sw=SW_THIN, rx=3)
    f.text(455, top + 50, "coffee maker", T_NOTE, TEXT, bold=True)
    f.receptacle(320, top - 60, 50, gfci=True)
    f.card(600, 90, 180, 200, "GFCI here")
    f.lines(614, 150, ["receptacles in", "areas with a sink", "and permanent", "food or drink prep"], T_MIN, TEXT,
            "start", gap=1.2)
    f.highlight(606, 128, 168, 156)


@figure("outdoor_outlets_210-8f", h=420, nec="210.8(F)", records=OUTDOOR)
def outdoor_outlets(f):
    f.title("Dwelling: outdoor outlets", y=36)
    grade = 360
    f.rect(40, 90, 300, grade - 90, fill=PANEL, stroke=LINE, sw=SW_STRUCT)
    f.text(190, 130, "house wall", T_NOTE, MUTED)
    f.grade(grade, 20, f.w - 20, label=None, soil_h=f.h - grade - 10)
    f.receptacle(130, 260, 50, gfci=True)
    f.text(130, 316, "receptacle", T_NOTE, TEXT, bold=True)
    f.rect(420, 250, 120, 110, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=6)
    f.circle(480, 290, 34, fill=BG, stroke=EDGE, sw=SW_THIN)
    for k in range(4):
        f.line(452, 270 + k * 13, 508, 270 + k * 13, EDGE, 2)
    f.text(480, 394, "A/C condenser", T_NOTE, TEXT, bold=True)
    f.disconnect(350, 200, 50, 70)
    f.line(400, 240, 420, 280, TEXT, 4)
    f.card(570, 90, 210, 200, "GFCI on outdoor")
    f.lines(584, 150, ["outlets fed by", "single-phase circuits,", "150 V to ground", "or less, and"], T_MIN, TEXT,
            "start", gap=1.2)
    f.value(584, 260, "50 A or less", T_NOTE, anchor="start", label="? A", what="the amp limit")
    f.tag(f.w - 24, f.h - 14, "NEC 210.8(F)", anchor="end")
