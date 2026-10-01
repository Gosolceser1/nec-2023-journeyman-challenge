"""One visual system for every original study figure (docs/DIAGRAMS_AUDIT.md).

Every figure is an SVG drawn in code on a dark slate canvas, 800 units wide,
with the same palette, stroke widths, fonts, dimension lines and legend. The
app draws a figure about 390-480 px wide on a phone, so one canvas unit is
about half a screen pixel: keep values at 28-32, object labels at 22-24 and
nothing under 20. Text is plain ASCII (MuPDF's SVG renderer drops other
glyphs) and dashes are drawn as segments (it ignores stroke-dasharray).

Answer safety: anything that answers one of the figure's questions goes
through `Fig.value()` or `Fig.mask()`. Each names the records it answers, and
the build turns it into a '?' badge (data/diagram_masks.json) for exactly
those records. The build also scans every visible label against every
record's correct answer, so a shared drawing can't show a sibling's value
that happens to answer the current question.
"""
import math

import pymupdf

W = 800

# Palette (Tailwind slate / sky, as the app theme).
BG = "#0f172a"        # canvas
PANEL = "#1e293b"     # equipment bodies, rooms
PANEL_2 = "#334155"   # doors, devices, secondary bodies
EDGE = "#64748b"      # ceilings, secondary outlines
LINE = "#94a3b8"      # walls, floors, grade, structure
TEXT = "#e2e8f0"      # object labels
MUTED = "#94a3b8"     # notes, captions
DIM = "#38bdf8"       # dimension lines and their values (cyan)
ZONE = "#0ea5e9"      # zones, hatched areas
OK = "#34d399"        # answer values, "permitted"
NO = "#f87171"        # "not permitted", hazards
AMBER = "#fbbf24"     # bonding jumpers, attention
ORANGE = "#fb923c"    # isolated-ground marking
WIRE_HOT = "#e2e8f0"  # ungrounded conductors (drawn light)
WIRE_NEU = "#cbd5e1"  # neutral / grounded conductor
WIRE_GND = "#86efac"  # EGC, GEC, bonding conductors (green)
SOIL = "#3f2e1f"
SOIL_DOT = "#78593a"
TRENCH = "#5b4430"
CONCRETE = "#94a3b8"
WATER = "#0c4a6e"
WATER_EDGE = "#38bdf8"
WOOD = "#a16207"
STEEL = "#64748b"
ROD = "#b45309"
CLAMP = "#ca8a04"     # bronze acorn clamps, lugs

FONT = "Helvetica, Arial, sans-serif"

# Stroke widths.
SW_STRUCT = 4   # walls, floors, grade, ceilings
SW_OBJ = 3      # equipment outlines, devices
SW_THIN = 2     # detail, leaders, extension lines
SW_DIM = 3      # dimension lines
SW_WIRE = 4     # conductors
ARROW = 12      # dimension arrowhead length

# Text sizes.
T_VALUE = 30    # dimension values, the key numbers
T_LABEL = 24    # object labels
T_NOTE = 22     # notes, captions, section tags
T_MIN = 20


def _esc(s):
    return str(s).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def text_width(s, size, bold=False):
    return pymupdf.get_text_length(str(s), fontname="hebo" if bold else "helv", fontsize=size)


