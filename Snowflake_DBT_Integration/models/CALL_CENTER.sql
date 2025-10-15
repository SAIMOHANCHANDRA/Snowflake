{{
    config(
    tags=['tag1','tag2','tag3']
  ) 
}}
SELECT * FROM {{source('source','CALL_CENTER')}}