-- back compat for old kwarg name
  
  begin;
    
        
            
	    
	    
            
        
    

    

    merge into MAIN.STAGING.EmployeeDetails_Incremental as DBT_INTERNAL_DEST
        using MAIN.STAGING.EmployeeDetails_Incremental__dbt_tmp as DBT_INTERNAL_SOURCE
        on ((DBT_INTERNAL_SOURCE.Id = DBT_INTERNAL_DEST.Id))

    
    when matched then update set
        "ID" = DBT_INTERNAL_SOURCE."ID","NAME" = DBT_INTERNAL_SOURCE."NAME","SALARY" = DBT_INTERNAL_SOURCE."SALARY","GENDER" = DBT_INTERNAL_SOURCE."GENDER","CITY" = DBT_INTERNAL_SOURCE."CITY","DEPT" = DBT_INTERNAL_SOURCE."DEPT","HIREDATE" = DBT_INTERNAL_SOURCE."HIREDATE"
    

    when not matched then insert
        ("ID", "NAME", "SALARY", "GENDER", "CITY", "DEPT", "HIREDATE")
    values
        ("ID", "NAME", "SALARY", "GENDER", "CITY", "DEPT", "HIREDATE")

;
    commit;