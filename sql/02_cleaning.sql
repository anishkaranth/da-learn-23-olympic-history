-- 02_cleaning.sql  Dedupe, NA -> NULL, types, standardisation, region mapping, outlier flags, integrity checks (Spark SQL dialect)

-- 1. exact duplicate rows (same athlete, Games, event, medal and every other column) are dropped
CREATE OR REPLACE TABLE cln_dedup AS
SELECT DISTINCT * FROM stg_athlete_events;

-- 2. NOC -> region: noc_regions.csv + overrides (SGP missing as SIN; region 'NA' for ROT/TUV/UNK uses the notes text)
CREATE OR REPLACE TABLE cln_noc AS
WITH base AS (
  SELECT trim(r_noc) AS noc, NULLIF(NULLIF(trim(r_region), ''), 'NA') AS region, NULLIF(trim(r_notes), '') AS notes FROM stg_noc_regions
  UNION ALL
  SELECT trim(noc), region, reason FROM ref_noc_overrides WHERE trim(noc) NOT IN (SELECT trim(r_noc) FROM stg_noc_regions)
)
SELECT b.noc, COALESCE(o.region, b.region) AS region, b.notes,
       CASE WHEN o.noc IS NOT NULL THEN 1 ELSE 0 END AS dq_region_overridden
FROM base b LEFT JOIN ref_noc_overrides o ON b.noc = trim(o.noc);

-- 3. typed + standardised rows
CREATE OR REPLACE TABLE cln_typed AS
SELECT
  TRY_CAST(trim(r_id) AS INT)                                           AS athlete_id,
  trim(r_name)                                                          AS athlete_name,
  upper(trim(r_sex))                                                    AS sex,
  TRY_CAST(NULLIF(trim(r_age), 'NA') AS INT)                            AS age,
  TRY_CAST(NULLIF(trim(r_height), 'NA') AS DOUBLE)                      AS height_cm,
  TRY_CAST(NULLIF(trim(r_weight), 'NA') AS DOUBLE)                      AS weight_kg,
  trim(r_team)                                                          AS team_raw,
  regexp_replace(trim(r_team), '-[0-9]+$', '')                          AS team,
  CASE WHEN regexp_like(trim(r_team), '-[0-9]+$') THEN 1 ELSE 0 END     AS dq_team_suffix,
  upper(trim(r_noc))                                                    AS noc,
  trim(r_games)                                                         AS games,
  TRY_CAST(trim(r_year) AS INT)                                         AS yr,
  initcap(trim(r_season))                                               AS season,
  trim(r_city)                                                          AS city,
  trim(r_sport)                                                         AS sport,
  trim(r_event)                                                         AS event,
  CASE WHEN trim(r_medal) IN ('Gold', 'Silver', 'Bronze') THEN trim(r_medal) END AS medal,
  CASE WHEN trim(r_medal) NOT IN ('Gold', 'Silver', 'Bronze', 'NA') OR r_medal IS NULL THEN 1 ELSE 0 END AS dq_bad_medal
FROM cln_dedup;

