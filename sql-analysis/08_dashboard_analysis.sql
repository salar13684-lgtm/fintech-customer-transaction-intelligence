SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.gender,
    c.city,
    c.region,
    c.occupation,
    c.account_type,
    c.income_band,
    c.account_status,

    COUNT(t.transaction_id) AS transaction_count,

    ROUND(
        COALESCE(SUM(t.transaction_amount), 0)::numeric,
        2
    ) AS total_transaction_value,

    ROUND(
        COALESCE(SUM(t.fee_amount), 0)::numeric,
        2
    ) AS platform_revenue,

    ROUND(
        COALESCE(AVG(t.transaction_amount), 0)::numeric,
        2
    ) AS average_transaction_value,

    MAX(t.transaction_date) AS last_transaction_date,

    CASE
        WHEN COALESCE(SUM(t.transaction_amount), 0) >= 500000
            THEN 'VIP'

        WHEN COALESCE(SUM(t.transaction_amount), 0) >= 200000
            THEN 'High Value'

        WHEN COALESCE(SUM(t.transaction_amount), 0) >= 50000
            THEN 'Medium Value'

        ELSE 'Low Value'
    END AS customer_value_segment,

    CASE
        WHEN COUNT(t.transaction_id) >= 100
            THEN 'Very Active'

        WHEN COUNT(t.transaction_id) >= 50
            THEN 'Active'

        WHEN COUNT(t.transaction_id) >= 10
            THEN 'Moderately Active'

        WHEN COUNT(t.transaction_id) >= 1
            THEN 'Low Activity'

        ELSE 'Inactive'
    END AS activity_segment

FROM customers AS c

LEFT JOIN transactions AS t
    ON c.customer_id = t.customer_id
    AND t.transaction_status = 'Completed'

GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name,
    c.gender,
    c.city,
    c.region,
    c.occupation,
    c.account_type,
    c.income_band,
    c.account_status

ORDER BY total_transaction_value DESC;

--Dataset 2: Monthly Performance
SELECT
    DATE_TRUNC(
        'month',
        transaction_date
    )::date AS transaction_month,

    COUNT(transaction_id) AS transaction_count,

    COUNT(DISTINCT customer_id) AS active_customers,

    ROUND(
        SUM(transaction_amount)::numeric,
        2
    ) AS transaction_value,

    ROUND(
        SUM(fee_amount)::numeric,
        2
    ) AS platform_revenue,

    ROUND(
        AVG(transaction_amount)::numeric,
        2
    ) AS average_transaction_value

FROM transactions

WHERE transaction_status = 'Completed'

GROUP BY
    DATE_TRUNC('month', transaction_date)

ORDER BY transaction_month;

--Dataset 3: Regional Performance
SELECT
    c.region,

    COUNT(DISTINCT c.customer_id) AS customers,

    COUNT(t.transaction_id) AS transactions,

    ROUND(
        SUM(t.transaction_amount)::numeric,
        2
    ) AS transaction_value,

    ROUND(
        SUM(t.fee_amount)::numeric,
        2
    ) AS platform_revenue,

    ROUND(
        AVG(t.transaction_amount)::numeric,
        2
    ) AS average_transaction_value,

    ROUND(
        (
            SUM(t.fee_amount)
            / NULLIF(COUNT(DISTINCT c.customer_id), 0)
        )::numeric,
        2
    ) AS revenue_per_customer

FROM customers AS c

INNER JOIN transactions AS t
    ON c.customer_id = t.customer_id

WHERE t.transaction_status = 'Completed'

GROUP BY c.region

ORDER BY platform_revenue DESC;

--Dataset 4: Transaction Performance
SELECT
    t.transaction_type,
    t.payment_method,
    t.channel,

    COUNT(t.transaction_id) AS transaction_count,

    ROUND(
        SUM(t.transaction_amount)::numeric,
        2
    ) AS transaction_value,

    ROUND(
        SUM(t.fee_amount)::numeric,
        2
    ) AS platform_revenue,

    ROUND(
        AVG(t.transaction_amount)::numeric,
        2
    ) AS average_transaction_value

FROM transactions AS t

WHERE t.transaction_status = 'Completed'

GROUP BY
    t.transaction_type,
    t.payment_method,
    t.channel

ORDER BY transaction_value DESC;

--Dataset 5: Customer Risk
WITH customer_metrics AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        c.region,
        c.account_type,
        c.account_status,

        COUNT(t.transaction_id) AS transaction_count,

        SUM(t.transaction_amount) AS total_transaction_value,

        SUM(t.fee_amount) AS platform_revenue,

        AVG(t.transaction_amount) AS average_transaction_value,

        MAX(t.transaction_date) AS last_transaction_date

    FROM customers AS c

    LEFT JOIN transactions AS t
        ON c.customer_id = t.customer_id
        AND t.transaction_status = 'Completed'

    GROUP BY
        c.customer_id,
        c.first_name,
        c.last_name,
        c.region,
        c.account_type,
        c.account_status
)

SELECT
    customer_id,
    first_name,
    last_name,
    region,
    account_type,
    account_status,

    transaction_count,

    ROUND(
        COALESCE(total_transaction_value, 0)::numeric,
        2
    ) AS total_transaction_value,

    ROUND(
        COALESCE(platform_revenue, 0)::numeric,
        2
    ) AS platform_revenue,

    ROUND(
        COALESCE(average_transaction_value, 0)::numeric,
        2
    ) AS average_transaction_value,

    last_transaction_date,

    CASE
        WHEN last_transaction_date IS NULL
            THEN 'Never Active'

        WHEN DATE '2026-08-19' - last_transaction_date >= 180
            THEN 'High Risk'

        WHEN DATE '2026-08-19' - last_transaction_date >= 90
            THEN 'At Risk'

        WHEN DATE '2026-08-19' - last_transaction_date >= 30
            THEN 'Monitor'

        ELSE 'Active'
    END AS activity_risk_status,

    CASE
        WHEN COALESCE(total_transaction_value, 0) >= 500000
            THEN 'VIP'

        WHEN COALESCE(total_transaction_value, 0) >= 200000
            THEN 'High Value'

        WHEN COALESCE(total_transaction_value, 0) >= 50000
            THEN 'Medium Value'

        ELSE 'Low Value'
    END AS customer_value_segment

FROM customer_metrics

ORDER BY total_transaction_value DESC;

--transaction status performance
SELECT
    transaction_status,

    COUNT(*) AS transaction_count,

    ROUND(
        SUM(transaction_amount)::numeric,
        2
    ) AS transaction_value,

    ROUND(
        SUM(fee_amount)::numeric,
        2
    ) AS platform_revenue

FROM transactions

GROUP BY transaction_status

ORDER BY transaction_count DESC;