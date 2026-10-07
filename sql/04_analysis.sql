-- 04_analysis.sql  KPIs and business questions (Spark SQL dialect). Unless a table says otherwise, analysis uses the official
-- Games only: the 1906 Intercalated Games (not recognised by the IOC) and the 1912-1948 Art Competitions are excluded.
-- Medal counts use fact_medal / cln_medal_events (one medal per podium place, team members not multiplied).

-- helper: official medal events with era
CREATE OR REPLACE TEMP VIEW v_medals AS
SELECT m.*, CASE WHEN yr < 1940 THEN '1896-1936' WHEN yr < 1990 THEN '1948-1988' ELSE '1992-2016' END AS era
FROM cln_medal_events m WHERE is_official = 1;

CREATE OR REPLACE TEMP VIEW v_entries AS
SELECT * FROM cln_entries WHERE is_official = 1;

-- Q1 headline KPIs
CREATE OR REPLACE TABLE a_kpi_headline AS
SELECT
  (SELECT COUNT(*) FROM stg_athlete_events)                                   AS raw_rows,
  (SELECT COUNT(*) FROM cln_entries)                                          AS clean_entries,
  (SELECT COUNT(DISTINCT athlete_id) FROM cln_entries)                        AS athletes,
  (SELECT COUNT(DISTINCT games) FROM cln_entries)                             AS games_editions,
  (SELECT COUNT(DISTINCT games) FROM v_entries)                               AS official_games_editions,
  (SELECT COUNT(DISTINCT games) FROM v_entries WHERE season = 'Summer')       AS summer_games,
  (SELECT COUNT(DISTINCT games) FROM v_entries WHERE season = 'Winter')       AS winter_games,
  (SELECT COUNT(DISTINCT event) FROM v_entries)                               AS official_events,
  (SELECT COUNT(DISTINCT sport) FROM v_entries)                               AS official_sports,
  (SELECT COUNT(DISTINCT noc) FROM cln_entries)                               AS nocs,
  (SELECT COUNT(DISTINCT region) FROM cln_entries)                            AS regions,
  (SELECT SUM(is_medal) FROM v_entries)                                       AS athlete_medal_rows,
  (SELECT COUNT(*) FROM v_medals)                                             AS medal_events,
  (SELECT ROUND(100.0 * SUM(is_medal) / COUNT(*), 2) FROM v_entries)          AS pct_entries_medal,
  (SELECT ROUND(100.0 * COUNT(DISTINCT CASE WHEN sex = 'F' THEN athlete_id END) / COUNT(DISTINCT athlete_id), 2)
     FROM v_entries WHERE games = '2016 Summer')                              AS female_pct_athletes_2016,
  (SELECT ROUND(100.0 * COUNT(DISTINCT CASE WHEN sex = 'F' THEN athlete_id END) / COUNT(DISTINCT athlete_id), 2)
     FROM v_entries WHERE games = '1948 Summer')                              AS female_pct_athletes_1948,
  (SELECT COUNT(DISTINCT athlete_id) FROM v_entries WHERE games = '2016 Summer') AS athletes_2016,
  (SELECT COUNT(DISTINCT athlete_id) FROM v_entries WHERE games = '1896 Summer') AS athletes_1896,
  (SELECT MAX(medals) FROM cln_athletes)                                      AS most_medals_one_athlete,
  (SELECT MIN(yr) FROM cln_entries)                                           AS first_year,
  (SELECT MAX(yr) FROM cln_entries)                                           AS last_year;

-- Q2 every Games edition: size, nations, events, women
CREATE OR REPLACE TABLE a_games AS
SELECT e.games, e.yr AS year, e.season, max(e.host_city) AS host_city, max(e.host_region) AS host_region,
       COUNT(DISTINCT e.athlete_id) AS athletes,
       COUNT(DISTINCT CASE WHEN e.sex = 'F' THEN e.athlete_id END) AS female_athletes,
       ROUND(100.0 * COUNT(DISTINCT CASE WHEN e.sex = 'F' THEN e.athlete_id END) / COUNT(DISTINCT e.athlete_id), 2) AS female_pct,
       COUNT(DISTINCT e.noc) AS nocs, COUNT(DISTINCT e.sport) AS sports, COUNT(DISTINCT e.event) AS events,
       COUNT(DISTINCT CASE WHEN e.event_gender = 'Women' THEN e.event END) AS women_events,
       ROUND(100.0 * COUNT(DISTINCT CASE WHEN e.event_gender = 'Women' THEN e.event END) / COUNT(DISTINCT e.event), 2) AS women_events_pct,
       (SELECT COUNT(*) FROM v_medals m WHERE m.games = e.games) AS medals_awarded,
       (SELECT COUNT(DISTINCT m.region) FROM v_medals m WHERE m.games = e.games) AS regions_with_medal
