public class CreateClinicianTasksBatch implements Database.batchable<sObject>
{
    public Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator([SELECT id, name,enrtcr__Start_Date__c, enrtcr__Worker__c, enrtcr__Worker__r.enrtcr__User__c,enrtcr__Session__r.enrtcr__Service_Types__c, enrtcr__Session__r.enrtcr__Status__c, enrtcr__Shift__r.enrtcr__Published__c
                                            FROM enrtcr__Worker_Appointment__c
                                        WHERE enrtcr__Session__r.enrtcr__Service_Types__c INCLUDES ('Initial Assessment','Followup Assessment')
                                            AND enrtcr__Session__r.enrtcr__Status__c = 'Rostered'
                                            AND enrtcr__Shift__r.enrtcr__Published__c = true
                                            AND (enrtcr__Start_Date__c <= NEXT_N_DAYS:2 AND enrtcr__Start_Date__c > TODAY)
                                            AND Task_Created__c = false]);
    }

    public void execute(Database.BatchableContext info, List<enrtcr__Worker_Appointment__c> scope)
    {
        List<Task> tasksTopAdd = new List<Task>();
        List<enrtcr__Worker_Appointment__c> aptToUpdate = new List<enrtcr__Worker_Appointment__c>();
        Set<Id> sessionIds = new Set<Id>();

        for(enrtcr__Worker_Appointment__c wa : scope)
        {
            sessionIds.add(wa.enrtcr__Session__c);
        }

        //Get list of clients per session
        List<enrtcr__Client_Appointment__c> clientAptList = new List<enrtcr__Client_Appointment__c>();
        Map<Id,List<enrtcr__Client_Appointment__c>> clientAptsForSessionMap = new Map<Id,List<enrtcr__Client_Appointment__c>>();
        Id oldSessionId = null;

        for(enrtcr__Client_Appointment__c ca : [SELECT Id,enrtcr__Client__c,enrtcr__Session__c FROM enrtcr__Client_Appointment__c WHERE enrtcr__Session__c IN :sessionIds ORDER BY enrtcr__Session__c])
        {
            if(oldSessionId != ca.enrtcr__Session__c)
            {
                if(oldSessionId != null)
                {
                    clientAptsForSessionMap.put(oldSessionId,clientAptList);
                }
                clientAptList = new List<enrtcr__Client_Appointment__c>();
                clientAptList.add(ca);
                oldSessionId = ca.enrtcr__Session__c;
            }
            else
            {
                clientAptList.add(ca);
            }

        }
        if(clientAptList.size()> 0)
        {
            clientAptsForSessionMap.put(oldSessionId, clientAptList);
        }

        //MAIN LOOP
        for(enrtcr__Worker_Appointment__c wa : scope)
        {
            if(clientAptsForSessionMap.containsKey(wa.enrtcr__Session__c))
            {
                List<enrtcr__Client_Appointment__c> clientAptForSessionList = clientAptsForSessionMap.get(wa.enrtcr__Session__c);

                for(enrtcr__Client_Appointment__c ca : clientAptForSessionList)
                {
                    Task t = new Task();
                    t.Subject= 'Assign yourself to new client as their clinician';
                    t.Status ='Not Started';
                    t.Priority = 'High';
                    t.OwnerId = wa.enrtcr__Worker__r.enrtcr__User__c;
                    t.WhatId = wa.Id;
                    t.WhoId = ca.enrtcr__Client__c;
                    t.ActivityDate = wa.enrtcr__Start_Date__c.date();
                    t.Type = 'Other';

                    tasksTopAdd.add(t);
                }

                wa.Task_Created__c = true;
                aptToUpdate.add(wa);
            }
        }

        INSERT tasksTopAdd;
        UPDATE aptToUpdate;
    }

    public void finish(Database.BatchableContext info)
    {

    }
}