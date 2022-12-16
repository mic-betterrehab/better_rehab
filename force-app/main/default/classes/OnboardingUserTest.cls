@isTest
private class OnboardingUserTest {
    static testMethod void validateUserCreation() {

        User x = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

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
        newWorker.enrtcr__User__c = x.Id;
        insert newWorker;

        enrtcr__Site__c site = TestObjects.createSite(2);
        site.Office_Admin__c = x.id;
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
        newOnboarder.FTE__c = 0.8;
        //newOnboarder.State__c = 'NSW';
        newOnboarder.Department__c = 'PBS';
        newOnboarder.Internal_Banding__c = 'Graduate Clinician';
        newOnboarder.Phone_Number__c = '0432 256 298';
        newOnboarder.Clinical_Supervisor__c = newWorker.Id;
        //newOnboarder.Office__c = 'Eastern Sydney';
        newOnboarder.Gender__c = 'Male';
        newOnboarder.Start_Date__c = System.today();
        newOnboarder.Role_Title__c = 'Physiotherapy';

        insert newOnboarder;

        Test.startTest();
        PageReference pageRef = Page.OnboardUser_Button_Controller;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', String.valueOf(newOnboarder.Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(newOnboarder);
        OnboardingUserController UC = new OnboardingUserController(sc);
        UC.autoRun();

        Test.stopTest();

        if (UC.checkRemainingLicenses()) {
            User[] users = [SELECT id, Email FROM User WHERE Email = 'newPerson@betterrehab.com.au'];
        	System.assertEquals('newperson@betterrehab.com.au', users[0].Email);
        }
    }
}