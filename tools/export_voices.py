import asyncio
import json
from pathlib import Path

import edge_tts


NATIVE = {"en-US", "en-GB", "en-AU", "en-CA", "en-IE", "en-NZ"}
PLACE = {
    "en-US": "US",
    "en-GB": "UK",
    "en-AU": "Australia",
    "en-CA": "Canada",
    "en-IE": "Ireland",
    "en-NZ": "New Zealand",
}


async def main() -> None:
    rows = []
    for voice in await edge_tts.list_voices():
        locale = voice["Locale"]
        if locale not in NATIVE:
            continue
        short = voice["ShortName"]
        if "Multilingual" in short:
            continue
        name = short.split("-")[-1].replace("Neural", "")
        if name.endswith("Multilingual"):
            name = name.replace("Multilingual", " multilingual")
        rows.append(
            {
                "label": "%s · %s · %s" % (name, PLACE[locale], voice["Gender"]),
                "id": short,
            }
        )
    rows.sort(key=lambda row: row["label"])
    path = Path(__file__).resolve().parents[1] / "voices.json"
    path.write_text(json.dumps(rows, indent=2), encoding="utf-8")
    print(len(rows))


if __name__ == "__main__":
    asyncio.run(main())
