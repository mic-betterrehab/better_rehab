//this class is a test for the edited MessageTriggerHandler
@isTest
public class BR_MessageTriggerHandlerTest {
    
    @TestSetup
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
                
        User x = [SELECT id FROM User WHERE IsActive = TRUE AND ProfileId =: [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1] limit 1];
        
        //create site
        enrtcr__Site__c newSite = TestObjects.createSite(2);
        newSite.Office_Admin__c = x.Id;
        insert newSite;
        
        List<Contact> listOfContacts = new List<Contact>();
        
        //create 1 worker
        Contact newWorker = TestObjects.createContact(6, 'NDIS');       
        listOfContacts.add(newWorker);        
        
        //create 1 client
        Contact newClient = TestObjects.createContact(1, 'NDIS');
        listOfContacts.add(newClient);
        
        insert listOfContacts;     
        
        //create an event
        Event newEvent = TestObjects.createEvent('Initial Appointment', 'Booked', x);        
        insert newEvent;
        
        //create a CER
        Client_Event_Relation__c newCER = TestObjects.createCER('Booked', newClient, newEvent);    
        insert newCER;
        
        //create an ER - no status here for now
        EventRelation newER = TestObjects.createER(newWorker, newEvent);
		insert newER; 
        
        //create 5 initial surveys
        List<Feedback_Survey__c> testFS = new List<Feedback_Survey__c>();
        for (Integer i = 0; i < 5 ; i++) {
            testFS.add(
                new Feedback_Survey__c(
                    RecordTypeId = Schema.SObjectType.Feedback_Survey__c.getRecordTypeInfosByDeveloperName().get('Initial_Client_Survey').getRecordTypeId(),
                    Client_Event_Relation__c = newCER.Id,
                    Recipient__c = newClient.Id,
                    Survey_Sent_Time__c = Datetime.now(),
                    Event_Subject__c = newEvent.Subject, Event_Start_DateTime__c = newEvent.StartDateTime, Event_End_DateTime__c = newEvent.EndDateTime
                )
            );            
        }
        
