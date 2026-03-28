-- ============================================================
--  PROJECT 3: Movie Database SQL Analysis
--  Author  : Abel Dani Stanly
--  Course  : Cisco NetAcad – Data Analytics Essentials
--  Dataset : Movie Database (4,535 films, 2000–2017)
--  Tools   : SQL (compatible with SQLite / MySQL / PostgreSQL)
-- ============================================================
--
-- TABLE SCHEMA (reference):
--   movies (
--     id               INT,
--     title            VARCHAR(255),
--     budget           BIGINT,
--     revenue          BIGINT,
--     runtime          FLOAT,
--     popularity       FLOAT,
--     release_date     DATE,
--     vote_average     FLOAT,
--     vote_count       INT,
--     original_language VARCHAR(10)
--   )
-- ============================================================


-- ────────────────────────────────────────────────────────────
--  QUERY 1: Total film count and dataset overview
--  Business Question: How large is the dataset and what is the
--  date range covered?
-- ────────────────────────────────────────────────────────────
SELECT
    COUNT(*)                    AS total_films,
    MIN(YEAR(release_date))     AS earliest_year,
    MAX(YEAR(release_date))     AS latest_year,
    COUNT(DISTINCT original_language) AS languages_represented,
    ROUND(AVG(vote_average), 2) AS avg_audience_rating
FROM movies;


-- ────────────────────────────────────────────────────────────
--  QUERY 2: Top 10 highest-grossing films of all time
--  Business Question: Which films generated the most revenue?
-- ────────────────────────────────────────────────────────────
SELECT
    title,
    YEAR(release_date)          AS release_year,
    FORMAT(budget, 0)           AS budget_usd,
    FORMAT(revenue, 0)          AS revenue_usd,
    FORMAT(revenue - budget, 0) AS profit_usd,
    ROUND((revenue - budget) / budget * 100, 1) AS roi_pct
FROM movies
WHERE budget > 0
  AND revenue > 0
ORDER BY revenue DESC
LIMIT 10;


-- ────────────────────────────────────────────────────────────
--  QUERY 3: Top 10 films by Return on Investment (ROI)
--  Business Question: Which low-budget films punched above
--  their weight financially?
-- ────────────────────────────────────────────────────────────
SELECT
    title,
    YEAR(release_date)  AS release_year,
    budget,
    revenue,
    (revenue - budget)  AS profit,
    ROUND((revenue - budget) / budget * 100, 1) AS roi_pct
FROM movies
WHERE budget > 1000000   -- exclude micro-budget outliers
  AND revenue > 0
ORDER BY roi_pct DESC
LIMIT 10;


-- ────────────────────────────────────────────────────────────
--  QUERY 4: Annual box office trends (revenue & film count)
--  Business Question: How has the film industry's revenue
--  grown year-over-year between 2000 and 2017?
-- ────────────────────────────────────────────────────────────
SELECT
    YEAR(release_date)                      AS release_year,
    COUNT(*)                                AS films_released,
    ROUND(SUM(revenue) / 1000000, 2)        AS total_revenue_millions,
    ROUND(AVG(budget)  / 1000000, 2)        AS avg_budget_millions,
    ROUND(AVG(vote_average), 2)             AS avg_audience_rating
FROM movies
WHERE budget > 0
  AND revenue > 0
GROUP BY YEAR(release_date)
ORDER BY release_year;


-- ────────────────────────────────────────────────────────────
--  QUERY 5: Revenue performance by original language
--  Business Question: Which languages dominate global box
--  office revenue, and what is the average ROI per language?
-- ────────────────────────────────────────────────────────────
SELECT
    original_language,
    COUNT(*)                                          AS film_count,
    ROUND(SUM(revenue) / 1000000, 2)                  AS total_revenue_m,
    ROUND(AVG(revenue) / 1000000, 2)                  AS avg_revenue_m,
    ROUND(AVG((revenue - budget) / budget * 100), 1)  AS avg_roi_pct
FROM movies
WHERE budget > 0
  AND revenue > 0
GROUP BY original_language
HAVING COUNT(*) >= 5           -- filter languages with <5 films
ORDER BY total_revenue_m DESC
LIMIT 10;


-- ────────────────────────────────────────────────────────────
--  QUERY 6: Budget tier analysis using CASE WHEN
--  Business Question: Do blockbuster budgets guarantee better
--  returns compared to mid-range productions?
-- ────────────────────────────────────────────────────────────
SELECT
    CASE
        WHEN budget < 5000000             THEN '1. Low Budget (<$5M)'
        WHEN budget BETWEEN 5000000
                        AND 19999999      THEN '2. Mid Budget ($5M–$20M)'
        WHEN budget BETWEEN 20000000
                        AND 79999999      THEN '3. High Budget ($20M–$80M)'
        ELSE                                   '4. Blockbuster (>$80M)'
    END                                         AS budget_tier,
    COUNT(*)                                    AS film_count,
    ROUND(AVG(revenue) / 1000000, 2)            AS avg_revenue_m,
    ROUND(AVG((revenue - budget) / budget * 100), 1) AS avg_roi_pct,
    ROUND(SUM(CASE WHEN revenue > budget THEN 1 ELSE 0 END)
          / COUNT(*) * 100, 1)                  AS pct_profitable
