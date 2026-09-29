"""Prototype study figures, drawn from the NEC 2023 text (not traced from any source).

    python tools/diagrams/protos.py [--png-dir DIR]

Each figure is ONE picture with the answer drawn in, plus mask rects that the
app covers with "?" badges until the question is answered (the same
data/diagram_masks.json mechanism as the PDF figures). Writes
docs/diagrams_proto/<name>.svg, docs/diagrams_proto/masks.json and, with
PyMuPDF, a 2x PNG of each into --png-dir (default .audit_tmp/diagrams/protos).
Text is plain ASCII: MuPDF's SVG renderer drops other glyphs.
"""
import argparse
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SVG_DIR = ROOT / "docs" / "diagrams_proto"

BG = "#0f172a"
PANEL = "#1e293b"
EDGE = "#64748b"
LINE = "#94a3b8"
TEXT = "#e2e8f0"
MUTED = "#94a3b8"
DIM = "#38bdf8"
ZONE = "#0ea5e9"
OK = "#34d399"
NO = "#f87171"
FONT = "Helvetica, Arial, sans-serif"
# The app draws a figure about 390-470 px wide, so a canvas unit is ~0.5
# screen px. Keep main labels >= 28 and nothing under 22.
W, H = 800, 500


class Svg:
    def __init__(self):
        self.parts, self.masks = [], []
        self.rect(0, 0, W, H, fill=BG, rx=16)

    def add(self, s):
        self.parts.append(s)

    def rect(self, x, y, w, h, fill="none", stroke="none", sw=2, rx=0, op=1.0):
        self.add(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{fill}" '
                 f'fill-opacity="{op}" stroke="{stroke}" stroke-width="{sw}"/>')

    def line(self, x1, y1, x2, y2, stroke=LINE, sw=2):
        self.add(f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{stroke}" '
                 f'stroke-width="{sw}" stroke-linecap="round"/>')

    def poly(self, pts, fill):
        p = " ".join(f"{x},{y}" for x, y in pts)
        self.add(f'<polygon points="{p}" fill="{fill}"/>')

    def circle(self, cx, cy, r, fill="none", stroke="none", sw=2):
        self.add(f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>')

    def text(self, x, y, s, size=24, fill=TEXT, anchor="middle", bold=False, rotate=None):
        w = ' font-weight="bold"' if bold else ""
        r = f' transform="rotate({rotate} {x} {y})"' if rotate is not None else ""
        self.add(f'<text x="{x}" y="{y}" font-family="{FONT}" font-size="{size}"{w} '
                 f'fill="{fill}" text-anchor="{anchor}"{r}>{s}</text>')

    def arrow_head(self, x, y, dx, dy, color, size=12):
        px, py = -dy, dx
        self.poly([(x, y), (x - dx * size + px * size * 0.55, y - dy * size + py * size * 0.55),
                   (x - dx * size - px * size * 0.55, y - dy * size - py * size * 0.55)], color)

    def vdim(self, x, y1, y2, color=DIM):
        self.line(x, y1, x, y2, color, 3)
        self.arrow_head(x, y1, 0, -1, color)
        self.arrow_head(x, y2, 0, 1, color)

    def hdim(self, x1, x2, y, color=DIM):
        self.line(x1, y, x2, y, color, 3)
        self.arrow_head(x1, y, -1, 0, color)
        self.arrow_head(x2, y, 1, 0, color)

    def hatch(self, x, y, w, h, color=ZONE, step=20):
        self.rect(x, y, w, h, fill=color, op=0.16, stroke=color, sw=2)
        k = -h + step
        while k < w:
            t0, t1 = max(0, -k), min(h, w - k)
            if t1 > t0:
                self.line(x + k + t0, y + h - t0, x + k + t1, y + h - t1, color, 1)
            k += step

    def mask(self, x, y, w, h, label="?", ring=False):
        """Region (canvas px) the app hides until the question is answered."""
        m = {"rect": [round(x / W, 4), round(y / H, 4), round(w / W, 4), round(h / H, 4)]}
        if label != "?":
            m["label"] = label
        if ring:
            m["ring"] = True
        self.masks.append(m)

    def svg(self):
        body = "\n".join(self.parts)
        return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" '
                f'viewBox="0 0 {W} {H}">\n{body}\n</svg>\n')


