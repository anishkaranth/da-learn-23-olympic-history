# RESULTS · da-learn-23 · 120 years of Olympic history (1896-2016)

All numbers below come from the **full** dataset (271,116 raw rows) run through `sql/01`-`sql/05` on DuckDB
(1.5.6); nothing is estimated or hand-typed. Databricks was skipped because the workspace hit its resource quota, so there is
no live Lakeview dashboard; the SQL stays Databricks-compatible. Charts: `results/images/` (SVG + PNG).

![Dashboard](images/dashboard.png)

## Headline KPIs
| KPI | Value |
|---|---|
| Raw rows / clean entries | 271,116 / 269,731 |
| Distinct athletes | 135,571 |
| Games editions (official) | 51 (50: 28 Summer + 22 Winter; 1906 excluded) |
| Official events / sports | 715 / 65 |
| NOCs / regions | 230 / 209 |
| Athlete medal rows / podium places (team medal = 1) | 39,158 / 18,556 |
| Entries that won a medal | 14.74% |
| Women among athletes, 1948 / 2016 | 9.65% / 45.03% |
| Athletes 1896 / 2016 | 176 / 11,179 |
| Most medals by one athlete | 28 |
| Assertions | 26/26 PASS |

## Insights
1. **The USA tops the all-time table, but the Soviet Union ruled the Cold War.** Counting each podium place once (a relay gold is one medal, not four), the USA has won 2,792 medals (15.1% of all, 1,115 gold), Russia including the Soviet Union and Unified Team 1,916, and Germany (East + West + unified) 1,731. In 1948-1988 the Russia/Soviet region took 16.7% of medals vs 14.6% for the USA; since 1992 the USA leads again (11.2%) and China has climbed to 4th (6.7%).
2. **Women went from absent to near parity.** No women competed in 1896; they were 9.7% of Summer athletes in 1948 and 45.0% in Rio 2016, when 44.4% of events were women-only. The Games also grew from 176 athletes from 12 nations to 11,179 from 207.
3. **Home advantage is real.** Since 1948 the host won a bigger share of medals at home than its own average at the other same-season Games within 12 years in 32 of 36 Games (median lift 1.61x). The USA took 25.3% of medals in Los Angeles 1984 (Soviet-led boycott) and the Soviet Union 30.9% in Moscow 1980 (US-led boycott); China rose from 7.14% to 10.38% in Beijing 2008. Atlanta 1996 is a rare exception for the USA (12.01% vs 13.9%).
4. **Small teams can be the most efficient.** In the Summer Games of 2000-2016, Kenya won 19.3 medals per 100 athletes sent (53 from 274), ahead of Russia (19.0), USA (18.8) and China (17.4).
5. **Every sport has a body type and an age.** In 1992-2016 male basketball players averaged 199.9 cm and 99.0 kg, female gymnasts 153.9 cm and 45.6 kg, and male weightlifters only 170 cm but 85 kg (BMI 29.0). Medallists are youngest in rhythmic gymnastics (median 18.5) and oldest in equestrianism (median 36). Across all Games, under-18 entries win a medal 9.4% of the time vs 16.7% at 26-29.
6. **Dominance and legends.** China won 77% of all diving golds since 1992 (37 of 48) and the USA 40% of swimming golds. Michael Phelps has 28 medals (23 gold), 10 more than the next athlete, gymnast Larysa Semenivna Latynina (18).

## All-time medal table (top 15, regions)
![Medal table](images/medal_table.png)

| # | Region | Gold | Silver | Bronze | Total | Summer | Winter | % of all |
|---|---|---|---|---|---|---|---|---|
| 1 | USA | 1,115 | 891 | 786 | 2,792 | 2,513 | 279 | 15.05 |
| 2 | Russia | 727 | 600 | 589 | 1,916 | 1,577 | 339 | 10.33 |
| 3 | Germany | 568 | 579 | 584 | 1,731 | 1,354 | 377 | 9.33 |
| 4 | UK | 278 | 304 | 306 | 888 | 861 | 27 | 4.79 |
| 5 | France | 246 | 273 | 313 | 832 | 723 | 109 | 4.48 |
| 6 | Italy | 244 | 212 | 236 | 692 | 578 | 114 | 3.73 |
| 7 | Sweden | 196 | 210 | 233 | 639 | 495 | 144 | 3.44 |
| 8 | China | 240 | 185 | 173 | 598 | 545 | 53 | 3.22 |
| 9 | Australia | 156 | 174 | 198 | 528 | 515 | 13 | 2.85 |
| 10 | Hungary | 175 | 149 | 172 | 496 | 490 | 6 | 2.67 |
| 11 | Japan | 152 | 151 | 177 | 480 | 435 | 45 | 2.59 |
| 12 | Norway | 169 | 157 | 148 | 474 | 155 | 319 | 2.55 |
| 13 | Canada | 125 | 158 | 188 | 471 | 301 | 170 | 2.54 |
| 14 | Finland | 141 | 146 | 175 | 462 | 301 | 161 | 2.49 |
| 15 | Netherlands | 123 | 133 | 144 | 400 | 290 | 110 | 2.16 |

