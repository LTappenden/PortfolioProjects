-- Active: 1662630630995@@127.0.0.1@3306@salesdata

SELECT * FROM sales_data_sample;

-- Checking unique values 
SELECT DISTINCT status FROM sales_data_sample;
SELECT DISTINCT year_id FROM sales_data_sample;
SELECT DISTINCT Productline FROM sales_data_sample;
SELECT DISTINCT country FROM sales_data_sample;
SELECT DISTINCT DEALSIZE FROM sales_data_sample;
SELECT DISTINCT TERRITORY FROM sales_data_sample;

--ANALYSIS
--Let's start by grouping sale by PRODUCTLINE
SELECT PRODUCTLINE, sum(sales) AS Revenue
FROM sales_data_sample
GROUP BY PRODUCTLINE
ORDER BY Revenue DESC;

--Grouping sales by YEAR_ID
SELECT YEAR_ID, sum(sales) AS Revenue
FROM sales_data_sample
GROUP BY YEAR_ID
ORDER BY Revenue DESC;

--We can see that the sales in 2005 are quite low, so we will check why
--Checking to see if they operated in the entire year
SELECT DISTINCT month_id FROM sales_data_sample 
WHERE year_id = 2005;
-- We can see that the company only operated for 5 months in 2005 

--Check how many months the company operated in 2003 and 2004
SELECT DISTINCT month_id FROM sales_data_sample 
WHERE year_id = 2003;
SELECT DISTINCT month_id FROM sales_data_sample 
WHERE year_id = 2004;

--Grouping sales by DEALSIZE
SELECT DEALSIZE, sum(sales) AS Revenue
FROM sales_data_sample
GROUP BY DEALSIZE
ORDER BY Revenue DESC;
--The company makes the most money from medium sized deals 

--What was the best month for sales in a specific year and how much was earned in that month?
SELECT MONTH_ID, sum(sales) AS Revenue, count(ORDERNUMBER) AS Frequency 
FROM sales_data_sample
WHERE YEAR_ID = 2004 
GROUP BY MONTH_ID
ORDER BY Revenue DESC;

SELECT MONTH_ID, sum(sales) AS Revenue, count(ORDERNUMBER) AS Frequency 
FROM sales_data_sample
WHERE YEAR_ID = 2003
GROUP BY MONTH_ID
ORDER BY Revenue DESC;

-- We can check 2005 but it is not really a true reflection for the company because they didn't operate the whole year
SELECT MONTH_ID, sum(sales) AS Revenue, count(ORDERNUMBER) AS Frequency 
FROM sales_data_sample
WHERE YEAR_ID = 2005
GROUP BY MONTH_ID
ORDER BY Revenue DESC;

--November seems to be the best month, so what do they sell the most of in November 
--Year ID and Month ID can be changed to see what they sell in other months
SELECT MONTH_ID, PRODUCTLINE, sum(sales) AS Revenue, count(ORDERNUMBER) AS Frequency 
FROM sales_data_sample
WHERE YEAR_ID = 2004 AND MONTH_ID = 11
GROUP BY MONTH_ID, PRODUCTLINE
ORDER BY Revenue DESC;

--What city has the highest number of sales in a specific country
SELECT CITY, sum(sales) AS Revenue
FROM sales_data_sample
WHERE COUNTRY = 'UK'
GROUP BY CITY
ORDER BY Revenue DESC;

--What is the best product in the United States?
SELECT COUNTRY, YEAR_ID, PRODUCTLINE, sum(sales) AS Revenue
FROM sales_data_sample
WHERE country = 'USA'
GROUP BY COUNTRY, YEAR_ID, PRODUCTLINE
ORDER BY Revenue DESC;



--WHO IS THE BEST CUSTOMER?
-- This will be done with an RFM analysis
--RFM is an indexing technique that uses past purchase behaviour to segment customers
SELECT 
    CUSTOMERNAME,
    sum(sales) AS MonetaryValue,
	avg(sales) AS AvgMonetaryValue,
	count(ORDERNUMBER) AS Frequency,		
    max(ORDERDATE) AS last_order_date
FROM sales_data_sample
GROUP BY CUSTOMERNAME;

--Date difference between customers last order date vs the maximum date in the dataset to test the recency
SELECT 
    CUSTOMERNAME,
    sum(sales) AS MonetaryValue,
	avg(sales) AS AvgMonetaryValue,
	count(ORDERNUMBER) AS Frequency,		
    max(ORDERDATE) AS last_order_date,
    (SELECT MAX(ORDERDATE) FROM sales_data_sample) AS max_order_date
FROM sales_data_sample
GROUP BY CUSTOMERNAME;

