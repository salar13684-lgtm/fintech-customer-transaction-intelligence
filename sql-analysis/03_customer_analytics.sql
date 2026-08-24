--3 Customer Analytics
--Customer distribution by region
SELECT
    region,
    COUNT(*) AS customer_count
FROM customers
GROUP BY region
ORDER BY customer_count DESC;
--calculating customer percentage along with customer count
SELECT
    region,
    COUNT(*) AS customer_count,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM customers),
        2
    ) AS customer_percentage
FROM customers
GROUP BY region
ORDER BY customer_count DESC;

--Customer distribution by account type
SELECT
    account_type,
    COUNT(*) AS customer_count
FROM customers
GROUP BY account_type
ORDER BY customer_count DESC;
--CALCULATING customer percentage
SELECT
    account_type,
    COUNT(*) AS customer_count,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM customers),
        2
    ) AS customer_percentage
FROM customers
GROUP BY account_type
ORDER BY customer_count DESC;

SELECT
    income_band,
    COUNT(*) AS customer_count
FROM customers
GROUP BY income_band
ORDER BY customer_count DESC;

--Customer distribution by occupation
SELECT
    occupation,
    COUNT(*) AS customer_count
FROM customers
GROUP BY occupation
ORDER BY customer_count DESC;

--How many transactions does each customer make?
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.region,
    COUNT(t.transaction_id) AS transaction_count
FROM customers AS c
INNER JOIN transactions AS t
    ON c.customer_id = t.customer_id
WHERE t.transaction_status = 'Completed'
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name,
    c.region
ORDER BY transaction_count DESC
LIMIT 10;

--Total spending per customer
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.region,
    ROUND(SUM(t.transaction_amount)::numeric, 2) AS total_spending
FROM customers AS c
INNER JOIN transactions AS t
    ON c.customer_id = t.customer_id
WHERE t.transaction_status = 'Completed'
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name,
    c.region
ORDER BY total_spending DESC
LIMIT 10;

--Average transaction value per customer
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.region,
    COUNT(t.transaction_id) AS transaction_count,
    ROUND(AVG(t.transaction_amount)::numeric, 2) AS average_transaction_value
FROM customers AS c
INNER JOIN transactions AS t
    ON c.customer_id = t.customer_id
WHERE t.transaction_status = 'Completed'
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name,
    c.region
ORDER BY average_transaction_value DESC
LIMIT 10;

--op 10 customers by platform revenue
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.region,
    ROUND(SUM(t.fee_amount)::numeric, 2) AS platform_revenue
FROM customers AS c
INNER JOIN transactions AS t
    ON c.customer_id = t.customer_id
WHERE t.transaction_status = 'Completed'
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name,
    c.region
ORDER BY platform_revenue DESC
LIMIT 10;

--Customer value segmentation
WITH customer_spending AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        c.region,
        SUM(t.transaction_amount) AS total_spending
    FROM customers AS c
    INNER JOIN transactions AS t
        ON c.customer_id = t.customer_id
    WHERE t.transaction_status = 'Completed'
    GROUP BY
        c.customer_id,
        c.first_name,
        c.last_name,
        c.region
)

SELECT
    customer_id,
    first_name,
    last_name,
    region,
    ROUND(total_spending::numeric, 2) AS total_spending,

    CASE
        WHEN total_spending >= 500000 THEN 'VIP'
        WHEN total_spending >= 200000 THEN 'High Value'
        WHEN total_spending >= 50000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment

FROM customer_spending
ORDER BY total_spending DESC;

--How many customers are in each segment?
WITH customer_spending AS (
    SELECT
        c.customer_id,
        SUM(t.transaction_amount) AS total_spending
    FROM customers AS c
    INNER JOIN transactions AS t
        ON c.customer_id = t.customer_id
    WHERE t.transaction_status = 'Completed'
    GROUP BY c.customer_id
),

