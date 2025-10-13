
  
    

        create or replace transient table MAIN.STAGING.my_second_dbt_model
         as
        (select *
  from MAIN.STAGING.my_first_dbt_model
  where id = 1
        );
      
  