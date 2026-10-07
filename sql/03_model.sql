-- 03_model.sql  Star schema: fact_entry (athlete x event x Games), fact_medal (team-deduplicated podium places) + dimensions

CREATE OR REPLACE TABLE dim_games AS
SELECT DISTINCT
  yr * 10 + CASE season WHEN 'Summer' THEN 1 ELSE 2 END AS games_key,
  games, yr AS year, season, host_city, host_noc, host_region, is_intercalated,
  CASE WHEN yr < 1940 THEN '1896-1936' WHEN yr < 1990 THEN '1948-1988' ELSE '1992-2016' END AS era
FROM cln_entries;

CREATE OR REPLACE TABLE dim_noc AS
SELECT n.noc, n.region, n.notes, n.dq_region_overridden,
       CASE WHEN n.noc IN (SELECT DISTINCT noc FROM cln_entries) THEN 1 ELSE 0 END AS appears_in_results
FROM cln_noc n;

CREATE OR REPLACE TABLE dim_event AS
SELECT ROW_NUMBER() OVER (ORDER BY sport, event) AS event_key, sport, event, event_gender, is_art, first_year, last_year, editions
FROM (SELECT sport, event, max(event_gender) AS event_gender, max(is_art) AS is_art, min(yr) AS first_year, max(yr) AS last_year,
             COUNT(DISTINCT games) AS editions
      FROM cln_entries GROUP BY sport, event) e;

CREATE OR REPLACE TABLE dim_athlete AS
SELECT athlete_id, athlete_name, sex, latest_noc, latest_region, latest_sport, first_year, last_year, n_games, n_entries,
       medals, golds, silvers, bronzes, birth_year_est
FROM cln_athletes;

CREATE OR REPLACE TABLE fact_entry AS
SELECT c.entry_key, c.athlete_id, g.games_key, e.event_key, c.noc, c.team, c.age, c.height_cm, c.weight_kg,
       CASE WHEN c.dq_bmi_outlier = 0 THEN c.bmi END AS bmi, c.medal, c.medal_rank, c.is_medal,
       c.is_official, c.is_host_nation, c.dq_bmi_outlier
FROM cln_entries c
JOIN dim_games g ON c.games = g.games
JOIN dim_event e ON c.sport = e.sport AND c.event = e.event;

CREATE OR REPLACE TABLE fact_medal AS
SELECT ROW_NUMBER() OVER (ORDER BY m.yr, m.season, m.event, m.medal_rank, m.noc, m.team_raw) AS medal_key,
       g.games_key, e.event_key, m.noc, m.team_raw AS team_entry, m.medal, m.medal_rank, m.athletes_on_entry, m.is_official, m.is_host_nation
FROM cln_medal_events m
JOIN dim_games g ON m.games = g.games
JOIN dim_event e ON m.sport = e.sport AND m.event = e.event;
