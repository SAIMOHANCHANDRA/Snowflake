{% snapshot EmployeeDetails_SCD2 %}

{{
    config(
      target_schema='PUBLIC',
      unique_key='Id',
      strategy='timestamp',
      updated_at='HIREDATE',
      invalidate_hard_deletes = true
    )
}}
 
SELECT * FROM  {{ source('source2','EmployeeDetails') }} 

{% endsnapshot %}
 