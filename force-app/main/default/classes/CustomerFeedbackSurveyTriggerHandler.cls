/**
 * Created by ersoz on 13/11/20.
 * Populates the Number of surveys Sent field on corresponding Contact record.
 */

public with sharing class CustomerFeedbackSurveyTriggerHandler {

    Map<Id,Customer_Feedback_Survey__c> newMap;
    Map<Id,Customer_Feedback_Survey__c> oldMap;

    public CustomerFeedbackSurveyTriggerHandler(
            Map<Id,Customer_Feedback_Survey__c> newMap,
            Map<Id,Customer_Feedback_Survey__c> oldMap,
            System.TriggerOperation operationType
    ){

        this.newMap = newMap;
        this.oldMap = oldMap;

        processTriggerContext(operationType);
    }

    private void processTriggerContext(System.TriggerOperation operationType){

        if(operationType == System.TriggerOperation.AFTER_INSERT || operationType == System.TriggerOperation.AFTER_UNDELETE){

            afterInsert();
        }
        else if (operationType == System.TriggerOperation.AFTER_DELETE){

            afterDelete();
        }
    }

    private void afterInsert() {

        Set<Id> recipientIds = new Set<Id>();

        for(Customer_Feedback_Survey__c newSurvey : newMap.values()) {

            recipientIds.add(newSurvey.Recipient__c);
        }

        process(recipientIds);
    }

    private void afterDelete() {

        Set<Id> recipientIds = new Set<Id>();

        for(Customer_Feedback_Survey__c newSurvey : oldMap.values()) {

            recipientIds.add(newSurvey.Recipient__c);
        }
//        system.debug('recipientIds delete ==> '+recipientIds);

        process(recipientIds);

    }

    private void process(Set<Id> recipientIds){

        Map<Id,List<Customer_Feedback_Survey__c>> contactIdToSurveys = new Map<Id, List<Customer_Feedback_Survey__c>>();

//        system.debug('SURVEYS delete ==> '+[select Id,Recipient__c from Customer_Feedback_Survey__c]);


        for (Customer_Feedback_Survey__c newSurvey : [select Id,Recipient__c from Customer_Feedback_Survey__c where Recipient__c IN :recipientIds]){
//            system.debug('newSurvey delete ==> '+newSurvey);

            List<Customer_Feedback_Survey__c> surveys = contactIdToSurveys.get(newSurvey.Recipient__c);

            if(surveys == null){

                surveys = new List<Customer_Feedback_Survey__c>();

                contactIdToSurveys.put(newSurvey.Recipient__c, surveys);
            }
            surveys.add(newSurvey);
        }

//        system.debug('contactIdToSurveys delete ==> '+contactIdToSurveys);

        List<Contact> clientsToUpdate = new List<Contact>();

        for (Contact newClient : [SELECT Id,Number_Of_Survey_Sent__c FROM Contact WHERE Id IN : recipientIds]){

            List<Customer_Feedback_Survey__c> surveys = contactIdToSurveys.get(newClient.Id);

//            system.debug('surveys delete ==> '+surveys);

            if(surveys != null) {

                newClient.Number_Of_Survey_Sent__c = surveys.size();
                clientsToUpdate.add(newClient);
            }
        }

        if(!clientsToUpdate.isEmpty()) update clientsToUpdate;
    }
}