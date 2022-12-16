public with sharing class br_actions {
    public String message {get;set;}
    public Id KPIEmployeeId {get;set;}
    public List<SelectOption> employees {get;set;}
    
    public br_actions() {
    	List<Contact> workers = Utility.getEmployees();
        
        employees = new List<SelectOption>();
        for (Contact worker : workers) {
            employees.add(new SelectOption(worker.id, worker.Name));
        }
        
        message = 'Loaded.';
    }
    
    public void recalibrateKPIAll() {
        br_kpiRecalibration KPIClassInstance = new br_kpiRecalibration(null);
        if (KPIClassInstance.classContructionValid == true) {
            String result = KPIClassInstance.performChecks(null);
        
            Action_Log__c audit = new Action_Log__c();
            audit.Action__c = 'KPI Recalibration Bulk';
            if (result == 'Success') {
                audit.Status__c = 'Success';
                audit.Response__c = Utility.maptoJSON(KPIClassInstance.auditMap);
            } else {
                audit.Status__c = 'Error';
                audit.Response__c = result;
            }
            
            insert audit;
        } 
    }
    
    public void recalibrateClinician() {
        if (KPIEmployeeId == null) {            
            message = 'Failed to recalibrate KPI for employee. Employee not found.';
        } else {
            br_kpiRecalibration KPIClassInstance = new br_kpiRecalibration(KPIEmployeeId);
            if (KPIClassInstance.classContructionValid == true) {
                String result = KPIClassInstance.performChecks(KPIEmployeeId);
                
                Action_Log__c audit = new Action_Log__c();
                audit.Action__c = 'KPI Recalibration Single';
                if (result == 'Success') {
                    audit.Status__c = 'Success';
                    audit.Response__c = Utility.maptoJSON(KPIClassInstance.auditMap);
                } else {
                    audit.Status__c = 'Error';
                    audit.Response__c = result;
                }
                insert audit;
            }
        }
    }
    
    /*public void recalibrateSSA() {   
        br_SARecalibration SAClassInstance = new br_SARecalibration();
        
        Action_Log__c audit = new Action_Log__c();
        audit.Action__c = 'SA Refresh All';
        
        Map<String, Object> logs = new Map<String, Object>();
        
        if (SAClassInstance.classContructValid == true) {
            
            SAClassInstance.findAndUpdateSSA();
            SAClassInstance.SAUpdateHandler('first');
            SAClassInstance.SAUpdateHandler('second');
            
            String resultSAIfirst = SAClassInstance.performSAIChanges('first'); 
           	String resultSAfirst = SAClassInstance.performSAChanges('first');
            
            String resultSAIsecond;
            if (resultSAfirst == 'Success') {
                resultSAIsecond = SAClassInstance.performSAIChanges('second');
            } else {
                logs.put('first run SA', resultSAfirst);
            }
            
            String resultSAsecond;
            if (resultSAIfirst == 'Success') {
                resultSAsecond = SAClassInstance.performSAChanges('second');
            } else {
                logs.put('first run SAI', resultSAIfirst);
            }
           	
            if (resultSAIsecond == 'Success' && resultSAsecond == 'Success') {
                audit.Status__c = 'Success';
                logs.put('update status', 'Success');   
            } else {
                audit.Status__c = 'Error';
                logs.put('second run SAI', resultSAIsecond);
                logs.put('second run SA', resultSAsecond);
            }
        } else {
            logs.put('Construction Error', 'There was an error constructing the class');
        }
        logs.put('errors', SAClassInstance.errorLog);
        audit.Response__c = Utility.maptoJSON(logs);
        insert audit;
    }*/
    
    public void recalibrateSABatch(){
        BR_SupervisionSABatch batch = new BR_SupervisionSABatch();
        ID batchId = Database.executeBatch(batch, 40);
        System.debug('in br actions: ' + batchId);
    }
    
    public void recalibrateMiscSABatch(){
        BR_MiscSABatch batch = new BR_MiscSABatch();
        ID batchId = Database.executeBatch(batch);
        System.debug('in br actions for Misc SA Batch: ' + batchId);
    }
    
    public void recalibrateRMSABatch(){
        BR_RMSABatch batch = new BR_RMSABatch();
        ID batchId = Database.executeBatch(batch, 40);
        System.debug('in br actions for rm sa: ' + batchId);
    }
    
    
    /*public void recalibrateTSSA() {
        br_SARecalibration SAClassInstance = new br_SARecalibration();
        
        Action_Log__c audit = new Action_Log__c();
        audit.Action__c = 'SA Refresh All';
        
        Map<String, Object> logs = new Map<String, Object>();
        
        if (SAClassInstance.classContructValid == true) {
            SAClassInstance.findAndUpdateTSSA();
            SAClassInstance.SAUpdateHandler('first');
            SAClassInstance.SAUpdateHandler('second');
            
            String resultSAIfirst = SAClassInstance.performSAIChanges('first'); 
           	String resultSAfirst = SAClassInstance.performSAChanges('first');
            
            String resultSAIsecond;
            if (resultSAfirst == 'Success') {
                resultSAIsecond = SAClassInstance.performSAIChanges('second');
            } else {
                logs.put('first run SA', resultSAfirst);
            }
            
            String resultSAsecond;
            if (resultSAIfirst == 'Success') {
                resultSAsecond = SAClassInstance.performSAChanges('second');
            } else {
                logs.put('first run SAI', resultSAIfirst);
            }
           	
            if (resultSAIsecond == 'Success' && resultSAsecond == 'Success') {
                audit.Status__c = 'Success';
                logs.put('update status', 'Success');   
            } else {
                audit.Status__c = 'Error';
                logs.put('second run SAI', resultSAIsecond);
                logs.put('second run SA', resultSAsecond);
            }
        } else {
            logs.put('Construction Error', 'There was an error constructing the class');
        }
        logs.put('errors', SAClassInstance.errorLog);
        audit.Response__c = Utility.maptoJSON(logs);
        insert audit;
    }*/
}