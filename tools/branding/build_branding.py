"""Build every branded image from the SVG sources in assets/branding/source/.

    python tools/branding/build_branding.py

Needs Pillow and the Godot console binary ($GODOT, default: tools/godot.env's
GODOT_BINARY in the repo root), which rasterises the SVGs (tools/branding/render_svg.gd). Run it with a
temporary APPDATA like every other Godot run. Wordmark text is set in Barlow Semi Condensed
(assets/branding/source/fonts/, SIL OFL) from data/edition.json and the bank, never typed in.

Writes:
  assets/branding/source/png/icon_<size>.png   16 ... 1024 (16 and 24 from icon_small.svg)
  assets/branding/icon.png                     512 px, application/config/icon
  assets/branding/icon.ico                     16-256, one hand-picked image per size
  assets/branding/android_icon_192.png         legacy Android launcher icon
  assets/branding/android_{foreground,background,monochrome}.png   432 px adaptive layers
  assets/branding/mark.png                     the mark alone, for the menu title (Widgets.make_brand_title)
  assets/branding/splash.png                   1440x1080 boot splash, drawn at 2x and shrunk by stretch_mode Keep
  docs/media/banner.png                        1280x640 README / social preview banner
  .audit_tmp/shots/release/icon_sizes.png      the icon at every size, dark and light
"""
from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "release"))
sys.path.insert(0, str(ROOT / "tools" / "visual"))
sys.path.insert(0, str(ROOT / "tools"))
from godot_env import godot_binary  # noqa: E402
from make_showcase import hero_facts  # noqa: E402
from sync_identity import identity  # noqa: E402

IDENTITY = identity(ROOT)
EDITION = IDENTITY["edition"]["short"]  # "NEC 2023", drawn into the splash and banner
BRAND = ROOT / "assets" / "branding"
SRC = BRAND / "source"
PNG = SRC / "png"
FONTS = SRC / "fonts"
BANNER = ROOT / "docs" / "media" / "banner.png"
SCRATCH = ROOT / ".audit_tmp" / "branding_render"
SHEET = ROOT / ".audit_tmp" / "shots" / "release" / "icon_sizes.png"

ICON_SIZES = [16, 24, 32, 48, 64, 128, 256, 512, 1024]
SMALL_SIZES = [16, 24]  # from icon_small.svg: the full icon's sheen and traces turn to mush below 32 px
ICO_SIZES = [16, 24, 32, 48, 64, 128, 256]
MARK_PX = 128  # menu title mark; shown at 22-48 px, so this stays sharp at 2x UI scale
MARK_SIZES = [MARK_PX, 640, 120, 80]  # in-app, splash hero, banner wordmark, splash wordmark

BG = (2, 4, 8)  # AppTheme.BG_TOP, the boot splash / clear colour
BG_BOTTOM = (8, 16, 30)  # AppTheme.BG_BOTTOM
SLATE_50 = (248, 250, 252)
SLATE_300 = (203, 213, 225)
SLATE_400 = (148, 163, 184)
SLATE_500 = (100, 116, 139)
SKY_400 = (56, 189, 248)
AMBER_400 = (251, 191, 36)
BORDER_BLUE = (30, 58, 95)
CHIP_BG = (11, 20, 38)


def godot() -> str:
    exe = godot_binary(ROOT)
    if not Path(exe).exists():
        sys.exit(f"Godot not found: {exe} (set GODOT)")
    return exe


def render(jobs: list[tuple[Path, Path, list[int]]]) -> None:
    args = []
    for svg, prefix, sizes in jobs:
        args += [str(svg), str(prefix), ",".join(map(str, sizes))]
    cmd = [godot(), "--headless", "--path", str(ROOT), "--script", "res://tools/branding/render_svg.gd", "--", *args]
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        sys.exit(f"render failed ({res.returncode}):\n{res.stdout}\n{res.stderr}")


def font(weight: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONTS / f"BarlowSemiCondensed-{weight}.ttf"), size)


def tracked_width(text: str, f: ImageFont.FreeTypeFont, tracking: float) -> float:
    return sum(f.getlength(ch) for ch in text) + tracking * max(0, len(text) - 1)


def draw_tracked(d: ImageDraw.ImageDraw, x: float, baseline: float, text: str, f: ImageFont.FreeTypeFont,
                 fill, tracking: float) -> float:
    for ch in text:
        d.text((x, baseline), ch, font=f, fill=fill, anchor="ls")
        x += f.getlength(ch) + tracking
    return x


