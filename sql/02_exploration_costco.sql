-- ================================================
-- COSTCO WHOLESALE E-COMMERCE BUSINESS INTELLIGENCE
-- ================================================
-- FILE 02: DATA EXPLORATION
-- Purpose: Understand dataset structure, contents,
-- distributions, and data quality issues before
-- any cleaning or transformation. Read-only --
-- no tables are created or modified in this file.
-- ================================================

USE costco_ecommerce;


-- ================================================
-- SECTION 1: STRUCTURAL OVERVIEW
-- ================================================

-- 2.1 Preview all core tables
SELECT * FROM orders_raw LIMIT 5;
SELECT * FROM order_items_raw LIMIT 5;
SELECT * FROM customers_raw LIMIT 5;
SELECT * FROM products_raw LIMIT 5;
SELECT * FROM order_reviews_raw LIMIT 5;
SELECT * FROM order_payments_raw LIMIT 5;
SELECT * FROM sellers_raw LIMIT 5;
SELECT * FROM marketing_spend_raw LIMIT 5;
SELECT * FROM product_costs_raw LIMIT 5;
SELECT * FROM order_returns_raw LIMIT 5;

-- 2.2 Confirm column structures
DESCRIBE orders_raw;
DESCRIBE order_items_raw;
DESCRIBE customers_raw;
DESCRIBE products_raw;
DESCRIBE order_reviews_raw;
DESCRIBE order_payments_raw;
DESCRIBE marketing_spend_raw;
DESCRIBE product_costs_raw;
DESCRIBE order_returns_raw;

-- Finding: All columns TEXT type as expected.
-- Type casting and conversion handled in 03_cleaning.


-- ================================================
-- SECTION 2: ORDER STATUS DISTRIBUTION
-- Critical: determines which orders are included
-- in revenue analysis
-- ================================================

-- 2.3 Distinct order statuses and counts
SELECT
    order_status,
    COUNT(*) AS order_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2)
        AS pct_of_total
FROM orders_raw
GROUP BY order_status
ORDER BY order_count DESC;

-- Finding: 96,478 orders (97.02% of orders) were delivered.
-- Note: Only "delivered" orders will be included
-- in revenue analysis. Canceled, unavailable, and
-- other non-delivered statuses excluded from
-- financial calculations in 03_cleaning.


-- ================================================
-- SECTION 3: DATE RANGE AND COMPLETENESS
-- ================================================

-- 2.4 Order date range
SELECT
    MIN(order_purchase_timestamp)   AS earliest_order,
    MAX(order_purchase_timestamp)   AS latest_order,
    COUNT(*)                        AS total_orders
FROM orders_raw;

-- Finding: 99,441 total orders from Sep-2016 to Oct-2018.


-- 2.5 NULL and empty value check on delivery dates
SELECT
    COUNT(*) AS total_orders,
    SUM(CASE WHEN order_approved_at = ''
        OR order_approved_at IS NULL
        THEN 1 ELSE 0 END)              AS null_approved_at,
    SUM(CASE WHEN order_delivered_carrier_date = ''
        OR order_delivered_carrier_date IS NULL
        THEN 1 ELSE 0 END)              AS null_carrier_date,
    SUM(CASE WHEN order_delivered_customer_date = ''
        OR order_delivered_customer_date IS NULL
        THEN 1 ELSE 0 END)              AS null_customer_delivery,
    SUM(CASE WHEN order_estimated_delivery_date = ''
        OR order_estimated_delivery_date IS NULL
        THEN 1 ELSE 0 END)              AS null_estimated_delivery
FROM orders_raw;

-- Finding: -- Finding: Of 99,441 total orders:
-- 160 rows missing order_approved_at (0.16%)
-- 1,783 rows missing order_delivered_carrier_date (1.79%)
-- 2,965 rows missing order_delivered_customer_date (2.98%)
-- 0 rows missing order_estimated_delivery_date
--
-- Missing delivery dates are expected for non-delivered
-- orders (canceled, shipped, processing, etc.).
-- Key question answered in 2.6:
-- Do any *delivered* orders have missing delivery timestamps?
-- If yes, those rows will be excluded from
-- on-time delivery analysis in 03_cleaning.


-- 2.6 Delivered orders with missing delivery dates
SELECT COUNT(*) AS delivered_missing_delivery_date
FROM orders_raw
WHERE order_status = 'delivered'
AND (order_delivered_customer_date = ''
    OR order_delivered_customer_date IS NULL);

-- Finding: 8 orders were found with missing delivery dates.
-- Any delivered orders with null delivery dates
-- will be excluded from on-time delivery analysis.


