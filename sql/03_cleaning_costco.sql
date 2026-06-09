-- ================================================
-- COSTCO WHOLESALE E-COMMERCE BUSINESS INTELLIGENCE
-- ================================================
-- FILE 03: DATA CLEANING
-- Purpose: Create clean, analysis-ready versions
-- of all raw tables with proper data types,
-- standardized categorical values, filtered
-- records, and consistent naming conventions.
-- Raw tables are never modified.
--
-- Cleaning decisions documented from
-- 02_exploration findings:
--   - Orders filtered to 'delivered' status only
--   - 610 products with missing category assigned
--     to 'Uncategorized'
--   - 2 Portuguese categories without translation
--     manually mapped via CASE WHEN override
--   - Marketing channel names standardized
--   - Return category casing standardized
--   - All date columns converted to DATE/DATETIME
--   - All numeric columns cast to DECIMAL or INT
-- ================================================

USE costco_ecommerce;


-- ================================================
-- TABLE 1: CUSTOMERS CLEAN
-- ================================================

DROP TABLE IF EXISTS customers_clean;

CREATE TABLE customers_clean AS
SELECT
    TRIM(customer_id)           AS customer_id,
    TRIM(customer_unique_id)    AS customer_unique_id,
    TRIM(customer_zip_code)     AS customer_zip_code,
    TRIM(customer_city)         AS customer_city,
    TRIM(customer_state)        AS customer_state
FROM customers_raw
WHERE customer_id IS NOT NULL
AND customer_id != '';

-- Verify
SELECT COUNT(*) AS customers_clean_rows
FROM customers_clean;
-- Findings: 99,441 cleaned rows.


-- ================================================
-- TABLE 2: ORDERS CLEAN
-- Filtered to delivered orders only (96,478)
-- All timestamp columns converted to DATETIME
-- ================================================

DROP TABLE IF EXISTS orders_clean;

CREATE TABLE orders_clean AS
SELECT
    TRIM(order_id)                      AS order_id,
    TRIM(customer_id)                   AS customer_id,
    TRIM(order_status)                  AS order_status,
    STR_TO_DATE(NULLIF(TRIM(order_purchase_timestamp), ''),
    '%Y-%m-%d %H:%i:%s')                AS order_purchase_timestamp,
	STR_TO_DATE(NULLIF(TRIM(order_approved_at), ''),
    '%Y-%m-%d %H:%i:%s')                AS order_approved_at,
	STR_TO_DATE(NULLIF(TRIM(order_delivered_carrier_date), ''),
    '%Y-%m-%d %H:%i:%s')                AS order_delivered_carrier_date,
	STR_TO_DATE(NULLIF(TRIM(order_delivered_customer_date), ''),
    '%Y-%m-%d %H:%i:%s')                AS order_delivered_customer_date,
	STR_TO_DATE(NULLIF(TRIM(order_estimated_delivery_date), ''),
    '%Y-%m-%d %H:%i:%s')                AS order_estimated_delivery_date
FROM orders_raw
WHERE order_status = 'delivered'
AND order_id IS NOT NULL
AND order_id != '';

-- Verify
SELECT COUNT(*) AS orders_clean_rows
FROM orders_clean;
-- Findings: 96,478 cleaned rows.

-- Verify date conversion worked
SELECT
    MIN(order_purchase_timestamp)   AS earliest_order,
    MAX(order_purchase_timestamp)   AS latest_order
FROM orders_clean;
-- Expected: chronological dates 2016-2018
-- Finding: orders_clean spans Sep-2016 to Aug-2018
-- after filtering to delivered status only.
-- Orders placed in late 2018 (Sep-Oct) excluded
-- because delivery was not yet confirmed at the
-- time of dataset snapshot -- these appear as
-- 'shipped' or 'processing' in orders_raw.
-- This is expected behavior and does not indicate
-- data loss -- simply reflects the natural lag
-- between order placement and delivery completion.
-- Revenue analysis therefore covers approximately
-- 2 full years of completed transaction data.


