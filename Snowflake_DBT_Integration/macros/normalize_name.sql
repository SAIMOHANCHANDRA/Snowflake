{% macro normalize_sf_name(column_name) %}
    case
        when {{ column_name }} ilike '%__c_c' then regexp_replace({{ column_name }}, '__c_c$', '_c')
        else regexp_replace({{ column_name }}, '(__c|_c)$', '')
    end
{% endmacro %}
