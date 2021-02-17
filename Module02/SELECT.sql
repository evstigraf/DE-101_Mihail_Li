SELECT SUM(sales) AS total_sales
FROM dw.sales_fact
WHERE returned IS FALSE

SELECT SUM(profit)  AS total_profit
FROM dw.sales_fact
WHERE returned IS false

SELECT round(SUM(profit)/SUM(sales)*100, 2) AS profit_ratio
FROM dw.sales_fact
WHERE returned IS FALSE

SELECT round(SUM(sales)/COUNT(order_id), 2) AS avg_sales
FROM dw.sales_fact
WHERE returned IS FALSE

SELECT round(SUM(profit)/COUNT(order_id), 2) AS avg_profit
FROM dw.sales_fact
WHERE returned IS FALSE

SELECT year, month, SUM(sales) AS sales, SUM(profit) AS profit, AVG(discount)*100 AS discount
FROM dw.sales_fact LEFT JOIN dw.calendar_dim ON dw.sales_fact.ship_date_id = dw.calendar_dim.date_id
WHERE returned IS FALSE
GROUP BY year, month
ORDER BY year, month

SELECT state, SUM(sales) AS sales, SUM(profit) AS profit, AVG(discount)*100 AS discount
FROM dw.sales_fact LEFT JOIN dw.geography ON dw.sales_fact.geo_id = dw.geography.geo_id
WHERE returned IS FALSE
GROUP BY state
ORDER BY sales DESC