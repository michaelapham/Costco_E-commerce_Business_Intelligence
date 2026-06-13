# Costco Wholesale — E-commerce Division Case Study 🏤


## The Challenge
You've just joined Costco Wholesale's newly formed E-Commerce Analytics team as a Junior Data Analyst. The division has been running its online storefront for three years, and management has a problem: nobody has a clear picture of what's actually working.
On your first week, your manager drops a Slack message in your inbox:

> *"Hey — before the Q1 business review, I need you to dig into our e-commerce data. Leadership wants to know which product departments are actually profitable, whether our marketing spend is paying off, and why our repeat customer rate feels lower than it should be. We've got three years of order data, customer records, product info, and marketing spend sitting in separate tables. Nobody's connected it all yet. That's your job now. Good luck."*

Three years of transactions. Nine source tables. Three custom data sources. No documentation. No prior analysis.
You have two weeks before the executive presentation.

---

## 📊 The Data

### This case study works with nine source tables

- **`customers.csv`** — Customer IDs, cities, states, zip codes
- **`orders.csv`** — Order IDs, statuses, purchase and delivery timestamps 
- **`order_items.csv`** — Line items with product IDs, prices, freight costs
- **`order_payments.csv`** — Payment types and amounts per order
- **`order_reviews.csv`** — Customer review scores (1–5) and dates  
- **`products.csv`** — Product IDs, department categories, dimensions, weight
- **`sellers.csv`** — Seller IDs and locations
- **`geolocation.csv`** — ZIP code to lat/lng mapping  
- **`category_translation.csv`** — Portuguese to English category name lookup

### and three custom-built tables (Generated in Excel):
  
- **`marketing_spend.csv`** — Monthly spend by channel (SEO, PPC, Email, Social, Influencer) — 2016–2018
- **`product_costs.csv`** — Unit cost, avg selling price, and gross margin by Costco department  
- **`order_returns.csv`** — Return transactions with reason, refund amount, and restocking fee

> **Note:** This project uses a public e-commerce dataset adapted and rebranded for portfolio purposes. All company references are fictional. No proprietary Costco data was used.

---

## 🎯 Business Questions Answered
### 💰 Finance Director
*"I need to understand where we're actually making money — and where we're not."*

1. What is total revenue, gross profit, and gross margin by department?
2. Which departments have the highest and lowest profit margins?
3. How has revenue trended month-over-month and year-over-year?
4. What is the running cumulative revenue total through FY2018?
5. How do freight costs impact net profitability by department?
6. What is the financial impact of returns by department?

### 📣 Marketing Manager
*"Our CAC feels too high. I need to know which channels are actually working."*

1. What is our Customer Acquisition Cost (CAC) by marketing channel?
2. What is our Return on Ad Spend (ROAS) by channel?
3. Which channel delivers the most revenue per marketing dollar?
4. How has new customer acquisition trended over three years?
5. What is the conversion rate from acquired customer to repeat buyer?
6. Which marketing channels are most efficient for high-CLV customers?

### 🛍️ VP of E-Commerce
*"Why aren't customers coming back? And who are our best customers?"*

1. What is the overall repeat purchase rate?
2. What does our RFM segmentation look like — who are our Champions vs. At-Risk customers?
3. What is the average Customer Lifetime Value across segments?
4. Which customer cohorts have the highest 90-day and 180-day retention rates?
5. What percentage of customers have made 2+ orders?
6. Which states have the highest customer concentration and LTV?

### 🏷️ Merchandising Lead
*"I need to know which products to push, which to cut, and which are getting returned too often."*

1. Which product departments rank highest by gross profit?
2. What is the return rate by department and what are the top return reasons?
3. What is the average review score by department — where are quality issues concentrated?
4. Which specific products within each department generate the most profit?
5. How does order volume compare to profitability across departments (volume vs. margin)?
6. What is the on-time delivery rate by department and seller?

---

## 🔍 Key Findings

### Revenue & Growth
- Total delivered revenue of **$13.4M** across 96,478 orders (2016–2018),
  with 2017–2018 YoY growth of **+21.6% revenue** and **+21.5% order volume**
