/**
 * Created by ersoz on 13/11/20.
 */

trigger CustomerFeedbackSurveyTrigger on Customer_Feedback_Survey__c (after insert, after delete, after undelete) {

    new CustomerFeedbackSurveyTriggerHandler(Trigger.newMap, Trigger.oldMap, Trigger.operationType);
}