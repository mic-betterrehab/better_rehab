trigger nad_rateTrigger on enrtcr__Rate__c (before insert, before update) {

    for (enrtcr__Rate__c r : Trigger.New) {
        if (r.enrtcr__Service__c != null && r.Status__c == 'Active') {
            Id service = r.enrtcr__Service__c;
            enrtcr__Rate__c[] ratess = [SELECT id, Status__c, Name FROM enrtcr__Rate__c WHERE enrtcr__Service__r.Id =: service AND Status__c = 'Active'];
            if (ratess.size() > 1) {
                r.Status__c.addError('The service associated with this rate already has an active rate.');
                continue;
            }
            //if (Trigger.isBefore && Trigger.isInsert) {
            //    if (ratess.size() > 0) {
            //        r.Status__c.addError('The service associated with this rate already has an active rate.');
            //        continue;
            //    }
            //} else if (Trigger.isBefore && Trigger.isUpdate) {
            //   if (ratess.size() > 1) {
            //        r.Status__c.addError('The service associated with this rate already has an active rate.');
            //        continue;
            //    }
            //}
            
        }
    }
    
}