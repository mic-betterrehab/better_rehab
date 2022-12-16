trigger BR_EventTrigger on Event (after insert, after update) {
    System.debug('Inside Event Trigger');
    System.debug('Size of Event Trigger: ' + Trigger.new.size());
    
    for(Event evt : trigger.new){
        System.debug('Now triggering: ' + evt.Id);
    }
    
    if(Trigger.isAfter){
        if(Trigger.isInsert){            
            new BR_ReengagementEventHandler(Trigger.new);
            for(Event evt : trigger.new){
                System.debug('Event Id Insert: ' + evt.Id);
            }
        }
    }
    
}