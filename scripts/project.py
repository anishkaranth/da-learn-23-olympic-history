"""Project-specific settings used by run_pipeline.py (raw files, exports, JSON.shot content)."""
NAME = "da-learn-23-olympic-history"
DATASET = ("120 years of Olympic history: athletes and results, Athens 1896 to Rio 2016 (Kaggle heesoo37/120-years-of-olympic-history-"
           "athletes-and-results, CC0: Public Domain; scraped from sports-reference.com by Randi Griffin). GitHub mirror rgriff23/Olympic_history: "
           "athlete_events.csv (271,116 rows x 15 columns, 41,229,571 B) + noc_regions.csv (230 NOCs, 3,595 B)")
RAW_FILES = ["athlete_events.csv", "noc_regions.csv"]
DIMS = ["dim_games", "dim_event", "dim_noc", "dim_athlete"]
FACT_SAMPLE_EVERY = 5   # fact_entry_sample = entry_key % 5 = 0
METRIC_TABLES = ["a_kpi_headline", "a_games", "a_medal_table", "a_medal_table_noc", "a_medal_era", "a_region_trend", "a_host_effect", "a_women",
                 "a_sport_physique", "a_age_band", "a_sport_age", "a_top_athletes", "a_medal_efficiency", "a_sport_dominance"]


def export_full(con, export, root):
    """Full run: the four dims and fact_medal (every podium place) are exported in full; fact_entry (269,731 rows) as a deterministic
    1-in-5 sample (entry_key % 5 = 0) to keep the repo small. Same files go to data/clean/star/ and powerbi/data/."""
    con.execute(f"CREATE OR REPLACE TEMP VIEW fact_entry_sample AS SELECT * FROM fact_entry WHERE entry_key % {FACT_SAMPLE_EVERY} = 0")
    for t in DIMS + ["fact_medal", "fact_entry_sample"]:
        export(con, t, root / "data/clean/star" / f"{t}.csv")
        export(con, t, root / "powerbi/data" / f"{t}.csv")


def build_shot(q, kpi):
    """Headline snapshot written to results/JSON.shot."""
    return {
        "config": {"sql_dialect": "Spark SQL style (+ DuckDB shims in sql/00), run on DuckDB; Databricks skipped (workspace quota)",
                   "grain": "fact_entry = one athlete x event x Games row; fact_medal = one podium place (Games x event x NOC x team entry x medal)",
                   "official_scope": "analysis excludes the 1906 Intercalated Games (not IOC-recognised) and the 1912-1948 Art Competitions",
                   "medal_rule": "team members share one medal: a relay or team gold counts once for the nation, not once per athlete",
                   "region_rule": "NOC -> region from noc_regions.csv (URS/EUN -> Russia, GDR/FRG -> Germany, YUG -> Serbia ...), SGP override added",
                   "host_effect": "host region's share of all medals at home vs its mean share at the other same-season Games within 12 years",
                   "physique": "Summer 1992-2016, one row per athlete x Games x sport, BMI < 15 or > 60 excluded",
                   "sample_rule": "data/raw: every athlete whose ID % 20 = 0 (all their rows) + every row of an exact-duplicate group "
                                  "(scripts/make_sample.py); noc_regions.csv in full"},
        "headline": kpi,
        "medal_table_top10": q("SELECT rnk, region, gold, silver, bronze, total, pct_all_medals FROM a_medal_table WHERE rnk <= 10 ORDER BY rnk"),
        "host_effect": q("SELECT games, host_region, host_medals, host_pct_at_home, host_pct_other_games FROM a_host_effect ORDER BY year, season"),
        "women_summer": q("SELECT year, female_pct, women_events_pct FROM a_women WHERE season = 'Summer' ORDER BY year"),
        "top_athletes": q("SELECT rnk, athlete_name, noc, sport, gold, silver, bronze, medals FROM a_top_athletes ORDER BY rnk LIMIT 5"),
        "medal_efficiency_top5": q("SELECT region, athlete_games, medals, medals_per_100_athletes FROM a_medal_efficiency "
                                   "ORDER BY medals_per_100_athletes DESC LIMIT 5"),
    }
