{{ config(materialized='ephemeral') }}

WITH orders AS (
    SELECT * FROM {{ ref('stg_orders') }}
    WHERE event_type = 'order_placed'
),

products AS (
    SELECT * FROM {{ ref('stg_products') }}
)

SELECT 
    o.*,
    p.product_name,
    p.category,
    p.sub_category,
    p.brand,
    p.margin_pct,
    p.is_low_stock,
    CASE WHEN o.discount_pct > 0 THEN TRUE ELSE FALSE END AS is_discounted
FROM orders o
LEFT JOIN products p ON o.product_id = p.product_id