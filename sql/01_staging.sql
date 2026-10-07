-- 01_staging.sql  Land the raw files as all-text staging tables (no cleaning yet).
-- DuckDB: read_csv(...). On Databricks use read_files('/Volumes/workspace/da_learn_23/raw/athlete_events.csv', format => 'csv',
-- header => true, inferSchema => false) - the column names and all-string types are identical.

-- athlete_events.csv: one row per athlete x event x Games (271,116 rows, 15 columns; missing values are the literal string NA)
CREATE OR REPLACE TABLE stg_athlete_events AS
SELECT ID AS r_id, Name AS r_name, Sex AS r_sex, Age AS r_age, Height AS r_height, Weight AS r_weight, Team AS r_team, NOC AS r_noc,
       Games AS r_games, Year AS r_year, Season AS r_season, City AS r_city, Sport AS r_sport, Event AS r_event, Medal AS r_medal
FROM read_csv('{{RAW_DIR}}/athlete_events.csv', header = true, all_varchar = true);

-- noc_regions.csv: NOC code -> modern region (230 rows). The file uses old-Mac CR-only line endings; DuckDB's sniffer detects them,
-- on Databricks pass lineSep => '\r'.
CREATE OR REPLACE TABLE stg_noc_regions AS
SELECT NOC AS r_noc, region AS r_region, notes AS r_notes
FROM read_csv('{{RAW_DIR}}/noc_regions.csv', header = true, all_varchar = true);

-- hand-made references (data/reference/)
CREATE OR REPLACE TABLE ref_host_nations AS
SELECT * FROM read_csv('{{REF_DIR}}/host_nations.csv', header = true, all_varchar = true);
CREATE OR REPLACE TABLE ref_noc_overrides AS
SELECT * FROM read_csv('{{REF_DIR}}/noc_region_overrides.csv', header = true, all_varchar = true);