FROM v_entries e
GROUP BY e.games, e.yr, e.season;

-- Q3 all-time medal table by region (Soviet Union / Unified Team -> Russia, East/West Germany -> Germany, as in noc_regions.csv)
CREATE OR REPLACE TABLE a_medal_table AS
SELECT ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC, SUM(CASE WHEN medal = 'Gold' THEN 1 ELSE 0 END) DESC) AS rnk, region,
       SUM(CASE WHEN medal = 'Gold' THEN 1 ELSE 0 END) AS gold, SUM(CASE WHEN medal = 'Silver' THEN 1 ELSE 0 END) AS silver,
       SUM(CASE WHEN medal = 'Bronze' THEN 1 ELSE 0 END) AS bronze, COUNT(*) AS total,
       SUM(CASE WHEN season = 'Summer' THEN 1 ELSE 0 END) AS summer_total, SUM(CASE WHEN season = 'Winter' THEN 1 ELSE 0 END) AS winter_total,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM v_medals), 2) AS pct_all_medals,
       COUNT(DISTINCT games) AS games_with_medal
FROM v_medals GROUP BY region;

-- Q3b medal table by NOC (historic teams kept separate: URS, GDR, FRG, EUN ...)
CREATE OR REPLACE TABLE a_medal_table_noc AS
SELECT ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rnk, noc, max(region) AS region,
       SUM(CASE WHEN medal = 'Gold' THEN 1 ELSE 0 END) AS gold, COUNT(*) AS total, min(yr) AS first_medal_year, max(yr) AS last_medal_year
FROM v_medals GROUP BY noc;

-- Q4 medal share by era (top 10 regions per era)
CREATE OR REPLACE TABLE a_medal_era AS
SELECT * FROM (
  SELECT era, region, COUNT(*) AS medals, SUM(CASE WHEN medal = 'Gold' THEN 1 ELSE 0 END) AS gold,
         ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY era), 2) AS pct_era_medals,
         ROW_NUMBER() OVER (PARTITION BY era ORDER BY COUNT(*) DESC) AS rnk
  FROM v_medals GROUP BY era, region) x
WHERE rnk <= 10;

-- Q5 medals per Summer Games for the six biggest medal-winning regions
CREATE OR REPLACE TABLE a_region_trend AS
SELECT m.yr AS year, m.region, COUNT(*) AS medals,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM v_medals t WHERE t.games = m.games), 2) AS pct_games_medals
FROM v_medals m
WHERE m.season = 'Summer' AND m.region IN (SELECT region FROM a_medal_table WHERE rnk <= 6)
GROUP BY m.yr, m.region, m.games;

-- Q6 host-nation effect: host's medal share at home vs its average share at the other same-season Games within 12 years
CREATE OR REPLACE TABLE a_host_effect AS
WITH share AS (
  SELECT games, yr, season, region, COUNT(*) AS medals,
         100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY games) AS pct
  FROM v_medals GROUP BY games, yr, season, region
),
hosts AS (SELECT DISTINCT games, yr, season, host_region, host_city FROM v_entries WHERE host_region IS NOT NULL),
other AS (
  SELECT h.games, ROUND(AVG(COALESCE(o.pct, 0)), 2) AS host_pct_other_games, COUNT(*) AS comparison_games
  FROM hosts h
  JOIN hosts g ON g.season = h.season AND g.games <> h.games AND abs(g.yr - h.yr) <= 12
  LEFT JOIN share o ON o.games = g.games AND o.region = h.host_region
  GROUP BY h.games
)
SELECT h.games, h.yr AS year, h.season, h.host_city, h.host_region,
       COALESCE(s.medals, 0) AS host_medals, ROUND(COALESCE(s.pct, 0), 2) AS host_pct_at_home,
       x.host_pct_other_games, x.comparison_games,
       ROUND(COALESCE(s.pct, 0) / NULLIF(x.host_pct_other_games, 0), 2) AS home_lift
FROM hosts h
LEFT JOIN share s ON s.games = h.games AND s.region = h.host_region
LEFT JOIN other x ON x.games = h.games;

-- Q7 women at the Games (Summer and Winter): athlete share and events for women
CREATE OR REPLACE TABLE a_women AS
SELECT year, season, athletes, female_athletes, female_pct, events, women_events, women_events_pct FROM a_games;

