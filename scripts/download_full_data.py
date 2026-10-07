#!/usr/bin/env python3
"""Download the full '120 years of Olympic history' data into data/raw_full/ and verify SHA-256.

Dataset: "120 years of Olympic history: athletes and results" by Randi Griffin (Kaggle user heesoo37), scraped from
sports-reference.com in May 2018; Kaggle licence CC0: Public Domain.
  Kaggle page: https://www.kaggle.com/datasets/heesoo37/120-years-of-olympic-history-athletes-and-results
  Author's GitHub mirror (same files, used here because there is no Kaggle API key): https://github.com/rgriff23/Olympic_history
"""
import hashlib, pathlib, sys, urllib.request

BASE = "https://raw.githubusercontent.com/rgriff23/Olympic_history/master/data"
FILES = {  # name: (sha256, bytes)
    "athlete_events.csv": ("675c6e6bb445107614c85ed6b886a66ff094cdaeb58443da14b9e9cd98fc56bd", 41229571),
    "noc_regions.csv": ("d9be65009dd12851058119cfc1df207cf64ce9c5dd2c3cd85bb95342f59c47f7", 3595),
}
out = pathlib.Path(__file__).resolve().parents[1] / "data" / "raw_full"
out.mkdir(parents=True, exist_ok=True)
bad = 0
for name, (sha, size) in FILES.items():
    p = out / name
    if not p.exists() or p.stat().st_size != size:
        url = f"{BASE}/{name}"
        print("downloading", url, f"({size / 1e6:.1f} MB)")
        tmp = p.with_suffix(".part")
        urllib.request.urlretrieve(url, tmp)
        tmp.replace(p)
    got = hashlib.sha256(p.read_bytes()).hexdigest()
    print(f"{name:22s} {p.stat().st_size:>12,} bytes  {'OK' if got == sha else 'CHECKSUM MISMATCH ' + got}")
    bad += got != sha
sys.exit(1 if bad else 0)
