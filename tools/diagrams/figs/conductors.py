"""Conductors: EGC sizing, termination temperature, color code, TC bending radius, grounded-conductor connection."""
from nec_style import *  # noqa: F401,F403


def _card(f, x, y, w, h, title=""):
    f.rect(x, y, w, h, fill=PANEL, stroke=EDGE, sw=SW_THIN, rx=8)
    if title:
        f.text(x + 14, y + 30, title, T_NOTE, TEXT, "start", True)


def _ocpd(f, x, y, w=56, h=64):
    f.rect(x, y, w, h, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=5)
    f.rect(x + w * 0.3, y + h * 0.25, w * 0.4, h * 0.5, fill=EDGE, stroke=TEXT, sw=SW_THIN, rx=3)


def _xfmr(f, x, y):
    for dy in (-18, 18):
        f.circle(x, y + dy, 20, fill="none", stroke=TEXT, sw=SW_OBJ)


@figure("egc_size_250-122", h=470, nec="250.122(A), Table 250.122",
        records={"final-exam-#1-068": {}, "final-exam-#3-017": {"terms": ["same size"]}})
def egc_size(f):
    f.title("Equipment grounding conductor from the OCPD rating", y=34)
    _ocpd(f, 40, 90, 64, 72)
    f.text(72, 80, "50 A", T_LABEL, TEXT, bold=True)
    f.line(104, 110, 330, 110, WIRE_HOT, SW_WIRE)
    f.line(104, 126, 330, 126, WIRE_HOT, SW_WIRE)
    f.line(104, 142, 330, 142, WIRE_GND, SW_WIRE)
    f.rect(330, 88, 90, 80, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=5)
    f.text(375, 196, "load", T_NOTE, MUTED)
    f.text(216, 98, "circuit conductors", T_MIN, TEXT)
    f.text(216, 176, "EGC", T_NOTE, WIRE_GND, bold=True)
    _card(f, 450, 60, 330, 330, "Table 250.122 (copper)")
    f.text(466, 124, "OCPD not over", T_NOTE, MUTED, "start")
    f.text(764, 124, "EGC", T_NOTE, MUTED, "end")
    rows = [("15 A", "14 AWG", True), ("20 A", "12 AWG", True), ("60 A", "10 AWG", True),
            ("100 A", "8 AWG", False), ("200 A", "6 AWG", False)]
    for i, (a, s, hide) in enumerate(rows):
        y = 170 + i * 44
        f.line(460, y - 30, 770, y - 30, EDGE, 1)
        f.text(466, y, a, 26, TEXT, "start", True)
        if hide:
            f.value(764, y, s, 26, anchor="end", pad=5, what=f"the {a} row")
        else:
            f.text(764, y, s, 26, DIM, "end", True)
    _card(f, 20, 230, 410, 200, "How to read it")
    f.lines(36, 290, ["Use the first row whose rating is", "at or above the OCPD.",
                      "Never required larger than the", "circuit conductors (250.122(A))."],
            T_NOTE, TEXT, "start", gap=1.3)
    f.tag(f.w - 24, f.h - 12, "NEC 250.122", anchor="end")


@figure("termination_temp_110-14c", h=520, nec="310.15(A), 110.14(C), 110.14(C)(2), Table 310.16",
        records=["open-book-exam-#7-015", "open-book-exam-#7-017"])
