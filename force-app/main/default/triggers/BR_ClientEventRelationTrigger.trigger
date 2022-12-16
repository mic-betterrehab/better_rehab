trigger BR_ClientEventRelationTrigger on Client_Event_Relation__c (after insert, after update) {
    System.debug('Inside CER Trigger');
    
    System.debug('Size of CER Trigger: ' + Trigger.new.size());
        
    
    if(Trigger.isAfter){
        if(Trigger.isInsert){ 
            new BR_EventCommunicationBookCancelCreation(Trigger.newMap, Trigger.operationType);
        }
        
        else if(Trigger.isUpdate){
            new BR_EventCommunicationBookCancelUpdate(Trigger.newMap, Trigger.oldMap, Trigger.operationType); 
        }
    }   
}