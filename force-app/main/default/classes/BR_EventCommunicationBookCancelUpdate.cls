public class BR_EventCommunicationBookCancelUpdate {
    //This is to handle Pendula for updating an event booking confirmation and cancellation
    //For time change, go to this class: BR_EventCommunicationTimeChange
    private enum EventType {
        BOOKED, CANCELLED, SMS_REMINDER
    }
    
    private final Id SINGLE_RECORDTYPE_ID_BOOKED = Schema.SObjectType.Event_Communication__c.getRecordTypeInfosByDeveloperName().get('Single_Appointment_Confirmation').getRecordTypeId();
    private final Id SINGLE_RECORD_TYPE_ID_TIME_CHANGED = Schema.SObjectType.Event_Communication__c.getRecordTypeInfosByDeveloperName().get('Single_Appointment_Time_Changed').getRecordTypeId();
    private final Id RECURRING_RECORDTYPE_ID_BOOKED = Schema.SObjectType.Event_Communication__c.getRecordTypeInfosByDeveloperName().get('Recurring_Appointment_Confirmation').getRecordTypeId();
    private final Id SINGLE_RECORDTYPE_ID_CANCELLED = Schema.SObjectType.Event_Communication__c.getRecordTypeInfosByDeveloperName().get('Single_Appointment_Cancellation').getRecordTypeId();
    private final Id RECURRING_RECORDTYPE_ID_CANCELLED = Schema.SObjectType.Event_Communication__c.getRecordTypeInfosByDeveloperName().get('Recurring_Appointment_Cancellation').getRecordTypeId();
    private final Id REMINDER_RECORDTYPE_ID = Schema.SObjectType.Event_Communication__c.getRecordTypeInfosByDeveloperName().get('X24_Hour_Reminder').getRecordTypeId();
    private final Id BR_EVENT = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('BR_Event').getRecordTypeId();
    
    private final String STATUS_BOOKED = 'Booked';
    private final String STATUS_CANCELLED = 'Cancelled';
    
    List<Event_Communication__c> ecToInsert = new List<Event_Communication__c>();
    List<Client_Event_Relation__c> cerForSMS = new List<Client_Event_Relation__c>();
    List<Client_Event_Relation__c> cerCancelled = new List<Client_Event_Relation__c>();
    List<Event_Communication__c> ecToUpdate = new List<Event_Communication__c>();    
    Map<Id, Event> eventIdMap;
    Map<Id, Id> cerIdToEventId = new Map<Id, Id>();
    Map<Id, Id> cerIdToClientId = new Map<Id, Id>();
    
    List<Client_Event_Relation__c> removedCER = new List<Client_Event_Relation__c>();
    Map<Id, Id> cerToRecurrence = new Map<Id, Id>();
    Set<Id> recurrenceIds = new Set<Id>();
    Map<Id, List<LookedUpFromActivity>> orderedListOfRecurrenceAndEvents = new Map<Id, List<LookedUpFromActivity>>();
    
    List<Client_Event_Relation__c> recurringCERToCreateECFor = new List<Client_Event_Relation__c>();
    List<Client_Event_Relation__c> oneOffCER = new List<Client_Event_Relation__c>();
    List<Client_Event_Relation__c> recurringUniqueChangeCER = new List<Client_Event_Relation__c>();
    List<Client_Event_Relation__c> recurringCER = new List<Client_Event_Relation__c>();
    Map<Id, Integer> numberOfCERRecurrence = new Map<Id, Integer>();
    
    Map<Id, Client_Event_Relation__c> newMapFromTrigger = new Map<Id, Client_Event_Relation__c>();
    Map<Id, Client_Event_Relation__c> oldMapFromTrigger = new Map<Id, Client_Event_Relation__c>();
    
    List<Client_Event_Relation__c> validCERForBooking = new List<Client_Event_Relation__c>();
    
    Map<Id, Event> eventsTimeChanged = new Map<Id, Event>();
    List<Client_Event_Relation__c> cersNoTimeChanged = new List<Client_Event_Relation__c>();
    
    public BR_EventCommunicationBookCancelUpdate(Map<Id, Client_Event_Relation__c> newMap, Map<Id, Client_Event_Relation__c> oldMap, TriggerOperation op){
        
        if(BR_EventCommunicationHelper.isPendulaActive()){
            
            //call this method upon class instantiation        
            switch on op {
                
                when AFTER_UPDATE {
                    System.debug('Inside BR_EventCommunicationBookCancelUpdate: Trigger is after update');
                    newMapFromTrigger.putAll(newMap);
                    oldMapFromTrigger.putAll(oldMap);
                    this.afterUpdate(); 
                    System.debug('Size of cer map that comes in: ' + newMapFromTrigger.size());
                }
            }
            
            insert ecToInsert;
            update ecToUpdate;
        }
    }
        
    //after update will be called if someone create a draft event and booked it now OR if they cancelled a booked appt
    private void afterUpdate(){
            
        List<Client_Event_Relation__c> cerBooked = new List<Client_Event_Relation__c>();

        for(Client_Event_Relation__c cer : newMapFromTrigger.values()){
            Client_Event_Relation__c oldCER = oldMapFromTrigger.get(cer.Id);
            
            //List of booked CER
            if(cer.Status__c != oldCER.Status__c && cer.Status__c == STATUS_BOOKED){
                System.debug('CER ID: ' + cer.Id + ' CER is changed from ' + oldCER.Status__c + ' to booked');
                cerBooked.add(cer);
                cerIdToEventId.put(cer.Id, cer.Event_Id__c);      
                cerIdToClientId.put(cer.Id, cer.Client__c);
            } else {
                System.debug('CER ID: ' + cer.Id + ' CER is changed from ' + oldCER.Status__c + ' to ' + cer.Status__c); //the latest
            }
            
            //List of cancelled CER
            if(cer.Status__c != oldCER.Status__c && cer.Status__c == STATUS_CANCELLED){
                System.debug('CER ID: ' + cer.Id + ' CER is cancelled');
                cerCancelled.add(cer);
                cerIdToEventId.put(cer.Id, cer.Event_Id__c);
                cerIdToClientId.put(cer.Id, cer.Client__c);
            }
        }
        
        eventIdMap = new Map<Id, Event>([SELECT Id, RecordTypeId, Subject, Event_Recurrence__c, Event_Type__c, StartDateTime, EndDateTime
                                         FROM Event WHERE Id =: cerIdToEventId.values() AND RecordTypeId =: BR_EVENT]);     
        
        if(!cerBooked.isEmpty()){   
            //For booking reminder, categorise them based on recurrence
            //categorizeCER(cerBooked, EventType.BOOKED);
            checkForTimeChangeNotification(cerBooked, EventType.BOOKED);
        }
        
        if(!cerCancelled.isEmpty()){           
            //For cancellation reminder, categorise them based on recurrence
            categorizeCER(cerCancelled, EventType.CANCELLED);
        }
    }
    
    //before categorise CER, check if there has been a time change notif for this cer
    private void checkForTimeChangeNotification(List<Client_Event_Relation__c> cer, EventType flowType){
        //get the event id from this list of cer
        List<Id> eventIds = new List<Id>();
        
        for(Client_Event_Relation__c c : cer){
            eventIds.add(c.Event_Id__c);
        }
        
        Map<Id, Event> eventsToCreateTimeChangeNotification = new Map<Id, Event>();
        
        for(Client_Event_Relation__c c : cer){
            Event ev = eventIdMap.get(cerIdToEventId.get(c.Id));
            
            System.debug('CER ID: ' + c.Id);   
            
            //check if ev here has a record in the list
            if(c.Time_Changed__c == TRUE){
                System.debug('This CER has had a time changed before. Need to send a TC reminder. Putting their Event IDs in a list.');     
                
                //CER that comes through here could be a single CER or a recurring CER (no way to know)
                eventsToCreateTimeChangeNotification.put(ev.Id, ev);
                
            } else {
                //if no time changed, then put it in the validCER list for further processing
                System.debug('This CER HAS NOT HAD a time changed. Can send the booking reminder.');
                validCERForBooking.add(c);
            }
        }
        
        if(!validCERForBooking.isEmpty()){
            System.debug('Content of cerBooked in check for TC: ' + validCERForBooking);
            categorizeCER(validCERForBooking, EventType.BOOKED);
        }
        
        if(!eventsToCreateTimeChangeNotification.isEmpty()){
            System.debug('Sending eventsToCreateTimeChangeNotification to BR_EventCommunicationTimeChange');
            BR_EventCommunicationTimeChange newTimeChange = new BR_EventCommunicationTimeChange(cer, eventsToCreateTimeChangeNotification);
        }
    }

    //all that comes in this method will either be booked without time change or cancelled
    //categorise as recurring or not
    private void categorizeCER(List<Client_Event_Relation__c> cer, EventType flowType){
        System.debug('Categorizing CER now');
        
        /*eventIdMap = new Map<Id, Event>([SELECT Id, Subject, Event_Recurrence__c, Event_Type__c, StartDateTime, EndDateTime
                        FROM Event WHERE Id =: cerIdToEventId.values() AND RecordTypeId =: BR_EVENT]);*/
        
        //find out whether this CER is a part of a recurring events
        for(Client_Event_Relation__c c : cer){
            
            if(eventIdMap.get(cerIdToEventId.get(c.Id)).Event_Type__c == 'Initial Appointment' || eventIdMap.get(cerIdToEventId.get(c.Id)).Event_Type__c == 'Therapy Session'){
                
                cerForSMS.add(c);
                
                if(eventIdMap.get(cerIdToEventId.get(c.Id)).Event_Recurrence__c != NULL){
                    
                    //if yes, add them to the list of recurring cer
                    recurringCER.add(c);
                    cerToRecurrence.put(c.Id, eventIdMap.get(cerIdToEventId.get(c.Id)).Event_Recurrence__c); //mapping CER to recurrence for later use
                    recurrenceIds.add(eventIdMap.get(cerIdToEventId.get(c.Id)).Event_Recurrence__c);
                    
                    System.debug('This CER is recurring');
                    
                } else {
                    //if no, add them to the list of one-off cer
                    oneOffCER.add(c);
                    System.debug('This CER is NOT recurring');
                }
            } else {
                System.debug('This CER is not Initial Appt or Therapy Session');
            }
        }
        
        //Do this for SMS
        if(!cerForSMS.isEmpty()){
           if(flowType == EventType.BOOKED){  
               List<Event_Communication__c> smsECToInsert = BR_EventCommunicationHelper.createSingleEC(cerForSMS, REMINDER_RECORDTYPE_ID, eventIdMap, cerIdToEventId);
               ecToInsert.addAll(smsECToInsert);
            }         
        }
        
        //Do this for recurring
        if(!recurringCER.isEmpty()){
            handleRecurring(recurringCER, flowType, recurrenceIds); 
        }
        
        //Do this for non-recurring
        if(!oneOffCER.isEmpty()){
            if(flowType == EventType.BOOKED){
                List<Event_Communication__c> bookedECToInsert = BR_EventCommunicationHelper.createSingleEC(oneOffCER, SINGLE_RECORDTYPE_ID_BOOKED, eventIdMap, cerIdToEventId);
               	ecToInsert.addAll(bookedECToInsert);
            }
            
            if(flowType == EventType.CANCELLED){
                List<Event_Communication__c> cancelledECToInsert = BR_EventCommunicationHelper.createSingleEC(oneOffCER, SINGLE_RECORDTYPE_ID_CANCELLED, eventIdMap, cerIdToEventId);
               	ecToInsert.addAll(cancelledECToInsert);
            }
        }
        
    }   
       
    //categorize booked/cancelled
    private void handleRecurring(List<Client_Event_Relation__c> recurringCER, EventType flowType, Set<Id> recurrences){
                
        orderedListOfRecurrenceAndEvents = BR_EventCommunicationHelper.getMapOfRecurrencesAndEvents(recurrences, eventIdMap.keySet());
        
        //create the EC
        if(flowType == EventType.BOOKED){
            sortRecurringChangesBasedOnChangeType(recurringCER, EventType.BOOKED, validCERForBooking);
        }
        
        if(flowType == EventType.CANCELLED){
            sortRecurringChangesBasedOnChangeType(recurringCER, EventType.CANCELLED, cerCancelled);
        }
    }
    
    //same process - different type of changes
    private void sortRecurringChangesBasedOnChangeType(List<Client_Event_Relation__c> oneSetOfCER, EventType flowType, List<Client_Event_Relation__c> matchingCERList){
        System.debug('Size of oneSetOfCER: ' + oneSetOfCER.size());
                
        Map<Id, List<Id>> mapOfCERIdToListOfEvents = new Map<Id, List<Id>>();
        
        for(Client_Event_Relation__c oneCER : oneSetOfCER){
            
            //get the other cer with this recurrences - only have events tho
            List<LookedUpFromActivity> newList = orderedListOfRecurrenceAndEvents.get(cerToRecurrence.get(oneCER.Id)); //list of events
            System.debug('cerToRecurrence.get(oneCER.Id): ' + cerToRecurrence.get(oneCER.Id));
            System.debug('newList: ' + newList);
            List<Id> ids = new List<Id>();
            
            for(LookedUpFromActivity events : newList){
                System.debug('ids: ' + events.Id);
                ids.add(events.Id); //this is the issue                
            }
            
            mapOfCERIdToListOfEvents.put(oneCER.Id, ids);
            
        }
        
        for(Client_Event_Relation__c recurCER : oneSetOfCER){
            
            List<Client_Event_Relation__c> newListOfRelatedCERs = new List<Client_Event_Relation__c>();
            
            for(Client_Event_Relation__c m : matchingCERList){
                for(Id eId : mapOfCERIdToListOfEvents.get(recurCER.Id)){
                    if(m.Event_Id__c == eId && m.Client__c == recurCER.Client__c){
                        newListOfRelatedCERs.add(m);
                    }
                }                
            }
            
            //Step 2: Find out if all cer in step 1 was changed to booked/cancelled
            if(newListOfRelatedCERs.size() == 1){                
                
                recurringUniqueChangeCER.add(recurCER);                 
                
            } else if(newListOfRelatedCERs.size() > 1) {
                
                List<LookedUpFromActivity> newListRecurrence = orderedListOfRecurrenceAndEvents.get(cerToRecurrence.get(recurCER.Id)); //list of events
                
                //Step 3: check if the current CER is the 1st in the cerBooked
                // this has to be not always 0 because if the time change is true, then u want to remove 
                if(recurCER.Event_Id__c == newListRecurrence[0].Id){
                    recurringCERToCreateECFor.add(recurCER);
                    numberOfCERRecurrence.put(recurCER.Id, newListOfRelatedCERs.size());
                }
                
            } else {
                System.debug('No CER status is booked');
            }
            
        }
        
        //create the EC
        if(flowType == EventType.BOOKED){
            
            //for recurring booked and booked for >1 recurrences (assuming it's always ALL recurrences)
            List<Event_Communication__c> finalRecurringECBookedToInsert = BR_EventCommunicationHelper.createRecurringEC(recurringCERToCreateECFor, RECURRING_RECORDTYPE_ID_BOOKED, eventIdMap, cerIdToEventId, numberOfCERRecurrence);
			ecToInsert.addAll(finalRecurringECBookedToInsert);
            
            //for recurring booked but only booked for 1 recurrence
            List<Event_Communication__c> finalSingleECBookedToInsert = BR_EventCommunicationHelper.createSingleEC(recurringUniqueChangeCER, SINGLE_RECORDTYPE_ID_BOOKED, eventIdMap, cerIdToEventId);
            ecToInsert.addAll(finalSingleECBookedToInsert);
        }
        
        //create the EC
        if(flowType == EventType.CANCELLED){
            //for recurring cancelled and cancelled for >1 recurrences (assuming it's always ALL recurrences)
            List<Event_Communication__c> finalRecurringECCancelledToInsert = BR_EventCommunicationHelper.createRecurringEC(recurringCERToCreateECFor, RECURRING_RECORDTYPE_ID_CANCELLED, eventIdMap, cerIdToEventId, numberOfCERRecurrence);
			ecToInsert.addAll(finalRecurringECCancelledToInsert);
            
            //for recurring cancelled but only cancelled for 1 recurrence
            List<Event_Communication__c> finalSingleECCancelledToInsert = BR_EventCommunicationHelper.createSingleEC(recurringUniqueChangeCER, SINGLE_RECORDTYPE_ID_CANCELLED, eventIdMap, cerIdToEventId);
            ecToInsert.addAll(finalSingleECCancelledToInsert);
        }
    }
}