        insert testFS;
    }
    
    @IsTest
    public static void validateValidResponse() {
        
        List<Feedback_Survey__c> testSurveys = [SELECT Id,Recipient__r.Id,Recipient__r.MobilePhone FROM Feedback_Survey__c];
        List<Survey_Settings__c> testSettings = [SELECT Id,Flow_Name__c,Flow_Id__c FROM Survey_Settings__c];
        
        List<Pendula__Message__c> testOutboundMessages = new List<Pendula__Message__c>();
        List<Pendula__Message__c> testInboundMessages = new List<Pendula__Message__c>();
        
        Integer pendulaId = 123;
        for (Feedback_Survey__c testSurvey : testSurveys) {
            
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
            [SELECT COUNT() FROM Feedback_Survey__c WHERE Unrecognised_Response__c = NULL],
            'Unrecognised_Response__c should not be populated for valid response'
        );
    }
    
    @IsTest
    public static void validateNullResponse() {
        
        List<Feedback_Survey__c> testSurveys = [SELECT Id,Recipient__r.Id,Recipient__r.MobilePhone FROM Feedback_Survey__c];
        List<Survey_Settings__c> testSettings = [SELECT Id,Flow_Name__c,Flow_Id__c FROM Survey_Settings__c];
        
        List<Pendula__Message__c> testOutboundMessages = new List<Pendula__Message__c>();
        List<Pendula__Message__c> testInboundMessages = new List<Pendula__Message__c>();
        
        Integer pendulaId = 123;
        for (Feedback_Survey__c testSurvey : testSurveys) {
            
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
            [SELECT COUNT() FROM Feedback_Survey__c WHERE Unrecognised_Response__c != NULL],
            'Failed to populate Unrecognised_Response__c for null response'
        );
    }
    
    @IsTest
    public static void validateInvalidNumberResponse() {
        
        List<Feedback_Survey__c> testSurveys = [SELECT Id,Recipient__r.Id,Recipient__r.MobilePhone FROM Feedback_Survey__c];
        List<Survey_Settings__c> testSettings = [SELECT Id,Flow_Name__c,Flow_Id__c FROM Survey_Settings__c];
        
        List<Pendula__Message__c> testOutboundMessages = new List<Pendula__Message__c>();
        List<Pendula__Message__c> testInboundMessages = new List<Pendula__Message__c>();
        
        Integer pendulaId = 123;
        for (Feedback_Survey__c testSurvey : testSurveys) {
            
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
            [SELECT COUNT() FROM Feedback_Survey__c WHERE Unrecognised_Response__c != NULL],
            'Failed to populate Unrecognised_Response__c for invalid number response'
        );
    }
    
    @IsTest
    public static void validateInvalidTextResponse() {
        
        List<Feedback_Survey__c> testSurveys = [SELECT Id,Recipient__r.Id,Recipient__r.MobilePhone FROM Feedback_Survey__c];
        List<Survey_Settings__c> testSettings = [SELECT Id,Flow_Name__c,Flow_Id__c FROM Survey_Settings__c];
        
        List<Pendula__Message__c> testOutboundMessages = new List<Pendula__Message__c>();
        List<Pendula__Message__c> testInboundMessages = new List<Pendula__Message__c>();
        
        Integer pendulaId = 123;
        for (Feedback_Survey__c testSurvey : testSurveys) {
            
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
            [SELECT COUNT() FROM Feedback_Survey__c WHERE Unrecognised_Response__c != NULL],
            'Failed to populate Unrecognised_Response__c for invalid text response'
        );
    }
    
    @IsTest
    public static void validateOptOutResponse() {
        
        List<Feedback_Survey__c> testSurveys = [SELECT Id,Recipient__r.Id,Recipient__r.MobilePhone FROM Feedback_Survey__c];
        List<Survey_Settings__c> testSettings = [SELECT Id,Flow_Name__c,Flow_Id__c FROM Survey_Settings__c];
        
        List<Pendula__Message__c> testOutboundMessages = new List<Pendula__Message__c>();
        List<Pendula__Message__c> testInboundMessages = new List<Pendula__Message__c>();
        
        Integer pendulaId = 123;
        for (Feedback_Survey__c testSurvey : testSurveys) {
            
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
            [SELECT COUNT() FROM Feedback_Survey__c WHERE Unrecognised_Response__c = NULL],
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
        
        Client_Event_Relation__c testCER = [SELECT Id FROM Client_Event_Relation__c][0];
        Event testEvent = [SELECT Id, Subject, StartDateTime, EndDateTime FROM Event][0];
        
        List<Feedback_Survey__c> testSurveys = new List<Feedback_Survey__c>();
        for (Integer i = 0; i <3 ; i++) {
            
            testSurveys.add(
                new Feedback_Survey__c(
                    RecordTypeId = Schema.SObjectType.Feedback_Survey__c.getRecordTypeInfosByDeveloperName().get('Initial_Client_Survey').getRecordTypeId(),
					Client_Event_Relation__c = testCER.Id,
                    Recipient__c = testClient.Id,
                    Survey_Sent_Time__c = Datetime.now(),
					Event_Subject__c = testEvent.Subject, Event_Start_DateTime__c = testEvent.StartDateTime, Event_End_DateTime__c = testEvent.EndDateTime
                )
            );
        }
        insert testSurveys;
        
        testSurveys = [SELECT Id FROM Feedback_Survey__c WHERE Recipient__c = :testClient.Id];
        
        List<Pendula__Message__c> testOutboundMessages = new List<Pendula__Message__c>();
        List<Pendula__Message__c> testInboundMessages = new List<Pendula__Message__c>();
        
        Integer pendulaId = 123;
        
        for (Feedback_Survey__c testSurvey : testSurveys) {
            
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
        
        List<Feedback_Survey__c> surveys = [select id,Survey_is_Completed__c from Feedback_Survey__c where Id in :testSurveys];
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
            5,
            [SELECT COUNT() FROM Feedback_Survey__c WHERE Unrecognised_Response__c != NULL],
            'There should be 5 incomplete survey for 1 client'
        );
    }
}