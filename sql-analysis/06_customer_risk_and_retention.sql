SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.region,
    MAX(t.transaction_date) AS last_transaction_date
FROM customers AS c
LEFT JOIN transactions AS t
    ON c.customer_id = t.customer_id
    AND t.transaction_status = 'Completed'
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name,
    c.region
ORDER BY last_transaction_date;

--Customers who never completed a transaction
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.region,
    c.account_type,
    c.account_status
FROM customers AS c
LEFT JOIN transactions AS t
    ON c.customer_id = t.customer_id
    AND t.transaction_status = 'Completed'
WHERE t.transaction_id IS NULL
ORDER BY c.customer_id;

--Customer who never transacted
SELECT
    COUNT(*) AS customers_without_completed_transactions
FROM customers AS c
LEFT JOIN transactions AS t
    ON c.customer_id = t.customer_id
    AND t.transaction_status = 'Completed'
WHERE t.transaction_id IS NULL;

--Customer transaction frequency
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.region,

    COUNT(t.transaction_id) AS completed_transactions

FROM customers AS c

INNER JOIN transactions AS t
    ON c.customer_id = t.customer_id

WHERE t.transaction_status = 'Completed'

GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name,
    c.region

ORDER BY completed_transactions DESC
LIMIT 20;

--customer activity segmentation
WITH customer_activity AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        c.region,

        COUNT(t.transaction_id) AS transaction_count

    FROM customers AS c

    LEFT JOIN transactions AS t
        ON c.customer_id = t.customer_id
        AND t.transaction_status = 'Completed'

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
    transaction_count,

    CASE
        WHEN transaction_count >= 100 THEN 'Very Active'
        WHEN transaction_count >= 50 THEN 'Active'
        WHEN transaction_count >= 10 THEN 'Moderately Active'
        WHEN transaction_count >= 1 THEN 'Low Activity'
        ELSE 'Inactive'
    END AS activity_segment

FROM customer_activity

ORDER BY transaction_count DESC;

--Number of customers in each activity segment
WITH customer_activity AS (
    SELECT
        c.customer_id,
        COUNT(t.transaction_id) AS transaction_count

    FROM customers AS c

    LEFT JOIN transactions AS t
        ON c.customer_id = t.customer_id
        AND t.transaction_status = 'Completed'

    GROUP BY c.customer_id
),

activity_segments AS (
    SELECT
        customer_id,
        transaction_count,

        CASE
            WHEN transaction_count >= 100 THEN 'Very Active'
            WHEN transaction_count >= 50 THEN 'Active'
            WHEN transaction_count >= 10 THEN 'Moderately Active'
            WHEN transaction_count >= 1 THEN 'Low Activity'
            ELSE 'Inactive'
        END AS activity_segment

    FROM customer_activity
)

SELECT
    activity_segment,
    COUNT(*) AS customer_count
FROM activity_segments
GROUP BY activity_segment
ORDER BY customer_count DESC;

--last transaction and customer activity 
WITH customer_activity AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        c.region,

        COUNT(t.transaction_id) AS transaction_count,
        MAX(t.transaction_date) AS last_transaction_date

    FROM customers AS c

    LEFT JOIN transactions AS t
        ON c.customer_id = t.customer_id
        AND t.transaction_status = 'Completed'

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
    transaction_count,
    last_transaction_date,

    CASE
        WHEN last_transaction_date IS NULL THEN 'Never Active'
        WHEN last_transaction_date >= DATE '2026-08-01' THEN 'Recently Active'
        WHEN last_transaction_date >= DATE '2026-07-01' THEN 'Active'
        WHEN last_transaction_date >= DATE '2026-05-01' THEN 'At Risk'
        ELSE 'Inactive'
    END AS activity_status

FROM customer_activity

ORDER BY last_transaction_date DESC;

--Days since last transaction
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.region,

    MAX(t.transaction_date) AS last_transaction_date,

    CURRENT_DATE - MAX(t.transaction_date) AS days_since_last_transaction

FROM customers AS c

INNER JOIN transactions AS t
    ON c.customer_id = t.customer_id

WHERE t.transaction_status = 'Completed'

GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name,
    c.region

ORDER BY days_since_last_transaction DESC;

--Inactive customers
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.region,
    MAX(t.transaction_date) AS last_transaction_date

FROM customers AS c

INNER JOIN transactions AS t
    ON c.customer_id = t.customer_id

WHERE t.transaction_status = 'Completed'

GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name,
    c.region

HAVING CURRENT_DATE - MAX(t.transaction_date) >= 90

ORDER BY last_transaction_date;SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.region,
    MAX(t.transaction_date) AS last_transaction_date

FROM customers AS c

INNER JOIN transactions AS t
    ON c.customer_id = t.customer_id

WHERE t.transaction_status = 'Completed'

GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name,
    c.region

HAVING CURRENT_DATE - MAX(t.transaction_date) >= 90

ORDER BY last_transaction_date;

--Total inactive customer by region
WITH customer_last_activity AS (
    SELECT
        c.customer_id,
        c.region,
        MAX(t.transaction_date) AS last_transaction_date

    FROM customers AS c

    INNER JOIN transactions AS t
        ON c.customer_id = t.customer_id

    WHERE t.transaction_status = 'Completed'

    GROUP BY
        c.customer_id,
        c.region
)

