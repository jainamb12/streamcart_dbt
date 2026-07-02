{% macro generate_row_key(cols_list) %}
    MD5(CONCAT_WS('|', {% for col in cols_list %}{{ col }}{% if not loop.last %}, {% endif %}{% endfor %}))
{% endmacro %}