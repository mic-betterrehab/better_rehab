@isTest
private class ContactTriggerHandlerTest
{
    @IsTest
    static void contactTriggerTest()
    {
        Id conGeneralRecTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('General').getRecordTypeId();

        Contact con = new Contact();
        con.LastName = 'smith';
        con.RecordTypeId = conGeneralRecTypeId;
        INSERT con;

        con.enrtcr__Preferred_Name__c  = 'bob';
        UPDATE con;

        DELETE con;
    }

    @IsTest
    static void testException()
    {
        CustomException.formatException('error');
    }
}