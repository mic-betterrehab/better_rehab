/**
 * Created by me on 17/07/2019.
 */

@IsTest
private class SessionAppointmentTest
{
    @IsTest
    static void testBehavior()
    {
        Contact testContact = new Contact(
                MobilePhone = '0400000000',
                LastName = 'TestName',
                RecordTypeId = Contact.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Client').getRecordTypeId()
        );
        insert testContact;

        Contact testWorker = new Contact(
                MobilePhone = '0500000000',
                LastName = 'TestWorker',
                RecordTypeId = Contact.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Employee').getRecordTypeId(),
                enrtcr__User__c = UserInfo.getUserId()
        );
        insert testWorker;

        enrtcr__Session__c testSession = new enrtcr__Session__c();
        testSession.enrtcr__Start_Date__c = Datetime.now().addDays(1);
        testSession.enrtcr__End_Date__c = Datetime.now().addDays(2);
        testSession.enrtcr__Service_Types__c = 'Initial Assessment';
        testSession.enrtcr__Status__c = SessionTriggerHandler.ROSTERED;
        insert testSession;

        Test.startTest();
        enrtcr__Client_Appointment__c testAppointment = new enrtcr__Client_Appointment__c(
                enrtcr__Client__c = testContact.Id,
                enrtcr__Session__c = testSession.Id,
                enrtcr__Start_Date__c = testSession.enrtcr__Start_Date__c,
                enrtcr__End_Date__c = testSession.enrtcr__End_Date__c
        );
        insert testAppointment;

        enrtcr__Worker_Appointment__c wAppointment = new enrtcr__Worker_Appointment__c();
        wAppointment.enrtcr__Worker__c = testWorker.ID;
        wAppointment.enrtcr__Session__c = testSession.ID;
        wAppointment.enrtcr__Status__c = SessionTriggerHandler.ROSTERED;
        insert wAppointment;

        testSession.enrtcr__Status__c = 'Pending';
        update testSession;

        testSession.enrtcr__Status__c = SessionTriggerHandler.ROSTERED;
        update testSession;

        testSession.enrtcr__Start_Date__c = testSession.enrtcr__Start_Date__c.addHours(1);
        update testSession;

        testSession.enrtcr__Service_Types__c = 'Followup Assessment';
        update testSession;

        testSession.enrtcr__Service_Types__c = 'Initial Assessment';
        update testSession;

        try
        {
           delete testAppointment;
        }
        catch(Exception e)
        {}
        try
        {
            delete wAppointment;
        }
        catch(Exception e)
        {}
        try
        {
            delete testSession;
        }
        catch(Exception e)
        {}
        Test.stopTest();
    }
}