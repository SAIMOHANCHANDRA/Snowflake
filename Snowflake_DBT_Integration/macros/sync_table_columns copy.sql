{% macro table_columns_sync_copy(primary_col, watermark_col, source_db, source_schema, source_table, target_db, target_schema, target_table) %}
    {% set schema_diff_json = compare_table_schemas(source_db, source_schema, source_table, target_db, target_schema, target_table) %}
    {% set schema_diff = fromjson(schema_diff_json) %}

    {% set primary_col = primary_col | upper %}
    {% set watermark_col = watermark_col | upper %}
    {% set full_table_name = schema_diff["target_table"] | upper %}
    {% set result_log = [] %}

    -- Iterate through each column change
    {% for change in schema_diff["result"] %}
        {% set col_name = change.keys() | list | first %}
        {% set details = change[col_name] %}
        {% set datatype = details[0] %}
        {% set action = details[1] | upper %}

        {% if action == 'ADD' %}
            {% set sql %}
                ALTER TABLE {{ full_table_name }}
                ADD COLUMN IF NOT EXISTS {{ col_name }} {{ datatype }}
            {% endset %}
            {% do run_query(sql) %}
            {% do result_log.append('Added column: ' ~ col_name) %}

        {% elif action == 'DELETE' %}
            {% if col_name | upper == primary_col or col_name | upper == watermark_col %}
                {% do exceptions.raise_compiler_error(
                    'Cannot DELETE protected column: ' ~ col_name ~
                    ' (Primary: ' ~ primary_col ~ ', Watermark: ' ~ watermark_col ~ ')'
                ) %}
            {% endif %}
            {% set sql %}
                ALTER TABLE {{ full_table_name }}
                DROP COLUMN IF EXISTS {{ col_name }}
            {% endset %}
            {% do run_query(sql) %}
            {% do result_log.append('Deleted column: ' ~ col_name) %}

        {% else %}
            {% do exceptions.raise_compiler_error(
                'Invalid action "' ~ action ~ '" for column ' ~ col_name
            ) %}
        {% endif %}
    {% endfor %}

    {% do log('✅ Table ' ~ full_table_name ~ ' updated successfully.', info=True) %}
    {% for r in result_log %}
        {% do log(r, info=True) %}
    {% endfor %}
{% endmacro %}
