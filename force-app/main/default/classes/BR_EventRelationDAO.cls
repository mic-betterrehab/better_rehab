public with sharing class BR_EventRelationDAO {
    public static List<EventRelation> getWorkerEventsByIds(Set<Id> ids) {
        DateTime cutoff = System.today() - 120;
        return [
            SELECT
                Id,
                Status,
                RelationId,
                Event.Id,
                Event.OwnerId,
                Event.enrtcr__Client__c,
                Event.StartDateTime,
                Event.EndDateTime,
                Event.Event_Type__c,
                Event.Event_Status__c,
                Event.Subject,
                Event.IsAllDayEvent,
                Event.isRecurrence__c,
                Event.Event_Recurrence__c
            FROM EventRelation
            WHERE RelationId IN: ids
            AND Event.StartDateTime >: cutoff
            AND Event.RecordTypeId =: Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('BR_Event').getRecordTypeId()
        ];
    }

    public static List<EventRelation> getWorkerLastNextSevenDaysEventsById(Set<Id> ids, String today) {
        DateTime dt = (DateTime)JSON.deserialize('"' + today + '"', DateTime.class);
        DateTime lastSevenDays = dt - 7;
        DateTime nextSevenDays = dt + 7;
        return [
            SELECT
                Id,
                Status,
                RelationId,
                Event.Id,
                Event.OwnerId,
                Event.enrtcr__Client__c,
                Event.StartDateTime,
                Event.EndDateTime,
                Event.Event_Type__c,
                Event.Event_Status__c,
                Event.Subject,
                Event.IsAllDayEvent,
                Event.isRecurrence__c,
                Event.Event_Recurrence__c
            FROM EventRelation
            WHERE RelationId IN: ids
            AND Event.StartDateTime >: lastSevenDays
            AND Event.StartDateTime <: nextSevenDays
            AND Event.RecordTypeId =: Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('BR_Event').getRecordTypeId()
        ];
    }

    public static List<EventRelation> getWorkerEventsByDate(Set<Id> ids, String startDate, String endDate) {
        Datetime startEvent = (DateTime)JSON.deserialize('"' + startDate + '"', DateTime.class);
        Datetime endEvent = (DateTime)JSON.deserialize('"' + endDate + '"', DateTime.class);
        return [
            SELECT
                Id,
                Status,
                RelationId,
                Event.Id,
                Event.OwnerId,
                Event.enrtcr__Client__c,
                Event.StartDateTime,
                Event.EndDateTime,
                Event.Event_Type__c,
                Event.Event_Status__c,
                Event.Subject,
                Event.IsAllDayEvent,
                Event.isRecurrence__c,
                Event.Event_Recurrence__c
            FROM EventRelation
            WHERE RelationId IN: ids
            AND Event.StartDateTime >=: startEvent
            AND Event.StartDateTime <=: endEvent
            AND Event.RecordTypeId =: Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('BR_Event').getRecordTypeId()
        ];
    }
}