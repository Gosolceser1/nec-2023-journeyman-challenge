#!/usr/bin/env python3
"""Refresh the curated field overlay from a raw builder baseline and bank."""
from __future__ import annotations

import argparse
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("baseline", type=Path, help="raw builder output (built with overrides skipped)")
    parser.add_argument("--bank", type=Path, default=ROOT / "data" / "question_bank.json")
    parser.add_argument("--output", type=Path, default=ROOT / "tools" / "pipeline" / "question_bank_overrides.json")
    args = parser.parse_args()

    baseline = json.loads(args.baseline.read_text(encoding="utf-8"))
    curated = json.loads(args.bank.read_text(encoding="utf-8"))
    if set(baseline) != set(curated):
        raise SystemExit("top-level schema differs; refusing to build a field-only overlay")
    raw_records = baseline.get("records")
    curated_records = curated.get("records")
    if not isinstance(raw_records, list) or not isinstance(curated_records, list):
        raise SystemExit("both banks must contain a records array")
    if [r.get("id") for r in raw_records] != [r.get("id") for r in curated_records]:
        raise SystemExit("record IDs/order differ; refusing to build an incomplete overlay")

    patches: dict[str, dict] = {}
    field_count = 0
    for raw, final in zip(raw_records, curated_records):
        removed = set(raw) - set(final)
        if removed:
            raise SystemExit(f"{raw.get('id')}: field deletion not supported: {sorted(removed)}")
        changes = {key: value for key, value in final.items() if raw.get(key) != value}
        if changes:
            patches[final["id"]] = changes
            field_count += len(changes)

    overlay = {"version": 1, "records": patches}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(overlay, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {len(patches)} record overrides / {field_count} field overrides to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
