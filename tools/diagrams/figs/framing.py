"""Protecting cables in wood framing, 300.4(A)(2) and 300.4(D)."""
from nec_style import *  # noqa: F401,F403


def _nm_section(f, x, y, w=36, h=18):
    """Flat NM cable seen end-on, top-left at (x, y)."""
    f.rect(x, y, w, h, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=h / 2)
    for k in (0.28, 0.5, 0.72):
        f.circle(x + w * k, y + h / 2, 3, fill=TEXT)


@figure("framing_protection_300-4", h=450, nec="300.4(A)(2), 300.4(D)",
        records={"final-exam-#1-055": {}, "open-book-exam-#1-004": {},
                 "open-book-exam-#5-010": {"like": "final-exam-#1-055"}})
def framing_protection(f):
    parallel = ["final-exam-#1-055"]
    notch = ["open-book-exam-#1-004"]
    inch = 56.0
    face, sd, sw = 150, 3.5 * inch, 1.5 * inch
    # Left: cable run parallel to a stud (plan view).
    f.text(200, 40, "Parallel to a stud (plan)", T_LABEL, MUTED, bold=True)
    f.rect(30, face - 14, 340, 14, fill=PANEL_2, stroke=LINE, sw=SW_THIN)
    f.text(30, face - 26, "drywall", T_NOTE, MUTED, "start")
    sx = 70
    f.stud(sx, face, sw, sd)
    f.text(sx + sw / 2, face + sd + 34, "stud", T_NOTE, TEXT, bold=True)
    f.line(sx + sw / 2, 70, sx + sw / 2, face + 40, TEXT, 4)
    f.rect(sx + sw / 2 - 11, 64, 22, 7, fill=TEXT, rx=2)
    f.text(sx + sw / 2 + 20, 84, "screw", T_NOTE, MUTED, "start")
    cy = face + 1.25 * inch
    _nm_section(f, 186, cy, 36, 18)
    f.text(204, cy + 50, "NM cable", T_NOTE, TEXT, bold=True)
    f.ext(sx + sw + 2, face, 278, face)
    f.ext(224, cy, 278, cy)
    f.dim_v(270, face, cy)
    f.value(284, cy - 14, "1 1/4 in", anchor="start", records=parallel)
    # Right: cable laid in a notch, steel plate over it (side view of the stud).
    f.text(610, 40, "In a notch (side view)", T_LABEL, MUTED, bold=True)
    x0, x1 = 500, f.w - 30
    n0, nw, nd = 610, 48, 0.75 * inch
    f.stud(x0, face, x1 - x0, sd)
    f.rect(n0, face - 1, nw, nd + 1, fill=BG)
    f.polyline([(n0, face), (n0, face + nd), (n0 + nw, face + nd), (n0 + nw, face)], "#ca8a04", SW_THIN)
    _nm_section(f, n0 + 6, face + nd - 20, 36, 18)
    f.text((x0 + x1) / 2, face + sd + 34, "notched stud", T_NOTE, TEXT, bold=True)
    f.text(x0 - 10, 270, "NM cable", T_NOTE, TEXT, "end", True)
    f.leader(x0 - 8, 262, n0 + 8, face + nd - 10)
    f.rect(n0 - 34, face - 9, nw + 68, 9, fill=STEEL, stroke=TEXT, sw=SW_THIN)
    f.text(n0 - 44, face - 2, "steel plate", T_NOTE, TEXT, "end", True)
    f.value(n0 + nw / 2, 108, "1/16 in", records=notch)
    f.leader(n0 + nw / 2, 120, n0 + nw / 2, face - 10)
    f.tag(f.w - 24, f.h - 24, "NEC 300.4(A)(2), 300.4(D)", anchor="end")