class Fig:
    """An 800 x h canvas. Coordinates are canvas units, origin top-left."""

    def __init__(self, h=450, w=W):
        self.w, self.h = w, h
        self.parts = []
        self.labels = []   # [text, x, y, w, h] in canvas units (for the leak scan)
        self.masks = []    # {"rect": [x,y,w,h] canvas, "label", "ring", "records", "what"}
        self.highlights = []  # {"rect": [x,y,w,h] canvas, "records"}: outlined after answering
        self.rect(0, 0, w, h, fill=BG)

    # ------------------------------------------------------------ primitives
    def add(self, s):
        self.parts.append(s)

    def rect(self, x, y, w, h, fill="none", stroke="none", sw=SW_THIN, rx=0, op=1.0):
        self.add(f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" rx="{rx}" fill="{fill}" '
                 f'fill-opacity="{op}" stroke="{stroke}" stroke-width="{sw}"/>')

    def line(self, x1, y1, x2, y2, stroke=LINE, sw=SW_THIN, op=1.0):
        self.add(f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" stroke="{stroke}" '
                 f'stroke-width="{sw}" stroke-linecap="round" stroke-opacity="{op}"/>')

    def dline(self, x1, y1, x2, y2, stroke=LINE, sw=SW_THIN, dash=10, gap=8, op=1.0):
        """Dashed line, drawn as segments."""
        length = math.hypot(x2 - x1, y2 - y1)
        if length == 0:
            return
        ux, uy = (x2 - x1) / length, (y2 - y1) / length
        t = 0.0
        while t < length:
            e = min(t + dash, length)
            self.line(x1 + ux * t, y1 + uy * t, x1 + ux * e, y1 + uy * e, stroke, sw, op)
            t += dash + gap

    def polyline(self, pts, stroke=LINE, sw=SW_THIN, fill="none"):
        p = " ".join(f"{x:.1f},{y:.1f}" for x, y in pts)
        self.add(f'<polyline points="{p}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}" '
                 f'stroke-linecap="round" stroke-linejoin="round"/>')

    def poly(self, pts, fill, stroke="none", sw=SW_THIN, op=1.0):
        p = " ".join(f"{x:.1f},{y:.1f}" for x, y in pts)
        self.add(f'<polygon points="{p}" fill="{fill}" fill-opacity="{op}" stroke="{stroke}" stroke-width="{sw}"/>')

    def circle(self, cx, cy, r, fill="none", stroke="none", sw=SW_THIN):
        self.add(f'<circle cx="{cx:.1f}" cy="{cy:.1f}" r="{r}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>')

    def path(self, d, stroke=LINE, sw=SW_THIN, fill="none"):
        self.add(f'<path d="{d}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}" '
                 f'stroke-linecap="round" stroke-linejoin="round"/>')

    def text(self, x, y, s, size=T_LABEL, fill=TEXT, anchor="middle", bold=False, rotate=None):
        """Baseline-anchored text; returns its box [x, y, w, h] in canvas units."""
        s = str(s)
        assert s.isascii(), f"non-ASCII label {s!r}"
        size = max(size, T_MIN)
        wgt = ' font-weight="bold"' if bold else ""
        rot = f' transform="rotate({rotate} {x:.1f} {y:.1f})"' if rotate is not None else ""
        self.add(f'<text x="{x:.1f}" y="{y:.1f}" font-family="{FONT}" font-size="{size}"{wgt} '
                 f'fill="{fill}" text-anchor="{anchor}"{rot}>{_esc(s)}</text>')
        tw = text_width(s, size, bold)
        x0 = x - (tw / 2 if anchor == "middle" else tw if anchor == "end" else 0)
        box = [x0, y - size * 0.78, tw, size * 1.0]
        if rotate is not None and abs(abs(rotate) - 90) < 1:
            # Rotated a quarter turn about (x, y).
            cx, cy = box[0] + box[2] / 2, box[1] + box[3] / 2
            dx, dy = cx - x, cy - y
            if rotate < 0:
                ncx, ncy = x + dy, y - dx
            else:
                ncx, ncy = x - dy, y + dx
            box = [ncx - box[3] / 2, ncy - box[2] / 2, box[3], box[2]]
        self.labels.append([s] + [round(v, 1) for v in box])
        return box

    def lines(self, x, y, rows, size=T_NOTE, fill=MUTED, anchor="middle", bold=False, gap=1.25):
        """Several text rows, top baseline at y. Returns the union box."""
        boxes = [self.text(x, y + i * size * gap, r, size, fill, anchor, bold) for i, r in enumerate(rows)]
        return self._joined(rows, boxes)

    def _joined(self, rows, boxes):
        """Multi-row labels also count as one label for the leak scan."""
        b = _union(boxes)
        if len(rows) > 1:
            self.labels.append([" ".join(str(r) for r in rows)] + [round(v, 1) for v in b])
        return b

    # ------------------------------------------------------------ answer safety
    def mask(self, x, y, w, h, label="?", ring=True, records=None, what="answer value"):
        """Hide [x, y, w, h] until the question is answered.

        records: record ids this region answers (None = every record the
        figure serves). ring: outline the region after the reveal."""
        x0, y0 = max(0.0, x), max(0.0, y)
        x1, y1 = min(self.w, x + w), min(self.h, y + h)
        m = {"rect": [x0, y0, x1 - x0, y1 - y0], "ring": ring, "what": what}
        if label != "?":
            m["label"] = label
        if records is not None:
            m["records"] = list(records)
        self.masks.append(m)
        return m

    def highlight(self, x, y, w, h, records=None):
        """Outline [x, y, w, h] after the question is answered (the part the key points at).

        Nothing is drawn before answering, so it never gives the answer away."""
        self.highlights.append({"rect": [x, y, w, h], "records": None if records is None else list(records)})

    def value(self, x, y, s, size=T_VALUE, fill=OK, anchor="middle", bold=True, records=None,
              label="?", pad=8, ring=True, what=None, rotate=None):
        """An answer value: drawn, and masked for `records` until answered."""
        b = self.text(x, y, s, size, fill, anchor, bold, rotate)
        self.mask(b[0] - pad, b[1] - pad, b[2] + 2 * pad, b[3] + 2 * pad, label, ring, records, what or f"'{s}'")
        return b

    def value_lines(self, x, y, rows, size=T_VALUE, fill=OK, anchor="middle", bold=True, records=None,
                    label="?", pad=8, ring=True, what=None, gap=1.2):
        boxes = [self.text(x, y + i * size * gap, r, size, fill, anchor, bold) for i, r in enumerate(rows)]
        b = self._joined(rows, boxes)
        self.mask(b[0] - pad, b[1] - pad, b[2] + 2 * pad, b[3] + 2 * pad, label, ring, records,
                  what or "'" + " ".join(rows) + "'")
        return b

    # ------------------------------------------------------------ arrows and dimensions
    def arrow_head(self, x, y, dx, dy, color=DIM, size=ARROW):
        px, py = -dy, dx
        self.poly([(x, y), (x - dx * size + px * size * 0.5, y - dy * size + py * size * 0.5),
                   (x - dx * size - px * size * 0.5, y - dy * size - py * size * 0.5)], color)

    def arrow(self, x1, y1, x2, y2, color=DIM, sw=SW_DIM, both=False):
        length = math.hypot(x2 - x1, y2 - y1)
        ux, uy = (x2 - x1) / length, (y2 - y1) / length
        self.line(x1, y1, x2 - ux * ARROW * 0.6, y2 - uy * ARROW * 0.6, color, sw)
        self.arrow_head(x2, y2, ux, uy, color)
        if both:
            self.arrow_head(x1, y1, -ux, -uy, color)

    def ext(self, x1, y1, x2, y2, color=DIM):
        """Dashed extension line from the object to a dimension line."""
        self.dline(x1, y1, x2, y2, color, SW_THIN, 7, 6, 0.7)

    def dim_v(self, x, y1, y2, color=DIM):
        """Vertical dimension line with arrowheads at both ends."""
        self.line(x, y1 + ARROW * 0.5, x, y2 - ARROW * 0.5, color, SW_DIM)
        self.arrow_head(x, min(y1, y2), 0, -1, color)
        self.arrow_head(x, max(y1, y2), 0, 1, color)

    def dim_h(self, x1, x2, y, color=DIM):
        self.line(x1 + ARROW * 0.5, y, x2 - ARROW * 0.5, y, color, SW_DIM)
        self.arrow_head(min(x1, x2), y, -1, 0, color)
        self.arrow_head(max(x1, x2), y, 1, 0, color)

    def leader(self, x1, y1, x2, y2, color=MUTED):
        """Thin pointer from a label (x1, y1) to the thing (x2, y2), with a dot."""
        self.line(x1, y1, x2, y2, color, SW_THIN)
        self.circle(x2, y2, 4, fill=color)

    # ------------------------------------------------------------ building blocks
    def floor(self, y, x0=20, x1=None, label=None):
        x1 = self.w - 20 if x1 is None else x1
        self.line(x0, y, x1, y, LINE, SW_STRUCT)
        if label:
            self.text(x0 + 6, y - 10, label, T_NOTE, MUTED, "start")

    def ceiling(self, y, x0=20, x1=None):
        self.line(x0, y, self.w - 20 if x1 is None else x1, y, EDGE, SW_STRUCT)

    def wall(self, x, y0, y1, thick=16, fill=PANEL_2):
        self.rect(x - thick / 2, y0, thick, y1 - y0, fill=fill, stroke=LINE, sw=SW_THIN)

    def soil(self, x, y, w, h, dots=True):
        self.rect(x, y, w, h, fill=SOIL, op=0.75)
        if dots:
            for i in range(0, int(w), 28):
                self.circle(x + 12 + i, y + 18 + (i * 37) % max(1, int(h) - 30), 3, fill=SOIL_DOT)

    def grade(self, y, x0=20, x1=None, label="grade", soil_h=None):
        x1 = self.w - 20 if x1 is None else x1
        if soil_h:
            self.soil(x0, y, x1 - x0, soil_h)
        self.line(x0, y, x1, y, LINE, SW_STRUCT)
        if label:
            self.text(x0 + 6, y - 10, label, T_NOTE, MUTED, "start")

    def concrete(self, x, y, w, h, label=None):
        self.rect(x, y, w, h, fill=CONCRETE, stroke=TEXT, sw=SW_THIN)
        for i in range(8, int(w) - 4, 34):
            self.circle(x + i, y + h * 0.5 + ((i * 13) % 7) - 3, 2.5, fill="#64748b")
        if label:
            self.text(x + w / 2, y - 10, label, T_LABEL, TEXT, bold=True)

    def hatch(self, x, y, w, h, color=ZONE, step=20, op=0.16):
        self.rect(x, y, w, h, fill=color, op=op, stroke=color, sw=SW_THIN)
        k = -h + step
        while k < w:
            t0, t1 = max(0, -k), min(h, w - k)
            if t1 > t0:
                self.line(x + k + t0, y + h - t0, x + k + t1, y + h - t1, color, 1)
            k += step

    def zone(self, x, y, w, h, color=ZONE, op=0.10):
        """Outlined, lightly filled area (working space, reach zone, ...)."""
        self.rect(x, y, w, h, fill=color, op=op, stroke=color, sw=SW_OBJ, rx=4)

    def panel(self, x, y, w, h, label="panel", breakers=4, label_below=True, main=False):
        """Panelboard front, top-left (x, y): tub, dead front with trim screws and
        two columns of breakers on a centre bus cover. breakers=0 leaves the dead
        front empty for the caller to fill. main: a two-pole main at the top."""
        self.rect(x, y, w, h, fill=PANEL, stroke=TEXT, sw=SW_OBJ + 1, rx=5)
        m = max(5.0, min(w, h) * 0.07)
        self.rect(x + m, y + m, w - 2 * m, h - 2 * m, fill=PANEL_2, op=0.55, stroke=EDGE, sw=SW_THIN, rx=3)
        sr = max(2.0, min(w, h) * 0.018)
        for sx, sy in ((x + m * 1.9, y + m * 1.9), (x + w - m * 1.9, y + m * 1.9),
                       (x + m * 1.9, y + h - m * 1.9), (x + w - m * 1.9, y + h - m * 1.9)):
            self.circle(sx, sy, sr, fill=EDGE)
        if breakers <= 0:
            if label:
                self.text(x + w / 2, y + h + 28 if label_below else y - 12, label, T_LABEL, TEXT, bold=True)
            return
        top, bot = y + m * 3.2, y + h - m * 3.2
        if main:
            mh = min((bot - top) * 0.24, w * 0.34)
            self.breaker(x + w / 2 - w * 0.2, top, w * 0.4, mh, poles=2)
            top += mh + m
        cw = w * 0.30
        self.rect(x + w / 2 - w * 0.05, top - 2, w * 0.10, bot - top + 4, fill=BG, op=0.6, rx=2)
        step = (bot - top) / breakers
        bh = max(6.0, step * 0.72)
        for i in range(breakers):
            yy = top + i * step + (step - bh) / 2
            for bx in (x + w / 2 - w * 0.06 - cw, x + w / 2 + w * 0.06):
                self.mini_breaker(bx, yy, cw, bh, handle_left=bx > x + w / 2)
        if label:
            self.text(x + w / 2, y + h + 28 if label_below else y - 12, label, T_LABEL, TEXT, bold=True)

    def mini_breaker(self, x, y, w, h, handle_left=False):
        """One plug-on breaker in a panel row: body plus a toggle at the bus end."""
        self.rect(x, y, w, h, fill=PANEL_2, stroke=LINE, sw=1.5, rx=1.5)
        tw = max(4.0, w * 0.34)
        tx = x + w * 0.12 if handle_left else x + w - w * 0.12 - tw
        self.rect(tx, y + h * 0.22, tw, h * 0.56, fill=TEXT, rx=1.5)

    def breaker(self, x, y, w=56, h=64, poles=1, on=True, color=TEXT, fill=PANEL_2, rating=None):
        """Molded-case breaker front, top-left (x, y): body, line and load lugs,
        handle slot with the toggle up (ON) or down (OFF); poles > 1 tie the handles."""
        self.rect(x, y, w, h, fill=fill, stroke=color, sw=SW_OBJ, rx=5)
        lug = max(3.0, h * 0.06)
        for yy in (y + lug * 1.6, y + h - lug * 1.6):
            for k in range(poles):
                self.circle(x + w * (k + 0.5) / poles, yy, lug, fill=EDGE)
        sw_ = min(w * 0.42 / poles, w * 0.32)
        sh = h * 0.46
        sy = y + (h - sh) / 2
        xs = [x + w * (k + 0.5) / poles for k in range(poles)]
        for cx in xs:
            self.rect(cx - sw_ / 2, sy, sw_, sh, fill=BG, stroke=EDGE, sw=1.5, rx=2)
            hy = sy + sh * (0.06 if on else 0.48)
            self.rect(cx - sw_ * 0.38, hy, sw_ * 0.76, sh * 0.46, fill=color, rx=2)
        if poles > 1:
            hy = sy + sh * (0.29 if on else 0.71)
            self.line(xs[0], hy, xs[-1], hy, color, max(2.0, sh * 0.08))
        if rating:
            self.text(x + w / 2, y + h + 26, rating, T_NOTE, TEXT, bold=True)

    def disconnect(self, x, y, w=90, h=120, on=True, label=None, label_dy=None):
        """Enclosed safety switch, top-left (x, y): body, door seam, hasp and the
        operating handle on the right side, up for ON and down for OFF."""
        self.rect(x, y, w, h, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ + 1, rx=5)
        m = max(5.0, w * 0.08)
        self.rect(x + m, y + m, w - 2 * m, h - 2 * m, fill="none", stroke=EDGE, sw=SW_THIN, rx=3)
        self.rect(x + w * 0.42, y + h - m - 2, w * 0.16, m + 6, fill=EDGE, stroke=TEXT, sw=1.5, rx=2)
        px, py = x + w + 2, y + h * 0.30
        tip = (px + w * 0.26, py - h * 0.20) if on else (px + w * 0.26, py + h * 0.20)
        self.rect(x + w - 2, py - h * 0.08, 8, h * 0.16, fill=EDGE, stroke=TEXT, sw=1.5, rx=2)
        self.line(px + 2, py, tip[0], tip[1], TEXT, max(5.0, w * 0.07))
        self.circle(tip[0], tip[1], max(4.0, w * 0.05), fill=TEXT)
        self.circle(px + 2, py, max(4.0, w * 0.05), fill=PANEL, stroke=TEXT, sw=1.5)
        if label:
            self.text(x + w / 2, y + (label_dy if label_dy is not None else -14), label, T_LABEL, TEXT, bold=True)

    def meter(self, cx, cy, r=24, label=None, label_dx=None):
        """Watthour meter in its socket, centred on the glass: socket base, sealing
        ring, glass with the register and dial."""
        self.rect(cx - r * 1.15, cy - r * 1.55, r * 2.3, r * 3.1, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=r * 0.35)
        self.circle(cx, cy, r + max(2.0, r * 0.1), fill=EDGE, stroke=TEXT, sw=SW_THIN)
        self.circle(cx, cy, r, fill=BG, stroke=LINE, sw=SW_THIN)
        self.rect(cx - r * 0.55, cy - r * 0.48, r * 1.1, r * 0.34, fill=PANEL, stroke=LINE, sw=1, rx=1.5)
        self.line(cx - r * 0.62, cy + r * 0.32, cx + r * 0.62, cy + r * 0.32, LINE, max(1.5, r * 0.08))
        self.line(cx, cy + r * 0.32, cx + r * 0.3, cy + r * 0.05, AMBER, max(1.5, r * 0.07))
        if label:
            dx = r * 1.15 + 10 if label_dx is None else label_dx
            self.text(cx + dx, cy + 8, label, T_NOTE, TEXT, "start" if dx >= 0 else "end", True)

    def transformer(self, x, y, w=110, h=90, kind="pad", label=None):
        """Distribution transformer. kind="pad": pad-mounted cabinet on its pad,
        top-left (x, y). kind="pole": pole-mounted can, top-left of the can,
        with two primary bushings on the lid and a hanger bracket."""
        if kind == "pole":
            self.rect(x, y, w, h, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=w * 0.18)
            self.line(x + 3, y + h * 0.18, x + w - 3, y + h * 0.18, EDGE, SW_THIN)
            for k in (0.3, 0.7):
                bx = x + w * k
                for j in range(3):
                    self.rect(bx - 6 + j, y - 10 - j * 8, 12 - 2 * j, 7, fill=LINE, stroke=TEXT, sw=1, rx=2)
            self.rect(x - 8, y + h * 0.35, 10, h * 0.3, fill=STEEL, stroke=TEXT, sw=1.5, rx=2)
        else:
            self.rect(x - 8, y + h, w + 16, max(10.0, h * 0.12), fill=CONCRETE, stroke=TEXT, sw=SW_THIN)
            self.rect(x, y, w, h, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ + 1, rx=4)
            self.line(x + w / 2, y + 6, x + w / 2, y + h - 6, EDGE, SW_THIN)
            for k in range(1, 5):
                yy = y + h * k / 5
                self.line(x - 6, yy, x, yy, EDGE, 3)
                self.line(x + w, yy, x + w + 6, yy, EDGE, 3)
            self.rect(x + w / 2 + 8, y + h * 0.42, 6, h * 0.16, fill=EDGE, rx=2)
        if label:
            self.text(x + w / 2, y + h + (40 if kind == "pad" else 28), label, T_LABEL, TEXT, bold=True)

    def coils(self, x, y, r=18):
        """One-line transformer symbol: two touching windings, centred on (x, y)."""
        self.circle(x, y - r * 0.8, r, stroke=TEXT, sw=SW_OBJ)
        self.circle(x, y + r * 0.8, r, stroke=TEXT, sw=SW_OBJ)

    def motor(self, cx, cy, w=96, h=64, label="M", shaft="right"):
        """Totally enclosed motor, side view, centred on the frame: ribbed frame,
        end bells, shaft, mounting feet and the conduit (terminal) box on top."""
        x0, y0 = cx - w / 2, cy - h / 2
        self.rect(x0 + w * 0.1, cy + h / 2 - 2, w * 0.18, h * 0.16, fill=STEEL, stroke=TEXT, sw=1.5)
        self.rect(x0 + w * 0.72, cy + h / 2 - 2, w * 0.18, h * 0.16, fill=STEEL, stroke=TEXT, sw=1.5)
        self.line(x0 + w * 0.02, cy + h / 2 + h * 0.15, x0 + w * 0.98, cy + h / 2 + h * 0.15, LINE, 3)
        self.rect(x0, y0, w, h, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ, rx=h * 0.22)
        for k in range(1, 6):
            yy = y0 + h * k / 6
            self.line(x0 + w * 0.2, yy, x0 + w * 0.8, yy, EDGE, 2)
        for ex in (x0 + w * 0.14, x0 + w * 0.86):
            self.line(ex, y0 + 4, ex, y0 + h - 4, LINE, 2)
        sx = x0 + w if shaft == "right" else x0
        d = 1 if shaft == "right" else -1
        self.rect(min(sx, sx + d * w * 0.22), cy - h * 0.09, w * 0.22, h * 0.18, fill=LINE, stroke=TEXT, sw=1.5, rx=2)
        self.rect(cx - w * 0.16, y0 - h * 0.24, w * 0.32, h * 0.26, fill=PANEL_2, stroke=TEXT, sw=SW_THIN, rx=3)
        if label:
            self.text(cx, cy + 9, label, T_LABEL, TEXT, bold=True)

    def motor_symbol(self, cx, cy, r=30, label="M"):
        """One-line motor symbol: circled M."""
        self.circle(cx, cy, r, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ)
        self.text(cx, cy + 9, label, T_LABEL, TEXT, bold=True)

    def card(self, x, y, w, h, title=None, align="start", title_fill=TEXT):
        """Information card: rounded slate panel with an optional bold title."""
        self.rect(x, y, w, h, fill=PANEL, stroke=EDGE, sw=SW_THIN, rx=8)
        if title:
            tx = x + 14 if align == "start" else x + w / 2
            self.text(tx, y + 30, title, T_NOTE, title_fill, align, True)

    def box(self, x, y, s=40, label=None, fill=PANEL_2):
        """Outlet / junction box with a blank cover, square, centred on (x, y):
        cover inset and two cover screws on the diagonal."""
        self.rect(x - s / 2, y - s / 2, s, s, fill=fill, stroke=TEXT, sw=SW_OBJ, rx=4)
        i = s * 0.13
        self.rect(x - s / 2 + i, y - s / 2 + i, s - 2 * i, s - 2 * i, fill="none", stroke=EDGE, sw=1.5, rx=3)
        sr = max(2.5, s * 0.07)
        for sx, sy in ((x - s * 0.24, y - s * 0.24), (x + s * 0.24, y + s * 0.24)):
            self.circle(sx, sy, sr, fill=LINE)
            self.line(sx - sr * 0.7, sy, sx + sr * 0.7, sy, BG, 1)
        if label:
            self.text(x, y + s / 2 + 26, label, T_NOTE, TEXT)

    def receptacle(self, x, y, s=44, label=None, gfci=False, label_dy=None, tr=False, ig=False,
                   blank_center=False):
        """Duplex receptacle (NEMA 5-15R) on its strap, centred on (x, y); s is the
        device height, 0.64 s wide. Each face has the taller neutral slot on the
        left, the hot slot on the right and the ground hole below. gfci: TEST and
        RESET buttons between smaller faces. ig: orange triangle. tr: 'TR' (s >= 90).
        blank_center: leave the centre clear for the caller's own marking."""
        w = s * 0.64
        self.rect(x - w / 2, y - s / 2, w, s, fill=PANEL_2, stroke=TEXT, sw=SW_OBJ if s >= 30 else SW_THIN,
                  rx=max(3.0, s * 0.1))
        rf = min(w * 0.37, s * (0.17 if gfci else 0.2))
        dy = s * (0.29 if gfci else 0.23)
        for fy in (y - dy, y + dy):
            self.nema_face(x, fy, rf, "5-15")
        if blank_center:
            pass
        elif gfci:
            bw, bh = w * 0.34, max(4.0, s * 0.1)
            self.rect(x - bw - 1.5, y - bh / 2, bw, bh, fill=TEXT, rx=1.5)
            self.rect(x + 1.5, y - bh / 2, bw, bh, fill=OK, rx=1.5)
        elif ig and s >= 50:
            t = s * 0.06
            self.poly([(x, y - t), (x - t * 1.15, y + t), (x + t * 1.15, y + t)], ORANGE)
        elif tr and s >= 90:
            self.text(x, y + 7, "TR", T_MIN, MUTED, bold=True)
        elif s >= 40:
            self.circle(x, y, max(2.0, s * 0.035), fill=LINE)
        if label:
            self.text(x, y + (label_dy if label_dy is not None else s / 2 + 26), label, T_NOTE, TEXT)

    def nema_face(self, cx, cy, r, cfg="5-15", fill=BG, stroke=TEXT):
        """One receptacle face, centred on (cx, cy), radius r: round with flats top
        and bottom. cfg "5-15": two parallel slots, the neutral (left) taller;
        "5-20": the neutral is a T slot; "6-15": two in-line horizontal slots;
        "6-20": the left one a T. Grounding hole below."""
        hf, wf = r * 0.82, r * 0.57
        self.path(f"M {cx - wf:.1f} {cy - hf:.1f} L {cx + wf:.1f} {cy - hf:.1f} "
                  f"A {r:.1f} {r:.1f} 0 0 1 {cx + wf:.1f} {cy + hf:.1f} L {cx - wf:.1f} {cy + hf:.1f} "
                  f"A {r:.1f} {r:.1f} 0 0 1 {cx - wf:.1f} {cy - hf:.1f} Z", stroke, max(1.5, r * 0.08), fill)
        sw = max(2.0, r * 0.16)
        sx, top = r * 0.38, cy - r * 0.42
        if cfg in ("5-15", "5-20"):
            self.line(cx - sx, top, cx - sx, top + r * 0.5, stroke, sw)
            self.line(cx + sx, top + r * 0.05, cx + sx, top + r * 0.45, stroke, sw)
            if cfg == "5-20":
                self.line(cx - sx, top + r * 0.25, cx - sx - r * 0.25, top + r * 0.25, stroke, sw)
        else:
            yy = top + r * 0.22
            self.line(cx - sx - r * 0.2, yy, cx - sx + r * 0.16, yy, stroke, sw)
            self.line(cx + sx - r * 0.16, yy, cx + sx + r * 0.2, yy, stroke, sw)
            if cfg == "6-20":
                self.line(cx - sx - r * 0.2, yy - r * 0.2, cx - sx - r * 0.2, yy + r * 0.2, stroke, sw)
        gy = cy + r * 0.4
        if r >= 10:
            g = r * 0.16
            self.path(f"M {cx - g:.1f} {gy + g * 1.4:.1f} V {gy:.1f} A {g:.1f} {g:.1f} 0 0 1 {cx + g:.1f} {gy:.1f} "
                      f"V {gy + g * 1.4:.1f} Z", stroke, max(1.5, r * 0.09))
        else:
            self.circle(cx, gy + r * 0.08, max(1.4, r * 0.14), fill=stroke)

    def plug(self, x, y, w=40, h=30, facing="left", cord=None, color=EDGE):
        """Grounding-type attachment plug, side view: body at (x, y) top-left, the
        blades out of the `facing` side and an optional cord polyline from the back."""
        self.rect(x, y, w, h, fill=color, stroke=TEXT, sw=SW_THIN, rx=min(w, h) * 0.25)
        for k in range(1, 3):
            gx = x + w * (0.35 + 0.2 * k) if facing == "left" else x + w * (0.65 - 0.2 * k)
            self.line(gx, y + 3, gx, y + h - 3, BG, 1)
        bl = w * 0.45
        for by in (y + h * 0.3, y + h * 0.7):
            if facing == "left":
                self.line(x - bl, by, x, by, LINE, 4)
            else:
                self.line(x + w, by, x + w + bl, by, LINE, 4)
        if cord:
            self.cable(cord, TEXT, 5)

    def plan_receptacle(self, x, y, r=12, gfci=False):
        """Plan-view duplex receptacle symbol: circle with two parallel lines
        through it. gfci: green circle with a dot."""
        c = OK if gfci else TEXT
        self.line(x - r - 6, y - 4, x + r * 0.55, y - 4, c, 3)
        self.line(x - r - 6, y + 4, x + r * 0.55, y + 4, c, 3)
        self.circle(x, y, r, fill="none", stroke=c, sw=SW_OBJ)
        if gfci:
            self.circle(x + r * 0.45, y, 3, fill=OK)

    def conduit(self, x1, y1, x2, y2, width=14, color=STEEL, edge=LINE, couplings=()):
        """Straight raceway run: a pipe with edges and a light highlight along one
        side; `couplings` are fractions 0-1 along the run that get a coupling band."""
        self.line(x1, y1, x2, y2, edge, width + 4)
        self.line(x1, y1, x2, y2, color, width)
        length = math.hypot(x2 - x1, y2 - y1)
        if length < 1:
            return
        ux, uy = (x2 - x1) / length, (y2 - y1) / length
        nx, ny = -uy, ux
        if ny > 0 or (ny == 0 and nx > 0):
            nx, ny = -nx, -ny
        o = width * 0.22
        if width >= 10:
            self.line(x1 + nx * o, y1 + ny * o, x2 + nx * o, y2 + ny * o, TEXT, max(1.0, width * 0.1), op=0.35)
        for t in couplings:
            cx, cy = x1 + (x2 - x1) * t, y1 + (y2 - y1) * t
            half = width * 0.55
            self.line(cx - ux * half, cy - uy * half, cx + ux * half, cy + uy * half, edge, width + 10)
            self.line(cx - ux * (half - 2), cy - uy * (half - 2), cx + ux * (half - 2), cy + uy * (half - 2),
                      PANEL_2, width + 6)

    def cable(self, pts, color=TEXT, sw=5):
        self.polyline(pts, color, sw)

    def strap(self, x, y, horizontal=True, size=22):
        """Support / strap marker on a run."""
        if horizontal:
            self.rect(x - 5, y - size / 2, 10, size, fill=AMBER, rx=2)
        else:
            self.rect(x - size / 2, y - 5, size, 10, fill=AMBER, rx=2)

    def person(self, x, y_feet, height=170, color=MUTED):
        """Simple standing figure, feet at y_feet."""
        head = height * 0.13
        top = y_feet - height
        self.circle(x, top + head, head, fill="none", stroke=color, sw=SW_OBJ)
        neck, hip = top + head * 2, y_feet - height * 0.45
        self.line(x, neck, x, hip, color, SW_OBJ + 1)
        self.line(x, neck + height * 0.08, x - height * 0.16, hip - height * 0.02, color, SW_OBJ)
        self.line(x, neck + height * 0.08, x + height * 0.16, hip - height * 0.02, color, SW_OBJ)
        self.line(x, hip, x - height * 0.12, y_feet, color, SW_OBJ)
        self.line(x, hip, x + height * 0.12, y_feet, color, SW_OBJ)

    def pool(self, x, y, w, depth, label="POOL"):
        """Section view of a pool: water surface at y, basin `depth` deep."""
        self.rect(x, y, w, depth, fill=WATER, stroke=WATER_EDGE, sw=SW_OBJ)
        for i in range(3):
            yy = y + 14 + i * 12
            self.path(f"M {x + 20} {yy} q 15 -8 30 0 t 30 0 t 30 0", WATER_EDGE, 2)
        if label:
            self.text(x + w / 2, y + depth / 2 + 8, label, T_LABEL, TEXT, bold=True)

    def rod(self, x, y_top, length=110, label=None):
        """Driven ground rod from y_top down."""
        self.line(x, y_top, x, y_top + length, ROD, 9)
        self.poly([(x - 5, y_top + length), (x + 5, y_top + length), (x, y_top + length + 12)], ROD)
        if length >= 30:
            cy = y_top + min(14, length * 0.15)
            self.rect(x - 8, cy - 6, 16, 12, fill=CLAMP, stroke=TEXT, sw=1.5, rx=3)
            self.line(x + 8, cy, x + 13, cy, TEXT, 3)
        if label:
            self.text(x, y_top + length + 38, label, T_NOTE, MUTED)

    def stud(self, x, y, w, h, label=None):
        self.rect(x, y, w, h, fill=WOOD, op=0.55, stroke="#ca8a04", sw=SW_THIN)
        for k in range(1, 4):
            yy = y + h * k / 4
            self.path(f"M {x + 4} {yy} q {w / 4} -6 {w / 2} 0 t {w / 2 - 8} 0", "#ca8a04", 1)
        if label:
            self.text(x + w / 2, y - 12, label, T_NOTE, MUTED)

    def mark_ok(self, cx, cy, r=18):
        self.circle(cx, cy, r, fill=OK)
        self.polyline([(cx - r * 0.45, cy), (cx - r * 0.12, cy + r * 0.38), (cx + r * 0.5, cy - r * 0.38)], BG, 5)

    def mark_no(self, cx, cy, r=18):
        self.circle(cx, cy, r, fill=NO)
        d = r * 0.42
        self.line(cx - d, cy - d, cx + d, cy + d, BG, 5)
        self.line(cx - d, cy + d, cx + d, cy - d, BG, 5)

    def tag(self, x, y, s, anchor="start"):
        """Section reference chip, e.g. 'NEC 250.53(A)(3)'."""
        size = T_NOTE
        tw = text_width(s, size, True)
        x0 = x - (tw / 2 if anchor == "middle" else tw if anchor == "end" else 0) - 10
        self.rect(x0, y - size - 4, tw + 20, size + 14, fill=PANEL, stroke=EDGE, sw=SW_THIN, rx=8)
        self.text(x0 + 10, y + 2, s, size, DIM, "start", True)

    def title(self, s, x=None, y=40, size=T_LABEL, fill=MUTED):
        self.text(self.w / 2 if x is None else x, y, s, size, fill, "middle" if x is None else "start", True)

    def legend(self, items, x, y, size=T_NOTE):
        """items: [(color, text, kind)] kind in {'line', 'box', 'dash'}; top-left at (x, y)."""
        for i, (color, label, *kind) in enumerate(items):
            k = kind[0] if kind else "line"
            yy = y + i * (size + 12)
            if k == "box":
                self.rect(x, yy - 10, 26, 18, fill=color, op=0.5, stroke=color, sw=SW_THIN, rx=3)
            elif k == "dash":
                self.dline(x, yy, x + 26, yy, color, SW_OBJ, 6, 4)
            else:
                self.line(x, yy, x + 26, yy, color, SW_WIRE + 1)
            self.text(x + 36, yy + 7, label, size, TEXT, "start")

    # ------------------------------------------------------------ output
    def svg(self):
        body = "\n".join(self.parts)
        return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.w}" height="{self.h}" '
                f'viewBox="0 0 {self.w} {self.h}">\n{body}\n</svg>\n')