customer_segments AS (
    SELECT
        customer_id,
        total_spending,
        CASE
            WHEN total_spending >= 500000 THEN 'VIP'
            WHEN total_spending >= 200000 THEN 'High Value'
            WHEN total_spending >= 50000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_segment
    FROM customer_spending
)

SELECT
    customer_segment,
    COUNT(*) AS customer_count,
    ROUND(SUM(total_spending)::numeric, 2) AS total_spending
FROM customer_segments
GROUP BY customer_segment
ORDER BY total_spending DESC;

--Which customer segment generates the most platform revenue?
WITH customer_revenue AS (
    SELECT
        c.customer_id,
        SUM(t.transaction_amount) AS total_spending,
        SUM(t.fee_amount) AS total_revenue
    FROM customers AS c
    INNER JOIN transactions AS t
        ON c.customer_id = t.customer_id
    WHERE t.transaction_status = 'Completed'
    GROUP BY c.customer_id
),

customer_segments AS (
    SELECT
        customer_id,
        total_spending,
        total_revenue,

        CASE
            WHEN total_spending >= 500000 THEN 'VIP'
            WHEN total_spending >= 200000 THEN 'High Value'
            WHEN total_spending >= 50000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_segment

    FROM customer_revenue
)

SELECT
    customer_segment,
    COUNT(*) AS customer_count,
    ROUND(SUM(total_spending)::numeric, 2) AS total_spending,
    ROUND(SUM(total_revenue)::numeric, 2) AS platform_revenue
FROM customer_segments
GROUP BY customer_segment
ORDER BY platform_revenue DESC;
/*Business Insight: Although VIP customers represent a smaller portion of the customer base, 
they contribute disproportionately to platform revenue.*/

--Rank customers by spending
WITH customer_spending AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        c.region,
        SUM(t.transaction_amount) AS total_spending
    FROM customers AS c
    INNER JOIN transactions AS t
        ON c.customer_id = t.customer_id
    WHERE t.transaction_status = 'Completed'
    GROUP BY
        c.customer_id,
        c.first_name,
        c.last_name,
        c.region
)

SELECT
    customer_id,
    first_name,
    last_name,
    region,
    ROUND(total_spending::numeric, 2) AS total_spending,

    RANK() OVER (
        ORDER BY total_spending DESC
    ) AS spending_rank

FROM customer_spending
ORDER BY spending_rank
LIMIT 20;

--Rank customers inside their region
WITH customer_spending AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        c.region,
        SUM(t.transaction_amount) AS total_spending
    FROM customers AS c
    INNER JOIN transactions AS t
        ON c.customer_id = t.customer_id
    WHERE t.transaction_status = 'Completed'
    GROUP BY
        c.customer_id,
        c.first_name,
        c.last_name,
        c.region
)

SELECT
    customer_id,
    first_name,
    last_name,
    region,
    ROUND(total_spending::numeric, 2) AS total_spending,

    RANK() OVER (
        PARTITION BY region
        ORDER BY total_spending DESC
    ) AS regional_rank

FROM customer_spending
ORDER BY region, regional_rank;

--Top 3 customers in every region
WITH customer_spending AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        c.region,
        SUM(t.transaction_amount) AS total_spending
    FROM customers AS c
    INNER JOIN transactions AS t
        ON c.customer_id = t.customer_id
    WHERE t.transaction_status = 'Completed'
    GROUP BY
        c.customer_id,
        c.first_name,
        c.last_name,
        c.region
),

ranked_customers AS (
    SELECT
        customer_id,
        first_name,
        last_name,
        region,
        total_spending,

        RANK() OVER (
            PARTITION BY region
            ORDER BY total_spending DESC
        ) AS regional_rank

    FROM customer_spending
)

SELECT
    customer_id,
    first_name,
    last_name,
    region,
    ROUND(total_spending::numeric, 2) AS total_spending,
    regional_rank
FROM ranked_customers
WHERE regional_rank <= 3
ORDER BY region, regional_rank;