SELECT
    region,
    COUNT(*) AS inactive_customers

FROM customer_last_activity

WHERE CURRENT_DATE - last_transaction_date >= 90

GROUP BY region

ORDER BY inactive_customers DESC;

--High-value customers but they are inactive mostly
WITH customer_metrics AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        c.region,

        SUM(t.transaction_amount) AS total_spending,
        COUNT(t.transaction_id) AS transaction_count,
        MAX(t.transaction_date) AS last_transaction_date

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

    transaction_count,

    last_transaction_date,

    CURRENT_DATE - last_transaction_date AS days_since_last_transaction

FROM customer_metrics

WHERE total_spending >= 200000
  AND CURRENT_DATE - last_transaction_date >= 90

ORDER BY total_spending DESC;

--High-value inactive customers by region
WITH customer_metrics AS (
    SELECT
        c.customer_id,
        c.region,

        SUM(t.transaction_amount) AS total_spending,
        MAX(t.transaction_date) AS last_transaction_date

    FROM customers AS c

    INNER JOIN transactions AS t
        ON c.customer_id = t.customer_id

    WHERE t.transaction_status = 'Completed'

    GROUP BY
        c.customer_id,
        c.region
),

high_value_inactive AS (
    SELECT
        customer_id,
        region,
        total_spending

    FROM customer_metrics

    WHERE total_spending >= 200000
      AND CURRENT_DATE - last_transaction_date >= 90
)

SELECT
    region,
    COUNT(*) AS high_value_inactive_customers,
    ROUND(SUM(total_spending)::numeric, 2) AS potentially_at_risk_transaction_value

FROM high_value_inactive

GROUP BY region

ORDER BY potentially_at_risk_transaction_value DESC;

--customer activity by account status
SELECT
    c.account_status,

    COUNT(DISTINCT c.customer_id) AS customers,

    COUNT(t.transaction_id) AS completed_transactions,

    ROUND(
        SUM(t.transaction_amount)::numeric,
        2
    ) AS transaction_value

FROM customers AS c

LEFT JOIN transactions AS t
    ON c.customer_id = t.customer_id
    AND t.transaction_status = 'Completed'

GROUP BY c.account_status

ORDER BY customers DESC;

--active vs inactive customer spending
WITH customer_metrics AS (
    SELECT
        c.customer_id,
        c.region,

        SUM(t.transaction_amount) AS total_spending,
        MAX(t.transaction_date) AS last_transaction_date

    FROM customers AS c

    INNER JOIN transactions AS t
        ON c.customer_id = t.customer_id

    WHERE t.transaction_status = 'Completed'

    GROUP BY
        c.customer_id,
        c.region
),

customer_status AS (
    SELECT
        customer_id,
        region,
        total_spending,
        last_transaction_date,

        CASE
            WHEN CURRENT_DATE - last_transaction_date >= 90
                THEN 'Inactive'
            ELSE 'Active'
        END AS activity_status

    FROM customer_metrics
)

SELECT
    activity_status,
    COUNT(*) AS customers,
    ROUND(SUM(total_spending)::numeric, 2) AS total_spending,
    ROUND(AVG(total_spending)::numeric, 2) AS average_customer_spending

FROM customer_status

GROUP BY activity_status

ORDER BY total_spending DESC;

--most active customer by region
WITH customer_activity AS (
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
),

ranked_customers AS (
    SELECT
        customer_id,
        first_name,
        last_name,
        region,
        transaction_count,

        ROW_NUMBER() OVER (
            PARTITION BY region
            ORDER BY transaction_count DESC
        ) AS activity_rank

    FROM customer_activity
)

SELECT
    customer_id,
    first_name,
    last_name,
    region,
    transaction_count

FROM ranked_customers

WHERE activity_rank = 1

ORDER BY region;

--customer activity trend over time
SELECT
    DATE_TRUNC('month', transaction_date)::date AS transaction_month,

    COUNT(DISTINCT customer_id) AS active_customers,

    COUNT(transaction_id) AS transactions,

    ROUND(
        SUM(transaction_amount)::numeric,
        2
    ) AS transaction_value

FROM transactions

WHERE transaction_status = 'Completed'

GROUP BY DATE_TRUNC('month', transaction_date)

ORDER BY transaction_month;

--monthly customer active growth
WITH monthly_activity AS (
    SELECT
        DATE_TRUNC('month', transaction_date)::date AS transaction_month,

        COUNT(DISTINCT customer_id) AS active_customers

    FROM transactions

    WHERE transaction_status = 'Completed'

    GROUP BY DATE_TRUNC('month', transaction_date)
),

activity_growth AS (
    SELECT
        transaction_month,
        active_customers,

        LAG(active_customers) OVER (
            ORDER BY transaction_month
        ) AS previous_month_active_customers

    FROM monthly_activity
)

SELECT
    transaction_month,
    active_customers,
    previous_month_active_customers,

    ROUND(
        (
            (active_customers - previous_month_active_customers)
            * 100.0
            / NULLIF(previous_month_active_customers, 0)
        )::numeric,
        2
    ) AS active_customer_growth_percentage

FROM activity_growth

ORDER BY transaction_month;

