public with sharing class br_writeOffHandler {
    private List<enrtcr__Support_Delivered__c> writeOffs = new List<enrtcr__Support_Delivered__c>();
    
    public br_writeOffHandler(Map<enrtcr__Support_Delivered__c, Double> toWriteOff) {
        if (toWriteOff.size() == 0) {
            System.debug('No services delivered came through the trigger');
            return;
        }
		System.debug('input = ' + toWriteOff);        
        enrtcr__Rate__c RM_write_off = [SELECT id, enrtcr__Service__r.Id, enrtcr__Service__r.Name 
                                        FROM enrtcr__Rate__c 
                                        WHERE enrtcr__Service__r.Name = 'Write Off - RMs' 
                                        LIMIT 1];
        System.debug('write off service found = ' + RM_write_off);
        for (enrtcr__Support_Delivered__c sde : toWriteOff.keySet()) {
            
            Double writeOffQuant = toWriteOff.get(sde);
            enrtcr__Support_Delivered__c writeoff = new enrtcr__Support_Delivered__c();
            
            writeoff.enrtcr__Date__c = sde.enrtcr__Date__c;
            writeoff.enrtcr__Comments__c = sde.enrtcr__Comments__c;
            writeoff.enrtcr__Client__c = sde.enrtcr__Client__c;
            writeoff.enrtcr__Support_Contract__c = sde.enrtcr__Support_Contract__c;
            writeoff.enrtcr__Support_Contract_Item__c = sde.enrtcr__Support_Contract_Item__c;
            writeoff.enrtcr__Support_CategoryId__c = sde.enrtcr__Support_CategoryId__c;
            writeoff.enrtcr__Worker__c = sde.enrtcr__Worker__c;
            writeoff.enrtcr__Adhoc_Service__c = RM_write_off.enrtcr__Service__r.Id;
            writeoff.enrtcr__Site__c = sde.enrtcr__Site__c;
            writeoff.enrtcr__Site_Service_Program__c = sde.enrtcr__Site_Service_Program__c;
            writeoff.enrtcr__Rate__c = RM_write_off.Id;
            writeoff.enrtcr__Quantity__c = writeOffQuant;
            writeoff.enrtcr__Client_Rep_Accepted__c = sde.enrtcr__Client_Rep_Accepted__c;
            writeoff.enrtcr__Client_Rep_Accepted_Date__c = sde.enrtcr__Client_Rep_Accepted_Date__c;
            writeoff.Original_Service__c = sde.enrtcr__Adhoc_Service__c;
            writeoff.Original_Quantity__c = sde.enrtcr__Quantity__c + writeOffQuant;
            writeoff.Parent_SDE__c = sde.Id;
                
                
            writeOffs.add(writeoff);
        }
        System.debug('insertion = ' + writeOffs);      
        insert writeOffs;
    }
}