
SELECT * FROM MAIN.PUBLIC.EmployeeDetails


    where HIREDATE >= ( select max(HIREDATE) from MAIN.STAGING.EmployeeDetails_Incremental )
