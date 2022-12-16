public with sharing class HSTPDischargeAudit {
    
    //private List<Task> tasks = new List<Task>();
    //private List<enrtcr__Support_Delivered__c> SDs = new List<enrtcr__Support_Delivered__c>();
    
    public HSTPDischargeAudit(List<enrtcr__Assessment__c> dischargeForms) {        
        for (enrtcr__Assessment__c form : dischargeForms) {
            //sanitize the form a bit
            if (form.Number_of_extra_sessions__c == NULL) {
                form.Number_of_extra_sessions__c = '0';
            }
            if (form.HSTP_Cancellation_Reason__c == NULL) {
                form.HSTP_Cancellation_Reason__c = '';
            }
            if (form.Discharge_Comments__c == NULL) {
                form.Discharge_Comments__c = '';
            }
            System.debug('Client Id = ' + form);
            //Get all the current SA's for the client in the discharge form. 
            List<enrtcr__Support_Contract__c> SAs = [SELECT id, Name, enrtcr__Client__r.Id 
                                                     FROM enrtcr__Support_Contract__c 
                                                     WHERE enrtcr__Status__c = 'Current' 
                                                     	AND enrtcr__Client__r.id =: form.enrtcr__Client__c
                                                     	AND enrtcr__Rate_Type_Display__c = 'HSTP'
                                                    ];
            if (SAs.size() > 0) {             
                //There should only be one active service agreement per client for a certain discipline
                enrtcr__Support_Contract__c ServiceAgreement = SAs[0];
                System.debug('found a SA' + serviceAgreement.Name);
                //Array of services to check for - right now we only do physio, but when we add new ones, make sure to add the appointment service for that discipline in the array below
                List<String> serviceNamesToCheck = new List<String>();
                serviceNamesToCheck.add('HSTP - Discharge Episode');
                serviceNamesToCheck.add('HSTP - Follow up Episode');
                serviceNamesToCheck.add('HSTP - Initial Episode');
                //Get the appointment SD's for the client.
                List<enrtcr__Support_Delivered__c> clinicianDelivered = [SELECT id 
                                                                         FROM enrtcr__Support_Delivered__c 
                                                                         WHERE enrtcr__Support_Contract__r.Id =: ServiceAgreement.Id 
                                                                         	AND enrtcr__Service_Name__c IN : serviceNamesToCheck 
                                                                         	AND enrtcr__Client__r.Id =: ServiceAgreement.enrtcr__Client__r.Id
                                                                        ];
                System.debug('Number of deliveries found = ' + clinicianDelivered.size() + integer.valueOf(form.Number_of_sessions__c) + integer.valueOf(form.Number_of_extra_sessions__c));
                Integer lastMeeting = form.Telehealth_Session_Completed__c == 'Yes' ? 1 : 0;
                System.debug('telehealth = ' + lastMeeting);
                Integer numSessions = integer.valueOf(form.Number_of_sessions__c) + integer.valueOf(form.Number_of_extra_sessions__c) + lastMeeting;
                if ( numSessions != clinicianDelivered.size()) {
                    form.Number_of_sessions__c.addError('Wrong number of sessions indicated. Indicated: ' + numSessions + ' Actual: ' + clinicianDelivered.size());
                    System.debug('Clinican did not indicate the correct amount of sessions compared to the number of service deliveries they have done for this client.');
                }
        	} else {
                form.enrtcr__Client__c.addError('Could not find a Service Agreement with rate type HSTP for this client');
                System.debug('Did not retreive any currennt Service agreements with name "HSTP SA" from this client');
            }      	
    	}
    }
}