trigger SessionCommunications on enrtcr__Session__c (after update) {
    if(Trigger.isUpdate){
        new SessionHandler(Trigger.newMap, Trigger.oldMap);
    }
}