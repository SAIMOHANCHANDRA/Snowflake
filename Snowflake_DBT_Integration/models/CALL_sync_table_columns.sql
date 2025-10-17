{{ config(
    materialized='view',
    pre_hook = "{{ table_columns_sync('ID', 'HIREDATE', 'MAIN', 'PUBLIC', 'EMPLOYEEDETAILS', 'MAIN', 'PUBLIC', 'EMPLOYEE_DETAILS4') }}"
) }}

select current_timestamp() as last_run_date
