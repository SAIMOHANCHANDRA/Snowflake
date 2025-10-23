{% macro sync_table_schema(source_database, source_schema, source_table, target_database, target_schema, target_table, primary_column, watermark_column) %}

{%- set get_source_columns_query -%}
    SELECT 
        CASE WHEN ENDSWITH(COLUMN_NAME, '_c__c') THEN UPPER(REPLACE(COLUMN_NAME, '_c__c', '__c'))
            WHEN ENDSWITH(COLUMN_NAME, '__c') THEN UPPER(REPLACE(COLUMN_NAME, '__c', ''))
            ELSE UPPER(COLUMN_NAME)
        END AS COLUMN_NAME,
        ORDINAL_POSITION,
        DATA_TYPE,
        CHARACTER_MAXIMUM_LENGTH,
        NUMERIC_PRECISION,
        NUMERIC_SCALE,
        IS_NULLABLE,
        COLUMN_DEFAULT
    FROM {{ source_database }}.INFORMATION_SCHEMA.COLUMNS
    WHERE UPPER(TABLE_SCHEMA) = UPPER('{{ source_schema }}')
      AND UPPER(TABLE_NAME) = UPPER('{{ source_table }}')
    ORDER BY ORDINAL_POSITION
{%- endset -%}

{%- set get_target_columns_query -%}
    SELECT 
        UPPER(COLUMN_NAME) AS COLUMN_NAME,
        ORDINAL_POSITION,
        DATA_TYPE,
        CHARACTER_MAXIMUM_LENGTH,
        NUMERIC_PRECISION,
        NUMERIC_SCALE,
        IS_NULLABLE,
        COLUMN_DEFAULT
    FROM {{ target_database }}.INFORMATION_SCHEMA.COLUMNS
    WHERE UPPER(TABLE_SCHEMA) = UPPER('{{ target_schema }}')
      AND UPPER(TABLE_NAME) = UPPER('{{ target_table }}')
      AND UPPER(COLUMN_NAME) NOT IN ('DBT_UPDATED_AT','DBT_RUN_ID')
    ORDER BY ORDINAL_POSITION
{%- endset -%}

{%- set source_columns = run_query(get_source_columns_query) -%}
{%- set target_columns = run_query(get_target_columns_query) -%}

