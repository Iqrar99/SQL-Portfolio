-- queries by Iqrar Agalosi Nureyza

/*
    List total unique customers that had transactions in JABODETABEK
    between 4 August 2020 and 17 August 2020.
*/
SELECT COUNT(ovo_id)
FROM public.ovo_transaction AS ovo_t
INNER JOIN public.ovo_ref_merchant AS ovo_r
ON ovo_t.merchant_id = ovo_r.merchant_id AND ovo_t.store_code = ovo_r.store_code
-- Use pattern matching for Jakarta, and array for the others to easier the conditional search
WHERE (city LIKE 'Jakarta%' OR city = ANY(ARRAY['Bogor', 'Depok', 'Tangerang', 'Bekasi']))
AND (txndate >= '2020-08-04' AND txndate <= '2020-08-17');


/*
    List only the Top 10 cities who had the highest transaction amount, per month.
*/
SELECT * FROM (
	SELECT city,
		SUM(amount) AS total_amount,
		EXTRACT(month FROM txndate::date) AS month_txn,
		-- Use rank() function to give rank for each row so it can be easier to filter
		rank() OVER (PARTITION BY EXTRACT(month FROM txndate::date) ORDER BY SUM(amount) DESC)
	FROM public.ovo_transaction AS ovo_t
	INNER JOIN public.ovo_ref_merchant AS ovo_r
	ON ovo_t.store_code = ovo_r.store_code AND ovo_t.merchant_id = ovo_r.merchant_id
	GROUP BY city, EXTRACT(month FROM txndate::date)
	ORDER BY month_txn ASC, total_amount DESC
-- With this, we can pick all top 10 for each month
) top10_per_month WHERE rank <= 10;


/*
    List total unique customers, total number of transactions, total amount paid,
    and total cashback per merchant, sort it by total number of transactions from biggest
    to smallest, then remove merchants who have cash back ratio
    (total cashback / total amount) below 5%.
*/
SELECT merchant_id,
	-- Simply use aggregate functions
	COUNT(DISTINCT ovo_id) AS total_unique_customer,
	COUNT(txn_id) AS total_transaction,
	SUM(amount) AS total_amount, 
	SUM(cashback) AS total_cashback,
	(SUM(cashback)/SUM(amount)) AS cashback_ratio
FROM public.ovo_transaction
GROUP BY merchant_id
HAVING (SUM(cashback)/SUM(amount)) >= 0.05
ORDER BY total_transaction DESC;


/*
    Show the distribution of customers based on the number of unique merchants
    s/he had transacted with. (Distribution of customer that have done transaction
    in 1 unique  merchant, 2 unique merchants, 3 unique merchants, etc)
*/
-- Count how many customer that used certain merchants
SELECT total_merchant AS total_unique_merchant_transacted_with, COUNT(ovo_id) AS total_customer
FROM (
	-- Count how many unique merchant per customer
	SELECT ovo_id, COUNT(merchant_id) AS total_merchant
	FROM (
		-- Make sure we do not have duplicate record
		SELECT DISTINCT ovo_id, merchant_id
		FROM public.ovo_transaction
	) AS unique_record
	GROUP BY ovo_id
	ORDER BY total_merchant
) AS task4_table
GROUP BY total_unique_merchant_transacted_with;


/*
    List customers who have transactions in the exact following order of merchants:
    TOKO BAJU, KOPI NONGKRONG, then KAKI LIMA.
    (If customer have transactions in the same merchant multiple times in sequential
    order then it counts as one appearance, for example: TOKO BAJU, KOPI NONGKRONG,
    KOPI NONGKRONG, KAKI LIMA, KOPI NONGKRONG will be TOKO_BAJU, KOPI NONGKRONG, KAKI LIMA,
    KOPI NONGKRONG. hints: you can use transaction id to sort transactions)
*/
-- First we need to eliminate all customer that have transacted with less than 3 merchants
WITH more2merchant AS (
	SELECT ovo_id
	FROM (
		SELECT DISTINCT ovo_id, merchant_id
		FROM public.ovo_transaction
	) AS unique_record
	GROUP BY ovo_id
	HAVING COUNT(merchant_id) >= 3
-- Then we sort the previous table and group them by customer ID and transaction date
), grouped_more2merchant AS (
	SELECT txndate, merchant_name, ovo_id
	FROM public.ovo_transaction
	WHERE ovo_id IN (SELECT * FROM more2merchant)
	ORDER BY ovo_id, txndate
-- We will ignore the consecutive duplicates. This can makes the searching easier.
), removed_consecutive_duplicate AS (
	SELECT * FROM (
		SELECT *, lag(merchant_name) OVER (ORDER BY ovo_id, txndate) AS prev_merchant
		FROM grouped_more2merchant
	) new_table
	-- Ignore the duplicate by checking the previous row
	WHERE prev_merchant IS DISTINCT FROM merchant_name
)
-- In the end, we save the next 2 row on new columns to check the order
SELECT *
FROM (
	SELECT
		ovo_id,
		merchant_name,
		lead(merchant_name) OVER (ORDER BY ovo_id, txndate) AS next_merchant,
		lead(merchant_name, 2) OVER (ORDER BY ovo_id, txndate) AS next2_merchant
	FROM removed_consecutive_duplicate
) next_table
-- Check the order if it matches
WHERE merchant_name = 'TOKO BAJU'
AND next_merchant = 'KOPI NONGKRONG'
AND next2_merchant = 'KAKI LIMA';