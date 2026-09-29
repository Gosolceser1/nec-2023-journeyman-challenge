"""Working space and dedicated equipment space, 110.26."""
import math

from nec_style import *  # noqa: F401,F403


def _dash_arc(f, cx, cy, r, a0, a1, color=MUTED, steps=18):
    """Door swing: dashed arc about (cx, cy), angles in degrees (screen coords, y down)."""
    for i in range(0, steps, 2):
        t0 = math.radians(a0 + (a1 - a0) * i / steps)
        t1 = math.radians(a0 + (a1 - a0) * (i + 1) / steps)
        f.line(cx + r * math.cos(t0), cy + r * math.sin(t0),
               cx + r * math.cos(t1), cy + r * math.sin(t1), color, SW_THIN)


def _hwall(f, x0, x1, y0, y1):
    f.rect(x0, y0, x1 - x0, y1 - y0, fill=PANEL_2, stroke=LINE, sw=SW_THIN)


DOOR_25 = "final-exam-#1-051"
MASONRY = "open-book-exam-#10-016"
OPEN_DOORS = "open-book-exam-#7-022"
GUARDED = "open-book-exam-#1-011"


@figure("working_space_110-26", h=480, nec="110.26 (open doors), Table 110.26(A)(1) Condition 2, 110.26(B), 110.26(C)(3)",
        records=[DOOR_25, MASONRY, OPEN_DOORS, GUARDED])
def working_space(f):
    f.title("Plan view (not to scale)", y=36)
    wt, wb = 60, 80           # equipment wall
    ct, cb = 300, 326         # opposite wall
    rx = 600                  # end wall with the personnel door
    sx0, sx1, sy1 = 140, 400, 124
    _hwall(f, 20, rx + 8, wt, wb)
    f.concrete(20, ct, rx - 20, cb - ct)
    # End wall with a door opening.
    hy, dw = 160, 90
    f.wall(rx, wt, hy)
    f.wall(rx, hy + dw, cb)
    # Switchboard and its working space.
    f.rect(sx0, wb, sx1 - sx0, sy1 - wb, fill=PANEL, stroke=TEXT, sw=SW_OBJ + 1, rx=4)
    f.text((sx0 + sx1) / 2, 110, "800 A SWITCHBOARD", T_NOTE, TEXT, bold=True)
    f.zone(sx0, sy1, sx1 - sx0, ct - sy1)
    f.text(262, 164, "live parts exposed", T_NOTE, NO, bold=True)
    f.text(250, 262, "working space", T_NOTE, ZONE, bold=True)
    # Equipment door swung open into the working space.
    dl = 75
    _dash_arc(f, sx1, sy1, dl, 180, 90)
    f.line(sx1, sy1, sx1, sy1 + dl, TEXT, 6)
    f.text(386, 214, "open door", T_NOTE, TEXT, "end")
    # Access left past the open door.
    f.ext(sx1 + 4, sy1 + dl, 432, sy1 + dl)
    f.dim_v(422, sy1 + dl, ct)
    f.value(436, 246, "24 in", anchor="start", records=[OPEN_DOORS], label="? in")
    f.text(436, 280, "x 6 1/2 ft high", T_NOTE, DIM, "start", True)
    # Passageway side: guard across the open end of the working space.
    f.text(76, 120, "passageway", T_MIN, MUTED)
    f.arrow(28, 164, 124, 164, MUTED, SW_THIN, both=True)
    f.line(sx0, sy1 + 6, sx0, ct - 6, AMBER, 4)
    for y in (sy1 + 8, (sy1 + ct) / 2, ct - 8):
        f.circle(sx0, y, 7, fill=AMBER)
    f.mask(sx0 - 14, sy1, 28, ct - sy1, records=[GUARDED], what="the guard drawn across the passageway")
    f.value(76, 246, "guarded", 28, records=[GUARDED])
    # Distance to the personnel door.
    f.ext(sx1, wb + 2, sx1, sy1)
    f.dim_h(sx1, rx - 8, 98)
    f.text(496, 132, "less than", T_NOTE, DIM, bold=True)
    f.value(496, 164, "25 ft", records=[DOOR_25], label="? ft")
    # Personnel door, swung 90 degrees outward with panic hardware.
    hx = rx + 8
    _dash_arc(f, hx, hy, dw, 90, 0)
    f.line(hx, hy, hx + dw, hy, TEXT, 6)
    f.line(hx + 10, hy + 9, hx + dw - 6, hy + 9, AMBER, 6)
    f.text(620, 132, "personnel door", T_NOTE, TEXT, "start", True)
    f.lines(620, 290, ["opens at least", "90 deg toward", "egress, listed", "panic or fire", "exit hardware"],
            T_NOTE, MUTED, "start")
    # The wall opposite the live parts.
    f.text(310, 360, "concrete, brick or tile wall", T_LABEL, TEXT, bold=True)
    f.value_lines(310, 400, ["considered grounded", "(Condition 2)"], 28, records=[MASONRY])
    f.tag(f.w - 24, f.h - 14, "NEC 110.26", anchor="end")


