# Build guide · Power BI Desktop (Windows)

There is no `.pbix` in this repo: Power BI Desktop only runs on Windows and this project was built on Linux. Everything needed to build the
report in about 20 minutes is here.

1. **Get the data.** Either use the committed CSVs in `powerbi/data/`, or regenerate them: `python scripts/download_full_data.py` then
   `python run_pipeline.py --source full`.
2. **Load.** Home > Get data > Text/CSV, load all six files from `powerbi/data/`. In Power Query check types: keys and counts as Whole
   number, `height_cm`, `weight_kg`, `bmi`, `birth_year_est` as Decimal, everything else Text. Close & Apply.
3. **Model.** In Model view create the relationships listed in `model.md` (many-to-one, single direction): `fact_medal` and
   `fact_entry_sample` to `dim_games` (games_key), `dim_event` (event_key) and `dim_noc` (noc); `fact_entry_sample` to `dim_athlete`
   (athlete_id). Sort `dim_games[games]` by `games_key`.
4. **Measures.** Create a blank table called `_Measures` and paste each line of `measures.dax` as a new measure.
5. **Visuals.** Build the page described in `dashboard_spec.md`. Add a page-level filter `fact_medal[is_official] = 1`.
6. **Check against the repo.** With no slicers, [Medals] should be 18,556 and the USA 2,792 (1,115 gold); [Athletes] should be 135,571.
   These match `results/metrics.json` and `results/RESULTS.md`.
