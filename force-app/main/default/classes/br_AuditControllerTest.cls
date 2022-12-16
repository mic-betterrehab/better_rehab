@isTest
private class br_AuditControllerTest {
    
    //Passed the threshold AND didn't fail any autofail questions
    static testMethod void successfulAudit() {
        Setting__c Clinical_Audit_Settings = TestObjects.createSetting('Clinical Audit', TestConstants.getClinicalAuditSetting());
        insert Clinical_Audit_Settings;
        
        User[] users = [SELECT id FROM User WHERE IsActive = TRUE AND ProfileId =: [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1] limit 2];
        
        // the user going to complete the audit on the worker
        User auditor = users[1];
        
        // the user profile of the worker getting audited
        User x = users[0];

        // person to get audited
        Contact newWorker = new Contact();
        newWorker.LastName = 'super';
        newWorker.FirstName = 'clin';
        newWorker.RecordTypeId = '0122v0000013OcoAAE';
        newWorker.enrtcr__Gender_Detail__c = 'Male';
        newWorker.enrtcr__Client_Region__c = 'NSW';
        newWorker.enrtcr__Start_Date__c = System.today() - 365;
        newWorker.enrtcr__Status__c = 'Current';
        newWorker.enrtcr__Mobile__c = '04322355644';
        newWorker.Email = 'clinsup@betterrehab.com.au';
        newWorker.Next_Audit__c = System.today();
        newWorker.enrtcr__User__c = x.Id; 
        insert newWorker;
        
        // client of worker (for purposes of auto choosing a participant in the Audit flow)
        Contact client = TestObjects.createContact(1, 'NDIS');
        insert client;
        
        // creating client clinician of worker and participant
        enrtcr__Staff_Allocation__c clientClinician = new enrtcr__Staff_Allocation__c();
        clientClinician.Client__c = client.Id;
        clientClinician.Clinician__c = newWorker.Id;
        clientClinician.Clinician_Status__c = 'Active';
        clientClinician.Name = 'myclient';
        insert clientClinician;
        
        
        Test.startTest();
        PageReference auditPage = Page.BR_Audit;
        Test.setCurrentPage(auditPage);
        auditPage.getParameters().put('Id', String.valueOf(newWorker.Id));
        auditPage.getParameters().put('Name', String.valueOf(newWorker.Name));
        ApexPages.StandardController sc = new ApexPages.StandardController(newWorker);
        br_AuditController UC = new br_AuditController(sc);
        
        UC.Auditor = auditor.Id;
        UC.clin = newWorker;
        //UC.Participant = client.Id;
        UC.finalClinArea = 'OT – AT';
        
        for (AuditSectionPackage section : UC.sections) {
            section.taskName = 'task for ' + section.sectionTitle;
            for (AuditQuestionPackage question : section.questions) {
                question.score = String.valueOf(question.maxScore);
            } 
        }

		UC.strengths = 'very strong';
        UC.improvements = 'can improve';
	        
        UC.submit();
        Test.stopTest();
		
        Clinical_Audit__c[] audits = [SELECT id, Status__c FROM Clinical_Audit__c];
        
        System.debug('size ' + audits.size());
		System.assertEquals(1, audits.size());
        System.assertEquals('CONFORMS', audits[0].Status__c);
        
        Task[] tasks = [SELECT id, Subject FROM Task WHERE WhatId =: audits[0].Id];

        System.assertEquals(UC.sections.size() + 2, tasks.size());
    }
    
