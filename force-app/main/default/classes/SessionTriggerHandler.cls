/**
 * Created by me on 17/07/2019.
 * Modified by Jarrah Nott on 14/07/2020.
 */

public with sharing class SessionTriggerHandler implements ITrigger
{
    public static final String ROSTERED = 'Rostered';

    private Set<ID> updateDatesSessionIds = new Set<ID>();
    private Set<ID> newTaskSessionIds = new Set<ID>();

    public void bulkBefore()
    {
        List<enrtcr__Session__c> mapOldSessions = (List<enrtcr__Session__c>) Trigger.old;
        List<enrtcr__Session__c> mapNewSessions = (List<enrtcr__Session__c>) Trigger.new;

        if (Trigger.isUpdate || Trigger.isInsert) populateSessionRegionBasedOnState(mapOldSessions, mapNewSessions);
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
    }

    public void afterUpdate(SObject oldSo, SObject so)
    {
        enrtcr__Session__c newValue = (enrtcr__Session__c)so;
        enrtcr__Session__c oldValue = (enrtcr__Session__c)oldSo;

        Boolean initialAssessment = newValue.enrtcr__Service_Types__c != null &&
                newValue.enrtcr__Service_Types__c.contains('Initial Assessment');

        if(initialAssessment &&
                (oldValue.enrtcr__Service_Types__c != newValue.enrtcr__Service_Types__c) ||
                (oldValue.enrtcr__Status__c != ROSTERED &&
                newValue.enrtcr__Status__c == ROSTERED))
        {
            newTaskSessionIds.add(newValue.ID);
        }
        else if(newValue.enrtcr__Start_Date__c != null &&
                    newValue.enrtcr__Start_Date__c != oldValue.enrtcr__Start_Date__c)
        {
            updateDatesSessionIds.add(newValue.ID);
        }
    }

    public void afterDelete(SObject so)
    {
    }

    public void andFinally()
    {
        if(!newTaskSessionIds.isEmpty())
        {
            SessionTaskFactory.createTasks(newTaskSessionIds);
            newTaskSessionIds = new Set<ID>();
        }
        if(!updateDatesSessionIds.isEmpty())
        {
            SessionTaskFactory.updateTaskDueDates(updateDatesSessionIds);
            updateDatesSessionIds = new Set<ID>();
        }
    }


    private static void populateSessionRegionBasedOnState(List<enrtcr__Session__c> oldSessions, List<enrtcr__Session__c> newSessions)
    {
        List<enrtcr__Session__c> sessionsToProcess = getSessionsToProcess(oldSessions, newSessions);
        Set<String> stateNames = getStateNames(sessionsToProcess);

        Map<String, enrtcr__Reference_Data__c> mapStateNameReferenceData = getReferenceDataByStateName(stateNames);
        for (enrtcr__Session__c session : sessionsToProcess)
        {
            if (!mapStateNameReferenceData.containsKey(session.enrtcr__Other_State__c)) continue;

            session.enrtcr__Session_Region__c = mapStateNameReferenceData.get(session.enrtcr__Other_State__c).Id;
        }

    }

    private static Set<String> getStateNames(List<enrtcr__Session__c> sessions)
    {
        Set<String> stateNames = new Set<String>();
        for (enrtcr__Session__c session : sessions)
        {
            stateNames.add(session.enrtcr__Other_State__c);
        }
        return stateNames;
    }

    private static List<enrtcr__Session__c> getSessionsToProcess(List<enrtcr__Session__c> oldSessions, List<enrtcr__Session__c> newSessions)
    {
        Boolean isUpdate = oldSessions != null && !oldSessions.isEmpty();
        List<enrtcr__Session__c> sessionsToProcess = new List<enrtcr__Session__c>();
        Integer i = 0;
        for (enrtcr__Session__c newSession : newSessions)
        {
            enrtcr__Session__c oldSession =  isUpdate? oldSessions[0] : null;
            Boolean insertCriteria = String.isNotBlank(newSession.enrtcr__Other_State__c);
            if (oldSession != null && insertCriteria && (oldSession.enrtcr__Other_State__c != newSession.enrtcr__Other_State__c || String.isBlank(newSession.enrtcr__Session_Region__c)) || insertCriteria)
            {
                sessionsToProcess.add(newSession);
            }

            i++;
        }
        return sessionsToProcess;
    }

    private static Map<String, enrtcr__Reference_Data__c> getReferenceDataByStateName(Set<String> stateNames)
    {
        Map<String, enrtcr__Reference_Data__c> mapStateNameReferenceData = new Map<String, enrtcr__Reference_Data__c>();
        for (enrtcr__Reference_Data__c referenceData : [
                SELECT Id, Name, enrtcr__State__c
                FROM enrtcr__Reference_Data__c
                WHERE RecordTypeId = :enrtcr__Reference_Data__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Session_Region').recordTypeId
                AND Name IN :stateNames
        ])
        {
            mapStateNameReferenceData.put(referenceData.Name, referenceData);
        }

        return mapStateNameReferenceData;
    }
}