def check_mark(s, cx, cy):
    s.circle(cx, cy, 20, fill=OK)
    s.add(f'<polyline points="{cx - 9},{cy} {cx - 3},{cy + 7} {cx + 10},{cy - 7}" fill="none" '
          f'stroke="{BG}" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>')


# ---------------------------------------------------------------- 110.26(E)(1)
def working_space():
    s = Svg()
    ceil, floor, ft = 90, 430, 40.0
    ws_top = floor - 6.5 * ft
    hx0, hx1, py0, py1 = 200, 290, 215, 330
    s.text(400, 34, "Sprinkler protection: permitted  (E)(1)(c)", 24, OK, bold=True)
    s.text(400, 64, "Water pipes, ducts, leak protection: not permitted", 22, NO, bold=True)
    s.mask(40, 8, 720, 70)
    # Front view.
    s.line(30, floor, 470, floor, LINE, 4)
    s.line(30, ceil, 470, ceil, EDGE, 4)
    s.text(400, 124, "front view", 22, MUTED)
    s.rect(140, ws_top, 210, floor - ws_top, stroke="#7dd3fc", sw=3, fill="#7dd3fc", op=0.06)
    s.hatch(hx0, ceil, hx1 - hx0, floor - ceil)
    s.rect(hx0, py0, hx1 - hx0, py1 - py0, fill=PANEL, stroke=TEXT, sw=4, rx=5)
    for i in range(4):
        s.line(hx0 + 16, py0 + 26 + i * 22, hx1 - 16, py0 + 26 + i * 22, EDGE, 5)
    s.text(245, 358, "panel", 22, TEXT, bold=True)
    s.text(245, 418, "working space", 22, "#7dd3fc", bold=True)
    s.hdim(140, 350, 472)
    s.text(245, 462, "30 in min", 28, DIM, bold=True)
    s.vdim(372, ws_top, floor)
    s.text(384, 300, "6 1/2 ft", 28, DIM, anchor="start", bold=True)
    s.vdim(118, ceil, py0)
    s.text(106, 146, "6 ft or", 22, DIM, anchor="end", bold=True)
    s.text(106, 172, "ceiling", 22, DIM, anchor="end", bold=True)
    # Sprinkler branch and head inside the dedicated space: the answer.
    s.line(hx0 + 4, 112, hx1 - 4, 112, OK, 7)
    s.line(245, 112, 245, 130, OK, 7)
    s.poly([(232, 130), (258, 130), (245, 146)], OK)
    check_mark(s, 245, 176)
    s.mask(hx0 + 2, 96, hx1 - hx0 - 4, 104, ring=True)
    # Side view.
    wall, depth = 560, 24
    x3 = wall + depth + 3 * ft
    s.line(wall, ceil, wall, floor, LINE, 5)
    s.line(wall, floor, 790, floor, LINE, 4)
    s.line(wall, ceil, 790, ceil, EDGE, 4)
    s.text(690, 118, "hatched =", 22, ZONE, bold=True)
    s.text(690, 144, "dedicated space", 22, ZONE, bold=True)
    s.rect(wall + depth, ws_top, x3 - wall - depth, floor - ws_top, stroke="#7dd3fc", sw=3, fill="#7dd3fc", op=0.06)
    s.hatch(wall, ceil, depth, floor - ceil)
    s.rect(wall, py0, depth, py1 - py0, fill=PANEL, stroke=TEXT, sw=4, rx=3)
    s.hdim(wall + depth, x3, 472)
    s.text((wall + depth + x3) / 2, 462, "3 ft min", 28, DIM, bold=True)
    s.text((wall + depth + x3) / 2, 300, "0-150 V", 22, MUTED)
    s.text((wall + depth + x3) / 2, 326, "to ground", 22, MUTED)
    return s


