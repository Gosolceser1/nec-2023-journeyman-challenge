"""Write the app's name into project.godot and export_presets.cfg from data/app.json.

    python tools/release/sync_identity.py          rewrite what differs (idempotent)
    python tools/release/sync_identity.py --check  exit 1 if a file disagrees

Visible names are templates in data/app.json filled from data/edition.json
({year}, {short}) and project.godot's config/version ({version}):
  project.godot       config/name, config/description
  export_presets.cfg  each preset's export_path (data/app.json "exports", by preset
                      name), Windows product_name / file_description / company_name,
                      Android package/name

The save folder (config/custom_user_dir_name) and the Android package id
(package/unique_name) are FROZEN: this script only checks them against
data/app.json and never writes them. A new folder name would leave existing
installs without their progress; a new package id would install a second app
instead of upgrading the old one.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def project_version(root: Path = ROOT) -> str:
    text = (root / "project.godot").read_text(encoding="utf-8")
    m = re.search(r'^config/version="([^"]*)"', text, re.M)
    if not m:
        sys.exit("project.godot has no application/config/version")
    return m.group(1)


def identity(root: Path = ROOT) -> dict:
    """data/app.json with every template filled in, plus edition and version."""
    app = json.loads((root / "data" / "app.json").read_text(encoding="utf-8"))
    edition = json.loads((root / "data" / "edition.json").read_text(encoding="utf-8"))
    fields = {"year": edition["year"], "short": edition["short"], "version": project_version(root)}
    out = dict(app)
    for key in ("display_name", "description", "file_stem"):
        out[key] = app[key].format(**fields)
    fields.update(display_name=out["display_name"], file_stem=out["file_stem"])
    out["exports"] = {name: path.format(**fields) for name, path in app.get("exports", {}).items()}
    out["edition"] = edition
    out["version"] = fields["version"]
    return out


def expected(ident: dict, presets_text: str) -> list[tuple[str, str, str, str, bool]]:
    """(file, section, key, value, frozen) for every managed setting."""
    name = ident["display_name"]
    rows = [
        ("project.godot", "application", "config/name", name, False),
        ("project.godot", "application", "config/description", ident["description"], False),
        ("project.godot", "application", "config/custom_user_dir_name", ident["user_dir"], True),
    ]
    for section, preset, platform in presets(presets_text):
        if preset in ident["exports"]:
            rows.append(("export_presets.cfg", section, "export_path", ident["exports"][preset], False))
        opts = section + ".options"
        if platform == "Windows Desktop":
            rows.append(("export_presets.cfg", opts, "application/product_name", name, False))
            rows.append(("export_presets.cfg", opts, "application/file_description", name, False))
            rows.append(("export_presets.cfg", opts, "application/company_name", ident["company"], False))
        elif platform == "Android":
            rows.append(("export_presets.cfg", opts, "package/name", name, False))
            rows.append(("export_presets.cfg", opts, "package/unique_name", ident["android_package"], True))
    return rows


def presets(text: str) -> list[tuple[str, str, str]]:
    """(section, name, platform) of every [preset.N]."""
    out = []
    for m in re.finditer(r"^\[(preset\.\d+)\]\r?$", text, re.M):
        section = m.group(1)
        out.append((section, get_value(text, section, "name") or "", get_value(text, section, "platform") or ""))
    return out


def _section_span(text: str, section: str) -> tuple[int, int] | None:
    m = re.search(r"^\[" + re.escape(section) + r"\]\r?$", text, re.M)
    if not m:
        return None
    nxt = re.search(r"^\[", text[m.end():], re.M)
    return m.end(), m.end() + nxt.start() if nxt else len(text)


def _key_re(key: str) -> re.Pattern:
    return re.compile(r'^' + re.escape(key) + r'="((?:[^"\\]|\\.)*)"\r?$', re.M)


def get_value(text: str, section: str, key: str) -> str | None:
    span = _section_span(text, section)
    if span is None:
        return None
    m = _key_re(key).search(text, span[0], span[1])
    return m.group(1).replace('\\"', '"') if m else None


def set_value(text: str, section: str, key: str, value: str) -> str:
    span = _section_span(text, section)
    if span is None:
        raise KeyError(f"no [{section}]")
    m = _key_re(key).search(text, span[0], span[1])
    if not m:
        raise KeyError(f"no {key} in [{section}]")
    quoted = value.replace('"', '\\"')
    return text[:m.start(1)] + quoted + text[m.end(1):]


def sync(root: Path = ROOT, check: bool = False) -> list[str]:
    """Problems (check) or changes made; frozen mismatches are always problems."""
    ident = identity(root)
    files = {n: (root / n).read_bytes().decode("utf-8") for n in ("project.godot", "export_presets.cfg")}
    report = []
    for file, section, key, value, frozen in expected(ident, files["export_presets.cfg"]):
        have = get_value(files[file], section, key)
        if have == value:
            continue
        if frozen:
            report.append(f"FROZEN {file} [{section}] {key} is {have!r}, data/app.json says {value!r}: "
                          "never change it (existing installs would lose progress / not upgrade)")
            continue
        report.append(f"{file} [{section}] {key}: {have!r} -> {value!r}")
        if have is None:
            report[-1] = f"MISSING {file} [{section}] {key} (expected {value!r})"
            continue
        files[file] = set_value(files[file], section, key, value)
    if not check:
        for name, text in files.items():
            path = root / name
            if path.read_bytes().decode("utf-8") != text:
                path.write_bytes(text.encode("utf-8"))
    return report


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--check", action="store_true", help="report differences, change nothing")
    args = ap.parse_args()
    report = sync(check=args.check)
    for line in report:
        print(line)
    bad = [r for r in report if args.check or r.startswith(("FROZEN", "MISSING"))]
    if not report:
        print("identity: project.godot and export_presets.cfg match data/app.json")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
