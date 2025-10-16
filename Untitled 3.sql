--practice public is source
--practice default is destination
CREATE TABLE EMPLOYEE(ID INT, NAME VARCHAR(100))

CREATE TABLE EMPLOYEE(ID INT)

SELECT {{compare_table_schemas('PRACTICE', 'PUBLIC', 'EMPLOYEE', 'PRACTICE', 'DEFAULT', 'EMPLOYEE')}}