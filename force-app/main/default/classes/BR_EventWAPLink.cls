public without sharing class BR_EventWAPLink {
    //This class is for when an event is first created
    
    /*List<Event> updatedEvent = new List<Event>();
    List<String> wapId = new List<String>();
    Map<String,String> eventWithWAP = new Map<String,String>();
    Map<String,String> wapStatus = new Map<String,String>(); 
    
    //need to do some selection in the trigger
    public BR_EventWAPLink(List<Event> events){
        
        System.debug('Inside EventWAPLink');  
        
        System.debug('getting the events id and whatid, size is: ' + events.size());
        
        for(Integer i = 0; i < events.size(); i++){
            System.debug('id from trigger: ' + events[i].Id + ' ' + events[i].WhatId);
        }
        
        List<Event> ids = [SELECT Id, WhatId, Event_Status__c, What.Type, Worker_Appointment__c FROM Event WHERE Id IN :events];
        System.debug('Size of Events Id: ' + ids.size());
        System.debug('Size of WhatType: ' + ids[0].What.Type);
        
        //check if the event is related to wap or not
        for(Integer i = 0; i < ids.size(); i++){
            if(ids[i].What.Type == ('enrtcr__Worker_Appointment__c')){
                System.debug('Calling the setWAP method');
                setWAP(ids[i], ids[i].WhatId); 
                
                System.debug('Size of WhatType: ' + ids[i].What.Type);
                System.debug('Size of WhatType: ' + ids[i].Id);
                System.debug('Size of WhatType: ' + ids[i].WhatId);
            }
        }
                
        System.debug('Checking size of updatedEvent: ' + updatedEvent.size());
        
        update updatedEvent;        
     }
    
    private void setWAP(Event newEvent, Id wapIdFromEvent){
        System.debug('Inside setWAP method, with newEvent: ' + newEvent.Id);
        System.debug('Inside setWAP method, with newEvent WhatId: ' + wapIdFromEvent);
        //put the ids and what id into a map        
        eventWithWAP.put(newEvent.Id, wapIdFromEvent);
        
        //get the list of WAP
        enrtcr__Worker_Appointment__c listOfWAP = [SELECT Id, enrtcr__Status__c FROM enrtcr__Worker_Appointment__c WHERE Id =: wapIdFromEvent];
        System.debug('getting the listOfWAP, size is: ' + listOfWAP.Id);
                
        wapStatus.put(listOfWAP.Id, listOfWAP.enrtcr__Status__c);
        
        newEvent.Worker_Appointment__c = eventWithWAP.get(newEvent.Id);
        System.debug('New WAP field: ' + newEvent.Worker_Appointment__c);
        newEvent.Event_Status__c = wapStatus.get(wapIdFromEvent);
        System.debug('New Status field: ' + newEvent.Event_Status__c);
        updatedEvent.add(newEvent);
        
        System.debug('Checking size of updatedEvent: ' + updatedEvent.size());           
    }*/
}