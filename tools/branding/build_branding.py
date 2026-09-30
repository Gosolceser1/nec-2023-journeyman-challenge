"""Build every branded image from the SVG sources in assets/branding/source/.

    python tools/branding/build_branding.py

Needs Pillow and the Godot console binary ($GODOT, default: the one in the repo
root), which rasterises the SVGs (tools/branding/render_svg.gd). Run it with a
temporary APPDATA like every other Godot run.

Writes:
  assets/branding/source/png/icon_<size>.png   16 ... 1024 (16 and 24 from icon_small.svg)
  assets/branding/icon.png                     512 px, application/config/icon
  assets/branding/icon.ico                     16-256, one hand-picked image per size
  assets/branding/android_icon_192.png         legacy Android launcher icon
  assets/branding/android_{foreground,background,monochrome}.png   432 px adaptive layers
  assets/branding/splash.png                   boot splash (icon + wordmark)
  .audit_tmp/shots/release/icon_options.png    the options sheet
"""
from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "release"))
from sync_identity import identity  # noqa: E402

IDENTITY = identity(ROOT)
EDITION = IDENTITY["edition"]["short"]  # "NEC 2023", drawn into the splash
BRAND = ROOT / "assets" / "branding"
SRC = BRAND / "source"
PNG = SRC / "png"
SCRATCH = ROOT / ".audit_tmp" / "branding_render"
SHEET = ROOT / ".audit_tmp" / "shots" / "release" / "icon_options.png"

ICON_SIZES = [16, 24, 32, 48, 64, 128, 256, 512, 1024]
SMALL_SIZES = [16, 24]  # from icon_small.svg: the badge turns to mush below 32 px
ICO_SIZES = [16, 24, 32, 48, 64, 128, 256]
PREVIEW_SIZES = [16, 24, 32, 48, 64, 256]

BG = "#020408"  # AppTheme.BG_TOP, the boot splash / clear colour
SLATE_50 = "#f8fafc"
SLATE_400 = "#94a3b8"
SKY_400 = "#38bdf8"


def godot() -> str:
    exe = os.environ.get("GODOT") or str(ROOT / "Godot_v4.7.2-stable_win64_console.exe")
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


def font(bold: bool, size: int) -> ImageFont.FreeTypeFont:
    for name in (("segoeuib.ttf", "arialbd.ttf") if bold else ("segoeui.ttf", "arial.ttf")):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def build_ico(images: dict[int, Image.Image], dest: Path) -> None:
    ordered = [images[s].convert("RGBA") for s in sorted(ICO_SIZES, reverse=True)]
    ordered[0].save(dest, format="ICO", sizes=[(s, s) for s in sorted(ICO_SIZES, reverse=True)],
                    append_images=ordered[1:])
    with Image.open(dest) as ico:
        got = sorted(s[0] for s in ico.info["sizes"])
    if got != sorted(ICO_SIZES):
        sys.exit(f"icon.ico has sizes {got}, expected {sorted(ICO_SIZES)}")


