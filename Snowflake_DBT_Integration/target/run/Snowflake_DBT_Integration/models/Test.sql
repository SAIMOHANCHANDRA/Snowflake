
  
    

        create or replace transient table MAIN.STAGING.Test
         as
        (SELECT {'target_table': '{{ tgt_db }}.{{ tgt_schema }}.{{ tgt_table }}', 'result': Markup('["{\\"NAME\\":[\\"TEXT\\",\\"ADDED\\"]}"]')}
        );
      
  