By NOC (historic teams kept separate), the top five are:
| # | NOC | Region | Gold | Total | First | Last |
|---|---|---|---|---|---|---|
| 1 | USA | USA | 1,115 | 2,792 | 1,896 | 2,016 |
| 2 | URS | Russia | 471 | 1,197 | 1,952 | 1,988 |
| 3 | GER | Germany | 309 | 969 | 1,896 | 2,016 |
| 4 | GBR | UK | 278 | 888 | 1,896 | 2,016 |
| 5 | FRA | France | 246 | 832 | 1,896 | 2,016 |

## Medal share by era
![Medal share by era](images/medal_era.png)
![Region trend](images/region_trend.png)

## Home advantage
![Host effect](images/host_effect.png)

| Games | Host | Medals | % at home | % other Games (avg) | Lift |
|---|---|---|---|---|---|
| 1948 Summer | UK | 23 | 5.65 | 3.87 | 1.46 |
| 1948 Winter | Switzerland | 9 | 13.64 | 4.95 | 2.75 |
| 1952 Summer | Finland | 22 | 4.81 | 2.43 | 1.98 |
| 1952 Winter | Norway | 16 | 23.88 | 10.69 | 2.23 |
| 1956 Summer | Australia | 35 | 7.49 | 3.44 | 2.18 |
| 1956 Winter | Italy | 3 | 4.23 | 2.69 | 1.57 |
| 1960 Summer | Italy | 36 | 7.81 | 4.67 | 1.67 |
| 1960 Winter | USA | 10 | 12.35 | 9.6 | 1.29 |
| 1964 Summer | Japan | 29 | 5.79 | 3.83 | 1.51 |
| 1964 Winter | Austria | 12 | 11.65 | 9.26 | 1.26 |
| 1968 Summer | Mexico | 9 | 1.71 | 0.33 | 5.18 |
| 1968 Winter | France | 9 | 8.65 | 2.52 | 3.43 |
| 1972 Summer | Germany | 106 | 17.67 | 13.07 | 1.35 |
| 1972 Winter | Japan | 3 | 2.86 | 0.29 | 9.85 |
| 1976 Summer | Canada | 11 | 1.79 | 1.73 | 1.04 |
| 1976 Winter | Austria | 6 | 5.41 | 6.86 | 0.79 |
| 1980 Summer | Russia | 195 | 30.9 | 14.28 | 2.16 |
| 1980 Winter | USA | 12 | 10.43 | 6.53 | 1.6 |
| 1984 Summer | USA | 173 | 25.26 | 11.5 | 2.2 |
| 1984 Winter | Serbia | 1 | 0.85 | 0.36 | 2.37 |
| 1988 Summer | South Korea | 33 | 4.47 | 2.26 | 1.98 |
| 1988 Winter | Canada | 5 | 3.62 | 4.45 | 0.81 |
| 1992 Summer | Spain | 22 | 2.7 | 1.27 | 2.13 |
| 1992 Winter | France | 9 | 5.36 | 2.72 | 1.97 |
| 1994 Winter | Norway | 23 | 12.78 | 8.36 | 1.53 |
| 1996 Summer | USA | 101 | 12.01 | 13.9 | 0.86 |
| 1998 Winter | Japan | 10 | 4.95 | 1.81 | 2.74 |
| 2000 Summer | Australia | 58 | 6.27 | 3.98 | 1.58 |
| 2002 Winter | USA | 34 | 14.59 | 8.99 | 1.62 |
| 2004 Summer | Greece | 16 | 1.73 | 0.64 | 2.7 |
| 2006 Winter | Italy | 11 | 4.37 | 5.26 | 0.83 |
| 2008 Summer | China | 100 | 10.38 | 7.14 | 1.45 |
| 2010 Winter | Canada | 26 | 10.08 | 8.18 | 1.23 |
| 2012 Summer | UK | 65 | 6.76 | 4.53 | 1.49 |
| 2014 Winter | Russia | 33 | 11.19 | 6.71 | 1.67 |
| 2016 Summer | Brazil | 19 | 1.95 | 1.5 | 1.3 |

