{{ config(materialized='table') }}

WITH customer_summary AS (
    SELECT * FROM {{ ref('int_customer_summary') }}
),

countries AS (
    SELECT * FROM {{ ref('country_config') }}
)

SELECT 
    cs.customer_id,
    cs.customer_name,
    cs.email,
    cs.phone,
    cs.customer_tier,
    cs.city,
    cs.country_code,
    c.country_name,
    c.region,
    c.currency_default,
    cs.total_orders,
    cs.total_gross_revenue,
    cs.total_net_revenue,
    {{ dbt_utils.safe_divide('cs.total_net_revenue', 'cs.total_orders') }} AS avg_order_value,
    cs.customer_segment,
    cs.days_since_last_order
FROM customer_summary cs
LEFT JOIN countries c ON cs.country_code = c.country_code