def termination_temp(f):
    term = ["open-book-exam-#7-015"]
    conn = ["open-book-exam-#7-017"]
    f.title("The lowest temperature rating on the conductor caps it", y=34)
    _ocpd(f, 40, 80, 64, 76)
    f.text(72, 184, "breaker lug", T_NOTE, TEXT, bold=True)
    f.text(72, 210, "marked 75 C", T_NOTE, AMBER, bold=True)
    f.line(104, 118, 560, 118, WIRE_HOT, SW_WIRE + 2)
    f.text(330, 102, "#10 Cu THHN, 90 C insulation", T_NOTE, TEXT, bold=True)
    f.rect(560, 88, 70, 60, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=5)
    f.text(595, 176, "load", T_NOTE, MUTED)
    f.text(330, 150, "4 current-carrying conductors in the raceway", T_MIN, MUTED)
    _card(f, 20, 232, 760, 150, "")
    f.text(36, 270, "Table 310.16, #10 Cu:  60 C = 30 A,  75 C = 35 A,  90 C = 40 A", T_NOTE, TEXT, "start")
    f.text(36, 306, "derate from the 90 C column:  40 A x 0.80 = 32 A", T_NOTE, TEXT, "start")
    b = f.text(36, 342, "check: 32 A is not over 35 A, the 75 C", T_NOTE, TEXT, "start")
    f.value(b[0] + b[2] + 10, 342, "termination", T_NOTE, anchor="start", records=term, pad=5,
            what="what caps the ampacity")
    f.text(36, 370, "rating, so 32 A is allowed", T_NOTE, TEXT, "start")
    _card(f, 20, 396, 760, 96, "Separate pressure connector (e.g. a splicing block)")
    b = f.text(36, 466, "ampacity not over its listed and", T_NOTE, TEXT, "start")
    v = f.value(b[0] + b[2] + 10, 466, "identified", T_NOTE, anchor="start", records=conn, pad=5,
            what="the rating word")
    f.text(v[0] + v[2] + 16, 466, "temperature rating", T_NOTE, TEXT, "start")
    f.tag(f.w - 24, f.h - 6, "NEC 110.14(C)", anchor="end")


@figure("conductor_colors_310-6", h=470, when="after", nec="310.6, 200.6(A), 250.119, 210.5(C)",
        records=["final-exam-#1-009"])
def conductor_colors(f):
    f.title("Insulation colors by what the conductor does", y=34)
    groups = [
        (70, "Grounded (neutral), 200.6", [("#f8fafc", "white"), ("#9ca3af", "gray"),
                                           ("stripes", "3 white or gray stripes")]),
        (190, "Equipment grounding, 250.119", [("#22c55e", "green"), ("gy", "green, yellow stripes"),
                                               ("#b45309", "bare")]),
        (310, "Ungrounded (hot), 310.6(C): any other color", [("#111827", "black"), ("#ef4444", "red"),
                                                            ("#3b82f6", "blue"), ("#f472b6", "pink")]),
    ]
    for y, title, sw in groups:
        f.text(30, y, title, T_NOTE, TEXT, "start", True)
        for i, (c, name) in enumerate(sw):
            x = 40 + i * 185
            if c == "stripes":
                f.rect(x, y + 20, 150, 26, fill="#111827", stroke=LINE, sw=SW_THIN, rx=13)
                for k in range(3):
                    f.line(x + 10, y + 27 + k * 6, x + 140, y + 27 + k * 6, "#f8fafc", 2)
            elif c == "gy":
                f.rect(x, y + 20, 150, 26, fill="#22c55e", stroke=LINE, sw=SW_THIN, rx=13)
                f.line(x + 10, y + 33, x + 140, y + 33, "#facc15", 5)
            else:
                f.rect(x, y + 20, 150, 26, fill=c, stroke=LINE, sw=SW_THIN, rx=13)
            f.text(x + 75, y + 76, name, T_MIN, MUTED)
    f.lines(30, 430, ["Hot conductors must be clearly different from both groups above."],
            T_NOTE, TEXT, "start")
    f.tag(f.w - 24, f.h - 8, "NEC 310.6", anchor="end")


@figure("tc_bending_radius_336-24", h=470, nec="336.24",
        records={"final-exam-#5-023": {"terms": ["12 times", "12 x"]}})
