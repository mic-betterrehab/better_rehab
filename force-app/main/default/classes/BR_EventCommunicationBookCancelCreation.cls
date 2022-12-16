public class BR_EventCommunicationBookCancelCreation {
    //This class is trigger on after insert of a client event relation
    //to create the event communication record for confirmation and SMS reminder
	
    private enum EventType {
        BOOKED, CANCELLED, SMS_REMINDER
    }
    
    //Types of Event communication that will be created in this class
    private final Id SINGLE_RECORDTYPE_ID_BOOKED = Schema.SObjectType.Event_Communication__c.getRecordTypeInfosByDeveloperName().get('Single_Appointment_Confirmation').getRecordTypeId();
    private final Id RECURRING_RECORDTYPE_ID_BOOKED = Schema.SObjectType.Event_Communication__c.getRecordTypeInfosByDeveloperName().get('Recurring_Appointment_Confirmation').getRecordTypeId();
	private final Id REMINDER_RECORDTYPE_ID = Schema.SObjectType.Event_Communication__c.getRecordTypeInfosByDeveloperName().get('X24_Hour_Reminder').getRecordTypeId();
    private final Id BR_EVENT = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('BR_Event').getRecordTypeId();
    
    private final String STATUS_BOOKED = 'Booked';
    
    List<Event_Communication__c> ecToInsert = new List<Event_Communication__c>();    
    List<Client_Event_Relation__c> cerBooked = new List<Client_Event_Relation__c>();
    List<Client_Event_Relation__c> cerForSMS = new List<Client_Event_Relation__c>();
    Map<Id, Event> cerIdToEvent = new Map<Id, Event>();
    Map<Id, Id> cerToRecurrence = new Map<Id, Id>();
    Map<Id, Id> cerIdToEventId = new Map<Id, Id>();
    Set<Id> recurrenceIds = new Set<Id>();
    Map<Id, List<LookedUpFromActivity>> orderedListOfRecurrenceAndEvents = new Map<Id, List<LookedUpFromActivity>>();
    Map<Id, Boolean> cerIsFirst = new Map<Id, Boolean>();
    Map<Id, Integer> numberOfCERRecurrence = new Map<Id, Integer>();       
    Map<Id, Event> eventIdMap;
    
    List<Client_Event_Relation__c> recurringCER = new List<Client_Event_Relation__c>();
    List<Client_Event_Relation__c> oneOffCER = new List<Client_Event_Relation__c>();
    
    Map<Id, Client_Event_Relation__c> newMapFromTrigger = new Map<Id, Client_Event_Relation__c>();
    
    public BR_EventCommunicationBookCancelCreation(Map<Id, Client_Event_Relation__c> newMap, TriggerOperation op){
        if(BR_EventCommunicationHelper.isPendulaActive()){            
            switch on op {
                when AFTER_INSERT {
                    System.debug('Inside BR_EventCommunicationBookCancelCreation: Trigger is after insert');
                    newMapFromTrigger.putAll(newMap);
                    this.afterInsert();
                }
            }
            
            insert ecToInsert;
        }   
    }
    
    //after insert will be called if someone creates an appt and click save and booked directly
    private void afterInsert(){
        for(Client_Event_Relation__c cer : newMapFromTrigger.values()){
            
            //List of Booked
            if(cer.Status__c == STATUS_BOOKED){
                System.debug('CER is created as booked');
                cerBooked.add(cer);  
                cerIdToEventId.put(cer.Id, cer.Event_Id__c);
            } else {
                System.debug('This CER is NOT inserted in a booked status');
            }            
        }        
               
        if(!cerBooked.isEmpty()){
            //For booking reminder, categorise them based on recurrence
            categorizeCER(cerBooked, EventType.BOOKED);            
        }
    }
    
    //categorise as recurring or not
    private void categorizeCER(List<Client_Event_Relation__c> cer, EventType flowType){        
        
        eventIdMap = new Map<Id, Event>([SELECT Id, Subject, Event_Recurrence__c, Event_Type__c, StartDateTime, EndDateTime
                        FROM Event WHERE Id =: cerIdToEventId.values() AND RecordTypeId =: BR_EVENT]);
        
        for(Client_Event_Relation__c c : cer){      
            //check if it's the session type that we want
            if(eventIdMap.get(cerIdToEventId.get(c.Id)).Event_Type__c == 'Initial Appointment' || eventIdMap.get(cerIdToEventId.get(c.Id)).Event_Type__c == 'Therapy Session'){
                //if yes, add it to the SMS list
                cerForSMS.add(c);                
                
                // if yes, check if it's recurring
                if(eventIdMap.get(cerIdToEventId.get(c.Id)).Event_Recurrence__c != NULL){
                    
                    //if yes, add them to the list of recurring cer
                    recurringCER.add(c);
                    cerToRecurrence.put(c.Id, eventIdMap.get(cerIdToEventId.get(c.Id)).Event_Recurrence__c); //mapping CER to recurrence for later use
                    recurrenceIds.add(eventIdMap.get(cerIdToEventId.get(c.Id)).Event_Recurrence__c);
                    
                } else {
                    //if no, add them to the list of one-off cer
                    oneOffCER.add(c);
                    System.debug('This CER is not recurring');
                }
            } else {
                System.debug('This CER is not Initial Appt or Therapy Session');
            }
        }
        
        //Do this for SMS
        if(!cerForSMS.isEmpty()){
            List<Event_Communication__c> smsECToInsert = BR_EventCommunicationHelper.createSingleEC(cerForSMS, REMINDER_RECORDTYPE_ID, eventIdMap, cerIdToEventId);
            ecToInsert.addAll(smsECToInsert);
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
        }
    }
    
    //categorize booked
    private void handleRecurring(List<Client_Event_Relation__c> listOfRecurringCER, EventType flowType, Set<Id> recurrences){
        List<Client_Event_Relation__c> recurringCERBooked = new List<Client_Event_Relation__c>(); 
        
        orderedListOfRecurrenceAndEvents = BR_EventCommunicationHelper.getMapOfRecurrencesAndEvents(recurrences, eventIdMap.keySet());
        
        for(Client_Event_Relation__c recurCER : listOfRecurringCER){            
            //Goal 1: make sure that this is the first CER in the series that gets inserted - we only want to connect a recurring EC with the first instance of the event/CER
            if(recurCER.Event_Id__c == orderedListOfRecurrenceAndEvents.get(cerToRecurrence.get(recurCER.Id))[0].Id){
                cerIsFirst.put(recurCER.Id, TRUE);
                recurringCERBooked.add(recurCER);
                
                //Goal 2: find out how many other CER is related to this CER
                Integer totalEventsInRecurrence = orderedListOfRecurrenceAndEvents.get(cerToRecurrence.get(recurCER.Id)).size();
                numberOfCERRecurrence.put(recurCER.Id, totalEventsInRecurrence);
                
            } else {
                cerIsFirst.put(recurCER.Id, FALSE);
            }
        }
        
        //create the EC
        if(flowType == EventType.BOOKED){            
            List<Event_Communication__c> finalECToInsert = BR_EventCommunicationHelper.createRecurringEC(recurringCERBooked, RECURRING_RECORDTYPE_ID_BOOKED, eventIdMap, cerIdToEventId, numberOfCERRecurrence);
			ecToInsert.addAll(finalECToInsert);
        }
    }
}