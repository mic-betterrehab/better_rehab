//Helper class to create EC and categorise events
public class BR_EventCommunicationHelper {
    
    public static Boolean isPendulaActive(){
        Boolean result;
        
        Pendula_Triggers__c pendulaTriggerIndication = Pendula_Triggers__c.getInstance();
        result = pendulaTriggerIndication.isTriggerEnabled__c;
        
        return result;
    }
    
    //for mapping recurrence and its events in ascending order
    //will only get events within the scope of trigger (cause we want to measure recurring changes based on whether all is changed at once or not)
    public static Map<Id, List<LookedUpFromActivity>> getMapOfRecurrencesAndEvents(Set<Id> uniqueRecurrenceIds, Set<Id> scopeOfEvents){
        
        Map<Id, List<LookedUpFromActivity>> recurrenceToEvents = new Map<Id, List<LookedUpFromActivity>>();
        
        //find the number of recurrences for each Recurrence ID comes through the trigger - we can change this to a utility method if needed
        List<Event_Recurrence__c> recurrencesAndEvents = [SELECT Id, (SELECT Id FROM Activities__r WHERE Id IN: scopeOfEvents ORDER BY StartDateTime ASC) FROM Event_Recurrence__c WHERE Id IN: uniqueRecurrenceIds];
        
        for(Event_Recurrence__c r : recurrencesAndEvents){
            recurrenceToEvents.put(r.Id, r.Activities__r); //order of events is preserved here
        }
        
        return recurrenceToEvents;
    }
    
    //for creating an EC for RECURRING booking/cancellation
    public static List<Event_Communication__c> createRecurringEC(List<Client_Event_Relation__c> recurringCERToRemind, Id recordTypeId, 
                                                                 Map<Id, Event> eventIdMap, Map<Id, Id> cerIdToEventId, Map<Id, Integer> numberOfCERRecurrence){    
        
        System.debug('How many CER in this recurring booking/cancellation: ' + recurringCERToRemind.size());                                                      
        List<Event_Communication__c> ecToInsert = new List<Event_Communication__c>();
                                                                     
      	//Step 1: retrieve the events set                                                           
        Set<Event> setOfEvents = new Set<Event>(); 
                                                                     
        for(Client_Event_Relation__c cerNew : recurringCERToRemind){
            
            Event uniqueEvent = eventIdMap.get(cerIdToEventId.get(cerNew.Id));   
            setOfEvents.add(uniqueEvent);            
        }                                                              
                                                                     
        Map<Event, String> mapOfWorkerProfessions = getWorkerProfessionMap(setOfEvents);
        
        for(Client_Event_Relation__c cer : recurringCERToRemind){
            
            //get the event
            Event e = eventIdMap.get(cerIdToEventId.get(cer.Id));           
            
            //get the number of recurrences
            Integer num = numberOfCERRecurrence.get(cer.Id);
            
            Event_Communication__c newEC = createEventCommunicationForRecurringChanges(e, cer, recordTypeId, num, mapOfWorkerProfessions);
            ecToInsert.add(newEc);
        }  
        
        return ecToInsert;
    }
    
    //This method is used to create an EC for RECURRING confirmation, cancellation, time changed
    public static Event_Communication__c createEventCommunicationForRecurringChanges(Event e, Client_Event_Relation__c cer, Id recordTypeId, Integer numberOfRecurrence, Map<Event, String> mapWorkerProfessions){
        System.debug('Creating a RECURRING EC now, with record type is: ' + recordTypeId);
        Event_Communication__c newEC = new Event_Communication__c();
        newEC.RecordTypeId = recordTypeId;
        newEC.Client_Event_Relation__c = cer.Id;
        newEC.Client_Contact__c = cer.Client__c;
        newEC.Start__c = e.StartDateTime;
        newEC.End__c = e.EndDateTime;
        newEC.Event_Subject__c = e.Subject;
        newEC.Event_Recurrence__c = e?.Event_Recurrence__c;
        newEC.Event_Recurrences__c = numberOfRecurrence;
        newEC.Workers_and_Professions__c = mapWorkerProfessions.get(e);
        return newEC;         
    }
    
