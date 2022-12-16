trigger serviceTrigger on enrtcr__Service__c (after insert) {
	new newServiceTriggerHandler(Trigger.new);
}