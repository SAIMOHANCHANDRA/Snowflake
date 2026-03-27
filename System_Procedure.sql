CREATE OR REPLACE PROCEDURE RETURN_INPUT_PARAMS_SQL(
    Variable1 STRING,
    Variable2 STRING,
    Operations STRING -- comma-separated operations
)
RETURNS STRING
LANGUAGE SQL
AS
-- $$
DECLARE
    v1 NUMBER;
    v2 NUMBER;
    result_string STRING := '';
    temp_result STRING;
BEGIN
    v1 := TO_NUMBER(Variable1);
    v2 := TO_NUMBER(Variable2);

    -- Loop over each operation using SPLIT + FLATTEN
    FOR op_row IN (
        SELECT TRIM(VALUE::STRING) AS OP
        FROM TABLE(FLATTEN(INPUT => SPLIT(Operations, ',')))
    )
    DO
        IF (op_row."OP" = 'ADD') THEN
            temp_result := TO_VARCHAR(v1 + v2);
        ELSEIF (op_row."OP" = 'SUBTRACT') THEN
            temp_result := TO_VARCHAR(v1 - v2);
        ELSEIF (op_row."OP" = 'MULTIPLICATION') THEN
            temp_result := TO_VARCHAR(v1 * v2);
        ELSEIF (op_row."OP" = 'DIVISION') THEN
            IF (v2 != 0) THEN
                temp_result := TO_VARCHAR(v1 / v2);
            ELSE
                temp_result := 'DIV_BY_ZERO';
            END IF;
        ELSE
            temp_result := 'NONE';
        END IF;

        result_string := result_string || v1 || ' ' || op_row."OP" || ' ' || v2 || ' => ' || temp_result || ' , ';
    END FOR;

    -- Remove trailing comma and space
    result_string := RTRIM(result_string, ' ,');

    RETURN result_string;
END;
-- $$;



CALL RETURN_INPUT_PARAMS_SQL('1','2','ADD,SUBTRACT,MULTIPLICATION,DIVISION');