-- ================================================
-- SECTION 4: CUSTOMER ANALYSIS
-- ================================================

-- 2.7 Customer state distribution -- top 10
SELECT
    customer_state,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER(), 2) AS pct_of_total
FROM customers_raw
GROUP BY customer_state
ORDER BY customer_count DESC
LIMIT 10;

-- Finding: SP drives significant business with 41,746 customers (41.98% of customers),
-- followed by RJ (12.92%) and MG (11.70%).


-- 2.8 Repeat customer analysis
-- How many customers placed more than one order?
SELECT
    order_count,
    COUNT(*) AS customers,
    ROUND(COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER(), 2) AS pct_of_customers
FROM (
    SELECT
        customer_unique_id,
        COUNT(o.order_id) AS order_count
    FROM customers_raw c
    JOIN orders_raw o
        ON c.customer_id = o.customer_id
    GROUP BY customer_unique_id
) AS customer_orders
GROUP BY order_count
ORDER BY order_count;

-- Finding: 96.88% of customers only order once, meaning
-- only 3.12% of customers order more than once.
-- Repeat purchase rate is a key e-commerce KPI.
-- Low repeat rate signals retention problem --
-- sets up RFM and cohort analysis in 06_advanced.
--
-- Business implication: customer retention is the
-- single biggest growth opportunity in this dataset.
-- A 1% improvement in repeat purchase rate would
-- add ~930 returning customers to the active base.
-- This finding directly motivates RFM segmentation,
-- CLV modeling, and cohort retention analysis
-- in 06_advanced_analysis.sql.

-- 2.9 Check for missing customer states
SELECT COUNT(*) AS missing_states
FROM customers_raw
WHERE customer_state = ''
OR customer_state IS NULL;

-- Finding: 0 missing customer states.


-- ================================================
-- SECTION 5: PRODUCT AND CATEGORY ANALYSIS
-- ================================================

-- 2.10 Distinct Portuguese category names
-- Shows what needs to be mapped to Costco departments
SELECT
    product_category_name,
    COUNT(*) AS product_count
FROM products_raw
GROUP BY product_category_name
ORDER BY product_count DESC;

-- Finding: All product category names are in Portuguese, and
-- will be translated to English while being remapped to Costco
-- department names via category_translation_raw
-- and custom CASE WHEN logic in 03_cleaning.


-- 2.11 Products with missing category names
SELECT COUNT(*) AS missing_category
FROM products_raw
WHERE product_category_name = ''
OR product_category_name IS NULL;

-- Finding: 610 products found with missing category names.
-- Products with no category cannot be assigned
-- to a Costco department -- flagged for handling
-- in 03_cleaning
--
-- Cleaning decision: products with missing category
-- assigned to 'Uncategorized' department in
-- 03_cleaning to preserve all order revenue in
-- analysis rather than dropping valid transactions.
-- Flagged separately in product analysis so
-- 'Uncategorized' does not skew department-level
-- findings.

-- 2.12 Category translation coverage check
-- Do all Portuguese categories have an English translation?
SELECT
    p.product_category_name,
    ct.product_category_name_english
FROM (
    SELECT DISTINCT product_category_name
    FROM products_raw
    WHERE product_category_name IS NOT NULL
    AND product_category_name != ''
) p
LEFT JOIN category_translation_raw ct
    ON p.product_category_name =
       ct.product_category_name
WHERE ct.product_category_name_english IS NULL
ORDER BY p.product_category_name;

-- Finding: pc_gamer and portateis_cozinha_e_preparadores_de_alimentos
-- do not have an English translation
-- and will need manual mapping in 03_cleaning.


-- ================================================
-- SECTION 6: REVENUE AND PRICING
-- ================================================

-- 2.13 Price and freight value ranges
SELECT
    MIN(CAST(price AS DECIMAL(10,2)))           AS min_price,
    MAX(CAST(price AS DECIMAL(10,2)))           AS max_price,
    ROUND(AVG(CAST(price AS DECIMAL(10,2))),2)  AS avg_price,
    MIN(CAST(freight_value AS DECIMAL(10,2)))   AS min_freight,
    MAX(CAST(freight_value AS DECIMAL(10,2)))   AS max_freight,
    ROUND(AVG(CAST(freight_value AS DECIMAL(10,2))),2)
                                                AS avg_freight
FROM order_items_raw;

-- Finding: Average price of $120.65 in ($0.85, $6735.00) and
-- average freight of 19.99 in (0.00, 409.68).
-- Identifies price outliers and freight cost burden.


-- 2.14 Zero price items -- potential data quality issue
SELECT COUNT(*) AS zero_price_items
FROM order_items_raw
WHERE CAST(price AS DECIMAL(10,2)) = 0;

