-- =============================================================
-- Project: Costco Wholesale E-Commerce Business Intelligence
-- File:    06_advanced_analysis.sql
-- Purpose: Advanced analysis — CTEs, window functions, RFM
--          segmentation, cohort retention, and MoM growth
-- Schema:  costco_ecommerce (star schema)
-- =============================================================

USE costco_ecommerce;

-- =============================================================
-- SECTION 1: MONTH-OVER-MONTH REVENUE GROWTH
-- =============================================================

-- 1A. Month-over-month revenue growth using LAG window function
-- LAG retrieves the prior month's revenue without a self-join.
-- MoM growth % reveals acceleration/deceleration in the business.
-- Excludes 2016 partial year from growth calculations.
WITH monthly_revenue AS (
    SELECT
        dd.year, dd.month_num, dd.month_name,
        ROUND(SUM(fo.revenue), 2)      AS total_revenue,
        ROUND(SUM(fo.gross_profit), 2) AS total_gross_profit,
        COUNT(DISTINCT fo.order_id)    AS total_orders
    FROM fact_orders fo
    JOIN dim_date dd ON fo.date_id = dd.date_id
    WHERE dd.year >= 2017
    GROUP BY dd.year, dd.month_num, dd.month_name, DATE_FORMAT(fo.date_id, '%Y-%m')

)
SELECT
    year, month_num, month_name, total_revenue, total_gross_profit, total_orders,
    LAG(total_revenue) OVER (ORDER BY 'year_month') AS prev_month_revenue,
    ROUND((total_revenue - LAG(total_revenue) OVER (ORDER BY 'year_month'))/ LAG(total_revenue) OVER (ORDER BY 'year_month') * 100, 2) 
		AS mom_revenue_growth_pct,
    ROUND((total_orders - LAG(total_orders) OVER (ORDER BY 'year_month'))/ LAG(total_orders) OVER (ORDER BY 'year_month') * 100, 2)
		AS mom_order_growth_pct
FROM monthly_revenue
ORDER BY 'year_month';

-- Finding: Month-over-month growth is volatile in early 2017 as the
-- business was still ramping — February showed +108.7% MoM growth
-- simply due to the low January baseline. Growth stabilized through
-- mid-2017 with moderate fluctuations. November 2017 was the standout
-- month, posting +52.6% MoM revenue growth and +62.8% order growth,
-- confirming the Black Friday/holiday spike identified in 05_analysis_core
-- Section 1B. December 2017 pulled back sharply (-26.9% revenue,
-- -24.4% orders) — a normal post-holiday pattern. 2018 entered strong
-- with January at +27.6% MoM off the December trough, then settled
-- into a low-growth steady state: April through August 2018 show MoM
-- revenue growth between -12.5% and +1.9%, consistent with a maturing
-- business that has exhausted its early growth phase. The absence of
-- a sustained positive MoM trend in 2018 reinforces the flat new
-- customer acquisition finding from Section 7C of 05_analysis_core —
-- the business is holding volume but not accelerating.

-- ---------------------------------------------------------------

-- 1B. Cumulative revenue by year using running total
-- Shows how revenue accumulates within each year.
-- Useful for visualizing YTD progress in Power BI.
WITH monthly_revenue AS (SELECT dd.year, dd.month_num, dd.month_name,
		ROUND(SUM(fo.revenue), 2) AS monthly_revenue
    FROM fact_orders fo
    JOIN dim_date dd ON fo.date_id = dd.date_id
    WHERE dd.year IN (2017, 2018)
    GROUP BY dd.year, dd.month_num, dd.month_name
)
SELECT
    year, month_num, month_name, monthly_revenue,
    ROUND(SUM(monthly_revenue) OVER (PARTITION BY year ORDER BY month_num ROWS UNBOUNDED PRECEDING), 2)
		AS cumulative_revenue_ytd
FROM monthly_revenue
ORDER BY year, month_num;

-- Finding: Cumulative YTD revenue curves confirm the growth story from
-- Section 1A. 2017 closed at $6.04M after 12 full months, with the
-- cumulative line accelerating sharply in November due to the holiday
-- spike. 2018 ran ahead of 2017 pace at every comparable month —
-- by August 2018 cumulative revenue reached $7.27M with four months
-- still remaining in the year, already exceeding 2017's full-year
-- total by 20.4%. If 2018's Q4 followed the same seasonal pattern
-- as 2017 (November spike + December pullback), full-year 2018
-- revenue would have projected to approximately $9.5M–$10M.
-- The consistent gap between the two curves throughout the year
-- confirms broad-based growth rather than a single month driving
-- the difference. In Power BI this query feeds a dual-line YTD
-- chart — one line per year — which visually communicates the
-- growth story more clearly than a standard time-series bar chart.