def wordmark(canvas: Image.Image, cx: float, baseline: float, size: int, mark: Image.Image) -> None:
    """'NEC 2023 <mark> JOURNEYMAN CHALLENGE' centred on cx: the mark is the title's '//'."""
    d = ImageDraw.Draw(canvas)
    f = font("Bold", size)
    track = size * 0.02
    lead, tail = EDITION, "JOURNEYMAN CHALLENGE"
    cap = size * 0.70
    mh = round(cap * 1.55)  # the mark's box has ~5% padding, so its art stands ~1.4 cap heights
    m = mark.resize((mh, mh), Image.LANCZOS)
    gap = size * 0.12
    wl, wt = tracked_width(lead, f, track), tracked_width(tail, f, track)
    x = cx - (wl + gap + mh + gap + wt) / 2
    x = draw_tracked(d, x, baseline, lead, f, SLATE_50, track) + gap
    canvas.alpha_composite(m, (round(x), round(baseline - cap / 2 - mh / 2)))
    draw_tracked(d, x + mh + gap, baseline, tail, f, SLATE_50, track)


def glow(canvas: Image.Image, box: tuple[int, int, int, int], colour, strength: float) -> None:
    w, h = box[2] - box[0], box[3] - box[1]
    # radial_gradient is the distance from the centre in px of a 256 square: 128 at the edge midpoints.
    alpha = Image.radial_gradient("L").point(lambda v: round(255 * strength * max(0.0, 1 - v / 128) ** 2))
    alpha = alpha.resize((w, h), Image.BICUBIC)
    layer = Image.new("RGBA", (w, h), colour)
    layer.putalpha(alpha)
    canvas.alpha_composite(layer, (box[0], box[1]))


def vertical_gradient(size: tuple[int, int], top, bottom) -> Image.Image:
    col = Image.new("RGBA", (1, size[1]))
    for y in range(size[1]):
        t = y / max(1, size[1] - 1)
        col.putpixel((0, y), tuple(round(a + (b - a) * t) for a, b in zip(top, bottom)) + (255,))
    return col.resize(size)


def build_ico(images: dict[int, Image.Image], dest: Path) -> None:
    ordered = [images[s].convert("RGBA") for s in sorted(ICO_SIZES, reverse=True)]
    ordered[0].save(dest, format="ICO", sizes=[(s, s) for s in sorted(ICO_SIZES, reverse=True)],
                    append_images=ordered[1:])
    with Image.open(dest) as ico:
        got = sorted(s[0] for s in ico.info["sizes"])
    if got != sorted(ICO_SIZES):
        sys.exit(f"icon.ico has sizes {got}, expected {sorted(ICO_SIZES)}")


def splash_subtitle() -> str:
    return f"{EDITION} EDITION  \u00b7  JOURNEYMAN EXAM PREP"