{%- if execute -%}
    {%- set source_dict = {} -%}
    {%- set target_dict = {} -%}
    {%- set protected_columns = [primary_column|upper, watermark_column|upper] -%}

    -- Define synonymous data types
    {%- set synonymous_types = {
        'STRING': ['VARCHAR', 'TEXT', 'NVARCHAR', 'CHAR', 'NCHAR'],
        'VARCHAR': ['STRING', 'TEXT', 'NVARCHAR', 'CHAR', 'NCHAR'],
        'TEXT': ['STRING', 'VARCHAR', 'NVARCHAR', 'CHAR', 'NCHAR'],
        'NVARCHAR': ['STRING', 'VARCHAR', 'TEXT', 'CHAR', 'NCHAR'],
        'CHAR': ['STRING', 'VARCHAR', 'TEXT', 'NVARCHAR', 'NCHAR'],
        'NCHAR': ['STRING', 'VARCHAR', 'TEXT', 'NVARCHAR', 'CHAR'],
        'NUMBER': ['DECIMAL', 'NUMERIC', 'INT', 'INTEGER', 'BIGINT', 'SMALLINT', 'TINYINT'],
        'DECIMAL': ['NUMBER', 'NUMERIC', 'INT', 'INTEGER', 'BIGINT', 'SMALLINT', 'TINYINT'],
        'NUMERIC': ['NUMBER', 'DECIMAL', 'INT', 'INTEGER', 'BIGINT', 'SMALLINT', 'TINYINT'],
        'INT': ['NUMBER', 'DECIMAL', 'NUMERIC', 'INTEGER', 'BIGINT', 'SMALLINT', 'TINYINT'],
        'INTEGER': ['NUMBER', 'DECIMAL', 'NUMERIC', 'INT', 'BIGINT', 'SMALLINT', 'TINYINT'],
        'BIGINT': ['NUMBER', 'DECIMAL', 'NUMERIC', 'INT', 'INTEGER', 'SMALLINT', 'TINYINT'],
        'SMALLINT': ['NUMBER', 'DECIMAL', 'NUMERIC', 'INT', 'INTEGER', 'BIGINT', 'TINYINT'],
        'TINYINT': ['NUMBER', 'DECIMAL', 'NUMERIC', 'INT', 'INTEGER', 'BIGINT', 'SMALLINT'],
        'FLOAT': ['FLOAT4', 'FLOAT8', 'DOUBLE', 'DOUBLE PRECISION', 'REAL'],
        'FLOAT4': ['FLOAT', 'FLOAT8', 'DOUBLE', 'DOUBLE PRECISION', 'REAL'],
        'FLOAT8': ['FLOAT', 'FLOAT4', 'DOUBLE', 'DOUBLE PRECISION', 'REAL'],
        'DOUBLE': ['FLOAT', 'FLOAT4', 'FLOAT8', 'DOUBLE PRECISION', 'REAL'],
        'DOUBLE PRECISION': ['FLOAT', 'FLOAT4', 'FLOAT8', 'DOUBLE', 'REAL'],
        'REAL': ['FLOAT', 'FLOAT4', 'FLOAT8', 'DOUBLE', 'DOUBLE PRECISION']
    } -%}

    -- Build source columns dictionary
    {%- for row in source_columns -%}
        {%- set col_name = row[0] -%}
        {%- set _ = source_dict.update({
            col_name: {
                'ordinal_position': row[1],
                'data_type': row[2],
                'char_max_length': row[3],
                'numeric_precision': row[4],
                'numeric_scale': row[5],
                'is_nullable': row[6],
                'column_default': row[7]
            }
        }) -%}
    {%- endfor -%}

    -- Build target columns dictionary
    {%- for row in target_columns -%}
        {%- set col_name = row[0] -%}
        {%- set _ = target_dict.update({
            col_name: {
                'ordinal_position': row[1],
                'data_type': row[2],
                'char_max_length': row[3],
                'numeric_precision': row[4],
                'numeric_scale': row[5],
                'is_nullable': row[6],
                'column_default': row[7]
            }
        }) -%}
    {%- endfor -%}

    {%- set alter_statements = [] -%}
    {%- set errors = [] -%}
    {%- set warnings = [] -%}
    {%- set skipped_deletes = [] -%}

    -- Check for columns to add or modify
    {%- for col_name, col_info in source_dict.items() -%}
        {%- if col_name not in target_dict -%}
            -- New column to add (NO RESTRICTIONS - add all columns including if named same as primary/watermark)
            {%- set data_type_def = col_info.data_type -%}
            {%- if col_info.data_type in ('VARCHAR', 'CHAR', 'NVARCHAR', 'NCHAR', 'STRING', 'TEXT') and col_info.char_max_length -%}
                {%- set data_type_def = col_info.data_type ~ '(' ~ col_info.char_max_length ~ ')' -%}
            {%- elif col_info.data_type in ('DECIMAL', 'NUMERIC', 'NUMBER') and col_info.numeric_precision -%}
                {%- if col_info.numeric_scale -%}
                    {%- set data_type_def = col_info.data_type ~ '(' ~ col_info.numeric_precision ~ ',' ~ col_info.numeric_scale ~ ')' -%}
                {%- else -%}
                    {%- set data_type_def = col_info.data_type ~ '(' ~ col_info.numeric_precision ~ ')' -%}
                {%- endif -%}
            {%- endif -%}

            {%- set nullable = 'NULL' if col_info.is_nullable == 'YES' else 'NOT NULL' -%}
            
            -- Build ADD COLUMN statement with DEFAULT if present
            {%- set add_stmt = 'ALTER TABLE ' ~ target_database ~ '.' ~ target_schema ~ '.' ~ target_table ~ 
                               ' ADD COLUMN ' ~ col_name ~ ' ' ~ data_type_def -%}
            
            {%- if col_info.column_default is not none -%}
                {%- set add_stmt = add_stmt ~ ' DEFAULT ' ~ col_info.column_default -%}
            {%- endif -%}
            
            {%- set add_stmt = add_stmt ~ ' ' ~ nullable -%}
            {%- set _ = alter_statements.append(add_stmt) -%}

        {%- else -%}
            -- Column exists - check for changes (MODIFY)
            {%- set target_info = target_dict[col_name] -%}
            {%- set type_changed = false -%}
            {%- set default_changed = false -%}
            {%- set nullable_changed = false -%}
            {%- set change_allowed = true -%}
            {%- set change_reason = '' -%}

            {%- set source_type = col_info.data_type -%}
            {%- set target_type = target_info.data_type -%}
            {%- set source_char_len = col_info.char_max_length -%}
            {%- set target_char_len = target_info.char_max_length -%}
            {%- set source_precision = col_info.numeric_precision -%}
            {%- set target_precision = target_info.numeric_precision -%}
            {%- set source_scale = col_info.numeric_scale -%}
            {%- set target_scale = target_info.numeric_scale -%}
            {%- set source_default = col_info.column_default -%}
            {%- set target_default = target_info.column_default -%}
            {%- set source_nullable = col_info.is_nullable -%}
            {%- set target_nullable = target_info.is_nullable -%}

            -- Check if type actually changed
            {%- if source_type != target_type or 
                   source_char_len != target_char_len or 
                   source_precision != target_precision or 
                   source_scale != target_scale -%}
                {%- set type_changed = true -%}
            {%- endif -%}

            -- Check if default changed
            {%- if source_default != target_default -%}
                {%- set default_changed = true -%}
            {%- endif -%}

            -- Check if nullability changed
            {%- if source_nullable != target_nullable -%}
                {%- set nullable_changed = true -%}
            {%- endif -%}

            {%- if type_changed -%}
                -- Check if this is a protected column (ONLY FOR TYPE MODIFY)
                {%- if col_name in protected_columns -%}
                    {%- set error_msg = 'ERROR: Cannot modify data type of protected column "' ~ col_name ~ '" (Primary: ' ~ primary_column|upper ~ ', Watermark: ' ~ watermark_column|upper ~ ')' -%}
                    {%- set _ = errors.append(error_msg) -%}
                    {%- set change_allowed = false -%}
                {%- else -%}
                    -- Validate the data type change
                    
                    -- Rule 1: Check if types are synonymous
                    {%- set is_synonymous = false -%}
                    {%- if source_type in synonymous_types -%}
                        {%- if target_type in synonymous_types[source_type] -%}
                            {%- set is_synonymous = true -%}
                        {%- endif -%}
                    {%- endif -%}

                    -- Rule 2: Text string columns
                    {%- if source_type in ('VARCHAR', 'CHAR', 'NVARCHAR', 'NCHAR', 'STRING', 'TEXT') and 
                           target_type in ('VARCHAR', 'CHAR', 'NVARCHAR', 'NCHAR', 'STRING', 'TEXT') -%}
                        
                        {%- if source_char_len and target_char_len -%}
                            {%- if source_char_len|int < target_char_len|int -%}
                                {%- set change_allowed = false -%}
                                {%- set change_reason = 'UNSUPPORTED: Cannot decrease text string length from ' ~ target_char_len ~ ' to ' ~ source_char_len -%}
                            {%- elif source_char_len|int > target_char_len|int -%}
                                {%- set change_allowed = true -%}
                                {%- set change_reason = 'SUPPORTED: Increasing text string length from ' ~ target_char_len ~ ' to ' ~ source_char_len -%}
                            {%- elif is_synonymous -%}
                                {%- set change_allowed = true -%}
                                {%- set change_reason = 'SUPPORTED: Synonymous type change from ' ~ target_type ~ ' to ' ~ source_type -%}
                            {%- endif -%}
                        {%- elif is_synonymous -%}
                            {%- set change_allowed = true -%}
                            {%- set change_reason = 'SUPPORTED: Synonymous type change from ' ~ target_type ~ ' to ' ~ source_type -%}
                        {%- endif -%}

                    -- Rule 3: Binary string columns
                    {%- elif source_type in ('BINARY', 'VARBINARY') and target_type in ('BINARY', 'VARBINARY') -%}
                        {%- set change_allowed = false -%}
                        {%- set change_reason = 'UNSUPPORTED: Cannot change binary string column length (from ' ~ target_type ~ ' to ' ~ source_type ~ ')' -%}

                    -- Rule 4: Numeric columns (NUMBER, DECIMAL, NUMERIC)
                    {%- elif source_type in ('NUMBER', 'DECIMAL', 'NUMERIC') and 
                             target_type in ('NUMBER', 'DECIMAL', 'NUMERIC') -%}
                        
                        {%- if source_precision and target_precision -%}
                            -- Check scale change (UNSUPPORTED)
                            {%- if source_scale != target_scale -%}
                                {%- set change_allowed = false -%}
                                {%- set change_reason = 'UNSUPPORTED: Cannot change scale of number column (from ' ~ target_precision ~ ',' ~ target_scale ~ ' to ' ~ source_precision ~ ',' ~ source_scale ~ ')' -%}
                            
                            -- Check precision increase (SUPPORTED)
                            {%- elif source_precision|int > target_precision|int -%}
                                {%- set change_allowed = true -%}
                                {%- set change_reason = 'SUPPORTED: Increasing precision from ' ~ target_precision ~ ',' ~ target_scale ~ ' to ' ~ source_precision ~ ',' ~ source_scale -%}
                            
                            -- Check precision decrease (SUPPORTED with warning)
                            {%- elif source_precision|int < target_precision|int -%}
                                {%- set change_allowed = true -%}
                                {%- set change_reason = 'SUPPORTED: Decreasing precision from ' ~ target_precision ~ ',' ~ target_scale ~ ' to ' ~ source_precision ~ ',' ~ source_scale ~ ' (WARNING: May impact Time Travel if new precision insufficient)' -%}
                                {%- set _ = warnings.append('WARNING: Column "' ~ col_name ~ '" precision decrease may impact Time Travel') -%}
                            
                            -- Same precision (synonymous type)
                            {%- elif is_synonymous -%}
                                {%- set change_allowed = true -%}
                                {%- set change_reason = 'SUPPORTED: Synonymous type change from ' ~ target_type ~ ' to ' ~ source_type -%}
                            {%- endif -%}
                        {%- elif is_synonymous -%}
                            {%- set change_allowed = true -%}
                            {%- set change_reason = 'SUPPORTED: Synonymous type change from ' ~ target_type ~ ' to ' ~ source_type -%}
                        {%- endif -%}

                    -- Rule 5: Different data types (UNSUPPORTED)
                    {%- elif source_type != target_type and not is_synonymous -%}
                        {%- set change_allowed = false -%}
                        {%- set change_reason = 'UNSUPPORTED: Cannot change column data type from ' ~ target_type ~ ' to ' ~ source_type ~ ' (different types)' -%}
                    
                    {%- endif -%}

                    -- Apply the change or log error
                    {%- if not change_allowed -%}
                        {%- set error_msg = 'ERROR: Column "' ~ col_name ~ '" - ' ~ change_reason -%}
                        {%- set _ = errors.append(error_msg) -%}
                    {%- else -%}
                        -- Build the ALTER statement
                        {%- set data_type_def = source_type -%}
                        {%- if source_type in ('VARCHAR', 'CHAR', 'NVARCHAR', 'NCHAR', 'STRING', 'TEXT') and source_char_len -%}
                            {%- set data_type_def = source_type ~ '(' ~ source_char_len ~ ')' -%}
                        {%- elif source_type in ('DECIMAL', 'NUMERIC', 'NUMBER') and source_precision -%}
                            {%- if source_scale -%}
                                {%- set data_type_def = source_type ~ '(' ~ source_precision ~ ',' ~ source_scale ~ ')' -%}
                            {%- else -%}
                                {%- set data_type_def = source_type ~ '(' ~ source_precision ~ ')' -%}
                            {%- endif -%}
                        {%- endif -%}

                        {%- set alter_stmt = 'ALTER TABLE ' ~ target_database ~ '.' ~ target_schema ~ '.' ~ target_table ~ 
                                             ' ALTER COLUMN ' ~ col_name ~ ' SET DATA TYPE ' ~ data_type_def -%}
                        {%- set _ = alter_statements.append(alter_stmt) -%}
                        
                        {%- if change_reason -%}
                            {{ log("  → " ~ change_reason, info=True) }}
                        {%- endif -%}
                    {%- endif -%}

                {%- endif -%}
            {%- endif -%}

            -- Handle DEFAULT value changes (separate from type changes)
            {%- if default_changed and col_name not in protected_columns -%}
                {%- if source_default is none -%}
                    -- Drop default
                    {%- set default_stmt = 'ALTER TABLE ' ~ target_database ~ '.' ~ target_schema ~ '.' ~ target_table ~ 
                                          ' ALTER COLUMN ' ~ col_name ~ ' DROP DEFAULT' -%}
                    {%- set _ = alter_statements.append(default_stmt) -%}
                    {{ log("  → DEFAULT: Dropping default for column " ~ col_name, info=True) }}
                {%- else -%}
                    -- Set/Change default
                    {%- set default_stmt = 'ALTER TABLE ' ~ target_database ~ '.' ~ target_schema ~ '.' ~ target_table ~ 
                                          ' ALTER COLUMN ' ~ col_name ~ ' SET DEFAULT ' ~ source_default -%}
                    {%- set _ = alter_statements.append(default_stmt) -%}
                    {{ log("  → DEFAULT: Setting default for column " ~ col_name ~ " to " ~ source_default, info=True) }}
                {%- endif -%}
            {%- endif -%}

            -- Handle NULLABILITY changes (separate from type and default changes)
            {%- if nullable_changed and col_name not in protected_columns -%}
                {%- if source_nullable == 'YES' -%}
                    -- Change to NULL (drop NOT NULL constraint)
                    {%- set nullable_stmt = 'ALTER TABLE ' ~ target_database ~ '.' ~ target_schema ~ '.' ~ target_table ~ 
                                           ' ALTER COLUMN ' ~ col_name ~ ' DROP NOT NULL' -%}
                    {%- set _ = alter_statements.append(nullable_stmt) -%}
                    {{ log("  → NULLABILITY: Changing column " ~ col_name ~ " from NOT NULL to NULL", info=True) }}
                {%- else -%}
                    -- Change to NOT NULL (set NOT NULL constraint)
                    {%- set nullable_stmt = 'ALTER TABLE ' ~ target_database ~ '.' ~ target_schema ~ '.' ~ target_table ~ 
                                           ' ALTER COLUMN ' ~ col_name ~ ' SET NOT NULL' -%}
                    {%- set _ = alter_statements.append(nullable_stmt) -%}
                    {{ log("  → NULLABILITY: Changing column " ~ col_name ~ " from NULL to NOT NULL", info=True) }}
                {%- endif -%}
            {%- endif -%}

        {%- endif -%}
    {%- endfor -%}

    -- Check for columns to drop (ONLY BLOCK PRIMARY/WATERMARK, DELETE OTHERS)
    {%- for col_name in target_dict.keys() -%}
        {%- if col_name not in source_dict -%}
            -- Check if this is a protected column
            {%- if col_name in protected_columns -%}
                {%- set skip_msg = 'SKIPPED: Cannot drop protected column "' ~ col_name ~ '" (Primary: ' ~ primary_column|upper ~ ', Watermark: ' ~ watermark_column|upper ~ ')' -%}
                {%- set _ = skipped_deletes.append(skip_msg) -%}
            {%- else -%}
                -- Non-protected column - proceed with drop
                {%- set drop_stmt = 'ALTER TABLE ' ~ target_database ~ '.' ~ target_schema ~ '.' ~ target_table ~ 
                                   ' DROP COLUMN ' ~ col_name -%}
                {%- set _ = alter_statements.append(drop_stmt) -%}
            {%- endif -%}
        {%- endif -%}
    {%- endfor -%}

    -- Display skipped deletes (informational, not errors)
    {%- if skipped_deletes|length > 0 -%}
        {{ log("=" * 80, info=True) }}
        {{ log("PROTECTED COLUMNS - DELETE OPERATIONS SKIPPED", info=True) }}
        {{ log("=" * 80, info=True) }}
        {%- for skip_msg in skipped_deletes -%}
            {{ log(skip_msg, info=True) }}
        {%- endfor -%}
        {{ log("=" * 80, info=True) }}
    {%- endif -%}

    -- Display warnings
    {%- if warnings|length > 0 -%}
        {{ log("=" * 80, info=True) }}
        {{ log("WARNINGS", info=True) }}
        {{ log("=" * 80, info=True) }}
        {%- for warning in warnings -%}
            {{ log(warning, info=True) }}
        {%- endfor -%}
        {{ log("=" * 80, info=True) }}
    {%- endif -%}

    -- Check for errors (ONLY MODIFY operations on protected columns and unsupported type changes)
    {%- if errors|length > 0 -%}
        {{ log("=" * 80, info=True) }}
        {{ log("SCHEMA SYNC FAILED - VALIDATION ERRORS DETECTED", info=True) }}
        {{ log("=" * 80, info=True) }}
        {%- for error in errors -%}
            {{ log(error, info=True) }}
        {%- endfor -%}
        {{ log("=" * 80, info=True) }}
        {{ exceptions.raise_compiler_error("Cannot proceed: Schema validation failed. See errors above.") }}
    {%- endif -%}

    -- Execute all alter statements
    {%- if alter_statements|length > 0 -%}
        {{ log("Schema sync required for " ~ target_database ~ "." ~ target_schema ~ "." ~ target_table, info=True) }}
        {{ log("Protected columns: " ~ protected_columns|join(', '), info=True) }}
        {%- for stmt in alter_statements -%}
            {{ log("Executing: " ~ stmt, info=True) }}
            {%- do run_query(stmt) -%}
        {%- endfor -%}
        {{ log("Schema sync completed successfully!", info=True) }}
    {%- else -%}
        {{ log("No schema changes detected for " ~ target_database ~ "." ~ target_schema ~ "." ~ target_table, info=True) }}
    {%- endif -%}
    {{ return("select 'Schema sync completed successfully!'") }}
{%- endif -%}

{% endmacro %}

