public class BR_SupervisionSABatch implements Database.Batchable<sObject> {
    
    // supervision <-> worker map
    public Map <Id, Contact> supvisToWorker = new Map<Id, Contact>(); //ID is the supervision ID, contact is the worker contact
    public Map<String, String> errorLog = new Map<String,String>();
    private List<String> allowedCD;
    private List<String> allowedCSIB;
    private List<String> allowedOSIB;
    public List<enrtcr__Support_Contract__c> firstSA = new List<enrtcr__Support_Contract__c>();
    public List<enrtcr__Support_Contract__c> secondSA = new List<enrtcr__Support_Contract__c>();
    public List<enrtcr__Support_Contract_Item__c> firstSAI = new List<enrtcr__Support_Contract_Item__c>();
    public List<enrtcr__Support_Contract_Item__c> secondSAI = new List<enrtcr__Support_Contract_Item__c>();
    Map<Id, enrtcr__Support_Contract_Item__c> secondSAIMap = new Map<Id, enrtcr__Support_Contract_Item__c>();
    public Date startDates;
    public Date endDates;
    public String status;
    public Map<String, String> auditMap = new Map<String, String>();
    
    //SAI - SA
    public Map<enrtcr__Support_Contract_Item__c, Id> SAIandSA = new Map<enrtcr__Support_Contract_Item__c, Id>();
    
    //saSAIListMap
    public Map<Id, List<enrtcr__Support_Contract_Item__c>> saSAIListMap = new Map<Id, List<enrtcr__Support_Contract_Item__c>>();
    
    //SA - Old amount
    public Map<Id, Double> SAOldTotalAllocation = new Map<Id, Double>();
    
    //SA id - SA object
    public Map<Id, enrtcr__Support_Contract__c> saMap = new Map<Id, enrtcr__Support_Contract__c>();
    
    //when calling this constructor, pass in the Service Agreement ID
    //constructor
    public BR_SupervisionSABatch(){
        //call this class with params of a list of workers (assuming batches of 50 workers at one go?)
        this.supvisToWorker = supvisToWorker;
        
        initialiseLists();
        buildContactRelationships();
        findStartEndDate();        
        status = 'Current';
    }
    
    //this will return a max of 50 million records
    public Database.QueryLocator start(Database.BatchableContext BC){
        //query the SAs
        String name = 'Supervision SA';
        String Query = 'SELECT id, Name, enrtcr__Client__c, enrtcr__Status__c, enrtcr__Start_Date__c, enrtcr__End_Date__c, enrtcr__Remaining_Balance__c, enrtcr__Total_Allocation__c '
            + 'FROM enrtcr__Support_Contract__c '
            + 'WHERE Name =: name'; //will return EVERYONE'S SAs (inactive and active workers)
        
        return Database.getQueryLocator(Query);
    }
    
    //for each execution of this method, max allowable DML statements is 150
    //will process 200 records at a time, unless stated otherwise in the executeBatch method
    //will return the ID of the new batch job - https://developer.salesforce.com/forums/?id=9060G000000XczmQAC
    //for each execution of this method, max allowable DML statements is 150
    public void execute(Database.BatchableContext BC,List<enrtcr__Support_Contract__c> scope){   
        System.debug('How many service agreements in the scope for this 1 batch? ' + scope.size());
        
        for(enrtcr__Support_Contract__c serviceAgreement : scope){
            System.debug('Currently process serviceAgreement in execution scope: ' + serviceAgreement.Id);
            
            SAOldTotalAllocation.put(serviceAgreement.Id, serviceAgreement.enrtcr__Total_Allocation__c);
            
            saMap.put(serviceAgreement.Id, serviceAgreement);
            
            //only allowed 200 SOQL queries, will refresh for every batch
            List<enrtcr__Support_Contract_Item__c> listOfRelatedSAIs = [SELECT id,
                                                                        Name,
                                                                        enrtcr__Support_Category_Remaining__c,
                                                                        enrtcr__Support_Category_Amount__c,
                                                                        enrtcr__Support_Category_Allocated__c,
                                                                        enrtcr__Support_Category__r.Name, //use this field to get the CS/OS/QA
                                                                        enrtcr__Support_Contract__r.Id,
                                                                        enrtcr__Support_Contract__r.enrtcr__Client__r.Id
                                                                        FROM enrtcr__Support_Contract_Item__c
                                                                        WHERE enrtcr__Support_Contract__r.Id =: serviceAgreement.Id
                                                                        AND (enrtcr__Support_Category__r.Name = 'Operational Supervision' OR enrtcr__Support_Category__r.Name = '1:1'
                                                                             OR enrtcr__Support_Category__r.Name = 'Joint Visit'
                                                                             OR enrtcr__Support_Category__r.Name = 'QA Support'
                                                                             OR enrtcr__Support_Category__r.Name = 'Clinical Audit')];
            //map it
            saSAIListMap.put(serviceAgreement.Id, listOfRelatedSAIs);
        }
        
        //find the refresh amount for every set of SAIs
        Set<Id> saId = saSAIListMap.keySet(); //there should be 40 service agreements in this keyset for 1 batch
        
        for(Id serviceAgreementId : saId){     
            
            findRefreshAmountSAI(saSAIListMap.get(serviceAgreementId), serviceAgreementId);
        }
        
        //convert the list to a map        
        //do a database update - technically, these are 4 DML statements
        Database.SaveResult[] resultOne = Database.update(firstSA, false);
        logResult(resultOne);
        Database.SaveResult[] resultTwo = Database.update(firstSAI, false);
        logResult(resultTwo);
        Database.SaveResult[] resultThree = Database.update(secondSA, false);
        logResult(resultThree);
        Database.SaveResult[] resultFour = Database.update(secondSAI, false);
        logResult(resultFour);
    }
    
