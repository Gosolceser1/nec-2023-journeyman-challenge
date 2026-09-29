"""Quick look at figures as the app shows them, without Godot.

    python tools/diagrams/preview.py [NAME ...] [--out DIR]

For each figure (default: all built ones) writes <out>/<name>.png: one row
per record, "before answering" (the '?' badges drawn like DiagramView) and
"after" (badges gone, answer regions ringed). Reads the built PNGs and
data/diagram_masks.json, so run build.py first. Also writes
<out>/_index.png, a small thumbnail sheet of every figure.
"""
import argparse
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
FIG_MAP = ROOT / "assets" / "diagrams" / "nec" / "figures.json"
MASKS = ROOT / "data" / "diagram_masks.json"

SLATE_900 = (15, 23, 42)
SKY_400 = (56, 189, 248)
AMBER_400 = (251, 191, 36)
EMERALD_500 = (16, 185, 129)
HEAD = (148, 163, 184)


def font(size):
    for name in ("arialbd.ttf", "DejaVuSans-Bold.ttf", "Arial Bold.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            pass
    return ImageFont.load_default()


def draw_state(img, masks, answered, scale=1.0, highlight=None):
    im = img.convert("RGB").copy()
    d = ImageDraw.Draw(im)
    w, h = im.size
    if answered and highlight:
        x, y, hw, hh = highlight
        d.rounded_rectangle([x * w, y * h, (x + hw) * w, (y + hh) * h], radius=int(6 * scale),
                            outline=EMERALD_500, width=max(2, int(2.5 * scale)))
    for m in masks:
        x, y, mw, mh = m["rect"]
        box = [x * w, y * h, (x + mw) * w, (y + mh) * h]
        if answered:
            if m.get("ring"):
                g = 3 * scale
                d.rounded_rectangle([box[0] - g, box[1] - g, box[2] + g, box[3] + g], radius=int(6 * scale),
                                    outline=EMERALD_500, width=max(2, int(2.5 * scale)))
            continue
        r = int(min((box[3] - box[1]) * 0.3, 10 * scale))
        d.rounded_rectangle(box, radius=r, fill=SLATE_900, outline=SKY_400, width=max(1, int(2 * scale)))
        label = m.get("label", "?")
        fs = int(max(8, min((box[3] - box[1]) * 0.62, 44 * scale)))
        f = font(fs)
        while d.textlength(label, font=f) > (box[2] - box[0]) * 0.9 and fs > 8:
            fs -= 1
            f = font(fs)
        tw = d.textlength(label, font=f)
        d.text(((box[0] + box[2] - tw) / 2, (box[1] + box[3]) / 2), label, font=f, fill=AMBER_400, anchor="lm")
    return im


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("names", nargs="*")
    ap.add_argument("--out", default=str(ROOT / ".audit_tmp" / "diagrams" / "preview"))
    args = ap.parse_args()
    fig_map = json.loads(FIG_MAP.read_text(encoding="utf-8"))
    recs = json.loads(MASKS.read_text(encoding="utf-8")).get("records", {})
    by_fig = {}
    for rid, e in fig_map.items():
        by_fig.setdefault(e["figure"], []).append(rid)
    names = args.names or sorted(by_fig)
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    thumbs = []
    hf = font(22)
    for name in names:
        if name not in by_fig:
            print("no such built figure:", name, file=sys.stderr)
            continue
        img = Image.open(ROOT / "assets" / "diagrams" / "nec" / f"{name}.png")
        w, h = img.size
        rows = sorted(by_fig[name])
        sheet = Image.new("RGB", (w * 2 + 30, (h + 40) * len(rows) + 10), (2, 6, 23))
        d = ImageDraw.Draw(sheet)
        for i, rid in enumerate(rows):
            e = recs.get(rid, {})
            when = e.get("when", "before")
            y = 10 + i * (h + 40)
            d.text((10, y), f"{rid}  ({when})  BEFORE", font=hf, fill=HEAD)
            d.text((w + 20, y), "AFTER", font=hf, fill=HEAD)
            if when == "before":
                sheet.paste(draw_state(img, e.get("masks", []), False, 1.5), (10, y + 30))
            else:
                d.text((20, y + 60), "(not shown before answering)", font=hf, fill=HEAD)
            sheet.paste(draw_state(img, e.get("masks", []), True, 1.5, fig_map[rid].get("highlight")), (w + 20, y + 30))
        sheet.save(out / f"{name}.png", optimize=True)
        t = img.convert("RGB").copy()
        t.thumbnail((400, 300))
        thumbs.append((name, t))
        print(out / f"{name}.png")
    if thumbs and not args.names:
        cols = 4
        th = max(t.size[1] for _, t in thumbs) + 30
        idx = Image.new("RGB", (cols * 410 + 10, ((len(thumbs) + cols - 1) // cols) * th + 10), (2, 6, 23))
        d = ImageDraw.Draw(idx)
        sf = font(14)
        for k, (name, t) in enumerate(thumbs):
            x, y = 10 + (k % cols) * 410, 10 + (k // cols) * th
            idx.paste(t, (x, y + 20))
            d.text((x, y), name, font=sf, fill=HEAD)
        idx.save(out / "_index.png", optimize=True)


if __name__ == "__main__":
    main()
