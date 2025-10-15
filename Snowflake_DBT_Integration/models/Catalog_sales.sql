{{ config(materialized='table') }}
select * from {{ source('source','CATALOG_SALES') }};