def build_splash(mark: Image.Image, mark_small: Image.Image, dest: Path) -> None:
    """Drawn at 2x on the clear colour; stretch_mode Keep fits it to the window. 4:3 rather
    than 16:9 so a portrait phone, which fits it to its width, still shows it large."""
    w, h = 1440, 1080
    img = Image.new("RGBA", (w, h), BG + (255,))
    glow(img, (180, 60, 1260, 860), SKY_400, 0.30)
    hero = mark.resize((300, 300), Image.LANCZOS)
    img.alpha_composite(hero, ((w - 300) // 2, 250))
    wordmark(img, w / 2, 700, 64, mark_small)
    d = ImageDraw.Draw(img)
    sub, f = splash_subtitle(), font("SemiBold", 26)
    draw_tracked(d, (w - tracked_width(sub, f, 7.8)) / 2, 772, sub, f, SLATE_500, 7.8)
    img.convert("RGB").save(dest, optimize=True)


def build_banner(mark: Image.Image, dest: Path) -> None:
    """README / social preview: the mark, the wordmark and what the app is, all from data."""
    facts = hero_facts()
    w, h = 1280, 640
    img = vertical_gradient((w, h), BG, BG_BOTTOM)
    d = ImageDraw.Draw(img)
    grid = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(grid)
    for x in range(0, w, 64):
        gd.line((x, 0, x, h), fill=BORDER_BLUE + (56,))
    for y in range(0, h, 64):
        gd.line((0, y, w, y), fill=BORDER_BLUE + (56,))
    img.alpha_composite(grid)
    glow(img, (-80, 20, 680, 620), SKY_400, 0.36)
    glow(img, (500, 130, 1340, 530), AMBER_400, 0.16)
    img.alpha_composite(mark.resize((340, 340), Image.LANCZOS), (90, 150))
    tx = 470
    eyebrow, fe = facts["edition"], font("SemiBold", 28)
    end = draw_tracked(d, tx, 262, eyebrow, fe, SKY_400, 9)
    rule = Image.new("RGBA", (96, 3))
    for x in range(96):
        t = x / 95
        rule.putpixel((x, 0), tuple(round(a + (b - a) * t) for a, b in zip(SKY_400, AMBER_400)) + (255,))
    img.alpha_composite(rule.resize((96, 3)), (round(end + 16), 251))
    draw_tracked(d, tx, 334, "JOURNEYMAN CHALLENGE", font("Bold", 66), SLATE_50, 1.3)
    tag = f"{facts['questions']} EXAM-STYLE QUESTIONS  \u00b7  A LESSON AFTER EVERY ANSWER"
    draw_tracked(d, tx, 388, tag, font("SemiBold", 22), SLATE_400, 1.6)
    cx, fc = tx, font("SemiBold", 18)
    for chip in ("WINDOWS", "ANDROID", "OFFLINE", f"{facts['items']}-QUESTION SIMULATOR"):
        cw = tracked_width(chip, fc, 2.2) + 36
        d.rounded_rectangle((cx, 428, cx + cw, 466), 19, fill=CHIP_BG, outline=BORDER_BLUE, width=2)
        draw_tracked(d, cx + 18, 453, chip, fc, SLATE_300, 2.2)
        cx += cw + 12
    dest.parent.mkdir(parents=True, exist_ok=True)
    img.convert("RGB").save(dest, optimize=True)


def build_sheet(final: dict[int, Path], dest: Path) -> None:
    sheet = Image.new("RGB", (1100, 330), "#0b1221")
    d = ImageDraw.Draw(sheet)
    d.text((20, 14), f"{IDENTITY['display_name']}: icon at actual size on dark and light, 4x zoom of 16/24/32 px",
           fill="#cbd5e1", font=font("SemiBold", 20))
    x = 20
    for bg in ("#202020", "#f3f3f3"):
        d.rectangle([x, 52, x + 260, 140], fill=bg)
        cx = x + 10
        for s in (16, 24, 32, 48, 64):
            im = Image.open(final[s]).convert("RGBA")
            sheet.paste(im, (cx, 64 + (64 - s) // 2), im)
            cx += s + 10
        x += 274
    zx = 20
    for s in (16, 24, 32):
        im = Image.open(final[s]).convert("RGBA").resize((s * 4, s * 4), Image.NEAREST)
        d.rectangle([zx, 160, zx + s * 4 - 1, 160 + s * 4 - 1], fill="#202020")
        sheet.paste(im, (zx, 160), im)
        zx += s * 4 + 18
    big = Image.open(final[256]).convert("RGBA").resize((256, 256), Image.LANCZOS)
    sheet.paste(big, (820, 56), big)
    dest.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(dest)


def main() -> None:
    PNG.mkdir(parents=True, exist_ok=True)
    if SCRATCH.exists():
        shutil.rmtree(SCRATCH)
    SCRATCH.mkdir(parents=True)
    big = [s for s in ICON_SIZES if s not in SMALL_SIZES] + [192]
    render([
        (SRC / "icon.svg", SCRATCH / "icon", big),
        (SRC / "icon_small.svg", SCRATCH / "icon_small", SMALL_SIZES),
        (SRC / "mark.svg", SCRATCH / "mark", MARK_SIZES),
        (SRC / "android_foreground.svg", SCRATCH / "android_foreground", [432]),
        (SRC / "android_background.svg", SCRATCH / "android_background", [432]),
        (SRC / "android_monochrome.svg", SCRATCH / "android_monochrome", [432]),
    ])

    final: dict[int, Path] = {}
    for s in ICON_SIZES:
        src = SCRATCH / (f"icon_small_{s}.png" if s in SMALL_SIZES else f"icon_{s}.png")
        final[s] = PNG / f"icon_{s}.png"
        shutil.copyfile(src, final[s])
    build_ico({s: Image.open(final[s]) for s in ICO_SIZES}, BRAND / "icon.ico")
    shutil.copyfile(final[512], BRAND / "icon.png")
    shutil.copyfile(SCRATCH / "icon_192.png", BRAND / "android_icon_192.png")
    for layer in ("foreground", "background", "monochrome"):
        shutil.copyfile(SCRATCH / f"android_{layer}_432.png", BRAND / f"android_{layer}.png")
    shutil.copyfile(SCRATCH / f"mark_{MARK_PX}.png", BRAND / "mark.png")
    mark = Image.open(SCRATCH / "mark_640.png").convert("RGBA")
    build_splash(mark, Image.open(SCRATCH / "mark_80.png").convert("RGBA"), BRAND / "splash.png")
    build_banner(mark, BANNER)
    build_sheet(final, SHEET)
    print("branding built:", ", ".join(p.name for p in sorted(BRAND.glob("*.*")) if p.suffix != ".import"))
    print("banner:", BANNER)
    print("sheet:", SHEET)


if __name__ == "__main__":
    main()