--DATEDIFF to capture the Recency 
SELECT 
    CUSTOMERNAME,
    sum(sales) AS MonetaryValue,
	avg(sales) AS AvgMonetaryValue,
	count(ORDERNUMBER) AS Frequency,		
    max(ORDERDATE) AS last_order_date,
    (SELECT MAX(ORDERDATE) FROM sales_data_sample) AS max_order_date,
    DATEDIFF(day, max(ORDERDATE), (SELECT MAX(ORDERDATE) FROM sales_data_sample)) AS Recency
FROM sales_data_sample
GROUP BY CUSTOMERNAME;

--Put results into CTE before using an NTILE to spilt the 92 rows of output into 4 equal buckets
;with rfm as 
(
SELECT 
    CUSTOMERNAME,
    sum(sales) AS MonetaryValue,
	avg(sales) AS AvgMonetaryValue,
	count(ORDERNUMBER) AS Frequency,		
    max(ORDERDATE) AS last_order_date,
    (SELECT MAX(ORDERDATE) FROM sales_data_sample) AS max_order_date,
    DATEDIFF(day, max(ORDERDATE), (SELECT MAX(ORDERDATE) FROM sales_data_sample)) AS Recency
FROM sales_data_sample
GROUP BY CUSTOMERNAME
)
SELECT r.*
FROM rfm AS r;

--Now for the bucketing using NTILE 
;with rfm as 
(
SELECT 
    CUSTOMERNAME,
    sum(sales) AS MonetaryValue,
	avg(sales) AS AvgMonetaryValue,
	count(ORDERNUMBER) AS Frequency,		
    max(ORDERDATE) AS last_order_date,
    (SELECT MAX(ORDERDATE) FROM sales_data_sample) AS max_order_date,
    DATEDIFF(day, max(ORDERDATE), (SELECT MAX(ORDERDATE) FROM sales_data_sample)) AS Recency
FROM sales_data_sample
GROUP BY CUSTOMERNAME
)
SELECT r.*,
    NTILE(4) OVER (ORDER BY Recency DESC) AS rfm_recency,
    NTILE(4) OVER (ORDER BY Frequency) AS rfm_frequency,
    NTILE(4) OVER (ORDER BY MonetaryValue) AS rfm_monetary
FROM rfm AS r;

--Results will now be passed through another CTE for the key statement 
;with rfm AS 
(
SELECT 
    CUSTOMERNAME,
    sum(sales) AS MonetaryValue,
	avg(sales) AS AvgMonetaryValue,
	count(ORDERNUMBER) AS Frequency,		
    max(ORDERDATE) AS last_order_date,
    (SELECT MAX(ORDERDATE) FROM sales_data_sample) AS max_order_date,
    DATEDIFF(day, max(ORDERDATE), (SELECT MAX(ORDERDATE) FROM sales_data_sample)) AS Recency
FROM sales_data_sample
GROUP BY CUSTOMERNAME
),
rfm_calc AS 
(
    SELECT r.*,
        NTILE(4) OVER (ORDER BY Recency DESC) AS rfm_recency,
        NTILE(4) OVER (ORDER BY Frequency) AS rfm_frequency,
        NTILE(4) OVER (ORDER BY MonetaryValue) AS rfm_monetary
FROM rfm AS r
)
SELECT c.*
FROM rfm_calc AS C;

--Concatination 
;with rfm AS 
(
SELECT 
    CUSTOMERNAME,
    sum(sales) AS MonetaryValue,
	avg(sales) AS AvgMonetaryValue,
	count(ORDERNUMBER) AS Frequency,		
    max(ORDERDATE) AS last_order_date,
    (SELECT MAX(ORDERDATE) FROM sales_data_sample) AS max_order_date,
    DATEDIFF(day, max(ORDERDATE), (SELECT MAX(ORDERDATE) FROM sales_data_sample)) AS Recency
FROM sales_data_sample
GROUP BY CUSTOMERNAME
),
rfm_calc AS 
(
    SELECT r.*,
        NTILE(4) OVER (ORDER BY Recency DESC) AS rfm_recency,
        NTILE(4) OVER (ORDER BY Frequency) AS rfm_frequency,
        NTILE(4) OVER (ORDER BY MonetaryValue) AS rfm_monetary
FROM rfm AS r
)
SELECT c.*, rfm_recency+rfm_frequency+rfm_monetary AS rfm_cell
FROM rfm_calc AS C;

