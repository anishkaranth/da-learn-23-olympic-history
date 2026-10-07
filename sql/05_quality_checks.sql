-- 05_quality_checks.sql  Data-quality evidence: before/after counts, issue counts, null rates, assertions (Spark SQL dialect)

CREATE OR REPLACE TABLE dq_row_counts AS
SELECT 'athlete_events rows' AS entity, (SELECT COUNT(*) FROM stg_athlete_events) AS raw_rows,
       (SELECT COUNT(*) FROM cln_dedup) AS distinct_rows, (SELECT COUNT(*) FROM cln_entries) AS clean_rows, 'athlete x event x Games' AS grain
UNION ALL SELECT 'noc_regions rows', (SELECT COUNT(*) FROM stg_noc_regions), NULL, (SELECT COUNT(*) FROM cln_noc), 'NOC code'
UNION ALL SELECT 'fact_entry', NULL, NULL, (SELECT COUNT(*) FROM fact_entry), 'athlete x event x Games'
UNION ALL SELECT 'fact_medal (team-deduplicated podium places)', (SELECT SUM(is_medal) FROM cln_entries), NULL, (SELECT COUNT(*) FROM fact_medal),
       'Games x event x NOC x team entry x medal'
UNION ALL SELECT 'dim_athlete', NULL, NULL, (SELECT COUNT(*) FROM dim_athlete), 'athlete id'
UNION ALL SELECT 'dim_games', NULL, NULL, (SELECT COUNT(*) FROM dim_games), 'Games edition'
UNION ALL SELECT 'dim_event', NULL, NULL, (SELECT COUNT(*) FROM dim_event), 'sport x event'
UNION ALL SELECT 'dim_noc', NULL, NULL, (SELECT COUNT(*) FROM dim_noc), 'NOC code';

CREATE OR REPLACE TABLE dq_null_rates AS
SELECT 'entries' AS entity, 'Age' AS column_name, ROUND(100.0 * SUM(CASE WHEN age IS NULL THEN 1 ELSE 0 END) / COUNT(*), 3) AS null_pct,
       'NA -> NULL, left out of age views' AS treatment FROM cln_entries
UNION ALL SELECT 'entries', 'Height', ROUND(100.0 * SUM(CASE WHEN height_cm IS NULL THEN 1 ELSE 0 END) / COUNT(*), 3), 'NA -> NULL' FROM cln_entries
UNION ALL SELECT 'entries', 'Weight', ROUND(100.0 * SUM(CASE WHEN weight_kg IS NULL THEN 1 ELSE 0 END) / COUNT(*), 3), 'NA -> NULL' FROM cln_entries
UNION ALL SELECT 'entries', 'Height (Summer 1992-2016)', ROUND(100.0 * SUM(CASE WHEN height_cm IS NULL THEN 1 ELSE 0 END) / COUNT(*), 3),
       'physique views use 1992-2016 only' FROM cln_entries WHERE season = 'Summer' AND yr >= 1992
UNION ALL SELECT 'entries', 'Height (before 1960)', ROUND(100.0 * SUM(CASE WHEN height_cm IS NULL THEN 1 ELSE 0 END) / COUNT(*), 3),
       'mostly unknown for early Games' FROM cln_entries WHERE yr < 1960
UNION ALL SELECT 'entries', 'Medal', ROUND(100.0 * SUM(CASE WHEN medal IS NULL THEN 1 ELSE 0 END) / COUNT(*), 3), 'NA = no medal (not missing)' FROM cln_entries
UNION ALL SELECT 'entries', 'region (after NOC mapping)', ROUND(100.0 * SUM(dq_noc_unmapped) / COUNT(*), 3), 'SGP override added' FROM cln_entries;

