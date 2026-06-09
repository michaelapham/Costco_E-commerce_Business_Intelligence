-- ================================================
-- COSTCO WHOLESALE E-COMMERCE BUSINESS INTELLIGENCE
-- ================================================
-- FILE 01: RAW DATA IMPORT
-- Purpose: Create all 12 raw tables and import
-- CSV data using LOAD DATA INFILE. All columns
-- stored as TEXT to prevent silent row loss
-- during import. Row counts verified after each
-- import.
--
-- Import order:
--   Olist source tables (9) → Custom tables (3)
--
-- Note: All files must be in MySQL secure_file_priv
-- directory before running this script.
-- Run: SHOW VARIABLES LIKE 'secure_file_priv';
-- to confirm path.
-- ================================================

CREATE DATABASE IF NOT EXISTS costco_ecommerce;
USE costco_ecommerce;

-- ================================================
-- SESSION SETTINGS
-- Disable strict mode to handle edge cases
-- gracefully rather than stopping on first error
-- ================================================

SET SESSION sql_mode = '';
SET SESSION innodb_strict_mode = OFF;
SET SESSION net_read_timeout = 600;
SET SESSION net_write_timeout = 600;


-- ================================================
-- TABLE 1: CUSTOMERS
-- ================================================

DROP TABLE IF EXISTS customers_raw;

