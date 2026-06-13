-- =============================================================
-- Project: Costco Wholesale E-Commerce Business Intelligence
-- File:    05_analysis_core.sql
-- Purpose: Core business analysis — revenue, profitability,
--          customers, delivery, marketing, and returns
-- Schema:  costco_ecommerce (star schema)
-- =============================================================

USE costco_ecommerce;

-- =============================================================
-- SECTION 1: REVENUE & PROFITABILITY OVERVIEW
-- =============================================================

-- 1A. Total revenue, gross profit, and AOV by year
-- Shows top-line business performance trend over 3 years.
-- Gross profit = revenue minus cost of goods sold.
-- AOV (average order value) measures basket size per transaction.
SELECT
    dd.year,
    COUNT(DISTINCT fo.order_id) AS total_orders,
    ROUND(SUM(fo.revenue), 2) AS total_revenue,
    ROUND(SUM(fo.gross_profit), 2) AS total_gross_profit,
    ROUND(SUM(fo.gross_profit) / SUM(fo.revenue) * 100, 2) AS gross_margin_pct,
    ROUND(SUM(fo.revenue) / COUNT(DISTINCT fo.order_id), 2) AS avg_order_value
FROM fact_orders fo
JOIN dim_date dd ON fo.date_id = dd.date_id
GROUP BY dd.year
ORDER BY dd.year;

-- Finding: 2016 is a partial year (Sep–Dec only) with 267 orders
-- and $40.8K revenue — not comparable to full years and excluded
-- from trend interpretation. 2017–2018 show healthy YoY growth:
-- +21.6% revenue ($6.0M → $7.3M) and +21.5% order volume (43K → 53K).
-- AOV declined slightly from $139 to $138, suggesting a modest shift
-- toward lower-ticket purchases over time rather than a pricing issue.
-- Gross margin held stable at ~44% across both full years, confirming
-- consistent department pricing strategy. Notably, revenue growth was
-- driven primarily by repeat purchase behavior rather than new customer
-- acquisition — monthly new customer counts remained flat across the
-- entire period (Section 7C), meaning the 21.6% revenue growth came
-- from existing customers ordering more frequently or in larger volumes.

-- ---------------------------------------------------------------

-- 1B. Monthly revenue, gross profit, and AOV (all years combined)
-- Reveals seasonality patterns. Useful for Power BI time-series line chart.
SELECT
    dd.year,
    dd.month_num,
    dd.month_name,
    COUNT(DISTINCT fo.order_id) AS total_orders,
    ROUND(SUM(fo.revenue), 2) AS total_revenue,
    ROUND(SUM(fo.gross_profit), 2) AS total_gross_profit,
    ROUND(SUM(fo.gross_profit) / SUM(fo.revenue) * 100, 2) AS gross_margin_pct,
    ROUND(SUM(fo.revenue) / COUNT(DISTINCT fo.order_id), 2) AS avg_order_value
FROM fact_orders fo
JOIN dim_date dd ON fo.date_id = dd.date_id
GROUP BY dd.year, dd.month_num, dd.month_name
ORDER BY dd.year, dd.month_num;

-- Finding: 2016 monthly data is sparse and partial (Sep, Oct, Dec only)
-- and excluded from trend interpretation. 2017 shows a clear growth
-- trajectory, accelerating from 750 orders in January to a November
-- peak of 7,289 orders — the single highest month across the dataset,
-- likely driven by Black Friday and holiday shopping. December 2017
-- pulled back to 5,513 orders, a typical post-peak pattern. 2018
-- entered at an elevated baseline (~7,000 orders/month) and held
-- relatively flat through August, consistent with a business that has
-- matured from growth phase into steady-state volume. No Q4 seasonal
-- spike appears in 2018 because the dataset ends in August before the
-- holiday period — 2018 full-year figures would likely show a November
-- peak comparable to or exceeding 2017. AOV ranged $125–$153 with no
-- strong seasonal pattern, confirming that basket size is driven by
-- department mix rather than time of year.

-- =============================================================
-- SECTION 2: DEPARTMENT PERFORMANCE
-- =============================================================

