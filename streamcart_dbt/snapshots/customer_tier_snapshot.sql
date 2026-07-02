{% snapshot customer_tier_snapshot %}

{{
    config(
      target_schema='snapshots',
      unique_key='customer_id',
      strategy='timestamp',
      updated_at='_loaded_at'
    )
}}

WITH extracted AS (
    SELECT 
        TRIM(get_json_object(data, '$.customer.id')) AS customer_id,
        COALESCE(INITCAP(LOWER(get_json_object(data, '$.customer.tier'))), 'Standard') AS customer_tier,
        INITCAP(LOWER(get_json_object(data, '$.customer.address.city'))) AS city,
        _loaded_at,
        ROW_NUMBER() OVER (
            PARTITION BY TRIM(get_json_object(data, '$.customer.id')) 
            ORDER BY _loaded_at DESC
        ) AS rn
    FROM {{ source('raw_streamcart', 'raw_orders') }}
)

SELECT 
    customer_id,
    customer_tier,
    city,
    _loaded_at
FROM extracted
WHERE rn = 1

{% endsnapshot %}