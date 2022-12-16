/**
 * Created by ersoz on 2019-06-12.
 */
@isTest
public class SessionHandlerTest {

    public static String CRON_EXP = '0 0 0 15 3 ? 2023';

    @isTest
    public static void testCreateCommunicationAppointmentConfirmation(){

        Contact testContact = TestData.createTestContact();
        insert testContact;

        enrtcr__Recurrence__c testRecurrence = TestData.createTestRecurrence();
        insert testRecurrence;

        enrtcr__Session__c testParentSession = TestData.createTestSession(null, 'Draft', testRecurrence.Id, null, null);
        insert testParentSession;

        enrtcr__Client_Appointment__c testClientAppointment1 = TestData.createTestClientAppointment(testParentSession.Id, testContact.Id, testParentSession.enrtcr__Start_Date__c, testParentSession.enrtcr__End_Date__c);
        enrtcr__Client_Appointment__c testClientAppointment2 = TestData.createTestClientAppointment(testParentSession.Id, testContact.Id, testParentSession.enrtcr__Start_Date__c, testParentSession.enrtcr__End_Date__c);
        insert new List<enrtcr__Client_Appointment__c> {testClientAppointment1, testClientAppointment2};

        List<enrtcr__Session__c> testChildSessions = new List<enrtcr__Session__c>();
        for (Integer i = 1; i < 4; i++) {

            testChildSessions.add(
                    TestData.createTestSession(
                            testParentSession.Id,
                            'Draft',
                            testRecurrence.Id,
                            testParentSession.enrtcr__Start_Date__c,
                            testParentSession.enrtcr__End_Date__c
                    )
            );
        }
        insert testChildSessions;
        List<enrtcr__Session__c> sessionsToUpdate = new List<enrtcr__Session__c>();
        for (enrtcr__Session__c session : [SELECT Id, enrtcr__Status__c FROM enrtcr__Session__c])
        {
            session.enrtcr__Status__c = 'Rostered';
            sessionsToUpdate.add(session);
        }
        update sessionsToUpdate;

        Id nonRecurrenceSessionComRecordTypeId = Schema.SObjectType.Session_Communication__c.getRecordTypeInfosByDeveloperName().get('Appointment_Booked').getRecordTypeId();
        Id recurrenceSessionComRecordTypeId = Schema.SObjectType.Session_Communication__c.getRecordTypeInfosByDeveloperName().get('Recurrence_Confirmation').getRecordTypeId();

        system.assertEquals(4,
                [SELECT Id FROM Session_Communication__c].size(),
                'Session Communication Record was not created for each of the appointments');

        system.assertEquals(1,
                [SELECT Id FROM Session_Communication__c
                WHERE Session__c = :testParentSession.Id
                AND Client_Appointment__c = :testClientAppointment1.Id
                AND RecordTypeId = :nonRecurrenceSessionComRecordTypeId].size(),
                'Appointment Booked Session Communication Record was not created for the first appointment of the Non Recurring Session');

        system.assertEquals(1,
                [SELECT Id FROM Session_Communication__c
                WHERE Session__c = :testParentSession.Id
                AND Client_Appointment__c = :testClientAppointment2.Id
                AND RecordTypeId = :nonRecurrenceSessionComRecordTypeId].size(),
                'Appointment Booked Session Communication Record was not created for the second appointment of the Non Recurring Session');

        system.assertEquals(1,
                [SELECT Id FROM Session_Communication__c
                WHERE Session__c = :testParentSession.Id
                AND Client_Appointment__c = :testClientAppointment1.Id
                AND RecordTypeId = :recurrenceSessionComRecordTypeId].size(),
                'Recurrence Confirmation Session Communication Record was not created for the first appointment of the Recurring Session');

        system.assertEquals(1,
                [SELECT Id FROM Session_Communication__c
                WHERE Session__c = :testParentSession.Id
                AND Client_Appointment__c = :testClientAppointment2.Id
                AND RecordTypeId = :recurrenceSessionComRecordTypeId].size(),
                'Recurrence Confirmation Session Communication Record was not created for the second appointment of the Recurring Session');

        Id sessionComIdForApp1 = [SELECT Id FROM Session_Communication__c
        WHERE Session__c = :testParentSession.Id
        AND RecordTypeId = :recurrenceSessionComRecordTypeId
        AND Client_Appointment__c = :testClientAppointment1.Id][0].Id;

        Id sessionComIdForApp2 = [SELECT Id FROM Session_Communication__c
        WHERE Session__c = :testParentSession.Id
        AND RecordTypeId = :recurrenceSessionComRecordTypeId
        AND Client_Appointment__c = :testClientAppointment2.Id][0].Id;

        system.assertEquals(3,
                [SELECT Id FROM Session_Recurrence_Communication__c WHERE Session_Communication__c = :sessionComIdForApp1].size(),
                'Session Recurrence Communication Record was not created for each of the Child Sessions with Appointment1');

        system.assertEquals(3,
                [SELECT Id FROM Session_Recurrence_Communication__c WHERE Session_Communication__c = :sessionComIdForApp2].size(),
                'Session Recurrence Communication Record was not created for each of the Child Sessions with Appointment2');
    }

