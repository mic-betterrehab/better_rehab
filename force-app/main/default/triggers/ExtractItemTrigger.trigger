trigger ExtractItemTrigger on enrtcr__Extract_Item__c (before insert, before update, before delete, after insert, after update, after delete)
{
    TriggerHandler.createHandler(enrtcr__Extract_Item__c.SObjectType);
}