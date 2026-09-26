import asyncio
import json
import sys
from pathlib import Path

import edge_tts

DEFAULT_VOICE = "en-US-AriaNeural"
RATE = "+0%"


def _english_voice(voice: str) -> str:
    # Multilingual neural voices switch to French when they see an inch mark or curly quote.
    return voice.replace("Multilingual", "") or DEFAULT_VOICE


async def _speak(text: str, output_path: str, voice: str) -> None:
    await edge_tts.Communicate(text, _english_voice(voice), rate=RATE).save(output_path)


async def _speak_all(jobs: list) -> None:
    await asyncio.gather(*jobs)


def synthesize(segments: list, folder: Path, voice: str) -> list:
    """Speak every non-empty segment into folder. Returns the manifest rows."""
    folder.mkdir(parents=True, exist_ok=True)
    jobs = []
    manifest = []
    for index, segment in enumerate(segments):
        text = str(segment.get("text", "")).strip()
        if not text:
            continue
        name = "%d.mp3" % index
        jobs.append(_speak(text, str(folder / name), voice))
        manifest.append(
            {
                "file": name,
                "choice": int(segment.get("choice", -1)),
                "teach": bool(segment.get("teach", False)),
                "text": text,
            }
        )
    asyncio.run(_speak_all(jobs))
    if not manifest:
        raise SystemExit("empty speech text")
    (folder / "manifest.json").write_text(json.dumps(manifest), encoding="utf-8")
    return manifest


def main() -> None:
    text_path, output_path = sys.argv[1], sys.argv[2]
    voice = sys.argv[3] if len(sys.argv) > 3 and sys.argv[3] else DEFAULT_VOICE
    payload = json.loads(Path(text_path).read_text(encoding="utf-8"))
    if isinstance(payload, dict) and "segments" in payload:
        segments = payload["segments"]
    elif isinstance(payload, list):
        segments = payload
    else:
        segments = [{"text": str(payload), "choice": -1}]
    synthesize(segments, Path(output_path), voice)


if __name__ == "__main__":
    main()
