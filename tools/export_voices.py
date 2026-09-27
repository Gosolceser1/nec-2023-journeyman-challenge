"""Rebuild voices.json: the curated US-English Edge neural voices for the picker.

Ranking (best first):
  natural  - Microsoft's conversational "Copilot" personas (Andrew, Ava, Brian,
             Emma): the most human-sounding voices the free Edge endpoint offers.
  general  - all-purpose assistant voices (Jenny).
  classic  - older news/narration voices; clear but more "announcer".
Skipped: Multilingual variants (they flip to French on inch marks and curly
quotes, see speak_question.py) and cartoon/child voices.
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
        if short in EXTRA_VOICES:
            label, tier = EXTRA_VOICES[short]
            rows.append({"label": label, "id": short, "tier": tier})
            continue
        if voice["Locale"] != "en-US" or skip(voice):
            continue
        name = short.split("-")[-1].replace("Neural", "")
        traits = voice.get("VoiceTag", {}).get("VoicePersonalities", [])
        trait = TRAIT_WORDING.get(traits[0], traits[0]) if traits else ""
        label = "%s · %s" % (name, voice["Gender"])
        if trait:
            label += " · " + trait
        rows.append({"label": label, "id": short, "tier": tier_of(voice)})
    rows.sort(key=lambda row: (TIER_ORDER[row["tier"]], row["label"]))
    path = Path(__file__).resolve().parents[1] / "voices.json"
    path.write_text(json.dumps(rows, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(len(rows))


if __name__ == "__main__":
    asyncio.run(main())
