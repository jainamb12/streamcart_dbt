WITH staging AS (
    SELECT * FROM {{ ref('stg_orders') }}
)

SELECT
    customer_id,
    -- dbt_utils.pivot
    {{ dbt_utils.pivot(
        'channel',
        ['mobile_app', 'web', 'partner_api'],
        agg='sum',
        then_value='net_amount'
    ) }}
FROM staging
GROUP BY customer_id