-- 2A. Revenue, gross profit, and gross margin % by Costco department
-- Identifies which departments drive revenue vs. which are most profitable.
-- Gross margin % is the key profitability metric — a department with high
-- revenue but low margin may be hurting overall business health.
SELECT
    dp.costco_department,
    COUNT(DISTINCT fo.order_id) AS total_orders,
    COUNT(fo.order_id) AS units_sold,
    ROUND(SUM(fo.revenue), 2) AS total_revenue,
    ROUND(SUM(fo.gross_profit), 2) AS total_gross_profit,
    ROUND(SUM(fo.gross_profit) / SUM(fo.revenue) * 100, 2) AS gross_margin_pct,
    ROUND(AVG(fo.revenue), 2) AS avg_unit_price
FROM fact_orders fo
JOIN dim_products dp ON fo.product_key = dp.product_key
GROUP BY dp.costco_department
ORDER BY total_revenue DESC;

-- Finding: 2016 data is sparse and partial (Sep, Oct, Dec only);
-- excluded from trend interpretation. 2017 shows clear growth
-- trajectory, accelerating from 750 orders in January to a
-- November peak of 7,289 orders — the single highest month
-- across the dataset, likely driven by Black Friday / holiday
-- shopping. December 2017 dipped to 5,513, typical post-peak
-- pullback. 2018 entered at an elevated baseline (~7,000 orders/month)
-- and held relatively flat through August, suggesting the business
-- matured from growth phase into steady-state volume. No strong
-- seasonal spike appears in 2018, possibly because the dataset
-- ends in August before the Q4 holiday period. AOV ranged
-- $125–$153 with no strong seasonal pattern, indicating basket
-- size is driven more by department mix than time of year.

-- ---------------------------------------------------------------

-- 2B. Top 5 departments by gross margin %
-- Highlights Costco's highest-margin product categories.
-- Margin % matters more than raw revenue for long-term profitability.
SELECT
    dp.costco_department,
    ROUND(SUM(fo.revenue), 2) AS total_revenue,
    ROUND(SUM(fo.gross_profit), 2) AS total_gross_profit,
    ROUND(SUM(fo.gross_profit) / SUM(fo.revenue) * 100, 2) AS gross_margin_pct
FROM fact_orders fo
JOIN dim_products dp ON fo.product_key = dp.product_key
GROUP BY dp.costco_department
ORDER BY gross_margin_pct DESC
LIMIT 5;

-- Finding: Health & Beauty is the highest-margin department at 56.3%,
-- generating $920K gross profit on $1.6M revenue — the strongest
-- combination of margin and volume in the top 5. Apparel & Accessories
-- and Home Goods follow at ~52-53% but with significantly lower revenue,
-- indicating niche high-margin categories rather than volume drivers.
-- Seasonal & Specialty ($825K revenue, 51.9%) and Jewelry & Watches
-- ($1.2M revenue, 51.3%) round out the top 5 — both solid margin
-- performers with meaningful revenue scale. All top 5 departments
-- exceed 50% gross margin, well above the company-wide ~44% average,
-- suggesting these are Costco's most profitable product lines and
-- priority candidates for marketing investment.

-- ---------------------------------------------------------------

-- 2C. Bottom 5 departments by gross margin %
-- Loss-making or near-zero margin departments — flag for pricing review.
-- Similar to the Superstore analysis where Tables/Bookcases were loss leaders.
SELECT
    dp.costco_department,
    ROUND(SUM(fo.revenue), 2) AS total_revenue,
    ROUND(SUM(fo.gross_profit), 2) AS total_gross_profit,
    ROUND(SUM(fo.gross_profit) / SUM(fo.revenue) * 100, 2) AS gross_margin_pct
FROM fact_orders fo
JOIN dim_products dp ON fo.product_key = dp.product_key
GROUP BY dp.costco_department
ORDER BY gross_margin_pct ASC
LIMIT 5;

-- Finding: Uncategorized products show 0% gross margin — these are
-- orders where product_category did not match any entry in
-- product_costs_clean, resulting in a COALESCE(gross_margin_pct, 0)
-- fallback. $171K in revenue is effectively invisible to profitability
-- tracking and should be investigated for data completeness.
-- Electronics & Computers is the most concerning legitimate department:
-- $1.3M in revenue but only 25% gross margin — the lowest of any
-- mapped category and well below the ~44% company average. Mobile &
-- Wireless (28.8%) and Consumer Electronics (29.6%) follow the same
-- pattern, confirming that the entire technology segment operates on
-- thin margins. Home Furnishings (40.8%) is below average but
-- significantly healthier than electronics. The technology departments
-- likely require high volume to justify their place in the portfolio
-- and are most vulnerable to margin erosion from discounting or
-- returns.