    @isTest
    public static void testCreateCommunicationAppointmentTimeChanged(){

        Contact testContact = TestData.createTestContact();
        insert testContact;

        enrtcr__Recurrence__c testRecurrence = TestData.createTestRecurrence();
        insert testRecurrence;

        enrtcr__Session__c testParentSession = TestData.createTestSession(null,'Rostered', testRecurrence.Id, null, null);
        insert testParentSession;

        enrtcr__Client_Appointment__c testClientAppointment1 = TestData.createTestClientAppointment(testParentSession.Id, testContact.Id, testParentSession.enrtcr__Start_Date__c, testParentSession.enrtcr__End_Date__c);
        enrtcr__Client_Appointment__c testClientAppointment2 = TestData.createTestClientAppointment(testParentSession.Id, testContact.Id, testParentSession.enrtcr__Start_Date__c, testParentSession.enrtcr__End_Date__c);
        insert new List<enrtcr__Client_Appointment__c> {testClientAppointment1, testClientAppointment2};

        List<enrtcr__Session__c> testChildSessions = new List<enrtcr__Session__c>();
        for (Integer i = 1; i < 4; i++) {

            testChildSessions.add(
                    TestData.createTestSession(
                            testParentSession.Id,
                            'Rostered',
                            testRecurrence.Id,
                            testParentSession.enrtcr__Start_Date__c,
                            testParentSession.enrtcr__End_Date__c
                    )
            );
        }
        insert testChildSessions;

        //Parent session and each of the recurrences Time Changed
        List<enrtcr__Session__c> sessionsToUpdate = new List<enrtcr__Session__c>();
        for (enrtcr__Session__c session : [SELECT Id, enrtcr__Status__c, enrtcr__Start_Date__c, enrtcr__End_Date__c FROM enrtcr__Session__c])
        {
            session.enrtcr__Start_Date__c = session.enrtcr__Start_Date__c.addMinutes(-5);
            session.enrtcr__End_Date__c = session.enrtcr__End_Date__c.addDays(1);
            sessionsToUpdate.add(session);
        }
        update sessionsToUpdate;

        Id nonRecurrenceSessionComRecordTypeId = Schema.SObjectType.Session_Communication__c.getRecordTypeInfosByDeveloperName().get('Appointment_Time_Changed').getRecordTypeId();
        Id recurrenceSessionComRecordTypeId = Schema.SObjectType.Session_Communication__c.getRecordTypeInfosByDeveloperName().get('Recurrence_Changed').getRecordTypeId();

        system.assertEquals(4,
                [SELECT Id FROM Session_Communication__c].size(),
                'Session Communication Record was not created for each of the appointments');

        system.assertEquals(1,
                [SELECT Id FROM Session_Communication__c
                WHERE Session__c = :testParentSession.Id
                AND Client_Appointment__c = :testClientAppointment1.Id
                AND RecordTypeId = :nonRecurrenceSessionComRecordTypeId].size(),
                'Appointment Time Changed Session Communication Record was not created for the first appointment of the Non Recurring Session');

        system.assertEquals(1,
                [SELECT Id FROM Session_Communication__c
                WHERE Session__c = :testParentSession.Id
                AND Client_Appointment__c = :testClientAppointment2.Id
                AND RecordTypeId = :nonRecurrenceSessionComRecordTypeId].size(),
                'Appointment Time Changed Session Communication Record was not created for the second appointment of the Non Recurring Session');

        system.assertEquals(1,
                [SELECT Id FROM Session_Communication__c
                WHERE Session__c = :testParentSession.Id
                AND Client_Appointment__c = :testClientAppointment1.Id
                AND RecordTypeId = :recurrenceSessionComRecordTypeId].size(),
                'Recurrence Confirmation Session Communication Record was not created for the first appointment of the Recurring Session');

        system.assertEquals(1,
                [SELECT Id FROM Session_Communication__c
                WHERE Session__c = :testParentSession.Id
                AND Client_Appointment__c = :testClientAppointment2.Id
                AND RecordTypeId = :recurrenceSessionComRecordTypeId].size(),
                'Recurrence Confirmation Session Communication Record was not created for the second appointment of the Recurring Session');

        Id sessionComIdForApp1 = [SELECT Id FROM Session_Communication__c
        WHERE Session__c = :testParentSession.Id
        AND RecordTypeId = :recurrenceSessionComRecordTypeId
        AND Client_Appointment__c = :testClientAppointment1.Id][0].Id;

        Id sessionComIdForApp2 = [SELECT Id FROM Session_Communication__c
        WHERE Session__c = :testParentSession.Id
        AND RecordTypeId = :recurrenceSessionComRecordTypeId
        AND Client_Appointment__c = :testClientAppointment2.Id][0].Id;

        system.assertEquals(3,
                [SELECT Id FROM Session_Recurrence_Communication__c WHERE Session_Communication__c = :sessionComIdForApp1].size(),
                'Session Recurrence Communication Record was not created for each of the Child Sessions with Appointment1');

        system.assertEquals(3,
                [SELECT Id FROM Session_Recurrence_Communication__c WHERE Session_Communication__c = :sessionComIdForApp2].size(),
                'Session Recurrence Communication Record was not created for each of the Child Sessions with Appointment2');
    }

