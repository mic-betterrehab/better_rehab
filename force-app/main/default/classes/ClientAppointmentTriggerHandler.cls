/**
 * Created by me on 17/07/2019.
 */

public with sharing class ClientAppointmentTriggerHandler implements ITrigger
{
    private List<enrtcr__Client_Appointment__c> newClientSessions = new List<enrtcr__Client_Appointment__c>();

    public void bulkBefore()
    {
    }

    public void bulkAfter()
    {
    }

    public void beforeInsert(SObject so)
    {
    }

    public void beforeUpdate(SObject oldSo, SObject so)
    {
    }

    public void beforeDelete(SObject so)
    {
    }

    public void afterInsert(SObject so)
    {
        enrtcr__Client_Appointment__c newValue = (enrtcr__Client_Appointment__c)so;
        if(newValue.Initial_Assessment__c &&
                newValue.Session_Status__c == SessionTriggerHandler.ROSTERED)
        {
            newClientSessions.add(newValue);
        }
    }

    public void afterUpdate(SObject oldSo, SObject so)
    {
    }

    public void afterDelete(SObject so)
    {
    }

    public void andFinally()
    {
        if(!newClientSessions.isEmpty())
        {
            SessionTaskFactory.createTasks(newClientSessions);
            newClientSessions = new List<enrtcr__Client_Appointment__c>();
        }
    }
}