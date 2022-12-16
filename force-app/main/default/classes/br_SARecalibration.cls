public with sharing class br_SARecalibration { 
    //this class is only for refreshing team support SA - ALL will use new system as of monday
    
    // supervision <-> worker map
    /*Map <Id, Contact> supvisToWorker = new Map<Id, Contact>();
    
    // direct supervisor id (contact) <-> list of supervisees (contact) map
    private Map<Id, List<Contact>> regionalSupervisees = new Map<Id, List<Contact>>();
    
    // list of supervision service agreement items to update
    private List<enrtcr__Support_Contract_Item__c> firstSupervisionSAIs = new List<enrtcr__Support_Contract_Item__c>();
    private List<enrtcr__Support_Contract_Item__c> secondSupervisionSAIs = new List<enrtcr__Support_Contract_Item__c>();
    
    // list of team support service agreement items to update
    private List<enrtcr__Support_Contract_Item__c> secondTSSAIs = new List<enrtcr__Support_Contract_Item__c>();
    private List<enrtcr__Support_Contract_Item__c> firstTSSAIs = new List<enrtcr__Support_Contract_Item__c>();
    
    // list of service agreements to update
    private List<enrtcr__Support_Contract__c> firstServiceAgreements = new List<enrtcr__Support_Contract__c>();
    private List<enrtcr__Support_Contract__c> secondServiceAgreements = new List<enrtcr__Support_Contract__c>();
    
    // map for SA and amount to increment allocation
    private Map<Id, Double> firstSAIncrement = new Map<Id, Double>();
    private Map<Id, Double> secondSAIncrement = new Map<Id, Double>();
    
    // allowed clinician disciplines
    private List<String> allowedCD;
    
    // allowed Clin support IB's
    private List<String> allowedCSIB;
    
    // allowed Op Sup IB's
    private List<String> allowedOSIB;
    
    // error log for all operations
    public Map<String, String> errorLog = new Map<String,String>();
    
    // class construction status
    public Boolean classContructValid = true;
    
     public static KPI__c KPI_SETTINGS {
        get {
            if (KPI_SETTINGS == null) {
                KPI_SETTINGS = KPI__c.getOrgDefaults();
            }
            return KPI_SETTINGS;
        }
        set;
    }
    
    public br_SARecalibration() {
        //initialise checklist arrays
        initialiseLists();
        
		// map supervision profile to worker profile
        if (buildContactRelationships() == false) {
            errorLog.put('Contruction Error', 'Could not build relationships');
            classContructValid = false;
        }
        
        // get all employees (contact)
        List<Contact> employees = Utility.getEmployees();
        
        if (employees == null) {
            errorLog.put('Contruction Error', 'Employees List cannot be null');
            classContructValid = false;
        }
        // find all direct supervisees and map them to class variable
        buildDSrelationships(employees);
    }
    
    // update the service agreements
    public void SAUpdateHandler(String filter) {
        for (enrtcr__Support_Contract__c SA : [SELECT 
                                               		id, 
                                               		Name, 
                                               		enrtcr__Total_Allocation__c
                                               FROM enrtcr__Support_Contract__c 
                                               WHERE id IN : (filter == 'first' ? firstSAIncrement.keySet() : secondSAIncrement.keySet())
                                              ]) 
        {
            if (filter == 'first') {
                SA.enrtcr__Total_Allocation__c += firstSAIncrement.get(SA.Id);
                secondServiceAgreements.add(SA);
            } else {
                SA.enrtcr__Total_Allocation__c += secondSAIncrement.get(SA.Id);
                firstServiceAgreements.add(SA);
            }
            
            SA.enrtcr__Start_Date__c = KPI_SETTINGS.Date_Start__c;
            SA.enrtcr__End_Date__c = KPI_SETTINGS.Date_End__c;
        }
    }
    
    public String performSAChanges(String filter) {
        try {
            if (filter == 'first') {update firstServiceAgreements;} else {update secondServiceAgreements;}      
            return 'Success';
        } catch (DMLException e) {
            System.debug(e.getMessage());
            return e.getMessage();
        }
    }
    
    public String performSAIChanges(String filter) {
        if (filter == 'first') {
            try {
                update firstSupervisionSAIs;
                update firstTSSAIs;
                return 'Success';
            } catch (DMLException e) {
                System.debug(e.getMessage());
                return e.getMessage();
            }
        } else if (filter == 'second') {
			try {
                update secondSupervisionSAIs;
                update secondTSSAIs;
                return 'Success';
            } catch (DMLException e) {
                return e.getMessage();
            }
        }
        
        return 'Success';
    }

    private boolean buildContactRelationships() {
        
        // get all contacts that have the supervision field filled in
        List<Contact> superRelos = [SELECT id, 
                                    		Name, 
                                    		Supervision__c, 
                                    		Record_Type_Name__c,
                                    		Internal_Banding__c,
                                    		Clinician_Discipline__c,
                                    		Weeks_Completed__c,
                                    		FTE__c,
                                    		enrtcr__Status__c
                                    FROM Contact 
                                    WHERE Supervision__c != null];
        
        // return the function if nothing is returned
        if (superRelos == null) {
            return false;
        }
        
        // return the function if list returned is empty
        if (superRelos.size() == 0) {
            return false;
        }
        
        // single for loop (trusting data is correct)
        
        for (Contact worker : superRelos) {
            if (worker.Record_Type_Name__c != 'Employee') {
                continue;
            }
            supvisToWorker.put(worker.Supervision__c, worker);
        }
        return true;
    }
    
    public void buildDSrelationships(List<Contact> allEmployees) {
         for (Contact c : allEmployees) {
         	// ensure rm field is populated
            if (c.Regional_Manager__c != null) {
                // if rm is listed in map already, only need to add to ds's list
                if ( regionalSupervisees.get(c.Regional_Manager__c) == null ) {
                    regionalSupervisees.put(c.Regional_Manager__c, new List<Contact>{c});
                } else {
                    // if ds is not listed in map, create new list with supervisee and add to map
                    List<Contact> supervisees = regionalSupervisees.get(c.Regional_Manager__c);
                    supervisees.add(c);
                    regionalSupervisees.put(c.Regional_Manager__c, supervisees);
                }
            }
        }
    }
    
    public void findAndUpdateTSSA() {
        
        List<enrtcr__Support_Contract_Item__c> updatedSAIs = new List<enrtcr__Support_Contract_Item__c>();
        
    	for (enrtcr__Support_Contract_Item__c SAI : [SELECT id, 
                                                     		Name, 
                                                     		enrtcr__Support_Category_Remaining__c,
                                                     		enrtcr__Support_Category_Amount__c,
                                                     		enrtcr__Support_Category_Allocated__c,
                                                     		enrtcr__Support_Category__r.Name,
                                                     		enrtcr__Support_Contract__r.Id,
                                                     		enrtcr__Support_Contract__r.enrtcr__Client__r.Id //this will be the regional manager's supervision profile
                                                     FROM enrtcr__Support_Contract_Item__c 
                                                     WHERE enrtcr__Support_Contract__r.Name = 'RM SA'
                                                     	AND enrtcr__Support_Category__r.Name != NULL
                                                    ]) 
        {
            // get the worker profile of the regional manager
            Contact RMWorker = supvisToWorker.get(SAI.enrtcr__Support_Contract__r.enrtcr__Client__r.Id);
            
            // error checking
            if (RMWorker == null) {
               	errorLog.put('SAI Attribution Error', 'No worker found for SAI ' + SAI.Id);
            	continue;
            }
            
            if (RMWorker.enrtcr__Status__c != 'Current') {
                System.debug('RM is not current ' + RMWorker.Id);
                continue;
            }
            
            // find the list of their supervisees
            List<Contact> supervisees = regionalSupervisees.get(RMWorker.Id);
            
            // error checking
            if (supervisees == null) {
                errorLog.put('Supervisee List Allocation Error', 'Could not gather direct supervisees for ' + RMWorker.Id);
                continue;
            }
            
            // amount to refresh SAI with
            Double refreshAmount = 0;
            
            switch on (SAI.enrtcr__Support_Category__r.Name){
                when 'Onboarding'{refreshAmount = 80;}
                when 'Offboarding'{refreshAmount = 20;}
                when 'Mid Probation Review'{refreshAmount = 20;}
                when 'Probation Review'{refreshAmount = 20;}
                when 'Support Plan'{refreshAmount = 10;}
                when 'Performance Improvement Plan'{refreshAmount = 10;}
                when 'Business Development'{refreshAmount = 10;}
                when else {
                    errorLog.put('SAI Support Category Error', 'Invalid support category ' + SAI.enrtcr__Support_Category__r.Name + ' for SAI ' + SAI.Id);
                    continue;
                }
            }
            
            // calculate update amount (unused $ do not roll over to next cycle)
            Double updateAmount = refreshAmount - SAI.enrtcr__Support_Category_Remaining__c;
                
            System.debug('Updating ' + SAI.enrtcr__Support_Category__r.Name + ' from ' + SAI.enrtcr__Support_Category_Remaining__c + ' to ' + SAI.enrtcr__Support_Category_Amount__c + ' + ' + updateAmount );
            
            // update the category amount
            SAI.enrtcr__Support_Category_Amount__c += updateAmount;
            updatedSAIs.add(SAI);
        }  
        
        //call the check method to decide which one to update first
        //checkSAUpdateOrder(updatedSAIs, serviceAgreementId);     
        System.debug('Calling the checkSAUpdateOrder method. What are the SAIs that are passed? ' + updatedSAIs);
    }
    
    private void trackSAChanges(Map<Id, Double> saMap, Double updateAmount, Id SA) {
        if (!saMap.containsKey(SA)) {
            saMap.put(SA, updateAmount);
        } else {
            Double newRefreshAmount = saMap.get(SA) + updateAmount;
            saMap.put(SA, newRefreshAmount);
        }
    }
    
    //NOT USED ANYMORE
    public Double findAmount(Contact supervisee) {
        // do calculation
        if(supervisee.Internal_Banding__c == 'Graduate Clinician'){
            return (supervisee.FTE__c) * 1.5 * 4;
        } else if(supervisee.Internal_Banding__c == 'Early Practicing Clinician'){
            return (supervisee.FTE__c) * 1 * 4;
        } else if(supervisee.Internal_Banding__c == 'Practicing Clinician' || supervisee.Internal_Banding__c == 'Senior Clinician' || supervisee.Internal_Banding__c == 'AHA Early Service' || supervisee.Internal_Banding__c == 'AHA Full Service' || supervisee.Internal_Banding__c == 'AHA Community' || supervisee.Internal_Banding__c == 'AHA Senior Service'){
            return (supervisee.FTE__c) * 0.75 * 4;
        } else {
            errorLog.put('Invalid Data Error', 'supervisee ' + supervisee.Id + ' for RM ' + supervisee.Regional_Manager__c + ' has an invalid internal banding of ' + supervisee.Internal_Banding__c);
            return 0;
        }
    }
    
    private void initialiseLists() {
        allowedCD = new List<String>{'Occupational Therapy', 'Speech Pathology', 'Physiotherapy', 'PBS', 'Exercise Physiology'};
        allowedCSIB = new List<String>{'Graduate Clinician', 'Early Practicing Clinician', 'Practicing Clinician', 'Senior Clinician'};
        allowedOSIB = new List<String>{'Graduate Clinician', 'Early Practicing Clinician', 'Practicing Clinician', 'Senior Clinician', 'AHA Early Service', 'AHA Full Service', 'AHA Community', 'AHA Senior Service'};
    }*/
}