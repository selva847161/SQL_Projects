---Data Cleaning and Validation
---Null Check

SELECT
     SUM(CASE WHEN ACC_ID IS NULL THEN 1 ELSE 0 END) AS NULL_ACC_ID,
     SUM(CASE WHEN ACC_SIZE IS NULL THEN 1 ELSE 0 END) AS NULL_ACC_SIZE,
     SUM(CASE WHEN ACC_TARGETS IS NULL THEN 1 ELSE 0 END) AS NULL_ACC_TARGETS,
     SUM(CASE WHEN ACC_TYPE IS NULL THEN 1 ELSE 0 END) AS NULL_ACC_TYPE,
     SUM(CASE WHEN COMP_BRAND IS NULL THEN 1 ELSE 0 END) AS NULL_COMP_BRAND,
     SUM(CASE WHEN [MONTH] IS NULL THEN 1 ELSE 0 END) AS NULL_MONTH,
     SUM(CASE WHEN DISTRICT IS NULL THEN 1 ELSE 0 END) AS NULL_DISTRICT,
     SUM(CASE WHEN F1 IS NULL THEN 1 ELSE 0 END) AS NULL_F1,
     SUM(CASE WHEN QTY IS NULL THEN 1 ELSE 0 END) AS NULL_QTY,
     SUM(CASE WHEN SALES IS NULL THEN 1 ELSE 0 END) AS NULL_SALES,
     SUM(CASE WHEN SALES_VISIT_1 IS NULL THEN 1 ELSE 0 END) AS NULL_SALES_VISIT_1,
     SUM(CASE WHEN SALES_VISIT_2 IS NULL THEN 1 ELSE 0 END) AS NULL_SALES_VISIT_2,
     SUM(CASE WHEN SALES_VISIT_3 IS NULL THEN 1 ELSE 0 END) AS NULL_SALES_VISIT_3,
     SUM(CASE WHEN SALES_VISIT_4 IS NULL THEN 1 ELSE 0 END) AS NULL_SALES_VISIT_4,
     SUM(CASE WHEN SALES_VISIT_5 IS NULL THEN 1 ELSE 0 END) AS NULL_SALES_VISIT_5,
     SUM(CASE WHEN STRATEGY_1 IS NULL THEN 1 ELSE 0 END) AS NULL_STRATEGY_1,
     SUM(CASE WHEN STRATEGY_2 IS NULL THEN 1 ELSE 0 END) AS NULL_STRATEGY_2,
     SUM(CASE WHEN STRATEGY_3 IS NULL THEN 1 ELSE 0 END) AS NULL_STRATEGY_3
FROM drug_data;


---Blank or Empty Strings
SELECT *
FROM drug_data
WHERE 
ACC_ID = '' OR ACC_TYPE = '';

---Duplicate Detection
SELECT 
ACC_ID,ACC_SIZE,ACC_TARGETS,ACC_TYPE,COMP_BRAND,[MONTH],DISTRICT,F1,QTY,SALES,
SALES_VISIT_1,SALES_VISIT_2,SALES_VISIT_3,SALES_VISIT_4,SALES_VISIT_5,STRATEGY_1,
STRATEGY_2,STRATEGY_3,COUNT(*) AS CNT 
FROM drug_data
GROUP BY 
ACC_ID,ACC_SIZE,ACC_TARGETS,ACC_TYPE,COMP_BRAND,[MONTH],DISTRICT,F1,QTY,SALES,
SALES_VISIT_1,SALES_VISIT_2,SALES_VISIT_3,SALES_VISIT_4,SALES_VISIT_5,STRATEGY_1,
STRATEGY_2,STRATEGY_3
HAVING COUNT(*) > 1;

---Creating Schema
---Dimension Tables
---Month Table
CREATE TABLE dim_month(
    month_id INT IDENTITY(1,1) PRIMARY KEY,
    full_date DATE,
    [year] INT,
    [quarter] INT,
    [month] INT,
    month_name VARCHAR(20),
    [day] INT,
    [week] INT
);