## Women and growth
![Women](images/women_trend.png)
![Participation](images/participation.png)
![Nations](images/nations_trend.png)

## Efficiency (Summer 2000-2016)
![Efficiency](images/medal_efficiency.png)

| Region | Athlete-Games | Medals | Gold | Medals / 100 athletes |
|---|---|---|---|---|
| Kenya | 274 | 53 | 17 | 19.34 |
| Russia | 2,048 | 389 | 126 | 18.99 |
| USA | 2,792 | 526 | 200 | 18.84 |
| China | 2,195 | 381 | 175 | 17.36 |
| Cuba | 764 | 105 | 32 | 13.74 |
| UK | 1,768 | 238 | 95 | 13.46 |
| Romania | 554 | 66 | 26 | 11.91 |
| France | 1,669 | 189 | 52 | 11.32 |
| Germany | 2,084 | 234 | 72 | 11.23 |
| South Korea | 1,267 | 138 | 52 | 10.89 |
| Japan | 1,530 | 159 | 49 | 10.39 |
| Kazakhstan | 588 | 59 | 16 | 10.03 |
| Uzbekistan | 318 | 31 | 9 | 9.75 |
| Netherlands | 1,088 | 104 | 37 | 9.56 |
| Bulgaria | 370 | 35 | 8 | 9.46 |

## Body type and age
![Physique](images/physique.png)
![Height by sport](images/height_by_sport.png)
![Age medal rate](images/age_medal_rate.png)
![Sport age](images/sport_age.png)

| Age band | Entries | Medal entries | Medal rate % |
|---|---|---|---|
| <18 | 12,467 | 1,168 | 9.37 |
| 18-21 | 54,039 | 6,866 | 12.71 |
| 22-25 | 83,648 | 12,844 | 15.35 |
| 26-29 | 58,799 | 9,823 | 16.71 |
| 30-34 | 31,684 | 5,237 | 16.53 |
| 35-39 | 10,160 | 1,535 | 15.11 |
| 40+ | 6,746 | 1,112 | 16.48 |

## Sport dominance and legends
![Sport dominance](images/sport_dominance.png)
![Top athletes](images/top_athletes.png)

| # | Athlete | NOC | Sport | First | Last | G | S | B | Total |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Michael Fred Phelps, II | USA | Swimming | 2,000 | 2,016 | 23 | 3 | 2 | 28 |
| 2 | Larysa Semenivna Latynina (Diriy-) | URS | Gymnastics | 1,956 | 1,964 | 9 | 5 | 4 | 18 |
| 3 | Nikolay Yefimovich Andrianov | URS | Gymnastics | 1,972 | 1,980 | 7 | 5 | 3 | 15 |
| 4 | Ole Einar Bjrndalen | NOR | Biathlon | 1,994 | 2,014 | 8 | 4 | 1 | 13 |
| 5 | Borys Anfiyanovych Shakhlin | URS | Gymnastics | 1,956 | 1,964 | 7 | 4 | 2 | 13 |
| 6 | Edoardo Mangiarotti | ITA | Fencing | 1,936 | 1,960 | 6 | 5 | 2 | 13 |
| 7 | Takashi Ono | JPN | Gymnastics | 1,952 | 1,964 | 5 | 4 | 4 | 13 |
| 8 | Paavo Johannes Nurmi | FIN | Athletics | 1,920 | 1,928 | 9 | 3 | 0 | 12 |
| 9 | Birgit Fischer-Schmidt | GER | Canoeing | 1,980 | 2,004 | 8 | 4 | 0 | 12 |
| 10 | Sawao Kato | JPN | Gymnastics | 1,968 | 1,976 | 8 | 3 | 1 | 12 |

## Data quality
![Data quality](images/data_quality.png)

**Row counts**

| entity | raw_rows | distinct_rows | clean_rows | grain |
|---|---|---|---|---|
| athlete_events rows | 271,116 | 269,731 | 269,731 | athlete x event x Games |
| dim_athlete |  |  | 135,571 | athlete id |
| dim_event |  |  | 765 | sport x event |
| dim_games |  |  | 51 | Games edition |
| dim_noc |  |  | 231 | NOC code |
| fact_entry |  |  | 269,731 | athlete x event x Games |
| fact_medal (team-deduplicated podium places) | 39,772 |  | 18,927 | Games x event x NOC x team entry x medal |
| noc_regions rows | 230 |  | 231 | NOC code |

