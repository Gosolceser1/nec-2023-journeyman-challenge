"""README media from the showcase captures: quantized screenshots and the hero banner.

    Godot --path . --script tools/visual/snap_showcase.gd                                   (temp APPDATA!)
    Godot --path . --script tools/visual/snap_showcase.gd -- --mobile-ui --win=1080x1920
    python tools/visual/make_showcase.py

Reads .audit_tmp/shots/showcase/, writes docs/media/. The answer GIFs are made
separately: snap_motion.gd -- --answers, then ffmpeg (crop 1280x340, 30 fps).
"""
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
SHOTS = ROOT / ".audit_tmp" / "shots" / "showcase"
OUT = ROOT / "docs" / "media"
ICON = ROOT / "assets" / "branding" / "icon.png"
FONTS = Path("C:/Windows/Fonts")

BG_TOP = (2, 4, 8)
BG_BOTTOM = (8, 16, 30)
SKY_400 = (56, 189, 248)
SLATE_300 = (203, 213, 225)
SLATE_400 = (148, 163, 184)
HAIRLINE = (30, 58, 88)

STILLS = {
    "desktop-menu.png": "desk_01_menu.png",
    "desktop-table-question.png": "desk_02_table_question.png",
    "desktop-correct.png": "desk_03_table_correct.png",
    "desktop-wrong.png": "desk_06_wrong.png",
    "desktop-diagram.png": "desk_07_diagram_question.png",
    "desktop-simulator.png": "desk_08_simulator.png",
    "desktop-results.png": "desk_09_results.png",
    "mobile-menu.png": "mob_01_menu.png",
    "mobile-question.png": "mob_02_table_question.png",
    "mobile-results.png": "mob_09_results.png",
}


def hero_facts() -> dict:
    """What the banner states: the edition, the bank's playable questions, the simulator size."""
    edition = json.loads((ROOT / "data" / "edition.json").read_text(encoding="utf-8"))
    bank = json.loads((ROOT / "data" / "question_bank.json").read_text(encoding="utf-8"))
    blueprint = json.loads((ROOT / "data" / "exam_blueprint.json").read_text(encoding="utf-8"))
    return {"edition": edition["short"], "questions": int(bank["playable"]),
            "items": sum(int(a["items"]) for a in blueprint["areas"])}


def quantize_save(img: Image.Image, path: Path, colors: int = 256) -> None:
    q = img.convert("RGB").quantize(colors, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.FLOYDSTEINBERG)
    q.save(path, optimize=True)


def font(name: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONTS / name), size)


def vertical_gradient(size: tuple[int, int], top, bottom) -> Image.Image:
    w, h = size
    col = Image.new("RGB", (1, h))
    for y in range(h):
        t = y / max(1, h - 1)
        col.putpixel((0, y), tuple(round(a + (b - a) * t) for a, b in zip(top, bottom)))
    return col.resize((w, h))


def rounded(img: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, img.width - 1, img.height - 1), radius, fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def paste_framed(canvas: Image.Image, shot: Image.Image, box: tuple[int, int, int, int], radius: int, border: int) -> None:
    x, y, w, h = box
    glow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(glow).rounded_rectangle((x - 6, y - 6, x + w + 6, y + h + 6), radius + 6, fill=(*SKY_400, 70))
    canvas.alpha_composite(glow.filter(ImageFilter.GaussianBlur(22)))
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle((x + 8, y + 16, x + w + 8, y + h + 16), radius, fill=(0, 0, 0, 170))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(18)))
    frame = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(frame).rounded_rectangle((x - border, y - border, x + w + border, y + h + border), radius + border,
                                            fill=(13, 22, 38, 255), outline=(*SKY_400, 150), width=2)
    canvas.alpha_composite(frame)
    canvas.alpha_composite(rounded(shot.resize((w, h), Image.LANCZOS), radius), (x, y))


def hero() -> Image.Image:
    W, H = 1600, 800
    canvas = vertical_gradient((W, H), BG_TOP, BG_BOTTOM).convert("RGBA")
    d = ImageDraw.Draw(canvas)
    for gx in range(0, W, 40):
        d.line((gx, 0, gx, H), fill=(12, 24, 40, 255))
    for gy in range(0, H, 40):
        d.line((0, gy, W, gy), fill=(12, 24, 40, 255))
    halo = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(halo).ellipse((760, 60, 1560, 760), fill=(*SKY_400, 38))
    canvas.alpha_composite(halo.filter(ImageFilter.GaussianBlur(120)))

    icon = Image.open(ICON).convert("RGBA").resize((148, 148), Image.LANCZOS)
    canvas.alpha_composite(icon, (80, 150))
    facts = hero_facts()
    d = ImageDraw.Draw(canvas)
    d.text((82, 330), f"NFPA 70  •  {facts['edition']}  •  JOURNEYMAN EXAM PREP", font=font("seguisb.ttf", 18), fill=SKY_400)
    d.text((78, 362), f"{facts['edition']} //", font=font("segoeuib.ttf", 58), fill=(255, 255, 255))
    d.text((78, 432), "Journeyman", font=font("segoeuib.ttf", 58), fill=(255, 255, 255))
    d.text((78, 502), "Challenge", font=font("segoeuib.ttf", 58), fill=SKY_400)
    body = font("segoeui.ttf", 23)
    d.text((82, 598), f"{facts['questions']} exam-style questions with the NEC", font=body, fill=SLATE_300)
    d.text((82, 630), "reference, a lesson and a memory tip.", font=body, fill=SLATE_300)
    chip_font = font("seguisb.ttf", 17)
    cx = 82
    for label in ("Windows", "Android", "Offline", f"{facts['items']}-question simulator"):
        tw = d.textlength(label, font=chip_font)
        d.rounded_rectangle((cx, 690, cx + tw + 28, 724), 17, fill=(11, 18, 33), outline=HAIRLINE, width=2)
        d.text((cx + 14, 696), label, font=chip_font, fill=SLATE_400)
        cx += tw + 40

    desk = Image.open(SHOTS / "desk_03_table_correct.png")
    phone = Image.open(SHOTS / "mob_01_menu.png")
    paste_framed(canvas, desk, (560, 110, 880, 495), 14, 8)
    paste_framed(canvas, phone, (1296, 200, 270, 480), 26, 10)
    return canvas.convert("RGB")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for name, src in STILLS.items():
        quantize_save(Image.open(SHOTS / src), OUT / name)
    quantize_save(hero(), OUT / "hero.png")
    total = 0
    for p in sorted(OUT.iterdir()):
        total += p.stat().st_size
        print(f"{p.name:32} {p.stat().st_size / 1024:8.0f} KB")
    print(f"{'total':32} {total / 1024 / 1024:8.2f} MB")


if __name__ == "__main__":
    main()
