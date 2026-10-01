"""Burial cover, Table 300.5(A)."""
from nec_style import *  # noqa: F401,F403


@figure("burial_under_concrete_300-5", h=450, nec="Table 300.5(A) Column 1, 300.5(A) cover definition",
        records={"final-exam-#1-049": {}, "open-book-exam-#4-004": {},
                 "open-book-exam-#7-013": {"when": "after"}})
def burial(f):
    grade, in_px = 150, 11.0
    slab_top = grade - 2 * in_px
    cable_top = slab_top + 18 * in_px
    f.title("Cover = top of the concrete to the top of the cable", y=40)
    f.soil(20, grade, f.w - 40, f.h - grade - 20)
    tx0, tx1 = 330, 490
    f.rect(tx0, grade, tx1 - tx0, cable_top - grade + 40, fill=TRENCH, op=0.95)
    f.concrete(200, slab_top, 400, grade - slab_top)
    f.text(400, slab_top - 12, "2 in concrete", T_LABEL + 2, TEXT, bold=True)
    f.line(20, grade, 200, grade, LINE, SW_STRUCT)
    f.line(600, grade, f.w - 20, grade, LINE, SW_STRUCT)
    f.text(28, grade - 12, "grade", T_NOTE, MUTED, "start")
    cx = (tx0 + tx1) / 2
    f.circle(cx, cable_top + 13, 13, fill=PANEL_2, stroke=TEXT, sw=3)
    for dx, col in ((-5, WIRE_HOT), (5, WIRE_NEU)):
        f.circle(cx + dx, cable_top + 10, 4, fill=col)
    f.circle(cx, cable_top + 19, 3.5, fill=WIRE_GND)
    f.text(cx, cable_top + 66, "direct-buried cable", T_LABEL, TEXT, bold=True)
    x = 300
    f.ext(x - 10, cable_top, cx - 14, cable_top)
    f.dim_v(x, slab_top, cable_top)
    f.value_lines(x - 16, 250, ["18 in", "min"], anchor="end", label="?")
    f.lines(520, 250, ["Column 1:", "direct burial", "cables"], T_LABEL, MUTED, "start", True)
    f.tag(f.w - 24, f.h - 30, "NEC Table 300.5(A)", anchor="end")
