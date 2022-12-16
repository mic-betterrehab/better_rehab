@isTest
private class OnboardingTriggerHandlerTest {
    /*static testMethod void validateTaskCreation() {

        User u = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

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
        newWorker.enrtcr__User__c = u.Id;
        insert newWorker;

        enrtcr__Site__c site = TestObjects.createSite(2);
        site.Office_Admin__c = u.id;
        site.Name = 'Mulgrave';
        site.enrtcr__Business_State__c = 'VIC';
        insert site;

        Onboarding__c newOnboarder = new Onboarding__c();

        newOnboarder.User_Apex_Run__c = false;
        newOnboarder.Contact_Apex_Run__c = false;
        newOnboarder.Email__c = 'newperson@betterrehab.com.au';
        newOnboarder.First_Name__c = 'newP';
        newOnboarder.Last_Name__c = 'person';
        newOnboarder.Site__c = site.Id;
        newOnboarder.Department__c = 'PBS';
        newOnboarder.FTE__c = 0.5;
        newOnboarder.Phone_Number__c = '0432 256 298';
        newOnboarder.Clinical_Supervisor__c = newWorker.Id;
        newOnboarder.Gender__c = 'Male';
        newOnboarder.Start_Date__c = System.today();
        newOnboarder.Role_Title__c = 'Physiotherapy';

        Test.startTest();
        insert newOnboarder;
        Test.stopTest();

        Task[] tasks = [SELECT id FROM Task WHERE WhatId =: newOnboarder.Id];
        System.assertEquals(37, tasks.size());
    }*/
}