-- ================================================
-- TABLE 3: ORDER ITEMS CLEAN
-- price and freight_value cast to DECIMAL
-- shipping_limit_date converted to DATETIME
-- ================================================

DROP TABLE IF EXISTS order_items_clean;

CREATE TABLE order_items_clean AS
SELECT
    TRIM(order_id)                                      AS order_id,
    CAST(TRIM(order_item_id) AS UNSIGNED)               AS order_item_id,
    TRIM(product_id)                                    AS product_id,
    TRIM(seller_id)                                     AS seller_id,
    STR_TO_DATE(NULLIF(TRIM(shipping_limit_date), ''),
        '%Y-%m-%d %H:%i:%s')                            AS shipping_limit_date,
    CAST(TRIM(price) AS DECIMAL(10,2))                  AS price,
    CAST(TRIM(freight_value) AS DECIMAL(10,2))          AS freight_value
FROM order_items_raw
WHERE order_id IS NOT NULL
AND order_id != ''
AND price IS NOT NULL
AND price != '';

-- Verify
SELECT COUNT(*) AS order_items_clean_rows
FROM order_items_clean;
-- Findings: 112,650 clean rows.

-- Verify price range looks correct
SELECT
    MIN(price)          AS min_price,
    MAX(price)          AS max_price,
    ROUND(AVG(price),2) AS avg_price
FROM order_items_clean;


-- ================================================
-- TABLE 4: ORDER PAYMENTS CLEAN
-- payment_value cast to DECIMAL
-- payment_sequential and installments cast to INT
-- Note: orders may have multiple payment rows --
-- handled in analysis via SUM aggregation
-- ================================================

DROP TABLE IF EXISTS order_payments_clean;

CREATE TABLE order_payments_clean AS
SELECT
    TRIM(order_id)                                AS order_id,
    CAST(TRIM(payment_sequential) AS UNSIGNED)    AS payment_sequential,
    TRIM(payment_type)                            AS payment_type,
    CAST(TRIM(payment_installments) AS UNSIGNED)  AS payment_installments,
    CAST(TRIM(payment_value) AS DECIMAL(10,2))    AS payment_value
FROM order_payments_raw
WHERE order_id IS NOT NULL
AND order_id != '';

-- Verify
SELECT COUNT(*) AS order_payments_clean_rows
FROM order_payments_clean;
-- Finding: 103,886 cleaned rows.


-- ================================================
-- TABLE 5: ORDER REVIEWS CLEAN
-- review_score cast to INT
-- date columns converted to DATETIME
-- ================================================
SET SESSION sql_mode = '';
DROP TABLE IF EXISTS order_reviews_clean;

CREATE TABLE order_reviews_clean AS
SELECT
    TRIM(review_id)                                         AS review_id,
    TRIM(order_id)                                          AS order_id,
    CAST(TRIM(review_score) AS UNSIGNED)                    AS review_score,
    TRIM(review_comment_title)                              AS review_comment_title,
    TRIM(review_comment_message)                            AS review_comment_message,
    STR_TO_DATE(NULLIF(TRIM(review_creation_date), ''),
        '%Y-%m-%d %H:%i:%s')                                AS review_creation_date,
    STR_TO_DATE(NULLIF(TRIM(review_answer_timestamp), ''),
        '%Y-%m-%d %H:%i:%s')                                AS review_answer_timestamp
FROM order_reviews_raw
WHERE review_id IS NOT NULL
AND review_id != ''
AND review_score IS NOT NULL
AND review_score != '';

-- Finding: 99,223 rows created successfully.
-- 1 warning (Error 1411) -- one row contained
-- an unparseable date value in review_creation_date
-- or review_answer_timestamp. Converted to NULL
-- by MySQL with sql_mode = '' rather than
-- stopping the import. Single NULL date row has
-- no material impact on review score analysis.
-- Date-dependent review queries will naturally
-- exclude this row via NULL handling.

