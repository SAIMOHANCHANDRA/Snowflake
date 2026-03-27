
      
  
    

        create or replace transient table MAIN.STAGING_STAGING.snapshot4
         as
        (
    

    select *,
        md5(coalesce(cast(CUSTOMERID as varchar ), '')
         || '|' || coalesce(cast(UPDATED_AT as varchar ), '')
        ) as dbt_scd_id,
        UPDATED_AT as dbt_updated_at,
        UPDATED_AT as dbt_valid_from,
        
  
  coalesce(nullif(UPDATED_AT, UPDATED_AT), to_date('9999-12-31'))
  as dbt_valid_to
from (
        select * from MAIN.STAGING.customer
    ) sbq



        );
      
  
  