-- 4. clean entries: one row per athlete x event x Games, with region, host flags, derived measures and quality flags
CREATE OR REPLACE TABLE cln_entries AS
WITH host AS (
  SELECT h.games, h.city AS host_city, h.host_noc, n.region AS host_region
  FROM ref_host_nations h LEFT JOIN cln_noc n ON trim(h.host_noc) = n.noc WHERE h.is_main_host_city = '1'
)
SELECT
  t.*,
  ROW_NUMBER() OVER (ORDER BY t.yr, t.season, t.event, t.athlete_id, t.team_raw, t.city) AS entry_key,
  COALESCE(n.region, 'Unknown')                                         AS region,
  CASE WHEN t.yr = 1906 THEN 1 ELSE 0 END                               AS is_intercalated,
  CASE WHEN t.sport = 'Art Competitions' THEN 1 ELSE 0 END              AS is_art,
  CASE WHEN t.yr <> 1906 AND t.sport <> 'Art Competitions' THEN 1 ELSE 0 END AS is_official,
  CASE WHEN t.event LIKE '%Women''s%' THEN 'Women' WHEN t.event LIKE '%Mixed%' THEN 'Mixed'
       WHEN t.event LIKE '%Men''s%' THEN 'Men' ELSE 'Open' END          AS event_gender,
  CASE t.medal WHEN 'Gold' THEN 1 WHEN 'Silver' THEN 2 WHEN 'Bronze' THEN 3 END AS medal_rank,
  CASE WHEN t.medal IS NOT NULL THEN 1 ELSE 0 END                       AS is_medal,
  ROUND(t.weight_kg / ((t.height_cm / 100.0) * (t.height_cm / 100.0)), 2) AS bmi,
  CASE WHEN t.weight_kg / ((t.height_cm / 100.0) * (t.height_cm / 100.0)) < 15
         OR t.weight_kg / ((t.height_cm / 100.0) * (t.height_cm / 100.0)) > 60 THEN 1 ELSE 0 END AS dq_bmi_outlier,
  CASE WHEN t.age >= 65 THEN 1 ELSE 0 END                               AS dq_age_65_plus,
  CASE WHEN t.age < 13 THEN 1 ELSE 0 END                                AS dq_age_under_13,
  CASE WHEN COALESCE(n.region, 'x') = COALESCE(h.host_region, 'y') THEN 1 ELSE 0 END AS is_host_nation,
  h.host_city, h.host_noc, h.host_region,
  CASE WHEN n.noc IS NULL THEN 1 ELSE 0 END                             AS dq_noc_unmapped,
  CASE WHEN t.games <> concat(CAST(t.yr AS STRING), ' ', t.season) THEN 1 ELSE 0 END AS dq_games_mismatch,
  CASE WHEN NOT starts_with(t.event, t.sport) THEN 1 ELSE 0 END         AS dq_event_sport_mismatch
FROM cln_typed t
LEFT JOIN cln_noc n ON t.noc = n.noc
LEFT JOIN host h ON t.games = h.games
WHERE t.athlete_id IS NOT NULL AND t.yr IS NOT NULL;

-- 5. medal events: team events give every team member a medal row, so podium places are counted once per
--    Games x event x NOC x team entry x medal (e.g. a gold in the men's eight is 1 medal, not 9 athlete medals)
CREATE OR REPLACE TABLE cln_medal_events AS
SELECT games, yr, season, sport, event, event_gender, noc, region, team_raw, medal, medal_rank, is_official, is_host_nation,
       COUNT(*) AS athletes_on_entry
FROM cln_entries
WHERE medal IS NOT NULL
GROUP BY games, yr, season, sport, event, event_gender, noc, region, team_raw, medal, medal_rank, is_official, is_host_nation;

-- 6. athlete-level profile (one row per athlete id)
CREATE OR REPLACE TABLE cln_athletes AS
SELECT athlete_id,
       max_by(athlete_name, yr)          AS athlete_name,
       max(sex)                          AS sex,
       max_by(noc, yr)                   AS latest_noc,
       max_by(region, yr)                AS latest_region,
       max_by(sport, yr)                 AS latest_sport,
       min(yr)                           AS first_year,
       max(yr)                           AS last_year,
       COUNT(DISTINCT games)             AS n_games,
       COUNT(*)                          AS n_entries,
       SUM(is_medal)                     AS medals,
       SUM(CASE WHEN medal = 'Gold' THEN 1 ELSE 0 END)   AS golds,
       SUM(CASE WHEN medal = 'Silver' THEN 1 ELSE 0 END) AS silvers,
       SUM(CASE WHEN medal = 'Bronze' THEN 1 ELSE 0 END) AS bronzes,
       COUNT(DISTINCT sex)               AS n_sexes,
       COUNT(DISTINCT athlete_name)      AS n_names,
       percentile_approx(yr - age, 0.5)  AS birth_year_est
FROM cln_entries
GROUP BY athlete_id;
