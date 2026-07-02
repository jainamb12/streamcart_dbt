{% snapshot product_price_snapshot %}

{{
    config(
      target_schema='snapshots',
      unique_key='product_id',
      strategy='check',
      check_cols=['list_price', 'is_available']
    )
}}

WITH extracted AS (
    SELECT 
        TRIM(get_json_object(data, '$.product_id')) AS product_id,
        CAST(get_json_object(data, '$.pricing.list_price') AS FLOAT) AS list_price,
        CASE 
            WHEN LOWER(get_json_object(data, '$.is_available')) IN ('1', 'yes', 'true') THEN TRUE 
            ELSE FALSE 
        END AS is_available,
        _loaded_at,
        ROW_NUMBER() OVER (
            PARTITION BY TRIM(get_json_object(data, '$.product_id')) 
            ORDER BY _loaded_at DESC
        ) AS rn
    FROM {{ source('raw_streamcart', 'raw_products') }}
)

SELECT 
    product_id,
    list_price,
    is_available,
    _loaded_at
FROM extracted
WHERE rn = 1

{% endsnapshot %}