- 2018 cumulative revenue reached **$7.3M through August alone**, already
  exceeding 2017's full-year total — projecting to ~$9.5–10M if Q4 seasonal
  patterns held
- **November 2017** was the single highest revenue month ($1.0M, +52.6% MoM),
  driven by Black Friday and holiday demand
- Revenue growth was sustained entirely by **repeat purchase behavior** from
  existing customers — monthly new customer acquisition remained flat across
  all 36 months despite consistent marketing spend

### Department Performance
- **Health & Beauty** is the strongest department in the portfolio: highest
  gross margin (56.3%), top-3 revenue ($1.6M), strong customer satisfaction
  (4.20 avg review), and lowest return rate (3.09%) — the only department
  excelling across all four dimensions simultaneously
- **Electronics & Computers** is the highest-risk department: third-highest
  revenue ($1.3M) but lowest gross margin (25.0%), below-average satisfaction
  (4.01), and a slight YoY revenue decline in 2018 (-2.5%) while all other
  top departments grew
- The technology segment (Electronics, Mobile, Consumer Electronics) operates
  at 25–30% gross margin — **15–20 percentage points below the company average
  of ~44%** — requiring high volume to justify its place in the portfolio
- **Home & Kitchen** held the #1 revenue rank in both 2017 and 2018 but at a
  mid-tier 46.2% margin, making it a volume driver rather than a profit driver

### Customer Behavior
- **92.1% of customers placed exactly one order**, confirmed by cohort
  retention rates collapsing from 100% at Month 0 to below 1% at Month 1
  across all cohorts — structural single-purchase behavior inherent to the
  Olist marketplace model
- RFM segmentation identified **Champions and Loyal Customers (39.6% of
  customers) generating ~67% of total revenue** ($8.98M), consistent with
  Pareto concentration
- The top 10% of customers by revenue account for **41.2% of total revenue**
  ($5.5M), confirming right-tail concentration typical of e-commerce
- **Needs Attention** customers show an avg recency of 457 days — effectively
  lapsed — making win-back campaigns unlikely to be cost-effective for this segment

### Geographic Performance
- **São Paulo (SP) dominates** with 40,519 orders and $5.1M revenue (~38% of
  total), with the top 3 states (SP, RJ, MG) accounting for ~64% of revenue
- Gross margin is nearly uniform across all states (43.6%–44.8%), indicating
  standardized national pricing with no regional discounting
- **Smaller Northeast and North states show the highest AOV** ($199–$218 vs
  national avg ~$138), suggesting underpenetrated markets where customers
  place larger individual orders — potential growth opportunity if logistics
  can support them

### Delivery & Satisfaction
- Overall on-time delivery rate of **92.1%** across 111,498 delivered orders,
  with an avg delivery time of 12.4 days
- **Northeast states are the weakest delivery performers** — AL (76.1%), MA
  (79.9%), and SE (84.0%) — with avg delivery times of 21–24 days, nearly
  double the national average, driven by geographic distance from seller
  concentration in SP
- Customer satisfaction averages **4.11 out of 5** with a J-curve distribution:
  57.6% five-star reviews but 11.4% one-star reviews, indicating polarized
  sentiment where delivery failures drive disproportionate negative feedback
- **Books & Media** leads satisfaction (4.43) while **Home Furnishings** ranks
  lowest (3.96) — consistent with its longer delivery times and higher return exposure

### Marketing Efficiency
- **Email is the most efficient channel**: $22.25 CAC and 5.38 ROAS —
  4.5x the ROAS of Influencer marketing ($99.94 CAC, 1.20 ROAS)
- **Influencer marketing** delivers the worst return of any channel, barely
  recovering $1.20 per $1 spent — budget reallocation toward Email and SEO
  would meaningfully improve blended ROAS
- New customer acquisition remained **flat across all 36 months** for every
  channel, confirming that marketing investment maintained rather than grew
  the customer base

### Returns
- Overall return rate of **8.04%** (7,760 of 96,478 orders), resulting in
  $1.87M in refunds and net revenue of **$11.48M** after returns
- **Damaged (27.2%)** and **Not As Described (26.9%)** account for over half
  of all returns — both operationally actionable through packaging improvement
  and product listing accuracy