-- =============================================================
-- SECTION 3: GEOGRAPHIC PERFORMANCE
-- =============================================================

-- 3A. Revenue and order volume by customer state
-- Identifies geographic concentration of the customer base.
-- High revenue states are priority markets for marketing investment.
SELECT
    dc.customer_state,
    COUNT(DISTINCT fo.order_id) AS total_orders,
    COUNT(DISTINCT fo.customer_key) AS unique_customers,
    ROUND(SUM(fo.revenue), 2) AS total_revenue,
    ROUND(SUM(fo.gross_profit), 2) AS total_gross_profit,
    ROUND(SUM(fo.revenue) / COUNT(DISTINCT fo.order_id), 2) AS avg_order_value
FROM fact_orders fo
JOIN dim_customers dc ON fo.customer_key = dc.customer_key
GROUP BY dc.customer_state
ORDER BY total_revenue DESC;

-- Finding: São Paulo (SP) dominates all geographic metrics —
-- 40,519 orders, $5.1M revenue, and 39,259 unique customers —
-- representing roughly 38% of total revenue. Rio de Janeiro (RJ)
-- and Minas Gerais (MG) are distant second and third at $1.8M
-- and $1.6M respectively. The top 3 states alone account for
-- ~64% of total revenue, confirming heavy geographic concentration
-- in Brazil's Southeast region. Notably, smaller Northeast and
-- North states (PB, AL, AC, AP) show the highest AOV ($199–$218),
-- suggesting that customers in lower-volume regions tend to place
-- larger individual orders — possibly due to fewer local alternatives
-- or bulk purchasing behavior. This AOV inversion is worth
-- investigating: high-AOV, low-volume states may represent
-- underpenetrated markets with growth potential if logistics
-- and delivery performance can support them.

-- ---------------------------------------------------------------

-- 3B. Top 10 states by revenue
-- Focused view for executive summary / Power BI bar chart.
SELECT
    dc.customer_state,
    COUNT(DISTINCT fo.order_id) AS total_orders,
    ROUND(SUM(fo.revenue), 2) AS total_revenue,
    ROUND(SUM(fo.gross_profit) / SUM(fo.revenue) * 100, 2) AS gross_margin_pct
FROM fact_orders fo
JOIN dim_customers dc ON fo.customer_key = dc.customer_key
GROUP BY dc.customer_state
ORDER BY total_revenue DESC
LIMIT 10;

-- Finding: Gross margin is remarkably consistent across all top 10
-- states, ranging only from 43.56% (BA) to 44.82% (GO) — a spread
-- of just 1.26 percentage points. This indicates that department
-- mix is nearly uniform across geographies; no single state is
-- disproportionately purchasing high- or low-margin products.
-- Margin uniformity also confirms that pricing strategy is
-- standardized nationally with no regional discounting distorting
-- profitability. For Power BI, geographic margin variance is not
-- a meaningful story — focus the map visualization on revenue
-- volume and AOV instead, where the real regional differences lie.

-- =============================================================
-- SECTION 4: CUSTOMER SATISFACTION
-- =============================================================

-- 4A. Average review score by Costco department
-- Reveals which departments have the highest/lowest customer satisfaction.
-- Low review scores often correlate with product quality or delivery issues.
-- Note: review_score sourced from order_reviews_clean via fact_orders.
SELECT
    dp.costco_department,
    COUNT(fo.review_score) AS reviews_submitted,
    ROUND(AVG(fo.review_score), 2) AS avg_review_score,
    SUM(CASE WHEN fo.review_score >= 4 THEN 1 ELSE 0 END) AS positive_reviews,
    SUM(CASE WHEN fo.review_score <= 2 THEN 1 ELSE 0 END) AS negative_reviews,
    ROUND(SUM(CASE WHEN fo.review_score >= 4 THEN 1 ELSE 0 END) / COUNT(fo.review_score) * 100, 2) 
		AS positive_review_pct
