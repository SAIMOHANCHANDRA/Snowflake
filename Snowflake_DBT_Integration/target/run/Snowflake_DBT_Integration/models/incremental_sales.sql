
  
    

        create or replace transient table MAIN.STAGING.incremental_sales
         as
        (

SELECT 
    1 AS order_id,
    '2025-10-15' AS order_date,
    100 AS amount


select * from incremental_sales
        );
      
  