-- Verify
SELECT COUNT(*) AS order_reviews_clean_rows
FROM order_reviews_clean;

-- Verify score range
SELECT
    MIN(review_score) AS min_score,
    MAX(review_score) AS max_score
FROM order_reviews_clean;
-- Finding: Minimum score of 1 to 5 maximum.


-- ================================================
-- TABLE 6: PRODUCTS CLEAN
-- Three-step category mapping:
--   Step 1: Join to category_translation_raw
--           for Portuguese → English translation
--   Step 2: CASE WHEN override for 2 untranslated
--           Portuguese categories (from 2.12)
--   Step 3: CASE WHEN mapping English categories
--           to Costco department names
-- Products with no category: 'Uncategorized'
-- ================================================

DROP TABLE IF EXISTS category_translation_clean;

CREATE TABLE category_translation_clean AS
SELECT
    TRIM(BOTH '\r' FROM 
         TRIM(product_category_name))          AS product_category_name,
    TRIM(BOTH '\r' FROM
         TRIM(product_category_name_english))  AS product_category_name_english
FROM category_translation_raw;

-- Data Quality Note: category_translation_raw
-- contained hidden carriage return characters
-- (\r, hex 0D) appended to every value in the
-- product_category_name_english column -- a result
-- of Windows line endings (\r\n) where MySQL
-- stripped \n during import but retained \r.
-- Symptom: all string equality comparisons against
-- translation values returned 0 matches despite
-- values appearing correct visually.
-- Diagnosis: HEX() revealed 0D suffix on every value.
-- Fix: created category_translation_clean using
-- TRIM(BOTH '\r' FROM column) to strip carriage
-- returns before joining to products_raw.
-- category_translation_clean used in all subsequent
-- joins -- category_translation_raw preserved
-- as original reference.


DROP TABLE IF EXISTS products_clean;

