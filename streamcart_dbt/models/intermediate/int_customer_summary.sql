{{ config(materialized='ephemeral') }}

WITH enriched_orders AS (
    SELECT * FROM {{ ref('int_orders_enriched') }}
),

customer_aggs AS (
    SELECT 
        customer_id,
        MAX(customer_name) AS customer_name,
        MAX(email) AS email,
        MAX(phone) AS phone,
        MAX(customer_tier) AS customer_tier,
        MAX(city) AS city,
        MAX(country_code) AS country_code,
        COUNT(DISTINCT CASE WHEN payment_status = 'success' THEN order_id END) AS total_orders,
        SUM(CASE WHEN payment_status = 'success' THEN gross_amount ELSE 0 END) AS total_gross_revenue,
        SUM(CASE WHEN payment_status = 'success' THEN net_amount ELSE 0 END) AS total_net_revenue,
        MAX(order_date) AS last_order_date
    FROM enriched_orders
    GROUP BY customer_id
)

SELECT 
    *,
    datediff(CURRENT_DATE(), last_order_date) AS days_since_last_order,
    CASE 
        WHEN total_orders >= 10 THEN 'Platinum'
        WHEN total_orders >= 5 THEN 'Gold'
        WHEN total_orders >= 2 THEN 'Silver'
        ELSE 'Bronze'
    END AS customer_segment
FROM customer_aggs