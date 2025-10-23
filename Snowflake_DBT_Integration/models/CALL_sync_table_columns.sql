{{ config(
    materialized='view',
    pre_hook = "{{ sync_table_schema('MAIN', 'PUBLIC', 'EMPLOYEEDETAILS', 'MAIN', 'PUBLIC', 'EMPLOYEE_DETAILS4','ID','HIREDATE') }}"
) }}

select current_timestamp() as last_run_date
