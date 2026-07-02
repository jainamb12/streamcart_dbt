WITH raw_data AS (
    SELECT 
        data, 
        _loaded_at 
    FROM {{ source('raw_streamcart', 'raw_products') }}
),
extracted AS (
    SELECT 
        TRIM(get_json_object(data, '$.product_id')) AS product_id,
        get_json_object(data, '$.name') AS raw_name,
        get_json_object(data, '$.category') AS raw_category,
        get_json_object(data, '$.sub_category') AS raw_sub_category,
        get_json_object(data, '$.brand') AS raw_brand,
        get_json_object(data, '$.is_available') AS raw_is_available,
        get_json_object(data, '$.tags') AS raw_tags,
        get_json_object(data, '$.specs.weight_kg') AS raw_weight_kg,
        get_json_object(data, '$.specs.warranty_yr') AS raw_warranty_yr,
        get_json_object(data, '$.pricing.cost_price') AS raw_cost_price,
        get_json_object(data, '$.pricing.list_price') AS raw_list_price,
        get_json_object(data, '$.stock.qty_on_hand') AS raw_qty_on_hand,
        get_json_object(data, '$.stock.reorder_lvl') AS raw_reorder_lvl,
        get_json_object(data, '$.stock.warehouse') AS raw_warehouse,
        ROW_NUMBER() OVER (
            PARTITION BY TRIM(get_json_object(data, '$.product_id')) 
            ORDER BY _loaded_at DESC
        ) AS rn
    FROM raw_data
),

cleaned AS (
    -- Apply cleaning rules
    SELECT 
        product_id,
        TRIM(raw_name) AS product_name,
        INITCAP(LOWER(raw_category)) AS category,
        LOWER(TRIM(raw_sub_category)) AS sub_category,
        INITCAP(LOWER(raw_brand)) AS brand,
        CASE 
            WHEN LOWER(raw_is_available) IN ('1', 'yes', 'true') THEN TRUE 
            ELSE FALSE 
        END AS is_available,
        -- Remove JSON brackets and quotes to create a comma-separated string
        REGEXP_REPLACE(raw_tags, '[\\[\\]\\"]', '') AS tags,
        CAST(raw_weight_kg AS FLOAT) AS weight_kg,
        CAST(raw_warranty_yr AS INTEGER) AS warranty_years,
        CAST(raw_cost_price AS FLOAT) AS cost_price,
        CAST(raw_list_price AS FLOAT) AS list_price,
        CAST(raw_qty_on_hand AS INTEGER) AS qty_on_hand,
        CAST(raw_reorder_lvl AS INTEGER) AS reorder_level,
        UPPER(TRIM(raw_warehouse)) AS warehouse_code
    FROM extracted
    WHERE rn = 1
),

final AS (
    -- Calculate derived columns
    SELECT 
        *,
        ROUND((list_price - cost_price) / NULLIF(list_price, 0) * 100, 2) AS margin_pct,
        CASE 
            WHEN qty_on_hand <= reorder_level THEN TRUE 
            ELSE FALSE 
        END AS is_low_stock
    FROM cleaned
)

SELECT * FROM final limit 5