CREATE TABLE products_clean AS
SELECT
    TRIM(p.product_id)                          AS product_id,

    -- Step 1 + 2: Portuguese to English with
    -- manual override for untranslated categories
   CASE
    WHEN TRIM(ct.product_category_name_english)
         IN ('computers_accessories', 'computers',
             'consoles_games', 'tablets_printing_image')
         OR TRIM(p.product_category_name) = 'pc_gamer'
        THEN 'Electronics & Computers'
    WHEN TRIM(ct.product_category_name_english)
         IN ('telephony', 'fixed_telephony')
        THEN 'Mobile & Wireless'
    WHEN TRIM(ct.product_category_name_english)
         IN ('electronics', 'audio',
             'small_appliances',
             'small_appliances_home_oven_and_coffee')
        THEN 'Consumer Electronics'
    WHEN TRIM(ct.product_category_name_english)
         IN ('furniture_decor', 'furniture_living_room',
             'furniture_bedroom',
             'furniture_mattress_and_upholstery',
             'kitchen_dining_laundry_garden_furniture')
        THEN 'Home Furnishings'
    WHEN TRIM(ct.product_category_name_english)
         IN ('bed_bath_table', 'housewares',
             'home_appliances', 'home_appliances_2',
             'la_cuisine', 'home_confort',
             'home_comfort_2')
         OR TRIM(p.product_category_name)
         = 'portateis_cozinha_e_preparadores_de_alimentos'
        THEN 'Home & Kitchen'
    WHEN TRIM(ct.product_category_name_english)
         IN ('home_construction', 'market_place')
        THEN 'Home Goods'
    WHEN TRIM(ct.product_category_name_english)
         IN ('garden_tools', 'costruction_tools_garden')
        THEN 'Garden & Outdoor'
    WHEN TRIM(ct.product_category_name_english)
         IN ('sports_leisure', 'fashion_sport',
             'fashio_female_clothing',
             'fashion_male_clothing',
             'fashion_underwear_beach',
             'fashion_childrens_clothes')
        THEN 'Sporting Goods & Outdoor'
    WHEN TRIM(ct.product_category_name_english)
         IN ('toys', 'baby', 'diapers_and_hygiene')
        THEN 'Toys & Baby'
    WHEN TRIM(ct.product_category_name_english)
         IN ('health_beauty', 'perfumery')
        THEN 'Health & Beauty'
    WHEN TRIM(ct.product_category_name_english)
         IN ('food_drink', 'food', 'drinks')
        THEN 'Grocery & Food Court'
    WHEN TRIM(ct.product_category_name_english)
         IN ('watches_gifts', 'jewelry',
             'christmas_supplies', 'party_supplies')
        THEN 'Jewelry & Watches'
    WHEN TRIM(ct.product_category_name_english)
         IN ('auto', 'air_conditioning')
        THEN 'Automotive'
    WHEN TRIM(ct.product_category_name_english)
         IN ('stationery', 'office_furniture',
             'industry_commerce_and_business',
             'agro_industry_and_commerce',
             'security_and_services')
        THEN 'Business & Office'
    WHEN TRIM(ct.product_category_name_english)
         IN ('pet_shop')
        THEN 'Pet Supplies'
    WHEN TRIM(ct.product_category_name_english)
         IN ('books_general_interest', 'books_technical',
             'books_imported', 'cds_dvds_musicals',
             'dvds_blu_ray', 'music', 'cine_photo')
        THEN 'Books & Media'
    WHEN TRIM(ct.product_category_name_english)
         IN ('fashion_bags_accessories',
             'fashion_shoes', 'luggage_accessories')
        THEN 'Apparel & Accessories'
    WHEN TRIM(ct.product_category_name_english)
         IN ('construction_tools_safety',
             'construction_tools_lights',
             'construction_tools_construction',
             'costruction_tools_tools',
             'signaling_and_security')
        THEN 'Hardware & Tools'
    WHEN TRIM(ct.product_category_name_english)
         IN ('small_appliances',
             'small_appliances_home_oven_and_coffee')
        THEN 'Appliances'
    WHEN TRIM(ct.product_category_name_english)
         IN ('cool_stuff', 'flowers',
             'arts_and_craftmanship', 'art',
             'musical_instruments')
        THEN 'Seasonal & Specialty'
    WHEN p.product_category_name IS NULL
         OR TRIM(p.product_category_name) = ''
        THEN 'Uncategorized'
    ELSE 'Uncategorized'
END                                             AS costco_department,

    CAST(TRIM(p.product_name_lenght)
         AS UNSIGNED)                           AS product_name_length,
    CAST(TRIM(p.product_description_lenght)
         AS UNSIGNED)                           AS product_description_length,
    CAST(TRIM(p.product_photos_qty)
         AS UNSIGNED)                           AS product_photos_qty,
    CAST(TRIM(p.product_weight_g)
         AS DECIMAL(10,2))                      AS product_weight_g,
    CAST(TRIM(p.product_length_cm)
         AS DECIMAL(10,2))                      AS product_length_cm,
    CAST(TRIM(p.product_height_cm)
         AS DECIMAL(10,2))                      AS product_height_cm,
    CAST(TRIM(p.product_width_cm)
         AS DECIMAL(10,2))                      AS product_width_cm
FROM products_raw p
LEFT JOIN category_translation_clean ct
    ON TRIM(p.product_category_name)
    = TRIM(ct.product_category_name);

-- Verify
SELECT COUNT(*) AS products_clean_rows
FROM products_clean;
-- Finding: 32,951 cleaned rows.

-- Verify Costco department mapping
SELECT
    costco_department,
    COUNT(*) AS product_count
FROM products_clean
GROUP BY costco_department
ORDER BY product_count DESC;

-- Verify Uncategorized count
SELECT COUNT(*) AS uncategorized_products
FROM products_clean
WHERE costco_department = 'Uncategorized';

-- Findings: 610 uncategorized products.

-- ================================================
-- TABLE 7: SELLERS CLEAN
-- ================================================

DROP TABLE IF EXISTS sellers_clean;

