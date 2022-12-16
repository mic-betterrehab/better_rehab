@isTest
private class BR_ClinicalAuditSharingTest {
	//Test for the BR_ClinicalAuditSharing class
    @testSetup static void prepData(){
        // Select users for the test.
        User y = [SELECT Id FROM User WHERE IsActive = TRUE AND ProfileId =: [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1] LIMIT 1]; //find a sys admin user
        User x = [SELECT Id FROM User WHERE IsActive = TRUE AND ProfileId =: [SELECT Id FROM Profile WHERE Name='Enrite Care - Basic' limit 1] LIMIT 1]; //this is a basic clinician - the auditee
        
        List<Contact> lists = new List<Contact>();
        List<Contact> updatedContacts = new List<Contact>();
        
        //Create the client contact
        Contact newClient = TestObjects.createContact(1,'NDIS');
        lists.add(newClient);
        
        for (Integer i = 0 ; i < 3; i++){
            Contact newWorker = new Contact();
            newWorker.LastName = 'Worker';
            newWorker.FirstName = 'newW' + String.valueOf(i);
            newWorker.RecordTypeId = '0122v0000013OcoAAE';
            newWorker.enrtcr__Gender_Detail__c = 'Male';
            newWorker.enrtcr__Client_Region__c = 'NSW';
            newWorker.enrtcr__Start_Date__c = System.today();
            newWorker.Next_audit__c = System.today();
            newWorker.enrtcr__Status__c = 'Current';
            newWorker.enrtcr__Mobile__c = '04322355644';
            newWorker.Email = 'newWorker'+ String.valueOf(i) + '@betterrehab.com.au';
            newWorker.enrtcr__User__c = x.Id;
            
            lists.add(newWorker);
        }        
        
        insert lists;
        
        //Set 1 worker to have all CS and DS
        Contact employee = [SELECT id, Clinical_Supervisor__c, Direct_Supervisor__c FROM Contact WHERE Email = 'newWorker0@betterrehab.com.au'];
        Contact cs = [SELECT id, Clinical_Supervisor__c, Direct_Supervisor__c FROM Contact WHERE Email = 'newWorker1@betterrehab.com.au'];
        Contact ds = [SELECT id, Clinical_Supervisor__c, Direct_Supervisor__c FROM Contact WHERE Email = 'newWorker2@betterrehab.com.au'];
        
        employee.Clinical_Supervisor__c = cs.Id;
        employee.Direct_Supervisor__c = ds.Id; 
        updatedContacts.add(employee);
        
        update updatedContacts;
        
        //Create the clinical audit entry
        Clinical_Audit__c newAudit = new Clinical_Audit__c();
        newAudit.Name = 'Test Audit';
        newAudit.Client__c = newClient.Id;
        newAudit.Clinician__c = employee.Id;
        newAudit.Auditor__c = y.Id;
        newAudit.Audit_Type__c = 'Clinical Audit';
        insert newAudit;
    }
    
    @isTest static void testCreateCA(){
        Clinical_Audit__c newAudit = [SELECT Id FROM Clinical_Audit__c WHERE Name = 'Test Audit'];
        
        List<Clinical_Audit__Share> shareList = [SELECT Id, UserOrGroupId, AccessLevel, RowCause FROM Clinical_Audit__Share WHERE ParentId = :newAudit.Id AND AccessLevel = 'Read'];
        
        System.assertEquals(2,shareList.size());
        
    }
}