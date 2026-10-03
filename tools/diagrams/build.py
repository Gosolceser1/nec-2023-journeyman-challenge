"""Build the original study figures and their masks.

    python tools/diagrams/build.py            # write SVG, PNG, figures.json, masks, labels
    python tools/diagrams/build.py --check    # verify the committed outputs are current (no writes)
    python tools/diagrams/build.py --only NAME[,NAME]  # draw only these (still validates all)

Figures are drawn by the modules in tools/diagrams/figs/ (one visual system:
tools/diagrams/nec_style.py). Outputs:

  docs/diagrams/svg/<name>.svg          the drawing (review copy; not shipped)
  assets/diagrams/nec/<name>.png        1.5x render, palette-compressed (shipped)
  assets/diagrams/nec/figures.json      record id -> figure (file, when, size, nec)
  data/diagram_masks.json  "records"    record id -> leaks + '?' masks
  docs/diagrams/labels.json             every label's text and box (leak scan input)

The build fails if a wired record has no figure, a record sits in two
figures, or any label shows a record's answer outside that record's masks
(tools/diagrams/leakscan.py).
"""
import argparse
import datetime
import hashlib
import importlib
import io
import json
import pkgutil
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "diagrams"))

import leakscan  # noqa: E402
import nec_style  # noqa: E402
from records import NEED  # noqa: E402

SVG_DIR = ROOT / "docs" / "diagrams" / "svg"
PNG_DIR = ROOT / "assets" / "diagrams" / "nec"
FIG_MAP = PNG_DIR / "figures.json"
MASKS = ROOT / "data" / "diagram_masks.json"
LABELS = ROOT / "docs" / "diagrams" / "labels.json"
BANK = ROOT / "data" / "question_bank.json"
SCALE = 1.5
PALETTE = 96

# Tiers wired into the app (the rest are drawn but not shipped). R = the
# questions that cannot be answered without their figure.
WIRED_TIERS = "RABC"


def load_figs(modules=None):
    import figs
    for m in pkgutil.iter_modules(figs.__path__):
        if modules is None or m.name in modules:
            importlib.import_module(f"figs.{m.name}")
    return nec_style.FIGURES


def wired(rid):
    return rid in NEED and NEED[rid][0] in WIRED_TIERS


def _r(v):
    return round(v, 4)


def draw_all(modules=None, every_tier=False, bank=None):
    """name -> {"fig": Fig, "records": {id: opts}, ...} for figures serving wired records.

    With `bank`, every pre-answer record also gets the strict masks (strict_masks)."""
    out = {}
    for name, spec in sorted(load_figs(modules).items()):
        recs = {r: o for r, o in spec["records"].items() if every_tier or wired(r)}
        if not recs:
            continue
        f = nec_style.Fig(spec["h"])
        spec["fn"](f)
        recs = {r: _like(name, spec, f, r, o) for r, o in recs.items()}
        out[name] = dict(spec, fig=f, records=recs)
        if bank is not None:
            strict_masks(out[name], bank)
    return out


def strict_hits_for(d, rid, bank):
    """[(label, reasons)] the record may not see before answering (leakscan strict rule)."""
    f = d["fig"]
    sib = [bank[r] for r in d["records"] if r != rid and r in bank]
    terms = list(d["terms"].get(rid, [])) + list(d["records"][rid].get("terms", []))
    given, vals, phrases = leakscan.strict_keys(bank[rid], sib, terms)
    keep = [re.compile(k, re.I) for k in d.get("keep", ())]
    out = []
    for lab in f.labels:
        text = lab[0]
        if any(k.search(text) for k in keep):
            hit = [f"section reference '{r}'" for r in leakscan.location_refs(text)]
        else:
            hit = leakscan.strict_hits(text, given, vals, phrases)
        if hit:
            out.append((lab, hit))
    return out


