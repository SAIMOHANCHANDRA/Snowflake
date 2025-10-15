
CREATE OR REPLACE TABLE customer_history (
    CUSTOMERID INT,
    NAME STRING,
    START_DATE DATE,
    END_DATE DATE,
    UPDATED_AT TIMESTAMP
);




DECLARE
    i INT = 1;  
BEGIN
    
    WHILE i <= 100 DO
        INSERT INTO customer_history (CUSTOMERID, NAME, START_DATE, END_DATE, UPDATED_AT)
        VALUES (i, 'Customer ' || i, '2025-01-01', NULL, CURRENT_TIMESTAMP());
        LET i = i + 1;  
    END WHILE;
END;

