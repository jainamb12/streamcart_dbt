{% macro standardise_boolean(col) %}
    CASE 
        WHEN LOWER(TRIM(CAST({{ col }} AS STRING))) IN ('true', '1', 'yes', 'y') THEN TRUE 
        ELSE FALSE 
    END
{% endmacro %}