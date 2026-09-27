"""Apply curated record-field overrides to raw builder output."""
from __future__ import annotations


def apply_overrides(records: list[dict], overlay: dict) -> None:
    if not isinstance(overlay, dict) or overlay.get("version") != 1:
        raise ValueError("question-bank overrides must have version 1")
    changes = overlay.get("records")
    if not isinstance(changes, dict):
        raise ValueError("question-bank overrides must contain a records object")

    by_id: dict[str, dict] = {}
    for record in records:
        if not isinstance(record, dict) or not isinstance(record.get("id"), str):
            raise ValueError("builder records must be objects with string IDs")
        record_id = record["id"]
        if record_id in by_id:
            raise ValueError(f"duplicate builder record ID: {record_id}")
        by_id[record_id] = record

    unknown = set(changes) - set(by_id)
    if unknown:
        raise ValueError(f"overrides reference unknown record IDs: {sorted(unknown)}")

    for record_id, fields in changes.items():
        if not isinstance(fields, dict):
            raise ValueError(f"overrides for {record_id} must be an object")
        if "id" in fields:
            raise ValueError(f"overrides may not change record ID: {record_id}")
        by_id[record_id].update(fields)