-- =============================================================
-- SECTION 2: REVENUE RANKING BY DEPARTMENT
-- =============================================================

-- 2A. Department revenue rank using RANK window function
-- RANK assigns position by revenue within each year.
-- Tracks whether department standings shift year over year.
WITH dept_annual AS (
    SELECT
        dd.year, dp.costco_department,
        ROUND(SUM(fo.revenue), 2) AS total_revenue,
        ROUND(SUM(fo.gross_profit), 2) AS total_gross_profit,
        ROUND(SUM(fo.gross_profit) / SUM(fo.revenue) * 100, 2)
			AS gross_margin_pct
    FROM fact_orders fo
    JOIN dim_date dd ON fo.date_id = dd.date_id
    JOIN dim_products dp ON fo.product_key = dp.product_key
    WHERE dd.year IN (2017, 2018)
    GROUP BY dd.year, dp.costco_department
)
SELECT
    year, costco_department, total_revenue, total_gross_profit, gross_margin_pct,
    RANK() OVER (PARTITION BY year ORDER BY total_revenue DESC) AS revenue_rank
FROM dept_annual
ORDER BY year, revenue_rank;

-- Finding: Home & Kitchen held the #1 revenue rank in both 2017 and
-- 2018 ($819K → $1.1M, +34.8% YoY), confirming it as the dominant
-- volume department despite a mid-tier margin of 46.2%. Health &
-- Beauty retained #2 both years ($691K → $935K, +35.3% YoY) and
-- remains the standout department combining top-3 revenue with the
-- highest margin in the portfolio (56.3%) — the only department
-- excelling on both dimensions simultaneously. Electronics &
-- Computers dropped from #3 to #4 as Jewelry & Watches climbed
-- from #4 to #3 ($484K → $701K, +45.0% YoY) — the largest rank
-- improvement among high-revenue departments. Electronics &
-- Computers actually declined slightly in absolute revenue
-- ($646K → $630K, -2.5%) while every other top-10 department
-- grew, suggesting category softness or increased competition.
-- Seasonal & Specialty fell from #5 to #9 despite modest revenue
-- growth, displaced by faster-growing departments. The bottom tier
-- (Books & Media, Grocery & Food Court, Home Goods) grew
-- proportionally but remains subscale — collectively under $165K
-- in 2018. Gross margins are identical year over year for every
-- department, confirming that margin is set at the category level
-- in product_costs_clean rather than fluctuating with market
-- conditions — a known characteristic of the synthetic dataset.

-- =============================================================
-- SECTION 3: RFM CUSTOMER SEGMENTATION
-- =============================================================

-- 3A. Calculate raw RFM scores per customer
-- Recency  = days since last order (lower = better)
-- Frequency = total number of orders placed
-- Monetary  = total revenue generated
-- Reference date: 2018-09-01 (day after dataset ends 2018-08-29)
WITH rfm_base AS (
    SELECT
        fo.customer_key,
        DATEDIFF('2018-09-01', MAX(fo.date_id))      AS recency_days,
        COUNT(DISTINCT fo.order_id)                  AS frequency,
        ROUND(SUM(fo.revenue), 2)                    AS monetary
    FROM fact_orders fo
    GROUP BY fo.customer_key
),
rfm_scored AS (
    SELECT
        customer_key, recency_days, frequency, monetary,
        -- Recency: lower days = higher score (NTILE reversed)
        NTILE(5) OVER (ORDER BY recency_days DESC)   AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC)       AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)        AS m_score
    FROM rfm_base
)
SELECT
    customer_key, recency_days, frequency, monetary, r_score, f_score, m_score,
    CONCAT(r_score, f_score, m_score)  AS rfm_score,
    (r_score + f_score + m_score)   AS rfm_total,
    CASE
        WHEN (r_score + f_score + m_score) >= 13 THEN 'Champions'
        WHEN (r_score + f_score + m_score) >= 10 THEN 'Loyal Customers'
        WHEN (r_score + f_score + m_score) >= 7  THEN 'Potential Loyalists'
        WHEN r_score >= 4
             AND (f_score + m_score) <= 4        THEN 'New Customers'
        WHEN r_score <= 2
             AND (f_score + m_score) >= 6        THEN 'At Risk'
        WHEN r_score <= 2
             AND (f_score + m_score) >= 4        THEN 'Needs Attention'
        ELSE 'Hibernating'
    END  AS rfm_segment
