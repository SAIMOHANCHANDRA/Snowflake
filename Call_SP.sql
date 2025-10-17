-- CREATE OR REPLACE TABLE TargetColumnDetails AS
SELECT 
    OBJECT_KEYS(f.value)[0]::STRING AS column_name,
    f2.value[0]::STRING AS datatype,
    UPPER(f2.value[1]::STRING) AS action_type
FROM TABLE(
    FLATTEN(
        INPUT => PARSE_JSON('{
        "target_table": "MAIN.PUBLIC.EMPLOYEEDETAILS_INCREMENTAL", 
          "result": [
            { "AGE": ["NUMBER", "ADD"] },
            { "ADDRESS": ["STRING", "DELETE"] },
            { "HIREDATE": ["TIMESTAMP", "DELETE"] }
          ]
        }'):"result"
    )
) AS f,
TABLE(FLATTEN(INPUT => f.value)) AS f2;




SELECT 
    payload:"target_table"::STRING AS target_table,
    OBJECT_KEYS(f.value)[0]::STRING AS column_name,
    f2.value[0]::STRING AS datatype,
    UPPER(f2.value[1]::STRING) AS action_type
FROM TABLE(
    FLATTEN(
        INPUT => PARSE_JSON('{
        "target_table": "MAIN.PUBLIC.EMPLOYEEDETAILS_INCREMENTAL", 
          "result": [
            { "AGE": ["NUMBER", "ADD"] },
            { "ADDRESS": ["STRING", "DELETE"] },
            { "HIREDATE": ["TIMESTAMP", "DELETE"] }
          ]
        }'):"result"
    )
) AS f,
    TABLE(FLATTEN(INPUT => f.value)) AS f2;
     

WITH data AS (
  SELECT 
    PARSE_JSON('{
      "target_table": "MAIN.PUBLIC.EMPLOYEEDETAILS_INCREMENTAL", 
      "result": [
        { "AGE": ["NUMBER", "ADD"] },
        { "ADDRESS": ["STRING", "DELETE"] },
        { "HIREDATE": ["TIMESTAMP", "DELETE"] }
      ]
    }') AS payload
)
SELECT 
    payload:"target_table"::STRING AS target_table,
    OBJECT_KEYS(f.value)[0]::STRING AS column_name,
    f2.value[0]::STRING AS datatype,
    UPPER(f2.value[1]::STRING) AS action_type
FROM data,
     TABLE(FLATTEN(INPUT => payload:"result")) AS f,
     TABLE(FLATTEN(INPUT => f.value)) AS f2;

        
SELECT 
    PARSE_JSON(ColumnDict):"target_table"::STRING AS target_table,
    OBJECT_KEYS(f.value)[0]::STRING AS column_name,
    f2.value[0]::STRING AS datatype,
    UPPER(f2.value[1]::STRING) AS action_type
FROM TABLE(
        FLATTEN(
            INPUT => PARSE_JSON(ColumnDict):"result"
        )
     ) AS f,
     TABLE(FLATTEN(INPUT => f.value)) AS f2;



CALL MANAGE_TABLE_COLUMNS(
    'ID',
    'HIREDATE', 
    PARSE_JSON('{
        "target_table": "MAIN.PUBLIC.EMPLOYEEDETAILS_INCREMENTAL", 
        "result": [
            { "AGE": ["NUMBER", "ADD"] },
            { "ADDRESS": ["STRING", "DELETE"] },
            { "HIREDATE": ["TIMESTAMP", "DELETE"] }
        ]
    }')
);





CREATE TABLE EMPLOYEE_DETAILS3 AS SELECT * FROM EMPLOYEEDETAILS;


SELECT * FROM  EMPLOYEE_DETAILS3;

DESC TABLE EMPLOYEE_DETAILS3;

SELECT * FROM EMPLOYEEDETAILS;

ALTER TABLE EMPLOYEEDETAILS
DROP COLUMN CONTACT;


-------
CREATE TABLE EMPLOYEEDETAILS AS SELECT * FROM EMPLOYEE_DETAILS4;

SELECT * FROM EMPLOYEE_DETAILS4;

SELECT * FROM MAIN.PUBLIC.EMPLOYEEDETAILS;

DESC TABLE EMPLOYEE_DETAILS4;


DROP TABLE MAIN.PUBLIC.EMPLOYEEDETAILS;

ALTER TABLE EMPLOYEEDETAILS
ADD COLUMN CONTACT NUMBER;

ALTER TABLE EMPLOYEE_DETAILS4
DROP COLUMN CONTACT;

ALTER TABLE EMPLOYEEDETAILS
DROP COLUMN HIREDATE;--HIREDATE;

ALTER TABLE EMPLOYEEDETAILS
DROP COLUMN GENDER;
 