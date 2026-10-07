# Dashboard spec · da-learn-23 Olympic history

One report page, 16:9, plus a drill-through page. All medal visuals use `fact_medal` with `is_official = 1` (set as a page-level filter).

| # | Visual | Fields | Matches repo chart |
|---|---|---|---|
| 1 | KPI cards | [Athletes], [Games Count], DISTINCTCOUNT(dim_noc[noc]), [Medals], [Female Athletes %] (2016 filter), [Top Athlete Medals] | dashboard.svg header |
| 2 | Clustered bar: medal table | Axis dim_noc[region], values [Gold], [Silver], [Bronze]; Top N 15 by [Medals] | medal_table.svg |
| 3 | Line: medal share per Summer Games | Axis dim_games[year], legend dim_noc[region] (top 6), value [Share of All Medals %]; season = Summer, year >= 1948 | region_trend.svg |
| 4 | Matrix heatmap: share by era | Rows region, columns dim_games[era], value [Share of All Medals %], conditional formatting | medal_era.svg |
| 5 | Line: women | Axis year, values [Female Athletes %] (and a women-events measure if you add one); season = Summer | women_trend.svg |
| 6 | Clustered column: home advantage | Axis dim_games[games] (hosts since 1948), values [Host Share %] vs a what-if average of the region's share at nearby Games | host_effect.svg |
| 7 | Scatter: body type | X [Avg Height cm], Y [Avg Weight kg], details dim_event[sport], legend dim_athlete[sex]; year >= 1992, Summer | physique.svg |
| 8 | Column: medal rate by age band | Axis = a calculated column on fact_entry_sample age bands, value [Medal Rate %] | age_medal_rate.svg |
| 9 | Table: legends | dim_athlete name, latest_noc, latest_sport, golds, silvers, bronzes, medals; Top N 15 | top_athletes.svg |

Slicers: dim_games[season], dim_games[era], dim_noc[region], dim_event[sport].
Drill-through page "Nation": medals by Games for the selected region, sports it wins in, and its host Games.
