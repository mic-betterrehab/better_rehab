public without sharing class BR_EventWAPUpdate {
    //This class is to update the event status based on the worker appointment field
    //This class will run correctly if BR_EventWAPLink is running correctly
    /*List<Event> updatedEvent = new List<Event>();
    List<Event> deletedEvent = new List<Event>();
    
    public BR_EventWAPUpdate(List<enrtcr__Worker_Appointment__c> waps){
        
        //get the list of events that are related to this waps
        List<Event> ids = [SELECT Id, Worker_Appointment__c, Event_Status__c, Worker_Appointment__r.enrtcr__Status__c FROM Event WHERE Worker_Appointment__c IN :waps];
        System.debug('Size of Events Id: ' + ids.size());
        
        //check if the wap status is cancelled or not
        for(Integer i = 0; i < ids.size(); i++){
            if(ids[i].Worker_Appointment__r.enrtcr__Status__c == 'Cancelled'){
                //delete the event
                deletedEvent.add(ids[i]);
            } else {
                //update the event status
                ids[i].Event_Status__c = ids[i].Worker_Appointment__r.enrtcr__Status__c;
                System.debug('New Status field: ' + ids[i].Event_Status__c);
                updatedEvent.add(ids[i]);
            }
        }
        
        if(updatedEvent.size() > 0){
            update updatedEvent;
            System.debug('Updating some events');
        }
        
        if(deletedEvent.size() > 0){
            delete deletedEvent;
            System.debug('Deleting some events');
        }
        
    }*/
}