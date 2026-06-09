-- ================================================
-- COSTCO WHOLESALE E-COMMERCE BUSINESS INTELLIGENCE
-- ================================================
-- FILE 04: STAR SCHEMA
-- Purpose: Transform clean tables into an
-- analytics-ready star schema with one central
-- fact table surrounded by dimension tables.
-- This structure simplifies analysis queries,
-- improves Power BI performance, and mirrors
-- enterprise data warehouse design patterns.
--
-- Schema structure:
--
--              dim_customers
--                    |
-- dim_date ---- fact_orders ---- dim_products
--                    |
--              dim_sellers
--
-- Separate fact table:
--   fact_marketing (joins to dim_date by month)
--
-- Surrogate keys (auto-increment integers) used
-- on all dimension tables for proper data
-- warehouse design and Power BI compatibility.
-- ================================================

USE costco_ecommerce;


-- ================================================
-- DIMENSION TABLE 1: dim_date
-- Built from order purchase timestamps
-- Provides year, quarter, month, day breakdowns
-- for time-series analysis in Power BI
-- ================================================

DROP TABLE IF EXISTS dim_date;

CREATE TABLE dim_date AS
SELECT DISTINCT
    DATE(order_purchase_timestamp)                 AS date_id,
    DATE(order_purchase_timestamp)                 AS full_date,
    YEAR(order_purchase_timestamp)                 AS year,
    QUARTER(order_purchase_timestamp)              AS quarter,
    MONTH(order_purchase_timestamp)                AS month_num,
    MONTHNAME(order_purchase_timestamp)            AS month_name,
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS 'year-month',
    DAYNAME(order_purchase_timestamp)              AS day_name,
    DAYOFWEEK(order_purchase_timestamp)            AS day_of_week,
    CASE
        WHEN QUARTER(order_purchase_timestamp) = 1 THEN 'Q1'
        WHEN QUARTER(order_purchase_timestamp) = 2 THEN 'Q2'
        WHEN QUARTER(order_purchase_timestamp) = 3 THEN 'Q3'
        ELSE 'Q4'
    END   AS quarter_label
FROM orders_clean
WHERE order_purchase_timestamp IS NOT NULL;

-- Add primary key
ALTER TABLE dim_date
ADD PRIMARY KEY (date_id);

-- Verify
SELECT COUNT(*) AS dim_date_rows
FROM dim_date;

SELECT
    MIN(full_date) AS earliest_date,
    MAX(full_date) AS latest_date
FROM dim_date;

-- Finding: dim_date spans 2016-09-15 to 2018-08-29
-- 712 distinct order dates across ~2 full years.
-- Date range reflects delivered orders only --
-- orders placed in late 2018 excluded because
-- delivery was not yet confirmed at dataset
-- snapshot time. Consistent with orders_clean
-- date range verified in 03_cleaning.


-- Check number of rows in dim_date
SELECT COUNT(*) AS dim_date_rows FROM dim_date;

-- Finding: 612 distinct order dates across
-- 2016-09-15 to 2018-08-29. Averages roughly
-- one order date per calendar day over the
-- ~2 year period, with some days having no
-- orders (weekends, holidays).

-- ================================================
-- DIMENSION TABLE 2: dim_customers
-- One row per unique customer
-- Uses customer_unique_id to properly identify
-- repeat customers across multiple orders
-- ================================================

DROP TABLE IF EXISTS dim_customers;

CREATE TABLE dim_customers AS
SELECT
    ROW_NUMBER() OVER (ORDER BY customer_unique_id)  AS customer_key,
    customer_unique_id,
    customer_zip_code,
    UPPER(TRIM(customer_city))     AS customer_city,
    UPPER(TRIM(customer_state))    AS customer_state,
    CASE
        WHEN customer_state IN ('SP','RJ','MG','ES') THEN 'Southeast'
        WHEN customer_state IN ('PR','SC','RS') THEN 'South'
        WHEN customer_state IN ('BA','SE','AL','PE','PB','RN','CE','PI','MA')
            THEN 'Northeast'
        WHEN customer_state IN ('GO','MT','MS','DF') THEN 'Central-West'
        WHEN customer_state IN ('AM','PA','AC','RO','RR','AP','TO')
            THEN 'North'
        ELSE 'Unknown'
    END     AS brazil_region