    @isTest
    public static void testCreateCommunicationOneOffAppointmentTimeChanged() {

        Contact testContact = TestData.createTestContact();
        insert testContact;

        enrtcr__Recurrence__c testRecurrence = TestData.createTestRecurrence();
        insert testRecurrence;

        enrtcr__Session__c testParentSession = TestData.createTestSession(null,'Rostered', testRecurrence.Id, null, null);
        insert testParentSession;

        enrtcr__Client_Appointment__c testClientAppointment1 = TestData.createTestClientAppointment(testParentSession.Id, testContact.Id, testParentSession.enrtcr__Start_Date__c, testParentSession.enrtcr__End_Date__c);
        enrtcr__Client_Appointment__c testClientAppointment2 = TestData.createTestClientAppointment(testParentSession.Id, testContact.Id, testParentSession.enrtcr__Start_Date__c, testParentSession.enrtcr__End_Date__c);
        insert new List<enrtcr__Client_Appointment__c> {testClientAppointment1, testClientAppointment2};

        List<enrtcr__Session__c> testChildSessions = new List<enrtcr__Session__c>();
        for (Integer i = 1; i < 4; i++) {

            testChildSessions.add(
                    TestData.createTestSession(
                            testParentSession.Id,
                            'Rostered',
                            testRecurrence.Id,
                            testParentSession.enrtcr__Start_Date__c,
                            testParentSession.enrtcr__End_Date__c
                    )
            );
        }
        insert testChildSessions;

        enrtcr__Session__c testChildOneOffSession = [
                SELECT Id, enrtcr__Status__c, enrtcr__Parent_Session__c, enrtcr__Start_Date__c, enrtcr__End_Date__c
                FROM enrtcr__Session__c
                WHERE enrtcr__Parent_Session__c != NULL
                LIMIT 1][0];

        testChildOneOffSession.enrtcr__Start_Date__c = testChildOneOffSession.enrtcr__Start_Date__c.addMinutes(-5);
        testChildOneOffSession.enrtcr__End_Date__c = testChildOneOffSession.enrtcr__End_Date__c.addDays(1);
        update testChildOneOffSession;

        Id oneOffRecurrenceSessionComRecordTypeId = Schema.SObjectType.Session_Communication__c.getRecordTypeInfosByDeveloperName().get('Appointment_Time_Changed').getRecordTypeId();

        system.assertEquals(2,
                [SELECT Id FROM Session_Communication__c].size(),
                'Appointment Time Changed Session Communication Record was not created for each of the appointments');

        system.assertEquals(1,
                [
                        SELECT Id
                        FROM Session_Communication__c
                        WHERE Session__c = :testChildOneOffSession.enrtcr__Parent_Session__c
                        AND Client_Appointment__c = :testClientAppointment1.Id
                        AND RecordTypeId = :oneOffRecurrenceSessionComRecordTypeId
                ].size(),
                'Appointment Time Changed One Off Session Communication Record was not created for the first appointment of the Recurring Session');

        system.assertEquals(1,
                [
                        SELECT Id
                        FROM Session_Communication__c
                        WHERE Session__c = :testChildOneOffSession.enrtcr__Parent_Session__c
                        AND Client_Appointment__c = :testClientAppointment2.Id
                        AND RecordTypeId = :oneOffRecurrenceSessionComRecordTypeId
                ].size(),
                'Appointment Time Changed One Off Session Communication Record was not created for the second appointment of the Recurring Session');

        system.assertEquals(0,
                [SELECT Id FROM Session_Recurrence_Communication__c].size(),
                'Session Recurrence Communication Record should not be created for One Off Time Change');
    }