    // test a user that is in the monthly audite cycle being moved into the quarterly stream
    static testMethod void monthlyStreamToQuarterly() {
        System.debug('Monthly to Quarterly');
        Setting__c Clinical_Audit_Settings = TestObjects.createSetting('Clinical Audit', TestConstants.getClinicalAuditSetting());
        insert Clinical_Audit_Settings;
        
        Integer CYCLE_PERIOD = 28;

        User[] users = [SELECT id FROM User WHERE IsActive = TRUE AND ProfileId =: [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1] limit 2];
        
        // the user going to complete the audit on the worker
        User auditor = users[1];
        
        // the user profile of the worker getting audited
        User x = users[0];

        // person to get audited
        Contact newWorker = new Contact();
        newWorker.LastName = 'super';
        newWorker.FirstName = 'clin';
        newWorker.RecordTypeId = '0122v0000013OcoAAE';
        newWorker.enrtcr__Gender_Detail__c = 'Male';
        newWorker.enrtcr__Client_Region__c = 'NSW';
        newWorker.enrtcr__Start_Date__c = System.today() - 365;
        newWorker.enrtcr__Status__c = 'Current';
        newWorker.enrtcr__Mobile__c = '04322355644';
        newWorker.Email = 'clinsup@betterrehab.com.au';
        newWorker.Next_Audit__c = System.today();
        newWorker.enrtcr__User__c = x.Id; 
        insert newWorker;
        
        // client of worker (for purposes of auto choosing a participant in the Audit flow)
        Contact client = TestObjects.createContact(1, 'NDIS');
        insert client;
        
        // history of audits for worker
        List<Clinical_Audit__c> historicalAudits = new List<Clinical_Audit__c>();
        
        Clinical_Audit__c CA_History = new Clinical_Audit__c();
        CA_History.Auditor__c = auditor.Id;
        CA_History.Client__c = client.Id;
        CA_History.Clinician__c = newWorker.Id;
        CA_History.Clinical_Area__c = 'OT – AT';
        CA_History.Numerator__c = 12;
        CA_History.Denominator__c = 15;
        CA_History.Status__c = 'CONFORMS';
        CA_History.Audit_Type__c = 'Clinical Audit';

        historicalAudits.add(CA_History);

        insert historicalAudits;
        
        Date NextAuditDate = [SELECT id, Next_Audit__c FROM Contact WHERE id =: newWorker.Id].Next_Audit__c;
        // testing the trigger for a worker who has passed probation and has passed their 2nd audit
        Test.startTest();
            Clinical_Audit__c CA_Test = new Clinical_Audit__c();
            CA_Test.Auditor__c = auditor.Id;
            CA_Test.Client__c = client.Id;
            CA_Test.Clinician__c = newWorker.Id;
            CA_Test.Clinical_Area__c = 'OT – AT';
            CA_Test.Numerator__c = 12;
            CA_Test.Denominator__c = 15;
            CA_Test.Status__c = 'CONFORMS';
        	CA_Test.Audit_Type__c = 'Clinical Audit';
        	
        	insert CA_Test;
        Test.stopTest();
		
        Contact worker = [SELECT id, Next_Audit__c FROM Contact WHERE id =: newWorker.Id];

		System.assertEquals(NextAuditDate + (3 * CYCLE_PERIOD), worker.Next_Audit__c);
    }

    // test a user that is in the monthly audite cycle not being moved into the quarterly stream because of fail history
    static testMethod void lastAuditWasFailTest() {
       	Setting__c Clinical_Audit_Settings = TestObjects.createSetting('Clinical Audit', TestConstants.getClinicalAuditSetting());
        insert Clinical_Audit_Settings;
        
        Integer CYCLE_PERIOD = 28;

        User[] users = [SELECT id FROM User WHERE IsActive = TRUE AND ProfileId =: [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1] limit 2];
        
        // the user going to complete the audit on the worker
        User auditor = users[1];
        
        // the user profile of the worker getting audited
        User x = users[0];

        // person to get audited
        Contact newWorker = new Contact();
        newWorker.LastName = 'super';
        newWorker.FirstName = 'clin';
        newWorker.RecordTypeId = '0122v0000013OcoAAE';
        newWorker.enrtcr__Gender_Detail__c = 'Male';
        newWorker.enrtcr__Client_Region__c = 'NSW';
        newWorker.enrtcr__Start_Date__c = System.today() - 365;
        newWorker.enrtcr__Status__c = 'Current';
        newWorker.enrtcr__Mobile__c = '04322355644';
        newWorker.Email = 'clinsup@betterrehab.com.au';
        newWorker.Next_Audit__c = System.today();
        newWorker.enrtcr__User__c = x.Id; 
        insert newWorker;
        
        // client of worker (for purposes of auto choosing a participant in the Audit flow)
        Contact client = TestObjects.createContact(1, 'NDIS');
        insert client;
        
        // history of audits for worker
        List<Clinical_Audit__c> historicalAudits = new List<Clinical_Audit__c>();
        
        Clinical_Audit__c CA_History = new Clinical_Audit__c();
        CA_History.Auditor__c = auditor.Id;
        CA_History.Client__c = client.Id;
        CA_History.Clinician__c = newWorker.Id;
        CA_History.Clinical_Area__c = 'OT – AT';
        CA_History.Numerator__c = 12;
        CA_History.Denominator__c = 15;
        CA_History.Status__c = 'DOES NOT CONFORM';
        CA_History.Audit_Type__c = 'Clinical Audit';

        historicalAudits.add(CA_History);

        insert historicalAudits;
        
        Date NextAuditDate = [SELECT id, Next_Audit__c FROM Contact WHERE id =: newWorker.Id].Next_Audit__c;
        // testing the trigger for a worker who has passed probation and has passed their 2nd audit
        Test.startTest();
            Clinical_Audit__c CA_Test = new Clinical_Audit__c();
            CA_Test.Auditor__c = auditor.Id;
            CA_Test.Client__c = client.Id;
            CA_Test.Clinician__c = newWorker.Id;
            CA_Test.Clinical_Area__c = 'OT – AT';
            CA_Test.Numerator__c = 12;
            CA_Test.Denominator__c = 15;
            CA_Test.Status__c = 'CONFORMS';
        	CA_Test.Audit_Type__c = 'Clinical Audit';
        	
        	insert CA_Test;
        Test.stopTest();
		
        Contact worker = [SELECT id, Next_Audit__c FROM Contact WHERE id =: newWorker.Id];

		System.assertEquals(NextAuditDate + CYCLE_PERIOD, worker.Next_Audit__c);
    }

