public with sharing class ContactTriggerHandler implements ITrigger, Database.Stateful
{
    List<Contact> contactsToAdd = new List<Contact>();
    List<Account> accountsToAdd = new List<Account>();
    Id accHouseholdRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();

    public void bulkBefore()
    {
    }

    public void bulkAfter()
    {
    }

    public void beforeInsert(SObject so)
    {
        if(so.get(Contact.AccountId) == null && so.get(Contact.Record_Type_Name__c ) == 'General')
        {
            contactsToAdd.add((Contact)so);
        }
    }

    public void beforeUpdate(SObject oldSo, SObject so)
    {
    }

    public void beforeDelete(SObject so)
    {
    }

    public void afterInsert(SObject so)
    {
    }

    public void afterUpdate(SObject oldSo, SObject so)
    {
    }

    public void afterDelete(SObject so)
    {
    }

    public void andFinally()
    {
        if(contactsToAdd.size() > 0)
        {
            Map<String,Contact> contactsByNameKeys = new Map<String,Contact>();
            //Create Account For Each Contact
            for (Contact con : contactsToAdd)
            {
                String accName = con.LastName + ' Household';
                String key = accName + con.enrtcr__External_Client_ID__c;
                Account acc = new Account();
                acc.Name = accName;
                acc.RecordTypeId = accHouseholdRecTypeId;
                acc.SicDesc = key;
                accountsToAdd.add(acc);
                contactsByNameKeys.put(key,con);
            }
            INSERT accountsToAdd;
            for (Account acc : accountsToAdd)
            {
                //Put Account Id's on Contacts
                if (contactsByNameKeys.containsKey(acc.SicDesc))
                {
                    contactsByNameKeys.get(acc.SicDesc).accountId = acc.Id;
                }
            }
            contactsToAdd = new List<Contact>();
        }
    }
}