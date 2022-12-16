trigger BR_PDApprovalTrigger on PD_Approval__c (after update) {
	new BR_PDApproval(Trigger.newMap, Trigger.oldMap);
    System.debug('BR_PDApprovalTrigger is activated!');
}