trigger BR_AuditTrigger on Clinical_Audit__c (after insert) {
    String PASS = 'CONFORMS';
    String FAIL = 'DOES NOT CONFORM';
    Integer CYCLE_PERIOD = 28;

    List<Clinical_Audit__c> audits = Trigger.new;
    List<Contact> updateData = new List<Contact>();

    // get all the clinicians contact profiles of the audits getting entered 
    Set<Id> clinicianIds = new Set<Id>();
    for (Clinical_Audit__c ca : audits) {
        clinicianIds.add(ca.Clinician__c);
    }
    List<Contact> clinicians = [SELECT id, Probation_End_Date__c, Next_Audit__c FROM Contact WHERE id IN :clinicianIds];
    Map<Id, Contact> clinicianMap = new Map<Id, Contact>(clinicians);
    
    for (Clinical_Audit__c ca : audits) {

        // only do work if the audit type is clinical audit
        if (ca.Audit_Type__c != 'Clinical Audit') {
            continue;
        }

        // pull the clinician data
        Contact clinician = clinicianMap.get(ca.Clinician__c);
		
        // safety check for next audit date for clinician
        Date nextAudit = clinician.Next_Audit__c != NULL ? clinician.Next_Audit__c : System.today();
        
        // if the audit is a fail, auto set next audit date to one month stream
        if (ca.Status__c == FAIL) {
            clinician.Next_Audit__c = nextAudit + CYCLE_PERIOD;
            updateData.add(clinician);
            continue;
        }

        // pull the audit history of the clinician
        List<Clinical_Audit__c> auditHistory = [SELECT id, Status__c
                                                FROM Clinical_Audit__c 
                                                WHERE Clinician__c =: clinician.id
                                                    AND Audit_Type__c  = 'Clinical Audit' 
                                                ORDER BY createdDate DESC 
                                                LIMIT 2 // 2 because the latest one is gonna be the one that just got submitted
                                                ];
        // if the clinician has not completed at least 2 clinical audits, place/keep them in the monthly cycle
        if (auditHistory.size() < 2) {
            clinician.Next_Audit__c = nextAudit + CYCLE_PERIOD;
            updateData.add(clinician);
            continue;
        }
        
        // boolean checks to qualify for quarterly audits
        Boolean auditsPassed = auditHistory[0].Status__c == PASS && auditHistory[1].Status__c == PASS;
        Boolean probationPassed = System.today() > clinician.Probation_End_Date__c; 
        
        if (auditsPassed && probationPassed) {
            clinician.Next_Audit__c = nextAudit + (3 * CYCLE_PERIOD);
            updateData.add(clinician);
            continue;
        }

        // keep/place in monthly cycle if does not qualify for quarterly
        clinician.Next_Audit__c = nextAudit + CYCLE_PERIOD;
        updateData.add(clinician);
    }

    try {
        update updateData;
    } catch (DmlException err) {
        System.debug(err.getMessage());
    }   
}