def _union(boxes):
    x0 = min(b[0] for b in boxes)
    y0 = min(b[1] for b in boxes)
    x1 = max(b[0] + b[2] for b in boxes)
    y1 = max(b[1] + b[3] for b in boxes)
    return [x0, y0, x1 - x0, y1 - y0]


# ---------------------------------------------------------------- registry
FIGURES = {}


def figure(name, records, h=450, when=None, nec="", terms=None, note="", keep=()):
    """Register a drawing.

    name     file stem (assets/diagrams/nec/<name>.png), lower-case, [a-z0-9_-]
    records  record ids this drawing serves; a dict {id: {"when": ..., "terms": [...]}}
             sets per-record options; {"like": other_id} makes a repeat question share
             the other record's masks, highlight, terms and timing
    when     "before" (setup: shown pre-answer, answers masked) or "after"
             (teaching: shown only once answered); default "before"
    nec      section(s) the drawing is authored from, e.g. "250.53(A)(3)"
    terms    extra answer words to scan for, per record: {id: ["MBJ", ...]}
    keep     regexes for labels that are the question's own data and stay visible
             before answering although they state a value (required exam figures)
    """
    def deco(fn):
        assert name not in FIGURES, f"duplicate figure {name}"
        recs = records if isinstance(records, dict) else {r: {} for r in records}
        FIGURES[name] = {"fn": fn, "records": recs, "h": h, "when": when or "before",
                         "nec": nec, "terms": terms or {}, "note": note, "module": fn.__module__,
                         "keep": list(keep)}
        return fn
    return deco
