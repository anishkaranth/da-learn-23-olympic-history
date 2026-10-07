# Data

| Folder | What | In git? |
|---|---|---|
| `raw/` | Deterministic sample of the raw files: `athlete_events.csv` (15,313 of 271,116 rows: every athlete whose ID % 20 = 0 with all their rows, plus every exact-duplicate row group) and `noc_regions.csv` unchanged | yes (2.4 MB) |
| `raw_full/` | The full original files, downloaded with `python scripts/download_full_data.py` (SHA-256 checked) | no (`.gitignore`) |
| `reference/` | Hand-made lookups: `host_nations.csv` (host NOC for each of the 51 Games; 1956 has Melbourne + Stockholm) and `noc_region_overrides.csv` (SGP, ROT, TUV, UNK) | yes |
| `clean/star/` | Star-schema output of the full run: the four dims and `fact_medal` complete, `fact_entry_sample` = every 5th clean entry | yes |

Raw columns (`athlete_events.csv`): ID, Name, Sex, Age, Height (cm), Weight (kg), Team, NOC, Games, Year, Season, City, Sport, Event, Medal.
Missing values are the literal text `NA`. `noc_regions.csv` has NOC, region, notes and uses old-Mac CR-only line endings.
Rebuild the sample with `python scripts/make_sample.py` after downloading the full data.
