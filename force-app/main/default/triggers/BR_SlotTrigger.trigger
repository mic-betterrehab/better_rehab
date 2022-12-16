trigger BR_SlotTrigger on Slot__c (before insert, before update) {

    for (Slot__c s : Trigger.New) {
        
        // expired resource check
        Resource__c r = [SELECT id, Expiry_Date__c FROM Resource__c WHERE id =: s.Resource__c];
        if (s.End_Time__c >= r.Expiry_Date__c) {
            System.debug('error1');
            s.addError('Cannot book expired resource');
        }
        
        // booking clash check
        List<Slot__c> overlappingSlots = [SELECT id, Start_Time__c, End_Time__c 
                                          FROM Slot__c
                                          WHERE id != : s.Id
                                            AND Resource__c =: s.Resource__c
                                          	AND (
                                                (Start_Time__c > :s.Start_Time__c AND Start_Time__c < :s.End_Time__c) 
                                          	OR (Start_Time__c <= :s.Start_Time__c AND End_Time__c >= :s.End_Time__c) 
                                          	OR (End_Time__c > :s.Start_Time__c AND End_Time__c < : s.End_Time__c)
                                              )
                                          LIMIT 1
                                         ];
        if (overlappingSlots.size() > 0) {
            System.debug('error2');
            s.addError('Booking clash error');
        }
        
    }
}