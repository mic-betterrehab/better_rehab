/**
 * Created by me on 17/07/2019.
 */

public with sharing class WorkerAppointmentTriggerHandler implements ITrigger
{
    private List<enrtcr__Worker_Appointment__c> newWorkerAppointments = new List<enrtcr__Worker_Appointment__c>();

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
        enrtcr__Worker_Appointment__c newValue = (enrtcr__Worker_Appointment__c)so;
        if(newValue.Initial_Assessment__c &&
                newValue.enrtcr__Session_Status__c == SessionTriggerHandler.ROSTERED)
        {
            newWorkerAppointments.add(newValue);
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
        if(!newWorkerAppointments.isEmpty())
        {
            SessionTaskFactory.createTasks(newWorkerAppointments);
            newWorkerAppointments = new List<enrtcr__Worker_Appointment__c>();
        }
    }
}