FROM fact_orders fo
JOIN dim_products dp ON fo.product_key = dp.product_key
WHERE fo.review_score IS NOT NULL
GROUP BY dp.costco_department
ORDER BY avg_review_score DESC;

-- Finding: Customer satisfaction is high overall, with all departments
-- scoring between 3.94 and 4.43 out of 5. Books & Media leads at 4.43
-- with an 87.1% positive review rate, likely reflecting low return risk
-- and accurate product descriptions for standardized items. Apparel &
-- Accessories (4.25) and Grocery & Food Court (4.25) also perform well
-- despite being categories typically prone to fit or freshness issues.
-- Home Furnishings scores lowest among mapped departments at 3.96 with
-- only 72.9% positive reviews — consistent with its below-average
-- delivery performance and higher return risk for bulky items.
-- Business & Office (3.97) and Mobile & Wireless (3.98) also sit at
-- the bottom, suggesting technology and office categories face higher
-- customer expectation gaps. Notably, Electronics & Computers (4.01)
-- scores near the bottom despite being a top-revenue department,
-- combining low margin (25%) with middling satisfaction — flagging it
-- as the highest-risk department in the portfolio. The ~0.5 point
-- spread across all departments is relatively narrow, indicating no
-- catastrophically underperforming category, but the bottom quartile
-- (Home Furnishings, Business & Office, Mobile & Wireless) warrants
-- targeted quality and delivery improvement.

-- ---------------------------------------------------------------

-- 4B. Overall review score distribution
-- Snapshot of customer sentiment across all orders.
-- Heavy skew toward 5-star or 1-star is common in e-commerce data.
SELECT
    fo.review_score,
    COUNT(*) AS review_count,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER () * 100, 2) AS pct_of_total
FROM fact_orders fo
WHERE fo.review_score IS NOT NULL
GROUP BY fo.review_score
ORDER BY fo.review_score DESC;

-- Finding: Review score distribution is heavily skewed toward 5-star
-- ratings, with 57.6% of all reviews at the maximum score — a pattern
-- consistent with e-commerce datasets where satisfied customers
-- disproportionately leave positive feedback. Combined 4- and 5-star
-- reviews account for 76.8% of all ratings, indicating strong overall
-- customer sentiment. However, 1-star reviews (11.4%) outnumber
-- 2-star (3.4%) and 3-star (8.4%) combined, forming a classic
-- J-curve distribution typical of online retail — customers tend to
-- leave reviews only when very satisfied or very dissatisfied, with
-- middling experiences going unreviewed. The 11.4% 1-star rate
-- represents 12,620 orders and is the primary driver pulling the
-- overall average below 4.0. Reducing 1-star reviews — likely tied
-- to delivery failures and product description mismatches identified
-- in earlier sections — would have an outsized positive impact on
-- overall rating.

-- =============================================================
-- SECTION 5: PAYMENT ANALYSIS
-- =============================================================

-- 5A. Payment type distribution by order count and revenue
-- Reveals customer payment preferences.
-- Credit card dominance vs. boleto (bank slip) has implications
-- for checkout optimization and fraud risk.
-- Note: payment_type and avg_installments sourced from
-- order_payments_clean via fact_orders (avg_installments column).
-- payment_type is not stored in fact_orders — join to order_payments_clean.
SELECT
    opc.payment_type,
    COUNT(DISTINCT fo.order_id) AS total_orders,
    ROUND(SUM(fo.revenue), 2) AS total_revenue,
    ROUND(COUNT(DISTINCT fo.order_id)
        / SUM(COUNT(DISTINCT fo.order_id)) OVER () * 100, 2) AS pct_of_orders,
    ROUND(AVG(fo.avg_installments), 2) AS avg_installments
FROM fact_orders fo
JOIN order_payments_clean opc ON fo.order_id = opc.order_id
WHERE opc.payment_type IS NOT NULL
GROUP BY opc.payment_type
ORDER BY total_orders DESC;

