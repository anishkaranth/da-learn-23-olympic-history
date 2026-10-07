#!/usr/bin/env python3
"""Build the git-sized raw sample data/raw/ from data/raw_full/ (deterministic, no randomness).

athlete_events.csv: keep ALL rows of every athlete whose ID % 20 = 0, plus every row that belongs to an exact-duplicate group (so the
de-duplication step is exercised). Lines are copied byte-for-byte in their original order (same header, same quoting, same NA markers).
noc_regions.csv is tiny (230 rows) and is copied unchanged, CR-only line endings included."""
import csv, io, pathlib, shutil
from collections import Counter

ROOT = pathlib.Path(__file__).resolve().parents[1]
SRC, OUT = ROOT / "data/raw_full", ROOT / "data/raw"
OUT.mkdir(parents=True, exist_ok=True)
lines = (SRC / "athlete_events.csv").read_text(encoding="utf-8").splitlines(keepends=True)
header, body = lines[0], lines[1:]
counts = Counter(body)
n_out = 0
with open(OUT / "athlete_events.csv", "w", encoding="utf-8", newline="") as fo:
    fo.write(header)
    for ln in body:
        aid = int(next(csv.reader(io.StringIO(ln)))[0])
        if aid % 20 == 0 or counts[ln] > 1:
            fo.write(ln); n_out += 1
shutil.copyfile(SRC / "noc_regions.csv", OUT / "noc_regions.csv")
print(f"athlete_events.csv: {n_out:,} of {len(body):,} rows, {(OUT / 'athlete_events.csv').stat().st_size:,} B")
print(f"noc_regions.csv copied ({(OUT / 'noc_regions.csv').stat().st_size:,} B)")