    // test a user that is in the quarterly audit cycle moving to monthly because of a fail
    static testMethod void quarterlyStreamToMonthly() {
        System.debug('Quarterly To Monthly');
        Setting__c Clinical_Audit_Settings = TestObjects.createSetting('Clinical Audit', TestConstants.getClinicalAuditSetting());
        insert Clinical_Audit_Settings;
        
        Integer CYCLE_PERIOD = 28;

        User[] users = [SELECT id FROM User WHERE IsActive = TRUE AND ProfileId =: [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1] limit 2];
        
        // the user going to complete the audit on the worker
        User auditor = users[1];
        
        // the user profile of the worker getting audited
        User x = users[0];

        // person to get audited
        Contact newWorker = new Contact();
        newWorker.LastName = 'super';
        newWorker.FirstName = 'clin';
        newWorker.RecordTypeId = '0122v0000013OcoAAE';
        newWorker.enrtcr__Gender_Detail__c = 'Male';
        newWorker.enrtcr__Client_Region__c = 'NSW';
        newWorker.enrtcr__Start_Date__c = System.today() - 365;
        newWorker.enrtcr__Status__c = 'Current';
        newWorker.enrtcr__Mobile__c = '04322355644';
        newWorker.Email = 'clinsup@betterrehab.com.au';
        newWorker.Next_Audit__c = System.today();
        newWorker.enrtcr__User__c = x.Id; 
        insert newWorker;
        
        // client of worker (for purposes of auto choosing a participant in the Audit flow)
        Contact client = TestObjects.createContact(1, 'NDIS');
        insert client;
        
        
        Clinical_Audit__c CA_History1 = new Clinical_Audit__c();
        CA_History1.Auditor__c = auditor.Id;
        CA_History1.Client__c = client.Id;
        CA_History1.Clinician__c = newWorker.Id;
        CA_History1.Clinical_Area__c = 'OT – AT';
        CA_History1.Numerator__c = 12;
        CA_History1.Denominator__c = 15;
        CA_History1.Status__c = 'CONFORMS';
        CA_History1.Audit_Type__c = 'Clinical Audit';

        insert CA_History1;

        // this will make them go to the quarterly stream
        Clinical_Audit__c CA_History2 = new Clinical_Audit__c();
        CA_History2.Auditor__c = auditor.Id;
        CA_History2.Client__c = client.Id;
        CA_History2.Clinician__c = newWorker.Id;
        CA_History2.Clinical_Area__c = 'OT – AT';
        CA_History2.Numerator__c = 12;
        CA_History2.Denominator__c = 15;
        CA_History2.Status__c = 'CONFORMS';
        CA_History2.Audit_Type__c = 'Clinical Audit';

        insert CA_History2;
        
        // 4 beacuse when we inserted the first audit, it pushed the next audit date one cycle ahead. next insertion pushes it 3. total = 4
        System.assertEquals(System.today() + (4 * CYCLE_PERIOD), [SELECT Next_Audit__c FROM Contact WHERE id =: newWorker.Id].Next_Audit__c);
        
        Date NextAuditDate = [SELECT id, Next_Audit__c FROM Contact WHERE id =: newWorker.Id].Next_Audit__c;
        // testing the trigger for a worker who has passed probation and has passed their 2nd audit
        Test.startTest();
            Clinical_Audit__c CA_Test = new Clinical_Audit__c();
            CA_Test.Auditor__c = auditor.Id;
            CA_Test.Client__c = client.Id;
            CA_Test.Clinician__c = newWorker.Id;
            CA_Test.Clinical_Area__c = 'OT – AT';
            CA_Test.Numerator__c = 12;
            CA_Test.Denominator__c = 15;
            CA_Test.Status__c = 'DOES NOT CONFORM';
        	CA_Test.Audit_Type__c = 'Clinical Audit';
        
        	insert CA_Test;
        Test.stopTest();
        
        Contact worker = [SELECT id, Next_Audit__c FROM Contact WHERE id =: newWorker.Id];
        
        System.assertEquals(NextAuditDate + CYCLE_PERIOD, worker.Next_Audit__c);
    }

