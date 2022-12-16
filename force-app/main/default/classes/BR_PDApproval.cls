public with sharing class BR_PDApproval {
    //This class is to update pd request according to the approval outcome
    List<PD_Request__c> toUpdate;
    List<PD_Approval__c> approvals;
    List<RecordType> pdRequestList = new List<RecordType>();
    Map<String,Id> pdRequestType = new Map<String,Id>();
    List<PD_Approval__c> updatedApproval = new List<PD_Approval__c>();
    List<Contact> contactsToUpdate = new List<Contact>();
    
    public BR_PDApproval(Map<Id, PD_Approval__c> newMap, Map<Id, PD_Approval__c> oldMap) {
        
        approvals = new List<PD_Approval__c>();        
        toUpdate = new List<PD_Request__c>();
        System.debug('Inside BR_PDApproval class now');
        System.debug('Size of updatedApproval: ' + updatedApproval.size());        
        
        //fill the map
        pdRequestList = [SELECT Id, DeveloperName, SObjectType FROM RecordType WHERE SObjectType = 'PD_Request__c'];
        for(RecordType ids : pdRequestList){
            pdRequestType.put(ids.DeveloperName, ids.Id);
        }
        
        //only process if the status changed
        for(PD_Approval__c pd : newMap.values()){
            PD_Approval__c oldPDA = oldMap.get(pd.Id);
            
            if(pd.Status__c != oldPDA.Status__c){
                System.debug('This PD approval has a change of status!');
                updatedApproval.add(pd);
            }
        }
        
        if(!updatedApproval.isEmpty()){
            //find the record type id of each of the updated approval's pd request
            List<PD_Approval__c> apps = [SELECT id, Approver_Contact__r.Id, Approver_Contact__r.Internal_Banding__c, Status__c, PD_Request__c, Position__c, PD_Request__r.RecordTypeId,
                                         PD_Request__r.Direct_Supervisor_ID__c, PD_Request__r.Regional_Manager__c, PD_Request__r.State_Manager__c, 
                                         PD_Request__r.Principal_Clinician__c, PD_Request__r.Dept_Manager_ID__c, PD_Request__r.RecordType.DeveloperName, Cost_from_Employee_s_Total_PD__c, Additional_BR_Contributions__c, Comment__c
                                         FROM PD_Approval__c WHERE Id IN :updatedApproval];
            
            for (Integer i = 0; i < apps.size(); i++) {
                
                System.debug('Inside the for loop in BR_PDApproval');
                System.debug('Record type id for each pd request: ' + updatedApproval[i].PD_Request__c);
                
                List<PD_Request__c> request = [SELECT id, RecordTypeID, Employee_Name__c, Employee_Name__r.Annual_PD_Balance__c, Employee_Name__r.Better_Rewards_PD_Balance__c, Employee_Name__r.Total_Remaining_PD_Balance__c, 
                                               Cost_of_Course__c, Date_bypass__c, Status__c, Comment__c FROM PD_Request__c WHERE id =: apps[i].PD_Request__c LIMIT 1];
                
                if(apps[i].Position__c != 'N/A'){         
                    switch on apps[i].PD_Request__r.RecordType.DeveloperName {
                        when 'Clinician' {checkClinicianStatus(apps[i], request);}
                        when 'Principal_Clinician' {checkPCStatus(apps[i], request);}
                        when 'Leadership' {checkLeaderStatus(apps[i], request);}
                        when 'Allied_Health_Assistant' {checkAHAStatus(apps[i], request);}
                        when 'Operational' {checkOperationalResult(apps[i], request);}                    
                    }
                } else if(apps[i].Position__c == 'N/A'){
                    blankPosition(apps[i], request);
                }
            }
        }
        
        System.debug('Checking the size of updated approvals in BR_PDApprovals: ' + approvals.size());
        
        insert approvals;
        update toUpdate;       
        update contactsToUpdate;
    }
    
    //Method 1 - For Clinician
    private void checkClinicianStatus(PD_Approval__c clinApp, List<PD_Request__c> request){
        
        System.debug('Inside check clinician approval result');
        
        List<PD_Approval__c> newApprovals = new List<PD_Approval__c>();
        
        //Get the PD Request details - need a list here to create the BR_PDApprovalCreation instance
        //List<PD_Request__c> request = [SELECT id, RecordTypeID, Cost_of_Course__c FROM PD_Request__c WHERE id =: clinApp.PD_Request__c LIMIT 1];  
        
        BR_PDApprovalCreation approvalCreationInstance = new BR_PDApprovalCreation(request); //here 
        
        //if anyone denies, then nothing else matter
        if(clinApp.Status__c == 'Denied'){
            //update the PD Request status to denied
            updateRequest(clinApp, request[0]);
            System.debug('Approval says no, PD Request is denied');
        }
        
        //if they say yes
        if(clinApp.Status__c == 'Approved'){
            //after PC, always go to RM
            if(clinApp.Position__c == 'Principal Clinician'){                
                PD_Approval__c approvalRM = approvalCreationInstance.createRecord(request[0], clinApp.PD_Request__r.Regional_Manager__c, clinApp);
                newApprovals.add(approvalRM);
                System.debug('Only creating RM approval for clinician');                 
            }
            
            //after RM, only goes to SM if RM says yes and >400
            if(clinApp.Position__c == 'Regional Manager'){
                
                if(request[0].Cost_of_course__c <= 400){
                    updateRequest(clinApp, request[0]);
                    System.debug('Less than 400');
                }
                
                //if request is > 400, will ask SM only if RM says yes
                if(request[0].Cost_of_Course__c > 400){ 
                    System.debug('More than 400');     
                    //how to check here if the SM is the same as RM
                    if(clinApp.PD_Request__r.State_Manager__c == clinApp.PD_Request__r.Regional_Manager__c){
                        updateRequest(clinApp, request[0]);
                    } else {                        
                        PD_Approval__c approvalSM = approvalCreationInstance.createRecord(request[0], clinApp.PD_Request__r.State_Manager__c, clinApp);
                        newApprovals.add(approvalSM);   
                    }
                                   
                }                    
            }
            
            //SM always has the final say
            if(clinApp.Position__c == 'State Manager'){
                updateRequest(clinApp, request[0]);
            }
        }
        
        //assign the newApprovals list to the list that will be inserted
        approvals.addAll(newApprovals);
        System.debug('Size of newApprovals list in check PC Result: ' + newApprovals.size());
    }
    
    //Method 2 - For Principal Clinician
    private void checkPCStatus(PD_Approval__c pcApp, List<PD_Request__c> request){
        
        System.debug('Inside check PC approval result');
        
        List<PD_Approval__c> newApprovals = new List<PD_Approval__c>();
        //List<PD_Request__c> request = [SELECT id, RecordTypeID, Cost_of_Course__c FROM PD_Request__c WHERE id =: pcApp.PD_Request__c LIMIT 1];   
        
        BR_PDApprovalCreation approvalCreationInstance = new BR_PDApprovalCreation(request); //here 
        
        //if anyone denies, then nothing else matter
        if(pcApp.Status__c == 'Denied'){
            updateRequest(pcApp, request[0]);
            System.debug('Approval says no, PD Request is denied');
        }

        if(pcApp.Status__c == 'Approved'){
            if(pcApp.Position__c == 'Direct Supervisor'){
                PD_Approval__c approvalSM = approvalCreationInstance.createRecord(request[0], pcApp.PD_Request__r.State_Manager__c, pcApp);
                newApprovals.add(approvalSM);                
            }
            
            if(pcApp.Position__c == 'State Manager'){
                updateRequest(pcApp, request[0]);                   
            }           
           
        }
        
        //assign the newApprovals list to the list that will be inserted
        approvals.addAll(newApprovals);
        System.debug('Size of newApprovals list in check PC Result: ' + newApprovals.size());
    }
    
    //Method 3 - For Leadership
    private void checkLeaderStatus(PD_Approval__c leadershipApp, List<PD_Request__c> request){
        
        System.debug('Inside check Leadership approval result');
        
        //List<PD_Request__c> request = [SELECT id, RecordTypeID, Cost_of_Course__c FROM PD_Request__c WHERE id =: leadershipApp.PD_Request__c LIMIT 1];   
        
        BR_PDApprovalCreation approvalCreationInstance = new BR_PDApprovalCreation(request); //here 
        
        //if anyone denies, then nothing else matter
        if(leadershipApp.Status__c == 'Denied'){
            updateRequest(leadershipApp, request[0]);
            System.debug('Approval says no, PD Request is denied');
        }
        
        if(leadershipApp.Status__c == 'Approved'){            
            updateRequest(leadershipApp, request[0]);             
        }
    }
    
    //Method 4 - For AHAs
    private void checkAHAStatus(PD_Approval__c ahaApp, List<PD_Request__c> request){
        
        System.debug('Inside check AHA approval result');
        List<PD_Approval__c> newApprovals = new List<PD_Approval__c>();
        //List<PD_Request__c> request = [SELECT id, RecordTypeID, Cost_of_Course__c FROM PD_Request__c WHERE id =: ahaApp.PD_Request__c LIMIT 1];   
        
        BR_PDApprovalCreation approvalCreationInstance = new BR_PDApprovalCreation(request); //here 
        
        //if anyone denies, then nothing else matter
        if(ahaApp.Status__c == 'Denied'){
            updateRequest(ahaApp, request[0]);
            System.debug('Approval says no, PD Request is denied');
        }
        
        if(ahaApp.Status__c == 'Approved'){
            if(ahaApp.Position__c == 'Regional Manager'){
                if(request[0].Cost_of_course__c <= 400){
                    updateRequest(ahaApp, request[0]);
                    System.debug('Less than 400');
                }
                
                if(request[0].Cost_of_course__c > 400){
                    System.debug('More than 400');
                    if(ahaApp.PD_Request__r.State_Manager__c == ahaApp.PD_Request__r.Regional_Manager__c){
                        updateRequest(ahaApp, request[0]);
                    } else {
                        PD_Approval__c approvalSM = approvalCreationInstance.createRecord(request[0], ahaApp.PD_Request__r.State_Manager__c, ahaApp);
                        newApprovals.add(approvalSM);   
                    }         
                }
            }

            if(ahaApp.Position__c == 'State Manager'){
                updateRequest(ahaApp, request[0]);                   
            }   
        }
        
        //assign the newApprovals list to the list that will be inserted
        approvals.addAll(newApprovals);
        System.debug('Size of newApprovals list in check PC Result: ' + newApprovals.size());
    }
    
    //Method 5 - For Operational
    private void checkOperationalResult(PD_Approval__c opsApp, List<PD_Request__c> request){
        System.debug('Inside check Operational approval result');
        List<PD_Approval__c> newApprovals = new List<PD_Approval__c>();
        //List<PD_Request__c> request = [SELECT id, RecordTypeID, Cost_of_Course__c FROM PD_Request__c WHERE id =: opsApp.PD_Request__c LIMIT 1];   
        
        BR_PDApprovalCreation approvalCreationInstance = new BR_PDApprovalCreation(request); //here 
        
        //if anyone denies, then nothing else matter
        if(opsApp.Status__c == 'Denied'){
            //update the PD Request status to denied
            updateRequest(opsApp, request[0]);
            System.debug('Approval says no, PD Request is denied');
        }
        
        if(opsApp.Status__c == 'Approved'){            
            if(opsApp.Position__c == 'Direct Supervisor'){
                //If your DS is the ops manager
                if(opsApp.Approver_Contact__r.Internal_Banding__c == 'Operations Manager'){
                    updateRequest(opsApp, request[0]);
                } else {
                    if(request[0].Cost_of_Course__c <= 400){
                        updateRequest(opsApp, request[0]);
                        System.debug('DS says yes, PD Request is approved');                    
                    }
                    
                    if(request[0].Cost_of_Course__c > 400){      	
                        PD_Approval__c approvalDeptMgr = approvalCreationInstance.createRecord(request[0], opsApp.PD_Request__r.Dept_Manager_ID__c, opsApp);
                        newApprovals.add(approvalDeptMgr);                  
                        System.debug('More than 400, creating Dept Mgr approval');
                    }   
                }              
                                 
            }
            
            //Ops Mgr always has the final say
            if(opsApp.Position__c == 'Department Manager'){
                updateRequest(opsApp, request[0]);
            }
        }
        
        //assign the newApprovals list to the list that will be inserted
        approvals.addAll(newApprovals);
        System.debug('Size of newApprovals list in check PC Result: ' + newApprovals.size());
    }
    
    //What to do if approver position is blank
    private void blankPosition(PD_Approval__c blankApproval, List<PD_Request__c> request){
        //blank position will happen if someone, who is not in the list of approver, gets assigned the task
        //means the previous approver did not approve within 7 days
        //should only get here if the approver is now an NCL or an SM
        System.debug('N/A position is detected');
        
        List<PD_Approval__c> newApprovals = new List<PD_Approval__c>();
        //List<PD_Request__c> request = [SELECT id, RecordTypeID, Cost_of_Course__c FROM PD_Request__c WHERE id =: blankApproval.PD_Request__c LIMIT 1];   
        
        BR_PDApprovalCreation approvalCreationInstance = new BR_PDApprovalCreation(request); //here 
        
        //if anyone denies, then nothing else matter
        if(blankApproval.Status__c == 'Denied'){
            //update the PD Request status to denied
            updateRequest(blankApproval, request[0]);
            System.debug('Approval says no, PD Request is denied');
        }
        
        if(blankApproval.Status__c == 'Approved'){
            //double check that it's a clinician type
            if(blankApproval.PD_Request__r.RecordTypeId == pdRequestType.get('Clinician')){
                System.debug('N/A is from clinician');
                //Getting the previous approver's contact ID
                PD_Approval__History[] pdaHistory = [SELECT Id, Field, OldValue, NewValue, ParentId FROM PD_Approval__History WHERE Field = 'Approver_Contact__c'AND DataType = 'EntityId' AND ParentId =: blankApproval.Id];
                
                if(pdaHistory.size() > 0){
                    Contact prevApprover = [SELECT Id, Direct_Supervisor__r.Id FROM Contact WHERE Id =: String.valueOf(pdaHistory[0].OldValue)];
                    if(blankApproval.Approver_Contact__r.Id == prevApprover.Direct_Supervisor__r.Id){  
                        //get it to move to the next stage (aka move to RM)
                        PD_Approval__c approvalRM = approvalCreationInstance.createRecord(request[0], blankApproval.PD_Request__r.Regional_Manager__c, blankApproval);
                        newApprovals.add(approvalRM);  
                    }
                }
            } else {
                System.debug('N/A is from ' + blankApproval.PD_Request__r.RecordType.DeveloperName);
            }
        }
                
        //assign the newApprovals list to the list that will be inserted
        approvals.addAll(newApprovals);
        System.debug('Size of newApprovals list in check PC Result: ' + newApprovals.size());       
    }    
    
    //Method to update request
    private void updateRequest(PD_Approval__c finalApproval, PD_Request__c request){
		System.debug('Inside update request');        
        
        //Get the request based on the known ID - add employee's PD Balances in the SOQL as well
        //PD_Request__c request = [SELECT id, Employee_Name__c, Date_bypass__c, Status__c, Comment__c FROM PD_Request__c WHERE id =: finalApproval.PD_Request__c];
        Contact e = [SELECT Id, Annual_PD_Balance__c, Better_Rewards_PD_Balance__c FROM Contact WHERE Id =: request.Employee_Name__c];        
        
        //updating the request status, subsidized cost, and comment
        request.Status__c = finalApproval.Status__c;
        request.Comment__c = finalApproval.Comment__c;
        request.Date_bypass__c = TRUE;
        
        //calculation to decide how much to be deducted from the PD balances
        Decimal remainingAmtToBeDeducted = 0;
        Decimal newRewardsPD = 0;
        
        //handle null PD balance
        if(e.Annual_PD_Balance__c == NULL){
            e.Annual_PD_Balance__c = 0;
        }
        
        if(e.Better_Rewards_PD_Balance__c == NULL){
            e.Better_Rewards_PD_Balance__c = 0;
        }
        
        if(finalApproval.Status__c == 'Approved'){
            Decimal newEmployeePD = e.Annual_PD_Balance__c - finalApproval.Cost_from_Employee_s_Total_PD__c;
            
            if(newEmployeePD < 0){
                remainingAmtToBeDeducted = newEmployeePD; //this will be a negative value
                newEmployeePD = 0;
                newRewardsPD = e.Better_Rewards_PD_Balance__c + remainingAmtToBeDeducted >= 0 ? e.Better_Rewards_PD_Balance__c + remainingAmtToBeDeducted : 0;
                request.Cost_from_Rewards_PD__c = e.Better_Rewards_PD_Balance__c - newRewardsPD;
            } else {
                request.Cost_from_Rewards_PD__c = 0;
            }        
            
            request.Additional_BR_Contribution__c = finalApproval.Additional_BR_Contributions__c;
            request.Cost_from_Annual_PD__c = e.Annual_PD_Balance__c - newEmployeePD;           
            
            //update the employee's profile
            e.Annual_PD_Balance__c = newEmployeePD;
            e.Better_Rewards_PD_Balance__c = e.Better_Rewards_PD_Balance__c - request.Cost_from_Rewards_PD__c;            
            contactsToUpdate.add(e);
            
        } else if(finalApproval.Status__c == 'Denied'){
            request.Additional_BR_Contribution__c = 0;            
            request.Cost_from_Annual_PD__c = 0;
            request.Cost_from_Rewards_PD__c = 0;
        }
        
        //add to the list
        toUpdate.add(request);     
        
    }
}