CREATE TABLE sellers_clean AS
SELECT
    TRIM(seller_id)         AS seller_id,
    TRIM(seller_zip_code)   AS seller_zip_code,
    TRIM(seller_city)       AS seller_city,
    TRIM(seller_state)      AS seller_state
FROM sellers_raw
WHERE seller_id IS NOT NULL
AND seller_id != '';

-- Verify
SELECT COUNT(*) AS sellers_clean_rows
FROM sellers_clean;
-- Expected: 3,095


-- ================================================
-- TABLE 8: MARKETING SPEND CLEAN
-- Channel names standardized via CASE WHEN
-- Month converted from TEXT to DATE
-- spend_amount and new_customers cast to numerics
-- ================================================

DROP TABLE IF EXISTS marketing_spend_clean;

CREATE TABLE marketing_spend_clean AS
SELECT
    STR_TO_DATE(
        CONCAT('01-', month), '%d-%b-%Y')       AS month_date,

    -- Standardize channel names
    -- Inconsistencies found in 02_exploration 2.20:
    --   'Email Marketing' → 'Email'
    --   'ppc'             → 'PPC'
    --   'social media'    → 'Social Media'
    CASE
        WHEN LOWER(TRIM(channel))
             IN ('email', 'email marketing',
                 'e-mail', 'emails')
            THEN 'Email'
        WHEN LOWER(TRIM(channel))
             IN ('ppc', 'pay per click',
                 'paid search')
            THEN 'PPC'
        WHEN LOWER(TRIM(channel))
             IN ('social media', 'social',
                 'social_media')
            THEN 'Social Media'
        WHEN LOWER(TRIM(channel))
             IN ('seo', 'organic', 'search')
            THEN 'SEO'
        WHEN LOWER(TRIM(channel))
             IN ('influencer', 'influencers',
                 'influencer marketing')
            THEN 'Influencer'
        ELSE TRIM(channel)
    END                                         AS channel,

    CAST(TRIM(spend_amount) AS DECIMAL(10,2))         AS spend_amount,
    CAST(TRIM(new_customers_acquired) AS UNSIGNED)    AS new_customers_acquired
FROM marketing_spend_raw
WHERE month IS NOT NULL
AND month != '';

-- Verify
SELECT COUNT(*) AS marketing_spend_clean_rows
FROM marketing_spend_clean;
-- Findings: 180 cleaned rows.

-- Verify channel standardization
SELECT DISTINCT channel
FROM marketing_spend_clean
ORDER BY channel;
-- Findings: Correct field names: Email, Influencer, PPC, SEO, Social Media

-- Verify date conversion
SELECT
    MIN(month_date) AS earliest_month,
    MAX(month_date) AS latest_month
FROM marketing_spend_clean;
-- Finding: Marketing spend from Jan-2016 to Dec-2018.


-- ================================================
-- TABLE 9: PRODUCT COSTS CLEAN
-- product_costs_raw is the reference/lookup table
-- kept clean during generation (Title Case)
-- Only type casting needed here
-- ================================================

DROP TABLE IF EXISTS product_costs_clean;

CREATE TABLE product_costs_clean AS
SELECT
    TRIM(product_category)                         AS product_category,
    CAST(TRIM(unit_cost) AS DECIMAL(10,2))         AS unit_cost,
    CAST(TRIM(avg_selling_price) AS DECIMAL(10,2)) AS avg_selling_price,
    TRIM(supplier_region)                          AS supplier_region,
    CAST(TRIM(gross_margin_pct) AS DECIMAL(5,2))   AS gross_margin_pct
FROM product_costs_raw
WHERE product_category IS NOT NULL
AND product_category != '';

-- Verify
SELECT COUNT(*) AS product_costs_clean_rows
FROM product_costs_clean;
-- Expected: 20


