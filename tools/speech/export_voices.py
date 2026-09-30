"""Rebuild voices.json: the curated US-English Edge neural voices for the picker.

Ranking (best first):
  natural  - Microsoft's conversational "Copilot" personas (Andrew, Ava, Brian,
             Emma): the most human-sounding voices the free Edge endpoint offers.
  general  - all-purpose assistant voices (Jenny).
  classic  - older news/narration voices; clear but more "announcer".
Skipped: Multilingual variants (they flip to French on inch marks and curly
quotes, see speak_question.py) and cartoon/child voices.
The row marked "default": true is the app's starting voice and the voice of the
recorded clips (VoiceCatalog, speak_question.py); a rebuild keeps the mark on the
same voice id.

EXTRA_VOICES adds hand-picked non-US voices with a fixed label and tier. Ryan
is the closest free match to luvvoice's "Dylan Marlow - Gentle Trust" (a
proprietary cloned voice): calm British male, same pitch range.
"""

import asyncio
import json
from pathlib import Path

import edge_tts

TIER_ORDER = {"natural": 0, "general": 1, "classic": 2}
TRAIT_WORDING = {"Passion": "Passionate", "Authority": "Authoritative"}
EXTRA_VOICES = {
    "en-GB-RyanNeural": ("Ryan · Male · Calm British narrator", "natural"),
}


def tier_of(voice: dict) -> str:
    cats = voice.get("VoiceTag", {}).get("ContentCategories", [])
    if "Copilot" in cats:
        return "natural"
    if "General" in cats:
        return "general"
    return "classic"


def skip(voice: dict) -> bool:
    cats = voice.get("VoiceTag", {}).get("ContentCategories", [])
    return "Multilingual" in voice["ShortName"] or "Cartoon" in cats


async def main() -> None:
    rows = []
    for voice in await edge_tts.list_voices():
        short = voice["ShortName"]
        # gender and locale let the mobile picker list the en-US voices by gender.
        meta = {"locale": voice["Locale"], "gender": voice["Gender"]}
        if short in EXTRA_VOICES:
            label, tier = EXTRA_VOICES[short]
            rows.append({"label": label, "id": short, "tier": tier, **meta})
            continue
        if voice["Locale"] != "en-US" or skip(voice):
            continue
        name = short.split("-")[-1].replace("Neural", "")
        traits = voice.get("VoiceTag", {}).get("VoicePersonalities", [])
        trait = TRAIT_WORDING.get(traits[0], traits[0]) if traits else ""
        label = "%s · %s" % (name, voice["Gender"])
        if trait:
            label += " · " + trait
        rows.append({"label": label, "id": short, "tier": tier_of(voice), **meta})
    rows.sort(key=lambda row: (TIER_ORDER[row["tier"]], row["label"]))
    path = Path(__file__).resolve().parents[2] / "data" / "voices.json"
    old = json.loads(path.read_text(encoding="utf-8")) if path.exists() else []
    default_ids = {row["id"] for row in old if row.get("default")}
    for row in rows:
        if row["id"] in default_ids:
            row["default"] = True
    path.write_text(json.dumps(rows, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(len(rows))


if __name__ == "__main__":
    asyncio.run(main())