    @isTest
    public static void testCreateCommunicationAppointmentCancelled(){

        Contact testContact = TestData.createTestContact();
        insert testContact;

        enrtcr__Recurrence__c testRecurrence = TestData.createTestRecurrence();
        insert testRecurrence;

        enrtcr__Session__c testParentSession = TestData.createTestSession(null, 'Rostered', testRecurrence.Id, null, null);
        insert testParentSession;

        enrtcr__Client_Appointment__c testClientAppointment1 = TestData.createTestClientAppointment(testParentSession.Id, testContact.Id, testParentSession.enrtcr__Start_Date__c, testParentSession.enrtcr__End_Date__c);
        enrtcr__Client_Appointment__c testClientAppointment2 = TestData.createTestClientAppointment(testParentSession.Id, testContact.Id, testParentSession.enrtcr__Start_Date__c, testParentSession.enrtcr__End_Date__c);
        insert new List<enrtcr__Client_Appointment__c> {testClientAppointment1, testClientAppointment2};

        List<enrtcr__Session__c> testChildSessions = new List<enrtcr__Session__c>();
        for (Integer i = 1; i < 4; i++) {

            testChildSessions.add(
                    TestData.createTestSession(
                            testParentSession.Id,
                            'Rostered',
                            testRecurrence.Id,
                            testParentSession.enrtcr__Start_Date__c,
                            testParentSession.enrtcr__End_Date__c
                    )
            );
        }
        insert testChildSessions;

        List<enrtcr__Session__c> sessionsToUpdate = new List<enrtcr__Session__c>();
        for (enrtcr__Session__c session : [SELECT Id, enrtcr__Status__c, enrtcr__Cancellation_Reason__c FROM enrtcr__Session__c])
        {
            session.enrtcr__Status__c = 'Cancelled';
            session.enrtcr__Cancellation_Reason__c = 'Insufficient worker attendance';
            sessionsToUpdate.add(session);
        }
        update sessionsToUpdate;

        Id nonRecurrenceSessionComRecordTypeId = Schema.SObjectType.Session_Communication__c.getRecordTypeInfosByDeveloperName().get('Appointment_Cancelled').getRecordTypeId();

        system.assertEquals(2,
                [SELECT Id FROM Session_Communication__c].size(),
                'Appointment Cancelled Session Communication Record was not created for each of the appointments');

        system.assertEquals(1,
                [SELECT Id FROM Session_Communication__c
                WHERE Session__c = :testParentSession.Id
                AND Client_Appointment__c = :testClientAppointment1.Id
                AND RecordTypeId = :nonRecurrenceSessionComRecordTypeId].size(),
                'Appointment Cancelled Session Communication Record was not created for the first appointment of the Parent Session');

        system.assertEquals(1,
                [SELECT Id FROM Session_Communication__c
                WHERE Session__c = :testParentSession.Id
                AND Client_Appointment__c = :testClientAppointment2.Id
                AND RecordTypeId = :nonRecurrenceSessionComRecordTypeId].size(),
                'Appointment Cancelled Session Communication Record was not created for the second appointment of the Parent Session');
    }

