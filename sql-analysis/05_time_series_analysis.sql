--6 Time-Series Analytics
--Monthly transaction overcview 
SELECT
    DATE_TRUNC('month', transaction_date)::date AS transaction_month,
    COUNT(*) AS transaction_count,
    ROUND(SUM(transaction_amount)::numeric, 2) AS transaction_value,
    ROUND(AVG(transaction_amount)::numeric, 2) AS average_transaction_value,
    ROUND(SUM(fee_amount)::numeric, 2) AS platform_revenue
FROM transactions
WHERE transaction_status = 'Completed'
GROUP BY DATE_TRUNC('month', transaction_date)
ORDER BY transaction_month;


--Monthly revenue 
SELECT
    DATE_TRUNC('month', transaction_date)::date AS transaction_month,
    ROUND(SUM(fee_amount)::numeric, 2) AS monthly_revenue
FROM transactions
WHERE transaction_status = 'Completed'
GROUP BY DATE_TRUNC('month', transaction_date)
ORDER BY transaction_month;

--Month over month revenue
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', transaction_date)::date AS transaction_month,
        SUM(fee_amount) AS monthly_revenue
    FROM transactions
    WHERE transaction_status = 'Completed'
    GROUP BY DATE_TRUNC('month', transaction_date)
)

SELECT
    transaction_month,
    ROUND(monthly_revenue::numeric, 2) AS monthly_revenue,

    ROUND(
        LAG(monthly_revenue) OVER (
            ORDER BY transaction_month
        )::numeric,
        2
    ) AS previous_month_revenue

FROM monthly_revenue
ORDER BY transaction_month;

--Monthly revenue growth %
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', transaction_date)::date AS transaction_month,
        SUM(fee_amount) AS monthly_revenue
    FROM transactions
    WHERE transaction_status = 'Completed'
    GROUP BY DATE_TRUNC('month', transaction_date)
),

revenue_with_previous AS (
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
        previous_month_revenue::numeric,
        2
    ) AS previous_month_revenue,

    ROUND(
        (
            (monthly_revenue - previous_month_revenue)
            * 100.0
            / NULLIF(previous_month_revenue, 0)
        )::numeric,
        2
    ) AS revenue_growth_percentage

FROM revenue_with_previous
ORDER BY transaction_month;

--Monthly transaction growth
WITH monthly_transactions AS (
    SELECT
        DATE_TRUNC('month', transaction_date)::date AS transaction_month,
        COUNT(*) AS transaction_count
    FROM transactions
    WHERE transaction_status = 'Completed'
    GROUP BY DATE_TRUNC('month', transaction_date)
),

transaction_growth AS (
    SELECT
        transaction_month,
        transaction_count,

        LAG(transaction_count) OVER (
            ORDER BY transaction_month
        ) AS previous_month_transactions

    FROM monthly_transactions
)

SELECT
    transaction_month,
    transaction_count,
    previous_month_transactions,

    ROUND(
        (
            (transaction_count - previous_month_transactions)
            * 100.0
            / NULLIF(previous_month_transactions, 0)
        )::numeric,
        2
    ) AS transaction_growth_percentage

FROM transaction_growth
ORDER BY transaction_month;

--Monthly average transaction value 
SELECT
    DATE_TRUNC('month', transaction_date)::date AS transaction_month,

    COUNT(*) AS transaction_count,

    ROUND(
        AVG(transaction_amount)::numeric,
        2
    ) AS average_transaction_value

FROM transactions

WHERE transaction_status = 'Completed'

GROUP BY DATE_TRUNC('month', transaction_date)

ORDER BY transaction_month;

--Running cumulative revenue
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', transaction_date)::date AS transaction_month,
        SUM(fee_amount) AS monthly_revenue
    FROM transactions
    WHERE transaction_status = 'Completed'
    GROUP BY DATE_TRUNC('month', transaction_date)
)

SELECT
    transaction_month,

    ROUND(
        monthly_revenue::numeric,
        2
    ) AS monthly_revenue,

    ROUND(
        SUM(monthly_revenue) OVER (
            ORDER BY transaction_month
        )::numeric,
        2
    ) AS cumulative_revenue

FROM monthly_revenue

ORDER BY transaction_month;

--month moving average revenue 
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', transaction_date)::date AS transaction_month,
        SUM(fee_amount) AS monthly_revenue
    FROM transactions
    WHERE transaction_status = 'Completed'
    GROUP BY DATE_TRUNC('month', transaction_date)
)

