{{ config(materialized='incremental',
    unique_key='Id'
) }}
SELECT * FROM {{source('source2','EmployeeDetails')}}

{% if is_incremental() %}
    where HIREDATE >= ( select max(HIREDATE) from {{this}} )
{% endif %}

 