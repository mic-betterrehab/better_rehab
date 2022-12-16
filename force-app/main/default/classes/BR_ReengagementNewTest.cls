@isTest
public class BR_ReengagementNewTest {
    static testMethod void prepareTestData(){
        //create 4 workers
      	User x = [SELECT id FROM User WHERE IsActive = TRUE AND ProfileId =: [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1] limit 1];
        List<Contact> listOfContacts = new List<Contact>();
        
        for (Integer i = 0 ; i < 5; i++){
            Contact newWorker = new Contact();
            newWorker.LastName = 'Worker';
            newWorker.FirstName = 'newW' + String.valueOf(i);
            newWorker.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Employee').getRecordTypeId();
            newWorker.enrtcr__Gender_Detail__c = 'Male';
            newWorker.enrtcr__Client_Region__c = 'NSW';
            newWorker.enrtcr__Start_Date__c = System.today();
            newWorker.enrtcr__Status__c = 'Current';
            newWorker.enrtcr__Mobile__c = '04322355644';
            newWorker.Email = 'newWorker'+ String.valueOf(i) + '@betterrehab.com.au';
            newWorker.enrtcr__User__c = x.Id;
            
            listOfContacts.add(newWorker);
        }
        
      	//create 1 client
      	Contact newClient = TestObjects.createContact(1, 'NDIS');
        listOfContacts.add(newClient);
        
        //create the contacts to share events
        Contact contactsToShare = new Contact();
        contactsToShare.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Employee').getRecordTypeId();
        contactsToShare.Email = 'testWorker@betterrehab.com.au';
        contactsToShare.FirstName = 'Contact';
        contactsToShare.LastName = 'to share events';
        
        listOfContacts.add(contactsToShare);      
                
        insert listOfContacts;        
        
        //Get 4 workers
        Contact worker1 = [SELECT id, Clinical_Supervisor__c, Direct_Supervisor__c FROM Contact WHERE Email = 'newWorker1@betterrehab.com.au'];
        Contact worker2 = [SELECT id, Clinical_Supervisor__c, Direct_Supervisor__c FROM Contact WHERE Email = 'newWorker2@betterrehab.com.au'];
        Contact worker3 = [SELECT id, Clinical_Supervisor__c, Direct_Supervisor__c FROM Contact WHERE Email = 'newWorker3@betterrehab.com.au'];
        Contact worker4 = [SELECT id, Clinical_Supervisor__c, Direct_Supervisor__c FROM Contact WHERE Email = 'newWorker4@betterrehab.com.au'];
        
        Test.startTest();
        
        List<enrtcr__Assessment__c> listOfPlans = new List<enrtcr__Assessment__c>();
        
      	//create an MDT Plan review report
      	enrtcr__Assessment__c newMDT = new enrtcr__Assessment__c();
        newMDT.RecordTypeId = Schema.SObjectType.enrtcr__Assessment__c.getRecordTypeInfosByDeveloperName().get('MDT_Plan_Review').getRecordTypeId();
        newMDT.enrtcr__Client__c = newClient.Id;
        newMDT.MDT_Plan_Review_Type__c = 'Occupational Therapy';
        newMDT.Passed_QA__c = TRUE;
        newMDT.Plan_Review_Report_Date__c = System.today();
        newMDT.Completed_By__c = x.Id;
        newMDT.Follow_up_with_NDIS__c = 'No follow up required';
        newMDT.Clinician__c = worker1.Id;
        newMDT.Clinician_2__c = worker2.Id;
		newMDT.Clinician_3__c = worker3.Id;
		newMDT.Clinician_4__c = worker4.Id;
        
        listOfPlans.add(newMDT);
        
      	//create a plan review report
      	enrtcr__Assessment__c newPlanReview = new enrtcr__Assessment__c();
        newPlanReview.RecordTypeId = Schema.SObjectType.enrtcr__Assessment__c.getRecordTypeInfosByDeveloperName().get('Plan_Review').getRecordTypeId();
        newPlanReview.enrtcr__Client__c = newClient.Id;
        newPlanReview.Plan_Review_Type__c = 'Occupational Therapy';
        newPlanReview.Passed_QA__c = TRUE;
        newPlanReview.Plan_Review_Report_Date__c = System.today();
        newPlanReview.Completed_By__c = x.Id;
        newPlanReview.Follow_up_with_NDIS__c = 'No follow up required';
        newPlanReview.Clinician__c = worker1.Id;
        
        listOfPlans.add(newPlanReview);
        
        insert listOfPlans;
        
        Test.stopTest();
        
        //Get the list of sessions created (should be 5)
        List<Event> listOfEvents = [SELECT Id FROM Event WHERE Plan_Review_Report__c =: newMDT.Id OR Plan_Review_Report__c =: newPlanReview.Id];
        
        System.assertEquals(5, listOfEvents.size());
    }
}