    //send an email to me once finished
    public void finish(Database.BatchableContext BC){
        System.debug('In the FINISH method now!');
        //query the table that lists information about batch jobs
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors,
                            JobItemsProcessed,
                            JobType,
                            TotalJobItems, CreatedBy.Email
                            FROM AsyncApexJob
                            WHERE Id = :bc.getJobId()];
        // call some utility to print
        System.debug(job); 
    }
    
    private void initialiseLists() {
        allowedCD = new List<String>{'Occupational Therapy', 'Speech Pathology', 'Physiotherapy', 'PBS', 'Exercise Physiology','Allied Health Assistant'};
            allowedCSIB = new List<String>{'Graduate Clinician', 'Early Practicing Clinician', 'Practicing Clinician', 'Senior Clinician', 'AHA Early Service', 'AHA Full Service', 'AHA Community','AHA Senior Service'};
                allowedOSIB = new List<String>{'Graduate Clinician', 'Early Practicing Clinician', 'Practicing Clinician', 'Senior Clinician'};
                    }
    
    private boolean buildContactRelationships() {
        
        // get all contacts that have the supervision field filled in
        List<Contact> superRelos = [SELECT id, 
                                    Name, 
                                    Supervision__c, 
                                    Record_Type_Name__c,
                                    Internal_Banding__c,
                                    Clinician_Discipline__c,
                                    New_Framework__c,
                                    Is_new_framework__c,
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
            //map will store the supervision profile ID vs the worker Contact
            supvisToWorker.put(worker.Supervision__c, worker);
        }
        return true;
    }
    
    private void findStartEndDate(){
        KPI__c kpiDates = KPI__c.getInstance();
        startDates = kpiDates.Date_Start__c;
        endDates = kpiDates.Date_End__c;
    }
    
    //will be called 40 times in 1 batch
    private void findRefreshAmountSAI(List<enrtcr__Support_Contract_Item__c> listSAIs, Id serviceAgreementId){
        System.debug('Current service agreement in process: ' + serviceAgreementId);
        System.debug('Current SAIs in process: ' + listSAIs);
        List<enrtcr__Support_Contract_Item__c> updatedSAIs = new List<enrtcr__Support_Contract_Item__c>();
        
        // the amount to refresh the SAI with.
        Double refreshAmount = 0;
        
        // calculate the amount to refresh based on the support category for each SAI (total 3 at a time)
        for(enrtcr__Support_Contract_Item__c SAI : listSAIs){
            
            // find the worker of the supervision profile linked
            Contact worker = supvisToWorker.get(SAI.enrtcr__Support_Contract__r.enrtcr__Client__r.Id);
            
            System.debug('worker = ' + worker);
            
            // error check
            if (worker == null) {
                errorLog.put('SAI Attribution Error', 'No worker found for SAI ' + serviceAgreementId);
                System.debug('Worker is null ' + serviceAgreementId);
                continue;
            }
            
            if (worker.enrtcr__Status__c != 'Current') {
                errorLog.put('Worker Status Error', 'Worker is not current ' + worker.Id);
                System.debug('Worker is not current ' + worker.Id);
                continue;
            }
            
            if (worker.Clinician_Discipline__c == NULL) {
                errorLog.put('Worker CD Error', 'Worker does not have a clinician discipline ' + worker.Id);
                System.debug('Worker does not have a clinician discipline ' + worker.Id);
                continue;
            }
            
            if (worker.Internal_Banding__c == NULL) {
                errorLog.put('Worker IB Error', 'Worker does not have an IB ' + worker.Id);
                System.debug('Worker does not have an IB ' + worker.Id);
                continue;
            }
            
            switch on (SAI.enrtcr__Support_Category__r.Name) {
                when 'QA Support' {
                    // CD check
                    if (!allowedCD.contains(worker.Clinician_Discipline__c)) {
                        errorLog.put('Invalid Data Error', 'worker ' + worker.Id + ' has invalid clinician discipline ' + worker.Clinician_Discipline__c + ' for QA Support SAI calculation');
                        continue;
                    }
                    
                    // do calculation
                    switch on (worker.Clinician_Discipline__c) {
                        when 'Speech Pathology' {refreshAmount = 4 * worker.FTE__c;}
                        when 'Physiotherapy' {refreshAmount = 4 * worker.FTE__c;}
                        when 'Exercise Physiology' {refreshAmount = 4 * worker.FTE__c;}
                        when 'Occupational Therapy' {refreshAmount = 6 * worker.FTE__c;}
                        when 'PBS' {refreshAmount = 6 * worker.FTE__c;}
                    }
                }
                when '1:1' {
                    
                    // CD check
                    if (!allowedCD.contains(worker.Clinician_Discipline__c)) {
                        errorLog.put('Invalid Data Error', 'worker ' + worker.Id + ' has invalid clinician discipline ' + worker.Clinician_Discipline__c + ' for 1:1 SAI calculation');
                        continue;
                    }
                    
                    // IB check
                    if (!allowedCSIB.contains(worker.Internal_Banding__c)) {
                        errorLog.put('Invalid Data Error', 'worker ' + worker.Id + ' has invalid internal banding ' + worker.Internal_Banding__c + ' for 1:1 SAI calculation');
                        continue;
                    }
                    
                    switch on (worker.Internal_Banding__c) {
                        when 'Graduate Clinician' {refreshAmount = 2;}
                        when 'Early Practicing Clinician' {refreshAmount = 2;}
                        when 'Practicing Clinician' {refreshAmount = 1;}
                        when 'Senior Clinician' {refreshAmount = 1;}
                        when 'AHA Early Service' {refreshAmount = 1;}
                        when 'AHA Full Service' {refreshAmount = 1;}
                        when 'AHA Community' {refreshAmount = 1;}
                        when 'AHA Senior Service' {refreshAmount = 1;}
                        when else {
                            errorLog.put('Invalid Data Error', 'worker ' + worker.Id + ' has invalid internal banding ' + worker.Internal_Banding__c + ' for 1:1 SAI calculation');
                            refreshAmount = 0;
                        }
                    }

                }	
                when 'Joint Visit' {
                    
                    switch on (worker.Internal_Banding__c) {
                        when 'Graduate Clinician' {refreshAmount = 4;}
                        when 'Early Practicing Clinician' {refreshAmount = 2;}
                        when 'Practicing Clinician' {refreshAmount = 2;}
                        when 'Senior Clinician' {refreshAmount = 2;}
                        when else {
                            errorLog.put('Invalid Data Error', 'worker ' + worker.Id + ' has invalid internal banding ' + worker.Internal_Banding__c + ' for JV SAI calculation');
                            refreshAmount = 0;
                        }
                    }

                }
                when 'Operational Supervision' {
                    //if worker is in the old system
                    if(worker.New_Framework__c == FALSE){
                        // do calculation
                        switch on (worker.Internal_Banding__c) {
                            when 'Graduate Clinician' {refreshAmount = 2 * worker.FTE__c;}
                            when 'Early Practicing Clinician' {refreshAmount = 2 * worker.FTE__c;}
                            when 'Practicing Clinician' {refreshAmount = 1 * worker.FTE__c;}
                            when 'Senior Clinician' {refreshAmount = 0.5 * worker.FTE__c;}
                            when else {
                                errorLog.put('Invalid Data Error', 'worker ' + worker.Id + ' has invalid internal banding ' + worker.Internal_Banding__c + ' for Operational Support SAI calculation');
                            }
                        }
                    } else {
                        refreshAmount = 0;
                    }
                    
                }
                when 'Clinical Audit' {
                    // IB check
                    if (!allowedOSIB.contains(worker.Internal_Banding__c)) {
                        errorLog.put('Invalid Data Error', 'worker ' + worker.Id + ' has invalid internal banding ' + worker.Internal_Banding__c + ' for Clinical Audit SAI calculation');
                        continue;
                    }               
                    
                    refreshAmount = 1 * worker.FTE__c;
                }
                when else {
                    errorLog.put('SAI Support Category Error', 'Invalid support category ' + SAI.enrtcr__Support_Category__r.Name + ' for SAI ' + SAI.Id);
                    continue;
                }	
            }
            
            // calculate update amount (unused $ do not roll over to next cycle)
            // this updateAmount needs to be added to the SC's support cat amount
            Double updateAmount = refreshAmount - SAI.enrtcr__Support_Category_Remaining__c;
            
            System.debug('Updating ' + SAI.enrtcr__Support_Category__r.Name + ' from ' + SAI.enrtcr__Support_Category_Amount__c + ' + ' + updateAmount );
            
            // update the category amount - this is basically the net amount that will be used to update
            SAI.enrtcr__Support_Category_Amount__c += updateAmount; //can this be carried over to the next method?	
            updatedSAIs.add(SAI); //should be 3 in total after the loop finishes
        }
        //call the check method to decide which one to update first
        checkSAUpdateOrder(updatedSAIs, serviceAgreementId);     
        System.debug('Calling the checkSAUpdateOrder method. What are the SAIs that are passed? ' + updatedSAIs);
    }
    
    //need to check if this calculation is correct
    //process 1 sa at a time - 3 SAIs at a time
    private void checkSAUpdateOrder(List<enrtcr__Support_Contract_Item__c> updatedSAIs, Id serviceAgreementId){  
        System.debug('Inside checkSAUpdateOrder');
        //get the old SA net amount
        Double oldNetAmount = SAOldTotalAllocation.get(serviceAgreementId);
        Double newNetAmount = 0;
        //check the new remaining balance for each SAI
        for(enrtcr__Support_Contract_Item__c newSAI : updatedSAIs){
            //add 3 SAIs net amount
            newNetAmount += newSAI.enrtcr__Support_Category_Amount__c;
        }        
        
        enrtcr__Support_Contract__c sa = saMap.get(serviceAgreementId);
        sa.enrtcr__Total_Allocation__c = newNetAmount; //update the SA amount with the new amount 
        sa.enrtcr__Start_Date__c = startDates;
        sa.enrtcr__End_Date__c = endDates;
        sa.enrtcr__Status__c = status;        
        
        System.debug('What is the total net amount for this SA? ' + sa.enrtcr__Total_Allocation__c + 'for SA: ' + sa.Id);
        
        //increasing
        if(newNetAmount >= oldNetAmount){ //what is the rule for SA that doesn't increase or decrease?
            firstSA.add(sa);
            secondSAI.addAll(updatedSAIs);
            System.debug('new amount > old amount: updating SA first!');            
        } else if(newNetAmount < oldNetAmount) { //decreasing
            firstSAI.addAll(updatedSAIs);
            secondSA.add(sa);
            System.debug('new amount < old amount: updating SAI first!');
        }  
    }
    
    //log the database operation result
    private void logResult(Database.SaveResult[] srList){
        // Iterate through each returned result
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                System.debug('Successfully inserted record. Record ID: ' + sr.getId());
                auditMap.put(sr.getId(),'Successfully inserted record. Record ID: ' + sr.getId());
            }
            else {
                // Operation failed, so get all errors                
                for(Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Record fields that affected this error: ' + err.getFields());
                    auditMap.put(sr.getId(),'Failure in inserting record. Record ID: ' + sr.getId() + ' Message: ' + err.getStatusCode() + ': ' + err.getMessage());
                }
            }
        }
    }
}