-- Finding: Credit card is the dominant payment method by a wide margin,
-- accounting for 75.3% of orders and $10.8M in revenue. Boleto (bank
-- slip) is a distant second at 19.5% of orders — its presence reflects
-- the Brazilian market context where a significant portion of the
-- population is unbanked or prefers cash-equivalent payments. Voucher
-- and debit card together account for just 5.2% of orders and are
-- largely insignificant. The average installment count for credit card
-- (3.62) versus boleto and debit card (1.00) confirms that installment
-- purchasing is exclusively a credit card behavior — customers are
-- splitting larger purchases across multiple payments, which likely
-- inflates AOV for credit card orders relative to other methods.
-- From a business optimization standpoint, credit card checkout
-- experience and installment flexibility are the highest-leverage
-- payment levers given their overwhelming share of revenue.

-- =============================================================
-- SECTION 6: DELIVERY PERFORMANCE
-- =============================================================

-- 6A. On-time delivery rate overall
-- on_time_flag = 1 when delivered on or before estimated delivery date.
-- Late = on_time_flag = 0. NULL excluded (no delivery date recorded).
-- Note: fact_orders is already filtered to delivered orders only (orders_clean).
SELECT
    COUNT(*) AS total_delivered_orders,
    SUM(fo.on_time_flag) AS on_time_orders,
    SUM(CASE WHEN fo.on_time_flag = 0 THEN 1 ELSE 0 END) AS late_orders,
    ROUND(SUM(fo.on_time_flag) / COUNT(fo.on_time_flag) * 100, 2) AS on_time_rate_pct,
    ROUND(AVG(fo.days_to_deliver), 2) AS avg_days_to_deliver
FROM fact_orders fo
WHERE fo.on_time_flag IS NOT NULL;

-- Finding: 92.1% of delivered orders arrived on or before the estimated
-- delivery date, reflecting strong overall logistics performance.
-- 8,800 late orders (7.9%) represent the primary driver of negative
-- reviews identified in Section 4. Average delivery time of 12.41 days
-- is notably long by modern e-commerce standards — Amazon Prime has
-- conditioned customers to expect 1-2 day delivery — however this is
-- consistent with Brazil's geographic scale and infrastructure
-- constraints inherent to the Olist dataset. The 92.1% on-time rate
-- should be interpreted in that context rather than benchmarked
-- against US or European logistics standards. Reducing late deliveries
-- even modestly would have outsized impact on the 1-star review rate
-- identified in Section 4B, given the strong correlation between
-- late delivery and negative customer sentiment in e-commerce.

-- ---------------------------------------------------------------

-- 6B. On-time delivery rate by customer state
-- Identifies geographic delivery performance gaps.
-- States with poor on-time rates may need carrier or routing review.
SELECT
    dc.customer_state,
    COUNT(*) AS total_orders,
    SUM(fo.on_time_flag) AS on_time_orders,
    ROUND(SUM(fo.on_time_flag) / COUNT(fo.on_time_flag) * 100, 2) AS on_time_rate_pct,
    ROUND(AVG(fo.days_to_deliver), 2) AS avg_days_to_deliver
FROM fact_orders fo
JOIN dim_customers dc ON fo.customer_key = dc.customer_key
WHERE fo.on_time_flag IS NOT NULL
GROUP BY dc.customer_state
ORDER BY on_time_rate_pct ASC;

-- Finding: On-time delivery performance varies significantly by state,
-- revealing a clear geographic divide. Northern and Northeast states
-- perform worst — AL (76.1%), MA (79.9%), and SE (84.0%) sit at the
-- bottom, with average delivery times of 21–24 days, nearly double
-- the national average of 12.41 days. These regions are geographically
-- remote from Brazil's main distribution hubs in the Southeast,
-- explaining both the longer transit times and higher late rates.
-- SP (94.3%, 8.68 days) and MG (94.5%, 11.93 days) are the strongest
-- performers, benefiting from proximity to seller and warehouse
-- concentration. PR (95.2%) and AC (96.7%) are outlier high performers
-- despite AC being a remote Northern state — likely low order volume
-- (91 orders) making the rate less statistically reliable. The
-- correlation between delivery days and on-time rate is strong:
-- states with avg delivery above 20 days almost universally fall
-- below 88% on-time. Improving last-mile logistics in the Northeast
-- is the highest-leverage operational opportunity identified in
-- this analysis.

-- ---------------------------------------------------------------

