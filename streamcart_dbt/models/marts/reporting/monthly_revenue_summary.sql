{{ config(materialized='table') }}
WITH success_orders AS (
    SELECT * FROM {{ ref('fct_orders') }}
    WHERE payment_status = 'success'
),
monthly_base AS (
    SELECT 
        YEAR(order_date) AS order_year,
        MONTH(order_date) AS order_month,
        COUNT(DISTINCT order_id) AS total_orders,
        SUM(gross_amount) AS total_gross_revenue,
        SUM(net_amount) AS total_net_revenue,
        SUM(gross_amount - net_amount) AS total_discount_given,
        AVG(discount_pct) AS avg_discount_pct
    FROM success_orders
    GROUP BY 1, 2
),
-- Window functions to find top category and channel per month
ranked_categories AS (
    SELECT 
        YEAR(order_date) AS order_year, MONTH(order_date) AS order_month, category, SUM(net_amount) AS cat_revenue
    FROM success_orders
    GROUP BY 1, 2, 3
),
ranked_channels AS (
    SELECT 
        YEAR(order_date) AS order_year, MONTH(order_date) AS order_month, channel, COUNT(DISTINCT order_id) AS channel_orders
    FROM success_orders
    GROUP BY 1, 2, 3
)
SELECT DISTINCT
    m.*,
    FIRST_VALUE(c.category) OVER (PARTITION BY m.order_year, m.order_month ORDER BY c.cat_revenue DESC) AS top_category,
    FIRST_VALUE(ch.channel) OVER (PARTITION BY m.order_year, m.order_month ORDER BY ch.channel_orders DESC) AS top_channel
FROM monthly_base m
LEFT JOIN ranked_categories c ON m.order_year = c.order_year AND m.order_month = c.order_month
LEFT JOIN ranked_channels ch ON m.order_year = ch.order_year AND m.order_month = ch.order_month