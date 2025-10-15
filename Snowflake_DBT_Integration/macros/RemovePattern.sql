{% macro remove_pattern_from_columns(columns, pattern) %}
    {# This macro removes the given pattern from the END of each column name #}
    {% set cleaned_columns = [] %}

    {% for col in columns %}
        {% if col.endswith(pattern) %}
            {% set cleaned_col = col[:-pattern|length] %}
        {% else %}
            {% set cleaned_col = col %}
        {% endif %}
        {% do cleaned_columns.append(cleaned_col) %}
    {% endfor %}

    {{ return(cleaned_columns) }}
{% endmacro %}
