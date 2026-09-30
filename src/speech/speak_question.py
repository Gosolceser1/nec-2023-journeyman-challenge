"""Edge neural speech for the game.

    speak_question.py LINE_JSON FOLDER [VOICE]   one-shot: synthesize, write manifest
    speak_question.py --serve                    persistent helper (JSON lines on stdio)

The one-shot form is what tools/speech/pregenerate_speech.py uses. The game keeps one --serve helper running so the ~3 s import of
edge_tts + aiohttp is paid once, and clips stream back as each one finishes.

--serve protocol, one JSON object per line.
  in:  {"op": "speak", "id": N, "folder": F, "voice": V, "segments": [...], "prio": 0|1}
       {"op": "prio", "id": N, "prio": 0|1}      (a prefetch became the live read)
       {"op": "cancel", "id": N}
  out: {"event": "ready"}                        (imports done)
       {"event": "clip", "id": N, "index": I, "file": "I.mp3"}
       {"event": "done", "id": N}                (manifest.json written)
       {"event": "fail", "id": N, "reason": "..."}
prio 0 is a live read, prio 1 a prefetch; each has its own workers. Clips land
as I.mp3.part and are renamed when complete; manifest.json is written last and
only when every clip exists.

SPEECH_FAKE_CLIP=<mp3> (tests): copy that file instead of calling Edge, after
SPEECH_FAKE_DELAY seconds per clip. SPEECH_FAKE_FAIL=1 makes every clip fail.
"""

import asyncio
import json
import os
import shutil
import sys
import threading
import time
from pathlib import Path

def _catalog_default(path: Path = Path(__file__).resolve().parents[2] / "data" / "voices.json") -> str:
    """The voices.json row marked "default": true (VoiceCatalog reads the same
    mark); Andrew when the script runs outside the repo."""
    try:
        rows = json.loads(path.read_text(encoding="utf-8"))
        return next((str(r["id"]) for r in rows if r.get("default") is True), str(rows[0]["id"]))
    except (OSError, ValueError, LookupError, TypeError, AttributeError):
        return "en-US-AndrewNeural"


DEFAULT_VOICE = _catalog_default()
RATE = "+0%"

# edge-tts hardcodes 48 kbps; the endpoint also serves 96 kbps (48 kHz formats
# are refused, Opus does not play in Godot). Stored in every manifest row so
# clips recorded in another format are treated as stale. Keep in sync with
# SPEECH_FORMAT in speech_controller.gd.
OUTPUT_FORMAT = "audio-24khz-96kbitrate-mono-mp3"
_EDGE_DEFAULT_FORMAT = "audio-24khz-48kbitrate-mono-mp3"

# A DNS or socket hiccup used to fail the whole question and drop the game to
# the robotic system voice; retry each clip before giving up.
RETRY_DELAYS = (1.0, 2.0, 4.0)
MAX_PARALLEL = 4
# --serve: live reads get MAX_PARALLEL connections of their own; prefetch runs
# beside them on fewer, so it never delays the clip the learner is waiting for.
PREFETCH_PARALLEL = 3
# A stalled websocket once hung a bundle run for minutes; a clip takes ~1 s.
CLIP_TIMEOUT = 20.0
# A clip still missing after this long gets a second request raced against it.
HEDGE_AFTER = float(os.environ.get("SPEECH_HEDGE_AFTER", "2.5"))

FAKE_CLIP = os.environ.get("SPEECH_FAKE_CLIP", "")
FAKE_DELAY = float(os.environ.get("SPEECH_FAKE_DELAY", "0.05"))
FAKE_FAIL = os.environ.get("SPEECH_FAKE_FAIL", "") == "1"

_edge_tts = None


