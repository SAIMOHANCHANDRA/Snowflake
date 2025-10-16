{% macro compare_table_schemas(src_db, src_schema, src_table, tgt_db, tgt_schema, tgt_table) %}
    {# Step 1: Prepare queries to fetch schema metadata #}
    {% set src_query %}
        SELECT COLUMN_NAME, DATA_TYPE
        FROM {{ src_db }}.INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = '{{ src_schema | upper }}' AND TABLE_NAME = '{{ src_table | upper }}'
    {% endset %}

    {% set tgt_query %}
        SELECT COLUMN_NAME, DATA_TYPE
        FROM {{ tgt_db }}.INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = '{{ tgt_schema | upper }}' AND TABLE_NAME = '{{ tgt_table | upper }}'
    {% endset %}

    {# Step 2: Run both queries #}
    {% set src_result = run_query(src_query) %}
    {% set tgt_result = run_query(tgt_query) %}

    {% if not src_result or not tgt_result %}
        {% do log("One of the tables does not exist or has no columns.", info=true) %}
        {% do return({
            'source_table': src_db ~ '.' ~ src_schema ~ '.' ~ src_table,
            'target_table': tgt_db ~ '.' ~ tgt_schema ~ '.' ~ tgt_table,
            'added': [], 
            'deleted': [], 
            'datatype_changed': []
        }) %}
    {% endif %}

    {# Step 3: Build dictionaries for easy lookup #}
    {% set src_dict = {} %}
    {% for row in src_result %}
        {% do src_dict.update({ row['COLUMN_NAME'] | upper: row['DATA_TYPE'] | upper }) %}
    {% endfor %}

    {% set tgt_dict = {} %}
    {% for row in tgt_result %}
        {% do tgt_dict.update({ row['COLUMN_NAME'] | upper: row['DATA_TYPE'] | upper }) %}
    {% endfor %}

    {# Step 4: Initialize result lists #}
    {% set result = [] %}

    {# Step 5: Compare source vs target for added & datatype mismatches #}
    {% for col, dtype in src_dict.items() %}
        {% if col not in tgt_dict %}
            {#% do result.append('{' ~ '"' ~ col ~ '":["' ~ dtype ~ '","ADDED"]}') %#}
            {% set item = {col: [dtype, "ADD"]} %}
            {% do result.append(item) %}
        {#% elif tgt_dict[col] != dtype %}
            {% do result.append({
                col,dtype,'Updated',tgt_dict[col]
            }) %#}
        {% endif %}
    {% endfor %}

    {# Step 6: Detect deleted columns #}
    {% for col, dtype in tgt_dict.items() %}
        {% if col not in src_dict %}
            {#% do result.append("{" ~ '"' ~ col ~ '":["' ~ dtype ~ '","DELETED"]}') %#}
            {% set item = {col: [dtype, "DELETE"]} %}
            {% do result.append(item) %}
        {% endif %}
    {% endfor %}

    {# Step 7: Combine all results into one dictionary #}
    {% set final_result = 
    {
      "target_table": tgt_db ~ '.' ~ tgt_schema ~ '.' ~ tgt_table
      ,"result":  result
    }
    %}
    
    {{ return(tojson(final_result)) }}

    {# Step 9: Return dictionary to caller #}
    {% do return(final_result) %}
{% endmacro %}