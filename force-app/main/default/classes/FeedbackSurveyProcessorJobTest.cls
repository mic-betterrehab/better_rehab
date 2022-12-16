/***********************************************************************************************************************
 * Name: FeedbackSurveyProcessorJobTest
 * Description: Test class of Feedback Survey Processor Job.
 *
 * Version History
 * Date             Developer           Comments
 * --------------- ------------------- -------------------------------------------------------------------------------
 * 2020-02-11      Can Ersoz           Created.
 **********************************************************************************************************************/
@isTest
public with sharing class FeedbackSurveyProcessorJobTest {

    @TestSetup
    static void setup () {

        enrtcr__Site__c testSite = TestData.createTestSite();
        insert testSite;

        Contact testWorker = TestData.createTestWorkerContact();
        testWorker.Clinician_Discipline__c ='Physiotherapy';
        testWorker.enrtcr__Site__c = testSite.Id;
        insert testWorker;

        //create 3 initial assessment sessions
        List<enrtcr__Session__c> testInitialAssessmentSessions = new List<enrtcr__Session__c>();
        for (Integer i = 0; i < 3 ; i++) {

            testInitialAssessmentSessions.add(
                    TestData.createTestSession(
                            null,
                            'Draft',
                            null,
                            Datetime.now().addDays(-1),
                            Datetime.now().addDays(-1).addMinutes(5)
                    )
            );
        }

        for(enrtcr__Session__c testSession : testInitialAssessmentSessions){
            testSession.enrtcr__Service_Types__c = 'Initial Assessment';
        }
        insert testInitialAssessmentSessions;

        //assign workers for each sessions
        enrtcr__Worker_Appointment__c testWorkerAppointment1 =
                TestData.createTestWorkerAppointment(
                            testWorker.Id,
                        testInitialAssessmentSessions[0].Id,
                        testInitialAssessmentSessions[0].enrtcr__Start_Date__c,
                        testInitialAssessmentSessions[0].enrtcr__End_Date__c.addMinutes(-3)
                    );
        insert testWorkerAppointment1;

        enrtcr__Worker_Appointment__c testWorkerAppointment2 =
                TestData.createTestWorkerAppointment(
                        testWorker.Id,
                        testInitialAssessmentSessions[1].Id,
                        testInitialAssessmentSessions[1].enrtcr__Start_Date__c,
                        testInitialAssessmentSessions[1].enrtcr__End_Date__c.addMinutes(-3)
                );
        insert testWorkerAppointment2;

        enrtcr__Worker_Appointment__c testWorkerAppointment3 =
                TestData.createTestWorkerAppointment(
                        testWorker.Id,
                        testInitialAssessmentSessions[2].Id,
                        testInitialAssessmentSessions[2].enrtcr__Start_Date__c,
                        testInitialAssessmentSessions[2].enrtcr__End_Date__c.addMinutes(-3)
                );
        insert testWorkerAppointment3;

        //create 3 NDIS clients
        List<Contact> testClients = new List<Contact>();
        for (Integer i = 0; i < 3; i++) {

            testClients.add(
                    TestData.createTestContact()
            );
        }
        for(Contact testContact : testClients){
            testContact.Client_Division__c = 'NDIS';
        }
        insert testClients;

        //assign 1 client to different sessions
        //assign 1 client to another session
        enrtcr__Client_Appointment__c testClientAppointment1=
                TestData.createTestClientAppointment(
                        testInitialAssessmentSessions[0].Id,
                        testClients[0].Id,
                        testInitialAssessmentSessions[0].enrtcr__Start_Date__c,
                        testInitialAssessmentSessions[0].enrtcr__End_Date__c
                );
        insert testClientAppointment1;

        enrtcr__Client_Appointment__c testClientAppointment2=
                TestData.createTestClientAppointment(
                        testInitialAssessmentSessions[1].Id,
                        testClients[0].Id,
                        testInitialAssessmentSessions[1].enrtcr__Start_Date__c,
                        testInitialAssessmentSessions[1].enrtcr__End_Date__c
                );
        insert testClientAppointment2;

        enrtcr__Client_Appointment__c testClientAppointment3=
                TestData.createTestClientAppointment(
                        testInitialAssessmentSessions[2].Id,
                        testClients[1].Id,
                        testInitialAssessmentSessions[2].enrtcr__Start_Date__c,
                        testInitialAssessmentSessions[2].enrtcr__End_Date__c
                );
        insert testClientAppointment3;

        //create sessions to test follow up survey
        List<enrtcr__Session__c> testPastSessions = new List<enrtcr__Session__c>();
        for (Integer i = 0; i < 3; i++) {

            testPastSessions.add(
                    TestData.createTestSession(
                            null,
                            'Draft',
                            null,
                            Datetime.now().addDays(-5),
                            Datetime.now().addDays(-5).addMinutes(5)
                    )
            );
        }
        insert testPastSessions;

        List<enrtcr__Client_Appointment__c> testClientAppointments = new List<enrtcr__Client_Appointment__c>();

        for(enrtcr__Session__c pastSession : testPastSessions){

            testClientAppointments.add(
                    TestData.createTestClientAppointment(
                            pastSession.Id,
                            testClients[0].Id,
                            pastSession.enrtcr__Start_Date__c,
                            pastSession.enrtcr__End_Date__c
                    )
            );
        }
        insert testClientAppointments;

        //create sessions to get picked up by our schedule job for follow up survey creation
        enrtcr__Session__c testSessionForFollowUp=  TestData.createTestSession(
                    null,
                    'Draft',
                    null,
                    Datetime.now().addDays(-1),
                    Datetime.now().addDays(-1).addMinutes(5)
        );
        insert testSessionForFollowUp;

        enrtcr__Client_Appointment__c testClientAppointmentForFollowUp = TestData.createTestClientAppointment(
                 testSessionForFollowUp.Id,
                    testClients[0].Id,
                 testSessionForFollowUp.enrtcr__Start_Date__c,
                 testSessionForFollowUp.enrtcr__End_Date__c
        );
        insert testClientAppointmentForFollowUp;

        Customer_Feedback_Survey__c testSurvey = new Customer_Feedback_Survey__c(
                Recipient__c = testClients[0].Id,
                Session__c = testPastSessions[0].Id,
                Survey_Type__c = 'Follow up',
                RecordTypeId = Schema.SObjectType.Customer_Feedback_Survey__c.getRecordTypeInfosByDeveloperName().get('Follow_up').getRecordTypeId(),
                First_Question_Sent__c = Datetime.now().addDays(-55)
        );
        insert testSurvey;

    }

    @isTest
    static void validateInitialSurveyProcessor () {

        // Run the batch process
        Test.startTest();

        FeedbackSurveyProcessorJob testJob = new FeedbackSurveyProcessorJob();

        System.schedule('Test Survey Processor', '0 0 * * * ?', testJob);

        testJob.execute(null);

        Test.stopTest();

        // Assert the changes were made
        System.assertEquals(
                3,
        [SELECT COUNT() FROM Customer_Feedback_Survey__c
        WHERE RecordTypeId = : Schema.SObjectType.Customer_Feedback_Survey__c.getRecordTypeInfosByDeveloperName().get('Initial').getRecordTypeId()],
                'Failed to create Surveys for the clients'
        );

        System.assertEquals(
                3,
        [SELECT COUNT() FROM Customer_Feedback_Survey__c
        WHERE Worker__c != NULL AND Worker_Site__c != NULL AND Profession__c != NULL
          AND RecordTypeId = : Schema.SObjectType.Customer_Feedback_Survey__c.getRecordTypeInfosByDeveloperName().get('Initial').getRecordTypeId()],
                'Failed to populate relevant fields on Survey'
        );
    }

    @isTest
    static void validateFollowUpSurveyProcessorWithoutSixSessions () {

        delete [select id from enrtcr__Session__c order by enrtcr__End_Date__c Limit 1];

        // Run the batch process
        Test.startTest();

        FeedbackSurveyProcessorJob testJob = new FeedbackSurveyProcessorJob();

        System.schedule('Test Survey Processor', '0 0 * * * ?', testJob);

        testJob.execute(null);

        Test.stopTest();

        // Assert the changes were made
        System.assertEquals(
                0,
        [SELECT COUNT() FROM Customer_Feedback_Survey__c
        WHERE RecordTypeId = : Schema.SObjectType.Customer_Feedback_Survey__c.getRecordTypeInfosByDeveloperName().get('Follow_up').getRecordTypeId()],
                'Follow up Survey should not be generated for the client'
        );
    }

    @isTest
    static void validateFollowUpSurveyProcessorWithSixSessions () {

        delete [select id from Customer_Feedback_Survey__c where Survey_Type__c ='Follow up'];

        // Run the batch process
        Test.startTest();

        FeedbackSurveyProcessorJob testJob = new FeedbackSurveyProcessorJob();

        System.schedule('Test Survey Processor', '0 0 * * * ?', testJob);

        testJob.execute(null);

        Test.stopTest();

        // Assert the changes were made
        System.assertEquals(
                1,
        [SELECT COUNT() FROM Customer_Feedback_Survey__c
        WHERE Survey_Type__c = 'Follow up'],
                'Failed to create Surveys for the client'
        );
    }

    @isTest
    static void validateFollowUpSurveyProcessorEightWeeksWindow () {

        Customer_Feedback_Survey__c testSurvey = [
                select id,First_Question_Sent__c from Customer_Feedback_Survey__c
                where Survey_Type__c = 'Follow up'
                order by First_Question_Sent__c ASC Limit 1];

        testSurvey.First_Question_Sent__c = testSurvey.First_Question_Sent__c.addDays(-1);
        update testSurvey;

        // Run the batch process
        Test.startTest();

        FeedbackSurveyProcessorJob testJob = new FeedbackSurveyProcessorJob();

        System.schedule('Test Survey Processor', '0 0 * * * ?', testJob);

        testJob.execute(null);

        Test.stopTest();

        // Assert the changes were made
        System.assertEquals(
                2,
        [SELECT COUNT() FROM Customer_Feedback_Survey__c
        WHERE Survey_Type__c = 'Follow up'],
                'Failed to create Follow up Survey for the client'
        );

    }

    @isTest
    static void validateFollowUpSurveyProcessorNoEightWeeksWindow () {

        // Run the batch process
        Test.startTest();

        FeedbackSurveyProcessorJob testJob = new FeedbackSurveyProcessorJob();

        System.schedule('Test Survey Processor', '0 0 * * * ?', testJob);

        testJob.execute(null);

        Test.stopTest();

        // Assert the changes were made
        System.assertEquals(
                1,
        [SELECT COUNT() FROM Customer_Feedback_Survey__c
        WHERE Survey_Type__c = 'Follow up'],
                'Follow up survey should not be created for the client'
        );
    }
}