def strict_masks(d, bank):
    """Mask, per pre-answer record, every label that states a rule value the stem
    does not give, any answer choice of any question on the figure, or a section,
    table or Part number. A whole multi-row note is masked before its rows, so
    one badge covers it instead of a stack of overlapping ones."""
    f = d["fig"]
    for rid, opts in d["records"].items():
        if rid not in bank or opts.get("when", d["when"]) != "before":
            continue
        own = [m for m in f.masks if m.get("records") is None or rid in m["records"]]
        hits = sorted(strict_hits_for(d, rid, bank), key=lambda lh: -lh[0][3] * lh[0][4])
        for (text, x, y, w, h), hit in hits:
            if leakscan.covered([x, y, w, h], [m for m in own]):
                continue
            m = f.mask(x - 6, y - 5, w + 12, h + 10, ring=False, records=[rid], what=f"'{text}' ({hit[0]})")
            own.append(m)


def _like(name, spec, f, rid, opts):
    """{"like": other}: a repeat of another record on the same figure gets its
    masks, highlight, answer terms and timing (its own options still win)."""
    src = opts.get("like")
    if not src:
        return opts
    assert src in spec["records"], f"{name}: {rid} is like {src}, which the figure does not serve"
    base = spec["records"][src]
    for m in f.masks + f.highlights:
        if m.get("records") is not None and src in m["records"]:
            m["records"].append(rid)
    out = dict(opts)
    out.setdefault("when", base.get("when", spec["when"]))
    out["terms"] = list(spec["terms"].get(src, [])) + list(base.get("terms", [])) + list(opts.get("terms", []))
    return out


def record_masks(f, rid):
    ms = []
    for m in f.masks:
        if m.get("records") is None or rid in m["records"]:
            x, y, w, h = m["rect"]
            e = {"rect": [_r(x / f.w), _r(y / f.h), _r(w / f.w), _r(h / f.h)]}
            if "label" in m:
                e["label"] = m["label"]
            if m.get("ring"):
                e["ring"] = True
            ms.append((e, m.get("what", "answer value")))
    return ms


def record_highlight(f, rid):
    for hl in f.highlights:
        if hl["records"] is None or rid in hl["records"]:
            x, y, w, h = hl["rect"]
            return [_r(x / f.w), _r(y / f.h), _r(w / f.w), _r(h / f.h)]
    return None


def unit_labels(f):
    return [[t, _r(x / f.w), _r(y / f.h), _r(w / f.w), _r(h / f.h)] for t, x, y, w, h in f.labels]


def validate(drawn, bank, check_missing=True):
    errors = []
    seen = {}
    for name, d in drawn.items():
        f = d["fig"]
        for m in f.masks:
            for r in m.get("records") or []:
                if r not in d["records"] and (wired(r) or not check_missing):
                    errors.append(f"{name}: mask names {r}, which the figure does not serve")
        for t, x, y, w, h in f.labels:
            if x < -1 or y < -1 or x + w > f.w + 1 or y + h > f.h + 1:
                errors.append(f"{name}: label {t!r} runs off the canvas ({x:.0f},{y:.0f},{w:.0f},{h:.0f})")
        for rid, opts in d["records"].items():
            if rid in seen:
                errors.append(f"{rid}: in two figures ({seen[rid]}, {name})")
            seen[rid] = name
            if rid not in bank:
                errors.append(f"{name}: {rid} is not a bank record")
                continue
            when = opts.get("when", d["when"])
            if when not in ("before", "after"):
                errors.append(f"{name}: {rid} has when={when!r}")
            if when == "before":
                masks = [m for m, _ in record_masks(f, rid)]
                terms = list(d["terms"].get(rid, [])) + list(opts.get("terms", []))
                for text, hit in leakscan.leaks(bank[rid], unit_labels(f), masks, terms):
                    errors.append(f"{name}: {rid} shows its answer in {text!r} ({', '.join(hit)}) with no mask")
                own = [m for m in f.masks if m.get("records") is None or rid in m["records"]]
                for (text, x, y, w, h), hit in strict_hits_for(d, rid, bank):
                    if not leakscan.covered([x, y, w, h], own):
                        errors.append(f"{name}: {rid} shows {text!r} before answering ({', '.join(hit)})")
    for rid in NEED:
        if check_missing and wired(rid) and rid not in seen:
            errors.append(f"{rid}: wired tier {NEED[rid][0]} but no figure draws it")
    for rid in seen:
        if rid not in NEED:
            errors.append(f"{rid}: drawn, but not one of the audit's figure records (tools/diagrams/records.py)")
    return errors


