
  
    

        create or replace transient table MAIN.STAGING.Duplicate
         as
        (SELECT * FROM MAIN.STAGING.CALL_CENTER
        );
      
  