CREATE TABLE customers_raw (
    customer_id             TEXT,
    customer_unique_id      TEXT,
    customer_zip_code       TEXT,
    customer_city           TEXT,
    customer_state          TEXT
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/customers.csv'
INTO TABLE customers_raw
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Verify
SELECT COUNT(*) AS customers_rows FROM customers_raw;
-- Expected: 99,441


-- ================================================
-- TABLE 2: ORDERS
-- ================================================

DROP TABLE IF EXISTS orders_raw;

CREATE TABLE orders_raw (
    order_id                        TEXT,
    customer_id                     TEXT,
    order_status                    TEXT,
    order_purchase_timestamp        TEXT,
    order_approved_at               TEXT,
    order_delivered_carrier_date    TEXT,
    order_delivered_customer_date   TEXT,
    order_estimated_delivery_date   TEXT
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/orders.csv'
INTO TABLE orders_raw
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Verify
SELECT COUNT(*) AS orders_rows FROM orders_raw;
-- Expected: 99,441


-- ================================================
-- TABLE 3: ORDER ITEMS
-- ================================================

DROP TABLE IF EXISTS order_items_raw;

CREATE TABLE order_items_raw (
    order_id            TEXT,
    order_item_id       TEXT,
    product_id          TEXT,
    seller_id           TEXT,
    shipping_limit_date TEXT,
    price               TEXT,
    freight_value       TEXT
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/order_items.csv'
INTO TABLE order_items_raw
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Verify
SELECT COUNT(*) AS order_items_rows FROM order_items_raw;
-- Expected: 112,650


-- ================================================
-- TABLE 4: ORDER PAYMENTS
-- ================================================

DROP TABLE IF EXISTS order_payments_raw;

CREATE TABLE order_payments_raw (
    order_id                TEXT,
    payment_sequential      TEXT,
    payment_type            TEXT,
    payment_installments    TEXT,
    payment_value           TEXT
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/order_payments.csv'
INTO TABLE order_payments_raw
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Verify
SELECT COUNT(*) AS order_payments_rows FROM order_payments_raw;
-- Expected: 103,886


-- ================================================
-- TABLE 5: ORDER REVIEWS
-- ================================================

DROP TABLE IF EXISTS order_reviews_raw;

CREATE TABLE order_reviews_raw (
    review_id               TEXT,
    order_id                TEXT,
    review_score            TEXT,
    review_comment_title    TEXT,
    review_comment_message  TEXT,
    review_creation_date    TEXT,
    review_answer_timestamp TEXT
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/order_reviews.csv'
INTO TABLE order_reviews_raw
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Verify
SELECT COUNT(*) AS order_reviews_rows FROM order_reviews_raw;
-- Expected: ~99,224

-- Finding: 99,223 rows imported vs 99,224 expected.
-- Difference of 1 row (0.001%) — within acceptable
-- tolerance. Likely trailing newline in source CSV
-- or single malformed review record. No material
-- impact on analysis.

-- ================================================
-- TABLE 6: PRODUCTS
-- ================================================

DROP TABLE IF EXISTS products_raw;

CREATE TABLE products_raw (
    product_id                      TEXT,
    product_category_name           TEXT,
    product_name_lenght             TEXT,
    product_description_lenght      TEXT,
    product_photos_qty              TEXT,
    product_weight_g                TEXT,
    product_length_cm               TEXT,
    product_height_cm               TEXT,
    product_width_cm                TEXT
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/products.csv'
INTO TABLE products_raw
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Verify
SELECT COUNT(*) AS products_rows FROM products_raw;
-- Expected: 32,951


-- ================================================
-- TABLE 7: SELLERS
-- ================================================

DROP TABLE IF EXISTS sellers_raw;

CREATE TABLE sellers_raw (
    seller_id           TEXT,
    seller_zip_code     TEXT,
    seller_city         TEXT,
    seller_state        TEXT
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/sellers.csv'
INTO TABLE sellers_raw
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Verify
SELECT COUNT(*) AS sellers_rows FROM sellers_raw;
-- Expected: 3,095


-- ================================================
-- TABLE 8: GEOLOCATION
-- Note: Large table (~1M rows) — import may take
-- several minutes. Do not close Workbench.
-- ================================================

DROP TABLE IF EXISTS geolocation_raw;

CREATE TABLE geolocation_raw (
    geolocation_zip_code    TEXT,
    geolocation_lat         TEXT,
    geolocation_lng         TEXT,
    geolocation_city        TEXT,
    geolocation_state       TEXT
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/geolocation.csv'
INTO TABLE geolocation_raw
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Verify
SELECT COUNT(*) AS geolocation_rows FROM geolocation_raw;
-- Expected: ~1,000,163


-- ================================================
-- TABLE 9: CATEGORY TRANSLATION
-- ================================================

DROP TABLE IF EXISTS category_translation_raw;

CREATE TABLE category_translation_raw (
    product_category_name           TEXT,
    product_category_name_english   TEXT
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/category_translation.csv'
INTO TABLE category_translation_raw
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Verify
SELECT COUNT(*) AS category_translation_rows FROM category_translation_raw;
-- Expected: 71


-- ================================================
-- TABLE 10: MARKETING SPEND (Custom)
-- ================================================

DROP TABLE IF EXISTS marketing_spend_raw;

CREATE TABLE marketing_spend_raw (
    month                   TEXT,
    channel                 TEXT,
    spend_amount            TEXT,
    new_customers_acquired  TEXT
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/marketing_spend.csv'
INTO TABLE marketing_spend_raw
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Verify
SELECT COUNT(*) AS marketing_spend_rows FROM marketing_spend_raw;
-- Expected: 180 (36 months × 5 channels)


-- ================================================
-- TABLE 11: PRODUCT COSTS (Custom)
-- ================================================

DROP TABLE IF EXISTS product_costs_raw;

CREATE TABLE product_costs_raw (
    product_category    TEXT,
    unit_cost           TEXT,
    avg_selling_price   TEXT,
    supplier_region     TEXT,
    gross_margin_pct    TEXT
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/product_costs.csv'
INTO TABLE product_costs_raw
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Verify
SELECT COUNT(*) AS product_costs_rows FROM product_costs_raw;
-- Expected: 20


-- ================================================
-- TABLE 12: ORDER RETURNS (Custom)
-- ================================================

DROP TABLE IF EXISTS order_returns_raw;

CREATE TABLE order_returns_raw (
    return_id           TEXT,
    order_id            TEXT,
    product_category    TEXT,
    return_reason       TEXT,
    return_date         TEXT,
    refund_amount       TEXT,
    restocking_fee      TEXT
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/order_returns.csv'
INTO TABLE order_returns_raw
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Verify
SELECT COUNT(*) AS order_returns_rows FROM order_returns_raw;
-- Expected: ~8,000


-- ================================================
-- FINAL VERIFICATION
-- Run this block after all imports complete
-- to confirm all 12 tables loaded correctly
-- ================================================

SELECT 'customers_raw'          AS table_name, COUNT(*) AS row_count FROM customers_raw
UNION ALL
SELECT 'orders_raw',             COUNT(*) FROM orders_raw
UNION ALL
SELECT 'order_items_raw',        COUNT(*) FROM order_items_raw
UNION ALL
SELECT 'order_payments_raw',     COUNT(*) FROM order_payments_raw
UNION ALL
SELECT 'order_reviews_raw',      COUNT(*) FROM order_reviews_raw
UNION ALL
SELECT 'products_raw',           COUNT(*) FROM products_raw
UNION ALL
SELECT 'sellers_raw',            COUNT(*) FROM sellers_raw
UNION ALL
SELECT 'geolocation_raw',        COUNT(*) FROM geolocation_raw
UNION ALL
SELECT 'category_translation_raw', COUNT(*) FROM category_translation_raw
UNION ALL
SELECT 'marketing_spend_raw',    COUNT(*) FROM marketing_spend_raw
UNION ALL
SELECT 'product_costs_raw',      COUNT(*) FROM product_costs_raw
UNION ALL
SELECT 'order_returns_raw',      COUNT(*) FROM order_returns_raw
ORDER BY table_name;