- Health & Beauty's 3.09% return rate vs. Home Goods' 43.0% represents the
  widest performance gap in the portfolio, though high-return-rate departments
  with low order volumes are more sensitive to the synthetic return assignment
  methodology

---

## 📁 Repository Structure
```
costco-ecommerce-business-intelligence/
│
├── data/
│   ├── marketing_spend.csv          ← Custom: monthly spend by channel
│   ├── product_costs.csv            ← Custom: cost and margin by department
│   └── order_returns.csv            ← Custom: return transactions
│
├── sql/
│   ├── 00_create_database.sql       ← Database setup
│   ├── 01_import_raw.sql            ← Load all 12 tables
│   ├── 02_exploration.sql           ← Data quality checks
│   ├── 03_cleaning.sql              ← Type casting, NULLs, category mapping
│   ├── 04_star_schema.sql           ← Fact and dimension table creation
│   ├── 05_analysis_core.sql         ← Revenue, margin, marketing, product queries
│   └── 06_advanced_analysis.sql     ← RFM, CLV, cohort, window functions
│
├── excel/
│   ├── marketing_spend_model.xlsx   ← Marketing data generator
│   ├── product_costs_model.xlsx     ← Cost structure model
│   └── financial_summary.xlsx       ← Profitability summary model
│
├── dashboard/
│   └── costco_ecommerce.pbix        ← Power BI (4 dashboards)
│
├── docs/
│   ├── erd_diagram.png              ← Entity relationship diagram
│   ├── star_schema_diagram.png      ← Data warehouse schema
│   └── business_recommendations.md ← Final findings and action items
│
└── README.md
```
 
---

## 🛠️ Skills Demonstrated

### SQL & Database Engineering (MySQL)
- **Star schema design**: Built a production-style data warehouse with two fact
  tables (`fact_orders`, `fact_marketing`) and four dimension tables
  (`dim_customers`, `dim_products`, `dim_sellers`, `dim_date`), including
  surrogate keys, indexes, and foreign key relationships
- **Large dataset handling**: Imported and transformed 100K+ row datasets using
  `LOAD DATA INFILE`; optimized multi-table fact table creation with
  pre-aggregated temp tables to reduce join complexity
- **Data cleaning**: Standardized inconsistent categorical values, handled NULL
  substitutions with `COALESCE`, unduplicated customers using `customer_unique_id`,
  and validated row counts at each pipeline stage
- **Window functions**: Applied `LAG` for MoM growth, `RANK` and `PERCENT_RANK`
  for revenue ranking, `NTILE` for RFM scoring, and `SUM OVER` for running
  totals and percentage distributions
- **CTEs**: Structured complex multi-step analyses using common table expressions
  to improve readability and avoid nested subquery chains — including
  multi-CTE pipelines for RFM segmentation and cohort retention
- **Cohort analysis**: Implemented full cohort retention table using
  `PERIOD_DIFF` to calculate months since acquisition, joined against cohort
  sizes to produce retention rate curves across 23 monthly cohorts
- **RFM segmentation**: Scored 96,352 customers on Recency, Frequency, and
  Monetary dimensions using `NTILE(5)` and applied business logic segmentation
  into seven customer tiers
- **Aggregation & grouping**: Multi-dimensional aggregations across department,
  geography, time, payment type, seller, and customer segments
- **Subqueries**: Used correlated subqueries for return rate calculations
  requiring department-level order base denominators
- **Sequential file pipeline**: Organized analysis into six numbered SQL files
  (01 import → 02 exploration → 03 cleaning → 04 star schema → 05 core
  analysis → 06 advanced analysis) mirroring enterprise ETL pipeline structure

### Business Analytics
- **Profitability analysis**: Calculated and interpreted gross margin % by
  department, identifying a 31-percentage-point spread between the highest
  (Health & Beauty, 56.3%) and lowest (Electronics, 25.0%) margin categories
- **Customer segmentation**: Applied RFM methodology to segment 96,352
  customers into actionable tiers and quantified revenue concentration using
  Pareto analysis
- **Cohort retention**: Built and interpreted retention curves, correctly
  identifying structural single-purchase behavior and distinguishing it from
  a data quality issue