def scratch(modules, out_dir, bank):
    """Draw only `modules` into out_dir (SVG, PNG, per-record preview); touch nothing shared."""
    import preview
    from PIL import Image
    drawn = draw_all(modules, every_tier=True, bank=bank)
    errors = validate(drawn, bank, check_missing=False)
    out_dir.mkdir(parents=True, exist_ok=True)
    for name, d in drawn.items():
        f = d["fig"]
        svg = f.svg()
        (out_dir / f"{name}.svg").write_text(svg, encoding="ascii")
        png = out_dir / f"{name}.png"
        render_png(svg, png)
        img = Image.open(png)
        w, h = img.size
        rows = sorted(d["records"])
        sheet = Image.new("RGB", (w * 2 + 30, (h + 40) * len(rows) + 10), (2, 6, 23))
        from PIL import ImageDraw
        dr = ImageDraw.Draw(sheet)
        hf = preview.font(22)
        for i, rid in enumerate(rows):
            when = d["records"][rid].get("when", d["when"])
            ms = [m for m, _ in record_masks(f, rid)]
            y = 10 + i * (h + 40)
            dr.text((10, y), f"{rid}  ({when})  BEFORE", font=hf, fill=preview.HEAD)
            dr.text((w + 20, y), "AFTER", font=hf, fill=preview.HEAD)
            if when == "before":
                sheet.paste(preview.draw_state(img, ms, False, SCALE), (10, y + 30))
            else:
                dr.text((20, y + 60), "(not shown before answering)", font=hf, fill=preview.HEAD)
            sheet.paste(preview.draw_state(img, ms, True, SCALE, record_highlight(f, rid)), (w + 20, y + 30))
        sheet.save(out_dir / f"{name}_preview.png")
        print(out_dir / f"{name}_preview.png", f"{png.stat().st_size / 1024:.0f} KiB")
    for e in errors:
        print("ERROR:", e)
    print(f"{len(drawn)} figure(s), {sum(len(d['records']) for d in drawn.values())} record(s), {len(errors)} problem(s)")
    return 1 if errors else 0


