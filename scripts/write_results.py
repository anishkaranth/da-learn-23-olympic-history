#!/usr/bin/env python3
"""Write results/RESULTS.md from results/metrics.json + results/tables/*.csv (every number comes from the full-data run)."""
import csv, json, pathlib
from statistics import median

ROOT = pathlib.Path(__file__).resolve().parents[1]
RES = ROOT / "results"
T = RES / "tables"


def rd(name):
    with open(T / f"{name}.csv", newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def f(x):
    return float(x) if x not in ("", None) else 0.0


def i(x):
    return int(f(x))


def num(v):
    if v in ("", None):
        return ""
    try:
        x = float(v)
    except ValueError:
        return str(v).replace("|", "/")
    return f"{int(x):,}" if x.is_integer() and abs(x) >= 1000 else (str(int(x)) if x.is_integer() else f"{x:,.2f}".rstrip("0").rstrip("."))


def table(rows, cols, heads=None):
    out = ["| " + " | ".join(heads or cols) + " |", "|" + "---|" * len(cols)]
    for r in rows:
        out.append("| " + " | ".join(num(r[c]) for c in cols) + " |")
    return "\n".join(out)


m = json.loads((RES / "metrics.json").read_text())
k = m["kpis"]
mt = sorted(rd("a_medal_table"), key=lambda r: i(r["rnk"])); M = {r["region"]: r for r in mt}
noc = sorted(rd("a_medal_table_noc"), key=lambda r: i(r["rnk"]))
era = rd("a_medal_era"); E = {(r["era"], r["region"]): r for r in era}
games = sorted(rd("a_games"), key=lambda r: (i(r["year"]), r["season"])); G = {r["games"]: r for r in games}
host = sorted(rd("a_host_effect"), key=lambda r: (i(r["year"]), r["season"]))
h48 = [r for r in host if i(r["year"]) >= 1948]; hs = [r for r in h48 if r["season"] == "Summer"]
eff = sorted(rd("a_medal_efficiency"), key=lambda r: -f(r["medals_per_100_athletes"]))
ph = rd("a_sport_physique"); P = {(r["sport"], r["sex"]): r for r in ph}
age = {r["age_band"]: r for r in rd("a_age_band")}
sage = sorted(rd("a_sport_age"), key=lambda r: f(r["median_medalist_age"]))
top = sorted(rd("a_top_athletes"), key=lambda r: i(r["rnk"]))
dom = sorted(rd("a_sport_dominance"), key=lambda r: -f(r["top_region_pct"]))
dq_i = rd("dq_issues"); dq_n = rd("dq_null_rates"); dq_r = rd("dq_row_counts"); asr = rd("dq_assertions")
D = {r["check_name"]: i(r["affected_rows"]) for r in dq_i}
npass = sum(1 for r in asr if r["status"] == "PASS")
s16, s48 = G["2016 Summer"], G["1948 Summer"]
above = sum(1 for r in h48 if f(r["home_lift"]) > 1)
bas, gym = P[("Basketball", "M")], P[("Gymnastics", "F")]
wl_m = P[("Weightlifting", "M")]

ins = [
    f"**The USA tops the all-time table, but the Soviet Union ruled the Cold War.** Counting each podium place once (a relay gold is one medal, "
    f"not four), the USA has won {i(M['USA']['total']):,} medals ({f(M['USA']['pct_all_medals']):.1f}% of all, {i(M['USA']['gold']):,} gold), "
    f"Russia including the Soviet Union and Unified Team {i(M['Russia']['total']):,}, and Germany (East + West + unified) {i(M['Germany']['total']):,}. "
    f"In 1948-1988 the Russia/Soviet region took {f(E[('1948-1988', 'Russia')]['pct_era_medals']):.1f}% of medals vs "
    f"{f(E[('1948-1988', 'USA')]['pct_era_medals']):.1f}% for the USA; since 1992 the USA leads again ({f(E[('1992-2016', 'USA')]['pct_era_medals']):.1f}%) "
    f"and China has climbed to 4th ({f(E[('1992-2016', 'China')]['pct_era_medals']):.1f}%).",
    f"**Women went from absent to near parity.** No women competed in 1896; they were {f(s48['female_pct']):.1f}% of Summer athletes in 1948 and "
    f"{f(s16['female_pct']):.1f}% in Rio 2016, when {f(s16['women_events_pct']):.1f}% of events were women-only. The Games also grew from "
    f"{i(G['1896 Summer']['athletes'])} athletes from {i(G['1896 Summer']['nocs'])} nations to {i(s16['athletes']):,} from {i(s16['nocs'])}.",
    f"**Home advantage is real.** Since 1948 the host won a bigger share of medals at home than its own average at the other same-season Games "
    f"within 12 years in {above} of {len(h48)} Games (median lift {median(f(r['home_lift']) for r in h48):.2f}x). The USA took "
    f"{f(G['1984 Summer'] and [r for r in host if r['games'] == '1984 Summer'][0]['host_pct_at_home']):.1f}% of medals in Los Angeles 1984 "
    f"(Soviet-led boycott) and the Soviet Union {[r for r in host if r['games'] == '1980 Summer'][0]['host_pct_at_home']}% in Moscow 1980 "
    f"(US-led boycott); China rose from {[r for r in host if r['games'] == '2008 Summer'][0]['host_pct_other_games']}% to "
    f"{[r for r in host if r['games'] == '2008 Summer'][0]['host_pct_at_home']}% in Beijing 2008. Atlanta 1996 is a rare exception for the USA "
    f"({[r for r in host if r['games'] == '1996 Summer'][0]['host_pct_at_home']}% vs {[r for r in host if r['games'] == '1996 Summer'][0]['host_pct_other_games']}%).",
    f"**Small teams can be the most efficient.** In the Summer Games of 2000-2016, {eff[0]['region']} won {f(eff[0]['medals_per_100_athletes']):.1f} medals "
    f"per 100 athletes sent ({i(eff[0]['medals'])} from {i(eff[0]['athlete_games'])}), ahead of {eff[1]['region']} ({f(eff[1]['medals_per_100_athletes']):.1f}), "
    f"{eff[2]['region']} ({f(eff[2]['medals_per_100_athletes']):.1f}) and {eff[3]['region']} ({f(eff[3]['medals_per_100_athletes']):.1f}).",
    f"**Every sport has a body type and an age.** In 1992-2016 male basketball players averaged {f(bas['avg_height_cm']):.1f} cm and "
    f"{f(bas['avg_weight_kg']):.1f} kg, female gymnasts {f(gym['avg_height_cm']):.1f} cm and {f(gym['avg_weight_kg']):.1f} kg, and male weightlifters "
    f"only {f(wl_m['avg_height_cm']):.0f} cm but {f(wl_m['avg_weight_kg']):.0f} kg (BMI {f(wl_m['avg_bmi']):.1f}). Medallists are "
    f"youngest in {sage[0]['sport'].lower()} (median {f(sage[0]['median_medalist_age']):.1f}) and oldest in {sage[-1]['sport'].lower()} "
    f"(median {f(sage[-1]['median_medalist_age']):.0f}). Across all Games, under-18 entries win a medal {f(age['<18']['medal_rate_pct']):.1f}% of the time "
    f"vs {f(age['26-29']['medal_rate_pct']):.1f}% at 26-29.",
    f"**Dominance and legends.** China won {f(dom[0]['top_region_pct']):.0f}% of all diving golds since 1992 ({i(dom[0]['top_region_golds'])} of "
    f"{i(dom[0]['sport_golds'])}) and the USA {f([r for r in dom if r['sport'] == 'Swimming'][0]['top_region_pct']):.0f}% of swimming golds. "
    f"Michael Phelps has {i(top[0]['medals'])} medals ({i(top[0]['gold'])} gold), {i(top[0]['medals']) - i(top[1]['medals'])} more than "
    f"the next athlete, gymnast {top[1]['athlete_name'].split(' (')[0]} ({i(top[1]['medals'])}).",
]

md = f"""# RESULTS · da-learn-23 · 120 years of Olympic history (1896-2016)

All numbers below come from the **full** dataset ({i(k['raw_rows']):,} raw rows) run through `sql/01`-`sql/05` on DuckDB
({m['engine']['duckdb']}); nothing is estimated or hand-typed. Databricks was skipped because the workspace hit its resource quota, so there is
no live Lakeview dashboard; the SQL stays Databricks-compatible. Charts: `results/images/` (SVG + PNG).

![Dashboard](images/dashboard.png)

## Headline KPIs
| KPI | Value |
|---|---|
| Raw rows / clean entries | {i(k['raw_rows']):,} / {i(k['clean_entries']):,} |
| Distinct athletes | {i(k['athletes']):,} |
| Games editions (official) | {i(k['games_editions'])} ({i(k['official_games_editions'])}: {i(k['summer_games'])} Summer + {i(k['winter_games'])} Winter; 1906 excluded) |
| Official events / sports | {i(k['official_events'])} / {i(k['official_sports'])} |
| NOCs / regions | {i(k['nocs'])} / {i(k['regions'])} |
| Athlete medal rows / podium places (team medal = 1) | {i(k['athlete_medal_rows']):,} / {i(k['medal_events']):,} |
| Entries that won a medal | {f(k['pct_entries_medal']):.2f}% |
| Women among athletes, 1948 / 2016 | {f(k['female_pct_athletes_1948']):.2f}% / {f(k['female_pct_athletes_2016']):.2f}% |
| Athletes 1896 / 2016 | {i(k['athletes_1896'])} / {i(k['athletes_2016']):,} |
| Most medals by one athlete | {i(k['most_medals_one_athlete'])} |
| Assertions | {npass}/{len(asr)} PASS |

## Insights
""" + "\n".join(f"{n}. {t}" for n, t in enumerate(ins, 1)) + f"""

## All-time medal table (top 15, regions)
![Medal table](images/medal_table.png)

{table(mt[:15], ['rnk', 'region', 'gold', 'silver', 'bronze', 'total', 'summer_total', 'winter_total', 'pct_all_medals'],
       ['#', 'Region', 'Gold', 'Silver', 'Bronze', 'Total', 'Summer', 'Winter', '% of all'])}

By NOC (historic teams kept separate), the top five are:
{table(noc[:5], ['rnk', 'noc', 'region', 'gold', 'total', 'first_medal_year', 'last_medal_year'], ['#', 'NOC', 'Region', 'Gold', 'Total', 'First', 'Last'])}

## Medal share by era
![Medal share by era](images/medal_era.png)
![Region trend](images/region_trend.png)

## Home advantage
![Host effect](images/host_effect.png)

{table(h48, ['games', 'host_region', 'host_medals', 'host_pct_at_home', 'host_pct_other_games', 'home_lift'],
       ['Games', 'Host', 'Medals', '% at home', '% other Games (avg)', 'Lift'])}

## Women and growth
![Women](images/women_trend.png)
![Participation](images/participation.png)
![Nations](images/nations_trend.png)

## Efficiency (Summer 2000-2016)
![Efficiency](images/medal_efficiency.png)

{table(eff[:15], ['region', 'athlete_games', 'medals', 'gold', 'medals_per_100_athletes'], ['Region', 'Athlete-Games', 'Medals', 'Gold', 'Medals / 100 athletes'])}

## Body type and age
![Physique](images/physique.png)
![Height by sport](images/height_by_sport.png)
![Age medal rate](images/age_medal_rate.png)
![Sport age](images/sport_age.png)

{table([age[b] for b in ['<18', '18-21', '22-25', '26-29', '30-34', '35-39', '40+']], ['age_band', 'entries', 'medal_entries', 'medal_rate_pct'],
       ['Age band', 'Entries', 'Medal entries', 'Medal rate %'])}

## Sport dominance and legends
![Sport dominance](images/sport_dominance.png)
![Top athletes](images/top_athletes.png)

{table(top[:10], ['rnk', 'athlete_name', 'noc', 'sport', 'first_year', 'last_year', 'gold', 'silver', 'bronze', 'medals'],
       ['#', 'Athlete', 'NOC', 'Sport', 'First', 'Last', 'G', 'S', 'B', 'Total'])}

## Data quality
![Data quality](images/data_quality.png)

**Row counts**

{table(dq_r, ['entity', 'raw_rows', 'distinct_rows', 'clean_rows', 'grain'])}

**Issues found and how they were handled**

{table(dq_i, ['check_name', 'affected_rows'])}

**Null rates**

{table(dq_n, ['entity', 'column_name', 'null_pct', 'treatment'])}

**Assertions ({npass}/{len(asr)} PASS)**

{table(asr, ['check_name', 'failed_rows', 'status'])}

## How the images were made
`scripts/make_charts.py` reads the DuckDB query results exported to `results/tables/*.csv` and writes every chart as a plain-vector SVG with the
small custom writer `scripts/svgcharts.py` (rect, line, polyline, circle and text only; no plotting library, no embedded raster).
`scripts/render_png.py` then rasterises each SVG to a PNG at 2x with headless Google Chrome. Both versions are committed in `results/images/`.

## Files
`metrics.json` (KPIs, data-quality evidence, engine, SQL timings), `JSON.shot` (headline snapshot + run config), `tables/` (every `a_*` and
`dq_*` table as CSV), `images/` (SVG + PNG), `sample/` (the same pipeline on the committed raw sample).
"""
(RES / "RESULTS.md").write_text(md)
print("wrote", RES / "RESULTS.md")