- **Marketing efficiency**: Evaluated five channels on CAC and ROAS, identified
  budget reallocation opportunities, and recognized synthetic data limitations
  in channel trend analysis
- **Geographic analysis**: Identified market concentration, delivery performance
  gaps by state, and high-AOV underpenetrated markets in the Northeast and
  North regions
- **Trend analysis**: Detected MoM growth patterns, YoY revenue acceleration,
  and the divergence between order volume growth and flat new customer
  acquisition — correctly attributing revenue growth to repeat purchase
  behavior
- **Seller performance**: Designed and applied a multi-criteria seller tiering
  framework combining revenue, on-time rate, and satisfaction score to
  identify Elite, Strong, Average, Developing, and Underperforming segments
- **Honest data interpretation**: Consistently flagged synthetic dataset
  limitations (uniform margins, flat CAC, synthetic returns) rather than
  manufacturing misleading insights — demonstrating analytical integrity

(To be filled in with specifics later)
Power BI
Excel

---

## 🚀 How to Reproduce This Project

1. **Download the source data**
   - Olist Brazilian E-Commerce dataset: [kaggle.com/datasets/olistbr/brazilian-ecommerce](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
   - Download and unzip — 9 CSV files
2. **Generate custom tables**
   - Open `excel/marketing_spend_model.xlsx` and export as CSV
   - Open `excel/product_costs_model.xlsx` and export as CSV
   - `order_returns.csv` is pre-generated in `/data/`
3. **Run SQL scripts in order**
   ```
   00 → 01 → 02 → 03 → 04 → 05 → 06
   ```
   - Each script is self-contained and documented with findings
4. **Open Power BI dashboard**
   - Connect `costco_ecommerce.pbix` to your local MySQL `costco_ecommerce` database
   - Refresh data and explore all four dashboards

---

## Limitations 🛑

- **Synthetic supporting tables**: `product_costs_clean` (margins),
  `marketing_spend_clean` (CAC/ROAS), and `order_returns_clean` (returns)
  were generated to supplement the Olist dataset. Gross margins are uniform
  within each department rather than varying by SKU, marketing CAC is
  arithmetically stable across all 36 months with little to no variance,
  and return rates reflect modeled assignment rather than actual return
  behavior. Findings derived from these tables are directionally illustrative
  rather than operationally precise.

- **Single-purchase customer base**: The Olist dataset reflects a marketplace
  model where most customers transact once through a specific seller. Retention
  rates, RFM segments, and LTV estimates are structurally constrained by this
  behavior and do not reflect what a branded e-commerce operation like Costco
  would realistically produce. Cohort and RFM analyses demonstrate correct
  methodology applied to available data rather than favorable outcomes.

- **Partial year 2016**: Order data begins September 2016, making 2016 a
  ~3.5 month partial year. It is excluded from all YoY comparisons and trend
  analyses to avoid distorting growth calculations.

- **Truncated 2018**: The dataset ends August 29, 2018, omitting Q4 2018.
  Full-year 2018 revenue and the expected November holiday spike are not
  captured, causing 2018 annual totals to understate true full-year performance.

- **Brazilian market context**: The underlying Olist data reflects Brazilian
  e-commerce dynamics — boleto payment prevalence, 12+ day avg delivery times,
  and Northeast/North logistics gaps are artifacts of Brazil's infrastructure
  and geography rather than Costco operational decisions. These are noted
  where relevant rather than presented as US e-commerce benchmarks.

- **No inventory or SKU-level data**: Analysis operates at the product category
  level. SKU-level pricing, stockout analysis, and individual product
  performance are not available in the source dataset.

- **Static seller and customer keys**: Surrogate keys are assigned via
  `ROW_NUMBER()` at schema creation time and are not stable across schema
  rebuilds. Any external reference to specific customer or seller keys would
  require rejoining on natural keys (`customer_unique_id`, `seller_id`).

---

## 💡 Next Steps & Extensions
(To be filled in after analysis is complete to see what would make sense to add next)

---

## 👤 Author
 
- **Michael Pham**  
- [github.com/michaelapham](https://github.com/michaelapham)
- [linkedin.com/in/michaelapham99](https://linkedin.com/in/michaelapham99)