def render_png(svg_text, path):
    import pymupdf
    from PIL import Image
    doc = pymupdf.open(stream=svg_text.encode("ascii"), filetype="svg")
    pix = doc[0].get_pixmap(matrix=pymupdf.Matrix(SCALE, SCALE), alpha=False)
    img = Image.open(io.BytesIO(pix.tobytes("png"))).convert("RGB")
    q = img.quantize(colors=PALETTE, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    q.save(path, optimize=True)


def outputs(drawn, bank, old_map):
    fig_map, rec_masks, labels = {}, {}, {}
    today = datetime.date.today().isoformat()
    old_masks = {}
    if MASKS.exists():
        old_masks = json.loads(MASKS.read_text(encoding="utf-8")).get("records", {})
    for name, d in drawn.items():
        f = d["fig"]
        svg = f.svg()
        sha = hashlib.sha1(svg.encode("ascii")).hexdigest()[:12]
        labels[f"{name}.png"] = unit_labels(f)
        for rid, opts in sorted(d["records"].items()):
            when = opts.get("when", d["when"])
            fig_map[rid] = {"file": f"res://assets/diagrams/nec/{name}.png", "figure": name,
                            "source": "original", "style": "dark", "when": when,
                            "size": [int(f.w * SCALE), int(f.h * SCALE)], "nec": d["nec"], "svg_sha1": sha}
            hl = record_highlight(f, rid)
            if hl is not None:
                fig_map[rid]["highlight"] = hl
            ms = record_masks(f, rid) if when == "before" else []
            entry = {"file": f"{name}.png", "when": when,
                     "leaks": [{"region": m["rect"], "what": what} for m, what in ms],
                     "masks": [m for m, _ in ms]}
            terms = list(d["terms"].get(rid, [])) + list(opts.get("terms", []))
            if terms:
                entry["terms"] = terms
            prev = old_masks.get(rid, {})
            same = {k: prev[k] for k in prev if k != "reviewed"} == entry
            entry["reviewed"] = prev.get("reviewed", today) if same else today
            rec_masks[rid] = entry
    return fig_map, rec_masks, labels


def dump(obj):
    return json.dumps(obj, indent=1, ensure_ascii=True) + "\n"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--only", default="")
    ap.add_argument("--force-png", action="store_true")
    ap.add_argument("--scratch", default="", help="with --modules: draw only those modules into this dir")
    ap.add_argument("--modules", default="", help="figs module names, comma-separated")
    args = ap.parse_args()
    bank = {r["id"]: r for r in json.loads(BANK.read_text(encoding="utf-8"))["records"]}
    if args.scratch:
        mods = set(filter(None, args.modules.split(",")))
        if not mods:
            ap.error("--scratch needs --modules")
        return scratch(mods, Path(args.scratch), bank)
    drawn = draw_all(bank=bank)
    errors = validate(drawn, bank)
    old_map = json.loads(FIG_MAP.read_text(encoding="utf-8")) if FIG_MAP.exists() else {}
    fig_map, rec_masks, labels = outputs(drawn, bank, old_map)
    masks_doc = json.loads(MASKS.read_text(encoding="utf-8"))
    masks_doc["records"] = dict(sorted(rec_masks.items()))
    if args.check:
        stale = []
        for name, d in drawn.items():
            p = SVG_DIR / f"{name}.svg"
            if not p.exists() or p.read_text(encoding="ascii") != d["fig"].svg():
                stale.append(str(p.relative_to(ROOT)))
            if not (PNG_DIR / f"{name}.png").exists():
                stale.append(f"assets/diagrams/nec/{name}.png (missing)")
        strip = lambda m: {k: {kk: vv for kk, vv in v.items() if kk != "reviewed"} for k, v in m.items()}
        on_disk = json.loads(MASKS.read_text(encoding="utf-8")).get("records", {})
        if strip(on_disk) != strip(masks_doc["records"]):
            stale.append("data/diagram_masks.json records")
        if old_map != fig_map:
            stale.append("assets/diagrams/nec/figures.json")
        if not LABELS.exists() or json.loads(LABELS.read_text(encoding="utf-8")) != labels:
            stale.append("docs/diagrams/labels.json")
        for s in stale:
            errors.append(f"stale output: {s} (run tools/diagrams/build.py)")
        for e in errors:
            print("ERROR:", e)
        print(f"{len(drawn)} figures, {len(fig_map)} records, {len(errors)} problem(s)")
        return 1 if errors else 0
    for e in errors:
        print("ERROR:", e)
    SVG_DIR.mkdir(parents=True, exist_ok=True)
    PNG_DIR.mkdir(parents=True, exist_ok=True)
    only = set(filter(None, args.only.split(",")))
    keep = {f"{n}.png" for n in drawn}
    for p in PNG_DIR.glob("*.png"):
        if p.name not in keep:
            p.unlink()
            imp = p.with_name(p.name + ".import")
            if imp.exists():
                imp.unlink()
    for p in SVG_DIR.glob("*.svg"):
        if f"{p.stem}.png" not in keep:
            p.unlink()
    for name, d in drawn.items():
        svg = d["fig"].svg()
        sp = SVG_DIR / f"{name}.svg"
        changed = not sp.exists() or sp.read_text(encoding="ascii") != svg
        sp.write_text(svg, encoding="ascii")
        png = PNG_DIR / f"{name}.png"
        if (changed or args.force_png or not png.exists()) and (not only or name in only):
            render_png(svg, png)
    FIG_MAP.write_text(dump(dict(sorted(fig_map.items()))), encoding="ascii")
    MASKS.write_text(json.dumps(masks_doc, indent=2, ensure_ascii=True) + "\n", encoding="ascii")
    LABELS.write_text(dump(labels), encoding="ascii")
    total = sum(p.stat().st_size for p in PNG_DIR.glob("*.png"))
    print(f"{len(drawn)} figures, {len(fig_map)} records, PNG total {total / 1024:.0f} KiB, {len(errors)} problem(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
