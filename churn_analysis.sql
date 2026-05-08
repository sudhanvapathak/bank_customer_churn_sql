CREATE TABLE bank_customer_churn (
    customer_id      INT PRIMARY KEY,
    credit_score     INT,
    country          VARCHAR(50),
    gender           VARCHAR(10),
    age              INT,
    tenure           INT,
    balance          NUMERIC(15,2),
    products_number  INT,
    credit_card      INT,   -- 0 or 1
    active_member    INT,   -- 0 or 1
    estimated_salary NUMERIC(15,2),
    churn            INT    -- 0 (retained), 1 (churned)
);

SELECT count(*) FROM bank_customer_churn;

-- Basic churn sanity check on the given data.

SELECT 
	COUNT(*) AS total_customers,
	SUM(CASE WHEN churn = 1 THEN 1 ELSE 0 END) AS churned_customers, 
	ROUND(100.0 * SUM(CASE WHEN churn = 1 THEN 1 ELSE 0 END)/COUNT(*), 2) AS churn_rate_pct
FROM bank_customer_churn

-- Now that we have identified that 2037 customers have been churned,
-- First bucket customers into tenure bands, then compute churn within each band

WITH tenure_cohorts AS (
    SELECT
        customer_id,
        tenure,
        churn,
        CASE
            WHEN tenure BETWEEN 0 AND 1 THEN '0–1 years'
            WHEN tenure BETWEEN 2 AND 3 THEN '2–3 years'
            WHEN tenure BETWEEN 4 AND 5 THEN '4–5 years'
            ELSE '6+ years'
        END AS tenure_band
    FROM bank_customer_churn
)
SELECT
    tenure_band,
    COUNT(*) AS customers_in_band,
    SUM(CASE WHEN churn = 1 THEN 1 ELSE 0 END) AS churned_in_band,
    ROUND(100.0 * SUM(CASE WHEN churn = 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate_pct
FROM tenure_cohorts
GROUP BY tenure_band
ORDER BY churn_rate_pct DESC;

-- If we take a careful look at the data the riskiest customers are newly joined members
-- Which means they have either joined the bank for some promotional perks and once gained left the services.

-- Now let us find which is the most challenging area for our business

SELECT
    country,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN churn = 1 THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(100.0 * SUM(CASE WHEN churn = 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate_pct
FROM bank_customer_churn
GROUP BY country
ORDER BY churn_rate_pct DESC;

-- With all the areas we operate in Germany is the most challenging region 

SELECT
    churn,
    ROUND(AVG(balance), 2) AS avg_balance,
    ROUND(AVG(estimated_salary), 2) AS avg_estimated_salary
FROM bank_customer_churn
GROUP BY churn;

-- With the data above we can identify that our highest paid individuals are leaving 
-- This might be the result of additional fees we are charging to them based on salary 
-- Or missing perks we are offering to those who have competative less salary.

SELECT
    COUNT(*) AS total_lt_1_year,
    SUM(CASE WHEN churn = 1 THEN 1 ELSE 0 END) AS churned_lt_1_year,
    ROUND(100.0 * SUM(CASE WHEN churn = 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate_pct_lt_1_year
FROM bank_customer_churn
WHERE tenure < 1;

-- Here we can identify that 23% of our recently joined customers are not willing to stay with us 
-- This might be because of temperory offers 

SELECT
    customer_id,
    country,
    age,
    balance
FROM bank_customer_churn
WHERE churn = 1
  AND customer_id NOT IN (
      SELECT customer_id
      FROM bank_customer_churn
      WHERE active_member = 1
  );
-- From above query we can identify that the data consists most number of inactive customers
-- which might be the resaon for high churn rate.

WITH risk_scored AS (
    SELECT
        customer_id,
        credit_score,
        country,
        age,
        tenure,
        balance,
        products_number,
        active_member,
        churn,
        (
            CASE
                WHEN tenure <= 1 THEN 2
                WHEN tenure BETWEEN 2 AND 3 THEN 1
                ELSE 0
            END
            +
            CASE
                WHEN balance < 50000 THEN 2
                WHEN balance BETWEEN 50000 AND 100000 THEN 1
                ELSE 0
            END
            +
            CASE
                WHEN active_member = 0 THEN 2
                ELSE 0
            END
            +
            CASE
                WHEN products_number = 1 THEN 2
                WHEN products_number = 2 THEN 1
                ELSE 0
            END
        ) AS churn_risk_score
    FROM bank_customer_churn
    WHERE churn = 0  -- only active customers
)
SELECT
    customer_id,
    credit_score,
    country,
    age,
    tenure,
    balance,
    products_number,
    active_member,
    churn_risk_score,
    CASE
        WHEN churn_risk_score >= 6 THEN 'High'
        WHEN churn_risk_score BETWEEN 3 AND 5 THEN 'Medium'
        ELSE 'Low'
    END AS churn_risk_label
FROM risk_scored
ORDER BY churn_risk_score DESC;