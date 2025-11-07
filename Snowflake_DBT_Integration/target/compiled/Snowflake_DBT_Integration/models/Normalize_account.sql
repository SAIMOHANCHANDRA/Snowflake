with source_data as (
    select * from (
        values 
            ('Account__c'::string, 'Account_c'::string, 'Account__c_c'::string)
    ) as t(Account__c, Account_c, Account__c_c)
)

select
    
    case
        when Account__c ilike '%__c_c' then regexp_replace(Account__c, '__c_c$', '_c')
        else regexp_replace(Account__c, '(__c|_c)$', '')
    end
 as normalized_name1,
    
    case
        when Account_c ilike '%__c_c' then regexp_replace(Account_c, '__c_c$', '_c')
        else regexp_replace(Account_c, '(__c|_c)$', '')
    end
 as normalized_name2,
    
    case
        when Account__c_c ilike '%__c_c' then regexp_replace(Account__c_c, '__c_c$', '_c')
        else regexp_replace(Account__c_c, '(__c|_c)$', '')
    end
 as normalized_name3
from source_data