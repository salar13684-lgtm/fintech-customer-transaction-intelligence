--4 Transaction & Payment Analytics
--Overall transaction KPIs
SELECT
    COUNT(*) AS total_transactions,
    ROUND(SUM(transaction_amount)::numeric, 2) AS total_transaction_value,
    ROUND(AVG(transaction_amount)::numeric, 2) AS average_transaction_value,
    ROUND(MIN(transaction_amount)::numeric, 2) AS minimum_transaction_value,
    ROUND(MAX(transaction_amount)::numeric, 2) AS maximum_transaction_value
FROM transactions
WHERE transaction_status = 'Completed';

--Transaction performance by transaction type
SELECT
    transaction_type,
    COUNT(*) AS transaction_count,
    ROUND(SUM(transaction_amount)::numeric, 2) AS total_transaction_value,
    ROUND(AVG(transaction_amount)::numeric, 2) AS average_transaction_value
FROM transactions
WHERE transaction_status = 'Completed'
GROUP BY transaction_type
ORDER BY transaction_count DESC;

--Which transaction type generates the most platform revenue?
SELECT
    transaction_type,
    COUNT(*) AS transaction_count,
    ROUND(SUM(transaction_amount)::numeric, 2) AS transaction_value,
    ROUND(SUM(fee_amount)::numeric, 2) AS platform_revenue
FROM transactions
WHERE transaction_status = 'Completed'
GROUP BY transaction_type
ORDER BY platform_revenue DESC;

--Payment method popularity
SELECT
    payment_method,
    COUNT(*) AS transaction_count
FROM transactions
WHERE transaction_status = 'Completed'
GROUP BY payment_method
ORDER BY transaction_count DESC;

--Payment method transaction value
SELECT
    payment_method,
    COUNT(*) AS transaction_count,
    ROUND(SUM(transaction_amount)::numeric, 2) AS transaction_value,
    ROUND(AVG(transaction_amount)::numeric, 2) AS average_transaction_value
FROM transactions
WHERE transaction_status = 'Completed'
GROUP BY payment_method
ORDER BY transaction_value DESC;

--Payment method revenue
SELECT
    payment_method,
    COUNT(*) AS transaction_count,
    ROUND(SUM(fee_amount)::numeric, 2) AS platform_revenue
FROM transactions
WHERE transaction_status = 'Completed'
GROUP BY payment_method
ORDER BY platform_revenue DESC;

--Which channels drive the most financial activity?
SELECT
    channel,
    COUNT(*) AS transaction_count,
    ROUND(SUM(transaction_amount)::numeric, 2) AS transaction_value,
    ROUND(AVG(transaction_amount)::numeric, 2) AS average_transaction_value,
    ROUND(SUM(fee_amount)::numeric, 2) AS platform_revenue
FROM transactions
WHERE transaction_status = 'Completed'
GROUP BY channel
ORDER BY transaction_value DESC;

--TRANSACTION status analysis
SELECT
    transaction_status,
    COUNT(*) AS transaction_count,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM transactions),
        2
    ) AS percentage_of_transactions
FROM transactions
GROUP BY transaction_status
ORDER BY transaction_count DESC;

--Failed transaction analysis
SELECT
    transaction_type,
    COUNT(*) AS failed_transactions,
    ROUND(SUM(transaction_amount)::numeric, 2) AS failed_transaction_value
FROM transactions
WHERE transaction_status = 'Failed'
GROUP BY transaction_type
ORDER BY failed_transactions DESC

