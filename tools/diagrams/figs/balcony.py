"""Balcony, deck and porch receptacle, 210.52(E)(3)."""
from nec_style import *  # noqa: F401,F403


@figure("balcony_receptacle_210-52e3", h=460, nec="210.52(E)(3)",
        records={"final-exam-#1-008": {}, "open-book-exam-#10-020": {},
                 "final-exam-#2-049": {"like": "open-book-exam-#10-020"},
                 "open-book-exam-#2-025": {"like": "final-exam-#1-008"}, "open-book-exam-#11-001": {}})
def balcony(f):
    wall_x, deck_y, grade, ft = 250, 320, 420, 30.0
    f.rect(100, 40, wall_x - 100, grade - 40, fill=PANEL, stroke=EDGE, sw=SW_OBJ)
    f.text(175, 84, "DWELLING", T_LABEL, MUTED, bold=True)
    f.rect(wall_x - 16, deck_y - 180, 16, 180, fill=PANEL_2, stroke=LINE, sw=SW_THIN)
    f.text(214, 240, "door", T_NOTE, MUTED, rotate=-90)
    f.line(wall_x, 40, wall_x, grade, LINE, SW_STRUCT + 1)
    dx0, dx1 = wall_x + 12, 770
    f.rect(dx0, deck_y, dx1 - dx0, 18, fill="#475569", stroke=LINE, sw=SW_THIN)
    for x in (300, 740):
        f.rect(x - 8, deck_y + 18, 16, grade - deck_y - 18, fill=PANEL_2, stroke=EDGE, sw=SW_THIN)
    f.line(dx1 - 8, deck_y, dx1 - 8, deck_y - 110, LINE, 7)
    f.line(dx1 - 70, deck_y - 110, dx1 - 8, deck_y - 110, LINE, 7)
    f.grade(grade)
    f.text(560, deck_y - 38, "BALCONY / DECK / PORCH", T_LABEL, MUTED, bold=True)
    f.text(560, deck_y - 10, "walking surface", T_NOTE, MUTED)
    f.leader(366, deck_y + 64, wall_x + 6, deck_y + 12, DIM)
    t = f.text(372, deck_y + 72, "within", T_NOTE, DIM, "start", True)
    v = f.value(t[0] + t[2] + 7, deck_y + 72, "4 in", T_NOTE, fill=DIM, anchor="start", pad=4,
                records=["open-book-exam-#11-001"], what="the distance from the dwelling")
    f.text(v[0] + v[2] + 7, deck_y + 72, "of the dwelling", T_NOTE, DIM, "start", True)
    ry = deck_y - 6.5 * ft
    f.receptacle(wall_x + 16, ry, 48)
    f.text(wall_x + 46, ry - 34, "receptacle", T_LABEL, TEXT, "start", True)
    x = wall_x + 80
    f.ext(wall_x + 34, ry, x + 14, ry)
    f.dim_v(x, ry, deck_y)
    f.value_lines(x + 18, 172, ["6 ft 6 in max", "(2.0 m, 78 in)"], 32, anchor="start", label="? max")
    f.lines(470, 64, ["Also: GFCI 210.8(A)(3),", "weather-resistant 406.9"], T_NOTE, MUTED, "start")
    f.tag(f.w - 24, f.h - 10, "NEC 210.52(E)(3)", anchor="end")