---Brand Table
CREATE TABLE dim_brand(
    brand_id INT IDENTITY(1,1) PRIMARY KEY,
    comp_brand INT
);

---Account Table
CREATE TABLE dim_account(
    acc_key INT IDENTITY(1,1) PRIMARY KEY,
    acc_id VARCHAR(20),
    acc_size INT,
    acc_targets INT,
    acc_type VARCHAR(30)
);

---Frequency Table
CREATE TABLE dim_frequency(
    freq_id INT IDENTITY(1,1) PRIMARY KEY,
    F1 INT
);

---Fact Table
CREATE TABLE fact_drug_data(
    fact_id INT IDENTITY(1,1) PRIMARY KEY,
    
    District INT NOT NULL,
    Qty INT NOT NULL,
    Sales DECIMAL(18,2) NOT NULL,
    Sales_Visit_1 DECIMAL(18,2) NOT NULL,
    Sales_Visit_2 DECIMAL(18,2) NOT NULL,
    Sales_Visit_3 DECIMAL(18,2) NOT NULL,
    Sales_Visit_4 DECIMAL(18,2) NOT NULL,
    Sales_Visit_5 DECIMAL(18,2) NULL,
    Strategy_1 DECIMAL(18,2) NOT NULL,
    Strategy_2 DECIMAL(18,2) NOT NULL,
    Strategy_3 DECIMAL(18,2) NULL,

    month_id INT NOT NULL,
    brand_id INT NOT NULL,
    acc_key INT NOT NULL,
    freq_id INT NOT NULL,

    FOREIGN KEY (month_id) REFERENCES dim_month(month_id),
    FOREIGN KEY (brand_id) REFERENCES dim_brand(brand_id),
    FOREIGN KEY (acc_key) REFERENCES dim_account(acc_key),
    FOREIGN KEY (freq_id) REFERENCES dim_frequency(freq_id)
);

---Insert data in tables
---dim_month
INSERT INTO dim_month(full_date,year,quarter,month,month_name,day,week)
SELECT DISTINCT
       [Month],
       YEAR([Month]),
       DATEPART(QUARTER,[Month]),
       MONTH([Month]),
       DATENAME(MONTH,[Month]),
       DAY([Month]),
       DATEPART(WEEK,[Month])
FROM drug_data
WHERE [Month] IS NOT NULL;

---dim_account
INSERT INTO dim_account(acc_id,acc_size,acc_targets,acc_type)
SELECT DISTINCT
       acc_id,
       acc_size,
       acc_targets,
       acc_type 
FROM drug_data;

---dim_brand
INSERT INTO dim_brand(comp_brand)
SELECT DISTINCT
       comp_brand
FROM drug_data;

---dim_frequency
INSERT INTO dim_frequency(F1)
SELECT DISTINCT
       F1
FROM drug_data;

---fact_drug_data
INSERT INTO fact_drug_data
(
       district,
       Qty,
       Sales,
       Sales_Visit_1,
       Sales_Visit_2,
       Sales_Visit_3,
       Sales_Visit_4,
       Sales_Visit_5,
       Strategy_1,
       Strategy_2,
       Strategy_3,
       month_id,
       brand_id,
       acc_key,
       freq_id
)
SELECT 
       d.district,
       d.Qty,
       d.Sales,
       d.Sales_Visit_1,
       d.Sales_Visit_2,
       d.Sales_Visit_3,
       d.Sales_Visit_4,
       d.Sales_Visit_5,
       d.Strategy_1,
       d.Strategy_2,
       d.Strategy_3,
       dm.month_id,
       db.brand_id,
       da.acc_key,
       df.freq_id
FROM drug_data d

JOIN dim_month dm
       ON dm.full_date = d.[Month]

JOIN dim_brand db
       ON db.comp_brand = d.comp_brand 

JOIN dim_account da
       ON da.acc_id = d.acc_id 
       AND da.acc_size = d.acc_size 
       AND da.acc_targets = d.acc_targets 
       AND da.acc_type = d.acc_type 