-- Q8 body type by sport: modern Summer Games 1992-2016, one row per athlete x Games x sport, BMI outliers excluded
CREATE OR REPLACE TABLE a_sport_physique AS
WITH ag AS (
  SELECT sport, sex, athlete_id, games, max(height_cm) AS h, max(weight_kg) AS w, max(CASE WHEN dq_bmi_outlier = 0 THEN bmi END) AS b,
         max(age) AS a
  FROM v_entries WHERE season = 'Summer' AND yr >= 1992 GROUP BY sport, sex, athlete_id, games
)
SELECT sport, sex, COUNT(*) AS athlete_games, COUNT(h) AS with_height,
       ROUND(AVG(h), 1) AS avg_height_cm, ROUND(AVG(w), 1) AS avg_weight_kg, ROUND(AVG(b), 2) AS avg_bmi, ROUND(AVG(a), 1) AS avg_age
FROM ag GROUP BY sport, sex HAVING COUNT(h) >= 100;

-- Q9 age: medal rate by age band (official Games, entries with a known age)
CREATE OR REPLACE TABLE a_age_band AS
SELECT CASE WHEN age < 18 THEN '<18' WHEN age < 22 THEN '18-21' WHEN age < 26 THEN '22-25' WHEN age < 30 THEN '26-29'
            WHEN age < 35 THEN '30-34' WHEN age < 40 THEN '35-39' ELSE '40+' END AS age_band,
       min(age) AS min_age, COUNT(*) AS entries, SUM(is_medal) AS medal_entries, ROUND(100.0 * SUM(is_medal) / COUNT(*), 2) AS medal_rate_pct
FROM v_entries WHERE age IS NOT NULL
GROUP BY 1;

-- Q9b youngest and oldest sports: median age of medal-winning entries, Summer + Winter 1992-2016
CREATE OR REPLACE TABLE a_sport_age AS
SELECT sport, season, COUNT(*) AS medal_entries, ROUND(percentile_approx(age, 0.5), 1) AS median_medalist_age,
       min(age) AS youngest_medalist, max(age) AS oldest_medalist
FROM v_entries WHERE yr >= 1992 AND is_medal = 1 AND age IS NOT NULL
GROUP BY sport, season HAVING COUNT(*) >= 100;

-- Q10 most decorated athletes (official Games, athlete medal rows)
CREATE OR REPLACE TABLE a_top_athletes AS
SELECT ROW_NUMBER() OVER (ORDER BY SUM(is_medal) DESC, SUM(CASE WHEN medal = 'Gold' THEN 1 ELSE 0 END) DESC, athlete_id) AS rnk,
       athlete_id, max(athlete_name) AS athlete_name, max(noc) AS noc, max_by(sport, yr) AS sport, min(yr) AS first_year, max(yr) AS last_year,
       SUM(CASE WHEN medal = 'Gold' THEN 1 ELSE 0 END) AS gold, SUM(CASE WHEN medal = 'Silver' THEN 1 ELSE 0 END) AS silver,
       SUM(CASE WHEN medal = 'Bronze' THEN 1 ELSE 0 END) AS bronze, SUM(is_medal) AS medals
FROM v_entries GROUP BY athlete_id
QUALIFY rnk <= 15;

-- Q11 medal efficiency: Summer 2000-2016, medals per 100 athletes sent (regions with >= 250 athlete-Games)
CREATE OR REPLACE TABLE a_medal_efficiency AS
WITH sent AS (SELECT region, COUNT(DISTINCT concat(CAST(athlete_id AS STRING), '-', games)) AS athlete_games
              FROM v_entries WHERE season = 'Summer' AND yr >= 2000 GROUP BY region),
won AS (SELECT region, COUNT(*) AS medals, SUM(CASE WHEN medal = 'Gold' THEN 1 ELSE 0 END) AS gold
        FROM v_medals WHERE season = 'Summer' AND yr >= 2000 GROUP BY region)
SELECT s.region, s.athlete_games, COALESCE(w.medals, 0) AS medals, COALESCE(w.gold, 0) AS gold,
       ROUND(100.0 * COALESCE(w.medals, 0) / s.athlete_games, 2) AS medals_per_100_athletes
FROM sent s LEFT JOIN won w ON s.region = w.region
WHERE s.athlete_games >= 250;

-- Q12 who dominates each sport: top region's share of golds, Summer 1992-2016 (sports with >= 40 golds)
CREATE OR REPLACE TABLE a_sport_dominance AS
WITH g AS (SELECT sport, region, COUNT(*) AS golds FROM v_medals WHERE season = 'Summer' AND yr >= 1992 AND medal = 'Gold' GROUP BY sport, region),
r AS (SELECT sport, region, golds, SUM(golds) OVER (PARTITION BY sport) AS sport_golds,
             ROW_NUMBER() OVER (PARTITION BY sport ORDER BY golds DESC, region) AS rn FROM g)
SELECT sport, region AS top_region, golds AS top_region_golds, sport_golds, ROUND(100.0 * golds / sport_golds, 2) AS top_region_pct
FROM r WHERE rn = 1 AND sport_golds >= 40;