    @isTest
    public static void testCreateCommunicationAppointmentOneOffCancelled(){

        Contact testContact = TestData.createTestContact();
        insert testContact;

        enrtcr__Recurrence__c testRecurrence = TestData.createTestRecurrence();
        insert testRecurrence;

        enrtcr__Session__c testParentSession = TestData.createTestSession(null, 'Rostered', testRecurrence.Id, null, null);
        insert testParentSession;

        enrtcr__Session__c testChildSession1 = TestData.createTestSession(
                testParentSession.Id,
                'Rostered',
                testRecurrence.Id,
                testParentSession.enrtcr__Start_Date__c,
                testParentSession.enrtcr__End_Date__c
        );

        insert testChildSession1;

        enrtcr__Session__c testChildSession2 = TestData.createTestSession(
                testParentSession.Id,
                'Rostered',
                testRecurrence.Id,
                testParentSession.enrtcr__Start_Date__c,
                testParentSession.enrtcr__End_Date__c
        );

        insert testChildSession2;

        enrtcr__Client_Appointment__c testClientAppointment1 = TestData.createTestClientAppointment(testChildSession1.Id, testContact.Id, testChildSession1.enrtcr__Start_Date__c, testChildSession1.enrtcr__End_Date__c);
        insert new List<enrtcr__Client_Appointment__c> {testClientAppointment1};

        enrtcr__Session__c testChildSession = [SELECT Id, enrtcr__Status__c, enrtcr__Cancellation_Reason__c FROM enrtcr__Session__c WHERE Id = :testChildSession1.Id][0];

        testChildSession.enrtcr__Status__c = 'Cancelled';
        testChildSession.enrtcr__Cancellation_Reason__c = 'Insufficient worker attendance';
        update testChildSession;

        Id nonRecurrenceSessionComRecordTypeId = Schema.SObjectType.Session_Communication__c.getRecordTypeInfosByDeveloperName().get('Appointment_Cancelled').getRecordTypeId();

        system.assertEquals(1,
                [SELECT Id FROM Session_Communication__c].size(),
                'Appointment Cancelled Session Communication Record was not created');

        system.assertEquals(1,
                [SELECT Id FROM Session_Communication__c
                WHERE Session__c = :testChildSession1.Id
                AND Client_Appointment__c = :testClientAppointment1.Id
                AND RecordTypeId = :nonRecurrenceSessionComRecordTypeId].size(),
                'Appointment Cancelled Session Communication Record was not created for the related appointment of the Child Session');
    }

