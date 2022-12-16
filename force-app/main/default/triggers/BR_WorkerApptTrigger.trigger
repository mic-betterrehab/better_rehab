trigger BR_WorkerApptTrigger on enrtcr__Worker_Appointment__c (after update) {
    System.debug('Inside WAP Trigger');
    //new BR_EventWAPUpdate(Trigger.New);
}