def _edge():
    """Imports edge_tts on first use (about 3 s) and patches in OUTPUT_FORMAT."""
    global _edge_tts
    if _edge_tts is None:
        import aiohttp
        import edge_tts
        from edge_tts import communicate as edge_communicate

        edge_communicate.MP3_BITRATE_BPS = 96_000
        send_str = aiohttp.ClientWebSocketResponse.send_str

        async def send_str_with_format(self, data, *args, **kwargs):
            if "Path:speech.config" in data:
                if _EDGE_DEFAULT_FORMAT not in data:
                    raise RuntimeError("edge-tts changed its speech.config; re-check OUTPUT_FORMAT patch")
                data = data.replace(_EDGE_DEFAULT_FORMAT, OUTPUT_FORMAT)
            return await send_str(self, data, *args, **kwargs)

        aiohttp.ClientWebSocketResponse.send_str = send_str_with_format
        _edge_tts = edge_tts
    return _edge_tts


def _english_voice(voice: str) -> str:
    # Multilingual neural voices switch to French when they see an inch mark or curly quote.
    return voice.replace("Multilingual", "") or DEFAULT_VOICE


async def _render(text: str, part: Path, voice: str) -> None:
    if FAKE_CLIP:
        await asyncio.sleep(FAKE_DELAY)
        if FAKE_FAIL:
            raise OSError("fake failure")
        shutil.copyfile(FAKE_CLIP, part)
        return
    await _edge().Communicate(text, _english_voice(voice), rate=RATE).save(str(part))


# The service can end a stream early and still report success; no clip is
# spoken faster than MAX_WORDS_PER_SEC (same bound as tools/speech/audit_bundle.py).
MAX_WORDS_PER_SEC = 4.6
BYTES_PER_SEC = 96_000 // 8


def min_clip_bytes(text: str) -> int:
    return int(len(text.split()) / MAX_WORDS_PER_SEC * BYTES_PER_SEC)


def _part_paths(output_path: Path) -> tuple:
    return (output_path.with_name(output_path.name + ".part"), output_path.with_name(output_path.name + ".h.part"))


def _unlink_quietly(path: Path) -> None:
    try:
        path.unlink(missing_ok=True)
    except OSError:
        # Windows: still open by a request being cancelled; it cleans up after itself.
        pass


async def _attempt(text: str, part: Path, voice: str) -> None:
    try:
        await asyncio.wait_for(_render(text, part, voice), CLIP_TIMEOUT)
        size = part.stat().st_size
        if size == 0:
            raise RuntimeError("empty audio")
        if not FAKE_CLIP and size < min_clip_bytes(text):
            raise RuntimeError("cut-off audio: %d bytes for %d words" % (size, len(text.split())))
    except BaseException:
        _unlink_quietly(part)
        raise


async def _hedged(text: str, output_path: Path, voice: str) -> Path:
    """One clip, with a second request raced against the first if it is slow.

    Most clips arrive in ~0.5-1 s, but a few take 5-9 s on the service side;
    whichever request finishes first wins. Returns the finished .part file.
    """
    parts = _part_paths(output_path)
    tasks = {asyncio.ensure_future(_attempt(text, parts[0], voice)): parts[0]}
    try:
        done, _ = await asyncio.wait(tasks, timeout=HEDGE_AFTER)
        if not done:
            tasks[asyncio.ensure_future(_attempt(text, parts[1], voice))] = parts[1]
        error = None
        while tasks:
            done, _ = await asyncio.wait(tasks, return_when=asyncio.FIRST_COMPLETED)
            for task in done:
                part = tasks.pop(task)
                if task.exception() is None:
                    return part
                error = task.exception()
        raise error
    finally:
        for task in tasks:
            task.cancel()
        if tasks:
            await asyncio.gather(*tasks, return_exceptions=True)


async def _speak(text: str, output_path: Path, voice: str) -> None:
    # Written to .part and renamed only when complete, so an interrupted or
    # failed run never leaves a truncated clip under its real name.
    delays = (0.0,) if FAKE_CLIP else RETRY_DELAYS
    for attempt in range(len(delays) + 1):
        try:
            os.replace(await _hedged(text, output_path, voice), output_path)
            return
        except asyncio.CancelledError:
            raise
        except Exception:
            if attempt == len(delays):
                raise
            await asyncio.sleep(delays[attempt])


