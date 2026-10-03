"""Pools, spas, storable pools and fountains, Article 680."""
from nec_style import *  # noqa: F401,F403

FAN = ["final-exam-#1-043", "open-book-exam-#4-011"]
UNDERGROUND = ["final-exam-#1-060"]
SIX_FT = ["final-exam-#3-059", "final-exam-#3-007"]
FOUNTAIN = ["final-exam-#1-024"]
MOTOR_GFCI = ["open-book-exam-#1-024"]


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


@figure("fountain_receptacles_680-58", h=360, nec="680.58",
        records={FOUNTAIN[0]: {}, "open-book-exam-#3-015": {"like": FOUNTAIN[0]}})
def fountain_receptacles(f):
    f.title("Receptacles near a fountain (plan view)", y=36)
    ft = 24.0
    fx, fy, fr = 130, 200, 60
    f.circle(fx, fy, fr, fill=WATER, stroke=WATER_EDGE, sw=SW_OBJ)
    f.circle(fx, fy, 12, fill=WATER_EDGE)
    f.text(fx, fy + fr + 34, "fountain", T_LABEL, TEXT, bold=True)
    qx = fx + fr + 20 * ft
    f.plan_receptacle(qx, fy, gfci=True)
    f.lines(qx, fy - 40, ["15 or 20 A,", "125-250 V receptacle"], T_NOTE, TEXT, gap=1.1)
    f.text(qx, fy + 46, "GFCI protected", T_NOTE, OK, bold=True)
    f.ext(fx + fr, fy + 8, fx + fr, 300)
    f.ext(qx, fy + 60, qx, 300)
    f.dim_h(fx + fr, qx, 292)
    f.value((fx + fr + qx) / 2, 276, "within 20 ft", 28, label="? ft", what="the GFCI distance")
    f.text((fx + fr + qx) / 2, 330, "measured from the fountain edge", T_MIN, MUTED)
    f.tag(f.w - 24, f.h - 10, "NEC 680.58", anchor="end")


@figure("pool_underground_680-11", h=460, nec="680.11(A)",
        records={UNDERGROUND[0]: {}, "open-book-exam-#6-023": {"like": UNDERGROUND[0]}})
def pool_underground(f):
    f.title("Underground wiring near a pool (plan view)", y=36)
    ft = 22.0
    px0, py0, px1, py1 = 260, 180, 480, 290
    d5 = 5 * ft
    f.zone(px0 - d5, py0 - d5, px1 - px0 + 2 * d5, py1 - py0 + 2 * d5, ZONE, 0.10)
    f.rect(px0 - d5, py0 - d5, px1 - px0 + 2 * d5, py1 - py0 + 2 * d5, stroke=ZONE, sw=SW_THIN, rx=6)
    f.rect(px0, py0, px1 - px0, py1 - py0, fill=WATER, stroke=WATER_EDGE, sw=SW_OBJ)
    f.text((px0 + px1) / 2, (py0 + py1) / 2 + 8, "POOL", T_LABEL, TEXT, bold=True)
    f.text(px0 - d5 + 12, py1 + d5 - 14, "zone around the pool", T_NOTE, ZONE, "start", True)
    x = px0 + 160
    f.dim_v(x, py1, py1 + d5)
    f.value(x + 16, py1 + 64, "5 ft", 28, anchor="start", label="?", what="the zone width")
    cx = 400
    f.conduit(40, 110, cx, 110, width=10)
    f.conduit(cx, 104, cx, py0 - 2, width=10)
    f.lines(606, 150, ["zone measured", "horizontally from", "the inside wall"], T_MIN, MUTED, "start", gap=1.2)
    f.lines(606, 250, ["LFMC listed for", "direct burial is", "permitted in it"], T_MIN, TEXT, "start", True, gap=1.2)
    f.tag(f.w - 24, f.h - 12, "NEC 680.11(A)", anchor="end")