-- 6C. Average delivery days and on-time rate by department
-- Heavier/bulkier departments (furniture, appliances) may have longer
-- delivery windows — useful for setting customer expectations.
SELECT
    dp.costco_department,
    COUNT(*) AS total_orders,
    ROUND(AVG(fo.days_to_deliver), 2) AS avg_days_to_deliver,
    ROUND(SUM(fo.on_time_flag) / COUNT(fo.on_time_flag) * 100, 2)  AS on_time_rate_pct
FROM fact_orders fo
JOIN dim_products dp ON fo.product_key = dp.product_key
WHERE fo.on_time_flag IS NOT NULL
GROUP BY dp.costco_department
ORDER BY avg_days_to_deliver DESC;

-- Finding: Delivery days vary modestly across departments (10.07–15.46
-- days), with no category dramatically outperforming or underperforming.
-- Business & Office is the slowest at 15.46 days, likely due to bulkier
-- or specialty items requiring longer fulfillment. Grocery & Food Court
-- is fastest at 10.07 days, consistent with smaller, lighter items that
-- move quickly through the fulfillment chain. On-time rate is similarly
-- compressed across departments (90.7%–94.0%), suggesting delivery
-- performance is driven primarily by destination geography — confirmed
-- in 6B — rather than product category. Apparel & Accessories (94.0%)
-- and Pet Supplies (93.9%) lead on-time performance while also being
-- among the fastest delivered, reinforcing their strong customer
-- satisfaction scores in Section 4A. Electronics & Computers and
-- Home Furnishings, already flagged as underperformers on margin and
-- satisfaction, also sit below the on-time average at 92.3% and 91.8%
-- respectively — a consistent pattern of underperformance across
-- multiple dimensions for these two departments.

-- =============================================================
-- SECTION 7: MARKETING PERFORMANCE
-- =============================================================

-- 7A. CAC and ROAS by marketing channel (full period)
-- CAC = cost to acquire one new customer.
-- ROAS = revenue returned per $1 of marketing spend.
-- Pre-calculated in fact_marketing — aggregated here for full-period summary.
-- Lower CAC + higher ROAS = most efficient channel.
SELECT
    fm.channel,
    ROUND(SUM(fm.spend_amount), 2) AS total_spend,
    SUM(fm.new_customers_acquired) AS total_new_customers,
    ROUND(SUM(fm.spend_amount) / NULLIF(SUM(fm.new_customers_acquired), 0), 2)
		AS blended_cac,
    ROUND(SUM(fm.attributed_revenue) / NULLIF(SUM(fm.spend_amount), 0), 2)
		AS blended_roas
FROM fact_marketing fm
GROUP BY fm.channel
ORDER BY blended_roas DESC;

-- Finding: Email is the most efficient marketing channel by a wide
-- margin — lowest CAC at $22.25 and highest ROAS at 5.38, returning
-- $5.38 in attributed revenue per $1 spent. This is nearly 2x the
-- ROAS of SEO (3.00) and 4.5x that of Influencer (1.20). SEO is the
-- second most efficient channel and benefits from compounding returns
-- over time unlike paid channels. PPC acquires the most customers
-- (4,908) at a CAC of $55.52 and ROAS of 2.16 — acceptable for a
-- volume channel but significantly less efficient than Email or SEO.
-- Social Media and Influencer are the weakest performers: Influencer
-- has the highest CAC ($99.94) and lowest ROAS (1.20), barely
-- returning $1.20 per $1 spent. If budget reallocation were
-- recommended, shifting spend from Influencer and Social Media toward
-- Email and SEO would improve blended ROAS meaningfully. Critically,
-- monthly new customer acquisition remained flat across all 36 months
-- despite consistent spend (Section 7C), indicating that total
-- marketing investment was insufficient to drive customer base growth
-- and that revenue expansion was sustained entirely by repeat purchase
-- behavior from existing customers.

-- ---------------------------------------------------------------

-- 7B. Monthly CAC and ROAS by channel
-- Tracks efficiency trends over time per channel.
-- Useful for identifying if a channel is becoming more or less efficient.
SELECT
    fm.channel, fm.month_date, fm.spend_amount, fm.new_customers_acquired, fm.cac, fm.roas
FROM fact_marketing fm
ORDER BY fm.channel, fm.month_date;

