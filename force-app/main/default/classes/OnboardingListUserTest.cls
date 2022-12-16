@isTest
private class OnboardingListUserTest {
	/*static testMethod void validateUserCreation() {

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

        List<Onboarding__c> onboarders = new List<Onboarding__c>();

        for (Integer i = 0 ; i < 6; i++) {
            Onboarding__c newOnboarder = new Onboarding__c();
            newOnboarder.User_Apex_Run__c = false;
            newOnboarder.Contact_Apex_Run__c = false;
            newOnboarder.Email__c = 'newperson'+ String.valueOf(i) + '@betterrehab.com.au';
            newOnboarder.First_Name__c = 'newP' + String.valueOf(i);
            newOnboarder.Last_Name__c = 'person';
            newOnboarder.Site__c = site.Id;
            newOnboarder.FTE__c = 0.5;
            //newOnboarder.State__c = 'NSW';
            newOnboarder.Department__c = 'PBS';
            newOnboarder.Phone_Number__c = '0432 256 298';
            newOnboarder.Clinical_Supervisor__c = newWorker.Id;
            //newOnboarder.Office__c = 'Eastern Sydney';
            newOnboarder.Gender__c = 'Male';
            newOnboarder.Start_Date__c = System.today();
            newOnboarder.Role_Title__c = 'Physiotherapy';

            onboarders.add(newOnboarder);
        }
        insert onboarders;

        Test.startTest();
        PageReference pageRef = Page.Onboard_All;
        Test.setCurrentPage(pageRef);
        //pageRef.getParameters().put('Id', String.valueOf(newOnboarder.Id));
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(onboarders);
        OnboardingListUserController UC = new OnboardingListUserController(sc);
        UC.autoRun();

        Test.stopTest();

        Integer i = 0;
        for (User u : [SELECT id, Email FROM User WHERE Email =: 'newperson'+ String.valueOf(i) + '@betterrehab.com.au']) {
            System.assertEquals('newperson' + i + '@betterrehab.com.au', u.Email);
            i++;
        }
    }*/
}