{{ config(
    materialized='incremental',
    unique_key='event_id',
    incremental_strategy='merge'
) }}

WITH raw_data AS (
    SELECT 
        {{ dbt_utils.star(from=source('raw_streamcart', 'raw_orders'), except=["_source"]) }}
    FROM {{ source('raw_streamcart', 'raw_orders') }} AS src
    
    {% if is_incremental() %}
      WHERE src._loaded_at > (SELECT MAX(tgt._loaded_at) FROM {{ this }} AS tgt)
    {% endif %}
),

extracted_events AS (
    SELECT 
        _loaded_at,
        TRIM(get_json_object(data, '$.event_id')) AS event_id,
        get_json_object(data, '$.metadata.is_test_event') AS is_test_event,
        data,
        ROW_NUMBER() OVER (
            PARTITION BY TRIM(get_json_object(data, '$.event_id')) 
            ORDER BY _loaded_at DESC
        ) AS rn
    FROM raw_data
),

deduped_events AS (
    SELECT * FROM extracted_events 
    WHERE rn = 1 
      AND LOWER(is_test_event) != 'true'
      
    -- J3: Date Filter Variable
    {% if var('lookback_days', none) is not none %}
      AND _loaded_at >= date_add(CURRENT_TIMESTAMP(), -{{ var('lookback_days') }})
    {% endif %}
),

exploded_items AS (
    SELECT 
        _loaded_at,
        event_id,
        get_json_object(data, '$.event_type') AS event_type,
        get_json_object(data, '$.occurred_at') AS occurred_at,
        get_json_object(data, '$.customer.id') AS customer_id,
        get_json_object(data, '$.customer.name') AS customer_name,
        get_json_object(data, '$.customer.email') AS email,
        get_json_object(data, '$.customer.phone') AS phone,
        get_json_object(data, '$.customer.tier') AS customer_tier,
        get_json_object(data, '$.customer.address.city') AS city,
        get_json_object(data, '$.customer.address.country') AS country_code,
        get_json_object(data, '$.order.order_id') AS order_id,
        get_json_object(data, '$.order.channel') AS channel,
        get_json_object(data, '$.order.placed_at') AS order_date,
        get_json_object(data, '$.order.currency') AS currency_code,
        get_json_object(data, '$.order.total_amount') AS order_total,
        get_json_object(data, '$.order.payment.method') AS payment_method,
        get_json_object(data, '$.order.payment.status') AS payment_status,
        
        explode(from_json(
            get_json_object(data, '$.order.items'), 
            'array<struct<product_id:string,qty:string,unit_price:string,discount_pct:string>>'
        )) AS item
    FROM deduped_events
),

cleaned AS (
    SELECT
        _loaded_at,
        event_id,
        LOWER(TRIM(event_type)) AS event_type,
        to_timestamp(occurred_at, 'dd/MM/yyyy HH:mm:ss') AS occurred_at,
        TRIM(customer_id) AS customer_id,
        
        -- J1: PII Masking Logic
        {% if target.name == 'prod' %}
            INITCAP(TRIM(customer_name)) AS customer_name,
            LOWER(TRIM(email)) AS email,
        {% else %}
            CONCAT('Customer_', TRIM(customer_id)) AS customer_name,
            MD5(LOWER(TRIM(email))) AS email,
        {% endif %}
        
        RIGHT(REGEXP_REPLACE(phone, '[^0-9]', ''), 10) AS phone,
        COALESCE(INITCAP(LOWER(customer_tier)), 'Standard') AS customer_tier,
        INITCAP(LOWER(city)) AS city,
        UPPER(TRIM(country_code)) AS country_code,
        TRIM(order_id) AS order_id,
        LOWER(REPLACE(channel, ' ', '')) AS channel,
        
        -- Macro: parse_date_flexible
        {{ parse_date_flexible('order_date', 'dd/MM/yyyy', 'yyyy-MM-dd') }} AS order_date,
        
        UPPER(TRIM(currency_code)) AS currency_code,
        
        -- Macro: clean_amount
        {{ clean_amount('order_total') }} AS order_total,
        
        TRIM(item.product_id) AS product_id,
        NULLIF(CAST(item.qty AS INTEGER), 0) AS quantity,
        
        -- Macro: clean_amount
        {{ clean_amount('item.unit_price') }} AS unit_price,
        
        CASE 
            WHEN CAST(item.discount_pct AS FLOAT) > 60 THEN NULL 
            ELSE CAST(item.discount_pct AS FLOAT) 
        END AS discount_pct,
        
        LOWER(REPLACE(payment_method, ' ', '')) AS payment_method,
        LOWER(payment_status) AS payment_status
    FROM exploded_items
),

final AS (
    SELECT 
        *,
        (quantity * unit_price) AS gross_amount,
        -- Macro: safe_net_amount
        {{ safe_net_amount('(quantity * unit_price)', 'discount_pct') }} AS net_amount
    FROM cleaned
)

SELECT * FROM final