"""Where GFCI protection is required, 210.8."""
from nec_style import *  # noqa: F401,F403

TUB = ["open-book-exam-#1-010"]
CRAWL = ["final-exam-#3-006", "open-book-exam-#1-014"]
OUTDOOR = ["open-book-exam-#4-002"]


@figure("gfci_locations_210-8", h=500, nec="210.8(A) items (2), (3), (10), (11) and Ex. 1; 210.8(B)(3), (C), (F)",
        records={"open-book-exam-#1-010": {}, "final-exam-#3-006": {}, "open-book-exam-#1-014": {},
                 "open-book-exam-#4-002": {},
                 "final-exam-#1-012": {"when": "after"}, "final-exam-#3-064": {"when": "after"},
                 "open-book-exam-#1-012": {"when": "after"}, "open-book-exam-#4-021": {"when": "after"},
                 "open-book-exam-#2-004": {"like": "final-exam-#3-006"},
                 "open-book-exam-#2-013": {"like": "final-exam-#1-012"}, "open-book-exam-#3-004": {"when": "after"},
                 "open-book-exam-#5-016": {"when": "after"}})
def gfci_locations(f):
    roof, floor, grade = 160, 330, 420
    hx0, gx1, lx1, hx1 = 24, 150, 284, 500
    f.legend([(OK, "GFCI required", "box")], 40, 40)
    # Structure: roof, walls, garage slab, raised floor over the crawl space.
    f.soil(20, grade, f.w - 40, f.h - grade - 10)
    f.line(hx0 - 12, roof, hx1 + 50, roof, LINE, SW_STRUCT + 2)
    f.wall(hx0, roof, grade)
    f.wall(gx1, roof, grade)
    f.wall(hx1, roof, grade + 20)
    f.wall(lx1, roof, floor, thick=10)
    f.floor(floor, gx1 + 8, hx1 - 8)
    f.line(20, grade, f.w - 20, grade, LINE, SW_STRUCT)
    # Garage.
    f.text((hx0 + gx1) / 2, 200, "GARAGE", T_NOTE, TEXT, bold=True)
    f.receptacle(100, 350, 44, gfci=True)
    # Laundry.
    f.text((gx1 + lx1) / 2, 200, "LAUNDRY", T_NOTE, TEXT, bold=True)
    f.rect(168, 262, 64, 68, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=5)
    f.circle(200, 300, 18, fill="none", stroke=TEXT, sw=SW_THIN)
    f.receptacle(256, 270, 40, gfci=True)
    # Tub or shower: 6 ft from the outside edge.
    f.text((lx1 + hx1) / 2, 200, "TUB / SHOWER", T_NOTE, TEXT, bold=True)
    tx0, tx1 = 294, 382
    f.rect(tx0, 290, tx1 - tx0, 40, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=8)
    f.rect(tx0 + 8, 296, tx1 - tx0 - 16, 14, fill=WATER, stroke=WATER_EDGE, sw=SW_THIN, rx=4)
    rx = 466
    f.receptacle(rx, 290, 40, gfci=True)
    f.ext(tx1, 288, tx1, 240)
    f.ext(rx, 268, rx, 240)
    f.dim_h(tx1, rx, 248)
    f.value((tx1 + rx) / 2, 236, "6 ft", 28, records=TUB, label="? ft")
    # Crawl space lighting outlet.
    f.box(184, 346, 26)
    f.circle(184, 372, 11, fill=AMBER, stroke=TEXT, sw=SW_THIN)
    f.text(214, 362, "crawl space light", T_NOTE, TEXT, "start")
    f.value(214, 402, "120 V or less", 26, anchor="start", records=CRAWL, label="? V")
    # Snow-melting receptacle high under the eave (210.8(A) Ex. 1).
    sx, sy = hx1 + 26, roof + 38
    f.receptacle(sx, sy, 36)
    f.line(sx, sy - 18, sx, roof + 4, TEXT, 3)
    f.lines(40, 88, ["210.8(A) Ex. 1: not readily accessible,", "own snow-melt circuit: 426.28"], T_NOTE, MUTED, "start")
    f.leader(428, 114, sx - 14, sy - 6)
    # Outdoor outlet (210.8(F)).
    f.receptacle(hx1 + 26, 372, 40, gfci=True)
    f.text(556, 296, "OUTDOOR OUTLETS", T_NOTE, TEXT, "start", True)
    f.lines(556, 324, ["single-phase, 150 V", "to ground or less,"], T_NOTE, MUTED, "start")
    f.value(556, 402, "50 A or less", 26, anchor="start", records=OUTDOOR, label="? A")
    # Other than dwelling: sink + food or beverage prep (210.8(B)(3)).
    bx0, by0, bx1, by1 = 560, 24, 784, 250
    f.rect(bx0, by0, bx1 - bx0, by1 - by0, fill=PANEL, stroke=EDGE, sw=SW_OBJ, rx=8)
    f.text((bx0 + bx1) / 2, 54, "NOT A DWELLING", T_NOTE, TEXT, bold=True)
    f.lines((bx0 + bx1) / 2, 84, ["sink + food or", "beverage prep"], T_NOTE, MUTED)
    top = 196
    f.rect(bx0 + 12, top, bx1 - bx0 - 24, 12, fill=LINE)
    f.rect(bx0 + 18, top + 12, bx1 - bx0 - 36, by1 - top - 22, fill=PANEL_2, stroke=EDGE, sw=SW_THIN)
    f.rect(584, top - 2, 64, 16, fill=WATER, stroke=WATER_EDGE, sw=SW_THIN, rx=3)
    f.polyline([(628, top - 2), (628, top - 30), (608, top - 30), (608, top - 22)], TEXT, 4)
    f.rect(716, top - 48, 40, 48, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=4)
    f.rect(724, top - 26, 24, 22, fill=WATER, stroke=WATER_EDGE, sw=SW_THIN, rx=3)
    f.receptacle(680, top - 32, 36, gfci=True)
    f.tag(f.w - 24, f.h - 20, "NEC 210.8", anchor="end")
