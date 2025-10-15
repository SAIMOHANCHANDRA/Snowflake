
        
        SELECT COLUMN_NAME
        FROM {{ database }}.INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = '{{ schema }}'
          AND TABLE_NAME = '{{ table_name }}'
        ORDER BY ORDINAL_POSITION
