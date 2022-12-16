@isTest
private class offboardingTriggerHandlerTest {
    static testMethod void validateTaskCreation() {

        User u = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        Contact newWorker = TestObjects.createContact(6, 'NDIS');
        newWorker.LastName = 'super';
        newWorker.FirstName = 'clin';
        newWorker.Email = 'clinsup@betterrehab.com.au';
        newWorker.enrtcr__User__c = u.Id;
        newWorker.Internal_Banding__c = 'Regional Manager';
        insert newWorker;

        Contact ds = TestObjects.createContact(6, 'NDIS');
        ds.LastName = 'ds';
        ds.FirstName = 'worer';
        ds.Email = 'dsUP@betterrehab.com.au';
        insert ds;

        enrtcr__Site__c site = TestObjects.createSite(2);
        site.Office_Admin__c = u.Id;
        insert site;

        Offboarding__c newOffboarder = new Offboarding__c();
        newOffboarder.Name = 'newP person';
        newOffboarder.Offboarding_Name__c = newWorker.Id;
        newOffboarder.Offboarding_Type__c = 'Voluntary';
        newOffboarder.Exit_Date__c = System.today();
        newOffboarder.Comments__c = 'comments';
        newOffboarder.Site__c = site.Id;
        newOffboarder.Direct_Supervisor__c = ds.Id;

        Test.startTest();
        insert newOffboarder;
        Test.stopTest();

        Task[] tasks = [SELECT id FROM Task WHERE WhatId =: newOffboarder.Id];
        System.assertEquals(20, tasks.size());
    }
}