-- Finding: CAC and ROAS are essentially flat across all 36 months for
-- every channel — Email holds ~$22 CAC and ~5.38 ROAS with virtually
-- no variation, PPC locks at ~$55.50 CAC and ~2.16 ROAS, and the
-- pattern repeats for all five channels. This is a characteristic of
-- synthetically generated marketing data where CAC is back-calculated
-- from a fixed formula rather than derived from real campaign variance.
-- No meaningful month-over-month trend, seasonality effect, or
-- efficiency improvement is detectable. For portfolio presentation
-- purposes, 7B is best omitted from the Power BI dashboard in favor
-- of 7A (blended full-period summary) and 7C (new customer acquisition
-- trend), which tell cleaner stories. The lack of channel-level
-- variance over time is noted here as a data limitation inherent to
-- the synthetic marketing dataset.

-- ---------------------------------------------------------------

-- 7C. Monthly new customer acquisition trend (all channels combined)
-- Shows whether the business is growing its customer base month over month.
-- Declining acquisition despite flat or rising spend signals channel fatigue.
SELECT
    fm.month_date,
    SUM(fm.new_customers_acquired) AS new_customers_acquired,
    ROUND(SUM(fm.spend_amount), 2) AS total_marketing_spend,
    ROUND(SUM(fm.spend_amount) / NULLIF(SUM(fm.new_customers_acquired), 0), 2)
		AS blended_cac
FROM fact_marketing fm
GROUP BY fm.month_date
ORDER BY fm.month_date;

-- Finding: Total new customer acquisition across all channels shows
-- no meaningful growth trend over the 36-month period — monthly
-- acquisition fluctuates between ~219 and ~431 customers with no
-- sustained upward trajectory. This is the most significant marketing
-- insight in the dataset: while order volume grew 21.6% from 2017
-- to 2018 (Section 1A), new customer acquisition remained flat,
-- suggesting that revenue growth was driven primarily by repeat
-- purchases from the existing customer base rather than new customer
-- acquisition. Blended CAC hovers between $53–$68 throughout with
-- no efficiency improvement over time, consistent with the flat
-- per-channel CAC observed in 7B. Total monthly marketing spend
-- ranges from ~$12.5K to ~$26K with no clear scaling investment.
-- For a business growing at 21% YoY, flat acquisition spend and
-- flat new customer counts suggest the growth engine is retention
-- and repeat purchase behavior — a finding that directly motivates
-- the RFM segmentation and cohort retention analysis in
-- 06_advanced_analysis.sql.

-- =============================================================
-- SECTION 8: RETURNS ANALYSIS
-- =============================================================

-- 8A. Return rate and financial impact by Costco department
-- Return rate = returns / total orders for that department.
-- High return rates erode gross profit — particularly damaging in
-- low-margin departments already under pressure.
-- Note: order_returns_clean is a custom synthetic table (8,000 rows).
SELECT
    orc.product_category AS costco_department,
    COUNT(*) AS total_returns,
    ROUND(AVG(orc.refund_amount), 2) AS avg_refund_amount,
    ROUND(SUM(orc.refund_amount), 2) AS total_refund_amount,
    ROUND(COUNT(*) / dept_orders.dept_total * 100, 2)
		AS return_rate_pct
FROM order_returns_clean orc
JOIN (
    SELECT
        dp.costco_department,
        COUNT(*) AS dept_total
    FROM fact_orders fo
    JOIN dim_products dp ON fo.product_key = dp.product_key
    GROUP BY dp.costco_department
) AS dept_orders ON orc.product_category = dept_orders.costco_department
GROUP BY orc.product_category, dept_orders.dept_total
ORDER BY return_rate_pct DESC;

-- Finding: Return rates vary widely across departments, from 2.03%
-- (Home & Kitchen) to 42.98% (Home Goods). However, the top return
-- rate departments — Home Goods (43.0%), Books & Media (41.7%), and
-- Grocery & Food Court (35.9%) — should be interpreted with caution
-- given their relatively low total order volumes (392, 436, and 409
-- orders respectively), making their rates more sensitive to the
-- synthetic return assignment methodology. Average refund amounts are
-- remarkably consistent across all departments ($197–$214), suggesting
-- refund amounts were generated uniformly rather than scaled to actual
-- product prices — a known limitation of the synthetic returns table.
-- Among high-revenue departments, Electronics & Computers (4.24%) and
-- Home Furnishings (4.53%) carry meaningful return exposure given their
-- large order volumes (9,148 and 9,225 orders in Section 6C) —
-- translating to ~388 and ~418 returns and ~$80K in refunds each.
-- Health & Beauty has the lowest return rate of any mapped department
-- at 3.09%, reinforcing its position as the strongest overall
-- department: highest margin (56.3%), strong satisfaction (4.20),
-- solid on-time rate (91.4%), and lowest returns. The synthetic nature
-- of this table limits the depth of actionable insight, but the
-- framework demonstrates how return rate analysis would function
-- against real operational data.