# ---------------------------------------------------------------- 210.52(E)(3)
def balcony():
    s = Svg()
    wall_x, deck_y, grade, ft = 250, 320, 470, 30.0
    s.rect(110, 50, wall_x - 110, grade - 50, fill=PANEL, stroke=EDGE, sw=3)
    s.text(180, 92, "DWELLING", 24, MUTED, bold=True)
    s.rect(wall_x - 16, deck_y - 180, 16, 180, fill="#334155", stroke=LINE, sw=2)
    s.text(212, 240, "door", 22, MUTED, rotate=-90)
    s.line(wall_x, 50, wall_x, grade, LINE, 5)
    dx0, dx1 = wall_x + 12, 770
    s.rect(dx0, deck_y, dx1 - dx0, 18, fill="#475569", stroke=LINE, sw=2)
    for x in (300, 740):
        s.rect(x - 8, deck_y + 18, 16, grade - deck_y - 18, fill="#334155", stroke=EDGE, sw=2)
    s.line(dx1 - 8, deck_y, dx1 - 8, deck_y - 110, LINE, 7)
    s.line(dx1 - 70, deck_y - 110, dx1 - 8, deck_y - 110, LINE, 7)
    s.line(30, grade, 790, grade, LINE, 4)
    s.text(560, deck_y - 38, "BALCONY / DECK / PORCH", 24, MUTED, bold=True)
    s.text(560, deck_y - 10, "walking surface", 22, MUTED)
    s.line(wall_x + 6, deck_y + 20, 360, deck_y + 70, DIM, 2)
    s.text(366, deck_y + 78, "deck within 4 in of the dwelling", 22, DIM, anchor="start", bold=True)
    ry = deck_y - 6.5 * ft
    s.rect(wall_x + 2, ry - 26, 26, 52, fill="#334155", stroke=TEXT, sw=3, rx=5)
    s.circle(wall_x + 15, ry - 9, 4, fill=TEXT)
    s.circle(wall_x + 15, ry + 9, 4, fill=TEXT)
    s.text(wall_x + 40, ry - 36, "receptacle", 24, TEXT, anchor="start", bold=True)
    x = wall_x + 80
    s.line(wall_x + 28, ry, x + 14, ry, DIM, 2)
    s.vdim(x, ry, deck_y)
    s.text(x + 18, 215, "6 ft 6 in max", 36, OK, anchor="start", bold=True)
    s.text(x + 18, 250, "(78 in)  210.52(E)(3)", 24, OK, anchor="start")
    s.mask(x + 12, 180, 290, 80, label="? max", ring=True)
    s.text(470, 70, "Also: GFCI 210.8(A)(3),", 22, MUTED, anchor="start")
    s.text(470, 98, "WR + in-use cover 406.9(B)", 22, MUTED, anchor="start")
    return s


# ---------------------------------------------------------------- Table 300.5(A)
def burial():
    s = Svg()
    grade, in_px = 170, 12.0
    slab_top = grade - 2 * in_px
    cable_top = slab_top + 18 * in_px
    s.text(400, 44, "Cover = top of the concrete to top of the cable", 24, MUTED, bold=True)
    s.rect(30, grade, 740, 300, fill="#3f2e1f", op=0.6)
    for i in range(0, 740, 30):
        s.circle(44 + i, grade + 40 + (i * 37) % 230, 3, fill="#78593a")
    tx0, tx1 = 330, 490
    s.rect(tx0, grade, tx1 - tx0, cable_top - grade + 44, fill="#5b4430", op=0.95)
    s.rect(200, slab_top, 400, grade - slab_top, fill="#94a3b8", stroke=TEXT, sw=3)
    s.text(400, slab_top - 12, "2 in concrete", 28, TEXT, bold=True)
    s.line(30, grade, 200, grade, LINE, 4)
    s.line(600, grade, 770, grade, LINE, 4)
    s.text(40, grade - 12, "grade", 22, MUTED, anchor="start")
    cx = (tx0 + tx1) / 2
    s.circle(cx, cable_top + 13, 13, fill=BG, stroke=TEXT, sw=4)
    s.text(cx, cable_top + 74, "direct-buried cable", 24, TEXT, bold=True)
    x = 300
    s.line(x - 10, cable_top, cx - 13, cable_top, DIM, 2)
    s.vdim(x, slab_top, cable_top)
    s.text(x - 16, 270, "18 in", 36, OK, anchor="end", bold=True)
    s.text(x - 16, 304, "min", 26, OK, anchor="end", bold=True)
    s.mask(150, 234, 138, 82, label="cover ?", ring=True)
    s.text(520, 262, "Table 300.5(A)", 24, MUTED, anchor="start", bold=True)
    s.text(520, 292, "Column 1", 24, MUTED, anchor="start", bold=True)
    return s


