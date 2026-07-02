{{ config(materialized='table') }}

WITH fct_orders AS (
    SELECT * FROM {{ ref('fct_orders') }}
),

daily_metrics AS (
    SELECT 
        order_date,
        channel,
        COUNT(DISTINCT order_id) AS total_orders,
        COUNT(DISTINCT CASE WHEN payment_status = 'success' THEN order_id END) AS successful_orders,
        COUNT(DISTINCT CASE WHEN payment_status = 'failed' THEN order_id END) AS cancelled_orders,
        SUM(CASE WHEN payment_status = 'success' THEN gross_amount ELSE 0 END) AS total_gross_revenue,
        SUM(CASE WHEN payment_status = 'success' THEN net_amount ELSE 0 END) AS total_net_revenue
    FROM fct_orders
    GROUP BY order_date, channel
),

payment_ranks AS (
    SELECT 
        order_date,
        channel,
        payment_method,
        RANK() OVER (PARTITION BY order_date, channel ORDER BY COUNT(*) DESC) AS rnk
    FROM fct_orders
    GROUP BY order_date, channel, payment_method
)

SELECT 
    d.order_date,
    d.channel,
    d.total_orders,
    d.successful_orders,
    d.cancelled_orders,
    (d.successful_orders / NULLIF(d.total_orders, 0)) * 100 AS success_rate_pct,
    d.total_gross_revenue,
    d.total_net_revenue,
    d.total_net_revenue / NULLIF(d.successful_orders, 0) AS avg_order_value,
    p.payment_method AS most_used_payment_method
FROM daily_metrics d
LEFT JOIN (SELECT * FROM payment_ranks WHERE rnk = 1) p 
  ON d.order_date = p.order_date AND d.channel = p.channel