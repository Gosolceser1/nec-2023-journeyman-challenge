"""Compare two screenshot folders written by snap_all.gd, pixel by pixel.

    python tools/visual/compare_shots.py .audit_tmp/shots/before .audit_tmp/shots/after

Two back-to-back runs of the same build, even with --fixed-fps and --det,
differ by at most 1 colour level on a few dozen pixels (GPU rounding in the
animated shaders). A pixel counts as changed only above --noise (default 1).
Exit 0 when no image has a changed pixel.
"""
import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("before", type=Path)
    ap.add_argument("after", type=Path)
    ap.add_argument("--noise", type=int, default=1, help="max per-channel delta treated as render noise")
    args = ap.parse_args()

    shots = sorted(args.before.glob("*.png"))
    if not shots:
        print(f"no screenshots in {args.before}")
        return 2
    changed = 0
    for a in shots:
        b = args.after / a.name
        if not b.exists():
            print(f"MISSING  {a.name}")
            changed += 1
            continue
        ia = np.asarray(Image.open(a).convert("RGB"), dtype=np.int16)
        ib = np.asarray(Image.open(b).convert("RGB"), dtype=np.int16)
        if ia.shape != ib.shape:
            print(f"SIZE     {a.name}  {ia.shape} vs {ib.shape}")
            changed += 1
            continue
        d = np.abs(ia - ib).max(axis=2)
        exact = int((d > 0).sum())
        real = int((d > args.noise).sum())
        if real:
            ys, xs = np.nonzero(d > args.noise)
            print(f"CHANGED  {a.name:38s} px={real} box=({xs.min()},{ys.min()})-({xs.max()},{ys.max()}) maxdelta={int(d.max())}")
            changed += 1
        else:
            print(f"SAME     {a.name:38s} (noise px={exact})")
    print(f"{len(shots) - changed}/{len(shots)} identical")
    return 1 if changed else 0


if __name__ == "__main__":
    sys.exit(main())
