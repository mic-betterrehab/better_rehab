public class BR_ClinicalAuditSharing {
    //This class is to create a record of the Clinical Audit Share object type to allow auditee, TL, CS read access to the correct clinical audits
    List<Clinical_Audit__Share> listOfShares;
    
    public BR_ClinicalAuditSharing(List<Clinical_Audit__c> listOfAudits){
        listOfShares = new List<Clinical_Audit__Share>();
        System.debug('Inside BR_ClinicalAuditSharing');
        List<Clinical_Audit__c> audits = [SELECT Id, Clinician__c, OwnerId, Clinician__r.enrtcr__User__c, Clinician__r.Direct_Supervisor__c, Clinician__r.Clinical_Supervisor__c, Clinician__r.Direct_Supervisor__r.enrtcr__User__c, 
                                          Clinician__r.Clinical_Supervisor__r.enrtcr__User__c, Clinician__r.Principal_Clinician__r.enrtcr__User__c FROM Clinical_Audit__c WHERE Id IN :listOfAudits]; 
        
        for(Integer i = 0; i < audits.size(); i++){
            //if record owner = either the DS, CS then dont do this
            
            if(audits[i].OwnerId != audits[i].Clinician__r.enrtcr__User__c){
                Clinical_Audit__Share auditee = createShare(audits[i].Id, audits[i].Clinician__r.enrtcr__User__c); //for the auditee
                listOfShares.add(auditee);
            }
            
            //Check if the auditee has a DS or not
            if(audits[i].Clinician__r.Direct_Supervisor__c != NULL){
                if(audits[i].OwnerId != audits[i].Clinician__r.Direct_Supervisor__r.enrtcr__User__c){                
                    Clinical_Audit__Share TL = createShare(audits[i].Id, audits[i].Clinician__r.Direct_Supervisor__r.enrtcr__User__c); //for the TL (aka DS)
                    listOfShares.add(TL);
                } 
            }
            
            //Check if the auditee has a CS or not
            if(audits[i].Clinician__r.Clinical_Supervisor__c != NULL){
                if(audits[i].OwnerId != audits[i].Clinician__r.Clinical_Supervisor__r.enrtcr__User__c){                
                    Clinical_Audit__Share CS = createShare(audits[i].Id, audits[i].Clinician__r.Clinical_Supervisor__r.enrtcr__User__c); //for the CS
                    listOfShares.add(CS);
                } 
            }
            
        }
        
        insert listOfShares;
    }
    
    //for creating the READ ONLY sharing access
    public Clinical_Audit__Share createShare(Id recordId, Id userOrGroupId){
        System.debug('Inside createShare');
       	Clinical_Audit__Share caShare = new Clinical_Audit__Share();
        if(userOrGroupId != NULL){            
            caShare.ParentId = recordId;
            System.debug('ParentId is: ' + caShare.ParentId);
            caShare.UserOrGroupId = userOrGroupId;
            caShare.AccessLevel = 'Read';
        }
        
        return caShare;
    }
}