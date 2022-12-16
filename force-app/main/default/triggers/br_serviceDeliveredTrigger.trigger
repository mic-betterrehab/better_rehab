trigger br_serviceDeliveredTrigger on enrtcr__Support_Delivered__c (before update) {
   // List<enrtcr__Support_Delivered__c> toWriteOff = new List<enrtcr__Support_Delivered__c>();
    Map<enrtcr__Support_Delivered__c, Double> toWriteOffQuant = new Map<enrtcr__Support_Delivered__c, Double>();
    
    if (Trigger.isBefore) {
        if(Trigger.isUpdate) {
            for (Integer i = 0; i < Trigger.new.size(); i++) {
                System.debug(Trigger.old[i].Write_Off__c + '  ' + Trigger.new[i].Write_Off__c);
                System.debug(Trigger.old[i].enrtcr__Quantity__c);
                System.debug(Trigger.new[i].enrtcr__Quantity__c);
                if (
                    (Trigger.old[i].Write_Off__c == FALSE && Trigger.new[i].Write_Off__c == TRUE) &&
                    (Trigger.old[i].enrtcr__Quantity__c > Trigger.new[i].enrtcr__Quantity__c)  &&
                    (Trigger.old[i].enrtcr__Service_Name__c != 'Write Off - RMs')
                ) {
                    //toWriteOff.add(Trigger.new[i]);
                    toWriteOffQuant.put(Trigger.new[i], Trigger.old[i].enrtcr__Quantity__c - Trigger.new[i].enrtcr__Quantity__c);
                    
                }             
            }
            new br_writeOffHandler(toWriteOffQuant);
        }	   
    }
}