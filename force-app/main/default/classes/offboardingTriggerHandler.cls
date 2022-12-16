public with sharing class offboardingTriggerHandler {
    //This class is to generate a list of tasks when a new offboarder is created, assigning them to the correct office managers and supervisors
    //Tasks for the People and Culture team (HR, Talent, and L&D) are sent out through 3 email alerts in SF (not in this Apex code)
	private List<Task> tasks = new List<Task>();
    
    //get the queue ID for L&D and Talent
    List<Group> queueIDs = new List<Group>();    
    Map<String,String> queueTypes = new Map<String, String>();  
    
    public offboardingTriggerHandler(List<Offboarding__c> input) {
        if (input.size() == 0) {
            System.debug('No offboarders came through the trigger');
        }
        for (Offboarding__c offboarder : input) {
            if (offboarder == NULL) {
                continue;
            }
            createTasks(offboarder);
        }
        
        insert tasks;
    }
    
    private void createTasks(Offboarding__c offboarder) {
        //Id adminId = getAdmin(offboarder.Site__r.Name);
       	Id adminId = [SELECT id, Office_Admin__r.Id FROM enrtcr__Site__c WHERE id =: offboarder.Site__c LIMIT 1][0].Office_Admin__c;
        String dept = [SELECT id, Internal_Banding__c FROM Contact WHERE id =: offboarder.Offboarding_Name__c LIMIT 1][0].Internal_Banding__c;
        User[] financePersons = [SELECT id FROM User WHERE Name = 'Sarah Caldwell' LIMIT 1];
        Id financePerson = null;
        if (financePersons.size() > 0) {
            financePerson = financePersons[0].Id;
        }
        if (adminId == null) {
            adminId = '0052v00000h1toVAAQ';
        }
        String state = [SELECT id, enrtcr__Business_State__c FROM enrtcr__Site__c WHERE id =: offboarder.Site__c LIMIT 1][0].enrtcr__Business_State__c;
        ID adminTL = '0052v00000a7izCAAQ';
        if (state == 'NSW') {adminTL = '0052v00000gN5lcAAC';} else if (state == 'VIC') {adminTL = '0052v00000hrVUTAA2';}
        
        //get the queue ID for L&D and Talent
        queueIDs = [select Id, DeveloperName from Group WHERE Type = 'Queue' AND (DeveloperName = 'L_D_Queue' OR DeveloperName = 'Talent_Queue')];
        
        for(Integer i = 0; i < queueIDs.size(); i++){
            queueTypes.put(queueIDs[i].DeveloperName, queueIDs[i].Id);
        }
        
        createITTasks(offboarder);
        createAdminTasks(offboarder, adminId, adminTL);
        createDSTasks(offboarder);
        createFinanceTasks(offboarder, dept, financePerson);
    }
    
    private void createITTasks(Offboarding__c offboarder) {
        tasks.add(newTask(offboarder.Exit_Date__c, -14, 'IT', '00G2v0000052Zr2', 'Normal', 'Not Started', 'IT Offboarding on Lumary and Microsoft', offboarder.Id));
    }
    
    private void createAdminTasks(Offboarding__c offboarder, Id admin, Id adminTL) {
        tasks.add(newTask(offboarder.Exit_Date__c, 0, 'Admin', adminTL != null ? adminTL : '0052v00000h1tqbAAA', 'Normal', 'Not Started', 'Remove From Proda', offboarder.Id));
        tasks.add(newTask(offboarder.Exit_Date__c, 0, 'Admin', admin, 'Normal', 'Not Started', 'Send back IT Assets', offboarder.Id));
        tasks.add(newTask(offboarder.Exit_Date__c, 0, 'Admin', admin, 'Normal', 'Not Started', 'Request Final Kilometers', offboarder.Id));
        tasks.add(newTask(offboarder.Exit_Date__c, 0, 'Admin', admin, 'Normal', 'Not Started', 'Ensure Employee Hands Back Business Cards, Kits, Office Key', offboarder.Id));
        tasks.add(newTask(offboarder.Exit_Date__c, 0, 'Admin', admin, 'Normal', 'Not Started', 'Ensure Resource & Therapy Tools are Returned', offboarder.Id));
        tasks.add(newTask(offboarder.Exit_Date__c, 1, 'Admin', admin, 'Normal', 'Not Started', 'Update Key and Access Pass Register', offboarder.Id));
        tasks.add(newTask(offboarder.Exit_Date__c, 0, 'Admin', admin, 'Normal', 'Not Started', 'Collection of Mobile, Laptop, Passwords (including Apple ID password)', offboarder.Id));
        tasks.add(newTask(offboarder.Exit_Date__c, 0, 'Admin', '0052v00000gN24yAAC', 'Normal', 'Not Started', 'Review Proda', offboarder.Id));
    }
    
    private void createFinanceTasks(Offboarding__c offboarder, String dept, Id financePerson) {        
        if (dept.contains('Manager') || dept.contains('National Clinical Lead')) {
            tasks.add(newTask(offboarder.Exit_Date__c, -1, 'Admin', financePerson != null ? financePerson : '0052v00000h1tqbAAA', 'Normal', 'Not Started', 'Revoke Credit Card', offboarder.Id));
        }
    }
    
    private void createDSTasks(Offboarding__c offboarder) {        
        tasks.add(newTask(offboarder.Exit_Date__c, 0, 'DS', '00G2v0000052Zr2', 'Normal', 'Not Started', 'Ensure all upcoming initials have been reallocated', offboarder.Id));
		tasks.add(newTask(offboarder.Exit_Date__c, 1, 'DS', '00G2v0000052Zr2', 'Normal', 'Not Started', 'Ensure All Timesheets have been Submitted', offboarder.Id));
		tasks.add(newTask(offboarder.Exit_Date__c, 1, 'DS', '00G2v0000052Zr2', 'Normal', 'Not Started', 'Update Associated Provider (Clinical Supervisor)', offboarder.Id));
		tasks.add(newTask(offboarder.Exit_Date__c, -14, 'DS', '00G2v0000052Zr2', 'Normal', 'Not Started', 'Notification to Management/IT and Team', offboarder.Id));
		tasks.add(newTask(offboarder.Exit_Date__c, -14, 'DS', '00G2v0000052Zr2', 'Normal', 'Not Started', 'Arrangement of Farewell', offboarder.Id));
        tasks.add(newTask(offboarder.Exit_Date__c, -1, 'DS', '00G2v0000052Zr2', 'Normal', 'Not Started', 'Ensure All files are uploaded to SharePoint', offboarder.Id)); 
        tasks.add(newTask(offboarder.Exit_Date__c, -1, 'DS', '00G2v0000052Zr2', 'Normal', 'Not Started', 'Ensure Clinician Signs Out and Resets Mobile Device in Settings', offboarder.Id)); 
        tasks.add(newTask(offboarder.Exit_Date__c, -7, 'DS', '00G2v0000052Zr2', 'Normal', 'Not Started', 'Check PD Allowance', offboarder.Id));
        tasks.add(newTask(offboarder.Exit_Date__c, -7, 'DS', '00G2v0000052Zr2', 'Normal', 'Not Started', 'Update capacity tracker on Lumary', offboarder.Id));
        tasks.add(newTask(offboarder.Exit_Date__c, 7, 'DS', '00G2v0000052Zr2', 'Normal', 'Not Started', 'Ensure entire caseload has been marked as Inactive on Associations tab', offboarder.Id));

    }    
    
    private Task newTask(Date exitDate, Integer dueDateDays,  String OnboardingCategory, Id AssignedTo, String Priority, String Status, String Subject, Id RelatedTo) {
        Task t = new Task();
        t.ActivityDate = exitDate + dueDateDays;
        t.Onboarding_category__c = OnboardingCategory;
        t.OwnerId = AssignedTo;
        t.Priority = Priority;
        t.Status = Status;
        t.Subject = Subject;
        t.WhatId = RelatedTo;
        t.RecordTypeId = '0122v000001eZuHAAU';
        t.Type = 'Offboarding';
        
        return t;
    }
}