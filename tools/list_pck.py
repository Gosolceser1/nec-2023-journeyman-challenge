"""List the files inside a Godot 4 .pck (format 2, 3 or 4) and flag what should not ship.

    python tools/list_pck.py build/NEC2023JourneymanChallenge.pck [--desktop] [--all]

Prints a per-top-level-folder summary, then fails (exit 1) if a path that the
export presets exclude made it in (tests, tools except the speech helper,
docs, source PDFs, OCR PNGs), or if something the app loads at runtime is
missing (bank, voices, diagrams, sfx, imported speech clips).
"""
import struct
import sys
from collections import Counter

MAGIC = 0x43504447  # "GDPC"


def read_entries(path):
    with open(path, "rb") as f:
        data = f.read()
    start = 0
    magic = struct.unpack_from("<I", data, 0)[0]
    if magic != MAGIC:
        # Embedded pack: the trailer is <u64 size><magic> at the very end.
        tail_magic = struct.unpack_from("<I", data, len(data) - 4)[0]
        if tail_magic != MAGIC:
            raise SystemExit(f"{path}: not a Godot pack")
        size = struct.unpack_from("<Q", data, len(data) - 12)[0]
        start = len(data) - 12 - size
    pos = start
    magic, version, _maj, _min, _pat = struct.unpack_from("<5I", data, pos)
    pos += 20
    if version not in (2, 3, 4):
        raise SystemExit(f"unsupported pack format {version}")
    flags = struct.unpack_from("<I", data, pos)[0]
    pos += 4
    if flags & 1:
        raise SystemExit("encrypted pack directory")
    pos += 8  # file_base
    if version >= 3:
        dir_offset = struct.unpack_from("<Q", data, pos)[0]
        pos = start + dir_offset
    else:
        pos += 16 * 4
    count = struct.unpack_from("<I", data, pos)[0]
    pos += 4
    entries = []
    for _ in range(count):
        n = struct.unpack_from("<I", data, pos)[0]
        pos += 4
        name = data[pos:pos + n].rstrip(b"\0").decode("utf-8")
        pos += n
        _off, size = struct.unpack_from("<QQ", data, pos)
        pos += 16 + 16 + 4  # offset, size, md5, flags
        entries.append((name, size))
    return entries


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    entries = read_entries(sys.argv[1])
    names = [e[0].removeprefix("res://") for e in entries]
    total = sum(e[1] for e in entries)
    tops = Counter()
    sizes = Counter()
    for (name, size), rel in zip(entries, names):
        top = rel.split("/")[0] if "/" in rel else "(root)"
        tops[top] += 1
        sizes[top] += size
    print(f"{len(entries)} files, {total / 1e6:.1f} MB")
    for top, n in sorted(tops.items()):
        print(f"  {top:24s} {n:6d} files  {sizes[top] / 1e6:8.2f} MB")
    if "--all" in sys.argv:
        for rel in sorted(names):
            print("   ", rel)

    def shipped(pred):
        return [r for r in names if pred(r)]

    bad = shipped(lambda r: (
        r.startswith(("tools/tests/", "tools/visual/", "tools/pipeline/", "docs/", "exams_source_pdf/", "build/"))
        or (r.startswith("tools/") and not r.endswith("speak_question.py"))
        or r.endswith((".pdf", ".md"))
    ))
    # Imported textures live under .godot/imported; flag any OCR/tool PNG import.
    bad += shipped(lambda r: r.startswith(".godot/imported/") and "exam5_key" in r)
    need = {
        "question bank": lambda r: r.endswith("question_bank.json"),
        "voice catalog": lambda r: r.endswith("voices.json"),
        "diagrams map": lambda r: r.endswith("diagrams/diagrams.json"),
        "sfx": lambda r: "sfx/" in r and r.endswith(".wav.import"),
        "speech clips (imported)": lambda r: "speech/" in r and r.endswith(".mp3.import"),
        "speech manifests": lambda r: "speech/" in r and r.endswith("manifest.json"),
    }
    if "--desktop" in sys.argv:
        need["desktop speech helper"] = lambda r: r.endswith("speak_question.py")
    missing = [label for label, pred in need.items() if not shipped(pred)]
    for r in bad:
        print(f"  SHOULD NOT SHIP: {r}")
    for label in missing:
        print(f"  MISSING: {label}")
    print("PCK CHECK:", "PASS" if not bad and not missing else "FAIL")
    return 1 if bad or missing else 0


if __name__ == "__main__":
    sys.exit(main())
