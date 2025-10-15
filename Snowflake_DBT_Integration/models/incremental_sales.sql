{{ config(
    materialized='incremental',
    unique_key='order_id'
) }}

SELECT 
    1 AS order_id,
    '2025-10-15' AS order_date,
    100 AS amount

{% if is_incremental() %}
UNION ALL
SELECT 
    2 AS order_id,
    '2025-10-16' AS order_date,
    200 AS amount
{% endif %}
