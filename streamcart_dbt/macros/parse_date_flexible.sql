{% macro parse_date_flexible(col, fmt1, fmt2) %}
    CASE 
        WHEN {{ col }} LIKE '__/__/____%' THEN to_date({{ col }}, '{{ fmt1 }}') 
        ELSE to_date({{ col }}, '{{ fmt2 }}') 
    END
{% endmacro %}