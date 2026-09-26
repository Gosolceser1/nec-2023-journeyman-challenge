"""One-time batch generator: pre-synthesize every question's voice clips.

Reads speech plans from the Godot user folder (written by tools/dump_speech.gd),
then records the Edge neural voice for each question into
    <user>\\speech\\<question-id>__<voice>\\
The game plays those local files first and only synthesizes live when a question
changed or the voice was switched, so practice works offline after this run.

Usage:
    python tools\\dump_first (Godot step below), then:
    python tools\\pregenerate_speech.py [--voice VOICE] [--limit N] [--force]

Godot step (run from the project folder):
    Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tools/dump_speech.gd
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from speak_question import DEFAULT_VOICE, synthesize

ROOT = Path(__file__).resolve().parents[1]


def app_name() -> str:
    text = (ROOT / "project.godot").read_text(encoding="utf-8")
    match = re.search(r'config/name="([^"]+)"', text)
    return match.group(1) if match else "app"


def user_dir() -> Path:
    base = os.environ.get("APPDATA") or str(Path.home() / "AppData" / "Roaming")
    return Path(base) / "Godot" / "app_userdata" / app_name()


def saved_voice(userdata: Path) -> str:
    cfg = userdata / "voice.cfg"
    if not cfg.exists():
        return DEFAULT_VOICE
    match = re.search(r'^voice\s*=\s*"([^"]+)"', cfg.read_text(encoding="utf-8"), re.M)
    return match.group(1) if match else DEFAULT_VOICE


def plan_key(plan: dict) -> list:
    return [
        (str(s.get("text", "")).strip(), int(s.get("choice", -1)), bool(s.get("teach", False)))
        for s in plan.get("segments", [])
        if str(s.get("text", "")).strip() != ""
    ]


def manifest_key(folder: Path) -> list | None:
    manifest_path = folder / "manifest.json"
    if not manifest_path.exists():
        return None
    try:
        rows = json.loads(manifest_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return None
    if not isinstance(rows, list) or not rows:
        return None
    keys = []
    for row in rows:
        clip = folder / str(row.get("file", ""))
        if not clip.exists() or clip.stat().st_size == 0:
            return None
        keys.append((str(row.get("text", "")), int(row.get("choice", -1)), bool(row.get("teach", False))))
    return keys


def main() -> None:
    args_parser = argparse.ArgumentParser()
    args_parser.add_argument("--voice", default="")
    args_parser.add_argument("--limit", type=int, default=0)
    args_parser.add_argument("--force", action="store_true")
    args = args_parser.parse_args()

    userdata = user_dir()
    voice = args.voice or saved_voice(userdata)
    src = userdata / "speech_src"
    if not src.exists():
        raise SystemExit("speech plans not found. Run the Godot dump step first (see module docstring).")
    plans = sorted(src.glob("*.json"))
    if args.limit > 0:
        plans = plans[: args.limit]
    print("voice:", voice)
    print("questions:", len(plans))

    done, skipped, failed = 0, 0, 0
    for index, plan_path in enumerate(plans, start=1):
        plan = json.loads(plan_path.read_text(encoding="utf-8"))
        qid = plan.get("id") or plan_path.stem
        folder = userdata / "speech" / ("%s__%s" % (plan_path.stem, voice))
        wanted = plan_key(plan)
        if not wanted:
            print("[%d/%d] %s: empty plan, skipped" % (index, len(plans), qid))
            skipped += 1
            continue
        if not args.force and manifest_key(folder) == wanted:
            skipped += 1
            continue
        try:
            synthesize(plan["segments"], folder, voice)
            done += 1
            print("[%d/%d] %s: %d clips" % (index, len(plans), qid, len(wanted)))
        except Exception as exc:  # keep going; resume later with --force or re-run
            failed += 1
            print("[%d/%d] %s: FAILED %s" % (index, len(plans), qid, exc))
    print("done: %d | already cached: %d | failed: %d" % (done, skipped, failed))


if __name__ == "__main__":
    main()
