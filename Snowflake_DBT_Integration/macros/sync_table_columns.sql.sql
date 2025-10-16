{% macro table_columns_sync(primary_col, watermark_col, source_db, source_schema, source_table, target_db, target_schema, target_table) %}
    {% set schema_diff_json %}
    {
        "target_table": "{{ target_db }}.{{ target_schema }}.{{ target_table }}",
        "result": [
            { "CONTACT": ["NUMBER", "ADD"] },
           { "ADDRESS": ["STRING", "DELETE"] },
           { "HIREDATE": ["TIMESTAMP", "DELETE"] }
        ]
    }
    {% endset %}
 
    {% set call_stmt %}
    CALL MANAGE_TABLE_COLUMNS(
        '{{ primary_col }}',
        '{{ watermark_col }}',
        PARSE_JSON('{{ schema_diff_json | replace("'", "''") | trim }}')
    );
    {% endset %}
 
    {% do run_query(call_stmt) %}
 
{% endmacro %