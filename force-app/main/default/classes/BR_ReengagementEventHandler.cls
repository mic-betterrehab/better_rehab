public class BR_ReengagementEventHandler {
    //This class is to set what happened when a Re-engagement event is created - this is a new version to be used with the new calendar
	List<EventRelation> erToInsert;
    List<Client_Event_Relation__c> cerToInsert;
    List<Event> validEvents;
    
    public BR_ReengagementEventHandler(List<Event> events){
        erToInsert = new List<EventRelation>();
        cerToInsert = new List<Client_Event_Relation__c>();
        validEvents = new List<Event>();
        
        //making sure that this event is a re-engagement event
        for(Event ev : events){
            if(ev.Is_Re_engagement__c == TRUE){
                System.debug('This event is a re-engagement event');
                
                //Checking that all events here would only be automatically created events, that has the worker ID and plan review report connected to it
                if(String.isBlank(ev.Re_engagement_Worker_ID__c) == FALSE){
                    if(ev.Plan_Review_Report__c != null){
                        validEvents.add(ev); 						                        
                    } else {
                        System.debug('This event does not have a Plan review report');
                    }
                } else {
                    System.debug('This event does not have a re-engagement worker ID/created manually');
                }
            } else {
                System.debug('This is not a re-engagement event');
            }
        }
        
        if(!validEvents.isEmpty()){
            //create the ER
            createER(validEvents);
            
            //create the CER
            createCER(validEvents);
        }
        
		insert erToInsert;
		insert cerToInsert;
    }
    
    //function to create an ER - each event will always only have 1 worker for this use case
    private void createER(List<Event> events){
        System.debug('Creating ER for valid events');
        for(Event eve : events){
            EventRelation newER = new EventRelation();
            newER.EventId = eve.Id;
            newER.RelationId = eve.Re_engagement_Worker_ID__c;
            erToInsert.add(newER);
        }
        
    }
    
    //function to crate a CER - each event will always have 1 client
    private void createCER(List<Event> events){
		System.debug('Creating a CER');  
        
        Map<Id, Event> eventToClient = new Map<Id, Event>([SELECT Id, Plan_Review_Report__r.enrtcr__Client__c FROM Event WHERE Id IN: events]);
        
        for(Event ev : eventToClient.values()){
            Client_Event_Relation__c newCER = new Client_Event_Relation__c();
            newCER.Client__c = eventToClient.get(ev.Id).Plan_Review_Report__r.enrtcr__Client__c;
            newCER.Event_Id__c = ev.Id;
            newCER.Status__c = 'Pending';
            cerToInsert.add(newCER);
        }        
    }
}