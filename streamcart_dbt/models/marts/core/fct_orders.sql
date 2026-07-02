{{ config(
    materialized='incremental',
    unique_key='order_line_key',
    incremental_strategy='merge',
    on_schema_change='sync_all_columns',
    partition_by=['order_date'],
    post_hook=[
        "OPTIMIZE {{ this }}",
        "{% if target.name == 'prod' %} GRANT SELECT ON {{ this }} TO ROLE prod_reader {% endif %}"
    ]
) }}
WITH enriched_orders AS (
    SELECT * FROM {{ ref('int_orders_enriched') }} AS src
    
    {% if is_incremental() %}
      WHERE src.order_date > (SELECT MAX(tgt.order_date) FROM {{ this }} AS tgt)
    {% endif %}
),

channels AS (
    SELECT * FROM {{ ref('channel_mapping') }}
)

SELECT 
    eo.event_id,
    eo.order_id,
    eo.customer_id,
    eo.product_id,
    eo.order_date,
    eo.channel,
    ch.channel_label,
    ch.channel_group,
    eo.currency_code,
    eo.payment_method,
    eo.payment_status,
    eo.quantity,
    eo.unit_price,
    eo.discount_pct,
    eo.gross_amount,
    eo.net_amount,
    eo.customer_name,
    eo.customer_tier,
    eo.city,
    eo.product_name,
    eo.category,
    eo.sub_category,
    eo.brand,
    eo.margin_pct,
    eo.is_low_stock,
    {{ dbt_utils.generate_surrogate_key(['eo.order_id', 'eo.product_id']) }} AS order_line_key
    
    {% if var('show_margin', false) %}
    , eo.margin_pct * (1 - COALESCE(eo.discount_pct, 0) / 100) AS effective_margin_pct
    {% endif %}
    
FROM enriched_orders eo
LEFT JOIN channels ch ON eo.channel = ch.channel_code