JOIN dim_frequency df
       ON df.F1 = d.F1;

---Checking Joins
SELECT * FROM fact_drug_data f
JOIN dim_account da
ON f.acc_key = da.acc_key 
JOIN dim_brand db
ON f.brand_id = db.brand_id
JOIN dim_frequency df
ON f.freq_id = df.freq_id
JOIN dim_month dm 
ON f.month_id = dm.month_id;


---KPI's
---Total Sales (INR Million)
SELECT 
FORMAT(SUM(Sales)/1000000,'N2') + ' INR Million' AS TOTAL_SALES
FROM  fact_drug_data;

---Total Quantity Sold
SELECT 
SUM(Qty) AS TOTAL_QUANTITY_SOLD
FROM  fact_drug_data;

---Average Sales per Account
SELECT 
da.acc_key,
da.acc_id,
FORMAT(AVG(f.Sales)/1000000,'N2') + ' INR Million'  AS AVERAGE_SALES
FROM fact_drug_data f
JOIN dim_account da
ON f.acc_key = da.acc_key
GROUP BY da.acc_key,
         da.acc_id
ORDER BY AVG(f.Sales) DESC;

---Brand Contribution %
WITH brand_sales AS
(SELECT 
SUM(f.Sales) AS brand_total,
db.comp_brand
FROM fact_drug_data f
JOIN dim_brand db
ON f.brand_id = db.brand_id 
GROUP BY db.comp_brand),
     total_sales as 
(SELECT 
SUM(Sales) AS overall_total
FROM fact_drug_data)
SELECT
b.comp_brand,
FORMAT(t.overall_total/1000000,'N2') + ' INR Million' AS overall_total,
FORMAT(b.brand_total/1000000,'N2') + ' INR Million' AS brand_total,
FORMAT((b.brand_total/t.overall_total) * 100,'N2') + '%' AS brand_contribution_percentage
FROM brand_sales b
CROSS JOIN total_sales t;

---Average Revenue per visit
SELECT
FORMAT(AVG(ISNULL(Sales_Visit_1,0))/1000000,'N3') + ' INR Million' AS Sales_Visit_1_Avg,
FORMAT(AVG(ISNULL(Sales_Visit_2,0))/1000000,'N3') + ' INR Million' AS Sales_Visit_2_Avg,
FORMAT(AVG(ISNULL(Sales_Visit_3,0))/1000000,'N3') + ' INR Million' AS Sales_Visit_3_Avg,
FORMAT(AVG(ISNULL(Sales_Visit_4,0))/1000000,'N3') + ' INR Million' AS Sales_Visit_4_Avg,
FORMAT(AVG(ISNULL(Sales_Visit_5,0))/1000000,'N3') + ' INR Million' AS Sales_Visit_5_Avg
FROM fact_drug_data;


---Strategy Success Rate
WITH strategy_revenue AS
(SELECT 
SUM(ISNULL(Strategy_1,0)) AS S1,
SUM(ISNULL(Strategy_2,0)) AS S2,
SUM(ISNULL(Strategy_3,0)) AS S3
FROM fact_drug_data)
SELECT 
FORMAT((S1*100)/NULLIF((S1+S2+S3),0),'N2') + ' %' AS Strategy_1_Contribution,
FORMAT((S2*100)/NULLIF((S1+S2+S3),0),'N2') + ' %' AS Strategy_2_Contribution,
FORMAT((S3*100)/NULLIF((S1+S2+S3),0),'N2') + ' %' AS Strategy_3_Contribution
FROM strategy_revenue;

--Frequency Effectiveness
SELECT
TOP 10
da.acc_id,
da.acc_type,
df.F1,
FORMAT(SUM(f.Sales)/1000000,'N2') + ' INR Million' AS Revenue_by_frequency
FROM fact_drug_data f
JOIN dim_account da 
ON f.acc_key = da.acc_key
JOIN dim_frequency df
ON f.freq_id = df.freq_id
GROUP BY da.acc_id,
         da.acc_type,
         df.F1
