CALL MANAGE_TABLE_COLUMNS3(
    'ID',
    'HIREDATE',
    PARSE_JSON('{
        "target_table": "MAIN.PUBLIC.EMP_DETAILS",
        "result": [
            { "AGE12": ["NUMBER", "ADD"] },
        ]
    }')
);