FROM (
    SELECT DISTINCT
        c.customer_unique_id,
        c.customer_zip_code,
        c.customer_city,
        c.customer_state
    FROM customers_clean c
) AS unique_customers;

-- Modify customer_key column to BIGINT NOT NULL
-- before adding primary key
ALTER TABLE dim_customers
MODIFY COLUMN customer_key BIGINT NOT NULL;

ALTER TABLE dim_customers
ADD PRIMARY KEY (customer_key);

CREATE INDEX idx_customer_unique_id
ON dim_customers (customer_unique_id(50));

-- Verify
SELECT COUNT(*) AS dim_customers_rows
FROM dim_customers;

-- Finding: 96,352 unique customers identified
-- using customer_unique_id deduplication.
-- Difference of 3,089 from customers_clean (99,441)
-- represents repeat customers who placed 2+ orders
-- and appear multiple times in customers_clean
-- under different customer_id values but the same
-- customer_unique_id. Consistent with 2.8 finding
-- that 3,089 customers placed more than one order.


SELECT
    brazil_region,
    COUNT(*) AS customer_count
FROM dim_customers
GROUP BY brazil_region
ORDER BY customer_count DESC;


-- ================================================
-- DIMENSION TABLE 3: dim_products
-- One row per unique product
-- Includes Costco department mapping and
-- cost/margin data from product_costs_clean
-- ================================================

DROP TABLE IF EXISTS dim_products;

CREATE TABLE dim_products AS
SELECT
    ROW_NUMBER() OVER (
        ORDER BY p.product_id)                  AS product_key,
    p.product_id,
    p.costco_department,
    CASE
        WHEN p.costco_department IN (
             'Electronics & Computers',
             'Mobile & Wireless',
             'Consumer Electronics',
             'Appliances')
            THEN 'Technology & Electronics'
        WHEN p.costco_department IN (
             'Home Furnishings',
             'Home & Kitchen',
             'Home Goods',
             'Garden & Outdoor',
             'Hardware & Tools')
            THEN 'Home & Garden'
        WHEN p.costco_department IN (
             'Sporting Goods & Outdoor',
             'Toys & Baby',
             'Seasonal & Specialty')
            THEN 'Sports, Toys & Seasonal'
        WHEN p.costco_department IN (
             'Health & Beauty',
             'Grocery & Food Court',
             'Pet Supplies')
            THEN 'Health, Grocery & Pet'
        WHEN p.costco_department IN (
             'Jewelry & Watches',
             'Apparel & Accessories',
             'Books & Media')
            THEN 'Fashion, Jewelry & Media'
        WHEN p.costco_department IN (
             'Automotive',
             'Business & Office')
            THEN 'Auto & Business'
        ELSE 'Other'
    END      AS department_group,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,
    COALESCE(pc.unit_cost, 0)                 AS unit_cost,
    COALESCE(pc.avg_selling_price, 0)         AS avg_selling_price,
    COALESCE(pc.supplier_region, 'Unknown')   AS supplier_region,
    COALESCE(pc.gross_margin_pct, 0)          AS gross_margin_pct
FROM products_clean p
LEFT JOIN product_costs_clean pc
    ON p.costco_department = pc.product_category;

-- Add primary key
ALTER TABLE dim_products
MODIFY COLUMN product_key BIGINT NOT NULL;

ALTER TABLE dim_products
ADD PRIMARY KEY (product_key);

CREATE INDEX idx_product_id
ON dim_products (product_id(50));

-- Verify
SELECT COUNT(*) AS dim_products_rows
FROM dim_products;

SELECT
    costco_department,
    COUNT(*) AS product_count,
    ROUND(AVG(gross_margin_pct), 2) AS avg_margin_pct