ORDER BY SUM(f.Sales) DESC;

---Deep Dive Analysis
---Account / Customer Contribution
---Top 10 revenue generating customers
SELECT
TOP 10
da.acc_id,
da.acc_type,
FORMAT(SUM(f.Sales)/1000000,'N2') + ' INR Million' AS Revenue_by_frequency
FROM fact_drug_data f
JOIN dim_account da 
ON f.acc_key = da.acc_key
GROUP BY da.acc_id,
         da.acc_type
ORDER BY SUM(f.Sales) DESC;

---Customers with low sales but high visits
WITH customer_metrics AS
(SELECT 
acc_key AS acc_id,
SUM(Sales)/1000000 AS Total_Revenue,
SUM(
    CASE WHEN Sales_Visit_1 > 0 THEN 1 ELSE 0 END +
    CASE WHEN Sales_Visit_2 > 0 THEN 1 ELSE 0 END +
    CASE WHEN Sales_Visit_3 > 0 THEN 1 ELSE 0 END +
    CASE WHEN Sales_Visit_4 > 0 THEN 1 ELSE 0 END +
    CASE WHEN Sales_Visit_5 > 0 THEN 1 ELSE 0 END
    ) AS Total_Visits
FROM fact_drug_data
GROUP BY acc_key),
    
    benchmarks AS
(SELECT
AVG(Total_Revenue) AS Avg_Revenue,
AVG(Total_Visits) AS Avg_Visits
FROM customer_metrics)

SELECT
c.acc_id,
FORMAT(c.Total_Revenue,'N2') + 'INR Millions' AS Total_Revenue,
c.Total_Visits
FROM customer_metrics c
CROSS JOIN benchmarks b
WHERE 
    c.Total_Revenue < b.Avg_Revenue
AND c.Total_Visits > b.Avg_Visits
ORDER BY c.Total_Visits DESC;

---Customers with zero purchase
SELECT 
da.acc_id,
da.acc_type,
SUM(f.Sales) AS Total_Sales
FROM dim_account da
JOIN fact_drug_data f
ON da.acc_key = f.acc_key
GROUP BY da.acc_id,
         da.acc_type
HAVING SUM(f.Sales) = 0;

---Customer segmentation (high / medium / low value)
WITH customer_revenue AS
(SELECT
da.acc_id,
da.acc_type,
dm.full_date,
SUM(f.Sales) AS Total_Revenue
FROM dim_account da
JOIN fact_drug_data f
ON da.acc_key = f.acc_key
JOIN dim_month dm
ON dm.month_id = f.month_id
GROUP BY da.acc_id,
         da.acc_type,
         dm.full_date)
SELECT
acc_id,
acc_type,
full_date,
Total_Revenue,
CASE 
    WHEN Total_Revenue >= 40000000 THEN 'High_Value'
    WHEN Total_Revenue BETWEEN 10000000 AND 39999999 THEN 'Medium_Value'
    ELSE 'Low_Value' END AS customer_segment
FROM customer_revenue
ORDER BY Total_Revenue DESC;

---Visit Effectiveness Analysis
---Which visit number gives highest conversion?
WITH visit_avg AS
(SELECT 'Visit_1' AS Visit_No,
AVG(ISNULL(Sales_Visit_1,0))/1000000 AS avg_rev FROM fact_drug_data

UNION ALL

SELECT 'Visit_2',
AVG(ISNULL(Sales_Visit_2,0))/1000000 FROM fact_drug_data

UNION ALL

SELECT 'Visit_3',
AVG(ISNULL(Sales_Visit_3,0))/1000000 FROM fact_drug_data

UNION ALL

SELECT 'Visit_4',
AVG(ISNULL(Sales_Visit_4,0))/1000000 FROM fact_drug_data

UNION ALL

SELECT 'Visit_5',
AVG(ISNULL(Sales_Visit_5,0))/1000000 FROM fact_drug_data)

