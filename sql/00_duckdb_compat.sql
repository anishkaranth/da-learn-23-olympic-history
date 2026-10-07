-- 00_duckdb_compat.sql  (DuckDB ONLY - do NOT run on Databricks)
-- Spark / Databricks SQL function shims so that 01-05 can be written in Spark SQL dialect and still run unchanged on DuckDB.
-- On Databricks these functions are built in. Only the argument patterns used in this project are supported.
CREATE OR REPLACE MACRO regexp_like(s, p) AS regexp_matches(s, p);
CREATE OR REPLACE MACRO percentile_approx(x, p) AS quantile_cont(x, p);
-- initcap(s): this project only title-cases single words (Season = summer/SUMMER -> Summer)
CREATE OR REPLACE MACRO initcap(s) AS concat(upper(substr(s, 1, 1)), lower(substr(s, 2)));