FROM dim_products
GROUP BY costco_department
ORDER BY product_count DESC;


-- ================================================
-- DIMENSION TABLE 4: dim_sellers
-- One row per unique seller
-- ================================================

DROP TABLE IF EXISTS dim_sellers;

CREATE TABLE dim_sellers AS
SELECT
    ROW_NUMBER() OVER (ORDER BY seller_id)      AS seller_key,
    seller_id,
    seller_zip_code,
    UPPER(TRIM(seller_city))                    AS seller_city,
    UPPER(TRIM(seller_state))                   AS seller_state
FROM sellers_clean;

ALTER TABLE dim_sellers
MODIFY COLUMN seller_key BIGINT NOT NULL;

ALTER TABLE dim_sellers
ADD PRIMARY KEY (seller_key);

CREATE INDEX idx_seller_id
ON dim_sellers (seller_id(50));

-- Verify
SELECT COUNT(*) AS dim_sellers_rows
FROM dim_sellers;


-- ================================================
-- FACT TABLE 1: fact_orders
-- Central fact table -- one row per order line item
-- Contains all measurable metrics:
--   revenue, freight, gross_profit, review_score,
--   days_to_deliver, on_time_flag
-- ================================================
-- Pre-aggregate payments into temp table
DROP TABLE IF EXISTS temp_payments;

CREATE TABLE temp_payments AS
SELECT
    order_id,
    SUM(payment_value)                  AS total_payment_value,
    ROUND(AVG(payment_installments), 1) AS avg_installments
FROM order_payments_clean
GROUP BY order_id;

CREATE INDEX idx_temp_payments
ON temp_payments (order_id(50));

DROP TABLE IF EXISTS temp_customer_keys;

CREATE TABLE temp_customer_keys AS
SELECT
    c.customer_id,
    dc.customer_key,
    dc.customer_unique_id
FROM customers_clean c
JOIN dim_customers dc
    ON c.customer_unique_id = dc.customer_unique_id;

CREATE INDEX idx_temp_customer_keys
ON temp_customer_keys (customer_id(50));

SET SESSION net_read_timeout = 9999;
SET SESSION net_write_timeout = 9999;
SET SESSION wait_timeout = 9999;
SET SESSION interactive_timeout = 9999;

DROP TABLE IF EXISTS fact_orders;

CREATE TABLE fact_orders AS
SELECT
    o.order_id,
    ck.customer_key,
    dp.product_key,
    ds.seller_key,
    DATE(o.order_purchase_timestamp)        AS date_id,
    CAST(oi.price AS DECIMAL(10,2))         AS revenue,
    CAST(oi.freight_value AS DECIMAL(10,2)) AS freight_value,
    ROUND(CAST(oi.price AS DECIMAL(10,2))
        * COALESCE(dp.gross_margin_pct, 0)
        / 100, 2)                           AS gross_profit,
    COALESCE(pay.total_payment_value, 0)    AS payment_value,
    r.review_score,
    DATEDIFF(o.order_delivered_customer_date,
        o.order_purchase_timestamp)         AS days_to_deliver,
    CASE
        WHEN o.order_delivered_customer_date IS NULL THEN NULL
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date
            THEN 1
        ELSE 0
    END     AS on_time_flag,
    oi.order_item_id,
    pay.avg_installments
FROM orders_clean o
JOIN order_items_clean oi
    ON o.order_id = oi.order_id
JOIN temp_customer_keys ck
    ON o.customer_id = ck.customer_id
JOIN dim_products dp
    ON oi.product_id = dp.product_id
JOIN dim_sellers ds
    ON oi.seller_id = ds.seller_id
LEFT JOIN temp_payments pay
    ON o.order_id = pay.order_id
LEFT JOIN order_reviews_clean r
    ON o.order_id = r.order_id;

CREATE INDEX idx_fact_orders_date
ON fact_orders (date_id);

CREATE INDEX idx_fact_orders_customer
ON fact_orders (customer_key);

