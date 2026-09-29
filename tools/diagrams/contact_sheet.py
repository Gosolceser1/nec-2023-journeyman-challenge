"""Contact sheet of the prototype figure screenshots (tools/visual/snap_diagram_protos.gd).

    python tools/diagrams/contact_sheet.py <shots_dir> <out.png>

One row per prototype: desktop pre, desktop post, phone pre, phone zoom (pre), phone post.
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

NAMES = [
    ("working_space_110-26", "110.26 working space + dedicated space  (final-exam-#1-057)"),
    ("balcony_receptacle_210-52E3", "210.52(E)(3) balcony receptacle height  (final-exam-#1-008, open-book-exam-#10-020)"),
    ("burial_under_concrete_300-5", "Table 300.5(A) cover under 2 in concrete  (final-exam-#1-049, open-book-exam-#4-004)"),
    ("service_bonding_250", "250.28 main bonding jumper / GEC  (open-book-exam-#1-002; GEC variant for #10-024)"),
]
ROW_H, GAP, HEAD = 480, 16, 44


def font(size):
    for f in ("arialbd.ttf", "arial.ttf", "DejaVuSans-Bold.ttf"):
        try:
            return ImageFont.truetype(f, size)
        except OSError:
            continue
    return ImageFont.load_default()


def main():
    shots, out = Path(sys.argv[1]), Path(sys.argv[2])
    cells = [("desk_1280x720", "_pre", "Desktop 1280x720, before (masked)"),
             ("desk_1280x720", "_post", "Desktop, after (revealed)"),
             ("mob_540x960", "_pre", "Phone 540x960, before"),
             ("mob_540x960", "_zoom", "Phone zoom, before"),
             ("mob_540x960", "_post", "Phone, after")]
    desk, mob = round(ROW_H * 1280 / 720), round(ROW_H * 540 / 960)
    widths = [desk, desk, mob, mob, mob]
    W = sum(widths) + GAP * (len(widths) + 1)
    H = 70 + len(NAMES) * (HEAD + ROW_H + GAP)
    sheet = Image.new("RGB", (W, H), (2, 6, 23))
    d = ImageDraw.Draw(sheet)
    d.text((GAP, 18), "Prototype study figures: answer masked with '?' until answered (original, from NEC 2023 text; not wired into the bank)",
           fill=(56, 189, 248), font=font(30))
    y = 70
    for name, title in NAMES:
        d.text((GAP, y + 8), title, fill=(226, 232, 240), font=font(26))
        x = GAP
        for (prefix, phase, label), w in zip(cells, widths):
            p = shots / f"{prefix}_{name}{phase}.png"
            im = Image.open(p).convert("RGB").resize((w, ROW_H), Image.LANCZOS)
            sheet.paste(im, (x, y + HEAD))
            d.rectangle((x, y + HEAD + ROW_H - 30, x + w, y + HEAD + ROW_H), fill=(15, 23, 42))
            d.text((x + 8, y + HEAD + ROW_H - 26), label, fill=(148, 163, 184), font=font(18))
            x += w + GAP
        y += HEAD + ROW_H + GAP
    sheet.save(out, optimize=True)
    print(out, sheet.size)


if __name__ == "__main__":
    main()