SELECT 
Visit_No,
FORMAT(avg_rev,'N3') + ' INR Million' AS Avg_Revenue
FROM visit_avg
ORDER BY avg_rev DESC;

---Revenue generated per visit (V1 to V5)
WITH revenue_visit AS
(SELECT
'Visit_1' AS Visit_No,
SUM(ISNULL(Sales_Visit_1,0))/1000000 AS rev_per_visit FROM fact_drug_data

UNION ALL

SELECT 
'Visit_2',
SUM(ISNULL(Sales_Visit_2,0))/1000000 FROM fact_drug_data

UNION ALL

SELECT 
'Visit_3',
SUM(ISNULL(Sales_Visit_3,0))/1000000 FROM fact_drug_data

UNION ALL

SELECT 
'Visit_4',
SUM(ISNULL(Sales_Visit_4,0))/1000000 FROM fact_drug_data

UNION ALL

SELECT 
'Visit_5',
SUM(ISNULL(Sales_Visit_5,0))/1000000 FROM fact_drug_data)

SELECT 
Visit_No,
FORMAT(rev_per_visit,'N2') + ' INR Million' AS rev_per_visit,
RANK() OVER(ORDER BY rev_per_visit DESC) AS visit_rank
FROM revenue_visit;

---Strategy Performance Analysis
---Which strategy generates maximum revenue?
WITH max_rev AS
(SELECT 
'Strategy_1' AS Strategy_No,
SUM(ISNULL(Strategy_1,0))/1000000 AS Strategy_Sales FROM fact_drug_data

UNION ALL

SELECT 
'Strategy_2',
SUM(ISNULL(Strategy_2,0))/1000000 FROM fact_drug_data

UNION ALL

SELECT 
'Strategy_3',
SUM(ISNULL(Strategy_3,0))/1000000 FROM fact_drug_data)

SELECT
Strategy_No,
FORMAT(Strategy_Sales,'N2') + ' INR Million' AS str_rev,
RANK() OVER(ORDER BY Strategy_Sales DESC) AS Strategy_Rank
FROM max_rev;

---Strategy success rate by account type
WITH str_rate AS
(SELECT 
da.acc_type,
SUM(ISNULL(f.Strategy_1,0)) AS S1,
SUM(ISNULL(f.Strategy_2,0)) AS S2,
SUM(ISNULL(f.Strategy_3,0)) AS S3
FROM fact_drug_data f
JOIN dim_account da
ON f.acc_key = da.acc_key
GROUP BY da.acc_type)
SELECT 
acc_type,
FORMAT((S1*100)/NULLIF((S1+S2+S3),0),'N3') + ' %' AS str1_success_rate,
FORMAT((S2*100)/NULLIF((S1+S2+S3),0),'N3') + ' %' AS str2_success_rate,
FORMAT((S3*100)/NULLIF((S1+S2+S3),0),'N3') + ' %' AS str3_success_rate
FROM str_rate;

---Quantity vs Revenue Analysis
---High quantity but low revenue accounts
WITH total_qty_sales AS
(SELECT
da.acc_key AS acc_id,
SUM(f.Qty) AS Total_Qty,
SUM(f.Sales)/1000000 AS Total_Revenue
FROM fact_drug_data f
JOIN dim_account da
ON f.acc_key = da.acc_key
GROUP BY da.acc_key),
     account_det AS
(SELECT
AVG(Total_Qty) AS Avg_Qty,
AVG(Total_Revenue) AS Avg_Revenue
FROM total_qty_sales)
SELECT 
t.acc_id,
t.Total_Qty,
FORMAT(Total_Revenue,'N2') + ' INR Million' AS Total_Revenue
FROM total_qty_sales t
CROSS JOIN account_det a
WHERE 
    t.Total_Revenue < a.Avg_Revenue
AND t.Total_Qty > a.Avg_Qty
ORDER BY t.Total_Revenue;