    //for creating an EC for a single booking/sms reminder
    public static List<Event_Communication__c> createSingleEC(List<Client_Event_Relation__c> listOfCER, Id recordTypeId, 
                                                                 Map<Id, Event> eventIdMap, Map<Id, Id> cerIdToEventId){
        System.debug('Inside createSingleEC in Helper class');      
        List<Event_Communication__c> ecToInsert = new List<Event_Communication__c>();       
        
        //Step 1: retrieve the events set                                                           
        Set<Event> setOfEvents = new Set<Event>(); 
                                                                     
        for(Client_Event_Relation__c cerNew : listOfCER){
            
            Event uniqueEvent = eventIdMap.get(cerIdToEventId.get(cerNew.Id));   
            setOfEvents.add(uniqueEvent);            
        }                                                              
                                                                     
        Map<Event, String> mapOfWorkerProfessions = getWorkerProfessionMap(setOfEvents);
                                                                     
        //step 2: create the events ec                                                             
        for(Client_Event_Relation__c cer : listOfCER){
            
            Event e = eventIdMap.get(cerIdToEventId.get(cer.Id));
            
            Event_Communication__c newEC = createEventCommunicationForSingleChanges(e, cer, recordTypeId, mapOfWorkerProfessions);
            ecToInsert.add(newEc);
        } 
        
        return ecToInsert;
    }
	
    //This method is used to create an EC for SINGLE confirmation, cancellation, time changed
    public static Event_Communication__c createEventCommunicationForSingleChanges(Event e, Client_Event_Relation__c cer, Id recordTypeId, Map<Event, String> mapWorkerProfessions){
        System.debug('Creating an EC now, with record type is: ' + recordTypeId);
        Event_Communication__c newEC = new Event_Communication__c();
        newEC.RecordTypeId = recordTypeId;
        newEC.Client_Event_Relation__c = cer.Id;
        newEC.Client_Contact__c = cer.Client__c;
        newEC.Start__c = e.StartDateTime;
        newEC.End__c = e.EndDateTime;
        newEC.Event_Subject__c = e.Subject;
        newEC.Workers_and_Professions__c = mapWorkerProfessions.get(e);
        return newEC;        
    }
    
    public static Map<Event, String> getWorkerProfessionMap(Set<Event> events){
        Contact contactToShareEvent = [SELECT Id FROM Contact WHERE LastName = 'to share events'];
        
        Map<Event, String> eventToWorkerProfession = new Map<Event, String>();
        Map<Id, String> contactIdToWorkerProfession = new Map<Id, String>();
        
        String workersProfessions;
        
        Map<Id, Id> eventToWorker = new Map<Id, Id>();
        Set<Id> workerIds = new Set<Id>();
        
        //this will call >1 ER for each events
        List<EventRelation> er = [SELECT Id, RelationId, Relation.Name, EventId FROM EventRelation WHERE EventId IN: events AND RelationId != :contactToShareEvent.Id ORDER BY EventId];
        
        for(EventRelation workerAppt : er){
            workerIds.add(workerAppt.RelationId);
        }       
        
        Map<Client_Event_Relation__c, String> cerToWorkerInfos = new Map<Client_Event_Relation__c, String>();
        
        List<Contact> listOfContacts = [SELECT Id, Clinician_Discipline__c, Name FROM Contact WHERE Id IN: workerIds];
        
        for(Contact worker : listOfContacts){
            String oneWorker = worker?.Name + '(' + worker?.Clinician_Discipline__c +')';
            contactIdToWorkerProfession.put(worker.Id, oneWorker);
        }
        
        for(Event e : events){
            
            List<String> workerInfos = new List<String>();
            
            for(EventRelation oneER : er){
                
                if(oneER.EventId == e.Id){
                    System.debug('Event Id and e.id are the same');
                    String wpForOneER = contactIdToWorkerProfession.get(oneER.RelationId);
                    workerInfos.add(wpForOneER);  
                }  
                
            }   
            workersProfessions = String.join(workerInfos, ', ');
            eventToWorkerProfession.put(e, workersProfessions);            
        }
        
        return eventToWorkerProfession;
        
    }
}