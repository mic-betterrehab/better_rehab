/**
 * Created by ersoz on 15/11/20.
 */

@IsTest
public with sharing class CustomerFeedbackSurveyTriggerHandlerTest {

    @TestSetup
    public static void setup(){

        List<Contact> testClients = new List<Contact>();
        for (Integer i = 0; i < 3 ; i++) {

            testClients.add(
                    TestData.createTestContact()
            );
        }
        insert testClients;

        enrtcr__Session__c testSession = TestData.createTestSession(null, 'Draft', null, null, null);
        insert testSession;

        List<Customer_Feedback_Survey__c> testSurveys = new List<Customer_Feedback_Survey__c>();

        for (Contact testClient : testClients) {

            testSurveys.add(
                    new Customer_Feedback_Survey__c(
                            Session__c = testSession.Id,
                            Recipient__c = testClient.Id,
                            First_Question_Sent__c = Datetime.now()
                    )
            );
        }
        insert testSurveys;
    }

    @IsTest
    public static void validateInsert(){

        System.assertEquals(
                1,
        [SELECT Id,Number_Of_Survey_Sent__c FROM Contact][0].Number_Of_Survey_Sent__c,
                'Failed to populate Number_Of_Survey_Sent__c'
        );

        System.assertEquals(
                1,
                [SELECT Id,Number_Of_Survey_Sent__c FROM Contact][1].Number_Of_Survey_Sent__c,
                'Failed to populate Number_Of_Survey_Sent__c'
        );

        System.assertEquals(
                1,
                [SELECT Id,Number_Of_Survey_Sent__c FROM Contact][2].Number_Of_Survey_Sent__c,
                'Failed to populate Number_Of_Survey_Sent__c'
        );
    }

    @IsTest
    public static void validateDeleteAndUndelete(){

        List<Contact> clients = [SELECT Id,Number_Of_Survey_Sent__c FROM Contact];

        enrtcr__Session__c testSession = [SELECT Id FROM enrtcr__Session__c];

        List<Customer_Feedback_Survey__c> surveys = new List<Customer_Feedback_Survey__c>();
        for (Integer i = 0; i < 9; i++) {

            surveys.add(
                    new Customer_Feedback_Survey__c(
                            Session__c = testSession.Id,
                            Recipient__c = clients[2].Id,
                            First_Question_Sent__c = Datetime.now()
                    )
            );
        }
        insert surveys;

        Contact testClient = [SELECT Id,Number_Of_Survey_Sent__c FROM Contact WHERE Id =:clients[2].Id];

        System.assertEquals(
                10,
                testClient.Number_Of_Survey_Sent__c,
                'Failed to populate Number_Of_Survey_Sent__c'
        );

        List<Customer_Feedback_Survey__c> surveysToDelete = new List<Customer_Feedback_Survey__c>();
        for (Integer i = 0; i < 8; i++) {

            surveysToDelete.add(
                    surveys[i]
            );
        }
        delete surveysToDelete;

        testClient = [SELECT Id,Number_Of_Survey_Sent__c FROM Contact WHERE Id =:clients[2].Id];

        System.assertEquals(
                2,
                testClient.Number_Of_Survey_Sent__c,
                'Failed to update Number_Of_Survey_Sent__c after delete'
        );

        undelete surveysToDelete;

        testClient = [SELECT Id,Number_Of_Survey_Sent__c FROM Contact WHERE Id =:clients[2].Id];

        System.assertEquals(
                10,
                testClient.Number_Of_Survey_Sent__c,
                'Failed to recover Number_Of_Survey_Sent__c after undelete'
        );
    }
}