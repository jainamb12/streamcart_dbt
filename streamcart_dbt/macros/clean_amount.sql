{% macro clean_amount(col) %}
    CAST(REPLACE(REPLACE(TRIM({{ col }}), '$', ''), ',', '') AS DECIMAL(12,2))
{% endmacro %}