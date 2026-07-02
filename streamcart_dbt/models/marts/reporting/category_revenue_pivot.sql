{% set categories = ['Electronics', 'Apparel', 'Home Goods'] %}

WITH order_data AS (
    SELECT 
        o.customer_id,
        p.category,
        o.net_amount
    FROM {{ ref('stg_orders') }} o
    JOIN {{ ref('stg_products') }} p 
      ON o.product_id = p.product_id
)

SELECT
    customer_id,
    
    -- J2: Jinja For Loop to generate pivot columns
    {% for cat in categories %}
    SUM(CASE WHEN category = '{{ cat }}' THEN net_amount ELSE 0 END) AS {{ cat | lower | replace(' ', '_') }}_revenue
    {% if not loop.last %},{% endif %}
    {% endfor %}
    
FROM order_data
GROUP BY customer_id