--1 DATA EXPLORATION
SELECT * FROM customers 
LIMIT 10;

SELECT * FROM transactions 
LIMIT 10;

SELECT COUNT (*) AS total_customers
FROM customers ;

SELECT COUNT (*) AS total_transactions
FROM transactions ;

--Regions
SELECT DISTINCT region
FROM customers
ORDER BY region;

--Account types
SELECT DISTINCT account_type
FROM customers
ORDER BY account_type;

--Payment methods
SELECT DISTINCT transaction_type
FROM transactions
ORDER BY transaction_type ;

--Payment methods
SELECT DISTINCT payment_method
FROM transactions
ORDER BY payment_method ;

--Transaction statuses
SELECT DISTINCT transaction_status
FROM transactions
ORDER BY transaction_status;

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.region,
    t.transaction_id,
    t.transaction_type,
    t.transaction_amount
FROM customers AS c
INNER JOIN transactions AS t
    ON c.customer_id = t.customer_id
LIMIT 20;

--2 DATA QUALITY AUDIT
--Check null values in customers
SELECT
    COUNT(*) AS total_rows,
    COUNT(customer_id) AS customer_id_present,
    COUNT(first_name) AS first_name_present,
    COUNT(last_name) AS last_name_present,
    COUNT(gender) AS gender_present,
    COUNT(date_of_birth) AS dob_present,
    COUNT(city) AS city_present,
    COUNT(region) AS region_present,
    COUNT(occupation) AS occupation_present,
    COUNT(account_type) AS account_type_present,
    COUNT(signup_date) AS signup_date_present,
    COUNT(income_band) AS income_band_present,
    COUNT(account_status) AS account_status_present
FROM customers;

--check null in transactions
SELECT COUNT (*) AS total_rows,
	COUNT(transaction_id) AS transaction_id_present,
	COUNT(customer_id) AS customer_id_present,
	COUNT(transaction_date) AS transaction_date_present,
	COUNT(transaction_type) AS transaction_type_present,
	COUNT(payment_method) AS payment_method_present,
	COUNT(channel) AS channel_present,
	COUNT(transaction_amount) AS amount_present,
	COUNT(fee_amount) AS fee_present,
	COUNT(transaction_status) AS status_present
FROM transactions;

--Check duplicate customers
SELECT customer_id,
	COUNT(*) AS customer_count
FROM customers
	GROUP BY customer_id
	HAVING COUNT(*) > 1 ;

--Check duplicate transactions
SELECT transaction_id,
	COUNT (*) AS transaction_count
FROM transactions
	GROUP BY transaction_id
	HAVING COUNT(*) > 1 ;

--Checking whether every transaction belongs to a customer
SELECT
    t.transaction_id,
    t.customer_id
FROM transactions AS t
LEFT JOIN customers AS c
    ON t.customer_id = c.customer_id
WHERE c.customer_id IS NULL 
LIMIT 20;

--Check transaction amounts
SELECT  MIN(transaction_amount) AS minimum_amount,
		MAX(transaction_amount) AS maximum_amount,
		AVG(transaction_amount) AS average_amount	  
FROM transactions
	WHERE transaction_status = 'Completed' ;

--Checking if there is any 0 or negative transaction	
SELECT COUNT(*) AS invalid_amounts
FROM transactions
WHERE transaction_amount <= 0;

--Check transaction status distribution
SELECT transaction_status,
	COUNT (*) AS transaction_count
FROM transactions
	GROUP BY transaction_status
	ORDER BY transaction_count DESC ;

SELECT * FROM transactions
limit 5 ;

--Calculate completion rate
SELECT
    COUNT(*) AS total_transactions,

    COUNT(
        CASE
            WHEN transaction_status = 'Completed'
            THEN 1
        END
    ) AS completed_transactions,

    ROUND(
        COUNT(
            CASE
                WHEN transaction_status = 'Completed'
                THEN 1
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS completion_rate
FROM transactions;

--Check transaction amount by status
SELECT
    transaction_status,
    COUNT(*) AS transaction_count,
    ROUND(SUM(transaction_amount)::numeric, 2) AS total_amount,
    ROUND(AVG(transaction_amount)::numeric, 2) AS average_amount
FROM transactions
GROUP BY transaction_status
ORDER BY total_amount DESC;

--Check customer account status
SELECT
    account_status,
    COUNT(*) AS customer_count
FROM customers
GROUP BY account_status
ORDER BY customer_count DESC;
--calucalting percentages
SELECT
    account_status,
    COUNT(*) AS customer_count,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM customers),
        2
    ) AS percentage_of_customers
FROM customers
GROUP BY account_status
ORDER BY customer_count DESC;

--Check customers who have never transacted
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.region,
    c.account_type
FROM customers AS c
LEFT JOIN transactions AS t
    ON c.customer_id = t.customer_id
WHERE t.customer_id IS NULL;
--counting customers who never transacted
SELECT
    COUNT(*) AS customers_without_transactions
FROM customers AS c
LEFT JOIN transactions AS t
    ON c.customer_id = t.customer_id
WHERE t.customer_id IS NULL;