@figure("storable_pool_audio_680-35d", h=380, nec="680.35(D)", records=["final-exam-#3-007"])
def storable_audio(f):
    f.title("Audio equipment near a storable pool (plan view)", y=36)
    ft = 30.0
    sx, sy, sr = 170, 200, 90
    f.circle(sx, sy, sr, fill=WATER, stroke=WATER_EDGE, sw=SW_OBJ)
    f.text(sx, sy + 8, "storable pool", T_NOTE, TEXT, bold=True)
    ax = sx + sr + 6 * ft
    f.rect(ax, sy - 34, 60, 68, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=5)
    f.circle(ax + 30, sy - 8, 16, fill="none", stroke=TEXT, sw=SW_THIN)
    f.circle(ax + 30, sy + 22, 5, fill=LINE)
    f.lines(ax + 80, sy - 20, ["audio equipment,", "above the low-voltage", "contact limit"], T_NOTE, TEXT, "start",
            gap=1.15)
    f.ext(sx + sr, sy + 10, sx + sr, 320)
    f.ext(ax, sy + 36, ax, 320)
    f.dim_h(sx + sr, ax, 312)
    f.value(sx + sr + 3 * ft, 296, "6 ft", 28, label="?", what="the distance")
    f.text(ax + 80, sy + 60, "grounded + GFCI", T_NOTE, OK, "start", True)
    f.tag(f.w - 24, f.h - 10, "NEC 680.35(D)", anchor="end")


@figure("pump_receptacle_680-22a", h=380, nec="680.22(A)(2)", records=["final-exam-#3-059"])
def pump_receptacle(f):
    f.title("Pool pump receptacle (plan view)", y=36)
    ft = 30.0
    px0, py0, px1, py1 = 40, 100, 240, 300
    f.rect(px0, py0, px1 - px0, py1 - py0, fill=WATER, stroke=WATER_EDGE, sw=SW_OBJ)
    f.text((px0 + px1) / 2, 208, "POOL", T_LABEL, TEXT, bold=True)
    rx, ry = px1 + 6 * ft, 200
    f.plan_receptacle(rx, ry, gfci=True)
    mx, my = 600, 200
    f.motor(mx, my, 80, 50, label=None, shaft="left")
    f.circle(mx - 40 - 16 - 10, my, 16, fill=PANEL_2, stroke=TEXT, sw=SW_THIN)
    f.cable([(rx + 10, ry - 6), (rx + 40, my - 50), (mx, my - 50), (mx, my - 36)], TEXT, 3)
    f.lines(mx, 262, ["circulation", "pump motor"], T_NOTE, TEXT)
    f.lines(rx, ry + 48, ["pump", "receptacle"], T_NOTE, TEXT)
    f.ext(px1, py1 + 4, px1, 340)
    f.ext(rx, ry + 90, rx, 340)
    f.dim_h(px1, rx, 332)
    f.value((px1 + rx) / 2, 316, "6 ft min", 28, label="?", what="the minimum distance")
    f.tag(f.w - 24, f.h - 10, "NEC 680.22(A)(2)", anchor="end")


@figure("pool_motor_gfci_680-5b", h=380, nec="680.5(B)",
        records={MOTOR_GFCI[0]: {}, "open-book-exam-#3-012": {"like": MOTOR_GFCI[0]}})
def pool_motor_gfci(f):
    f.title("Outlet for a pool pump motor", y=36)
    f.panel(40, 90, 110, 170, label="panel", breakers=4)
    f.line(150, 170, 330, 170, WIRE_HOT, SW_WIRE)
    f.text(240, 156, "branch circuit", T_NOTE, MUTED)
    f.receptacle(360, 170, 70, gfci=True)
    f.cable([(380, 170), (440, 170), (440, 220), (500, 220)], TEXT, 4)
    f.motor(560, 220, 110, 70, label="M", shaft="right")
    f.lines(560, 300, ["permanently installed", "pump motor"], T_NOTE, TEXT, gap=1.1)
    f.card(40, 300, 450, 64)
    b = f.text(56, 340, "GFCI: 150 V or less to ground and", T_MIN, TEXT, "start")
    f.value(b[0] + b[2] + 8, 340, "60 A or less", T_MIN, anchor="start", pad=4, what="the amp limit")
    f.tag(f.w - 24, f.h - 10, "NEC 680.5(B)", anchor="end")
