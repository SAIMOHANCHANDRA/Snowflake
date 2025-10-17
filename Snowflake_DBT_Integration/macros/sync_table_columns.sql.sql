{% macro table_columns_sync(primary_col, watermark_col, source_db, source_schema, source_table, target_db, target_schema, target_table) %}

    {% set schema_diff_json = compare_table_schemas(source_db, source_schema, source_table, target_db, target_schema, target_table) %}
    {% set json_str = schema_diff_json | tojson %}

    {% set call_stmt %}
        CALL MANAGE_TABLE_COLUMNS(
            '{{ primary_col }}',
            '{{ watermark_col }}',
            PARSE_JSON('{{ json_str | replace("'", "''") }}')
        );
    {% endset %}

    {% do log("Executing MANAGE_TABLE_COLUMNS...", info=True) %}
    {% do run_query(call_stmt) %}
    {% do log("Procedure executed successfully.", info=True) %}

{% endmacro %}
