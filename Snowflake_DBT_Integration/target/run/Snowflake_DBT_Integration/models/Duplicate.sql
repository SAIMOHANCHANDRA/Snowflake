
  
    

        create or replace transient table MAIN.EDW.Duplicate
         as
        (SELECT * FROM MAIN.EDW.CALL_CENTER
        );
      
  