{% macro clean_columns_from_table(schema_name, table_name) %}
    {# 
        Get column names from INFORMATION_SCHEMA.COLUMNS
        Then apply cleaning rules:
        - If column ends with '__c', remove it
        - If column ends with '_c__c', remove the '_c' before '__c'
    #}

    {% set columns_query %}
        SELECT COLUMN_NAME
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = '{{ schema_name }}'
          AND TABLE_NAME = '{{ table_name }}'
        ORDER BY ORDINAL_POSITION
    {% endset %}

    {% set raw_columns = run_query(columns_query).columns[0].values() %}

    {% set cleaned_columns = [] %}

    {% for col in raw_columns %}
        {% if col.endswith('_c__c') %}
            {% set cleaned_col = col.replace('_c__c', '__c') %}
        {% elif col.endswith('__c') %}
            {% set cleaned_col = col[:-3] %}
        {% else %}
            {% set cleaned_col = col %}
        {% endif %}
        {% do cleaned_columns.append(cleaned_col) %}
    {% endfor %}

    {{ cleaned_columns | join(', ') }}
{% endmacro %}
