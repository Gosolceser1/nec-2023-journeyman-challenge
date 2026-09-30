#!/usr/bin/env python3
"""List the question-bank records to re-audit when switching NEC editions.

Compares the current edition's data (data/edition.json -> data/nec/<year>/)
with a target edition folder and reports, per NEC record:

* its cited article is missing from the target articles.json, or was retitled;
* its citation or explanation text matches a section the target edition
  renumbered (target renumbered.json), with the new home and any exam-area change
  (data/exam_blueprint.json assigns areas by NEC chapter);
* it cites a table or code value whose numbers differ in the target tables.json;
* it has no entry in the target content_audit.json yet.

Nothing is written to the bank. A dry run against the current edition
(``--to <current year>``) must report no records.

Usage:
    python tools/pipeline/edition_migration_report.py --to 2026 [--bank data/question_bank.json] [--out report.md]
See docs/EDITION_MIGRATION.md.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pipeline_paths import ROOT, edition  # noqa: E402

BLUEPRINT_PATH = ROOT / "data" / "exam_blueprint.json"
REQUIREMENTS_PATH = ROOT / "data" / "question_requirements.json"
TEXT_FIELDS = ["article", "reference_text", "formula", "worked", "info_tip", "tip_short", "lookup_summary"]
PRIMARY_ARTICLE_RE = re.compile(r"^(?:NEC\s+)?(?:Table\s+|Article\s+)?(\d{2,3})(?:\.\d|\b)")
CHAPTER_WORD_RE = re.compile(r"(?i)\bchapter\s+(\d)\b")
ARTICLE_NUMBER_RE = re.compile(r"\b([1-9])\d\d\b")


def _read(path: Path):
    return json.loads(path.read_text(encoding="utf-8")) if path.exists() else None


def load_edition(folder: Path) -> dict:
    """The edition files the report compares; only articles.json is required."""
    articles = _read(folder / "articles.json")
    if articles is None:
        raise FileNotFoundError(f"{folder / 'articles.json'} is missing; create the edition folder first "
                                "(docs/EDITION_MIGRATION.md)")
    renumbered = _read(folder / "renumbered.json") or {"sections": []}
    return {
        "folder": folder,
        "articles": {int(k): v for k, v in articles["articles"].items()},
        "renumbered": [(re.compile(e["pattern"]), e["home"]) for e in renumbered["sections"]],
        "tables": _read(folder / "tables.json") or {"tables": {}, "values": {}},
        "audit": (_read(folder / "content_audit.json") or {}).get("records", {}),
    }


def primary_article(reference: str) -> int | None:
    m = PRIMARY_ARTICLE_RE.match(str(reference).strip())
    return int(m.group(1)) if m else None


def chapter_of(reference: str) -> int:
    """Python twin of ChapterBars.chapter_of for NEC citations (0 = no NEC chapter)."""
    m = CHAPTER_WORD_RE.search(reference)
    if m:
        return int(m.group(1))
    if "70e" in reference.lower():
        return 0
    m = ARTICLE_NUMBER_RE.search(reference)
    return int(m.group(1)) if m else 0


def area_of(record_id: str, reference: str, blueprint: dict) -> str:
    override = blueprint.get("overrides", {}).get(record_id)
    if override:
        return override["area"]
    chapter = chapter_of(reference)
    return next((a["key"] for a in blueprint.get("areas", []) if chapter in a["chapters"]), "")


def changed_tables(current: dict, target: dict) -> list[str]:
    """Citations ("Table 310.16", "220.55") whose rows or values differ between the editions."""
    names = []
    cur_tables, new_tables = current["tables"].get("tables", {}), target["tables"].get("tables", {})
    for tid, table in cur_tables.items():
        if new_tables.get(tid, {}).get("rows") != table.get("rows"):
            names.append(table.get("title", tid))
    cur_values, new_values = current["tables"].get("values", {}), target["tables"].get("values", {})
    for key, value in cur_values.items():
        if new_values.get(key) != value:
            names.append(key.split(".")[0] if not key.startswith("ch9") else "Chapter 9")
    return sorted(set(names))


def record_text(rec: dict, requirement: dict) -> str:
    parts = [str(rec.get(f, "")) for f in TEXT_FIELDS]
    parts += [str(t) for t in requirement.get("tables", [])]
    return "\n".join(parts)


def report(records: list[dict], current: dict, target: dict, blueprint: dict,
           requirements: dict | None = None) -> dict:
    """{record id: [reasons]} for every NEC record that needs a look, plus a summary."""
    requirements = requirements or {}
    tables = changed_tables(current, target)
    # A target renumbered.json may carry the older entries forward; only new ones matter here.
    known = {pattern.pattern for pattern, _ in current["renumbered"]}
    renumbered = [(p, home) for p, home in target["renumbered"] if p.pattern not in known]
    flagged: dict[str, list[str]] = {}
    for rec in records:
        if rec.get("section") is not None:
            continue
        rid, reference = rec["id"], str(rec.get("article", ""))
        reasons = []
        article = primary_article(reference)
        if article is not None and article in current["articles"]:
            if article not in target["articles"]:
                reasons.append(f"Article {article} is not in the target edition")
            elif target["articles"][article] != current["articles"][article]:
                reasons.append(f"Article {article} retitled: {target['articles'][article]!r}")
        text = record_text(rec, requirements.get(rid, {}))
        for pattern, home in renumbered:
            if pattern.search(text):
                reason = f"renumbered: {pattern.pattern} -> {home}"
                if pattern.search(reference):
                    old_area, new_area = area_of(rid, reference, blueprint), area_of(rid, home, blueprint)
                    if old_area != new_area:
                        reason += f" (exam area {old_area} -> {new_area})"
                reasons.append(reason)
        for name in tables:
            if re.search(r"(?<![\w.])" + re.escape(name) + r"(?![\d])", text):
                reasons.append(f"{name} values changed")
        if rid not in target["audit"]:
            reasons.append("no content audit entry for the target edition")
        if reasons:
            flagged[rid] = reasons
    return {"flagged": flagged, "changed_tables": tables,
            "articles_added": sorted(set(target["articles"]) - set(current["articles"])),
            "articles_removed": sorted(set(current["articles"]) - set(target["articles"]))}


def render(result: dict, current_label: str, target_folder: Path, total: int) -> str:
    lines = [f"# Edition migration report: {current_label} -> {target_folder.name}", "",
             f"NEC records to re-audit: {len(result['flagged'])} of {total}", "",
             f"Articles added: {result['articles_added'] or 'none'}",
             f"Articles removed: {result['articles_removed'] or 'none'}",
             f"Tables/values with changed numbers: {result['changed_tables'] or 'none'}", ""]
    for rid, reasons in sorted(result["flagged"].items()):
        lines.append(f"- {rid}: " + "; ".join(reasons))
    return "\n".join(lines) + "\n"


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--to", required=True, help="target edition year (data/nec/<year>/) or a folder path")
    ap.add_argument("--bank", default=str(ROOT / "data" / "question_bank.json"))
    ap.add_argument("--out", help="write the markdown report here (default: stdout)")
    args = ap.parse_args(argv)

    info = edition()
    target_folder = Path(args.to) if not args.to.isdigit() else ROOT / "data" / "nec" / args.to
    current, target = load_edition(ROOT / "data" / info["dir"]), load_edition(target_folder)
    records = json.loads(Path(args.bank).read_text(encoding="utf-8"))["records"]
    requirements = (_read(REQUIREMENTS_PATH) or {}).get("records", {})
    result = report(records, current, target, _read(BLUEPRINT_PATH) or {}, requirements)
    text = render(result, info["short"], target_folder, sum(1 for r in records if r.get("section") is None))
    if args.out:
        Path(args.out).write_text(text, encoding="utf-8")
        print(f"{len(result['flagged'])} records to re-audit -> {args.out}")
    else:
        print(text, end="")
    return 0


if __name__ == "__main__":
    sys.exit(main())
