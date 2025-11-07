with source_data as (
    select * from (
        values 
            ('Account__c'::string, 'Account_c'::string, 'Account__c_c'::string)
    ) as t(Account__c, Account_c, Account__c_c)
)

select
    {{ normalize_sf_name("Account__c") }} as normalized_name1,
    {{ normalize_sf_name("Account_c") }} as normalized_name2,
    {{ normalize_sf_name("Account__c_c") }} as normalized_name3
from source_data