-- Finding: 0 zero-price items.


-- 2.15 Items per order distribution
SELECT
    items_per_order,
    COUNT(*) AS order_count,
    ROUND(COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER(), 2) AS pct_of_orders
FROM (
    SELECT
        order_id,
        COUNT(*) AS items_per_order
    FROM order_items_raw
    GROUP BY order_id
) AS order_sizes
GROUP BY items_per_order
ORDER BY items_per_order;

-- Finding: 90.06% of orders are single-item, 7.62% are two-item orders.
-- Most orders are single-item, which is important
-- context for average order value calculation.


-- ================================================
-- SECTION 7: PAYMENT ANALYSIS
-- ================================================

-- 2.16 Payment type distribution
SELECT
    payment_type,
    COUNT(DISTINCT order_id)    AS order_count,
    ROUND(COUNT(DISTINCT order_id) * 100.0 /
        SUM(COUNT(DISTINCT order_id)) OVER(), 2)
                                AS pct_of_orders,
    ROUND(SUM(CAST(payment_value AS DECIMAL(10,2))),2)
                                AS total_payment_value
FROM order_payments_raw
GROUP BY payment_type
ORDER BY order_count DESC;

-- Finding: 75.24% of orders were paid via credit card,
-- 19.46% were paid via boleto ("ticket").


-- 2.17 Orders with multiple payment methods
SELECT
    COUNT(*) AS orders_multiple_payments
FROM (
    SELECT order_id, COUNT(*) AS payment_count
    FROM order_payments_raw
    GROUP BY order_id
    HAVING COUNT(*) > 1
) AS multi_pay;

-- Finding: 2,961 orders have multiple payment methods
-- so need to be careful handling in revenue calculations
-- to avoid double-counting.


-- ================================================
-- SECTION 8: REVIEW SCORE ANALYSIS
-- ================================================

-- 2.18 Review score distribution
SELECT
    review_score,
    COUNT(*) AS review_count,
    ROUND(COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER(), 2) AS pct_of_reviews
FROM order_reviews_raw
WHERE review_score != ''
AND review_score IS NOT NULL
GROUP BY review_score
ORDER BY review_score DESC;

-- Finding: 57.78% of reviews are 5-star,
-- 19.29% are 4-star
-- 8.24% are 3-star
-- 3.18% are 2-star
-- 11.51% are 1-star.
-- Distribution of 1-5 scores reveals overall
-- customer satisfaction level.


-- 2.19 Average review score overall
SELECT
    ROUND(AVG(CAST(review_score AS DECIMAL(3,1))),2)
        AS avg_review_score
FROM order_reviews_raw
WHERE review_score != ''
AND review_score IS NOT NULL;

-- Finding: 4.09 star average review.


-- ================================================
-- SECTION 9: CUSTOM TABLE QUALITY CHECKS
-- ================================================

-- 2.20 Marketing spend -- distinct channels
-- Check for inconsistencies introduced intentionally
SELECT
    channel,
    COUNT(*) AS row_count,
    ROUND(SUM(CAST(spend_amount AS DECIMAL(10,2))),2)
        AS total_spend
FROM marketing_spend_raw
GROUP BY channel
ORDER BY channel;

-- Finding: 5 distinct channel values detected,
-- each with 36 rows (36 months) -- correct.
-- However channel names are inconsistent:
--   'Email Marketing' -- should be 'Email'
--   'ppc'             -- should be 'PPC'
--   'social media'    -- should be 'Social Media'
--   'SEO'             -- correct
--   'Influencer'      -- correct
--
-- 3 of 5 channels (60%) have naming inconsistencies
-- introduced during data generation to simulate
-- real-world data quality issues.
-- Standardization applied in 03_cleaning using
-- CASE WHEN to normalize all channel names to:
-- Email, PPC, Social Media, SEO, Influencer.
--
-- Spend distribution by channel:
--   PPC:          $272,476 (highest spend)
--   Influencer:   $181,793
--   Social Media: $125,073
--   SEO:           $51,099
--   Email:         $37,272 (lowest spend)
-- Total marketing spend: $667,713
-- CAC and ROAS efficiency by channel analyzed
-- in 05_analysis_core.sql.


-- 2.21 Marketing spend -- month range check
SELECT
    MIN(month) AS earliest_month,
    MAX(month) AS latest_month,
    COUNT(DISTINCT month) AS distinct_months
FROM marketing_spend_raw;

