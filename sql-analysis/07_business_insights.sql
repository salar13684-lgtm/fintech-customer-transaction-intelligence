SELECT
    COUNT(DISTINCT c.customer_id) AS total_customers,

    COUNT(t.transaction_id) AS completed_transactions,

    ROUND(
        SUM(t.transaction_amount)::numeric,
        2
    ) AS total_transaction_value,

    ROUND(
        SUM(t.fee_amount)::numeric,
        2
    ) AS total_platform_revenue,

    ROUND(
        AVG(t.transaction_amount)::numeric,
        2
    ) AS average_transaction_value,

    ROUND(
        AVG(t.fee_amount)::numeric,
        2
    ) AS average_transaction_fee

FROM customers AS c

INNER JOIN transactions AS t
    ON c.customer_id = t.customer_id

WHERE t.transaction_status = 'Completed';

--strongest region
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
        SUM(t.fee_amount) /
        COUNT(DISTINCT c.customer_id),
        2
    ) AS revenue_per_customer

FROM customers AS c

INNER JOIN transactions AS t
    ON c.customer_id = t.customer_id

WHERE t.transaction_status = 'Completed'

GROUP BY c.region

ORDER BY platform_revenue DESC;

--strongest customer segment
WITH customer_value AS (
    SELECT
        c.customer_id,

        SUM(t.transaction_amount) AS total_spending

    FROM customers AS c

    INNER JOIN transactions AS t
        ON c.customer_id = t.customer_id

    WHERE t.transaction_status = 'Completed'

    GROUP BY c.customer_id
),

segments AS (
    SELECT
        customer_id,
        total_spending,

        CASE
            WHEN total_spending >= 500000 THEN 'VIP'
            WHEN total_spending >= 200000 THEN 'High Value'
            WHEN total_spending >= 50000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_segment

    FROM customer_value
)

SELECT
    customer_segment,

    COUNT(*) AS customers,

    ROUND(
        SUM(total_spending)::numeric,
        2
    ) AS transaction_value,

    ROUND(
        AVG(total_spending)::numeric,
        2
    ) AS average_customer_value

FROM segments

GROUP BY customer_segment

ORDER BY transaction_value DESC;

-- segment contribution %
WITH customer_value AS (
    SELECT
        c.customer_id,
        SUM(t.transaction_amount) AS total_spending

    FROM customers AS c

    INNER JOIN transactions AS t
        ON c.customer_id = t.customer_id

    WHERE t.transaction_status = 'Completed'

    GROUP BY c.customer_id
),

segments AS (
    SELECT
        customer_id,
        total_spending,

        CASE
            WHEN total_spending >= 500000 THEN 'VIP'
            WHEN total_spending >= 200000 THEN 'High Value'
            WHEN total_spending >= 50000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_segment

    FROM customer_value
),

segment_summary AS (
    SELECT
        customer_segment,
        SUM(total_spending) AS segment_value
    FROM segments
    GROUP BY customer_segment
)

SELECT
    customer_segment,

    ROUND(
        segment_value::numeric,
        2
    ) AS segment_value,

    ROUND(
        (
            segment_value * 100.0 /
            SUM(segment_value) OVER ()
        )::numeric,
        2
    ) AS value_contribution_percentage

FROM segment_summary

ORDER BY segment_value DESC;

--WITH customer_metrics AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        c.region,

        COUNT(t.transaction_id) AS transaction_count,

        SUM(t.transaction_amount) AS total_spending,

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

    transaction_count,

    ROUND(
        total_spending::numeric,
        2
    ) AS total_spending,

    last_transaction_date,

    DATE '2026-08-19' - last_transaction_date
        AS days_since_last_transaction

FROM customer_metrics

WHERE total_spending >= 200000

  AND DATE '2026-08-19' - last_transaction_date >= 90

ORDER BY total_spending DESC;

--biggest retention opportunity
WITH customer_metrics AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        c.region,

        COUNT(t.transaction_id) AS transaction_count,

        SUM(t.transaction_amount) AS total_spending,

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

    transaction_count,

    ROUND(
        total_spending::numeric,
        2
    ) AS total_spending,

    last_transaction_date,

    DATE '2026-08-19' - last_transaction_date
        AS days_since_last_transaction

FROM customer_metrics

WHERE total_spending >= 200000

  AND DATE '2026-08-19' - last_transaction_date >= 90

ORDER BY total_spending DESC;

 --Quantify the retention opportunity
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

