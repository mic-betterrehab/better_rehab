public with sharing class onboardingTriggerHandler {
    //This class is to generate a list of tasks when a new onboarder is created, assigning them to the correct office managers and supervisors
    //Tasks for the People and Culture team (HR, Talent, and L&D) are sent out through 4 email alerts in SF (not in this Apex code)
	/*private List<Task> tasks = new List<Task>();
    
    //get the queue ID for L&D and Talent
    List<Group> queueIDs = new List<Group>();    
    List<enrtcr__Site__c> assetId = new List<enrtcr__Site__c>();
    Map<String,String> queueTypes = new Map<String, String>();  
    Map<String,String> OMIds = new Map<String, String>(); 
    String state;
    String officeCountry;
    
    public onboardingTriggerHandler(List<Onboarding__c> input) {
        if (input.size() == 0) {
            System.debug('No onboarders came through the trigger');
        }
        for (Onboarding__c onboarder : input) {
            if (onboarder == NULL) {
                continue;
            }
            createTasks(onboarder);
        }
        insert tasks;
    }
   
    private void createTasks(Onboarding__c onboarder) {
        //assign variables
        Id recordId = onboarder.Id;
        Date startDate = onboarder.Start_Date__c;
        String office = onboarder.Office__c;
        officeCountry = onboarder.Site__r.Business_Country__c;
        String internalBanding = onboarder.Internal_Banding__c;
        
        //Id adminId = getAdmin(office);
        User[] financePersons = [SELECT id FROM User WHERE Name = 'Cindy Sun' LIMIT 1];
        Id financePerson = null;
        if (financePersons.size() > 0) {
            financePerson = financePersons[0].Id;
        }
        ID adminId = [SELECT id, Office_Admin__r.Id FROM enrtcr__Site__c WHERE id =: onboarder.Site__c LIMIT 1][0].Office_Admin__c;
        state = [SELECT id, enrtcr__Business_State__c FROM enrtcr__Site__c WHERE id =: onboarder.Site__c LIMIT 1][0].enrtcr__Business_State__c;
        ID adminTL = '0052v00000a7izCAAQ';
        if (adminId == null) {
            adminId = '0052v00000h1toVAAQ';
        }
        if (state == 'NSW') {adminTL = '0052v00000gN5lcAAC';} else if (state == 'VIC' || state == 'SA') {adminTL = '0052v00000hrVUTAA2';}
        
        //get the queue ID for L&D and Talent
        queueIDs = [select Id, DeveloperName from Group WHERE Type = 'Queue' AND (DeveloperName = 'L_D_Queue' OR DeveloperName = 'Talent_Queue')];
        
        for(Integer i = 0; i < queueIDs.size(); i++){
            queueTypes.put(queueIDs[i].DeveloperName, queueIDs[i].Id);
        }        
          
        //create main tasks
        createAdminTasks(startDate, adminId, recordId, financePerson, adminTL, internalBanding);
        
        System.debug('1 = ' + onboarder.Direct_Supervisor__c);
        //do empty checks and create supervisor tasks
        List<Contact> DSID;
        if (onboarder.Direct_Supervisor__c != null) {
            System.debug('2');
            DSID = [SELECT id, enrtcr__User__r.Id FROM Contact WHERE id =: onboarder.Direct_Supervisor__c LIMIT 1];
            if (DSID.size() > 0) {
                System.debug('Creating task for DS');
                createDSTasks(startDate, recordId, DSID[0].enrtcr__User__r.Id, internalBanding);
            }
        }
        if (onboarder.Direct_Supervisor__c == NULL || DSID.size() == 0) {
            System.debug('Creating task for task trash. size = ');
            createDSTasks(startDate, recordId, '0052v00000h1tqbAAA', internalBanding);
        }
        //0052v00000h1tqbAAA
                
        List<Contact> PCID;
        if (onboarder.Principal_Clinician__c != null) {
            PCID = [SELECT id, enrtcr__User__r.Id FROM Contact WHERE id =: onboarder.Principal_Clinician__c LIMIT 1];
            if (PCID.size() > 0) {
                createPCTasks(startDate, recordId, PCID[0].enrtcr__User__r.Id, internalBanding);
            }
        }
        if (onboarder.Principal_Clinician__c == null || PCID.size() == 0) {
            createPCTasks(startDate, recordId, '0052v00000h1tqbAAA', internalBanding);
        }
        
        List<Contact> SMID;
        if (onboarder.State_Manager__c != null) {
            SMID = [SELECT id, enrtcr__User__r.Id FROM Contact WHERE id =: onboarder.State_Manager__c LIMIT 1];
            if (SMID.size() > 0) {
            	createSMTasks(startDate, recordId, SMID[0].enrtcr__User__r.Id, internalBanding);
            }
        }
        if (onboarder.State_Manager__c == null || SMID.size() == 0) {
            createSMTasks(startDate, recordId, '0052v00000h1tqbAAA', internalBanding);
        }
        
        for (Task t : tasks) {
            if (t.OwnerId == null) {
                system.debug(t);
            }
        }
        
    }
    
    private void createAdminTasks(Date startDate, Id admin, Id recordId, Id financePerson, Id adminTL, String internalBanding) {
        List<Task> adminTasks = new List<Task>();
        
        //these tasks are for both student and non students
        adminTasks.add(newTask(startDate, -7, 'Admin', admin, 'Normal', 'Not Started', 'Assign Desk /Welcome Sign/', 'Onboarding-Pre-Comm', recordId));
        adminTasks.add(newTask(startDate, -7, 'Admin', admin, 'Normal', 'Not Started', 'Organisation of Welcome Desk', 'Onboarding-Pre-Comm', recordId));
        adminTasks.add(newTask(startDate, -7, 'Admin', admin, 'Normal', 'Not Started', 'Schedule a welcome morning tea/lunch (on new starters first day)', 'Onboarding-Pre-Comm', recordId));
        adminTasks.add(newTask(startDate, 0, 'Admin', admin, 'Normal', 'Not Started', 'Practical demonstration of duress alarm', 'Onboarding-Post-Comm', recordId));
        adminTasks.add(newTask(startDate, 0, 'Admin', admin, 'Normal', 'Not Started', 'Access Codes and Networks', 'Onboarding-Post-Comm', recordId));
        
        if(internalBanding == 'Student'){
            adminTasks.add(newTask(startDate, 0, 'Admin', admin, 'Normal', 'Not Started', 'Send Student Laptop', 'Onboarding-Pre-Comm', recordId));
        } else {
            adminTasks.add(newTask(startDate, -7, 'Admin', admin, 'Normal', 'Not Started', 'Create Business Card Template (ONLY IF CLIENT FACING OR HEAD OF DEPARTMENT)', 'Onboarding-Pre-Comm', recordId));
            adminTasks.add(newTask(startDate, 5, 'Other', adminTL != null ? adminTL : '0052v00000h1tqbAAA', 'Normal', 'Not Started', 'Accept PRODA request', 'Onboarding-Pre-Comm', recordId));
            adminTasks.add(newTask(startDate, 0, 'Other', adminTL != null ? adminTL : '0052v00000h1tqbAAA', 'Normal', 'Not Started', 'Replace aircall personal number with assigned work number', 'Onboarding-Post-Comm', recordId));
            adminTasks.add(newTask(startDate, -1, 'Admin', admin, 'Normal', 'Not Started', 'Office Key and Update Register on Lumary', 'Onboarding-Pre-Comm', recordId));
            adminTasks.add(newTask(startDate, -7, 'Admin', admin, 'Normal', 'Not Started', 'Order Name Badge', 'Onboarding-Pre-Comm', recordId));
            adminTasks.add(newTask(startDate, 0, 'Admin', admin, 'Normal', 'Not Started', 'Duress Alarm', 'Onboarding-Post-Comm', recordId));
            adminTasks.add(newTask(startDate, 5, 'Admin', admin, 'Normal', 'Not Started', 'Take headshot for Outlook profile', 'Onboarding-Post-Comm', recordId));
            adminTasks.add(newTask(startDate, 5, 'Other', '0052v00000i2PrrAAE', 'Normal', 'Not Started', 'Introduce Rachel to the New Starter', 'Onboarding-Post-Comm', recordId)); 
        } 
        
        if(officeCountry == 'New Zealand'){
            adminTasks.add(newTask(startDate, -3, 'Other', '0052v00000i9rx3AAA', 'Normal', 'Not Started', 'Add Payroll Details to Xero (NZ starters)', 'Onboarding-Pre-Comm', recordId));
        }
         
        this.tasks.addAll(adminTasks);
    }
    
    private void createDSTasks(Date startDate, Id recordId, Id DSID, String internalBanding) {
        List<Task> dsTasks = new List<Task>();
        
        //tasks for both student and non students
        dsTasks.add(newTask(startDate, -3, 'DS', DSID, 'Normal', 'Not Started', 'Create first week timetable', 'Onboarding-Pre-Comm', recordId));
        dsTasks.add(newTask(startDate, -7, 'DS', DSID, 'Normal', 'Not Started', 'Send Welcome Email', 'Onboarding-Pre-Comm', recordId));
        dsTasks.add(newTask(startDate, -5, 'DS', DSID, 'Normal', 'Not Started', 'Intro call with new starter', 'Onboarding-Pre-Comm', recordId));
        dsTasks.add(newTask(startDate, -3, 'DS', DSID, 'Normal', 'Not Started', 'Schedule shadowing appointments', 'Onboarding-Pre-Comm', recordId));
        dsTasks.add(newTask(startDate, 0, 'DS', DSID, 'Normal', 'Not Started', 'Associate with supervision profile', 'Onboarding-Post-Comm', recordId));       
        dsTasks.add(newTask(startDate, 5, 'DS', DSID, 'Normal', 'Not Started', 'Send Team Introduction Email', 'Onboarding-Post-Comm', recordId));
        dsTasks.add(newTask(startDate, 0, 'DS', DSID, 'Normal', 'Not Started', 'Office Tour and Staff Introductions', 'Onboarding-Post-Comm', recordId));
        dsTasks.add(newTask(startDate, 5, 'DS', DSID, 'Normal', 'Not Started', 'Equipment Sign-Off', 'Onboarding-Post-Comm', recordId));       
        dsTasks.add(newTask(startDate, 0, 'DS', DSID, 'Normal', 'Not Started', 'Run through emergency evacuation plan & location of first aid kit', 'Onboarding-Post-Comm', recordId));        
        dsTasks.add(newTask(startDate, 0, 'DS', DSID, 'Normal', 'Not Started', 'Administration Introduction Email', 'Onboarding-Post-Comm', recordId));
        dsTasks.add(newTask(startDate, 5, 'DS', DSID, 'Normal', 'Not Started', 'NDIS Equipment Procurement', 'Onboarding-Post-Comm', recordId));
        dsTasks.add(newTask(startDate, 5, 'DS', DSID, 'Normal', 'Not Started', 'Resources & SharePoint - soft copy and hard copy', 'Onboarding-Post-Comm', recordId));
        
        if(internalBanding != 'Student'){            
            dsTasks.add(newTask(startDate, -1, 'DS', DSID, 'Normal', 'Not Started', 'Add to applicable Teams groups', 'Onboarding-Pre-Comm', recordId));
            dsTasks.add(newTask(startDate, -1, 'DS', DSID, 'Normal', 'Not Started', 'Invite to applicable recurring meetings & public holidays', 'Onboarding-Pre-Comm', recordId));
            dsTasks.add(newTask(startDate, -7, 'DS', DSID, 'Normal', 'Not Started', 'Update capacity tracker on Lumary', 'Onboarding-Pre-Comm', recordId));
            dsTasks.add(newTask(startDate, -7, 'DS', DSID, 'Normal', 'Not Started', 'Make Welcome Call to New Employee', 'Onboarding-Pre-Comm', recordId));            
            dsTasks.add(newTask(startDate, 1, 'DS', DSID, 'Normal', 'Not Started', 'Career Guide Overview', 'Onboarding-Post-Comm', recordId));
            dsTasks.add(newTask(startDate, 5, 'DS', DSID, 'Normal', 'Not Started', 'Report Templates and examples', 'Onboarding-Post-Comm', recordId));
            dsTasks.add(newTask(startDate, 5, 'DS', DSID, 'Normal', 'Not Started', 'Report How-To Guides', 'Onboarding-Post-Comm', recordId));
            dsTasks.add(newTask(startDate, 5, 'DS', DSID, 'Normal', 'Not Started', 'Billing Guidelines', 'Onboarding-Post-Comm', recordId));
            dsTasks.add(newTask(startDate, 11, 'DS', DSID, 'Normal', 'Not Started', 'Organising appointments post 2nd week', 'Onboarding-Post-Comm', recordId));
            dsTasks.add(newTask(startDate, 11, 'DS', DSID, 'Normal', 'Not Started', 'Add to email groups, Sharepoint folders and recurring meetings', 'Onboarding-Post-Comm', recordId));
        }
        
        this.tasks.addAll(dsTasks);
    }
    
    private void createPCTasks(Date startDate, Id recordId, Id PCID, String internalBanding) {
        List<Task> pcTasks = new List<Task>();
        
        if(internalBanding != 'Student'){            
            pcTasks.add(newTask(startDate, -7, 'PC', PCID, 'Normal', 'Not Started', 'Order therapy pack (if required)', 'Onboarding-Pre-Comm', recordId));
        }
        
        this.tasks.addAll(pcTasks);
    }
    
    private void createSMTasks(Date startDate, Id recordId, Id SMID, String internalBanding) {
        List<Task> smTasks = new List<Task>();
        
        //Pre comm tasks
        
        //Post comm tasks
        if(internalBanding != 'Student'){
            smTasks.add(newTask(startDate, 1, 'SM', SMID, 'Normal', 'Not Started', 'Call to welcome to team', 'Onboarding-Post-Comm', recordId));
        }        
        
        this.tasks.addAll(smTasks);
    }
    
    private Task newTask(Date startDate, Integer dueDateDays, String OnboardingCategory, Id AssignedTo, String Priority, String Status, String Subject, String OnboardingType, Id RelatedTo) {
        Task t = new Task();
        t.ActivityDate = startDate + dueDateDays;
        t.Onboarding_category__c = OnboardingCategory;
        t.OwnerId = AssignedTo;
        t.Priority = Priority;
        t.Status = Status;
        t.Subject = Subject;
        t.Type = OnboardingType;
        t.WhatId = RelatedTo;
        t.RecordTypeId = '0122v000001eZuHAAU';
        
        return t;
    }*/
}