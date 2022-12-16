/***********************************************************************************************************************
 * Name: ZiplineInboundResponseHandlerTest
 * Description: Test class of ZiplineInboundResponseHandler.
 *
 * Version History
 * Date             Developer           Comments
 * --------------- ------------------- -------------------------------------------------------------------------------
 * 2020-02-11      Can Ersoz           Created.
 **********************************************************************************************************************/
@isTest
public with sharing class ZiplineInboundResponseHandlerTest {

    @isTest
    static void test() {

        Test.StartTest();
        ZiplineInboundResponseHandler obj = new ZiplineInboundResponseHandler();
        System.assertNotEquals(null, obj);
        Test.StopTest();
    }

/*
    @TestSetup
    public static void setup() {

        Contact testClient = TestData.createTestContact();
        insert testClient;

        Contact testWorker = TestData.createTestWorkerContact();
        insert testWorker;

        enrtcr__Session__c testSession = TestData.createTestSession(null, 'Draft', null, null, null);
        insert testSession;

        enrtcr__Client_Appointment__c testClientAppointment = TestData.createTestClientAppointment(
                testSession.Id, testClient.Id, testSession.enrtcr__Start_Date__c, testSession.enrtcr__End_Date__c
        );
        insert testClientAppointment;

        enrtcr__Worker_Appointment__c testWorkerAppointment = TestData.createTestWorkerAppointment(
                testWorker.Id,
                testSession.Id,
                testSession.enrtcr__Start_Date__c,
                Datetime.now().addMinutes(5)
        );
        insert testWorkerAppointment;

        Customer_Feedback_Survey__c testCustomerFeedbackSurvey = new Customer_Feedback_Survey__c(
                Session__c = testSession.Id,
                Recipient__c = testClient.Id,
                First_Question_Sent__c = Datetime.now(),
                Survey_Response__c = 0
        );
        insert testCustomerFeedbackSurvey;

    }

    @isTest
    public static void testSurveyUnrecognisedResponse () {

        Contact testClient = [SELECT Id FROM Contact WHERE RecordTypeId = :Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Client').getRecordTypeId()];

        Zipline__Message__c testBlankMessage = TestData.createMessage(true, null);
        insert testBlankMessage;

        Zipline__Contact_Matching__c testContactMatchingForBlankMessage = TestData.createContactMatching(testClient.Id, testBlankMessage.Id);
        insert testContactMatchingForBlankMessage;

        System.assertEquals(1,
                [
                        SELECT Id
                        FROM Customer_Feedback_Survey__c
                        WHERE Recipient__c = :testClient.Id
                        AND Unrecognised_Response__c != NULL
                        AND Survey_is_Completed__c = FALSE
                ].size(),
                'Failed to populate Unrecognised Response for blank sms');

        Zipline__Message__c testMessage = TestData.createMessage(true, 'danke schon');
        insert testMessage;

        Zipline__Contact_Matching__c testContactMatching = TestData.createContactMatching(testClient.Id, testMessage.Id);
        insert testContactMatching;

        System.assertEquals(1,
                [
                        SELECT Id
                        FROM Customer_Feedback_Survey__c
                        WHERE Recipient__c = :testClient.Id
                        AND Unrecognised_Response__c != NULL
                        AND Survey_is_Completed__c = FALSE
                ].size(),
                'Failed to populate Unrecognised Response');


        Zipline__Message__c testMessageIncorrectScore = TestData.createMessage(true, '11');
        insert testMessageIncorrectScore;

        Zipline__Contact_Matching__c testContactMatchingForIncorrectScore = TestData.createContactMatching(testClient.Id, testMessage.Id);
        insert testContactMatchingForIncorrectScore;

        System.assertEquals(1,
                [
                        SELECT Id
                        FROM Customer_Feedback_Survey__c
                        WHERE Recipient__c = :testClient.Id
                        AND Unrecognised_Response__c != NULL
                        AND Survey_is_Completed__c = FALSE
                ].size(),
                'Failed to populate Unrecognised Response');
    }

    @isTest
    public static void testSurveyResponse () {

        Contact testClient = [SELECT Id FROM Contact WHERE RecordTypeId = :Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Client').getRecordTypeId()];

        Zipline__Message__c testMessage = TestData.createMessage(true, '3');
        insert testMessage;

        Zipline__Contact_Matching__c testContactMatching = TestData.createContactMatching(testClient.Id, testMessage.Id);
        insert testContactMatching;

        System.assertEquals(1,
                [
                        SELECT Id
                        FROM Customer_Feedback_Survey__c
                        WHERE Recipient__c = :testClient.Id
                        AND Survey_Response__c = 3
                        AND Survey_is_Completed__c = TRUE
                ].size(),
                'Failed to align response to Survey');
    }

    @isTest
    public static void testSurveyResponseOptOut () {

        Contact testClient = [SELECT Id FROM Contact WHERE RecordTypeId = :Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Client').getRecordTypeId()];

        Zipline__Message__c testMessage = TestData.createMessage(true, 'Stop');
        insert testMessage;

        Zipline__Contact_Matching__c testContactMatching = TestData.createContactMatching(testClient.Id, testMessage.Id);
        insert testContactMatching;

        System.assertEquals(1,
                [
                        SELECT Id
                        FROM Customer_Feedback_Survey__c
                        WHERE Recipient__c = :testClient.Id
                        AND Survey_Response__c = 0
                        AND Opt_out__c = TRUE
                        AND Survey_is_Completed__c = TRUE
                ].size(),
                'Failed to opt out');
    }*/
}