# Bank Customer Churn Analysis (PostgreSQL)

## 1. Project Overview

This project analyzes **bank customer churn** using SQL on PostgreSQL.

The main goal is to understand **which customers are most likely to leave**, what patterns predict churn, and how a bank could use these insights to design targeted retention campaigns. The workflow mirrors real churn work done at Canadian banks and telecoms, where churn directly impacts monthly recurring revenue and customer lifetime value.

I wrote all analysis in SQL and executed it using **pgAdmin on macOS**, focusing on clean, readable queries that can be discussed line by line in interviews.

---

## 2. Business Context

Customer churn is one of the most important metrics for subscription and relationship-based businesses such as:

- Banks (RBC, TD, Scotiabank, etc.)
- Telecoms (Bell, Telus, Rogers)
- Insurance and SaaS companies

Every customer who leaves reduces revenue and often costs more to replace than to retain.  
This project answers questions that a bank’s analytics or CRM team would care about, such as:

- Which customer segments have the highest churn rates?
- Are new customers more at risk than long-tenured customers?
- How does engagement (products held, activity level) affect churn?
- Can we assign a risk label (High / Medium / Low) to active customers so that retention teams know whom to prioritize?

---

## 3. Dataset

- **Source:** [Kaggle – Bank Customer Churn Dataset](https://www.kaggle.com/datasets/gauravtopre/bank-customer-churn-dataset)
- **Rows:** ~10,000 customers
- **Type:** Snapshot of bank customers with a churn flag (no transaction history)

### 3.1 Key Columns

Typical columns in this dataset include:

- `customer_id` – unique customer identifier
- `credit_score`
- `country` – e.g., France, Spain, Germany
- `gender`
- `age`
- `tenure` – years with the bank
- `balance` – account balance
- `products_number` – number of products held (accounts, loans, cards)
- `credit_card` – 1 if the customer has a credit card, 0 otherwise
- `active_member` – 1 if the customer is considered active, 0 otherwise
- `estimated_salary`
- `churn` (or `Exited`) – 1 if the customer has churned, 0 if they are still with the bank

> **Important:** This is a **point-in-time** dataset. There are no event timestamps (like exact churn dates), so the analysis focuses on **who** has churned and **which segments** are at higher risk, not on month-by-month churn trends.

---

## 4. Tech Stack

- **Database:** PostgreSQL
- **Client:** pgAdmin on macOS
- **Language:** SQL
- **Data Source:** Kaggle CSV file loaded into a PostgreSQL table

---

## 5. Repository Structure

> Adjust file names here to match your actual file(s). If you currently keep everything in one `.sql` file, that’s totally fine — you can refactor into multiple files later.

- `README.md` – this document
- `churn_analysis.sql` – all SQL queries for:
  - Table creation
  - Data quality checks
  - Churn analysis
  - Risk scoring

---

## 6. Data Model

This project uses a single main table:

```text
bank_customer_churn
```

Suggested schema:

```sql
CREATE TABLE bank_customer_churn (
    customer_id      INT PRIMARY KEY,
    credit_score     INT,
    country          VARCHAR(50),
    gender           VARCHAR(10),
    age              INT,
    tenure           INT,
    balance          NUMERIC(15,2),
    products_number  INT,
    credit_card      INT,
    active_member    INT,
    estimated_salary NUMERIC(15,2),
    churn            INT
);
```

- `customer_id` is the primary key.
- Binary flags (`credit_card`, `active_member`, `churn`) are stored as `INT` (0/1) for easy CSV import and flexible logic.
- Monetary fields use `NUMERIC(15,2)` to avoid rounding issues.

---

## 7. How to Run This Project

### 7.1 Prerequisites

- PostgreSQL installed locally
- pgAdmin installed (used as the SQL interface)
- Kaggle account to download the dataset

### 7.2 Steps

1. **Create the database**

   In pgAdmin:
   - Right-click **Databases** → **Create** → **Database…**
   - Name it `portfolio_churn` (or any name you prefer)
   - Save

2. **Create the table**

   - Open **Query Tool** on the new database.
   - Run the `CREATE TABLE` statement from `churn_analysis.sql`.

3. **Import the CSV**

   - Right-click the `bank_customer_churn` table → **Import/Export…**
   - Set:
     - Filename: path to the downloaded Kaggle CSV
     - Format: CSV
     - Header: checked (if the file has column names)
     - Delimiter: `,`
   - Click **OK** to import.

   Verify row count:

   ```sql
   SELECT COUNT(*) FROM bank_customer_churn;
   ```

4. **Run the analysis queries**

   - Open `churn_analysis.sql` in pgAdmin’s Query Tool.
   - Run sections step by step:
     - Overall churn rate
     - Churn by tenure cohorts
     - Churn by geography
     - Churn vs financial profile
     - Risk scoring (High / Medium / Low)

---

## 8. Analysis Outline

All queries live in `churn_analysis.sql`. They are organized into logical sections, each answering a specific business question.

### 8.1 Overall Churn Rate

**Goal:** Understand the baseline percentage of customers who have churned.

Key ideas:

- Use `COUNT(*)` to get total customers.
- Use `SUM(CASE WHEN churn = 1 THEN 1 ELSE 0 END)` to count churned customers.
- Compute a percentage as `churned / total`.

Example output (placeholder):

- Total customers: 10,000
- Churned customers: X
- Churn rate: Y %

### 8.2 Churn by Tenure Cohorts

**Goal:** Check whether newer customers are more likely to churn.

Approach:

- Create tenure bands (e.g., `0–1 years`, `2–3 years`, `4–5 years`, `6+ years`) using a `CASE` expression.
- Use a CTE (`WITH tenure_cohorts AS (...)`) to assign each customer to a band.
- Compute churn rate per band with `GROUP BY tenure_band`.

Business interpretation:

- If churn is highest in the `0–1 years` band, the onboarding and early experience may need attention.

### 8.3 Churn by Geography (Country)

**Goal:** Identify regions with unusually high churn rates.

Approach:

- Group by `country`.
- Use conditional aggregation to get churn counts and churn rates per country.

Business interpretation:

- Regions with significantly higher churn may require local campaigns, pricing changes, or product tweaks.

### 8.4 Churn vs Financial Profile

**Goal:** Compare key financial metrics between churned and retained customers.

Possible metrics:

- Average balance (`AVG(balance)`)
- Average estimated salary (`AVG(estimated_salary)`)

Approach:

- Group by `churn` (0 vs 1).
- Compute averages per group.

Business interpretation:

- If high-value customers (large balances) are churning, that is a red flag and may indicate issues with premium service or relationship management.

### 8.5 Short-Tenure Customers (< 1 Year)

**Goal:** Specifically quantify churn risk for customers who have been with the bank less than a year.

Approach:

- Filter using `WHERE tenure < 1`.
- Calculate churn rate for this group.
- Compare with overall churn rate.

Business interpretation:

- A much higher churn rate for new customers suggests you should focus on onboarding, education, and early engagement.

### 8.6 Subquery and NOT IN (Anti-Join Pattern)

**Goal:** Demonstrate SQL proficiency with subqueries and show how to find customers missing a behavior.

Example scenario:

- Identify churned customers who were **never active members**.

Approach:

- Main query selects `churn = 1`.
- Subquery finds all `customer_id` where `active_member = 1`.
- Use `customer_id NOT IN (subquery)` to get churned customers who were never active.

Business interpretation:

- These customers may have churned because they never really engaged with the bank’s products.

---

## 9. Churn Risk Scoring (High / Medium / Low)

**Goal:** Assign a simple **risk label** to each active customer based on their profile, so a retention team can prioritize outreach.

### 9.1 Logic

The risk score is a sum of points from several rules:

- **Tenure**
  - ≤ 1 year: +2 points
  - 2–3 years: +1 point
  - > 3 years: 0 points

- **Balance**
  - < 50,000: +2 points
  - 50,000–100,000: +1 point
  - > 100,000: 0 points

- **Active Member**
  - Not active (`active_member = 0`): +2 points
  - Active: 0 points

- **Number of Products**
  - 1 product: +2 points
  - 2 products: +1 point
  - 3+ products: 0 points

Total risk score is then mapped to labels:

- Score ≥ 6 → **High** risk
- Score 3–5 → **Medium** risk
- Score < 3 → **Low** risk

### 9.2 Implementation

Approach:

- Use a CTE (`WITH risk_scored AS (...)`) to calculate `churn_risk_score` for **active customers** (`churn = 0`).
- In the outer query, use `CASE` to convert the numeric score into a label: `High`, `Medium`, `Low`.
- Order by `churn_risk_score DESC` to see the riskiest customers first.

Business interpretation:

- This is a simple rules engine that could feed into a **retention campaign list** or a **CRM system**.
- In a real bank, these rules would be refined using historical data and/or machine learning, but rule-based scoring is often used as a starting point.

---

## 10. SQL Concepts Demonstrated

This project is designed to showcase core SQL skills that are frequently tested in data analyst and analytics engineer interviews:

- **Data definition**
  - Creating tables with appropriate data types and constraints

- **Data manipulation and aggregation**
  - `SELECT`, `WHERE`, `GROUP BY`, `ORDER BY`
  - `COUNT`, `SUM`, `AVG`, `ROUND`

- **Conditional logic**
  - Using `CASE` in both `SELECT` and aggregate expressions

- **Cohort and segmentation analysis**
  - Tenure bands and geographical segments

- **Common Table Expressions (CTEs)**
  - Multi-step logic using `WITH ... AS (...)`

- **Subqueries and anti-joins**
  - `NOT IN (subquery)` to find customers missing a behavior

- **Business thinking**
  - Translating raw columns into churn insights
  - Designing a practical churn risk scoring framework

---

## 11. Real-World Relevance

Although this project uses a public dataset, the structure of the work matches real churn analysis tasks at banks and telecoms:

- Segment customers by tenure, geography, and products.
- Identify high-risk groups and quantify their churn rate.
- Build simple rules to score and rank customers by churn risk.
- Communicate findings in plain language so business stakeholders can act.

This makes it a strong portfolio project and a great conversation piece in interviews.

---

## 12. Next Steps / Possible Extensions

Future improvements to this project could include:

- Adding a visualization layer (e.g., Power BI, Tableau) on top of the churn metrics.
- Exporting risk-scored customer lists and simulating retention campaigns.
- Extending the rules or exploring a machine learning model for churn prediction.
- Creating stored procedures or views for commonly used churn metrics.

---

## 13. Author

**Name:** *Sudhanva Pathak*  
**Role:** Data Analyst / Data Engineering Enthusiast  

Feel free to connect with me on LinkedIn to discuss churn analysis, SQL, or data analytics projects.
