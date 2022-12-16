trigger BR_ClinicalAuditTrigger on Clinical_Audit__c (after insert) {
	System.debug('Inside BR_ClinicalAuditTrigger');
    new BR_ClinicalAuditSharing(Trigger.New);
}