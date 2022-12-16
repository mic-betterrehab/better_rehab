/***********************************************************************************************************************
 * Name: WorkerAppointmentHandlerTest
 * Description: Test class for worker appointment trigger.
 *
 * Version History
 * Date             Developer           Comments
 * --------------- ------------------- -------------------------------------------------------------------------------
 * 2019-11-29      Can Ersoz           Created. Align Worker Info to Session
 **********************************************************************************************************************/
@isTest
public with sharing class WorkerAppointmentHandlerTest {

    @isTest
    public static void testWorkerAppointmentHandler() {

        enrtcr__Site__c testSite = TestData.createTestSite();
        insert testSite;

        Contact testWorker1 = TestData.createTestWorkerContact();
        testWorker1.Clinician_Discipline__c ='Physiotherapy';
        testWorker1.enrtcr__Site__c = testSite.Id;

        Contact testWorker2 = TestData.createTestWorkerContact();
        testWorker2.Clinician_Discipline__c ='Occupational Therapy';
        testWorker2.enrtcr__Site__c = testSite.Id;

        insert new List<Contact> {testWorker1,testWorker2};

        enrtcr__Session__c testSession = TestData.createTestSession(null, 'Draft', null, null, null);
        insert testSession;

        enrtcr__Worker_Appointment__c testWorkerAppointment1 = TestData.createTestWorkerAppointment(
                testWorker1.Id,
                testSession.Id,
                testSession.enrtcr__Start_Date__c,
                Datetime.now().addMinutes(5));

        enrtcr__Worker_Appointment__c testWorkerAppointment2 = TestData.createTestWorkerAppointment(
                testWorker2.Id,
                testSession.Id,
                testSession.enrtcr__Start_Date__c,
                Datetime.now().addMinutes(5));

        insert new List<enrtcr__Worker_Appointment__c> {testWorkerAppointment1,testWorkerAppointment2};

        System.assertEquals(
                'TestWorker(Physiotherapy), TestWorker(Occupational Therapy)',
        [SELECT Workers_and_Professions__c FROM enrtcr__Session__c WHERE Id =:testSession.Id][0].Workers_and_Professions__c,
                'Session Worker information was not populated'
        );

        System.assertNotEquals(
                null,
                [SELECT Worker_Site__c FROM enrtcr__Session__c WHERE Id =:testSession.Id][0].Worker_Site__c,
                'Failed to populate Session Worker Site'
        );

        delete [SELECT Id FROM enrtcr__Worker_Appointment__c];

        System.assertEquals(
                null,
        [SELECT Workers_and_Professions__c FROM enrtcr__Session__c WHERE Id =:testSession.Id][0].Workers_and_Professions__c,
                'Session Worker information was not deleted'
        );
    }
}