FROM rfm_scored
ORDER BY rfm_total DESC;

-- ---------------------------------------------------------------

-- 3B. RFM segment summary — size, revenue, and avg metrics
-- Aggregates customer counts and revenue by segment.
-- Champions and Loyal Customers are retention priority targets.
-- At Risk customers are win-back campaign candidates.
WITH rfm_base AS (
    SELECT
        fo.customer_key,
        DATEDIFF('2018-09-01', MAX(fo.date_id)) AS recency_days,
        COUNT(DISTINCT fo.order_id)             AS frequency,
        ROUND(SUM(fo.revenue), 2)               AS monetary
    FROM fact_orders fo
    GROUP BY fo.customer_key
),
rfm_scored AS (
    SELECT
        customer_key, recency_days, frequency, monetary,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC)     AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)      AS m_score
    FROM rfm_base
),
rfm_segmented AS (
    SELECT
        customer_key, recency_days, frequency, monetary,
        (r_score + f_score + m_score) AS rfm_total,
        CASE
            WHEN (r_score + f_score + m_score) >= 13 THEN 'Champions'
            WHEN (r_score + f_score + m_score) >= 10 THEN 'Loyal Customers'
            WHEN (r_score + f_score + m_score) >= 7  THEN 'Potential Loyalists'
            WHEN r_score >= 4
                 AND (f_score + m_score) <= 4        THEN 'New Customers'
            WHEN r_score <= 2
                 AND (f_score + m_score) >= 6        THEN 'At Risk'
            WHEN r_score <= 2
                 AND (f_score + m_score) >= 4        THEN 'Needs Attention'
            ELSE 'Hibernating'
        END                                          AS rfm_segment
    FROM rfm_scored
)
SELECT
    rfm_segment,
    COUNT(*)                                         AS customer_count,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER () * 100, 2) AS pct_of_customers,
    ROUND(SUM(monetary), 2)                          AS total_revenue,
    ROUND(AVG(monetary), 2)                          AS avg_revenue_per_customer,
    ROUND(AVG(recency_days), 0)                      AS avg_recency_days,
    ROUND(AVG(frequency), 2)                         AS avg_orders_per_customer
FROM rfm_segmented
GROUP BY rfm_segment
ORDER BY total_revenue DESC;

-- Finding: The RFM segmentation reveals a business with a healthy
-- core but a significant retention challenge. Potential Loyalists
-- are the largest segment at 50.3% of customers (47,055) but
-- contribute only $4.1M in revenue at $86 avg per customer —
-- indicating a large base of low-frequency, moderate-spend customers
-- who have not yet established repeat purchase behavior. Loyal
-- Customers (36.2%, 33,864) generate $7.8M in revenue at $231 avg,
-- making them the highest-revenue segment despite being smaller than
-- Potential Loyalists — the priority retention target. Champions
-- are only 3.4% of customers (3,206) but produce $1.1M at $357 avg
-- per customer, the highest monetary value of any segment, with 1.55
-- avg orders confirming genuine repeat purchase behavior. Together
-- Champions and Loyal Customers represent 39.6% of customers but
-- generate $8.98M — approximately 67% of total revenue, consistent
-- with the Pareto concentration pattern. Needs Attention (8.3%)
-- shows the highest avg recency of 457 days, meaning these customers
-- have not ordered in over a year and are effectively lapsed —
-- win-back campaigns are unlikely to be cost-effective at this
-- recency gap. New Customers (1.3%) and Hibernating (0.5%) are
-- negligible in both size and revenue. The absence of a meaningful
-- high-frequency Champions tier (only 3.4%) directly confirms the
-- flat retention finding anticipated in Section 4 — most customers
-- in this dataset place exactly one order and do not return.

-- =============================================================
-- SECTION 4: COHORT RETENTION ANALYSIS
-- =============================================================