CREATE INDEX idx_fact_orders_product
ON fact_orders (product_key);

-- Verify
SELECT COUNT(*) AS fact_orders_rows
FROM fact_orders;
-- Findings: 111,506 rows.
-- Performance note: fact_orders CREATE TABLE
-- required ~98 minutes to complete due to
-- multi-table join across 96,478 orders and
-- 112,650 line items on local MySQL instance.
-- Pre-aggregated temp_payments and
-- temp_customer_keys tables used to reduce
-- join complexity. In production environment
-- with proper indexing and server hardware
-- this would complete in seconds.
-- temp_payments and temp_customer_keys can be
-- dropped after fact_orders is verified:
DROP TABLE temp_payments;
DROP TABLE temp_customer_keys;

SELECT
    ROUND(SUM(revenue), 2)          AS total_revenue,
    ROUND(SUM(gross_profit), 2)     AS total_gross_profit,
    ROUND(SUM(freight_value), 2)    AS total_freight,
    ROUND(AVG(days_to_deliver), 1)  AS avg_days_to_deliver,
    ROUND(AVG(review_score), 2)     AS avg_review_score,
    ROUND(SUM(on_time_flag) * 100.0
        / COUNT(on_time_flag), 2)   AS on_time_pct
FROM fact_orders;


-- ================================================
-- FACT TABLE 2: fact_marketing
-- One row per month per channel
-- ================================================

DROP TABLE IF EXISTS fact_marketing;

CREATE TABLE fact_marketing AS
SELECT
    ms.month_date,
    ms.channel,
    ms.spend_amount,
    ms.new_customers_acquired,
    ROUND(ms.new_customers_acquired * (SELECT ROUND(AVG(revenue), 2)
            FROM fact_orders), 2)      AS attributed_revenue,
    CASE
        WHEN ms.new_customers_acquired = 0 THEN NULL
        ELSE ROUND(ms.spend_amount / ms.new_customers_acquired, 2)
    END  AS cac,
    CASE
        WHEN ms.spend_amount = 0 THEN NULL
        ELSE ROUND((ms.new_customers_acquired * (SELECT ROUND(AVG(revenue), 2)
                FROM fact_orders)) / ms.spend_amount, 2)
    END AS roas
FROM marketing_spend_clean ms;

-- Verify
SELECT COUNT(*) AS fact_marketing_rows
FROM fact_marketing;
-- Findings: 180 rows.

SELECT
    channel,
    ROUND(SUM(spend_amount), 2)    AS total_spend,
    SUM(new_customers_acquired)    AS total_customers,
    ROUND(AVG(cac), 2)             AS avg_cac,
    ROUND(AVG(roas), 2)            AS avg_roas
FROM fact_marketing
GROUP BY channel
ORDER BY total_spend DESC;


-- ================================================
-- FINAL VERIFICATION
-- ================================================

SELECT 'dim_date'           AS table_name,
       COUNT(*) AS row_count FROM dim_date
UNION ALL
SELECT 'dim_customers',
       COUNT(*) FROM dim_customers
UNION ALL
SELECT 'dim_products',
       COUNT(*) FROM dim_products
UNION ALL
SELECT 'dim_sellers',
       COUNT(*) FROM dim_sellers
UNION ALL
SELECT 'fact_orders',
       COUNT(*) FROM fact_orders
UNION ALL
SELECT 'fact_marketing',
       COUNT(*) FROM fact_marketing
ORDER BY table_name;

-- FINAL STAR SCHEMA VERIFICATION:
-- dim_date        :    612  (distinct order dates)
-- dim_customers   : 96,352  (deduplicated unique customers)
-- dim_products    : 32,951  (all products with dept mapping)
-- dim_sellers     :  3,095  (all sellers)
-- fact_orders     :111,506  (delivered order line items)
-- fact_marketing  :    180  (36 months x 5 channels)
--
-- Star schema complete. All dimension and fact
-- tables verified. Ready for analysis in
-- 05_analysis_core.sql and 06_advanced_analysis.sql.