CREATE OR REPLACE TABLE dq_issues AS
SELECT 'exact duplicate rows dropped' AS check_name, (SELECT COUNT(*) FROM stg_athlete_events) - (SELECT COUNT(*) FROM cln_dedup) AS affected_rows
UNION ALL SELECT 'rows with unparseable id / year dropped', (SELECT COUNT(*) FROM cln_typed WHERE athlete_id IS NULL OR yr IS NULL)
UNION ALL SELECT 'NOC SGP missing from noc_regions (override -> Singapore)', (SELECT COUNT(*) FROM cln_entries WHERE noc = 'SGP')
UNION ALL SELECT 'region literal NA (ROT/TUV/UNK, notes used)', (SELECT COUNT(*) FROM cln_entries WHERE noc IN ('ROT', 'TUV', 'UNK'))
UNION ALL SELECT 'team names with -1/-2 suffix (second boats/crews) normalised', (SELECT SUM(dq_team_suffix) FROM cln_entries)
UNION ALL SELECT 'Art Competitions rows (excluded from sport analysis)', (SELECT SUM(is_art) FROM cln_entries)
UNION ALL SELECT '1906 Intercalated Games rows (excluded, not IOC-recognised)', (SELECT SUM(is_intercalated) FROM cln_entries)
UNION ALL SELECT 'athlete medal rows collapsed into team podium places', (SELECT SUM(is_medal) FROM cln_entries) - (SELECT COUNT(*) FROM fact_medal)
UNION ALL SELECT 'BMI < 15 or > 60 (flagged, left out of BMI averages)', (SELECT SUM(dq_bmi_outlier) FROM cln_entries)
UNION ALL SELECT 'age 65+ (kept: mostly art, equestrian, sailing, shooting)', (SELECT SUM(dq_age_65_plus) FROM cln_entries)
UNION ALL SELECT 'age under 13 (kept)', (SELECT SUM(dq_age_under_13) FROM cln_entries)
UNION ALL SELECT 'Games played in two cities (1956 Summer: Melbourne + Stockholm)', (SELECT COUNT(*) FROM (SELECT games FROM cln_entries GROUP BY games HAVING COUNT(DISTINCT city) > 1) x)
UNION ALL SELECT 'official events with more than one gold (ties / shared golds)', (SELECT COUNT(*) FROM (SELECT games, event FROM cln_medal_events
         WHERE medal = 'Gold' AND is_official = 1 GROUP BY games, event HAVING COUNT(*) > 1) x)
UNION ALL SELECT 'official events with no gold recorded', (SELECT COUNT(*) FROM (SELECT games, event FROM cln_entries WHERE is_official = 1
         GROUP BY games, event HAVING SUM(CASE WHEN medal = 'Gold' THEN 1 ELSE 0 END) = 0) x)
UNION ALL SELECT 'repeat rows: same athlete, Games, event, team (1900/1908 races + several art works; kept)', (SELECT SUM(n) FROM (SELECT COUNT(*) AS n
         FROM cln_entries GROUP BY athlete_id, games, event, team_raw HAVING COUNT(*) > 1) x)
UNION ALL SELECT 'athlete ids with more than one name spelling', (SELECT COUNT(*) FROM cln_athletes WHERE n_names > 1)
UNION ALL SELECT 'RI: entries lost in dim joins', (SELECT COUNT(*) FROM cln_entries) - (SELECT COUNT(*) FROM fact_entry);

