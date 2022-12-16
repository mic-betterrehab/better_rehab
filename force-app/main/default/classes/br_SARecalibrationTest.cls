@isTest
private class br_SARecalibrationTest {
    // create contact and supervision profile (link together on supervision field)
    // create service agreement (SC) set the SA allocation to an incorrect amount
    // link SA to supervision profile
    // try and refresh the SA
    /*static testMethod void validate() {
		
        // get a user
        User supervisor = [SELECT id, Name, KPI__c FROM User WHERE id = '0052v00000h0I10AAE'];
        
        // create a worker profile
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
        supervisorContact.Email = supervisor.Name + '@betterrehab.com.au';
        supervisorContact.FTE__c = 0.8;
        supervisorContact.enrtcr__User__c = supervisor.Id;
        
        insert supervisorContact;
        
        // create a supervision profile
        Contact supervisionProfile = new Contact();
        supervisionProfile.LastName = 'SUPERVISION';
        supervisionProfile.FirstName = supervisor.Name;
        supervisionProfile.RecordTypeId = '0122v0000013ObcAAE';
        supervisionProfile.enrtcr__Gender_Detail__c = 'Male';
        supervisionProfile.enrtcr__Client_Region__c = 'NSW';
        supervisionProfile.enrtcr__Start_Date__c = System.today();
        supervisionProfile.enrtcr__Status__c = 'Current';
        supervisionProfile.enrtcr__Mobile__c = '04322355644';
        supervisionProfile.Clinician_Discipline__c = 'Occupational Therapy';
        supervisionProfile.Email = supervisor.Name + '@betterrehab.com.au';
        supervisionProfile.Supervision__c = supervisorContact.Id;
        
        insert supervisionProfile;
        
        // link supervision profile to worker profile
        supervisorContact.Supervision__c = supervisionProfile.Id;
        
        update supervisorContact;
        
   		// create a supervision SA for the supervision profile
   		enrtcr__Support_Contract__c SA = new enrtcr__Support_Contract__c();
        SA.enrtcr__Client__c = supervisionProfile.Id;
        SA.enrtcr__Funding_Type__c = 'NDIS';
        SA.enrtcr__Rate_Type__c = 'NDIS';
        SA.enrtcr__Start_Date__c = System.today() - 3;
        SA.enrtcr__End_Date__c = System.today() + 365;
        SA.enrtcr__Total_Allocation__c = 10;
        SA.enrtcr__Service_Agreement_Overclaim__c = 'Prevent';
		SA.enrtcr__Funding_Management__c = 'Participant';
        SA.enrtcr__Status__c = 'Current';
        SA.Name = 'Supervision SA';
        SA.enrtcr__Client_Approved_Date__c = System.today() - 1;
		
        insert SA;
        
        // create support categories
        List<enrtcr__Reference_Data__c> SCs = new List<enrtcr__Reference_Data__c>();
        SCs.add(TestObjects.createRD(27, 'Clinical Supervision' , 'NDIS'));
        SCs.add(TestObjects.createRD(27, 'Operational Supervision' , 'NDIS'));
        SCs.add(TestObjects.createRD(27, 'QA Support' , 'NDIS'));
        
        insert SCs;
        
        // create service agreement line items for the Supervision SA
        List<enrtcr__Support_Contract_Item__c> SAIs = new List<enrtcr__Support_Contract_Item__c>();
        
        enrtcr__Support_Contract_Item__c SAIClin = new enrtcr__Support_Contract_Item__c();
        SAIClin.RecordTypeId = '0122v0000013ObbAAE';
        SAIClin.enrtcr__Support_Category_Amount__c = 4;
        SAIClin.enrtcr__Support_Category__c = SCs[0].id;
        SAIClin.enrtcr__Support_Contract__c = SA.id;
        SAIClin.enrtcr__Item_Overclaim__c = 'Prevent';
        SAIs.add(SAIClin);
        
        enrtcr__Support_Contract_Item__c SAIOp = new enrtcr__Support_Contract_Item__c();
        SAIOp.RecordTypeId = '0122v0000013ObbAAE';
        SAIOp.enrtcr__Support_Category_Amount__c = 3;
        SAIOp.enrtcr__Support_Category__c = SCs[1].id;
        SAIOp.enrtcr__Support_Contract__c = SA.id;
        SAIOp.enrtcr__Item_Overclaim__c = 'Prevent';
        SAIs.add(SAIOp);
        
        enrtcr__Support_Contract_Item__c SAIQA = new enrtcr__Support_Contract_Item__c();
        SAIQA.RecordTypeId = '0122v0000013ObbAAE';
        SAIQA.enrtcr__Support_Category_Amount__c = 3;
        SAIQA.enrtcr__Support_Category__c = SCs[2].id;
        SAIQA.enrtcr__Support_Contract__c = SA.id;
        SAIQA.enrtcr__Item_Overclaim__c = 'Prevent';
        SAIs.add(SAIQA);
        
        insert SAIs;
        
        Test.startTest();
        
        br_actions page = new br_actions();
        page.recalibrateSSA();
        
        Test.stopTest();
        
        enrtcr__Support_Contract_Item__c[] saisFound = [SELECT Id, enrtcr__Support_Category__r.Name ,enrtcr__Support_Category_Amount__c, enrtcr__Support_Contract__r.enrtcr__Total_Allocation__c FROM enrtcr__Support_Contract_Item__c WHERE enrtcr__Support_Contract__r.Name = 'Supervision SA'];
        Action_Log__c[] log = [SELECT id, Response__c, Status__c FROM Action_Log__c];
        System.assertEquals(1, log.size());
        System.debug(log[0]);
        System.debug(saisFound);
        System.assertEquals(3, saisFound.size());
        for (enrtcr__Support_Contract_Item__c item : saisFound) {
            System.debug(item.enrtcr__Support_Category_Amount__c + item.enrtcr__Support_Category__r.Name);
            if (item.enrtcr__Support_Category__r.Name == 'QA Support') {
                System.assertEquals(3, item.enrtcr__Support_Category_Amount__c);
            }
            if (item.enrtcr__Support_Category__r.Name == 'Operational Supervision') {
                System.assertEquals(1 * 0.8, item.enrtcr__Support_Category_Amount__c);
            }
            if (item.enrtcr__Support_Category__r.Name == 'Clinical Supervision') {
                System.assertEquals(4, item.enrtcr__Support_Category_Amount__c);
            }
        }
        System.assertEquals(10, saisFound[0].enrtcr__Support_Contract__r.enrtcr__Total_Allocation__c);
    }*/
}