-- ---------------------------------------------------------------

-- 8B. Return reason distribution
-- Identifies why customers are returning products.
-- 'Item not as described' and 'defective' are actionable for product/listing improvement.
SELECT
    orc.return_reason,
    COUNT(*) AS return_count,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER () * 100, 2) AS pct_of_returns,
    ROUND(AVG(orc.refund_amount), 2) AS avg_refund_amount,
    ROUND(SUM(orc.refund_amount), 2) AS total_refund_amount
FROM order_returns_clean orc
GROUP BY orc.return_reason
ORDER BY return_count DESC;

-- Finding: Return reasons are relatively evenly distributed across
-- the top four categories, with Damaged (27.2%) and Not As Described
-- (26.9%) together accounting for over half of all returns. Both are
-- operationally actionable — Damaged items point to packaging and
-- fulfillment quality issues, while Not As Described indicates product
-- listing accuracy problems that could be addressed through better
-- photography, descriptions, or quality control. Changed Mind (18.5%)
-- and Wrong Item (18.3%) follow closely, the latter suggesting
-- fulfillment picking errors at a non-trivial rate. Defective returns
-- (9.1%) are the smallest category but carry the highest avg refund
-- at $210.44, consistent with defective items skewing toward higher
-- ticket electronics and appliances. Average refund amounts are again
-- highly consistent across reasons ($205–$210), reflecting the
-- synthetic generation methodology noted in 8A. In a real operational
-- context, Damaged and Not As Described would be the highest-priority
-- categories to reduce given their volume — each percentage point
-- reduction in these two categories alone would recover approximately
-- $4,500–$4,600 in refunds.

-- ---------------------------------------------------------------

-- 8C. Total financial impact of returns
-- Single summary line: total returns, total refunds, and effective
-- revenue after returns are subtracted.
-- Headline number for the Executive Overview dashboard.
SELECT
    COUNT(DISTINCT fo.order_id) AS total_delivered_orders,
    COUNT(DISTINCT orc.order_id) AS total_returned_orders,
    ROUND(COUNT(DISTINCT orc.order_id) / COUNT(DISTINCT fo.order_id) * 100, 2)
		AS overall_return_rate_pct,
    ROUND(SUM(orc.refund_amount), 2) AS total_refunds_issued,
    ROUND(SUM(fo.revenue), 2) AS gross_revenue,
    ROUND(SUM(fo.revenue) - COALESCE(SUM(orc.refund_amount), 0), 2)
		AS net_revenue_after_returns
FROM fact_orders fo
LEFT JOIN order_returns_clean orc ON fo.order_id = orc.order_id;

-- Finding: 7,760 orders were returned out of 96,478 delivered,
-- representing an 8.04% overall return rate. Total refunds issued
-- of $1.87M against gross revenue of $13.35M yields net revenue
-- of $11.48M after returns — a 14.0% reduction from gross to net.
-- The 8.04% return rate is within the normal range for e-commerce
-- (industry average typically 20-30% for apparel, 8-12% for general
-- merchandise), suggesting Costco's fictional e-commerce operation
-- performs reasonably well on returns containment. As noted in 8A
-- and 8B, the synthetic nature of the returns table means these
-- figures reflect modeled estimates rather than derived operational
-- data, and should be treated as directionally illustrative rather
-- than precise. In a real deployment, net revenue after returns would
-- be the primary top-line metric reported to leadership, making the
-- $11.48M figure the most accurate representation of true business
-- revenue generated over the dataset period.

-- =============================================================
-- END OF 05_analysis_core.sql
-- Next file: 06_advanced_analysis.sql
-- (CTEs, window functions, RFM, cohort retention, MoM growth)
-- =============================================================