    // test a user that is in the quarterly audit cycle staying in the same stream
    static testMethod void quarterlyMaintainQuarterly() {
        System.debug('Quarterly Stay');
        Setting__c Clinical_Audit_Settings = TestObjects.createSetting('Clinical Audit', TestConstants.getClinicalAuditSetting());
        insert Clinical_Audit_Settings;
        
        Integer CYCLE_PERIOD = 28;

        User[] users = [SELECT id FROM User WHERE IsActive = TRUE AND ProfileId =: [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1] limit 2];
        
        // the user going to complete the audit on the worker
        User auditor = users[1];
        
        // the user profile of the worker getting audited
        User x = users[0];

        // person to get audited
        Contact newWorker = new Contact();
        newWorker.LastName = 'super';
        newWorker.FirstName = 'clin';
        newWorker.RecordTypeId = '0122v0000013OcoAAE';
        newWorker.enrtcr__Gender_Detail__c = 'Male';
        newWorker.enrtcr__Client_Region__c = 'NSW';
        newWorker.enrtcr__Start_Date__c = System.today() - 365;
        newWorker.enrtcr__Status__c = 'Current';
        newWorker.enrtcr__Mobile__c = '04322355644';
        newWorker.Email = 'clinsup@betterrehab.com.au';
        newWorker.Next_Audit__c = System.today();
        newWorker.enrtcr__User__c = x.Id; 
        insert newWorker;
        
        // client of worker (for purposes of auto choosing a participant in the Audit flow)
        Contact client = TestObjects.createContact(1, 'NDIS');
        insert client;
        
        
        Clinical_Audit__c CA_History1 = new Clinical_Audit__c();
        CA_History1.Auditor__c = auditor.Id;
        CA_History1.Client__c = client.Id;
        CA_History1.Clinician__c = newWorker.Id;
        CA_History1.Clinical_Area__c = 'OT – AT';
        CA_History1.Numerator__c = 12;
        CA_History1.Denominator__c = 15;
        CA_History1.Status__c = 'CONFORMS';
        CA_History1.Audit_Type__c = 'Clinical Audit';

        insert CA_History1;

        // this will make them go to the quarterly stream
        Clinical_Audit__c CA_History2 = new Clinical_Audit__c();
        CA_History2.Auditor__c = auditor.Id;
        CA_History2.Client__c = client.Id;
        CA_History2.Clinician__c = newWorker.Id;
        CA_History2.Clinical_Area__c = 'OT – AT';
        CA_History2.Numerator__c = 12;
        CA_History2.Denominator__c = 15;
        CA_History2.Status__c = 'CONFORMS';
        CA_History2.Audit_Type__c = 'Clinical Audit';

        insert CA_History2;
       	
        // 4 beacuse when we inserted the first audit, it pushed the next audit date one cycle ahead. next insertion pushes it 3. total = 4
        System.assertEquals(System.today() + (4 * CYCLE_PERIOD), [SELECT Next_Audit__c FROM Contact WHERE id =: newWorker.Id].Next_Audit__c);
        
        Date NextAuditDate = [SELECT id, Next_Audit__c FROM Contact WHERE id =: newWorker.Id].Next_Audit__c;
        // testing the trigger for a worker who has passed probation and has passed their 2nd audit
        Test.startTest();
            Clinical_Audit__c CA_Test = new Clinical_Audit__c();
            CA_Test.Auditor__c = auditor.Id;
            CA_Test.Client__c = client.Id;
            CA_Test.Clinician__c = newWorker.Id;
            CA_Test.Clinical_Area__c = 'OT – AT';
            CA_Test.Numerator__c = 12;
            CA_Test.Denominator__c = 15;
            CA_Test.Status__c = 'CONFORMS';
        	CA_Test.Audit_Type__c = 'Clinical Audit';
        	
        	insert CA_Test;
        Test.stopTest();
        
        Contact worker = [SELECT id, Next_Audit__c FROM Contact WHERE id =: newWorker.Id];
        
        System.assertEquals(NextAuditDate + (3 * CYCLE_PERIOD), worker.Next_Audit__c);
    }

