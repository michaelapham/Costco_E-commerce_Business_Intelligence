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
(Will fill in after analysis is complete)
### Financial Performance

Total Revenue: TBD
Total Gross Profit: TBD
Blended Gross Margin: TBD
Avg Order Value: TBD

### Customer Intelligence

Total Customers: TBD
Repeat Purchase Rate: TBD
Avg Customer LTV: TBD
Top RFM Segment: TBD

### Marketing Efficiency

Blended CAC: TBD
Best ROAS Channel: TBD
Lowest CAC Channel: TBD

### Product Performance

Highest Margin Department: TBD
Lowest Margin Department: TBD
Highest Return Rate Department: TBD

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
(To be filled in with specifics later)
SQL
Power BI
Excel
Business Analytics

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
- Return dates are independently generated within the 2016–2018 range and are not constrained to be post-purchase-date for simplicity.

---

## 💡 Next Steps & Extensions
(To be filled in after analysis is complete to see what would make sense to add next)

---

## 👤 Author
 
**Michael Pham**  
[github.com/michaelapham](https://github.com/michaelapham)
[linkedin.com/in/michaelapham99](https://linkedin.com/in/michaelapham99)