def tc_bending(f):
    f.title("Type TC tray cable: minimum bending radius", y=34)
    cx, cy, r = 110, 380, 230
    f.path(f"M {cx} {cy - r} A {r} {r} 0 0 1 {cx + r} {cy}", "#0f172a", 34)
    f.path(f"M {cx} {cy - r} A {r} {r} 0 0 1 {cx + r} {cy}", PANEL_2, 30)
    f.path(f"M {cx} {cy - r} A {r} {r} 0 0 1 {cx + r} {cy}", TEXT, 2)
    f.line(cx - 60, cy - r, cx, cy - r, PANEL_2, 30)
    f.line(cx + r, cy, cx + r, cy + 40, PANEL_2, 30)
    f.circle(cx, cy, 5, fill=DIM)
    f.arrow(cx, cy, cx + r * 0.707, cy - r * 0.707)
    f.value(cx + 58, cy - 42, "R = 12 x D", 28, anchor="start", pad=6, what="the shielded multiple")
    f.text(cx + r + 50, cy + 34, "D = overall diameter", T_MIN, MUTED, "start")
    f.circle(cx + r + 90, cy - 30, 22, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ)
    f.dim_h(cx + r + 68, cx + r + 112, cy + 6)
    _card(f, 400, 60, 380, 250, "Minimum radius, 336.24")
    f.text(416, 118, "no metal shielding:", T_NOTE, MUTED, "start", True)
    f.lines(416, 152, ["4 x D  (D up to 1 in)", "5 x D  (over 1 in to 2 in)", "6 x D  (over 2 in)"],
            T_NOTE, TEXT, "start", gap=1.3)
    b = f.text(416, 282, "metallic shielding:", T_NOTE, MUTED, "start", True)
    f.value(b[0] + b[2] + 12, 282, "12 x D", 26, anchor="start", pad=5, what="the shielded multiple")
    f.tag(f.w - 24, f.h - 10, "NEC 336.24", anchor="end")


@figure("grounded_connection_200-3", h=470, nec="200.3",
        records={"open-book-exam-#7-001": {"terms": ["electrical connection"]}})
def grounded_connection(f):
    f.title("Premises neutral tied to a grounded supply conductor", y=34)
    for x0, ok in ((30, True), (420, False)):
        _card(f, x0, 56, 350, 290)
        _xfmr(f, x0 + 50, 150)
        f.text(x0 + 50, 216, "supply", T_NOTE, MUTED)
        ys = (126, 150, 174)
        for k, y in enumerate(ys):
            neutral = ok and k == 1
            if not ok and k == 1:
                continue
            f.line(x0 + 72, y, x0 + 250, y, WIRE_NEU if neutral else WIRE_HOT, SW_WIRE)
        f.panel(x0 + 250, 96, 80, 110, label="", breakers=3)
        f.text(x0 + 290, 232, "premises", T_NOTE, MUTED)
        if ok:
            f.line(x0 + 50, 150, x0 + 50, 250, WIRE_GND, SW_WIRE - 1)
            f.line(x0 + 34, 250, x0 + 66, 250, WIRE_GND, SW_WIRE)
            f.text(x0 + 170, 100, "grounded conductor", T_MIN, TEXT)
            f.leader(x0 + 170, 106, x0 + 200, 150, MUTED)
            f.mark_ok(x0 + 175, 300)
            f.text(x0 + 205, 308, "permitted", T_NOTE, OK, "start", True)
        else:
            f.text(x0 + 170, 100, "no grounded conductor", T_MIN, NO)
            f.mark_no(x0 + 175, 300)
            f.text(x0 + 205, 308, "not permitted", T_NOTE, NO, "start", True)
    b = f.text(30, 396, "The premises grounded conductor must be", T_NOTE, TEXT, "start")
    f.value(b[0] + b[2] + 10, 396, "electrically", T_NOTE, anchor="start", pad=5, what="the connection word")
    f.value_lines(30, 430, ["connected: a direct connection that carries current, not induced"], T_MIN, MUTED,
                  "start", False, pad=5, what="the definition")
    f.tag(f.w - 24, f.h - 8, "NEC 200.3", anchor="end")
