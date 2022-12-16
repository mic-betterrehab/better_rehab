public class BR_MiscSABatch implements Database.Batchable<sObject> {
    
    String jsonString;
    Map<String, Object> classSettings;
    
    //saSAIListMap
    Map<Id, List<enrtcr__Support_Contract_Item__c>> saSAIListMap = new Map<Id, List<enrtcr__Support_Contract_Item__c>>();
    
    //SA - Old amount
    Map<Id, Double> SAOldTotalAllocation = new Map<Id, Double>();
    
    //SA id - SA object
    Map<Id, enrtcr__Support_Contract__c> saMap = new Map<Id, enrtcr__Support_Contract__c>();
    
    Date startDates;
    Date endDates;
    String status;
    
    public Map<String, String> auditMap = new Map<String, String>();
    
    List<enrtcr__Support_Contract__c> firstSA = new List<enrtcr__Support_Contract__c>();
    List<enrtcr__Support_Contract__c> secondSA = new List<enrtcr__Support_Contract__c>();
    List<enrtcr__Support_Contract_Item__c> firstSAI = new List<enrtcr__Support_Contract_Item__c>();
    List<enrtcr__Support_Contract_Item__c> secondSAI = new List<enrtcr__Support_Contract_Item__c>();
    
    //when calling this constructor, pass in the Service Agreement ID
    //constructor
    public BR_MiscSABatch(){
        // get the kpi flow settings from settings object
        List<Setting__c> kpiFlowSettings = [SELECT id, Name, Settings__c FROM Setting__c WHERE Name = 'Misc SA To Recalibrate' LIMIT 1];
        
        // convert class settings string into Map
        jsonString = kpiFlowSettings[0].Settings__c;
        classSettings = Utility.JSONtoMap(jsonString);
        
        findStartEndDate();
        status = 'Current';
        
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        //Add the name of all the Contacts in the settings
        List<String> contactsToFind = new List<String>();
        for(String name : classSettings.keySet()){
            contactsToFind.add(name);
        }
        
        //get the SA for all the contacts in the list
        String Query = 'SELECT id, Name, enrtcr__Client__c, enrtcr__Client__r.Name, enrtcr__Status__c, enrtcr__Start_Date__c, enrtcr__End_Date__c, enrtcr__Remaining_Balance__c, enrtcr__Total_Allocation__c '
            + 'FROM enrtcr__Support_Contract__c '
            + 'WHERE enrtcr__Client__r.Name IN: contactsToFind'; 
        
        return Database.getQueryLocator(Query);
    }
    
    public void execute(Database.BatchableContext BC,List<enrtcr__Support_Contract__c> scope){
        System.debug('List of SAs returned: ' + scope);
        
        for(enrtcr__Support_Contract__c serviceAgreement : scope){
            SAOldTotalAllocation.put(serviceAgreement.Id, serviceAgreement.enrtcr__Total_Allocation__c);
            
            saMap.put(serviceAgreement.Id, serviceAgreement);
            
            List<enrtcr__Support_Contract_Item__c> listOfRelatedSAIs = [SELECT id,
                                                                        Name,
                                                                        enrtcr__Support_Category_Remaining__c,
                                                                        enrtcr__Support_Category_Amount__c,
                                                                        enrtcr__Support_Category_Allocated__c,
                                                                        enrtcr__Support_Category__r.Name, //use this field to get the line item name
                                                                        enrtcr__Support_Contract__r.Id,
                                                                        enrtcr__Support_Contract__r.enrtcr__Client__r.Id,
                                                                        enrtcr__Support_Contract__r.enrtcr__Client__r.Name
                                                                        FROM enrtcr__Support_Contract_Item__c
                                                                        WHERE enrtcr__Support_Contract__r.Id =: serviceAgreement.Id
                                                                       AND enrtcr__Support_Category__r.Name != NULL]; //add is not null to avoid getting uncategorised SAIs
            
            //map it - assuming 1 SA only has 1 SAI
            saSAIListMap.put(serviceAgreement.Id, listOfRelatedSAIs);
            
            System.debug('List of SAIs returned: ' + listOfRelatedSAIs);
        }
        
        System.debug('Map of SA and SAIs: ' + saSAIListMap);
        
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
      	 
        System.debug('Number of DML statements that have been called in this Apex Batch: ' + Limits.getDMLStatements());
        System.debug('Number of DML statements limit for this Apex Batch: ' + Limits.getLimitDMLStatements());
        System.debug('Number of Queries used in this apex batch so far: ' + Limits.getQueries());
        System.debug('Number of rows queried in this apex code so far: ' + Limits.getDmlRows());
    }
    
    private void findRefreshAmountSAI(List<enrtcr__Support_Contract_Item__c> listSAIs, Id serviceAgreementId){
        List<enrtcr__Support_Contract_Item__c> updatedSAIs = new List<enrtcr__Support_Contract_Item__c>();
        
        // the amount to refresh the SAI with.
        Double refreshAmount = 0;
        
        // calculate the amount to refresh based on the support category for each SAI 
        for(enrtcr__Support_Contract_Item__c SAI : listSAIs){            
            for(String name : classSettings.keySet()){
                if(SAI.enrtcr__Support_Contract__r.enrtcr__Client__r.Name == name){
                    refreshAmount = Double.valueOf(classSettings.get(name));
                }
            }
            
            // calculate update amount (unused $ do not roll over to next cycle)
            // this updateAmount needs to be added to the SC's support cat amount
            Double updateAmount = refreshAmount - SAI.enrtcr__Support_Category_Remaining__c;
            
            System.debug('Current SAI in loop: ' + SAI.Name);
            
            System.debug('Updating ' + SAI.enrtcr__Support_Category__r.Name + ' from ' + SAI.enrtcr__Support_Category_Amount__c + ' + ' + updateAmount );
            
            // update the category amount - this is basically the net amount that will be used to update
            SAI.enrtcr__Support_Category_Amount__c += updateAmount; //can this be carried over to the next method?	
            updatedSAIs.add(SAI);
        }
        
        //call the check method to decide which one to update first
        checkSAUpdateOrder(updatedSAIs, serviceAgreementId);     
        System.debug('Calling the checkSAUpdateOrder method. What are the SAIs that are passed? ' + updatedSAIs);
    }
    
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
        System.debug('sa: ' + sa);
        System.debug('newNetAmount: ' + newNetAmount);
        
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
    
    private void findStartEndDate(){
        KPI__c kpiDates = KPI__c.getInstance();
        startDates = kpiDates.Date_Start__c;
        endDates = kpiDates.Date_End__c;
    }
    
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