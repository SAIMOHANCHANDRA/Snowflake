//select parse_json(''{{ compare_table_schemas("MAIN","PUBLIC","EMPLOYEEDETAILS","MAIN","STAGING","EMPLOYEEDETAILS_INCREMENTAL") }}'') as schema_diff


 
select {{ compare_table_schemas("MAIN","PUBLIC","EMPLOYEEDETAILS","MAIN","STAGING","EMPLOYEE_DETAILS3") }} as schema_diff