# ---------------------------------------------------------------- 250.28 bonding
def service_bonding():
    s = Svg()
    ex0, ey0, ex1, ey1 = 250, 58, 610, 350
    s.text(430, 42, "SERVICE PANEL", 24, MUTED, bold=True)
    s.rect(ex0, ey0, ex1 - ex0, ey1 - ey0, fill=PANEL, stroke=TEXT, sw=4, rx=10)
    s.text(40, 86, "from meter", 22, MUTED, anchor="start")
    for y in (100, 136):
        s.line(40, y, 270, y, TEXT, 4)
    s.line(40, 118, 262, 118, "#cbd5e1", 4)
    s.rect(270, 80, 70, 70, fill="#334155", stroke=LINE, sw=3, rx=5)
    s.text(305, 124, "MAIN", 20, TEXT, bold=True)
    s.line(262, 118, 262, 181, "#cbd5e1", 4)
    s.line(262, 181, 380, 181, "#cbd5e1", 4)
    s.rect(380, 170, 180, 22, fill="#cbd5e1", rx=4)
    for x in range(396, 560, 20):
        s.circle(x, 181, 4, fill=PANEL)
    s.text(470, 160, "neutral bar", 22, TEXT, bold=True)
    s.rect(380, 280, 180, 22, fill="#86efac", rx=4)
    s.text(470, 330, "ground bar", 22, TEXT, bold=True)
    s.line(560, 291, ex1, 291, "#86efac", 4)
    s.rect(60, 225, 110, 95, fill="#334155", stroke=LINE, sw=3, rx=8)
    s.text(115, 282, "load", 24, TEXT, bold=True)
    s.line(170, 245, 305, 245, TEXT, 4)
    s.line(305, 245, 305, 150, TEXT, 4)
    s.line(170, 268, 355, 268, "#cbd5e1", 4)
    s.line(355, 268, 355, 187, "#cbd5e1", 4)
    s.line(355, 187, 380, 187, "#cbd5e1", 4)
    s.line(170, 291, 380, 291, "#86efac", 4)
    jx = 400
    s.line(jx, 192, jx, 280, "#fbbf24", 8)
    s.text(jx + 18, 228, "MAIN BONDING", 24, OK, anchor="start", bold=True)
    s.text(jx + 18, 256, "JUMPER", 24, OK, anchor="start", bold=True)
    s.mask(jx + 12, 202, 186, 64, ring=True)
    grade = 420
    s.line(560, 181, 680, 181, "#86efac", 5)
    s.line(680, 181, 680, grade, "#86efac", 5)
    s.line(680, grade, 770, grade, "#86efac", 5)
    s.line(30, grade, 790, grade, LINE, 4)
    for rx in (715, 770):
        s.line(rx, grade, rx, 492, "#a16207", 9)
    s.text(702, 482, "rods", 22, MUTED, anchor="end")
    return s


PROTOS = {
    "working_space_110-26": (working_space, ["final-exam-#1-057"]),
    "balcony_receptacle_210-52E3": (balcony, ["final-exam-#1-008", "open-book-exam-#10-020"]),
    "burial_under_concrete_300-5": (burial, ["final-exam-#1-049", "open-book-exam-#4-004"]),
    "service_bonding_250": (service_bonding, ["open-book-exam-#1-002"]),
}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--png-dir", default=str(ROOT / ".audit_tmp" / "diagrams" / "protos"))
    args = ap.parse_args()
    SVG_DIR.mkdir(parents=True, exist_ok=True)
    for old in SVG_DIR.glob("*_p*.svg"):
        old.unlink()
    png_dir = Path(args.png_dir)
    png_dir.mkdir(parents=True, exist_ok=True)
    import pymupdf
    sidecar = {}
    for name, (fn, ids) in PROTOS.items():
        s = fn()
        path = SVG_DIR / f"{name}.svg"
        path.write_text(s.svg(), encoding="ascii")
        doc = pymupdf.open(path)
        out = png_dir / f"{name}.png"
        doc[0].get_pixmap(matrix=pymupdf.Matrix(2, 2), alpha=True).save(out)
        sidecar[f"{name}.png"] = {"records": ids, "leaks": [
            {"region": m["rect"], "what": "answer drawn in the figure"} for m in s.masks], "masks": s.masks}
        print(out, len(s.masks), "mask(s)")
    (SVG_DIR / "masks.json").write_text(json.dumps(sidecar, indent=2) + "\n", encoding="ascii")


if __name__ == "__main__":
    main()
