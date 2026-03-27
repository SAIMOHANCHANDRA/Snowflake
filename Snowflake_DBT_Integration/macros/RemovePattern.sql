{% macro refined_columns_from_table(database, schema, table_name) %}
    {#
        Macro: refined_columns_from_table
        Purpose:
          Fetches columns from INFORMATION_SCHEMA.COLUMNS and
          refines them according to pattern rules:
            1. Replace "_c__c" → "__c"
            2. Remove "__c" suffix
          Then outputs:
            NULLIF(TRIM(column)) AS refined_name
    #}

    {% set query %}
        SELECT COLUMN_NAME
        FROM {{ database }}.INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = '{{ schema }}'
          AND TABLE_NAME = '{{ table_name }}'
        ORDER BY ORDINAL_POSITION
    {% endset %}

    {% set results = run_query(query) %}

    {% if execute %}
        {% set columns = results.columns[0].values() %}
        {% set refined_cols = [] %}

        {% for col in columns %}
            {# Step 1: Replace _c__c → __c #}
            {% set cleaned = col | replace('_c__c', '__c') %}
            {# Step 2: Remove trailing __c if present #}
            {% if cleaned.endswith('__c') %}
                {% set alias = cleaned[:-3] %}
            {% else %}
                {% set alias = cleaned %}
            {% endif %}

            {# Step 3: Build SELECT expression #}
            {% set select_expr = "NULLIF(TRIM(\"" ~ col ~"\")) AS " ~ alias %}
            {% do refined_cols.append(select_expr) %}
        {% endfor %}

        {{ return(refined_cols | join(', ')) }}
    {% else %}
        {{ return('') }}
    {% endif %}
{% endmacro %}
