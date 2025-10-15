CREATE OR REPLACE TABLE customer_history (
    CUSTOMERID INT,
    NAME STRING,
    START_DATE DATE,
    END_DATE DATE,
    UPDATED_AT TIMESTAMP
);
 
CREATE OR REPLACE PROCEDURE insert_customers()
RETURNS STRING
LANGUAGE JAVASCRIPT
AS
$$
  var i = 1;
  while (i <= 100) {
    var sql_command = `INSERT INTO customer_history (CUSTOMERID, NAME, START_DATE, END_DATE, UPDATED_AT)
                       VALUES (${i}, 'Customer ${i}', '2025-01-01', NULL, CURRENT_TIMESTAMP())`;
    snowflake.execute({sqlText: sql_command});
    i++;
  }
  return 'Inserted 100 rows';
$$;

CALL insert_customers();

SELECT * FROM customer_history;
INSERT INTO customer_history VALUES (2, 'ABCDEF', '2025-01-01', NULL, CURRENT_TIMESTAMP())
INSERT INTO customer_history VALUES (18, 'Tanuja', '2025-01-01', NULL, CURRENT_TIMESTAMP())
INSERT INTO customer_history VALUES (19, 'Tanuja', '2025-01-01', NULL, CURRENT_TIMESTAMP());
INSERT INTO customer_history VALUES (57, 'Tanuja', '2025-01-01', NULL, CURRENT_TIMESTAMP());

SELECT * FROM MAIN.STAGING.CUSTOMER WHERE CUSTOMERID=57;

