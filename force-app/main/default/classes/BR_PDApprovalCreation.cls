public with sharing class BR_PDApprovalCreation {
    //This class is for creating approval when a PD Request is first lodged and when subsequent approval has to be created
    List<PD_Approval__c> approvals;
    List<PD_Request__c> updatedPDRequests;
	List<RecordType> pdRequestList = new List<RecordType>();
    Map<String,Id> pdRequestType = new Map<String,Id>();    
    
    public BR_PDApprovalCreation(List<PD_Request__c> newPDRequests) {
        
        approvals = new List<PD_Approval__c>();
        updatedPDRequests = new List<PD_Request__c>();
        
        List<PD_Request__c> incomingRequests = [SELECT id, Cost_of_Course__c, Employee_Name__c, Employee_Name__r.Total_Remaining_PD_Balance__c, RecordTypeID, Regional_Manager__c, Principal_Clinician__c, Direct_Supervisor_ID__c FROM PD_Request__c WHERE id IN :newPDRequests];
        List<PD_Approval__c> existingApprovals = [SELECT id, Position__c, Status__c FROM PD_Approval__c WHERE PD_Request__c IN :newPDRequests];   //COLLECT MORE FIELDS HERE PLS
        
        pdRequestList = [SELECT Id, DeveloperName, SObjectType FROM RecordType WHERE SObjectType = 'PD_Request__c'];
        for(RecordType ids : pdRequestList){
            pdRequestType.put(ids.DeveloperName, ids.Id);
        }
        
        //Check whose approval to create based on the record type - this part of the code only runs for newly created PD request, as triggered in PD request trigger
        for (Integer i = 0; i < incomingRequests.size(); i++) {  
            System.debug('Record type ID is: ' + incomingRequests[i].RecordTypeId);
                
           	//Record Type 1 = Clinician
            if(incomingRequests[i].RecordTypeId == pdRequestType.get('Clinician')){
                if(existingApprovals.size() == 0){ 
                    PD_Approval__c pcApproval = createRecord(incomingRequests[i],incomingRequests[i].Principal_Clinician__c, null);  
                    approvals.add(pcApproval);   
                    System.debug('Clinician: Creating PC Approval');
                }      
            }
            
            //Record Type 2 and 3 = PC and Leadership
            if(incomingRequests[i].RecordTypeId == pdRequestType.get('Principal_Clinician') || incomingRequests[i].RecordTypeId == pdRequestType.get('Leadership')){
                if(existingApprovals.size() == 0){
                    PD_Approval__c dsApproval = createRecord(incomingRequests[i],incomingRequests[i].Direct_Supervisor_ID__c, null);  
                    approvals.add(dsApproval);     
                    System.debug('PC or Leadership: Creating DS Approval');
                }                
            }
            
            //Record Type 4 = AHA
            if(incomingRequests[i].RecordTypeId == pdRequestType.get('Allied_Health_Assistant')){
                if(existingApprovals.size() == 0){                    
                    PD_Approval__c rmApproval = createRecord(incomingRequests[i],incomingRequests[i].Regional_Manager__c, null);  
                    approvals.add(rmApproval);     
                    System.debug('AHA: Creating RM Approval');
                }
            }
            
            //Record Type 5 = Operational
            if(incomingRequests[i].RecordTypeId == pdRequestType.get('Operational')){
                if(existingApprovals.size() == 0){  
                    PD_Approval__c dsApproval = createRecord(incomingRequests[i], incomingRequests[i].Direct_Supervisor_ID__c, null);  
                    approvals.add(dsApproval);     
                    System.debug('Operational: Creating DS Approval');  
                }      
            }                            
                        
        }   
        
        insert approvals;   
        update updatedPDRequests;
    }
    
    //this method is called from within this class and BR_PDApproval class to create subsequent PD approvals
    //add PD_Approval__c prevApproval as the 3rd param - put null for the above code    
    public PD_Approval__c createRecord(PD_Request__c pdRequest, Id supervisorId, PD_Approval__c prevApproval){
        PD_Approval__c newApproval = new PD_Approval__c();
        
        if(supervisorId != NULL){ 
            newApproval.Approver_Contact__c = supervisorId;
            newApproval.Status__c = 'Pending';
            newApproval.PD_Request__c = pdRequest.Id;                         
        } 
        
        //if prevApproval == NULL, this means we are making the 1st approval record for this PD request
        if(prevApproval == NULL){
            //we want to pre-fill the PD Approval cost fields to make it easier for users to approve
            if(pdRequest.Cost_of_Course__c <= pdRequest.Employee_Name__r.Total_Remaining_PD_Balance__c){
                newApproval.Additional_BR_Contributions__c = 0;
                newApproval.Cost_from_Employee_s_Total_PD__c = pdRequest.Cost_of_Course__c;
            } else if(pdRequest.Cost_of_Course__c > pdRequest.Employee_Name__r.Total_Remaining_PD_Balance__c){
                newApproval.Additional_BR_Contributions__c = 0;
                newApproval.Cost_from_Employee_s_Total_PD__c = pdRequest.Employee_Name__r.Total_Remaining_PD_Balance__c;
            }
        } else {
            newApproval.Additional_BR_Contributions__c = prevApproval.Additional_BR_Contributions__c;
            newApproval.Cost_from_Employee_s_Total_PD__c = prevApproval.Cost_from_Employee_s_Total_PD__c;
        }        
        
        System.debug('Supervisor ID is not null and PDA is created with the ID of: ' + newApproval.Id);      
        return newApproval; 
    }   
    
  }