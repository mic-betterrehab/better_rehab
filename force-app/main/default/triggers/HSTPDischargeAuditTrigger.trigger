//Written by Nad - 03/11/2020
trigger HSTPDischargeAuditTrigger on enrtcr__Assessment__c (before insert, after insert) {
    if (Trigger.isBefore) {
        //You should only be getting one record save. If there are more, we don't want to process them if any of them are not HSTP discharge forms.
        Integer flag = 0;
        System.debug('inside the trigger');
        for (enrtcr__Assessment__c assessment : Trigger.New) {
            System.debug(assessment);
            System.debug(assessment.RecordTypeId);
            System.debug(assessment.RecordType.DeveloperName);
            if (assessment.RecordTypeId != '0122v000001eZulAAE') {
                System.debug('flag is 1');
                flag = 1;
            }
        }
        if(flag == 0) {
            System.debug('flag = ' + flag);
            new HSTPDischargeAudit(Trigger.new);
        }
    }
    
    //if (Trigger.isAfter) {
    //    Integer flag = 0;
    //    System.debug('inside the trigger2');
    //    for (enrtcr__Assessment__c assessment : Trigger.New) {
    //        if (assessment.RecordTypeId != '0122v000001eZulAAE') {
    //            flag = 1;
    //        }
    //    }
    //    if(flag == 0) {
    //        System.debug('flag = ' + flag);
    //        new HSTPDischargeTaskHandler(Trigger.new);
    //    }
    //}
    
}