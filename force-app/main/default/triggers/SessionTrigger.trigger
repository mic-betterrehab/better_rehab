/**
 * Created by me on 17/07/2019.
 */

trigger SessionTrigger on enrtcr__Session__c (before insert, before update, before delete, after insert, after update, after delete)
{
    TriggerHandler.createHandler(enrtcr__Session__c.SObjectType);
}