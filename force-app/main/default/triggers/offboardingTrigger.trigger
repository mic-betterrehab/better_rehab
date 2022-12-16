trigger offboardingTrigger on Offboarding__c (after insert) {
    try{
        new offboardingTriggerHandler(Trigger.new);
    } catch (Exception e) {
        System.debug(e.getMessage());
    }
}