-- 4A. Assign each customer to their acquisition cohort (month of first order)
-- Then calculate how many customers from each cohort returned in
-- subsequent months. Retention rate = returning customers / cohort size.
-- Note: Given the dataset's single-purchase nature (most customers
-- order once), retention rates are expected to be low — this analysis
-- quantifies that pattern precisely.
WITH customer_cohorts AS (
    SELECT
        fo.customer_key,
        DATE_FORMAT(MIN(fo.date_id), '%Y-%m')  AS cohort_month
    FROM fact_orders fo
    GROUP BY fo.customer_key
),
customer_orders AS (
    SELECT
        fo.customer_key,
        DATE_FORMAT(fo.date_id, '%Y-%m') AS order_month
    FROM fact_orders fo
),
cohort_data AS (
    SELECT
        cc.cohort_month,
        co.order_month,
        COUNT(DISTINCT co.customer_key)  AS active_customers,
        PERIOD_DIFF(REPLACE(co.order_month, '-', ''), REPLACE(cc.cohort_month, '-', ''))
			AS months_since_acquisition
    FROM customer_cohorts cc
    JOIN customer_orders co ON cc.customer_key = co.customer_key
    GROUP BY cc.cohort_month, co.order_month
),
cohort_sizes AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_key) AS cohort_size
    FROM customer_cohorts
    GROUP BY cohort_month
)
SELECT
    cd.cohort_month, cs.cohort_size, cd.months_since_acquisition, cd.active_customers,
    ROUND(cd.active_customers / cs.cohort_size * 100, 2) AS retention_rate_pct
FROM cohort_data cd
JOIN cohort_sizes cs ON cd.cohort_month = cs.cohort_month
WHERE cd.months_since_acquisition >= 0
  AND cd.months_since_acquisition <= 12
ORDER BY cd.cohort_month, cd.months_since_acquisition;

-- Finding: Cohort retention confirms what the RFM segmentation
-- anticipated — this is overwhelmingly a single-purchase customer
-- base. Month 0 retention is 100% by definition across all cohorts.
-- Month 1 retention drops immediately to 0.26%–0.81%, meaning
-- fewer than 1 in 100 customers places a second order the following
-- month. Retention never recovers — subsequent months hover between
-- 0.07% and 0.97% with no meaningful trend upward or downward,
-- indicating that the small fraction of returning customers are
-- scattered randomly across time rather than exhibiting a loyalty
-- pattern. The November 2017 cohort (7,084 customers, the largest)
-- follows the same pattern, confirming the single-purchase behavior
-- is not cohort-specific but structural across the entire customer
-- base. This is consistent with the Olist marketplace model where
-- customers discover a seller through the platform for a specific
-- purchase rather than returning to a brand repeatedly. For a real
-- Costco e-commerce operation this retention rate would be a critical
-- business problem — industry benchmarks for healthy e-commerce
-- retention sit at 20–40% Month 1. The RFM "Loyal Customers" and
-- "Champions" segments identified in Section 3B represent customers
-- with 2+ orders spread across longer time horizons rather than
-- consistent monthly returners, explaining why retention rates
-- appear low despite those segments existing.

-- ---------------------------------------------------------------

-- 4B. Average retention rate by months since acquisition
-- Collapses all cohorts into a single average retention curve.
-- Shows the typical customer lifecycle pattern across the business.
WITH customer_cohorts AS (
    SELECT
        fo.customer_key,
        DATE_FORMAT(MIN(fo.date_id), '%Y-%m') AS cohort_month
    FROM fact_orders fo
    GROUP BY fo.customer_key
),
customer_orders AS (
    SELECT
        fo.customer_key,
        DATE_FORMAT(fo.date_id, '%Y-%m') AS order_month
    FROM fact_orders fo
),
cohort_data AS (
    SELECT
        cc.cohort_month, co.order_month,
        COUNT(DISTINCT co.customer_key) AS active_customers,
        PERIOD_DIFF(REPLACE(co.order_month, '-', ''), REPLACE(cc.cohort_month, '-', '')) 
			AS months_since_acquisition
    FROM customer_cohorts cc
    JOIN customer_orders co ON cc.customer_key = co.customer_key
    GROUP BY cc.cohort_month, co.order_month
),
cohort_sizes AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_key) AS cohort_size
    FROM customer_cohorts
    GROUP BY cohort_month
),
retention_rates AS (
    SELECT
        cd.cohort_month, cd.months_since_acquisition,
        ROUND(cd.active_customers / cs.cohort_size * 100, 2) AS retention_rate_pct
    FROM cohort_data cd
    JOIN cohort_sizes cs ON cd.cohort_month = cs.cohort_month
    WHERE cd.months_since_acquisition >= 0
      AND cd.months_since_acquisition <= 12
)
SELECT
    months_since_acquisition,
    ROUND(AVG(retention_rate_pct), 2)  AS avg_retention_rate_pct,
    COUNT(DISTINCT cohort_month)       AS cohorts_included
