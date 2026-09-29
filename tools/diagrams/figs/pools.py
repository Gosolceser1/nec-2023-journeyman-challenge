"""Pools, spas, storable pools and fountains, Article 680."""
from nec_style import *  # noqa: F401,F403

FAN = ["final-exam-#1-043", "open-book-exam-#4-011"]
UNDERGROUND = ["final-exam-#1-060"]
SIX_FT = ["final-exam-#3-059", "final-exam-#3-007"]
FOUNTAIN = ["final-exam-#1-024"]


def _fan(f, x, y, half=70, dashed=False):
    """Section view of a ceiling-suspended (paddle) fan, blades at y."""
    if dashed:
        f.dline(x - half, y, x + half, y, MUTED, 6, 12, 8)
        f.rect(x - 16, y - 16, 32, 16, fill="none", stroke=MUTED, sw=SW_THIN, rx=4)
        return
    f.line(x, y - 32, x, y - 16, LINE, 5)
    f.rect(x - 18, y - 18, 36, 18, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=4)
    f.line(x - half, y, x + half, y, TEXT, 7)


@figure("spa_fan_height_680-43", h=450, nec="680.43(B)(1)(a), (B)(1)(b)", records=FAN)
def spa_fan(f):
    ceil, deck, water, ft = 64, 380, 392, 24.75
    fx, half = 400, 70
    y12 = water - 12 * ft
    y75 = water - 9.8 * ft
    f.title("Paddle fan over (or within 5 ft of) an indoor spa", y=36)
    f.ceiling(ceil, 20, 780)
    f.line(fx, ceil, fx, y12 - 32, LINE, 5)
    _fan(f, fx, y12, half)
    _fan(f, fx, y75, half, dashed=True)
    # Deck and sunken spa.
    sx0, sx1 = 280, 520
    f.floor(deck, 20, sx0)
    f.floor(deck, sx1, 780)
    f.rect(sx0, deck, sx1 - sx0, f.h - deck - 8, fill=PANEL, stroke=LINE, sw=SW_OBJ)
    f.pool(sx0 + 12, water, sx1 - sx0 - 24, f.h - water - 20, label=None)
    f.text(400, deck - 18, "SPA / HOT TUB", T_LABEL, TEXT, bold=True)
    f.leader(640, 404, sx1 - 14, water + 2)
    f.text(646, 412, "max water level", T_NOTE, MUTED, "start")
    # Without GFCI: 12 ft.
    x = 560
    f.ext(fx + half, y12, x + 12, y12)
    f.ext(sx1 - 10, water, x + 12, water)
    f.dim_v(x, y12, water)
    f.text(576, 208, "no GFCI", T_LABEL, TEXT, "start", True)
    f.value_lines(576, 250, ["12 ft", "(3.7 m)"], anchor="start", records=FAN, label="? ft")
    # With GFCI: 7 ft 6 in.
    x = 240
    f.ext(fx - half, y75, x - 12, y75)
    f.ext(sx0 + 10, water, x - 12, water)
    f.dim_v(x, y75, water)
    f.text(224, 272, "with GFCI", T_LABEL, TEXT, "end", True)
    f.lines(224, 308, ["7 ft 6 in", "(2.3 m)"], 28, DIM, "end", True)
    f.text(f.w - 24, 104, "not to scale", T_MIN, MUTED, "end")
    f.tag(24, f.h - 18, "NEC 680.43(B)(1)")


@figure("pool_fountain_distances_680", h=480, nec="680.11(A), 680.22(A)(2), 680.35(D), 680.58",
        records=UNDERGROUND + SIX_FT + FOUNTAIN)
def pool_distances(f):
    ft = 16.0
    f.text(20, 30, "plan view, not to scale", T_NOTE, MUTED, "start")
    # Permanently installed pool.
    px0, py0, px1, py1 = 100, 180, 250, 288
    d5 = 5 * ft
    f.zone(px0 - d5, py0 - d5, px1 - px0 + 2 * d5, py1 - py0 + 2 * d5, ZONE, 0.08)
    f.rect(px0, py0, px1 - px0, py1 - py0, fill=WATER, stroke=WATER_EDGE, sw=SW_OBJ)
    f.text((px0 + px1) / 2, 242, "POOL", T_LABEL, TEXT, bold=True)
    f.text(px1 + d5, py1 + d5 + 32, "underground wiring zone", T_NOTE, ZONE, "end", True)
    x = px0 + 30
    f.dim_v(x, py1, py1 + d5)
    f.value(x + 14, py1 + 42, "5 ft", 28, anchor="start", records=UNDERGROUND, label="?")
    # LFMC run into the zone to the pool wall.
    cx = 200
    f.conduit(cx, 50, cx, py0 - 2, width=10)
    f.lines(cx - 16, 70, ["LFMC listed for", "direct burial"], T_NOTE, TEXT, "end")
    # Pump receptacle.
    # Drawn well outside the 5 ft zone: at true scale 6 ft would sit on its edge.
    rx, ry = px1 + d5 + 36, 226
    f.plan_receptacle(rx, ry, gfci=True)
    f.rect(rx + 22, ry - 20, 44, 40, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=6)
    f.text(rx + 44, ry + 8, "M", T_LABEL, TEXT, bold=True)
    f.line(rx + 12, ry, rx + 22, ry, TEXT, 3)
    f.lines(rx + 44, 164, ["pump", "motor"], T_NOTE, TEXT)
    f.ext(rx, ry + 14, rx, 262)
    f.dim_h(px1, rx, 254)
    f.value((px1 + rx) / 2, 286, "6 ft", 28, records=SIX_FT, label="?")
    f.lines(rx + 16, 300, ["pump", "receptacle:", "GFCI"], T_NOTE, TEXT)
    f.line(446, 30, 446, f.h - 30, EDGE, SW_THIN)
    ft = 12.0
    # Storable pool with audio equipment.
    sx, sy, sr = 510, 150, 45
    f.circle(sx, sy, sr, fill=WATER, stroke=WATER_EDGE, sw=SW_OBJ)
    f.text(462, 76, "storable pool", T_LABEL, TEXT, "start", True)
    ax = sx + sr + 6 * ft
    f.rect(ax, sy - 20, 30, 40, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=4)
    f.circle(ax + 15, sy, 9, fill="none", stroke=TEXT, sw=SW_THIN)
    f.ext(sx + sr, sy + 8, sx + sr, 212)
    f.ext(ax, sy + 22, ax, 212)
    f.dim_h(sx + sr, ax, 204)
    f.value(sx + sr + 3 * ft, 240, "6 ft", 28, records=SIX_FT, label="?")
    f.lines(ax + 44, 128, ["audio:", "grounded", "+ GFCI"], T_NOTE, TEXT, "start")
    # Fountain.
    fx, fy, fr = 494, 380, 36
    f.circle(fx, fy, fr, fill=WATER, stroke=WATER_EDGE, sw=SW_OBJ)
    f.circle(fx, fy, 8, fill=WATER_EDGE)
    f.text(fx, fy - fr - 16, "fountain", T_LABEL, TEXT, bold=True)
    qx = fx + fr + 20 * ft
    f.plan_receptacle(qx, fy, gfci=True)
    f.lines(qx + 12, 314, ["receptacle:", "GFCI"], T_NOTE, TEXT, "end")
    f.ext(fx + fr, fy + 8, fx + fr, 440)
    f.ext(qx, fy + 14, qx, 440)
    f.dim_h(fx + fr, qx, 432)
    f.value((fx + fr + qx) / 2, 466, "20 ft", 28, records=FOUNTAIN, label="?")
    f.tag(24, f.h - 18, "NEC 680")
