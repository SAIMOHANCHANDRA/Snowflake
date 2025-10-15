
  
    

        create or replace transient table MAIN.STAGING.my_first_dbt_model
         as
        (

  with source_data as (
      select 1 as id
      union all
      select null as id
  )

  select *
  from source_data
        );
      
  