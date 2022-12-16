trigger BR_SessionTrigger on enrtcr__Session__c (after insert) {
    System.debug('Service type is re-engagement');
    //new BR_ReengagementSessionHandler(Trigger.new);
}