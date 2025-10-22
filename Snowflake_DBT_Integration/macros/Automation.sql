{% macro generate_all_salesforce_yml(database, schema) %}
{% set tables = run_query(
    "SELECT TABLE_NAME FROM " ~ database ~ ".INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = '" ~ schema ~ "'"
) %}
{% for table in tables.columns[0].values() %}
  {{ log("Generating YAML for " ~ table, info=True) }}
  {{ run_operation('generate_model_yaml', {'model_name': table | lower}) }}
{% endfor %}
{% endmacro %}