--Concatination with rfm's as a string
;with rfm AS 
(
SELECT 
    CUSTOMERNAME,
    sum(sales) AS MonetaryValue,
	avg(sales) AS AvgMonetaryValue,
	count(ORDERNUMBER) AS Frequency,		
    max(ORDERDATE) AS last_order_date,
    (SELECT MAX(ORDERDATE) FROM sales_data_sample) AS max_order_date,
    DATEDIFF(day, max(ORDERDATE), (SELECT MAX(ORDERDATE) FROM sales_data_sample)) AS Recency
FROM sales_data_sample
GROUP BY CUSTOMERNAME
),
rfm_calc AS 
(
    SELECT r.*,
        NTILE(4) OVER (ORDER BY Recency DESC) AS rfm_recency,
        NTILE(4) OVER (ORDER BY Frequency) AS rfm_frequency,
        NTILE(4) OVER (ORDER BY MonetaryValue) AS rfm_monetary
FROM rfm AS r
)
SELECT 
    c.*, rfm_recency + rfm_frequency + rfm_monetary AS rfm_cell,
    cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary  as varchar) AS rfm_cell_string
FROM rfm_calc AS C;

--To prevent running all scripts at once we can put result set in a temp table, so the CTE does not have to be run the whole time
DROP TABLE IF EXISTS #rfm 
;with rfm AS 
(
SELECT 
    CUSTOMERNAME,
    sum(sales) AS MonetaryValue,
	avg(sales) AS AvgMonetaryValue,
	count(ORDERNUMBER) AS Frequency,		
    max(ORDERDATE) AS last_order_date,
    (SELECT MAX(ORDERDATE) FROM sales_data_sample) AS max_order_date,
    DATEDIFF(day, max(ORDERDATE), (SELECT MAX(ORDERDATE) FROM sales_data_sample)) AS Recency
FROM sales_data_sample
GROUP BY CUSTOMERNAME
),
rfm_calc AS 
(
    SELECT r.*,
        NTILE(4) OVER (ORDER BY Recency DESC) AS rfm_recency,
        NTILE(4) OVER (ORDER BY Frequency) AS rfm_frequency,
        NTILE(4) OVER (ORDER BY MonetaryValue) AS rfm_monetary
FROM rfm AS r
)
SELECT 
    c.*, rfm_recency + rfm_frequency + rfm_monetary AS rfm_cell,
    cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary  as varchar) AS rfm_cell_string
INTO #rfm
FROM rfm_calc AS C;

SELECT * FROM #rfm;

--Now segmentations can be performed and a case statement will be used to do that 
--Can use rfm_cell values in the case statement but then use > 9 for high value customer, etc
SELECT CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell_string in (311, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

from #rfm;
--This RFM: whenever the customer made a recent purchase give the recency value a higher number, 4 being the highest because this was bucketed into 4


--What products are most often sold together?
--XML path for the conversion of rows to columns 
--Base query:
SELECT ORDERNUMBER, COUNT(*) AS rn
FROM sales_data_sample
WHERE status = 'shipped'
GROUP BY ORDERNUMBER;

--The order number is not unique in the sense that in one order there can be multiple line items 
SELECT * FROM sales_data_sample WHERE ORDERNUMBER = 10411;
--ORDERNUMBER is not unique but the ORDERLINENUMBER is unique 

--See how many orders have two items sold
SELECT ORDERNUMBER
FROM (
    SELECT ORDERNUMBER, COUNT(*) AS rn
    FROM sales_data_sample
    WHERE status = 'shipped'
    GROUP BY ORDERNUMBER
) AS m
WHERE rn = 2;

--Looking for productcodes for these orders
 SELECT PRODUCTCODE
 FROM sales_data_sample
 WHERE ORDERNUMBER IN 
 (
    SELECT ORDERNUMBER
    FROM (
        SELECT ORDERNUMBER, COUNT(*) AS rn
        FROM sales_data_sample
        WHERE status = 'shipped'
        GROUP BY ORDERNUMBER
    ) AS m
    WHERE rn = 2
 );

--XML path and stuff function 
SELECT stuff(
    (SELECT ',' + PRODUCTCODE
    FROM sales_data_sample
    WHERE ORDERNUMBER IN 
    (
        SELECT ORDERNUMBER
        FROM (
            SELECT ORDERNUMBER, COUNT(*) AS rn
            FROM sales_data_sample
            WHERE status = 'shipped'
            GROUP BY ORDERNUMBER
        ) AS m
        WHERE rn = 2
    )
    for xml path (''))
    , 1, 1, '') 

-- Need to know ordernumber for these productcodes 

SELECT DISTINCT ORDERNUMBER, stuff(
    (SELECT ',' + PRODUCTCODE
    FROM sales_data_sample AS p 
    WHERE ORDERNUMBER IN 
    (
        SELECT ORDERNUMBER
        FROM (
            SELECT ORDERNUMBER, COUNT(*) AS rn
            FROM sales_data_sample
            WHERE status = 'shipped'
            GROUP BY ORDERNUMBER
        ) AS m
        WHERE rn = 2
    )
    AND p.ORDERNUMBER = s.ORDERNUMBER
    for xml path (''))
    , 1, 1, '') AS ProductCodes
FROM sales_data_sample AS s
ORDER BY PRODUCTCODE DESC;   