@figure("dedicated_space_110-26e", h=500, nec="110.26(A)(1)-(3), 110.26(E)(1)",
        records=["final-exam-#1-057"])
def dedicated_space(f):
    ceil, floor, ft = 96, 440, 40.0
    ws_top = floor - 6.5 * ft
    hx0, hx1, py0, py1 = 200, 290, 215, 330
    f.value(400, 34, "Sprinkler protection: permitted  (E)(1)(c)", T_LABEL, OK)
    f.text(400, 66, "Water pipes, ducts, leak protection: not permitted", T_NOTE, NO, bold=True)
    f.mask(40, 44, 720, 34, what="the not-permitted list (it narrows the choices)")
    # Front view.
    f.floor(floor, 30, 470)
    f.ceiling(ceil, 30, 470)
    f.text(400, 130, "front view", T_NOTE, MUTED)
    f.zone(140, ws_top, 210, floor - ws_top, DIM, 0.06)
    f.hatch(hx0, ceil, hx1 - hx0, floor - ceil)
    f.panel(hx0, py0, hx1 - hx0, py1 - py0, label=None)
    f.text(245, 358, "panel", T_NOTE, TEXT, bold=True)
    f.text(245, 420, "working space", T_NOTE, DIM, bold=True)
    f.dim_h(140, 350, 470)
    f.text(245, 494, "30 in min", 28, DIM, bold=True)
    f.dim_v(372, ws_top, floor)
    f.text(384, 300, "6 1/2 ft", 28, DIM, "start", True)
    f.dim_v(118, ceil, py0)
    f.lines(106, 136, ["6 ft or", "ceiling,", "if lower"], T_NOTE, DIM, "end", True)
    # Sprinkler branch and head inside the dedicated space: the answer.
    f.line(hx0 + 4, 118, hx1 - 4, 118, OK, 7)
    f.line(245, 118, 245, 136, OK, 7)
    f.poly([(232, 136), (258, 136), (245, 152)], OK)
    f.mark_ok(245, 180)
    f.mask(hx0 + 2, 102, hx1 - hx0 - 4, 102, what="sprinkler head drawn in the dedicated space")
    # Side view.
    wall, depth = 560, 24
    x3 = wall + depth + 3 * ft
    f.line(wall, ceil, wall, floor, LINE, 5)
    f.floor(floor, wall, 780)
    f.ceiling(ceil, wall, 780)
    f.lines(690, 124, ["hatched =", "dedicated space"], T_NOTE, ZONE, bold=True)
    f.zone(wall + depth, ws_top, x3 - wall - depth, floor - ws_top, DIM, 0.06)
    f.hatch(wall, ceil, depth, floor - ceil)
    f.rect(wall, py0, depth, py1 - py0, fill=PANEL, stroke=TEXT, sw=4, rx=3)
    f.dim_h(wall + depth, x3, 470)
    f.text((wall + depth + x3) / 2, 494, "3 ft min", 28, DIM, bold=True)
    f.lines((wall + depth + x3) / 2, 300, ["0-150 V", "to ground"], T_NOTE, MUTED)