    @isTest
    public static void testCreateCommunicationLateCheckIn(){

        Contact testWorker = TestData.createTestWorkerContact();
        insert testWorker;

        enrtcr__Session__c testParentSession = TestData.createTestSession(null, 'Rostered', null , Datetime.now().addMinutes(-45), Datetime.now().addMinutes(30));
        insert testParentSession;

        //Worker appointment 30 mins Start Time Delay
        enrtcr__Worker_Appointment__c testWorkerAppointment = TestData.createTestWorkerAppointment(testWorker.Id, testParentSession.Id, Datetime.now().addMinutes(-30), Datetime.now().addMinutes(-20));
        insert testWorkerAppointment;

        Session_Communication__c testSessionCommunication = TestData.createSessionCommunication(
                Schema.SObjectType.Session_Communication__c.getRecordTypeInfosByDeveloperName().get('Late_Checkout').getRecordTypeId()
        );
        testSessionCommunication.Session__c = testParentSession.Id;
        testSessionCommunication.Worker_Appointment__c = testWorkerAppointment.Id;
        testSessionCommunication.Contact__c = testWorker.Id;
        insert testSessionCommunication;

        Test.startTest();

        System.schedule('SessionReminderJob',
                CRON_EXP,
                new SessionReminderJob());

        Test.stopTest();

        System.assertEquals(1,
        [SELECT COUNT() FROM Session_Communication__c
        WHERE Session__c = :testParentSession.Id
        AND Worker_Appointment__c = :testWorkerAppointment.Id
        AND RecordTypeId = :Schema.SObjectType.Session_Communication__c.getRecordTypeInfosByDeveloperName().get('Late_Checkin').getRecordTypeId()],
                'Failed to create Late CheckIn Session Communication');

    }

    @isTest
    public static void testCreateCommunicationLateCheckOut(){

        Contact testWorker = TestData.createTestWorkerContact();
        insert testWorker;

        enrtcr__Session__c testParentSession = TestData.createTestSession(null, 'Draft', null, Datetime.now().addMinutes(-45), Datetime.now().addMinutes(30));
        insert testParentSession;

        //Worker appointment 30 mins End Time Delay
        enrtcr__Worker_Appointment__c testWorkerAppointment = TestData.createTestWorkerAppointment(testWorker.Id, testParentSession.Id, Datetime.now().addMinutes(-35), Datetime.now().addMinutes(-30));
        insert testWorkerAppointment;

        testParentSession = [SELECT Id, enrtcr__Status__c FROM enrtcr__Session__c];
        testParentSession.enrtcr__Status__c = 'In Progress';
        update testParentSession;

        Session_Communication__c testSessionCommunication = TestData.createSessionCommunication(
                Schema.SObjectType.Session_Communication__c.getRecordTypeInfosByDeveloperName().get('Late_Checkin').getRecordTypeId()
        );
        testSessionCommunication.Session__c = testParentSession.Id;
        testSessionCommunication.Worker_Appointment__c = testWorkerAppointment.Id;
        testSessionCommunication.Contact__c = testWorker.Id;
        insert testSessionCommunication;

        Test.startTest();

        System.schedule('SessionReminderJob',
                CRON_EXP,
                new SessionReminderJob());

        Test.stopTest();

        System.assertEquals(1,
        [SELECT COUNT() FROM Session_Communication__c
        WHERE Session__c = :testParentSession.Id
        AND Worker_Appointment__c = :testWorkerAppointment.Id
        AND RecordTypeId = :Schema.SObjectType.Session_Communication__c.getRecordTypeInfosByDeveloperName().get('Late_Checkout').getRecordTypeId()],
                'Failed to create Late CheckOut Session Communication');
    }
}