/**
 * Created by ersoz on 25/10/20.
 */
@IsTest
public with sharing class MessageTriggerHandlerTest {

    /*@TestSetup
    public static void setup() {

        Pendula__Settings__c settings = Pendula__Settings__c.getOrgDefaults();

        settings.Pendula__Create_Event_Activity_Sync__c = true;
        settings.Pendula__Update_Original_Event_Activity__c = true;

        upsert settings;

        List<Survey_Settings__c> testSurveySettings = new List<Survey_Settings__c>();

        for (Integer j = 0; j <2 ; j++) {

            testSurveySettings.add(
                    new Survey_Settings__c(
                            Name = 'testSurvey'+j,
                            Flow_Name__c = 'InitialSurvey',
                            Flow_Id__c = 'pineapple'+j
                    )
            );
        }
        insert testSurveySettings;


        List<Contact> testClients = new List<Contact>();
        for (Integer i = 0; i < 5 ; i++) {

            testClients.add(
                    TestData.createTestContact()
            );
        }
        insert testClients;

        Contact testWorker = TestData.createTestWorkerContact();
        insert testWorker;

        enrtcr__Session__c testSession = TestData.createTestSession(null, 'Draft', null, null, null);
        insert testSession;

        List<enrtcr__Client_Appointment__c> testClientAppointments = new List<enrtcr__Client_Appointment__c>();
        List<Customer_Feedback_Survey__c> testSurveys = new List<Customer_Feedback_Survey__c>();

        for (Contact testClient : testClients) {

            testClientAppointments.add(
                    TestData.createTestClientAppointment(
                            testSession.Id, testClient.Id, testSession.enrtcr__Start_Date__c, testSession.enrtcr__End_Date__c
                    )
            );

            testSurveys.add(
                    new Customer_Feedback_Survey__c(
                            Session__c = testSession.Id,
                            Recipient__c = testClient.Id,
                            First_Question_Sent__c = Datetime.now()
                    )
            );
        }
        insert testClientAppointments;
        insert testSurveys;

        enrtcr__Worker_Appointment__c testWorkerAppointment = TestData.createTestWorkerAppointment(
                testWorker.Id,
                testSession.Id,
                testSession.enrtcr__Start_Date__c,
                Datetime.now().addMinutes(5)
        );
        insert testWorkerAppointment;
    }

    @IsTest
    public static void validateValidResponse() {

        List<Customer_Feedback_Survey__c> testSurveys = [SELECT Id,Recipient__r.Id,Recipient__r.MobilePhone FROM Customer_Feedback_Survey__c];
        List<Survey_Settings__c> testSettings = [SELECT Id,Flow_Name__c,Flow_Id__c FROM Survey_Settings__c];

        List<Pendula__Message__c> testOutboundMessages = new List<Pendula__Message__c>();
        List<Pendula__Message__c> testInboundMessages = new List<Pendula__Message__c>();

        Integer pendulaId = 123;
        for (Customer_Feedback_Survey__c testSurvey : testSurveys) {

            Pendula__Message__c testMessageOutbound = TestData.createPendulaMessage('Outbound', 'SMS', String.valueOf(pendulaId), testSurvey.Id, testSurvey.Recipient__r.Id, Datetime.now());
            testMessageOutbound.Pendula__Flow_Id__c = testSettings[0].Flow_Id__c;
            testMessageOutbound.RecordTypeId = Schema.SObjectType.Pendula__Message__c.getRecordTypeInfosByDeveloperName().get('Outbound_SMS').getRecordTypeId();
            testMessageOutbound.Pendula__SMS_To_Number__c = testSurvey.Recipient__r.MobilePhone;
            testMessageOutbound.Pendula__SMS_Body__c = 'Please answer';
            testOutboundMessages.add(testMessageOutbound);

            pendulaId++;

            Pendula__Message__c testMessageInboundOptOut = TestData.createPendulaMessage('Inbound', 'SMS', String.valueOf(pendulaId), null, testSurvey.Recipient__r.Id, Datetime.now().addMinutes(1));
            testMessageInboundOptOut.RecordTypeId = Schema.SObjectType.Pendula__Message__c.getRecordTypeInfosByDeveloperName().get('Inbound_SMS').getRecordTypeId();
            testMessageInboundOptOut.Pendula__SMS_Body__c = '5';
            testMessageInboundOptOut.Pendula__SMS_From_Number__c = testSurvey.Recipient__r.MobilePhone;
            testInboundMessages.add(testMessageInboundOptOut);

            pendulaId++;
        }
        insert testOutboundMessages;
        insert testInboundMessages;

        System.assertEquals(
                5,
        [SELECT COUNT() FROM Customer_Feedback_Survey__c WHERE Unrecognised_Response__c = NULL],
                'Unrecognised_Response__c should not be populated for valid response'
        );
    }

    @IsTest
    public static void validateNullResponse() {

        List<Customer_Feedback_Survey__c> testSurveys = [SELECT Id,Recipient__r.Id,Recipient__r.MobilePhone FROM Customer_Feedback_Survey__c];
        List<Survey_Settings__c> testSettings = [SELECT Id,Flow_Name__c,Flow_Id__c FROM Survey_Settings__c];

        List<Pendula__Message__c> testOutboundMessages = new List<Pendula__Message__c>();
        List<Pendula__Message__c> testInboundMessages = new List<Pendula__Message__c>();

        Integer pendulaId = 123;
        for (Customer_Feedback_Survey__c testSurvey : testSurveys) {

            Pendula__Message__c testMessageOutbound = TestData.createPendulaMessage('Outbound', 'SMS', String.valueOf(pendulaId), testSurvey.Id, testSurvey.Recipient__r.Id, Datetime.now());
            testMessageOutbound.Pendula__Flow_Id__c = testSettings[0].Flow_Id__c;
            testMessageOutbound.RecordTypeId = Schema.SObjectType.Pendula__Message__c.getRecordTypeInfosByDeveloperName().get('Outbound_SMS').getRecordTypeId();
            testMessageOutbound.Pendula__SMS_To_Number__c = testSurvey.Recipient__r.MobilePhone;
            testMessageOutbound.Pendula__SMS_Body__c = 'Please answer';
            testOutboundMessages.add(testMessageOutbound);

            pendulaId++;

            Pendula__Message__c testMessageInboundOptOut = TestData.createPendulaMessage('Inbound', 'SMS', String.valueOf(pendulaId), null, testSurvey.Recipient__r.Id, Datetime.now().addMinutes(1));
            testMessageInboundOptOut.RecordTypeId = Schema.SObjectType.Pendula__Message__c.getRecordTypeInfosByDeveloperName().get('Inbound_SMS').getRecordTypeId();
            testMessageInboundOptOut.Pendula__SMS_Body__c = null;
            testMessageInboundOptOut.Pendula__SMS_From_Number__c = testSurvey.Recipient__r.MobilePhone;
            testInboundMessages.add(testMessageInboundOptOut);

            pendulaId++;
        }
        insert testOutboundMessages;
        insert testInboundMessages;

        System.assertEquals(
                5,
        [SELECT COUNT() FROM Customer_Feedback_Survey__c WHERE Unrecognised_Response__c != NULL],
                'Failed to populate Unrecognised_Response__c for null response'
        );
    }

    @IsTest
    public static void validateInvalidNumberResponse() {

        List<Customer_Feedback_Survey__c> testSurveys = [SELECT Id,Recipient__r.Id,Recipient__r.MobilePhone FROM Customer_Feedback_Survey__c];
        List<Survey_Settings__c> testSettings = [SELECT Id,Flow_Name__c,Flow_Id__c FROM Survey_Settings__c];

        List<Pendula__Message__c> testOutboundMessages = new List<Pendula__Message__c>();
        List<Pendula__Message__c> testInboundMessages = new List<Pendula__Message__c>();

        Integer pendulaId = 123;
        for (Customer_Feedback_Survey__c testSurvey : testSurveys) {

            Pendula__Message__c testMessageOutbound = TestData.createPendulaMessage('Outbound', 'SMS', String.valueOf(pendulaId), testSurvey.Id, testSurvey.Recipient__r.Id, Datetime.now());
            testMessageOutbound.Pendula__Flow_Id__c = testSettings[0].Flow_Id__c;
            testMessageOutbound.RecordTypeId = Schema.SObjectType.Pendula__Message__c.getRecordTypeInfosByDeveloperName().get('Outbound_SMS').getRecordTypeId();
            testMessageOutbound.Pendula__SMS_To_Number__c = testSurvey.Recipient__r.MobilePhone;
            testMessageOutbound.Pendula__SMS_Body__c = 'Please answer';
            testOutboundMessages.add(testMessageOutbound);

            pendulaId++;

            Pendula__Message__c testMessageInboundOptOut = TestData.createPendulaMessage('Inbound', 'SMS', String.valueOf(pendulaId), null, testSurvey.Recipient__r.Id, Datetime.now().addMinutes(1));
            testMessageInboundOptOut.RecordTypeId = Schema.SObjectType.Pendula__Message__c.getRecordTypeInfosByDeveloperName().get('Inbound_SMS').getRecordTypeId();
            testMessageInboundOptOut.Pendula__SMS_Body__c = '11';
            testMessageInboundOptOut.Pendula__SMS_From_Number__c = testSurvey.Recipient__r.MobilePhone;
            testInboundMessages.add(testMessageInboundOptOut);

            pendulaId++;
        }
        insert testOutboundMessages;
        insert testInboundMessages;

        System.assertEquals(
                5,
        [SELECT COUNT() FROM Customer_Feedback_Survey__c WHERE Unrecognised_Response__c != NULL],
                'Failed to populate Unrecognised_Response__c for invalid number response'
        );
    }

    @IsTest
    public static void validateInvalidTextResponse() {

        List<Customer_Feedback_Survey__c> testSurveys = [SELECT Id,Recipient__r.Id,Recipient__r.MobilePhone FROM Customer_Feedback_Survey__c];
        List<Survey_Settings__c> testSettings = [SELECT Id,Flow_Name__c,Flow_Id__c FROM Survey_Settings__c];

        List<Pendula__Message__c> testOutboundMessages = new List<Pendula__Message__c>();
        List<Pendula__Message__c> testInboundMessages = new List<Pendula__Message__c>();

        Integer pendulaId = 123;
        for (Customer_Feedback_Survey__c testSurvey : testSurveys) {

            Pendula__Message__c testMessageOutbound = TestData.createPendulaMessage('Outbound', 'SMS', String.valueOf(pendulaId), testSurvey.Id, testSurvey.Recipient__r.Id, Datetime.now());
            testMessageOutbound.Pendula__Flow_Id__c = testSettings[0].Flow_Id__c;
            testMessageOutbound.RecordTypeId = Schema.SObjectType.Pendula__Message__c.getRecordTypeInfosByDeveloperName().get('Outbound_SMS').getRecordTypeId();
            testMessageOutbound.Pendula__SMS_To_Number__c = testSurvey.Recipient__r.MobilePhone;
            testMessageOutbound.Pendula__SMS_Body__c = 'Please answer';
            testOutboundMessages.add(testMessageOutbound);

            pendulaId++;

            Pendula__Message__c testMessageInboundOptOut = TestData.createPendulaMessage('Inbound', 'SMS', String.valueOf(pendulaId), null, testSurvey.Recipient__r.Id, Datetime.now().addMinutes(1));
            testMessageInboundOptOut.RecordTypeId = Schema.SObjectType.Pendula__Message__c.getRecordTypeInfosByDeveloperName().get('Inbound_SMS').getRecordTypeId();
            testMessageInboundOptOut.Pendula__SMS_Body__c = 'Thank you';
            testMessageInboundOptOut.Pendula__SMS_From_Number__c = testSurvey.Recipient__r.MobilePhone;
            testInboundMessages.add(testMessageInboundOptOut);

            pendulaId++;
        }
        insert testOutboundMessages;
        insert testInboundMessages;

        System.assertEquals(
                5,
        [SELECT COUNT() FROM Customer_Feedback_Survey__c WHERE Unrecognised_Response__c != NULL],
                'Failed to populate Unrecognised_Response__c for invalid text response'
        );
    }

    @IsTest
    public static void validateOptOutResponse() {

        List<Customer_Feedback_Survey__c> testSurveys = [SELECT Id,Recipient__r.Id,Recipient__r.MobilePhone FROM Customer_Feedback_Survey__c];
        List<Survey_Settings__c> testSettings = [SELECT Id,Flow_Name__c,Flow_Id__c FROM Survey_Settings__c];

        List<Pendula__Message__c> testOutboundMessages = new List<Pendula__Message__c>();
        List<Pendula__Message__c> testInboundMessages = new List<Pendula__Message__c>();

        Integer pendulaId = 123;
        for (Customer_Feedback_Survey__c testSurvey : testSurveys) {

            Pendula__Message__c testMessageOutbound = TestData.createPendulaMessage('Outbound', 'SMS', String.valueOf(pendulaId), testSurvey.Id, testSurvey.Recipient__r.Id, Datetime.now());
            testMessageOutbound.Pendula__Flow_Id__c = testSettings[0].Flow_Id__c;
            testMessageOutbound.RecordTypeId = Schema.SObjectType.Pendula__Message__c.getRecordTypeInfosByDeveloperName().get('Outbound_SMS').getRecordTypeId();
            testMessageOutbound.Pendula__SMS_To_Number__c = testSurvey.Recipient__r.MobilePhone;
            testMessageOutbound.Pendula__SMS_Body__c = 'Please answer';
            testOutboundMessages.add(testMessageOutbound);

            pendulaId++;

            Pendula__Message__c testMessageInboundOptOut = TestData.createPendulaMessage('Inbound', 'SMS', String.valueOf(pendulaId), null, testSurvey.Recipient__r.Id, Datetime.now().addMinutes(1));
            testMessageInboundOptOut.RecordTypeId = Schema.SObjectType.Pendula__Message__c.getRecordTypeInfosByDeveloperName().get('Inbound_SMS').getRecordTypeId();
            testMessageInboundOptOut.Pendula__SMS_Body__c = 'STOP';
            testMessageInboundOptOut.Pendula__SMS_From_Number__c = testSurvey.Recipient__r.MobilePhone;
            testInboundMessages.add(testMessageInboundOptOut);

            pendulaId++;
        }
        insert testOutboundMessages;
        insert testInboundMessages;

        System.assertEquals(
                5,
        [SELECT COUNT() FROM Customer_Feedback_Survey__c WHERE Unrecognised_Response__c = NULL],
                'Unrecognised_Response__c should not be populated for Opt-out'
        );
    }

    @IsTest
    public static void validateMultipleIncompleteSurveys() {

        List<Survey_Settings__c> testSurveySettings = [SELECT Id,Flow_Id__c FROM Survey_Settings__c];

        Contact testClient = [
                SELECT Id,MobilePhone FROM Contact
                WHERE RecordTypeId = :Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Client').getRecordTypeId()
        ][0];

        enrtcr__Session__c testSession = [SELECT Id FROM enrtcr__Session__c][0];

        List<Customer_Feedback_Survey__c> testSurveys = new List<Customer_Feedback_Survey__c>();
        for (Integer i = 0; i <3 ; i++) {

            testSurveys.add(
                    new Customer_Feedback_Survey__c(
                            Session__c = testSession.Id,
                            Recipient__c = testClient.Id,
                            First_Question_Sent__c = Datetime.now()
                    )
            );
        }
        insert testSurveys;

        testSurveys = [SELECT Id FROM Customer_Feedback_Survey__c WHERE Recipient__c = :testClient.Id];

        List<Pendula__Message__c> testOutboundMessages = new List<Pendula__Message__c>();
        List<Pendula__Message__c> testInboundMessages = new List<Pendula__Message__c>();

        Integer pendulaId = 123;

        for (Customer_Feedback_Survey__c testSurvey : testSurveys) {

            for (Integer i = 0; i < testSurveySettings.size() ; i++) {

                Pendula__Message__c testMessageOutbound = TestData.createPendulaMessage('Outbound', 'SMS', String.valueOf(pendulaId), testSurvey.Id, testClient.Id, Datetime.now());
                testMessageOutbound.Pendula__Flow_Id__c = testSurveySettings[i].Flow_Id__c;
                testMessageOutbound.RecordTypeId = Schema.SObjectType.Pendula__Message__c.getRecordTypeInfosByDeveloperName().get('Outbound_SMS').getRecordTypeId();
                testMessageOutbound.Pendula__SMS_To_Number__c = testClient.MobilePhone;
                testMessageOutbound.Pendula__SMS_Body__c = 'Please answer';
                testOutboundMessages.add(testMessageOutbound);

                pendulaId++;
            }
        }

        List<Customer_Feedback_Survey__c> surveys = [select id,Survey_is_Completed__c from Customer_Feedback_Survey__c where Id in :testSurveys];
        for (Integer i = 0; i < 3; i++) {

            surveys[i].Survey_is_Completed__c = true;
        }
        update surveys;

        pendulaId++;

        Pendula__Message__c testMessageInboundOptOut = TestData.createPendulaMessage('Inbound', 'SMS', String.valueOf(pendulaId), null, testClient.Id, Datetime.now().addMinutes(1));
        testMessageInboundOptOut.RecordTypeId = Schema.SObjectType.Pendula__Message__c.getRecordTypeInfosByDeveloperName().get('Inbound_SMS').getRecordTypeId();
        testMessageInboundOptOut.Pendula__SMS_Body__c = 'hey';
        testMessageInboundOptOut.Pendula__SMS_From_Number__c = testClient.MobilePhone;
        testInboundMessages.add(testMessageInboundOptOut);

        insert testOutboundMessages;
        insert testInboundMessages;

        System.assertEquals(
                1,
        [SELECT COUNT() FROM Customer_Feedback_Survey__c WHERE Unrecognised_Response__c != NULL],
                'There should be only 1 incomplete survey for 1 client'
        );
    }*/
}