#!/usr/bin/env python3
"""Render SVG charts (pure vector shapes, no raster) from the KPI tables exported by run_pipeline.py."""
import csv, pathlib, sys
from statistics import median
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import svgcharts as S

BLUE, ORANGE, GREEN, SAND, NAVY, BROWN, PURPLE, ROSE, TEAL, GOLD = S.PALETTE[:10]
MEDAL = {"Gold": "#c9a227", "Silver": "#9aa5b1", "Bronze": "#b0723e"}
AGE_ORDER = ["<18", "18-21", "22-25", "26-29", "30-34", "35-39", "40+"]


def rd(t, name):
    with open(pathlib.Path(t) / f"{name}.csv", newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def f(x):
    return float(x) if x not in ("", None) else 0.0


def i(x):
    return int(f(x))


def short(s, n=26):
    s = s.split(" (")[0]
    return s if len(s) <= n else s[: n - 1] + "."


def make_all(tables, out):
    out = pathlib.Path(out); out.mkdir(parents=True, exist_ok=True)
    P = {}
    kpi = rd(tables, "a_kpi_headline")[0]
    games = sorted(rd(tables, "a_games"), key=lambda r: (i(r["year"]), r["season"]))
    summer = [r for r in games if r["season"] == "Summer"]
    winter = [r for r in games if r["season"] == "Winter"]

    # 1 athletes per Summer Games
    P["participation"] = S.vbar("Athletes per Summer Games, 1896-2016", [r["year"][2:] if i(r["year"]) >= 1900 else r["year"] for r in summer],
                                [i(r["athletes"]) for r in summer], fmt="{:,.0f}", w=900, h=340, color=BLUE,
                                subtitle="distinct athletes (official events, art competitions excluded); no Games in 1916, 1940, 1944")
    # 2 nations (NOCs) per Games, Summer and Winter on one calendar axis
    years = sorted({i(r["year"]) for r in games})
    sm = {i(r["year"]): i(r["nocs"]) for r in summer}; wm = {i(r["year"]): i(r["nocs"]) for r in winter}
    P["nations_trend"] = S.line("Nations (NOCs) taking part per Games", [str(y) for y in years],
                                [("Summer", [sm.get(y) for y in years]), ("Winter", [wm.get(y) for y in years])], fmt="{:,.0f}",
                                subtitle="Summer and Winter Games share one calendar axis (Winter moved to even non-Summer years from 1994)", every=4)
    # 3 women
    P["women_trend"] = S.line("Women at the Summer Games", [r["year"] for r in summer],
                              [("% athletes who are women", [f(r["female_pct"]) for r in summer]),
                               ("% events for women only", [f(r["women_events_pct"]) for r in summer])],
                              fmt="{:.0f}%", subtitle=f"from 0% in 1896 to {f(summer[-1]['female_pct']):.1f}% of athletes in 2016", every=3)
    # 4 medal table
    mt = sorted(rd(tables, "a_medal_table"), key=lambda r: i(r["rnk"]))[:15]
    P["medal_table"] = S.hbar("All-time medal table, top 15 (1896-2016)", [r["region"] for r in mt], [i(r["total"]) for r in mt], fmt="{:,.0f}",
                              notes=[f"G{i(r['gold'])} S{i(r['silver'])} B{i(r['bronze'])}" for r in mt], color=GOLD, vmax=4000,
                              subtitle="podium places, team medal = 1; Soviet Union -> Russia, East + West Germany -> Germany")
    # 5 medal share by era heatmap
    era = rd(tables, "a_medal_era"); eras = ["1896-1936", "1948-1988", "1992-2016"]
    regs = []
    for e in eras:
        for r in sorted([x for x in era if x["era"] == e], key=lambda x: i(x["rnk"])):
            if r["region"] not in regs: regs.append(r["region"])
    em = {(r["era"], r["region"]): f(r["pct_era_medals"]) for r in era}
    P["medal_era"] = S.heatmap("Share of all medals by era (top 10 of each era)", regs, eras, [[em.get((e, g)) for e in eras] for g in regs],
                               fmt="{:.1f}%", subtitle="% of the era's podium places; blank = outside that era's top 10", w=560)
    # 6 region trend (boycott gaps visible)
    rt = rd(tables, "a_region_trend"); top6 = [r["region"] for r in mt[:6]]
    sy = [i(r["year"]) for r in summer if i(r["year"]) >= 1948]
    rv = {(r["region"], i(r["year"])): f(r["pct_games_medals"]) for r in rt}
    P["region_trend"] = S.line("Share of Summer medals per Games, top 6 nations, 1948-2016", [str(y) for y in sy],
                               [(g, [rv.get((g, y)) for y in sy]) for g in top6], fmt="{:.0f}%", every=1, w=900, h=360,
                               subtitle="gaps = no medals or absent: Russia (Soviet Union) skipped 1984, the USA skipped 1980, Germany was banned in 1948")
    # 7 host effect
    he = [r for r in sorted(rd(tables, "a_host_effect"), key=lambda r: (i(r["year"]), r["season"])) if i(r["year"]) >= 1948 and r["season"] == "Summer"]
    P["host_effect"] = S.grouped_vbar("Home advantage: host's share of medals, Summer 1948-2016",
                                      [f"{r['year'][2:]} {short(r['host_region'], 9)}" for r in he],
                                      [("at home", [f(r["host_pct_at_home"]) for r in he]),
                                       ("other Games within 12 years (avg)", [f(r["host_pct_other_games"]) for r in he])],
                                      fmt="{:.0f}", w=980, h=360, ylabel="% of all medals",
                                      subtitle=f"hosts beat their own nearby-Games average in {sum(1 for r in he if f(r['home_lift']) > 1)} of {len(he)} "
                                               f"Summer Games since 1948; median lift {median([f(r['home_lift']) for r in he]):.2f}x")
    # 8 medal efficiency
    me = sorted(rd(tables, "a_medal_efficiency"), key=lambda r: -f(r["medals_per_100_athletes"]))[:15]
    P["medal_efficiency"] = S.hbar("Medals per 100 athletes sent, Summer 2000-2016", [r["region"] for r in me],
                                   [f(r["medals_per_100_athletes"]) for r in me], fmt="{:.1f}", color=TEAL, vmax=30,
                                   notes=[f"{i(r['medals'])} medals / {i(r['athlete_games']):,} athletes" for r in me],
                                   subtitle="nations with >= 250 athlete-Games; team medal counts once")
    # 9 physique scatter
    ph = rd(tables, "a_sport_physique")
    pts = [(f(r["avg_height_cm"]), f(r["avg_weight_kg"]), 0 if r["sex"] == "M" else 1) for r in ph]
    lab_sports = {"Basketball", "Gymnastics", "Weightlifting", "Rowing", "Athletics", "Diving", "Judo", "Volleyball", "Boxing", "Swimming"}
    labels = {k: short(r["sport"], 14) for k, r in enumerate(ph) if r["sport"] in lab_sports}
    P["physique"] = S.scatter("Average height vs weight by sport, Summer 1992-2016", pts, xlabel="average height (cm)", ylabel="average weight (kg)",
                              labels=labels, groups=["men", "women"], subtitle="one dot per sport x sex (>= 100 athletes with a height)",
                              w=700, h=430, xticks=list(range(150, 205, 5)), xtick_fmt="{:d}")
    hm = sorted([r for r in ph if r["sex"] == "M"], key=lambda r: -f(r["avg_height_cm"]))
    sel = hm[:8] + hm[-7:]
    P["height_by_sport"] = S.hbar("Tallest and shortest sports, men, Summer 1992-2016", [r["sport"] for r in sel], [f(r["avg_height_cm"]) for r in sel],
                                  fmt="{:.1f} cm", color=[BLUE] * 8 + [ORANGE] * 7, vmax=210,
                                  notes=[f"{f(r['avg_weight_kg']):.0f} kg" for r in sel], subtitle="average height, top 8 and bottom 7 sports")
    # 10 age
    ab = {r["age_band"]: r for r in rd(tables, "a_age_band")}
    P["age_medal_rate"] = S.vbar("Medal rate by age band", AGE_ORDER, [f(ab[a]["medal_rate_pct"]) for a in AGE_ORDER], fmt="{:.1f}%",
                                 notes=[f"{i(ab[a]['entries']):,}" for a in AGE_ORDER], color=PURPLE,
                                 subtitle="% of entries that won a medal (official Games, known age); small grey = entries")
    sa = sorted(rd(tables, "a_sport_age"), key=lambda r: f(r["median_medalist_age"]))
    sa = sa[:8] + sa[-8:]
    P["sport_age"] = S.hbar("Median age of medallists by sport, 1992-2016", [f"{r['sport']} ({r['season'][0]})" for r in sa],
                            [f(r["median_medalist_age"]) for r in sa], fmt="{:.1f}", color=[GREEN] * 8 + [BROWN] * 8, vmax=40,
                            notes=[f"range {i(r['youngest_medalist'])}-{i(r['oldest_medalist'])}" for r in sa],
                            subtitle="youngest 8 and oldest 8 sports (>= 100 medal entries); S = Summer, W = Winter")
    # 11 top athletes
    ta = sorted(rd(tables, "a_top_athletes"), key=lambda r: i(r["rnk"]))
    P["top_athletes"] = S.hbar("Most decorated Olympians, 1896-2016", [f"{short(r['athlete_name'], 24)} ({r['noc']})" for r in ta],
                               [i(r["medals"]) for r in ta], fmt="{:.0f}", color=GOLD,
                               notes=[f"{r['sport']}, G{i(r['gold'])} S{i(r['silver'])} B{i(r['bronze'])}" for r in ta])
    # 12 sport dominance
    sd = sorted(rd(tables, "a_sport_dominance"), key=lambda r: -f(r["top_region_pct"]))
    P["sport_dominance"] = S.hbar("Who owns each sport? Top nation's share of golds, Summer 1992-2016", [r["sport"] for r in sd],
                                  [f(r["top_region_pct"]) for r in sd], fmt="{:.0f}%", color=NAVY, vmax=100,
                                  notes=[f"{r['top_region']} ({i(r['top_region_golds'])}/{i(r['sport_golds'])})" for r in sd],
                                  subtitle="sports with >= 40 golds awarded since 1992")
    # 13 data quality
    dq = sorted([r for r in rd(tables, "dq_issues") if i(r["affected_rows"]) > 0 and "two cities" not in r["check_name"]],
                key=lambda r: -i(r["affected_rows"]))
    P["data_quality"] = S.hbar("Data-quality issues found and handled", [short(r["check_name"], 44) for r in dq], [i(r["affected_rows"]) for r in dq],
                               fmt="{:,.0f}", color=ROSE, w=760, subtitle="rows affected in the raw / clean data (see sql/05_quality_checks.sql)")
    for k, p in P.items():
        S.save(p, out / f"{k}.svg")
    cards = [("athletes", f"{i(kpi['athletes']):,}"), ("Games editions", f"{i(kpi['official_games_editions'])}"),
             ("nations (NOCs)", f"{i(kpi['nocs'])}"), ("medals (podium places)", f"{i(kpi['medal_events']):,}"),
             ("women in 2016", f"{f(kpi['female_pct_athletes_2016']):.1f}%"), ("top medals, 1 athlete", f"{i(kpi['most_medals_one_athlete'])}")]
    S.dashboard(out / "dashboard.svg", "da-learn-23 · 120 years of Olympic history (1896-2016)",
                f"{i(kpi['raw_rows']):,} raw athlete-event rows -> {i(kpi['clean_entries']):,} clean; DuckDB SQL pipeline; Databricks skipped (quota)",
                cards, [P["medal_table"], P["women_trend"], P["region_trend_small"] if "region_trend_small" in P else
                        S.line("Share of Summer medals, top 6 nations, 1948-2016", [str(y) for y in sy], [(g, [rv.get((g, y)) for y in sy]) for g in top6],
                               fmt="{:.0f}%", every=4), P["medal_efficiency"],
                        S.grouped_vbar("Home advantage, Summer hosts 1984-2016", [f"{r['year'][2:]} {short(r['host_region'], 9)}" for r in he if i(r['year']) >= 1984],
                                       [("at home", [f(r["host_pct_at_home"]) for r in he if i(r['year']) >= 1984]),
                                        ("other Games avg", [f(r["host_pct_other_games"]) for r in he if i(r['year']) >= 1984])], fmt="{:.0f}"),
                        P["age_medal_rate"]], cols=2)
    print(f"wrote {len(P) + 1} SVG charts to {out}")


if __name__ == "__main__":
    root = pathlib.Path(__file__).resolve().parents[1]
    make_all(root / "results/tables", root / "results/images")
