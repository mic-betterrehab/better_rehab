@isTest
private class OnboardingContactTest {
    static testMethod void validateUserCreation() {
        
        User x = [SELECT id, Name, KPI__c FROM User WHERE IsActive = TRUE AND ProfileId =: [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1] limit 1];
        
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
        //newOnboarder.State__c = 'NSW';
        newOnboarder.FTE__c = 0.5;
        newOnboarder.Department__c = 'PBS';
        newOnboarder.Phone_Number__c = '0432 256 298';
        newOnboarder.Clinical_Supervisor__c = newWorker.Id;
        //newOnboarder.Office__c = 'Eastern Sydney';
        newOnboarder.Gender__c = 'Male';
        newOnboarder.Start_Date__c = System.today();
        newOnboarder.Role_Title__c = 'Physiotherapy';
        
        insert newOnboarder;
        
        System.debug('user apex run is: ' + newOnboarder.User_Apex_Run__c);
        
        Test.startTest();
        PageReference userPage = Page.OnboardUser_Button_Controller;
        Test.setCurrentPage(userPage);
        userPage.getParameters().put('Id', String.valueOf(newOnboarder.Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(newOnboarder);
        OnboardingUserController UC = new OnboardingUserController(sc);
        UC.autoRun();
        
        System.debug('user apex run 2 is: ' + newOnboarder.User_Apex_Run__c);

        PageReference pageRef = Page.OnboardContact_Button_Controller;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', String.valueOf(newOnboarder.Id));
        ApexPages.StandardController scc = new ApexPages.StandardController(newOnboarder);
        OnboardingUserController UCc = new OnboardingUserController(scc);
        UCc.autoRun();
        Test.stopTest();
        
        Contact[] contacts = [SELECT id, Email, Supervision__c FROM Contact WHERE Email = 'newperson@betterrehab.com.au'];
        Contact[] supervision = [SELECT id, Supervision__c FROM Contact WHERE LastName = 'Supervision'];
        
        for (Integer i = 0 ; i < contacts.size() ; i++) {
            System.assertEquals('newperson@betterrehab.com.au', contacts[i].Email);  
            System.assertEquals(supervision[i].id, contacts[i].Supervision__c); 
            System.debug(supervision[i].id);
        }       
        
        for (Integer i = 0 ; i < supervision.size() ; i++) {
           System.assertEquals(contacts[i].id, supervision[i].Supervision__c);            
        }
        
    }
}