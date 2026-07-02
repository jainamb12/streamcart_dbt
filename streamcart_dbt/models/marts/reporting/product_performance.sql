{{ config(materialized='table') }}
WITH fct_orders AS (
    SELECT * FROM {{ ref('fct_orders') }}
),
products AS (
    SELECT * FROM {{ ref('stg_products') }}
),
product_metrics AS (
    SELECT 
        product_id,
        MAX(product_name) AS product_name,
        MAX(category) AS category,
        MAX(sub_category) AS sub_category,
        MAX(brand) AS brand,
        MAX(margin_pct) AS margin_pct,
        MAX(is_low_stock) AS is_low_stock,
        SUM(CASE WHEN payment_status = 'success' THEN quantity ELSE 0 END) AS total_units_sold,
        SUM(CASE WHEN payment_status = 'success' THEN net_amount ELSE 0 END) AS total_net_revenue,
        AVG(discount_pct) AS avg_discount_pct
    FROM fct_orders
    GROUP BY product_id
)

SELECT 
    pm.product_id,
    pm.product_name,
    pm.category,
    pm.sub_category,
    pm.brand,
    pm.margin_pct,
    pm.is_low_stock,
    pm.total_units_sold,
    pm.total_net_revenue,
    pm.avg_discount_pct,
    RANK() OVER (PARTITION BY pm.category ORDER BY pm.total_net_revenue DESC) AS revenue_rank,
    p.qty_on_hand,
    p.reorder_level,
    p.warehouse_code
FROM product_metrics pm
LEFT JOIN products p ON pm.product_id = p.product_id