**Issues found and how they were handled**

| check_name | affected_rows |
|---|---|
| 1906 Intercalated Games rows (excluded, not IOC-recognised) | 1,733 |
| Art Competitions rows (excluded from sport analysis) | 2,263 |
| BMI < 15 or > 60 (flagged, left out of BMI averages) | 108 |
| Games played in two cities (1956 Summer: Melbourne + Stockholm) | 1 |
| NOC SGP missing from noc_regions (override -> Singapore) | 349 |
| RI: entries lost in dim joins | 0 |
| age 65+ (kept: mostly art, equestrian, sailing, shooting) | 177 |
| age under 13 (kept) | 53 |
| athlete ids with more than one name spelling | 0 |
| athlete medal rows collapsed into team podium places | 20,845 |
| exact duplicate rows dropped | 1,385 |
| official events with more than one gold (ties / shared golds) | 50 |
| official events with no gold recorded | 13 |
| region literal NA (ROT/TUV/UNK, notes used) | 21 |
| repeat rows: same athlete, Games, event, team (1900/1908 races + several art works; kept) | 139 |
| rows with unparseable id / year dropped | 0 |
| team names with -1/-2 suffix (second boats/crews) normalised | 6,114 |

**Null rates**

| entity | column_name | null_pct | treatment |
|---|---|---|---|
| entries | Age | 3.45 | NA -> NULL, left out of age views |
| entries | Height | 21.8 | NA -> NULL |
| entries | Height (Summer 1992-2016) | 5.36 | physique views use 1992-2016 only |
| entries | Height (before 1960) | 78.63 | mostly unknown for early Games |
| entries | Medal | 85.25 | NA = no medal (not missing) |
| entries | Weight | 22.81 | NA -> NULL |
| entries | region (after NOC mapping) | 0 | SGP override added |

**Assertions (26/26 PASS)**

| check_name | failed_rows | status |
|---|---|---|
| BMI flagged outliers are NULL in fact_entry | 0 | PASS |
| Games label = year + season | 0 | PASS |
| age within 10..97 when known | 0 | PASS |
| at most 3 medal ranks | 0 | PASS |
| clean rows = distinct raw rows | 0 | PASS |
| dim_games has 51 editions (28 Summer + 1906 Intercalated + 22 Winter) | 0 | PASS |
| entry_key unique | 0 | PASS |
| event name starts with sport name | 0 | PASS |
| every Games edition has a host nation | 0 | PASS |
| every NOC maps to a region | 0 | PASS |
| fact_entry athlete ids exist in dim_athlete | 0 | PASS |
| fact_entry keeps every clean entry (RI) | 0 | PASS |
| fact_medal keys exist in dim_games and dim_event | 0 | PASS |
| height within 120..230 cm when known | 0 | PASS |
| medal events <= athlete medal rows | 0 | PASS |
| medal in {Gold,Silver,Bronze,NA} | 0 | PASS |
| medal rows reconcile (fact_medal athletes = medal entries) | 0 | PASS |
| no exact duplicate entries left | 0 | PASS |
| one city per Games except 1956 Summer | 0 | PASS |
| one row per athlete x Games x event x team after 1908 (art works excepted) | 0 | PASS |
| one sex per athlete id | 0 | PASS |
| region medal table total = official medal events | 0 | PASS |
| season in {Summer,Winter} | 0 | PASS |
| sex in {M,F} | 0 | PASS |
| weight within 20..220 kg when known | 0 | PASS |
| year in 1896..2016 | 0 | PASS |

## How the images were made
`scripts/make_charts.py` reads the DuckDB query results exported to `results/tables/*.csv` and writes every chart as a plain-vector SVG with the
small custom writer `scripts/svgcharts.py` (rect, line, polyline, circle and text only; no plotting library, no embedded raster).
`scripts/render_png.py` then rasterises each SVG to a PNG at 2x with headless Google Chrome. Both versions are committed in `results/images/`.

## Files
`metrics.json` (KPIs, data-quality evidence, engine, SQL timings), `JSON.shot` (headline snapshot + run config), `tables/` (every `a_*` and
`dq_*` table as CSV), `images/` (SVG + PNG), `sample/` (the same pipeline on the committed raw sample).
