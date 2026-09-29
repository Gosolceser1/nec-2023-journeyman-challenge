"""Nebraska State Electrical Act / Board Rules questions from curated JSON sources.

These questions do not come from the OCR'd exam PDFs. Each quiz is two files in
tools/pipeline/sources/:

  <name>.json       the quiz sheet word for word: exam label, section and the
                    stems and choices, nothing else
  <name>_keys.json  per question: correct_index, citation, quoted law text and
                    the explanation fields (plus reviewer-only "evidence")

The records carry "section" (e.g. "ne_state_law") so the app keeps them out of
the NEC drills and the simulator. The NEC records have no such field.
"""
from __future__ import annotations

import json
from pathlib import Path

SOURCES_DIR = Path(__file__).resolve().parent / "sources"
LETTERS = ["A", "B", "C", "D", "E", "F"]
KEY_FIELDS = [
    "correct_index", "article", "article_title", "keywords",
    "lookup_summary", "gist", "info_tip", "reference_text", "tip_title", "tip",
    "choice_notes",
]


def _tip_short(tip: str, answers: list[str], correct: int, notes: list[str]) -> str:
    parts = [f"{tip} Correct: {LETTERS[correct]} — {answers[correct]}. {notes[correct]}"]
    for i, note in enumerate(notes):
        if i != correct:
            parts.append(f"Not {LETTERS[i]}: {note}")
    return " ".join(parts)


def _slug(exam: str) -> str:
    return exam.lower().replace(" ", "-")


def load_quiz(question_path: Path) -> tuple[list[dict], list[dict]]:
    """Returns (records, manifest entries) for one quiz."""
    quiz = json.loads(question_path.read_text(encoding="utf-8"))
    keys_path = question_path.with_name(question_path.stem + "_keys.json")
    keys = json.loads(keys_path.read_text(encoding="utf-8"))
    if quiz.get("version") != 1 or keys.get("version") != 1:
        raise ValueError(f"{question_path.name}: source files must have version 1")
    if keys.get("questions_file") != question_path.name:
        raise ValueError(f"{keys_path.name}: questions_file does not name {question_path.name}")
    exam, section = quiz["exam"], quiz["section"]
    numbers = [q["number"] for q in quiz["questions"]]
    if sorted(map(int, keys["keys"])) != sorted(numbers):
        raise ValueError(f"{keys_path.name}: keys do not match the question numbers {numbers}")

    records, manifest = [], []
    for q in quiz["questions"]:
        key = keys["keys"][str(q["number"])]
        missing = [f for f in KEY_FIELDS if f not in key]
        if missing:
            raise ValueError(f"{keys_path.name} #{q['number']}: missing {missing}")
        answers, correct = q["answers"], key["correct_index"]
        if len(key["choice_notes"]) != len(answers) or not 0 <= correct < len(answers):
            raise ValueError(f"{keys_path.name} #{q['number']}: choice_notes or correct_index do not fit the choices")
        records.append({
            "id": "%s-%03d" % (_slug(exam), q["number"]),
            "exam": exam,
            "question_number": q["number"],
            "prompt": q["prompt"],
            "answers": answers,
            "gist": key["gist"],
            "scene": "",
            "correct_index": correct,
            "article": key["article"],
            "article_title": key["article_title"],
            "keywords": key["keywords"],
            "lookup_summary": key["lookup_summary"],
            "info_tip": key["info_tip"],
            "reference_text": key["reference_text"],
            "reference_table": [],
            "tip_title": key["tip_title"],
            "tip_short": _tip_short(key["tip"], answers, correct, key["choice_notes"]),
            "formula": key.get("formula", ""),
            "worked": key.get("worked", ""),
            "choice_notes": key["choice_notes"],
            "available": True,
            "section": section,
        })
        manifest.append({"source": exam, "number": q["number"], "available": True})
    return records, manifest


def load_all(sources_dir: Path = SOURCES_DIR) -> tuple[list[dict], list[dict]]:
    records, manifest = [], []
    for path in sorted(sources_dir.glob("*.json")):
        if path.stem.endswith("_keys"):
            continue
        quiz_records, quiz_manifest = load_quiz(path)
        records.extend(quiz_records)
        manifest.extend(quiz_manifest)
    return records, manifest