CREATE OR REPLACE TABLE dq_assertions AS
WITH c AS (
  SELECT 'clean rows = distinct raw rows' AS check_name, (SELECT ABS((SELECT COUNT(*) FROM cln_entries) - (SELECT COUNT(*) FROM (SELECT DISTINCT * FROM stg_athlete_events) d))) AS failed_rows
  UNION ALL SELECT 'no exact duplicate entries left', (SELECT COUNT(*) FROM (SELECT athlete_id, games, event, team_raw, city, medal, age, height_cm, weight_kg
         FROM cln_entries GROUP BY ALL HAVING COUNT(*) > 1) x)
  UNION ALL SELECT 'entry_key unique', (SELECT COUNT(*) - COUNT(DISTINCT entry_key) FROM cln_entries)
  UNION ALL SELECT 'sex in {M,F}', (SELECT COUNT(*) FROM cln_entries WHERE sex NOT IN ('M', 'F'))
  UNION ALL SELECT 'one sex per athlete id', (SELECT COUNT(*) FROM cln_athletes WHERE n_sexes > 1)
  UNION ALL SELECT 'season in {Summer,Winter}', (SELECT COUNT(*) FROM cln_entries WHERE season NOT IN ('Summer', 'Winter'))
  UNION ALL SELECT 'Games label = year + season', (SELECT SUM(dq_games_mismatch) FROM cln_entries)
  UNION ALL SELECT 'year in 1896..2016', (SELECT COUNT(*) FROM cln_entries WHERE yr < 1896 OR yr > 2016)
  UNION ALL SELECT 'event name starts with sport name', (SELECT SUM(dq_event_sport_mismatch) FROM cln_entries)
  UNION ALL SELECT 'medal in {Gold,Silver,Bronze,NA}', (SELECT SUM(dq_bad_medal) FROM cln_entries)
  UNION ALL SELECT 'age within 10..97 when known', (SELECT COUNT(*) FROM cln_entries WHERE age < 10 OR age > 97)
  UNION ALL SELECT 'height within 120..230 cm when known', (SELECT COUNT(*) FROM cln_entries WHERE height_cm < 120 OR height_cm > 230)
  UNION ALL SELECT 'weight within 20..220 kg when known', (SELECT COUNT(*) FROM cln_entries WHERE weight_kg < 20 OR weight_kg > 220)
  UNION ALL SELECT 'every NOC maps to a region', (SELECT SUM(dq_noc_unmapped) FROM cln_entries)
  UNION ALL SELECT 'every Games edition has a host nation', (SELECT COUNT(*) FROM cln_entries WHERE host_region IS NULL)
  UNION ALL SELECT 'one city per Games except 1956 Summer', (SELECT COUNT(*) FROM (SELECT games FROM cln_entries WHERE games <> '1956 Summer'
         GROUP BY games HAVING COUNT(DISTINCT city) > 1) x)
  UNION ALL SELECT 'one row per athlete x Games x event x team after 1908 (art works excepted)', (SELECT COUNT(*) FROM (SELECT athlete_id, games, event, team_raw
         FROM cln_entries WHERE yr > 1908 AND is_art = 0 GROUP BY athlete_id, games, event, team_raw HAVING COUNT(*) > 1) x)
  UNION ALL SELECT 'medal events <= athlete medal rows', (SELECT CASE WHEN (SELECT COUNT(*) FROM fact_medal) <= (SELECT SUM(is_medal) FROM cln_entries) THEN 0 ELSE 1 END)
  UNION ALL SELECT 'medal rows reconcile (fact_medal athletes = medal entries)', (SELECT ABS((SELECT SUM(athletes_on_entry) FROM fact_medal) - (SELECT SUM(is_medal) FROM cln_entries)))
  UNION ALL SELECT 'fact_entry keeps every clean entry (RI)', (SELECT ABS((SELECT COUNT(*) FROM cln_entries) - (SELECT COUNT(*) FROM fact_entry)))
  UNION ALL SELECT 'fact_entry athlete ids exist in dim_athlete', (SELECT COUNT(*) FROM fact_entry f LEFT JOIN dim_athlete a ON f.athlete_id = a.athlete_id WHERE a.athlete_id IS NULL)
  UNION ALL SELECT 'fact_medal keys exist in dim_games and dim_event', (SELECT COUNT(*) FROM fact_medal f LEFT JOIN dim_games g ON f.games_key = g.games_key
         LEFT JOIN dim_event e ON f.event_key = e.event_key WHERE g.games_key IS NULL OR e.event_key IS NULL)
  UNION ALL SELECT 'dim_games has 51 editions (28 Summer + 1906 Intercalated + 22 Winter)', (SELECT ABS(COUNT(*) - 51) FROM dim_games)
  UNION ALL SELECT 'region medal table total = official medal events', (SELECT ABS((SELECT SUM(total) FROM a_medal_table) - (SELECT COUNT(*) FROM cln_medal_events WHERE is_official = 1)))
  UNION ALL SELECT 'at most 3 medal ranks', (SELECT COUNT(*) FROM cln_entries WHERE medal_rank NOT IN (1, 2, 3))
  UNION ALL SELECT 'BMI flagged outliers are NULL in fact_entry', (SELECT COUNT(*) FROM fact_entry WHERE dq_bmi_outlier = 1 AND bmi IS NOT NULL)
)
SELECT check_name, COALESCE(failed_rows, 0) AS failed_rows, CASE WHEN COALESCE(failed_rows, 0) = 0 THEN 'PASS' ELSE 'FAIL' END AS status FROM c;