-- ================================================
-- TABLE 10: ORDER RETURNS CLEAN
-- product_category standardized via CASE WHEN
-- Inconsistencies found in 02_exploration 2.24:
--   'electronics & computers' → 'Electronics & Computers'
--   'Home & kitchen'          → 'Home & Kitchen'
--   'home goods'              → 'Home Goods'
--   'SPORTING GOODS & OUTDOOR'→ 'Sporting Goods & Outdoor'
-- ================================================

DROP TABLE IF EXISTS order_returns_clean;

CREATE TABLE order_returns_clean AS
SELECT
    TRIM(return_id)                             AS return_id,
    TRIM(order_id)                              AS order_id,

    -- Standardize category casing
    CASE
        WHEN TRIM(LOWER(product_category))
             = 'electronics & computers'
            THEN 'Electronics & Computers'
        WHEN TRIM(LOWER(product_category))
             = 'home & kitchen'
            THEN 'Home & Kitchen'
        WHEN TRIM(LOWER(product_category))
             = 'home goods'
            THEN 'Home Goods'
        WHEN TRIM(LOWER(product_category))
             = 'sporting goods & outdoor'
            THEN 'Sporting Goods & Outdoor'
        ELSE TRIM(product_category)
    END                                        AS product_category,

    TRIM(return_reason)                                     AS return_reason,
    STR_TO_DATE(NULLIF(TRIM(return_date), ''), '%m/%d/%Y')  AS return_date,
    CAST(TRIM(refund_amount) AS DECIMAL(10,2))              AS refund_amount,
    CAST(TRIM(restocking_fee) AS DECIMAL(10,2))             AS restocking_fee
FROM order_returns_raw
WHERE return_id IS NOT NULL
AND return_id != '';

-- Verify
SELECT COUNT(*) AS order_returns_clean_rows
FROM order_returns_clean;
-- Findings: 8,000 cleaned rows.

-- Verify category standardization
SELECT DISTINCT product_category
FROM order_returns_clean
ORDER BY product_category;
-- Findings: All 20 categories are Title Case.

-- Verify return reason distribution
SELECT
    return_reason,
    COUNT(*) AS count
FROM order_returns_clean
GROUP BY return_reason
ORDER BY count DESC;


-- ================================================
-- FINAL VERIFICATION
-- Confirm all clean tables created with
-- correct row counts
-- ================================================

SELECT 'customers_clean'        AS table_name,
       COUNT(*) AS row_count FROM customers_clean
UNION ALL
SELECT 'orders_clean',
       COUNT(*) FROM orders_clean
UNION ALL
SELECT 'order_items_clean',
       COUNT(*) FROM order_items_clean
UNION ALL
SELECT 'order_payments_clean',
       COUNT(*) FROM order_payments_clean
UNION ALL
SELECT 'order_reviews_clean',
       COUNT(*) FROM order_reviews_clean
UNION ALL
SELECT 'products_clean',
       COUNT(*) FROM products_clean
UNION ALL
SELECT 'sellers_clean',
       COUNT(*) FROM sellers_clean
UNION ALL
SELECT 'marketing_spend_clean',
       COUNT(*) FROM marketing_spend_clean
UNION ALL
SELECT 'product_costs_clean',
       COUNT(*) FROM product_costs_clean
UNION ALL
SELECT 'order_returns_clean'        AS table_name,
       COUNT(*) AS row_count FROM order_returns_clean
UNION ALL
SELECT 'category_translation_clean',
       COUNT(*) FROM category_translation_clean
ORDER BY table_name;

-- FINAL VERIFICATION RESULTS:
-- category_translation_clean :  71
-- customers_clean            :  99,441
-- marketing_spend_clean      :  180
-- order_items_clean          :  112,650
-- order_payments_clean       :  103,886
-- order_returns_clean        :  8,000
-- order_reviews_clean        :  99,223  (1 null date, documented above)
-- orders_clean               :  96,478  (delivered orders only)
-- product_costs_clean        :  20
-- products_clean             :  32,951
-- sellers_clean              :  3,095
--
-- All clean tables verified. Raw tables preserved
-- untouched as original reference. Ready to
-- proceed to 04_star_schema.sql.