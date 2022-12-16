@isTest
private class br_kpiRecalibrationTest {
    static testMethod void validateSingleRecalibration() {
        User supervisor = [SELECT id, Name, KPI__c FROM User WHERE IsActive = TRUE AND ProfileId =: [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1] limit 1];
        
       	Contact supervisorContact = new Contact();
        supervisorContact.LastName = 'super';
        supervisorContact.FirstName = supervisor.Name;
        supervisorContact.RecordTypeId = '0122v0000013OcoAAE';
        supervisorContact.enrtcr__Gender_Detail__c = 'Male';
        supervisorContact.enrtcr__Client_Region__c = 'NSW';
        supervisorContact.enrtcr__Start_Date__c = System.today();
        supervisorContact.enrtcr__Status__c = 'Current';
        supervisorContact.enrtcr__Mobile__c = '04322355644';
        supervisorContact.Clinician_Discipline__c = 'Occupational Therapy';
        supervisorContact.Internal_Banding__c = 'Senior Clinician';
        supervisorContact.Email = 'supervisor@betterrehab.com.au';
        supervisorContact.FTE__c = 0.8;
        supervisorContact.enrtcr__User__c = supervisor.Id;
        
        insert supervisorContact;
        
        User[] users = [SELECT id, Name, KPI__c, Email, CommunityNickname FROM User WHERE ProfileId =: [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1] LIMIT 5];
        
        List<Contact> contacts = new List<Contact>();
        
        for (User u : users) {
            Contact newWorker = new Contact();
            newWorker.LastName = 'super';
            newWorker.FirstName = u.Name;
            newWorker.RecordTypeId = '0122v0000013OcoAAE';
            newWorker.enrtcr__Gender_Detail__c = 'Male';
            newWorker.enrtcr__Client_Region__c = 'NSW';
            newWorker.enrtcr__Start_Date__c = System.today();
            newWorker.enrtcr__Status__c = 'Current';
            newWorker.enrtcr__Mobile__c = '04322355644';
            newWorker.Clinician_Discipline__c = 'Occupational Therapy';
        	newWorker.Internal_Banding__c = 'Graduate Clinician';
            newWorker.enrtcr__Start_Date__c = System.today().addDays(-200);
            newWorker.Email = u.CommunityNickname + '@betterrehab.com.au';
            newWorker.enrtcr__User__c = u.Id;
            newWorker.FTE__c = 0.9;
            newWorker.Direct_Supervisor__c = supervisorContact.Id;
            newWorker.New_Framework__c = TRUE;
            contacts.add(newWorker);
        }
        
        insert contacts;
        
        Setting__c kpiflow = new Setting__c();
        kpiFlow.Name = 'kpiFlow';
        kpiFlow.Settings__c = '{"baseKPI":"25","AHA Early Service":"10","AHA Full Service":"15","AHA Community":"20","AHA Senior Service":"22","baseKPI NZ":"27.5"}';
            
        insert kpiFlow;
        
        Test.startTest();
        
        br_actions page = new br_actions();
        page.KPIEmployeeId = supervisorContact.Id;
        page.recalibrateClinician();
        
        Test.stopTest();
        
        User newSup = [SELECT id, Name,	KPI__c FROM User WHERE id =: supervisor.Id];
        Action_Log__c[] actionLogs = [SELECT id, Status__c FROM Action_Log__c LIMIT 1];
        System.assertEquals(12.50, newSup.KPI__c);
        System.assertEquals(1, actionLogs.size());
        System.assertEquals('Success', actionLogs[0].Status__c);
        
        
    }
}