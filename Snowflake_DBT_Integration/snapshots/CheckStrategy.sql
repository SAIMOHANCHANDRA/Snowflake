{% snapshot CheckStrategy %}

{{ config(
      database='MAIN',
      target_schema='STAGING',
      strategy='check',
      unique_key= 'CUSTOMERID',
      check_cols= ['CUSTOMERID','NAME'],
      invalidate_hard_deletes = True
    )
}}
 
SELECT * FROM  {{ ref('customer') }} 

{% endsnapshot %}
 