public class BR_CalendarClashController {
    /*Class Worker {
        String Id;
        String Name;
    }
    
    Class Client {
        String Id;
        String Name;
    }
    
    Class EventDetail {
        String subject;
        String startTime; 
        String endTime;
        String eventType;
        String clients;
        String workers;
        String serviceId;
        String address;
        String status;
        Boolean allDay;
        Boolean reengagement;
    }
    
    Class RepeatDetail {
        Boolean repeat;
        String repeatFrequency;
        String	repeatTime;
        String	onAfter;
        String	numberEvents;
        Date	onDate;
    }
    
    //take in a list of sobjects(contact) - v.clients and string of starttime and endtime
    @AuraEnabled
    public static String[] findClashingWorkerAndClientEvents(String eventJSON, String repeatJSON){
        
        Contact contactToShareEvent = [SELECT Id FROM Contact WHERE LastName = 'to share events'];
        
        Set<String> setOfClashingWorkersAndClients = new Set<String>();  
        
        // parse event details
        EventDetail eventObject = (EventDetail)JSON.deserialize(eventJSON, EventDetail.Class);
        
        // parse json strings into list of objects - ID, NAME
        List<Worker> convertedWorkers = (List<Worker>)JSON.deserialize(eventObject.workers, List<Worker>.Class);
        List<Client> convertedClients = (List<Client>)JSON.deserialize(eventObject.clients, List<Client>.Class);
        
        System.debug('How many workers in this event? ' + convertedWorkers.size());
        
        List<Id> workerIds = new List<Id>();
        List<Id> clientIds = new List<Id>();
        
        for(Worker w : convertedWorkers){
            workerIds.add(w.Id);
        }
        
        for(Client c : convertedClients){
            clientIds.add(c.Id);
        }
        
        Map<Id, Event> idsOfClashedEvents = retrieveEventIdsFromJSON(eventJSON, repeatJSON);
        List<ID> eventsForClients = new List<ID>();
        List<ID> eventsForWorkers = new List<ID>();
        
        //separate between which event we want to check for clash
        //for clients, only check for clash for Initials and Therapy
        //for workers, check for all types of event
        for(Event e : idsOfClashedEvents.values()){
            if(e.Event_Type__c == 'Initial Appointment' || e.Event_Type__c == 'Therapy Session'){
                eventsForClients.add(e.Id);
                eventsForWorkers.add(e.Id);
            } else {
                eventsForWorkers.add(e.Id);
            }
        }
        
        //always find clash for workers - regardless of what event type the user is creating
        List<EventRelation> listOfER = [SELECT Id, RelationId, Relation.Name, EventId FROM EventRelation WHERE (Status = 'New' OR Status = 'Accepted') AND RelationId IN: workerIds AND EventId IN: eventsForWorkers AND RelationId != :contactToShareEvent.Id ORDER BY RelationId];
        List<Client_Event_Relation__c> listOfCER = new List<Client_Event_Relation__c>();
        
        //only find clash for worker if the user is trying to make an initial or therapy
        //if the form is NOT initials or therapy, only search the worker avails
        if(eventObject.eventType == 'Initial Appointment' || eventObject.eventType == 'Therapy Session'){
            listOfCER = [SELECT Id, Client__c, Client__r.Id, Client__r.FirstName, Client__r.LastName FROM Client_Event_Relation__c WHERE (Status__c = 'Pending' OR Status__c = 'Booked') AND Client__c IN: clientIds AND Event_Id__c IN: eventsForClients ORDER BY Client__c];
        }
        
        
        //for each client, set up the map
        if(!listOfER.isEmpty()){
            
            for(Id w : workerIds){
                for(EventRelation er : listOfER){
                    if(er.RelationId == w){
                        setOfClashingWorkersAndClients.add(er.Relation.Name);
                        System.debug('This client has a clashing event. Name is: ' + er.Relation.Name);
                    } else {
                        System.debug('This client does NOT have a clashing event. Name is: ' + er.Relation.Name);
                    }
                }
            }     
        } else {
            System.debug('No CERs in any of the event that happens at the same time with our client');
        }
        
        //for each client, set up the map
        if(!listOfCER.isEmpty()){
            
            for(Id c : clientIds){
                for(Client_Event_Relation__c cer : listOfCER){
                    if(cer.Client__r.Id == c){
                        String clientFullName = cer.Client__r.FirstName + ' ' + cer.Client__r.LastName;
                        setOfClashingWorkersAndClients.add(clientFullName);
                        System.debug('This client has a clashing event. Name is: ' + cer.Client__r.FirstName);
                    } else {
                        System.debug('This client does NOT have a clashing event. Name is: ' + cer.Client__r.FirstName);
                    }
                }
            }     
        } else {
            System.debug('No CERs in any of the event that happens at the same time with our client');
        }
        
        String[] listOfClashingContacts = new List<String>();
        
        for(String finalWorkersAndClients : setOfClashingWorkersAndClients){
            listOfClashingContacts.add(finalWorkersAndClients);
        }
        
        return listOfClashingContacts;
    }
    
    //RAF CODE
    private static Map<Id, Event> retrieveEventIdsFromJSON(String eventJSON, String repeatJSON){
        System.debug('In retrieveEventIdsFromJSON now');
        
        Set<String> setOfClashingContacts= new Set<String>();
        Map<Id, Event> eventIds;        
        
        Id BR_EVENT = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('BR_Event').getRecordTypeId();
        
        // parse event details
        EventDetail eventObject = (EventDetail)JSON.deserialize(eventJSON, EventDetail.Class);
        
        DateTime startDateTime;
        DateTime endDateTime;
        Integer duration;
        
        List<Event> clashedEvents = new List<Event>();
        
        if(!String.isBlank(eventObject.startTime) && !String.isBlank(eventObject.endTime)){
            System.debug('start date from eventObject: ' + eventObject.startTime);
            System.debug('end date from eventObject: ' + eventObject.endTime);
            
            if (!eventObject.allDay) {
                startDateTime = eventObject.startTime.right(1) == 'Z' ? CalendarController.convertToLocal(eventObject.startTime) : CalendarController.convertToDateTime(eventObject.startTime, eventObject.allDay);
                endDateTime = eventObject.endTime.right(1) == 'Z' ? CalendarController.convertToLocal(eventObject.endTime) : CalendarController.convertToDateTime(eventObject.endTime, eventObject.allDay);
                duration = ((endDateTime.getTime() - startDateTime.getTime()) / 60000).intValue();
                
                eventIds = new Map<Id, Event>([SELECT Id, Event_Type__c, StartDateTime, EndDateTime FROM Event WHERE RecordTypeId =: BR_EVENT AND (Event_Status__c = 'Pending' OR Event_Status__c = 'Booked')
                                               AND ((StartDateTime >=: startDateTime AND EndDateTime <=: endDateTime) //for if your event duration is larger than an event's time
                                                    OR (StartDateTime <=: startDateTime AND EndDateTime >: startDateTime) //for if your start time is between an event's time
                                                    OR (StartDateTime <: endDateTime AND EndDateTime >=: endDateTime) //for if your end time is between an event's time
                                                   )]);
                
                
            } else {
                // both conversions use startTime for all day event to prevent multi day all day events (occurs if a user selects range across multiple days)
                if (eventObject.startTime.length() == 10) {
                    startDateTime = CalendarController.dateStringToDate(eventObject.startTime);
                    endDateTime = CalendarController.dateStringToDate(eventObject.startTime);
                } else if (eventObject.startTime.right(1) == 'Z') {
                    startDateTime = CalendarController.convertToLocal(eventObject.startTime);
                    endDateTime = CalendarController.convertToLocal(eventObject.startTime);
                } else {
                    startDateTime = CalendarController.convertToDate(eventObject.startTime);
                    endDateTime = CalendarController.convertToDate(eventObject.startTime);        
                }
                //duration = 1440;
                
                eventIds = new Map<Id, Event>([SELECT Id, Event_Type__c, StartDateTime, EndDateTime FROM Event WHERE RecordTypeId =: BR_EVENT AND (Event_Status__c = 'Pending' OR Event_Status__c = 'Booked') AND CALENDAR_MONTH(StartDateTime) =: startDateTime.month() 
                                               AND CALENDAR_YEAR(StartDateTime) =: startDateTime.year() AND DAY_IN_MONTH(StartDateTime) =: startDateTime.day()]);
            }
            
            System.debug('Start date time: ' + startDateTime);        
            System.debug('End date time: ' + endDateTime);

            
            System.debug('Number of clashed events in TOTAL: ' + eventIds.size());
            System.debug('Clashed Events IDs: ' + eventIds);
            
        } else {
            eventIds.put(null, null);
        }
        
        return eventIds;
    }*/
}