-- Finding: Earliest month is Apr-2016 and latest month is Sep-2018, which
-- is NOT correct.
-- Should span Jan-2016 through Dec-2018 (36 months). Likely due to TEXT type
-- alphabetically sorting of dates instead of chronological,
-- will need to convert to DATE type in 03_cleaning.


-- 2.22 Product costs -- category inconsistencies
SELECT
    product_category,
    unit_cost,
    avg_selling_price,
    gross_margin_pct
FROM product_costs_raw
ORDER BY product_category;

-- Finding: product_costs_raw is clean (Title Case)
-- as it is the reference/lookup table.


-- 2.23 Order returns -- return reason distribution
SELECT
    return_reason,
    COUNT(*) AS return_count,
    ROUND(COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER(), 2) AS pct_of_returns,
    ROUND(SUM(CAST(refund_amount AS DECIMAL(10,2))),2)
        AS total_refund_amount
FROM order_returns_raw
GROUP BY return_reason
ORDER BY return_count DESC;

-- Finding: 27.23% of returns are due to "Damaged"
-- 26.89% are due to "Not As Described"
-- 18.48% are due to "Changed Mind"
-- 18.29% are due to "Wrong Item"
-- 9.13% are due to "Defective".


-- 2.24 Order returns -- category inconsistencies
-- Check intentional casing issues
SELECT
    DISTINCT product_category
FROM order_returns_raw
ORDER BY product_category;

-- Finding: Mixed casing visible. Standardization
-- needed in 03_cleaning before joining
-- to product_costs_raw.


-- 2.25 Order returns -- refund amount range
SELECT
    MIN(CAST(refund_amount AS DECIMAL(10,2)))   AS min_refund,
    MAX(CAST(refund_amount AS DECIMAL(10,2)))   AS max_refund,
    ROUND(AVG(CAST(refund_amount AS DECIMAL(10,2))),2)
                                                AS avg_refund,
    ROUND(SUM(CAST(refund_amount AS DECIMAL(10,2))),2)
                                                AS total_refunds
FROM order_returns_raw;

-- Finding: Average refund of $207.44 in ($20.04, $400.95) for
-- a total of $1,659,516.77.


-- ================================================
-- SECTION 10: SELLER ANALYSIS
-- ================================================

-- 2.26 Seller state distribution -- top 10
SELECT
    seller_state,
    COUNT(*) AS seller_count
FROM sellers_raw
GROUP BY seller_state
ORDER BY seller_count DESC
LIMIT 10;

-- Finding: Majority of sellers in SP, followed by
-- PR, MG, SC, RJ, RS.


-- 2.27 Orders per seller distribution
SELECT
    orders_per_seller,
    COUNT(*) AS seller_count
FROM (
    SELECT
        seller_id,
        COUNT(DISTINCT order_id) AS orders_per_seller
    FROM order_items_raw
    GROUP BY seller_id
) AS seller_volumes
GROUP BY orders_per_seller
ORDER BY orders_per_seller DESC
LIMIT 20;

-- Identifies high volume sellers vs long tail
-- of low volume sellers.


-- ================================================
-- SECTION 11: DATA QUALITY SUMMARY
-- ================================================

-- 2.28 Comprehensive NULL check across all
-- key columns in core tables
SELECT
    'orders_raw'        AS table_name,
    'order_id'          AS column_name,
    SUM(CASE WHEN order_id = ''
        OR order_id IS NULL
        THEN 1 ELSE 0 END) AS null_count
FROM orders_raw
UNION ALL
SELECT 'orders_raw', 'customer_id',
    SUM(CASE WHEN customer_id = ''
        OR customer_id IS NULL
        THEN 1 ELSE 0 END)
FROM orders_raw
UNION ALL
SELECT 'order_items_raw', 'price',
    SUM(CASE WHEN price = ''
        OR price IS NULL
        THEN 1 ELSE 0 END)
FROM order_items_raw
UNION ALL
SELECT 'order_items_raw', 'product_id',
    SUM(CASE WHEN product_id = ''
        OR product_id IS NULL
        THEN 1 ELSE 0 END)
FROM order_items_raw
UNION ALL
SELECT 'customers_raw', 'customer_state',
    SUM(CASE WHEN customer_state = ''
        OR customer_state IS NULL
        THEN 1 ELSE 0 END)
FROM customers_raw
UNION ALL
SELECT 'products_raw', 'product_category_name',
    SUM(CASE WHEN product_category_name = ''
        OR product_category_name IS NULL
        THEN 1 ELSE 0 END)
FROM products_raw
ORDER BY null_count DESC;

-- Finding: products_raw.product_category_name contains 610 counts of NULL.
-- Identifies which columns need null handling in 03_cleaning.