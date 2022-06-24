-- queries by Iqrar Agalosi Nureyza

/*
	Check the top 10 customer with the most order
*/
SELECT customer_name, COUNT(*) AS total_order
FROM supermart
GROUP BY customer_name
ORDER BY total_order DESC
LIMIT 10;


/*
	See the total sales for each category on west region during 2017,
	order it from the highest sales
*/
SELECT category, SUM(sales) as total_sales
FROM supermart
WHERE EXTRACT('year' from order_date) = 2017
AND region  = 'West'
GROUP BY category
ORDER BY total_sales DESC;


/*
	What is the average sales for beverages during 4th quarter of 2018?
*/
SELECT AVG(sales) AS beverages_sales_average
FROM supermart
WHERE EXTRACT('year' from order_date) = 2018
AND EXTRACT('month' from order_date) >= 10
AND category = 'Beverages';


/*
	Check the average and total profits of snacks for each month during 2016
*/
SELECT EXTRACT('year' from order_date) as order_year,
	EXTRACT('month' from order_date) as order_month,
	AVG(profit) AS profit_avg,
	SUM(profit) AS total_profit
FROM supermart
WHERE EXTRACT('year' from order_date) = 2016
GROUP BY order_year, order_month;


/*
	Check what cities that never order Masalas on May 2017
*/
SELECT city 
FROM supermart
WHERE city NOT IN (	
	SELECT DISTINCT city
	FROM supermart
	WHERE sub_category = 'Masalas'
	AND EXTRACT('year' from order_date) = 2017
	AND EXTRACT('month' from order_date) = 5
);


/*
	What is the percentage of ordering amount of Noodles
	compared to all Snacks category during 2017?
*/
CREATE OR REPLACE FUNCTION calculate_percentage_subcategory(c text, sub_c text, order_year INT)
RETURNS FLOAT
AS
$$
	DECLARE
		total_category FLOAT;
		total_sub_category FLOAT;
		percentage FLOAT;
	BEGIN
		SELECT COUNT(*) INTO total_category
		FROM supermart
		WHERE category = c
		AND EXTRACT('year' from order_date) = order_year;
		
		SELECT COUNT(*) INTO total_sub_category
		FROM supermart
		WHERE sub_category = sub_c
		AND EXTRACT('year' from order_date) = order_year;
		
		percentage := (total_sub_category/total_category)*100;
		RETURN percentage;
	END;
$$
LANGUAGE plpgsql;

SELECT calculate_percentage_subcategory('Snacks', 'Noodles', 2017)
AS "Noodles order percentage 2017 (%)";


/*
	When is the highest discount of Bakery category happened in 2015?
*/
SELECT order_date, discount
FROM supermart
WHERE discount IN (
	SELECT MAX(discount)
	FROM supermart
	WHERE EXTRACT('year' from order_date) = 2015
	AND category = 'Bakery'
) AND EXTRACT('year' from order_date) = 2015
AND category = 'Bakery'
ORDER BY order_date;


/*
	How many unique people that have more than two orders in a same day during 2018?
*/
SELECT COUNT(DISTINCT customer_name) AS total_unique_customer
FROM (
	SELECT customer_name, order_date, COUNT(*) AS total_order_per_day
	FROM supermart
	WHERE EXTRACT('year' from order_date) = 2018
	GROUP BY order_date, customer_name
	HAVING COUNT(*) > 2
) AS order_more_than_2;
