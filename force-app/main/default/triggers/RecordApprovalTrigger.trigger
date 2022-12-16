trigger RecordApprovalTrigger on Record_Approval__c (before insert, before update, before delete, after insert, after update, after delete) {
    TriggerHandler.createHandler(Record_Approval__c.SObjectType);
}