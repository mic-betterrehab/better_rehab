public class BR_EventCommunicationTimeChange {
	//This class is to create the Pendula Time Changed notification and update the SMS reminder if there is an update in time
	//This class will be invoked if someone updates the time of their events 
	
    private enum EventType {
        TIME_CHANGED
    }
    
    private final Id SINGLE_RECORD_TYPE_ID_TIME_CHANGED = Schema.SObjectType.Event_Communication__c.getRecordTypeInfosByDeveloperName().get('Single_Appointment_Time_Changed').getRecordTypeId();
    private final Id RECURRING_TIME_CHANGED = Schema.SObjectType.Event_Communication__c.getRecordTypeInfosByDeveloperName().get('Recurring_Appointment_Time_Changed').getRecordTypeId();
    private final Id REMINDER_RECORDTYPE_ID = Schema.SObjectType.Event_Communication__c.getRecordTypeInfosByDeveloperName().get('X24_Hour_Reminder').getRecordTypeId();
    private final Id INITIAL_SURVEY = Schema.SObjectType.Feedback_Survey__c.getRecordTypeInfosByDeveloperName().get('Initial_Client_Survey').getRecordTypeId();
    private final Id BR_EVENT = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('BR_Event').getRecordTypeId();
    
    private final String STATUS_BOOKED = 'Booked';
    
    private Map<Id, List<Client_Event_Relation__c>> eventIdToListOfCER = new Map<Id, List<Client_Event_Relation__c>>();
    List<Client_Event_Relation__c> currentCERs = new List<Client_Event_Relation__c>();
        
    Map<Id, Event> eventTimeChanged = new Map<Id, Event>();
    List<Event_Communication__c> ecToInsert = new List<Event_Communication__c>();
    List<Event_Communication__c> smsRemindersToUpdate = new List<Event_Communication__c>();
    List<Feedback_Survey__c> initialFSToUpdate = new List<Feedback_Survey__c>();
    
    public Map<Id, Event> newMapFromTrigger = new Map<Id, Event>();
    Map<Id, Event> oldMapFromTrigger = new Map<Id, Event>();
    
    Map<Id, Event> recurringEvents = new Map<Id, Event>();
    Map<Id, Event> oneOffEvents = new Map<Id, Event>();
    
    Map<Id, Integer> numberOfEventRecurrence = new Map<Id, Integer>();
    
    /*public BR_EventCommunicationTimeChange(Map<Id, Event> newMap, Map<Id, Event> oldMap, TriggerOperation op){
        
        // if the KPI setting is active (TRUE), run this pendula trigger
        if(BR_EventCommunicationHelper.isPendulaActive()){
            //call this method upon class instantiation        
            switch on op {
                
                when AFTER_UPDATE {
                    System.debug('Trigger is after update');
                    newMapFromTrigger.putAll(newMap);
                    oldMapFromTrigger.putAll(oldMap);
                    this.afterUpdate(); 
                }
            }
            
            insert ecToInsert;
            update smsRemindersToUpdate;
            update initialFSToUpdate;
        }
        
    }*/
    
    public BR_EventCommunicationTimeChange(List<Client_Event_Relation__c> currentlyProcessedCERs, Map<Id, Event> mapOfEventsWithTimeChanged){
        newMapFromTrigger.putAll(mapOfEventsWithTimeChanged);
        currentCERs.addAll(currentlyProcessedCERs);
        
        this.afterUpdate();
        
        insert ecToInsert;
        update smsRemindersToUpdate;
        update initialFSToUpdate;
    }
        
    public void afterUpdate(){
        System.debug('Inside afterUpdate: ' + newMapFromTrigger);
        /*for(Event ev : newMapFromTrigger.values()){            
            Event oldEvent = oldMapFromTrigger.get(ev.Id);
            
            //List of Time Changed Events
            if(ev.RecordTypeId == BR_Event){
                if(ev.Event_Type__c == 'Initial Appointment' || ev.Event_Type__c == 'Therapy Session'){
                    if((ev.StartDateTime != oldEvent.StartDateTime || ev.EndDateTime != oldEvent.EndDateTime) && oldEvent.Event_Status__c == STATUS_BOOKED){
                        eventTimeChanged.put(ev.Id, ev); //everything here should only be booked event that has a time changed
                    } 
                }  
            }            
            
        }*/
        
        for(Event ev : newMapFromTrigger.values()){            
            //List of Time Changed Events
            if(ev.RecordTypeId == BR_Event){
                if(ev.Event_Type__c == 'Initial Appointment' || ev.Event_Type__c == 'Therapy Session'){
                    eventTimeChanged.put(ev.Id, ev); //everything here should only be booked event that has a time changed
                }  
            }            
            
        }
        
        //populate the map of eventIdToListOfCER
        if(!eventTimeChanged.isEmpty()){
            
            //a map of CER that has a time changed
            //Map<Id, Client_Event_Relation__c> cerMap = new Map<Id, Client_Event_Relation__c>([SELECT Id, Status__c, Event_Id__c, Client__c FROM Client_Event_Relation__c WHERE Time_Changed__c = TRUE AND Event_Id__c IN: eventTimeChanged.keySet()]);
			
            //the CERs in currentCERs will already have Time changed = true and status = booked and they are all in the current transaction
            Map<Id, Client_Event_Relation__c> cerMap = new Map<Id, Client_Event_Relation__c>([SELECT Id, Status__c, Event_Id__c, Client__c FROM Client_Event_Relation__c WHERE Id IN: currentCERs]);
			
            
            for(Event ev : eventTimeChanged.values()){
                List<Client_Event_Relation__c> listOfCERForAnEvent = new List<Client_Event_Relation__c>();
                
                //set up to find a list of cer for each event
                for(Client_Event_Relation__c cer : cerMap.values()){
                    if(cer.Event_Id__c == ev.Id){
                        listOfCERForAnEvent.add(cer);
                    }
                }
                
                //this will have a map of event id - list of CERs that are in the transactions
                eventIdToListOfCER.put(ev.Id, listOfCERForAnEvent);
                
            }  
            
            //For SMS Reminder, do this without finding whether it's recurring or not since each event has its own reminder
            updateExistingSMSReminder(eventTimeChanged); // will need to do this only for Event that has their time updated  
            categoriseEvent(eventTimeChanged);
        } 
    }
    
    private void categoriseEvent(Map<Id, Event> timeChangedEvents){
        //find out whether an event is recurring or not
        for(Event e : timeChangedEvents.values()){
            if(e.Event_Recurrence__c != NULL){
                //if yes, add them to the list of recurring cer
                recurringEvents.put(e.Id, e);
                
                System.debug('This event is recurring');
            } else {
                oneOffEvents.put(e.Id, e);
                
                System.debug('This event is not recurring');
            }
        }
        
        //for single time change, do these all
        
        if(!oneOffEvents.isEmpty()){
            //create the EC for single TC
            createECTimeChanged(oneOffEvents, SINGLE_RECORD_TYPE_ID_TIME_CHANGED);
            
            //Business rule states that initial appts are never recurring
            //So only update existing survey for one off events (initial FS)
            updateExistingFeedbackSurvey(oneOffEvents);
        }
        
        //for recurring time change, do these
        if(!recurringEvents.isEmpty()){
            //check whether this event comes here alone or with its other recurring things
            sortRecurringBasedOnChangeType(recurringEvents);
        }
    }
    
    private void sortRecurringBasedOnChangeType(Map<Id, Event> recurring){
        System.debug('Size of recurring events: ' + recurring.size());
        
        if(recurring.size() == 1){
            System.debug('This recurring event is only changed once');
            
            //create the EC for single TC
            createECTimeChanged(recurring, SINGLE_RECORD_TYPE_ID_TIME_CHANGED);            
            
        } else {
            System.debug('This recurring event is changed for more than one recurrence');
            
            //do we need a check here to make sure they are all from the same recurrence?
            
            //use the event sort helper to retrieve the earliest event in the map
            //this sort helper will put the LATEST event at the start i = 0
            BR_EventSortHelper[] evList = new List<BR_EventSortHelper>();
            
            //Check the list of events
            for (Event e : recurring.values()){
                System.debug('In sortRecurringBasedOnChangeType, currently processing this event: ' + e.Id);
                evList.add(new BR_EventSortHelper(e));
            }
            
            evList.sort();
            
            //CONVERT evList into a map of id - event with only 1 element
            //get the last element of evList
            BR_EventSortHelper firstEventInTheRecurrence = evList[evList.size()-1];
            
            Map<Id,Event> finalMapForEC = new Map<Id,Event>();
            finalMapForEC.put(firstEventInTheRecurrence.e.Id, firstEventInTheRecurrence.e);
            
            //create the EC for single TC
            numberOfEventRecurrence.put(firstEventInTheRecurrence.e.Id, evList.size());
            createECTimeChanged(finalMapForEC, RECURRING_TIME_CHANGED);         
			     
        }
    }
    
    private void updateExistingFeedbackSurvey(Map<Id, Event> timeChangedEvents){
        System.debug('Inside updateExistingFeedbackSurvey');
        
        List<Feedback_Survey__c> listOfInitialFeedbackSurvey = [SELECT Id, Event_Start_DateTime__c, Event_End_DateTime__c, Client_Event_Relation__r.Event_Id__c FROM Feedback_Survey__c 
                                                                WHERE RecordTypeId =: INITIAL_SURVEY AND Client_Event_Relation__r.Event_Id__c IN: timeChangedEvents.keySet()];
        
        if(!listOfInitialFeedbackSurvey.isEmpty()){
            for(Feedback_Survey__c initialFS : listOfInitialFeedbackSurvey){
                initialFS.Event_Start_DateTime__c = newMapFromTrigger.get(initialFS.Client_Event_Relation__r.Event_Id__c).StartDateTime;
                initialFS.Event_End_DateTime__c = newMapFromTrigger.get(initialFS.Client_Event_Relation__r.Event_Id__c).EndDateTime;
                initialFSToUpdate.add(initialFS);
            }
        }
        
    }
    
    private void updateExistingSMSReminder(Map<Id, Event> timeChangedEvents){
        System.debug('Inside updateExistingSMSReminder');
        
        List<Event_Communication__c> previousSMSReminder = [SELECT Id, Client_Event_Relation__c, Client_Event_Relation__r.Event_Id__c , Start__c, End__c FROM Event_Communication__c 
                                                                WHERE Client_Event_Relation__r.Event_Id__c IN: timeChangedEvents.keySet()
                                                               AND RecordTypeId =: REMINDER_RECORDTYPE_ID AND Is_Booked__c = TRUE];
              
        //update the existing sms reminders with the new start and end date time
        for(Event_Communication__c updatedEC : previousSMSReminder){
            updatedEC.Start__c = newMapFromTrigger.get(updatedEC.Client_Event_Relation__r.Event_Id__c).StartDateTime;
            updatedEC.End__c = newMapFromTrigger.get(updatedEC.Client_Event_Relation__r.Event_Id__c).EndDateTime;
            smsRemindersToUpdate.add(updatedEC);
        }
        
    }
    
    //this should take in 1 cer that was changed instead of the events because dont want to create lots of events
    private void createECTimeChanged(Map<Id, Event> listOfEvents, Id recordTypeId){
        System.debug('Inside createECTimeChanged');
        List<Client_Event_Relation__c> relatedCERs = new List<Client_Event_Relation__c>();
        Set<Event> setOfEvents = new Set<Event>(listOfEvents.values());
        
        Map<Event, String> mapOfWorkerProfessions = BR_EventCommunicationHelper.getWorkerProfessionMap(setOfEvents);
        
        for(Event ev : listOfEvents.values()){            
            relatedCERs = eventIdToListOfCER.get(ev.Id); //will have a list of CER
            
            //create the EC for each CER here            
            for(Client_Event_Relation__c cer : relatedCERs){
                Event e = newMapFromTrigger.get(cer.Event_Id__c);
                
                if(recordTypeId == SINGLE_RECORD_TYPE_ID_TIME_CHANGED){
                    Event_Communication__c newSingleEC = BR_EventCommunicationHelper.createEventCommunicationForSingleChanges(e, cer, recordTypeId, mapOfWorkerProfessions);
                    ecToInsert.add(newSingleEC);
                } else if(recordTypeId == RECURRING_TIME_CHANGED){ 
                    //for recurring time changed, listOfEvents will always be 1 (Cause we just put the earliest event)
                    //we are assuming that for each time change that happens to more than 1 event simultaneously, only events in the same recurrence are passed on. So we can use listOfEvents.size() for number of recurrence
                    Event_Communication__c newRecurringEC = BR_EventCommunicationHelper.createEventCommunicationForRecurringChanges(e, cer, recordTypeId, numberOfEventRecurrence.get(e.Id), mapOfWorkerProfessions);
                    ecToInsert.add(newRecurringEC);
                }    
            } 
        }  
    }    
}