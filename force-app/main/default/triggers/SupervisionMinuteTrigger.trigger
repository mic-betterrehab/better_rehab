trigger SupervisionMinuteTrigger on Supervision_Minutes__c (after insert) {
    new BR_SupervisionMinuteSharing(Trigger.New);
}