FROM retention_rates
GROUP BY months_since_acquisition
ORDER BY months_since_acquisition;

-- Finding: The average retention curve quantifies the structural
-- single-purchase pattern across all cohorts. Month 1 average
-- retention of 5.48% is inflated by the small 2016 partial-year
-- cohorts which have anomalously high retention rates due to their
-- tiny cohort sizes (1–264 customers) — the true steady-state Month 1
-- retention for large 2017–2018 cohorts is consistently below 1%.
-- Months 2–12 flatline between 0.21% and 0.38% with no decay curve,
-- confirming there is no meaningful cohort lifecycle to model —
-- customers who do return do so sporadically rather than following
-- a predictable retention pattern. The decreasing cohorts_included
-- count (23 at Month 0 down to 8 at Month 12) reflects the dataset's
-- time boundary — later cohorts simply don't have 12 months of
-- follow-up data available, which is expected and does not indicate
-- data quality issues. In a real business context this retention
-- curve would be the single most urgent metric requiring intervention
-- — even improving Month 1 retention from sub-1% to 5% would
-- materially increase LTV across the 96,352 customer base. For
-- portfolio presentation purposes this analysis demonstrates
-- correct cohort methodology and honest interpretation of results
-- rather than manufacturing a favorable retention story from
-- unsuitable data.

-- =============================================================
-- SECTION 5: TOP CUSTOMERS BY REVENUE
-- =============================================================

-- 5A. Top 20 customers by total revenue with percentile ranking
-- PERCENT_RANK identifies where each customer sits in the
-- overall revenue distribution. Top customers disproportionately
-- drive revenue in most e-commerce datasets (Pareto principle).
WITH customer_revenue AS (
    SELECT
        fo.customer_key, dc.customer_state, dc.brazil_region,
        COUNT(DISTINCT fo.order_id)       AS total_orders,
        ROUND(SUM(fo.revenue), 2)         AS total_revenue,
        ROUND(SUM(fo.gross_profit), 2)    AS total_gross_profit,
        ROUND(AVG(fo.review_score), 2)    AS avg_review_score,
        MIN(fo.date_id)                   AS first_order_date,
        MAX(fo.date_id)                   AS last_order_date
    FROM fact_orders fo
    JOIN dim_customers dc ON fo.customer_key = dc.customer_key
    GROUP BY fo.customer_key, dc.customer_state, dc.brazil_region
)
SELECT
    customer_key, customer_state, brazil_region, total_orders, total_revenue, total_gross_profit, avg_review_score, first_order_date, last_order_date,
    ROUND(PERCENT_RANK() OVER (ORDER BY total_revenue) * 100, 2) AS revenue_percentile
FROM customer_revenue
ORDER BY total_revenue DESC
LIMIT 20;

-- Finding: The top 20 customers by revenue are all single-order
-- customers (19 of 20 show frequency = 1, first_order_date =
-- last_order_date), confirming that high-value purchases in this
-- dataset are driven by large one-time transactions rather than
-- repeat buying. The #1 customer (key 3836, RJ) spent $13,440 in
-- a single order — nearly 97x the dataset's avg order value of
-- ~$138, suggesting a bulk or high-ticket item purchase. Customer
-- 82180 is the only top-20 customer with 2 orders ($7,388 total)
-- and customer 75468 is the sole multi-order customer with 4 orders
-- ($4,080 total) — both outliers in a dataset dominated by
-- single-purchase behavior. Revenue percentiles cluster at 99.98–
-- 100.00, confirming extreme right-tail concentration where a tiny
-- number of customers account for disproportionate spend. Geographic
-- distribution skews Southeast (RJ, SP, MG, ES) consistent with
-- the overall customer base, with one Northeast (PB, PE) and one
-- North (PA) customer appearing — the latter notable given the
-- high-AOV pattern identified for Northern states in Section 3B
-- of 05_analysis_core. One customer (key 26267) shows a NULL
-- review score, indicating no review was submitted for that order.

