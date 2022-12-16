@isTest
private class UserInactiveTest {
    static testMethod void validateUserInactive() {
        
        //Prep the data for Offboarding
        //Create a Worker Contact
        User x = [SELECT id, IsActive FROM User WHERE Id = '0052v00000YFBqhAAH'];
        x.IsActive = false;
        System.debug('Name for user is ' + x.Id);  

        Contact newWorker = new Contact();
        newWorker.LastName = 'super';
        newWorker.FirstName = 'clin';
        newWorker.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Employee').getRecordTypeId();
        newWorker.enrtcr__Gender_Detail__c = 'Male';
        newWorker.enrtcr__Client_Region__c = 'NSW';
        newWorker.enrtcr__Start_Date__c = System.today();
        newWorker.enrtcr__Status__c = 'Current';
        newWorker.enrtcr__Mobile__c = '04322355644';
        newWorker.Email = 'clinsup@betterrehab.com.au';
        newWorker.enrtcr__User__c = x.Id;
        newWorker.Internal_Banding__c = 'Team Leader';
        insert newWorker;  
        
        //Create a client contact
        Contact client = TestObjects.createContact(1, 'NDIS');
        client.enrtcr__NDIS_ID__c = '12345678';
        client.MMM_Score__c = '0';
        insert client;
        
        //Create SA, Support Contact, Client Clinician
        enrtcr__Reference_Data__c IDLSSC = TestObjects.CreateRD(27, 'NDIS', 'NDIS');
        insert IDLSSC;
        
        enrtcr__Support_Contract__c NDISSA = TestObjects.createSA(client.Id);
        insert NDISSA;
        
        enrtcr__Staff_Allocation__c clientClinician = new enrtcr__Staff_Allocation__c();
        clientClinician.Client__c = client.Id;
        clientClinician.Clinician__c = newWorker.Id;
        clientClinician.Clinician_Status__c = 'Active';
        clientClinician.Service_Agreement__c = NDISSA.Id;
        clientClinician.Name = 'Occupational Therapist';
        insert clientClinician;
        
        //Create a Site
        enrtcr__Site__c s = TestObjects.createSite(2);
        insert s;
        System.debug('Insert site success!');
        
        //Create a Session and Worker Appointment
        enrtcr__Session__c testSession = new enrtcr__Session__c();
        testSession.enrtcr__Start_Date__c = Datetime.now().addDays(1);
        testSession.enrtcr__End_Date__c = Datetime.now().addDays(2);
        testSession.enrtcr__Service_Types__c = 'Initial Assessment';
        testSession.enrtcr__Status__c = SessionTriggerHandler.ROSTERED;
        insert testSession;
        System.debug('Session Created!');
        
        enrtcr__Worker_Appointment__c wAppointment = new enrtcr__Worker_Appointment__c();
        wAppointment.enrtcr__Worker__c = newWorker.ID;
        wAppointment.enrtcr__Session__c = testSession.ID;
        wAppointment.enrtcr__Status__c = SessionTriggerHandler.ROSTERED;
        insert wAppointment; 
        
        //Create Offboarding and fill in required fields
        Offboarding__c offboarder = new Offboarding__c();
        offboarder.Offboarding_Name__c = newWorker.Id;
        offboarder.Direct_Supervisor__c = newWorker.Id;
        offboarder.State_Manager__c = newWorker.Id;
        offboarder.Site__c = s.Id;
        offboarder.Exit_Date__c = System.today();
        offboarder.Name = 'offboarder name';	//This is for Offboarding ID/Offboarding Name
        offboarder.Offboarding_Type__c = 'Terminations';
        offboarder.User__c = x.Id; //will need to make user field compulsory
        offboarder.User_Inactive_Run__c = false;
        offboarder.Comments__c = 'comments';
        
        try {
            insert offboarder;
            System.debug('User ID for the owner of this offboarding record is: ' + offboarder.OwnerId);
            System.debug('Insert offboarder success!');
        } catch (Exception e) {
            System.debug('error ' + e.getMessage());
        }
        
                
        Test.startTest();
        PageReference pageRef = Page.UserInactive_Button_Controller;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('id', String.valueOf(offboarder.Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(offboarder);
        UserInactive UC = new UserInactive(sc);
        UC.autoRun();
        
        Test.stopTest();

        System.assertEquals(FALSE, x.IsActive);
    }
}