FROM movies
WHERE budget > 0
  AND revenue > 0
GROUP BY budget_tier
ORDER BY budget_tier;


-- ────────────────────────────────────────────────────────────
--  QUERY 7: Films with above-average rating AND above-average
--           revenue (using subqueries)
--  Business Question: Which films achieved critical AND
--  commercial success simultaneously?
-- ────────────────────────────────────────────────────────────
SELECT
    title,
    YEAR(release_date) AS release_year,
    vote_average,
    FORMAT(revenue, 0) AS revenue_usd,
    vote_count
FROM movies
WHERE vote_average > (SELECT AVG(vote_average) FROM movies)
  AND revenue     > (SELECT AVG(revenue)     FROM movies WHERE revenue > 0)
  AND vote_count  > 500          -- ensure rating is statistically significant
ORDER BY vote_average DESC, revenue DESC
LIMIT 20;


-- ────────────────────────────────────────────────────────────
--  QUERY 8: Popularity vs audience rating correlation proxy
--  Business Question: Do more popular films (by TMDB score)
--  tend to be rated higher by audiences?
-- ────────────────────────────────────────────────────────────
SELECT
    CASE
        WHEN popularity < 10   THEN 'Low Popularity (<10)'
        WHEN popularity < 30   THEN 'Mid Popularity (10–30)'
        WHEN popularity < 70   THEN 'High Popularity (30–70)'
        ELSE                        'Viral (70+)'
    END                            AS popularity_band,
    COUNT(*)                       AS film_count,
    ROUND(AVG(vote_average), 2)    AS avg_rating,
    ROUND(AVG(revenue) / 1000000, 2) AS avg_revenue_m
FROM movies
WHERE vote_count > 100
GROUP BY popularity_band
ORDER BY avg_revenue_m DESC;


-- ────────────────────────────────────────────────────────────
--  QUERY 9: Runtime analysis — do longer films earn more?
--  Business Question: Is there a relationship between runtime
--  and box office revenue?
-- ────────────────────────────────────────────────────────────
SELECT
    CASE
        WHEN runtime < 80              THEN '1. Short (<80 min)'
        WHEN runtime BETWEEN 80 AND 100 THEN '2. Standard (80–100 min)'
        WHEN runtime BETWEEN 101 AND 130 THEN '3. Feature (101–130 min)'
        WHEN runtime BETWEEN 131 AND 160 THEN '4. Long (131–160 min)'
        ELSE                                  '5. Epic (>160 min)'
    END                                AS runtime_category,
    COUNT(*)                           AS film_count,
    ROUND(AVG(runtime), 1)             AS avg_runtime_min,
    ROUND(AVG(revenue) / 1000000, 2)   AS avg_revenue_m,
    ROUND(AVG(vote_average), 2)        AS avg_rating
FROM movies
WHERE runtime IS NOT NULL
  AND revenue > 0
GROUP BY runtime_category
ORDER BY runtime_category;


-- ────────────────────────────────────────────────────────────
--  QUERY 10: Most productive year — films released AND
--            highest aggregate profit (combined metric)
--  Business Question: What was the golden year of the
--  2000–2017 era by both volume and profitability?
-- ────────────────────────────────────────────────────────────
SELECT
    YEAR(release_date)                      AS release_year,
    COUNT(*)                                AS films_released,
    ROUND(SUM(revenue - budget) / 1000000, 2) AS total_profit_m,
    ROUND(AVG(revenue - budget) / 1000000, 2) AS avg_profit_m,
    ROUND(AVG((revenue - budget) / budget * 100), 1) AS avg_roi_pct,
    SUM(CASE WHEN revenue > budget THEN 1 ELSE 0 END) AS profitable_films
FROM movies
WHERE budget > 0
  AND revenue > 0
GROUP BY release_year
ORDER BY total_profit_m DESC
LIMIT 10;


-- ────────────────────────────────────────────────────────────
--  BONUS QUERY: Combined JOIN simulation using derived tables
--  Demonstrates multi-table thinking and subquery JOINs
--  Business Question: How do English films compare to
--  non-English films on key performance metrics?
-- ────────────────────────────────────────────────────────────
SELECT
    lang_group.language_segment,
    lang_group.film_count,
    ROUND(lang_group.avg_revenue_m, 2)  AS avg_revenue_m,
    ROUND(lang_group.avg_roi, 1)        AS avg_roi_pct,
    ROUND(lang_group.avg_rating, 2)     AS avg_audience_rating
FROM (
    SELECT
        CASE
            WHEN original_language = 'en' THEN 'English Language'
            ELSE 'Non-English Language'
        END                                             AS language_segment,
        COUNT(*)                                        AS film_count,
        AVG(revenue) / 1000000                         AS avg_revenue_m,
        AVG((revenue - budget) / budget * 100)         AS avg_roi,
        AVG(vote_average)                               AS avg_rating
    FROM movies
    WHERE budget > 0
      AND revenue > 0
    GROUP BY language_segment
) AS lang_group
ORDER BY avg_revenue_m DESC;

-- ============================================================
--  END OF QUERY FILE
--  Note: Queries tested on the Cisco NetAcad Movies dataset.
--  Syntax is MySQL-compatible. For SQLite, replace FORMAT()
--  with PRINTF() and YEAR() with STRFTIME('%Y', ...).
-- ============================================================