--Failure rate by transaction type
SELECT
    transaction_type,
    COUNT(*) AS total_transactions,

    COUNT(
        CASE
            WHEN transaction_status = 'Failed'
            THEN 1
        END
    ) AS failed_transactions,

    ROUND(
        COUNT(
            CASE
                WHEN transaction_status = 'Failed'
                THEN 1
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS failure_rate
FROM transactions
GROUP BY transaction_type
ORDER BY failure_rate DESC;

--Transaction performance by region
SELECT
    c.region,
    COUNT(t.transaction_id) AS transaction_count,
    ROUND(SUM(t.transaction_amount)::numeric, 2) AS transaction_value,
    ROUND(AVG(t.transaction_amount)::numeric, 2) AS average_transaction_value,
    ROUND(SUM(t.fee_amount)::numeric, 2) AS platform_revenue
FROM customers AS c
INNER JOIN transactions AS t
    ON c.customer_id = t.customer_id
WHERE t.transaction_status = 'Completed'
GROUP BY c.region
ORDER BY transaction_value DESC;

--Payment mwthod by region
SELECT
    c.region,
    t.payment_method,
    COUNT(*) AS transaction_count,
    ROUND(SUM(t.transaction_amount)::numeric, 2) AS transaction_value
FROM customers AS c
INNER JOIN transactions AS t
    ON c.customer_id = t.customer_id
WHERE t.transaction_status = 'Completed'
GROUP BY
    c.region,
    t.payment_method
ORDER BY
    c.region,
    transaction_value DESC;

--Account type transaction behaviour
SELECT
    c.account_type,
    COUNT(t.transaction_id) AS transaction_count,
    ROUND(SUM(t.transaction_amount)::numeric, 2) AS transaction_value,
    ROUND(AVG(t.transaction_amount)::numeric, 2) AS average_transaction_value,
    ROUND(SUM(t.fee_amount)::numeric, 2) AS platform_revenue
FROM customers AS c
INNER JOIN transactions AS t
    ON c.customer_id = t.customer_id
WHERE t.transaction_status = 'Completed'
GROUP BY c.account_type
ORDER BY transaction_value DESC;

--Rank transaction type by transaction value 
WITH transaction_type_summary AS (
    SELECT
        transaction_type,
        COUNT(*) AS transaction_count,
        SUM(transaction_amount) AS transaction_value
    FROM transactions
    WHERE transaction_status = 'Completed'
    GROUP BY transaction_type
)

SELECT
    transaction_type,
    transaction_count,
    ROUND(transaction_value::numeric, 2) AS transaction_value,

    RANK() OVER (
        ORDER BY transaction_value DESC
    ) AS transaction_value_rank

FROM transaction_type_summary
ORDER BY transaction_value_rank;

--Transaction type ranked by revenue
WITH transaction_type_summary AS (
    SELECT
        transaction_type,
        COUNT(*) AS transaction_count,
        SUM(fee_amount) AS platform_revenue
    FROM transactions
    WHERE transaction_status = 'Completed'
    GROUP BY transaction_type
)

SELECT
    transaction_type,
    transaction_count,
    ROUND(platform_revenue::numeric, 2) AS platform_revenue,

    RANK() OVER (
        ORDER BY platform_revenue DESC
    ) AS revenue_rank

FROM transaction_type_summary
ORDER BY revenue_rank;

--Payment method contribituion percentage 
SELECT
    payment_method,

    ROUND(
        SUM(transaction_amount)::numeric,
        2
    ) AS transaction_value,

    ROUND(
        (
            SUM(transaction_amount) * 100.0 /
            SUM(SUM(transaction_amount)) OVER ()
        )::numeric,
        2
    ) AS value_percentage

FROM transactions
WHERE transaction_status = 'Completed'
GROUP BY payment_method
ORDER BY transaction_value DESC;

--Average transaction value by payment method
SELECT
    payment_method,
    COUNT(*) AS transaction_count,
    ROUND(AVG(transaction_amount)::numeric, 2) AS average_transaction_value,
    ROUND(MIN(transaction_amount)::numeric, 2) AS minimum_transaction_value,
    ROUND(MAX(transaction_amount)::numeric, 2) AS maximum_transaction_value
FROM transactions
WHERE transaction_status = 'Completed'
GROUP BY payment_method
ORDER BY average_transaction_value DESC;