def _plan(segments: list) -> list:
    """(index, manifest row) for every non-empty segment. Clip I is I.mp3."""
    rows = []
    for index, segment in enumerate(segments):
        text = str(segment.get("text", "")).strip()
        if not text:
            continue
        rows.append(
            (
                index,
                {
                    "file": "%d.mp3" % index,
                    "choice": int(segment.get("choice", -1)),
                    "teach": bool(segment.get("teach", False)),
                    # speech_rules.gd VERSION the text was normalised under; the
                    # game treats a clip with a different version as stale.
                    "rules": int(segment.get("rules", 0)),
                    "format": OUTPUT_FORMAT,
                    "text": text,
                },
            )
        )
    return rows


def _write_manifest(folder: Path, rows: list) -> None:
    part = folder / "manifest.json.part"
    part.write_text(json.dumps([row for _index, row in rows]), encoding="utf-8")
    os.replace(part, folder / "manifest.json")


def _discard(folder: Path, rows: list) -> None:
    for _index, row in rows:
        clip = folder / row["file"]
        for path in (clip, *_part_paths(clip)):
            _unlink_quietly(path)


def synthesize(segments: list, folder: Path, voice: str) -> list:
    """Speak every non-empty segment into folder. Returns the manifest rows.

    Raises on failure, leaving no clips and no manifest from this run.
    """
    folder.mkdir(parents=True, exist_ok=True)
    (folder / "manifest.json").unlink(missing_ok=True)
    rows = _plan(segments)
    if not rows:
        raise SystemExit("empty speech text")

    async def run_all() -> None:
        gate = asyncio.Semaphore(MAX_PARALLEL)

        async def one(row: dict) -> None:
            async with gate:
                await _speak(row["text"], folder / row["file"], voice)

        await asyncio.gather(*(one(row) for _index, row in rows))

    try:
        asyncio.run(run_all())
    except BaseException:
        _discard(folder, rows)
        raise
    _write_manifest(folder, rows)
    return [row for _index, row in rows]


def _fail_line(exc: BaseException) -> str:
    message = str(exc).splitlines()[0] if str(exc) else ""
    return "%s: %s" % (type(exc).__name__, message)


class _Request:
    def __init__(self, rid: int, folder: Path, voice: str, rows: list, prio: int):
        self.id = rid
        self.folder = folder
        self.voice = voice
        self.rows = rows
        self.prio = prio
        self.left = len(rows)
        self.closed = False
        self.started: set = set()
        self.tasks: set = set()
        self.t0 = time.perf_counter()


