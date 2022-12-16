trigger ServiceDeliveredTrigger on enrtcr__Support_Delivered__c (before insert, before update, before delete, after insert, after update, after delete)
{
    TriggerHandler.createHandler(enrtcr__Support_Delivered__c.SObjectType);
}