trigger BR_PDRequestTrigger on PD_Request__c (before insert, after insert) {
    if (Trigger.isBefore) {
        // Process before insert
        for(Integer i = 0; i < Trigger.new.size(); i++){
            if(Trigger.new[i].Status__c != 'Pending'){
                Trigger.new[i].addError('Please change the status to Pending before submitting this PD Request');
            }          
            
        }
        
        System.debug('BR_PDRequestTrigger is activated!');
        
    } else if (Trigger.isAfter) {
        // Process after insert
        new BR_PDApprovalCreation(Trigger.new);
        System.debug('BR_PDRequestTrigger is activated!');
    } 
	
}