    // test a user that is in the monthly stays in the monhtly stream because they havent passed probation
    static testMethod void monthlyStayMonthlyProbationFail() {
        System.debug('Monthly Stay');
        Setting__c Clinical_Audit_Settings = TestObjects.createSetting('Clinical Audit', TestConstants.getClinicalAuditSetting());
        insert Clinical_Audit_Settings;
        
        Integer CYCLE_PERIOD = 28;

        User[] users = [SELECT id FROM User WHERE IsActive = TRUE AND ProfileId =: [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1] limit 2];
        
        // the user going to complete the audit on the worker
        User auditor = users[1];
        
        // the user profile of the worker getting audited
        User x = users[0];

        // person to get audited
        Contact newWorker = new Contact();
        newWorker.LastName = 'super';
        newWorker.FirstName = 'clin';
        newWorker.RecordTypeId = '0122v0000013OcoAAE';
        newWorker.enrtcr__Gender_Detail__c = 'Male';
        newWorker.enrtcr__Client_Region__c = 'NSW';
        newWorker.enrtcr__Start_Date__c = System.today();
        newWorker.enrtcr__Status__c = 'Current';
        newWorker.enrtcr__Mobile__c = '04322355644';
        newWorker.Email = 'clinsup@betterrehab.com.au';
        newWorker.Next_Audit__c = System.today();
        newWorker.enrtcr__User__c = x.Id; 
        insert newWorker;
        
        // client of worker (for purposes of auto choosing a participant in the Audit flow)
        Contact client = TestObjects.createContact(1, 'NDIS');
        insert client;
        
        
        Clinical_Audit__c CA_History1 = new Clinical_Audit__c();
        CA_History1.Auditor__c = auditor.Id;
        CA_History1.Client__c = client.Id;
        CA_History1.Clinician__c = newWorker.Id;
        CA_History1.Clinical_Area__c = 'OT – AT';
        CA_History1.Numerator__c = 12;
        CA_History1.Denominator__c = 15;
        CA_History1.Status__c = 'CONFORMS';
        CA_History1.Audit_Type__c = 'Clinical Audit';

        insert CA_History1;

        Date NextAuditDate = [SELECT id, Next_Audit__c FROM Contact WHERE id =: newWorker.Id].Next_Audit__c;
        // testing the trigger for a worker who has passed probation and has passed their 2nd audit
        Test.startTest();
            Clinical_Audit__c CA_Test = new Clinical_Audit__c();
            CA_Test.Auditor__c = auditor.Id;
            CA_Test.Client__c = client.Id;
            CA_Test.Clinician__c = newWorker.Id;
            CA_Test.Clinical_Area__c = 'OT – AT';
            CA_Test.Numerator__c = 12;
            CA_Test.Denominator__c = 15;
            CA_Test.Status__c = 'CONFORMS';
        	CA_Test.Audit_Type__c = 'Clinical Audit';
        
        	insert CA_Test;
        Test.stopTest();
        
        Contact worker = [SELECT id, Next_Audit__c FROM Contact WHERE id =: newWorker.Id];
        
        System.assertEquals(NextAuditDate + CYCLE_PERIOD, worker.Next_Audit__c);
    }
}