at_risk AS (
    SELECT
        customer_id,
        region,
        total_spending

    FROM customer_metrics

    WHERE total_spending >= 200000

      AND DATE '2026-08-19' - last_transaction_date >= 90
)

SELECT
    COUNT(*) AS at_risk_customers,

    ROUND(
        SUM(total_spending)::numeric,
        2
    ) AS at_risk_transaction_value,

    ROUND(
        AVG(total_spending)::numeric,
        2
    ) AS average_at_risk_customer_value

FROM at_risk;

--strongest transaction type
SELECT
    transaction_type,

    COUNT(*) AS transactions,

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

GROUP BY transaction_type

ORDER BY platform_revenue DESC;

--strongest payment method
SELECT
    payment_method,

    COUNT(*) AS transactions,

    ROUND(
        SUM(transaction_amount)::numeric,
        2
    ) AS transaction_value,

    ROUND(
        SUM(fee_amount)::numeric,
        2
    ) AS platform_revenue

FROM transactions

WHERE transaction_status = 'Completed'

GROUP BY payment_method

ORDER BY transactions DESC;

--Analyzing transaction failures
SELECT
    transaction_status,

    COUNT(*) AS transaction_count,

    ROUND(
        SUM(transaction_amount)::numeric,
        2
    ) AS transaction_value

FROM transactions

GROUP BY transaction_status

ORDER BY transaction_count DESC;

--overall failure rate.
SELECT
    COUNT(*) AS total_transactions,

    COUNT(*) FILTER (
        WHERE transaction_status = 'Failed'
    ) AS failed_transactions,

    ROUND(
        (
            COUNT(*) FILTER (
                WHERE transaction_status = 'Failed'
            ) * 100.0
            / NULLIF(COUNT(*), 0)
        )::numeric,
        2
    ) AS failure_rate_percentage

FROM transactions;

--Failure rate by payment method
SELECT
    payment_method,

    COUNT(*) AS total_transactions,

    COUNT(*) FILTER (
        WHERE transaction_status = 'Failed'
    ) AS failed_transactions,

    ROUND(
        (
            COUNT(*) FILTER (
                WHERE transaction_status = 'Failed'
            ) * 100.0
            / NULLIF(COUNT(*), 0)
        )::numeric,
        2
    ) AS failure_rate_percentage

FROM transactions

GROUP BY payment_method

ORDER BY failure_rate_percentage DESC;

--Failure rate by transaction type
SELECT
    transaction_type,

    COUNT(*) AS total_transactions,

    COUNT(*) FILTER (
        WHERE transaction_status = 'Failed'
    ) AS failed_transactions,

    ROUND(
        (
            COUNT(*) FILTER (
                WHERE transaction_status = 'Failed'
            ) * 100.0
            / NULLIF(COUNT(*), 0)
        )::numeric,
        2
    ) AS failure_rate_percentage

FROM transactions

GROUP BY transaction_type

ORDER BY failure_rate_percentage DESC;

--Monthly revenue trend: identify growth/decline
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', transaction_date)::date
            AS transaction_month,

        SUM(fee_amount) AS monthly_revenue

    FROM transactions

    WHERE transaction_status = 'Completed'

    GROUP BY
        DATE_TRUNC('month', transaction_date)
),

monthly_growth AS (
    SELECT
        transaction_month,
        monthly_revenue,

        LAG(monthly_revenue) OVER (
            ORDER BY transaction_month
        ) AS previous_month_revenue

    FROM monthly_revenue
)

SELECT
    transaction_month,

    ROUND(
        monthly_revenue::numeric,
        2
    ) AS monthly_revenue,

    ROUND(
        (
            (
                monthly_revenue - previous_month_revenue
            ) * 100.0
            / NULLIF(previous_month_revenue, 0)
        )::numeric,
        2
    ) AS revenue_growth_percentage

FROM monthly_growth

ORDER BY transaction_month;

--Monthly active customer trend
WITH monthly_activity AS (
    SELECT
        DATE_TRUNC('month', transaction_date)::date
            AS transaction_month,

        COUNT(DISTINCT customer_id)
            AS active_customers

    FROM transactions

    WHERE transaction_status = 'Completed'

    GROUP BY
        DATE_TRUNC('month', transaction_date)
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

    ROUND(
        (
            (
                active_customers
                - previous_month_active_customers
            ) * 100.0
            / NULLIF(previous_month_active_customers, 0)
        )::numeric,
        2
    ) AS active_customer_growth_percentage

FROM activity_growth

ORDER BY transaction_month;