def build_splash(icon: Image.Image, dest: Path) -> None:
    """Icon over the wordmark, on the app's clear colour. Shown unscaled and centred."""
    w, h = 720, 400
    img = Image.new("RGBA", (w, h), BG)
    d = ImageDraw.Draw(img)
    ic = icon.resize((168, 168), Image.LANCZOS)
    img.alpha_composite(ic, ((w - 168) // 2, 40))
    title = font(True, 34)
    parts = [(f"{EDITION} ", SLATE_50), ("// ", SKY_400), ("JOURNEYMAN CHALLENGE", SLATE_50)]
    total = sum(d.textlength(t, font=title) for t, _ in parts)
    x = (w - total) / 2
    for t, colour in parts:
        d.text((x, 240), t, font=title, fill=colour)
        x += d.textlength(t, font=title)
    sub = font(True, 15)
    line = letter_spaced(f"NFPA 70 \u2022 {EDITION} EDITION")
    d.text(((w - d.textlength(line, font=sub)) / 2, 298), line, font=sub, fill=SLATE_400)
    img.convert("RGB").save(dest)


def letter_spaced(text: str) -> str:
    """"NEC 2023" -> "N E C   2 0 2 3": one space between letters, three between words."""
    return "   ".join(" ".join(word) for word in text.split())


def build_sheet(rows: list[tuple[str, dict[int, Path], bool]], dest: Path) -> None:
    row_h, width = 330, 1560
    sheet = Image.new("RGB", (width, 60 + row_h * len(rows)), "#0b1221")
    d = ImageDraw.Draw(sheet)
    d.text((20, 16), f"{IDENTITY['display_name']}: icon options (actual size on a dark taskbar and a light "
           "Explorer window, 4x zoom of 16/24/32 px, and 256 px)", fill="#cbd5e1", font=font(False, 18))
    for r, (label, paths, chosen) in enumerate(rows):
        y0 = 60 + r * row_h
        if chosen:
            d.rounded_rectangle([8, y0 - 6, width - 8, y0 + row_h - 14], 14, outline="#34d399", width=3)
        d.text((24, y0 + 4), label, fill="#34d399" if chosen else "#7dd3fc", font=font(True, 20))
        x = 24
        for bg in ("#202020", "#f3f3f3"):
            d.rectangle([x, y0 + 42, x + 260, y0 + 130], fill=bg)
            cx = x + 10
            for s in (16, 24, 32, 48, 64):
                im = Image.open(paths[s]).convert("RGBA")
                sheet.paste(im, (cx, y0 + 54 + (64 - s) // 2), im)
                cx += s + 10
            x += 274
        zx = 24
        for s in (16, 24, 32):
            im = Image.open(paths[s]).convert("RGBA").resize((s * 4, s * 4), Image.NEAREST)
            d.rectangle([zx, y0 + 150, zx + s * 4 - 1, y0 + 150 + s * 4 - 1], fill="#202020")
            sheet.paste(im, (zx, y0 + 150), im)
            d.text((zx, y0 + 156 + s * 4), f"{s} px x4", fill="#94a3b8", font=font(False, 13))
            zx += s * 4 + 18
        big = Image.open(paths[256]).convert("RGBA")
        sheet.paste(big, (width - 24 - 256 - 290, y0 + 36), big)
        light = Image.new("RGB", (256, 256), "#f3f3f3")
        light.paste(big, (0, 0), big)
        sheet.paste(light, (width - 24 - 256, y0 + 36))
    dest.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(dest)


def main() -> None:
    PNG.mkdir(parents=True, exist_ok=True)
    if SCRATCH.exists():
        shutil.rmtree(SCRATCH)
    SCRATCH.mkdir(parents=True)
    big = [s for s in ICON_SIZES if s not in SMALL_SIZES] + [192]
    jobs = [
        (SRC / "icon.svg", SCRATCH / "icon", big + SMALL_SIZES),
        (SRC / "icon_small.svg", SCRATCH / "icon_small", SMALL_SIZES + [32, 48, 64, 256]),
        (SRC / "android_foreground.svg", SCRATCH / "android_foreground", [432]),
        (SRC / "android_background.svg", SCRATCH / "android_background", [432]),
        (SRC / "android_monochrome.svg", SCRATCH / "android_monochrome", [432]),
    ]
    options = ["option_a_bolt", "option_b_shield", "option_c_ring"]
    for name in options:
        jobs.append((SRC / "options" / f"{name}.svg", SCRATCH / name, PREVIEW_SIZES))
    render(jobs)

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
    build_splash(Image.open(final[1024]).convert("RGBA"), BRAND / "splash.png")

    rows = [(f"Option {chr(65 + i)}: {n.split('_', 2)[2]}", {s: SCRATCH / f"{n}_{s}.png" for s in PREVIEW_SIZES}, False)
            for i, n in enumerate(options)]
    rows.append(("Chosen: bolt + pass check (plain bolt at 16 and 24 px)", final, True))
    build_sheet(rows, SHEET)
    print("branding built:", ", ".join(p.name for p in sorted(BRAND.glob("*.*"))))
    print("sheet:", SHEET)


if __name__ == "__main__":
    main()
