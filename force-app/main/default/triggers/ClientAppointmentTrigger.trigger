/**
 * Created by me on 17/07/2019.
 */

trigger ClientAppointmentTrigger on enrtcr__Client_Appointment__c (before insert, before update, before delete, after insert, after update, after delete)
{
    TriggerHandler.createHandler(enrtcr__Client_Appointment__c.SObjectType);
}