SELECT
    transaction_month,

    ROUND(
        monthly_revenue::numeric,
        2
    ) AS monthly_revenue,

    ROUND(
        AVG(monthly_revenue) OVER (
            ORDER BY transaction_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        )::numeric,
        2
    ) AS three_month_moving_average

FROM monthly_revenue

ORDER BY transaction_month;

--best revenue month
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', transaction_date)::date AS transaction_month,
        SUM(fee_amount) AS monthly_revenue
    FROM transactions
    WHERE transaction_status = 'Completed'
    GROUP BY DATE_TRUNC('month', transaction_date)
)

SELECT
    transaction_month,
    ROUND(monthly_revenue::numeric, 2) AS monthly_revenue
FROM monthly_revenue
ORDER BY monthly_revenue DESC
LIMIT 1;

--lowest revenue month
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', transaction_date)::date AS transaction_month,
        SUM(fee_amount) AS monthly_revenue
    FROM transactions
    WHERE transaction_status = 'Completed'
    GROUP BY DATE_TRUNC('month', transaction_date)
)

SELECT
    transaction_month,
    ROUND(monthly_revenue::numeric, 2) AS monthly_revenue
FROM monthly_revenue
ORDER BY monthly_revenue
LIMIT 1;

--monthly revenue ranking
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', transaction_date)::date AS transaction_month,
        SUM(fee_amount) AS monthly_revenue
    FROM transactions
    WHERE transaction_status = 'Completed'
    GROUP BY DATE_TRUNC('month', transaction_date)
)

SELECT
    transaction_month,

    ROUND(
        monthly_revenue::numeric,
        2
    ) AS monthly_revenue,

    RANK() OVER (
        ORDER BY monthly_revenue DESC
    ) AS revenue_rank

FROM monthly_revenue

ORDER BY revenue_rank;

--monthly transaction typer performance
SELECT
    DATE_TRUNC('month', transaction_date)::date AS transaction_month,
    transaction_type,

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

WHERE transaction_status = 'Completed'

GROUP BY
    DATE_TRUNC('month', transaction_date),
    transaction_type

ORDER BY
    transaction_month,
    platform_revenue DESC;

--monthyly payment method performance
SELECT
    DATE_TRUNC('month', transaction_date)::date AS transaction_month,
    payment_method,

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

WHERE transaction_status = 'Completed'

GROUP BY
    DATE_TRUNC('month', transaction_date),
    payment_method

ORDER BY
    transaction_month,
    transaction_value DESC;

--monthly regional revenue 
SELECT
    DATE_TRUNC('month', t.transaction_date)::date AS transaction_month,
    c.region,

    COUNT(t.transaction_id) AS transaction_count,

    ROUND(
        SUM(t.transaction_amount)::numeric,
        2
    ) AS transaction_value,

    ROUND(
        SUM(t.fee_amount)::numeric,
        2
    ) AS platform_revenue

FROM customers AS c

INNER JOIN transactions AS t
    ON c.customer_id = t.customer_id

WHERE t.transaction_status = 'Completed'

GROUP BY
    DATE_TRUNC('month', t.transaction_date),
    c.region

ORDER BY
    transaction_month,
    platform_revenue DESC;

--Month over month regional revenue
WITH monthly_region_revenue AS (
    SELECT
        DATE_TRUNC('month', t.transaction_date)::date AS transaction_month,
        c.region,
        SUM(t.fee_amount) AS monthly_revenue
    FROM customers AS c
    INNER JOIN transactions AS t
        ON c.customer_id = t.customer_id
    WHERE t.transaction_status = 'Completed'
    GROUP BY
        DATE_TRUNC('month', t.transaction_date),
        c.region
),

regional_growth AS (
    SELECT
        transaction_month,
        region,
        monthly_revenue,

        LAG(monthly_revenue) OVER (
            PARTITION BY region
            ORDER BY transaction_month
        ) AS previous_month_revenue

    FROM monthly_region_revenue
)

SELECT
    transaction_month,
    region,

    ROUND(
        monthly_revenue::numeric,
        2
    ) AS monthly_revenue,

    ROUND(
        previous_month_revenue::numeric,
        2
    ) AS previous_month_revenue,

    ROUND(
        (
            (monthly_revenue - previous_month_revenue)
            * 100.0
            / NULLIF(previous_month_revenue, 0)
        )::numeric,
        2
    ) AS revenue_growth_percentage

FROM regional_growth

ORDER BY
    region,
    transaction_month;