class Server:
    """Two lanes of clip workers: live reads (prio 0) and prefetch (prio 1).

    Within a lane, older requests go first and each request's clips go in
    reading order, so the stem is always the first clip started.
    """

    def __init__(self) -> None:
        self.requests: dict = {}
        self.lanes = {0: asyncio.PriorityQueue(), 1: asyncio.PriorityQueue()}
        self.seq = 0

    def emit(self, event: dict) -> None:
        sys.stdout.write(json.dumps(event) + "\n")
        sys.stdout.flush()

    def queue_jobs(self, req: _Request) -> None:
        # Re-queued into the live lane on a prio bump: jobs already started
        # from the prefetch lane are skipped by "started".
        lane = self.lanes[0 if req.prio <= 0 else 1]
        for position, (index, row) in enumerate(req.rows):
            self.seq += 1
            lane.put_nowait((req.id, position, self.seq, index, row))

    def speak(self, msg: dict) -> None:
        rid = int(msg["id"])
        folder = Path(msg["folder"])
        folder.mkdir(parents=True, exist_ok=True)
        (folder / "manifest.json").unlink(missing_ok=True)
        rows = _plan(msg.get("segments", []))
        req = _Request(rid, folder, str(msg.get("voice", "")) or DEFAULT_VOICE, rows, int(msg.get("prio", 0)))
        self.requests[rid] = req
        if not rows:
            self.close(req, fail="empty speech text")
            return
        self.queue_jobs(req)

    def close(self, req: _Request, fail: str = "", cancelled: bool = False) -> None:
        if req.closed:
            return
        req.closed = True
        self.requests.pop(req.id, None)
        for task in list(req.tasks):
            task.cancel()
        if fail or cancelled:
            _discard(req.folder, req.rows)
        if fail:
            self.emit({"event": "fail", "id": req.id, "reason": fail})

    async def worker(self, lane: asyncio.PriorityQueue) -> None:
        while True:
            rid, _position, _seq, index, row = await lane.get()
            req = self.requests.get(rid)
            if req is None or req.closed or index in req.started:
                continue
            req.started.add(index)
            task = asyncio.current_task()
            req.tasks.add(task)
            try:
                await _speak(row["text"], req.folder / row["file"], req.voice)
            except asyncio.CancelledError:
                # Only a closed request cancels its tasks; the worker lives on.
                req.tasks.discard(task)
                if task.cancelling():
                    task.uncancel()
                continue
            except Exception as exc:
                req.tasks.discard(task)
                self.close(req, fail=_fail_line(exc))
                continue
            req.tasks.discard(task)
            if req.closed:
                continue
            self.emit({"event": "clip", "id": rid, "index": index, "file": row["file"],
                       "ms": round((time.perf_counter() - req.t0) * 1000)})
            req.left -= 1
            if req.left == 0:
                _write_manifest(req.folder, req.rows)
                req.closed = True
                self.requests.pop(rid, None)
                self.emit({"event": "done", "id": rid})

    def handle(self, line: str) -> None:
        try:
            msg = json.loads(line)
            op = msg.get("op")
            if op == "speak":
                self.speak(msg)
            elif op == "cancel":
                req = self.requests.get(int(msg["id"]))
                if req is not None:
                    self.close(req, cancelled=True)
            elif op == "prio":
                req = self.requests.get(int(msg["id"]))
                if req is not None and int(msg["prio"]) < req.prio:
                    req.prio = int(msg["prio"])
                    self.queue_jobs(req)
        except Exception as exc:
            self.emit({"event": "error", "reason": _fail_line(exc)})

    async def run(self) -> None:
        if not FAKE_CLIP:
            _edge()
        loop = asyncio.get_running_loop()
        lines: asyncio.Queue = asyncio.Queue()

        def read_stdin() -> None:
            # Windows asyncio cannot watch a pipe, so a thread feeds the loop.
            for raw in sys.stdin:
                loop.call_soon_threadsafe(lines.put_nowait, raw)
            loop.call_soon_threadsafe(lines.put_nowait, None)

        threading.Thread(target=read_stdin, daemon=True).start()
        workers = [asyncio.create_task(self.worker(self.lanes[0])) for _ in range(MAX_PARALLEL)]
        workers += [asyncio.create_task(self.worker(self.lanes[1])) for _ in range(PREFETCH_PARALLEL)]
        self.emit({"event": "ready"})
        while True:
            line = await lines.get()
            if line is None:
                break
            if line.strip():
                self.handle(line)
        for req in list(self.requests.values()):
            self.close(req, cancelled=True)
        for task in workers:
            task.cancel()


def main() -> None:
    if sys.argv[1:2] == ["--serve"]:
        sys.stdin.reconfigure(encoding="utf-8")
        asyncio.run(Server().run())
        return
    text_path, output_path = sys.argv[1], sys.argv[2]
    voice = sys.argv[3] if len(sys.argv) > 3 and sys.argv[3] else DEFAULT_VOICE
    payload = json.loads(Path(text_path).read_text(encoding="utf-8"))
    if isinstance(payload, dict) and "segments" in payload:
        segments = payload["segments"]
    elif isinstance(payload, list):
        segments = payload
    else:
        segments = [{"text": str(payload), "choice": -1}]
    try:
        synthesize(segments, Path(output_path), voice)
    except Exception as exc:
        # One line the game logs and shows as the fallback reason.
        print("SPEECH_FAIL: " + _fail_line(exc))
        sys.exit(2)


if __name__ == "__main__":
    main()
