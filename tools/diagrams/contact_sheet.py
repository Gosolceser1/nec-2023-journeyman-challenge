"""Contact sheet of in-app diagram shots (tools/visual/snap_diagrams.gd output).

One row per record: desktop before/after answering, mobile before/zoom/after.
Missing shots render as an empty cell, so a gap in the sweep is visible.

    python tools/diagrams/contact_sheet.py SHOTS_DIR OUT_PREFIX [--rows 8]

Writes OUT_PREFIX.png when everything fits on one page, otherwise
OUT_PREFIX_01.png, OUT_PREFIX_02.png, ...
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROW_H = 400
LABEL_W = 260
GAP = 12
BG = (15, 23, 42)
CELL = (30, 41, 59)
TEXT = (226, 232, 240)
MUTED = (148, 163, 184)
COLUMNS = [("desk", "pre", "desktop, before"), ("desk", "post", "desktop, after"),
           ("mob", "pre", "phone, before"), ("mob", "zoom", "phone, zoom"),
           ("mob", "post", "phone, after")]
NAME = re.compile(r"^(desk|mob)_(\d+)x(\d+)_(.+)_(pre|zoom|post)\.png$")


def font(size: int) -> ImageFont.ImageFont:
    for name in ("segoeui.ttf", "arial.ttf", "DejaVuSans.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def scan(shots: Path) -> tuple[dict, dict]:
    found: dict[str, dict] = {}
    aspect: dict[str, float] = {}
    for p in sorted(shots.glob("*.png")):
        m = NAME.match(p.name)
        if not m:
            continue
        layout, w, h, rid, state = m.groups()
        found.setdefault(rid, {})[(layout, state)] = p
        aspect[layout] = int(w) / int(h)
    return found, aspect


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("shots", type=Path)
    ap.add_argument("out_prefix", type=Path)
    ap.add_argument("--rows", type=int, default=8)
    ap.add_argument("--masks", type=Path,
                    default=Path(__file__).resolve().parents[2] / "data" / "diagram_masks.json")
    a = ap.parse_args()
    after = set()
    if a.masks.exists():
        records = json.loads(a.masks.read_text(encoding="utf-8")).get("records", {})
        after = {rid.replace("#", "") for rid, e in records.items() if e.get("when") == "after"}
    found, aspect = scan(a.shots)
    if not found:
        print("no shots in", a.shots)
        return 1
    widths = [round(ROW_H * aspect.get(layout, 0.5625)) for layout, _, _ in COLUMNS]
    sheet_w = LABEL_W + sum(widths) + GAP * (len(widths) + 1)
    head_h = 44
    f_id, f_head = font(22), font(20)
    ids = sorted(found)
    pages = [ids[i:i + a.rows] for i in range(0, len(ids), a.rows)]
    a.out_prefix.parent.mkdir(parents=True, exist_ok=True)
    missing = 0
    for n, page in enumerate(pages, 1):
        img = Image.new("RGB", (sheet_w, head_h + len(page) * (ROW_H + GAP) + GAP), BG)
        d = ImageDraw.Draw(img)
        x = LABEL_W + GAP
        for (_, _, title), w in zip(COLUMNS, widths):
            d.text((x, 10), title, fill=MUTED, font=f_head)
            x += w + GAP
        for r, rid in enumerate(page):
            y = head_h + r * (ROW_H + GAP)
            d.text((GAP, y + 8), rid, fill=TEXT, font=f_id)
            x = LABEL_W + GAP
            for (layout, state, _), w in zip(COLUMNS, widths):
                p = found[rid].get((layout, state))
                if p is None:
                    d.rectangle([x, y, x + w, y + ROW_H], fill=CELL)
                    hidden = rid in after and state != "post"
                    d.text((x + 10, y + 10), "figure shown\nafter answering" if hidden else "no shot",
                           fill=MUTED, font=f_head)
                    missing += 0 if hidden else 1
                else:
                    with Image.open(p) as shot:
                        img.paste(shot.convert("RGB").resize((w, ROW_H), Image.LANCZOS), (x, y))
                x += w + GAP
        out = a.out_prefix.with_suffix(".png") if len(pages) == 1 else \
            a.out_prefix.with_name(f"{a.out_prefix.name}_{n:02d}.png")
        img.save(out, optimize=True)
        print(out)
    print(f"{len(ids)} records, {len(pages)} page(s), {missing} missing shot(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