-- ---------------------------------------------------------------

-- 5B. Revenue concentration — what share of revenue comes from
-- the top 10%, 20%, and bottom 50% of customers
-- Tests whether Pareto principle (80/20 rule) applies.
WITH customer_revenue AS (
    SELECT
        fo.customer_key,
        ROUND(SUM(fo.revenue), 2) AS total_revenue
    FROM fact_orders fo
    GROUP BY fo.customer_key
),
customer_percentiles AS (
    SELECT
        customer_key, total_revenue,
        PERCENT_RANK() OVER (ORDER BY total_revenue) AS pct_rank
    FROM customer_revenue
)
SELECT
    CASE
        WHEN pct_rank >= 0.90 THEN 'Top 10%'
        WHEN pct_rank >= 0.80 THEN 'Top 10-20%'
        WHEN pct_rank >= 0.50 THEN 'Middle 30-50%'
        ELSE 'Bottom 50%'
    END AS customer_tier,
    COUNT(*) AS customer_count,
    ROUND(SUM(total_revenue), 2) AS tier_revenue,
    ROUND(SUM(total_revenue) / SUM(SUM(total_revenue)) OVER () * 100, 2)
		AS pct_of_total_revenue
FROM customer_percentiles
GROUP BY customer_tier
ORDER BY pct_of_total_revenue DESC;

-- Finding: Revenue concentration follows a modified Pareto pattern.
-- The top 10% of customers (9,353) generate $5.5M — 41.2% of total
-- revenue — while the bottom 50% (47,832 customers) contribute only
-- 17.3% ($2.3M). The top 20% combined (18,722 customers) account
-- for 56.7% of revenue ($7.6M), broadly consistent with the 80/20
-- principle though less extreme than typical e-commerce datasets
-- where the top 20% often drives 70–80% of revenue. The relatively
-- compressed distribution — bottom 50% still contributing 17.3% —
-- reflects the single-purchase nature of the dataset where most
-- customers have exactly one order, creating a flatter revenue
-- distribution than a mature repeat-purchase business would show.
-- In a real Costco e-commerce operation with stronger retention,
-- the top tier concentration would likely be more pronounced as
-- loyal repeat customers compound their lifetime value over time.
-- For marketing prioritization, the top 10% threshold represents
-- the Champions and upper Loyal Customers from Section 3B and
-- should be the primary audience for retention and upsell campaigns.

-- =============================================================
-- SECTION 6: SELLER PERFORMANCE
-- =============================================================

-- 6A. Top 20 sellers by revenue with performance metrics
-- Identifies highest-value sellers. In a marketplace model,
-- top sellers are key partners requiring relationship management.
WITH seller_metrics AS (
    SELECT
        fo.seller_key, ds.seller_state,
        COUNT(DISTINCT fo.order_id)      AS total_orders,
        ROUND(SUM(fo.revenue), 2)        AS total_revenue,
        ROUND(SUM(fo.gross_profit), 2)   AS total_gross_profit,
        ROUND(AVG(fo.review_score), 2)   AS avg_review_score,
        ROUND(SUM(fo.on_time_flag) / COUNT(fo.on_time_flag) * 100, 2) 
			AS on_time_rate_pct,
        ROUND(AVG(fo.days_to_deliver), 1) AS avg_days_to_deliver
    FROM fact_orders fo
    JOIN dim_sellers ds ON fo.seller_key = ds.seller_key
    WHERE fo.on_time_flag IS NOT NULL
    GROUP BY fo.seller_key, ds.seller_state
)
SELECT
    seller_key, seller_state, total_orders, total_revenue, total_gross_profit, avg_review_score, on_time_rate_pct, avg_days_to_deliver,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM seller_metrics
ORDER BY total_revenue DESC
LIMIT 20;

