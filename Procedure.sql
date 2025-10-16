CREATE OR REPLACE PROCEDURE MANAGE_TABLE_COLUMNS3(
    PrimaryColumn_name STRING,
    WatermarkColumn_name STRING,
    ColumnDict VARIANT
)
RETURNS STRING
LANGUAGE SQL
AS
--$$
DECLARE
    v_full_table_name STRING;
    v_primary_col STRING := UPPER(PrimaryColumn_name);
    v_watermark_col STRING := UPPER(WatermarkColumn_name);
    v_sql STRING;
    v_col STRING;
    v_datatype STRING;
    v_action STRING;
    v_result STRING := '';
    i NUMBER;

    v_full_table_name := UPPER(:ColumnDict:"target_table"::STRING);
BEGIN
    FOR i IN 0 TO 100 DO
            SELECT 
                OBJECT_KEYS(f.value)[0]::STRING AS column_name,
                f2.value[0]::STRING AS datatype,
                UPPER(f2.value[1]::STRING) AS action_type
            FROM TABLE(FLATTEN(INPUT => :ColumnDict:"result")) AS f,
             TABLE(FLATTEN(INPUT => f.value)) AS f2
            v_col := column_name;
            v_datatype := datatype;
            v_action := action_type;
    
            -- ADD operation
            IF (v_action = 'ADD') THEN
                v_sql := 'ALTER TABLE ' || v_full_table_name || 
                         ' ADD COLUMN IF NOT EXISTS ' || v_col || ' ' || v_datatype;
                EXECUTE IMMEDIATE v_sql;
                v_result := v_result || CHR(10) || 'Added column: ' || v_col;
    
            -- DELETE operation
            ELSEIF (v_action = 'DELETE') THEN
                IF (UPPER(v_col) IN (v_primary_col, v_watermark_col) ) THEN
                    --RAISE('Error: Cannot DELETE protected column ' || v_col);
                    LET VALIDATION_ERROR EXCEPTION(-20001, 'Cannot DELETE protected column');
                    RAISE VALIDATION_ERROR;
                END IF;
    
                v_sql := 'ALTER TABLE ' || v_full_table_name || 
                         ' DROP COLUMN IF EXISTS ' || v_col || '';
                EXECUTE IMMEDIATE v_sql;
                v_result := v_result || CHR(10) || 'Deleted column: ' || v_col;
    
            -- Invalid operation
            ELSE
                -- RAISE_ERROR('Invalid operation "' || v_action || '" for column ' || v_col);
                LET VALIDATION_ERROR EXCEPTION(-20002, 'Invalid operation');
                RAISE VALIDATION_ERROR;
            END IF;
    END FOR;

    RETURN 'Table ' || v_full_table_name || ' updated successfully.' || CHR(10) || v_result;
END;
--$$; 