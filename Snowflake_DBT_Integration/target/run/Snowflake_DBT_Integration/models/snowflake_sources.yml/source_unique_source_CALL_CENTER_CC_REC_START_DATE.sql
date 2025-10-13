select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    

select
    CC_REC_START_DATE as unique_field,
    count(*) as n_records

from SNOWFLAKE_SAMPLE_DATA.TPCDS_SF100TCL.CALL_CENTER
where CC_REC_START_DATE is not null
group by CC_REC_START_DATE
having count(*) > 1



      
    ) dbt_internal_test