-- Finding: SP-based sellers dominate the top 20, holding 15 of 20
-- positions — consistent with São Paulo's concentration as both the
-- primary customer and seller hub in the dataset. The top seller
-- (key 858, SP) leads with $229K revenue across 1,124 orders at a
-- 4.13 avg review score and 88.52% on-time rate — solid volume but
-- the lowest on-time rate in the top 5, suggesting fulfillment
-- capacity strain at high order volumes. Seller 1014 (BA) is the
-- standout outlier — a Northeast-based seller ranked #2 with $218K
-- revenue, 96.01% on-time rate, and only 348 orders, implying a
-- high-AOV product mix rather than volume-driven revenue. Seller
-- 1536 (SP, rank #5) is the most concerning top performer: 90.25%
-- on-time rate is acceptable but avg delivery of 22.3 days is the
-- highest in the top 20 by a wide margin — nearly double the top
-- seller's 14.9 days — likely contributing to its below-average
-- review score of 3.35, the lowest in the top 20. Seller 2872
-- (RJ, rank #20) posts the highest avg review score of 4.45 with
-- only 165 orders, suggesting a high-quality niche seller that
-- could scale. Generally, on-time rates across the top 20 range
-- from 88.4% to 96.0%, all above the 92.1% overall average with
-- a few exceptions — top sellers are generally stronger logistics
-- performers than the broader seller base.

-- ---------------------------------------------------------------

-- 6B. Seller performance tier distribution
-- Segments sellers into performance tiers based on combined
-- revenue rank and on-time rate. Flags underperforming sellers
-- with high volume but poor delivery or satisfaction metrics.
WITH seller_metrics AS (
    SELECT
        fo.seller_key,
        COUNT(DISTINCT fo.order_id)                  AS total_orders,
        ROUND(SUM(fo.revenue), 2)                    AS total_revenue,
        ROUND(AVG(fo.review_score), 2)               AS avg_review_score,
        ROUND(SUM(fo.on_time_flag) / COUNT(fo.on_time_flag) * 100, 2)
			AS on_time_rate_pct
    FROM fact_orders fo
    WHERE fo.on_time_flag IS NOT NULL
    GROUP BY fo.seller_key
    HAVING total_orders >= 10
)
SELECT
    CASE
        WHEN total_revenue >= 10000
             AND on_time_rate_pct >= 90
             AND avg_review_score >= 4.0 THEN 'Elite'
        WHEN total_revenue >= 5000
             AND on_time_rate_pct >= 85  THEN 'Strong'
        WHEN total_revenue >= 1000
             AND on_time_rate_pct >= 80  THEN 'Average'
        WHEN on_time_rate_pct < 80
             OR avg_review_score < 3.5   THEN 'Underperforming'
        ELSE 'Developing'
    END AS seller_tier,
    COUNT(*)                        AS seller_count,
    ROUND(SUM(total_revenue), 2)    AS tier_revenue,
    ROUND(AVG(on_time_rate_pct), 2) AS avg_on_time_pct,
    ROUND(AVG(avg_review_score), 2) AS avg_review_score
FROM seller_metrics
GROUP BY seller_tier
ORDER BY tier_revenue DESC;

-- Finding: The seller base is split between a high-performing
-- core and a small underperforming tail. Elite and Strong sellers
-- together represent only 478 sellers (35.2% of tiered sellers)
-- but generate $9.9M in combined revenue — approximately 74% of
-- total seller revenue — with on-time rates above 93% and review
-- scores above 4.0. Elite sellers (148) marginally outperform
-- Strong (330) on both on-time rate (94.84% vs 93.10%) and review
-- score (4.29 vs 4.07) while generating comparable total revenue
-- ($4.8M vs $5.1M), suggesting Strong sellers have higher volume
-- but slightly looser operational discipline. Average sellers (547)
-- contribute $1.7M at acceptable service levels (93.10% on-time,
-- 4.16 review) — a development opportunity if revenue per seller
-- can be increased through platform support or incentives.
-- Underperforming sellers (81) are the critical flag: 74.12%
-- on-time rate is well below the 92.1% platform average and the
-- 3.61 review score approaches the threshold where negative
-- customer sentiment compounds. Despite representing only 7.3%
-- of sellers, their $418K revenue means removal would have
-- meaningful top-line impact — a classic marketplace tension
-- between seller quality enforcement and revenue preservation.
-- Developing sellers (131) show strong service metrics (94.54%
-- on-time, 4.30 review) but low revenue, identifying them as
-- high-potential sellers worth investment in growth support.

-- =============================================================
-- END OF 06_advanced_analysis.sql
-- Next steps: Power BI dashboard build (4 dashboards)
-- =============================================================