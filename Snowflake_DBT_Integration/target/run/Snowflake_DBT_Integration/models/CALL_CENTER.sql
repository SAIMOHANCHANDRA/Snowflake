
  
    

        create or replace transient table MAIN.EDW.CALL_CENTER
         as
        (
SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF100TCL.CALL_CENTER
        );
      
  