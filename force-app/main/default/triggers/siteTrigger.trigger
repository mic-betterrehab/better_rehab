trigger siteTrigger on enrtcr__Site__c (after insert) {
	new siteTriggerHandler(Trigger.new);
}