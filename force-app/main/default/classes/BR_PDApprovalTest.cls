@isTest
private class BR_PDApprovalTest {
    @testSetup static void prepData(){
        //Prep the data
        List<RecordType> pdRequestList = new List<RecordType>();
        Map<String,Id> pdRequestType = new Map<String,Id>();

        pdRequestList = [SELECT Id, DeveloperName, SObjectType FROM RecordType WHERE SObjectType = 'PD_Request__c'];
        for(RecordType ids : pdRequestList){
            pdRequestType.put(ids.DeveloperName, ids.Id);
        }

        //Create 6 worker contacts (1 employee, 5 supervisors)
        User x = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        List<Contact> listOfContacts = new List<Contact>();

        for (Integer i = 0 ; i < 8; i++){
            Contact newWorker = TestObjects.createContact(6, 'NDIS');
            newWorker.FirstName = 'newW' + String.valueOf(i);
            newWorker.Email = 'newWorker'+ String.valueOf(i) + '@betterrehab.com.au';
            newWorker.enrtcr__User__c = x.Id;
            newWorker.Annual_PD_Balance__c = 400;
            newWorker.Better_Rewards_PD_Balance__c = 0;

            listOfContacts.add(newWorker);
        }

        //create a director
        Contact newDirector = TestObjects.createContact(6, 'NDIS');
        newDirector.FirstName = 'newDirector';
        newDirector.Email = 'newDirector@betterrehab.com.au';
        newDirector.Internal_Banding__c = 'Director';
        newDirector.enrtcr__User__c = x.Id;

        listOfContacts.add(newDirector);

        insert listOfContacts;

        List<Contact> updatedContacts = new List<Contact>();

        //Set the Ops Mgr to have the internal banding
        Contact om = [SELECT id, Clinical_Supervisor__c, Direct_Supervisor__c FROM Contact WHERE Email = 'newWorker6@betterrehab.com.au'];
        om.Internal_Banding__c = 'Operations Manager';
        updatedContacts.add(om);

        //Set 1 worker to have all 5 supervisors (CS, DS, RM, SM, PC)
        Contact employee = [SELECT id, Clinical_Supervisor__c, Direct_Supervisor__c FROM Contact WHERE Email = 'newWorker0@betterrehab.com.au'];
        Contact cs = [SELECT id, Clinical_Supervisor__c, Direct_Supervisor__c FROM Contact WHERE Email = 'newWorker1@betterrehab.com.au'];
        Contact ds = [SELECT id, Clinical_Supervisor__c, Direct_Supervisor__c FROM Contact WHERE Email = 'newWorker2@betterrehab.com.au'];
        Contact rm = [SELECT id, Clinical_Supervisor__c, Direct_Supervisor__c FROM Contact WHERE Email = 'newWorker3@betterrehab.com.au'];
        Contact sm = [SELECT id, Clinical_Supervisor__c, Direct_Supervisor__c FROM Contact WHERE Email = 'newWorker4@betterrehab.com.au'];
        Contact pc = [SELECT id, Clinical_Supervisor__c, Direct_Supervisor__c FROM Contact WHERE Email = 'newWorker5@betterrehab.com.au'];
        Contact director = [SELECT id, Clinical_Supervisor__c, Direct_Supervisor__c FROM Contact WHERE Email = 'newDirector@betterrehab.com.au'];

       	employee.Clinical_Supervisor__c = cs.Id;
        employee.Direct_Supervisor__c = ds.Id;
        updatedContacts.add(employee);
        ds.Direct_Supervisor__c = rm.Id;
        updatedContacts.add(ds);
        rm.Direct_Supervisor__c = director.Id;
        updatedContacts.add(rm);

        update updatedContacts;

        List<PD_Request__c> listOfPDs = new List<PD_Request__c>();

        //Create PD Request
        //will be approved, should generate 3 approvals
        PD_Request__c newPD1 = new PD_Request__c();
        newPD1.RecordTypeId = pdRequestType.get('Clinician');
        newPD1.Employee_Name__c = employee.Id;
        newPD1.Course_Name__c = 'First Aid / CPR';
        newPD1.Course_Date_1__c = System.today() + 20;
        newPD1.Cost_of_Course__c = 900;
        newPD1.Principal_Clinician__c = pc.Id;
        newPD1.Regional_Manager__c = rm.Id;
        newPD1.State_Manager__c = sm.Id;
        newPD1.Approved_by_Clinical_Supervisor__c = TRUE;
        newPD1.Approved_by_Direct_Supervisor__c = TRUE;
        listOfPDs.add(newPD1);

        //will be approved, should only generate 1 approval (only RM)
        PD_Request__c newPD2 = new PD_Request__c();
        newPD2.RecordTypeId = pdRequestType.get('Principal_Clinician');
        newPD2.Employee_Name__c = employee.Id;
        newPD2.Course_Name__c = 'First Aid / CPR';
        newPD2.Course_Date_1__c = System.today() + 20;
        newPD2.Cost_of_Course__c = 900;
        newPD2.State_Manager__c = sm.Id;
        newPD2.Approved_by_Clinical_Supervisor__c = TRUE;
        newPD2.Approved_by_Direct_Supervisor__c = TRUE;
        listOfPDs.add(newPD2);

        PD_Request__c newPD3 = new PD_Request__c();
        newPD3.RecordTypeId = pdRequestType.get('Allied_Health_Assistant');
        newPD3.Employee_Name__c = employee.Id;
        newPD3.Course_Name__c = 'First Aid / CPR';
        newPD3.Regional_Manager__c = rm.Id;
        newPD3.State_Manager__c = sm.Id;
        newPD3.Course_Date_1__c = System.today() + 20;
        newPD3.Cost_of_Course__c = 900;

        listOfPDs.add(newPD3);

        PD_Request__c newPD4 = new PD_Request__c();
        newPD4.RecordTypeId = pdRequestType.get('Operational');
        newPD4.Employee_Name__c = employee.Id;
        newPD4.Course_Name__c = 'First Aid / CPR';
        newPD4.Course_Date_1__c = System.today() + 20;
        newPD4.Cost_of_Course__c = 800;

        listOfPDs.add(newPD4);

        PD_Request__c newPD5 = new PD_Request__c();
        newPD5.RecordTypeId = pdRequestType.get('Leadership');
        newPD5.Employee_Name__c = employee.Id;
        newPD5.Course_Name__c = 'First Aid / CPR';
        newPD5.Course_Date_1__c = System.today() + 20;
        newPD5.Cost_of_Course__c = 900;
        listOfPDs.add(newPD5);

        insert listOfPDs;
    }

    @isTest static void testClinicianApproval(){
        //1. Get the first approval from principal clinician
        Test.startTest();
        PD_Approval__c approval = [SELECT id, Position__c, PD_Request__c FROM PD_Approval__c WHERE PD_Request__r.RecordType.DeveloperName =: 'Clinician'];

        approval.Cost_from_Employee_s_Total_PD__c = 300;
        approval.Additional_BR_Contributions__c = 600;
        approval.Comment__c = 'Testing PC';
        approval.Bypass_Validation_Rule__c = TRUE;
        System.debug('Get all the PD Request related IDs: ' + approval.PD_Request__c);

        //make it approved
        System.debug('PD1 Position: ' + approval.Position__c);
        approval.Status__c = 'Approved';
        update approval;

        //2. Second approval from regional manager
        PD_Approval__c rmApproval = [SELECT id, Position__c, PD_Request__c FROM PD_Approval__c WHERE PD_Request__c =: approval.PD_Request__c AND Position__c = 'Regional Manager'];

        rmApproval.Comment__c = 'Testing RM';
        rmApproval.Bypass_Validation_Rule__c = TRUE;
        System.debug('Get all the PD Request related IDs: ' + rmApproval.PD_Request__c);

        //make it approved
        System.debug('PD1 Position: ' + rmApproval.Position__c);
        rmApproval.Status__c = 'Approved';
        update rmApproval;

        //3. Third approval from state manager
        PD_Approval__c smApproval = [SELECT id, Position__c, PD_Request__c FROM PD_Approval__c WHERE PD_Request__c =: approval.PD_Request__c AND Position__c = 'State Manager'];

        smApproval.Comment__c = 'Testing SM';
        smApproval.Bypass_Validation_Rule__c = TRUE;
        System.debug('Get all the PD Request related IDs: ' + smApproval.PD_Request__c);

        //make it approved
        System.debug('PD1 Position: ' + smApproval.Position__c);
        smApproval.Status__c = 'Approved';
        update smApproval;
        
        Test.stopTest();

        List<PD_Approval__c> allApprovals = [SELECT id, Position__c, PD_Request__c FROM PD_Approval__c WHERE PD_Request__c =: approval.PD_Request__c]; //2 approvals here
        PD_Request__c req = [SELECT Id, Employee_Name__c, Status__c, Total_Subsidised_Cost__c FROM PD_Request__c WHERE Id =: approval.PD_Request__c];
        Contact e = [SELECT Id, Annual_PD_Balance__c, Better_Rewards_PD_Balance__c FROM Contact WHERE Id =: req.Employee_Name__c];

        System.assertEquals(3, allApprovals.size());
        System.assertEquals('Approved', req.Status__c);
        System.assertEquals(900, req.Total_Subsidised_Cost__c);
        System.assertEquals(100, e.Annual_PD_Balance__c);
        System.assertEquals(0, e.Better_Rewards_PD_Balance__c);
    }

    @isTest static void testPCApproval(){
        Test.startTest();
        //Should only be 1 - FIRST APPROVAL FROM DS
        PD_Approval__c appPC = [SELECT id, Position__c, PD_Request__c FROM PD_Approval__c WHERE PD_Request__r.RecordType.DeveloperName =: 'Principal_Clinician'];

        appPC.Cost_from_Employee_s_Total_PD__c = 400;
        appPC.Additional_BR_Contributions__c = 500;
        appPC.Comment__c = 'Testing PC';
        appPC.Bypass_Validation_Rule__c = TRUE;
        System.debug('Get all the PD Request related IDs: ' + appPC.PD_Request__c);

        //make it approved
        System.debug('PD1 Position: ' + appPC.Position__c);
        appPC.Status__c = 'Approved';
        update appPC;

        //Second approval
        PD_Approval__c smApproval = [SELECT id, Position__c, PD_Request__c FROM PD_Approval__c WHERE PD_Request__c =: appPC.PD_Request__c AND Position__c = 'State Manager'];

        smApproval.Comment__c = 'Testing PC';
        smApproval.Bypass_Validation_Rule__c = TRUE;
        System.debug('Get all the PD Request related IDs: ' + smApproval.PD_Request__c);

        //make it approved
        System.debug('PD1 Position: ' + smApproval.Position__c);
        smApproval.Status__c = 'Approved';
        update smApproval;
        
        Test.stopTest();

        List<PD_Approval__c> allApprovals = [SELECT id, Position__c, PD_Request__c FROM PD_Approval__c WHERE PD_Request__c =: appPC.PD_Request__c]; //2 approvals here
		PD_Request__c req = [SELECT Id, Employee_Name__c, Status__c, Total_Subsidised_Cost__c FROM PD_Request__c WHERE Id =: appPC.PD_Request__c];
        Contact e = [SELECT Id, Annual_PD_Balance__c, Better_Rewards_PD_Balance__c FROM Contact WHERE Id =: req.Employee_Name__c];

        System.assertEquals(2, allApprovals.size());
        System.assertEquals('Approved', req.Status__c);
        System.assertEquals(900, req.Total_Subsidised_Cost__c);
        System.assertEquals(0, e.Annual_PD_Balance__c);
        System.assertEquals(0, e.Better_Rewards_PD_Balance__c);

    }

    @isTest static void testAHAApproval(){
        Test.startTest();
        PD_Approval__c appPC = [SELECT id, Position__c, PD_Request__c FROM PD_Approval__c WHERE PD_Request__r.RecordType.DeveloperName =: 'Allied_Health_Assistant'];

        appPC.Cost_from_Employee_s_Total_PD__c = 0;
        appPC.Additional_BR_Contributions__c = 900;
        appPC.Comment__c = 'Testing PC';
        appPC.Bypass_Validation_Rule__c = TRUE;
        System.debug('Get all the PD Request related IDs: ' + appPC.PD_Request__c);

        //make it approved
        System.debug('PD1 Position: ' + appPC.Position__c);
        appPC.Status__c = 'Approved';
        update appPC;

        //Second approval
        PD_Approval__c smApproval = [SELECT id, Position__c, PD_Request__c FROM PD_Approval__c WHERE PD_Request__c =: appPC.PD_Request__c AND Position__c = 'State Manager'];

        smApproval.Comment__c = 'Testing PC';
        smApproval.Bypass_Validation_Rule__c = TRUE;
        System.debug('Get all the PD Request related IDs: ' + smApproval.PD_Request__c);

        //make it approved
        System.debug('PD1 Position: ' + smApproval.Position__c);
        smApproval.Status__c = 'Approved';
        update smApproval;
        Test.stopTest();

        List<PD_Approval__c> allApprovals = [SELECT id, Position__c, PD_Request__c FROM PD_Approval__c WHERE PD_Request__c =: appPC.PD_Request__c]; //2 approvals here
        PD_Request__c req = [SELECT Id, Employee_Name__c, Status__c, Total_Subsidised_Cost__c FROM PD_Request__c WHERE Id =: appPC.PD_Request__c];
        Contact e = [SELECT Id, Annual_PD_Balance__c, Better_Rewards_PD_Balance__c FROM Contact WHERE Id =: req.Employee_Name__c];

        System.assertEquals(2, allApprovals.size());
        System.assertEquals('Approved', req.Status__c);
        System.assertEquals(900, req.Total_Subsidised_Cost__c);
        System.assertEquals(400, e.Annual_PD_Balance__c);
        System.assertEquals(0, e.Better_Rewards_PD_Balance__c);

    }

    @isTest static void testLeadershipApproval(){
        Test.startTest();
        PD_Approval__c appPC = [SELECT id, Position__c, PD_Request__c FROM PD_Approval__c WHERE PD_Request__r.RecordType.DeveloperName =: 'Leadership'];

        appPC.Cost_from_Employee_s_Total_PD__c = 900;
        appPC.Additional_BR_Contributions__c = 0;
        appPC.Comment__c = 'Testing PC';
        appPC.Bypass_Validation_Rule__c = TRUE;
        System.debug('Get all the PD Request related IDs: ' + appPC.PD_Request__c);

        //make it approved
        System.debug('PD1 Position: ' + appPC.Position__c);
        appPC.Status__c = 'Approved';
        update appPC;
        Test.stopTest();

        List<PD_Approval__c> allApprovals = [SELECT id, Position__c, PD_Request__c FROM PD_Approval__c WHERE PD_Request__c =: appPC.PD_Request__c];
        PD_Request__c req = [SELECT Id, Employee_Name__c, Status__c, Total_Subsidised_Cost__c FROM PD_Request__c WHERE Id =: appPC.PD_Request__c];
        Contact e = [SELECT Id, Annual_PD_Balance__c, Better_Rewards_PD_Balance__c FROM Contact WHERE Id =: req.Employee_Name__c];

        System.assertEquals(1, allApprovals.size());
        System.assertEquals('Approved', req.Status__c);
        System.assertEquals(400, req.Total_Subsidised_Cost__c);
        System.assertEquals(0, e.Annual_PD_Balance__c);
        System.assertEquals(0, e.Better_Rewards_PD_Balance__c);
    }

    @isTest static void testOperationalApproval(){
        Test.startTest();
        PD_Approval__c appPC = [SELECT id, Position__c, PD_Request__c FROM PD_Approval__c WHERE PD_Request__r.RecordType.DeveloperName =: 'Operational'];

        appPC.Cost_from_Employee_s_Total_PD__c = 0;
        appPC.Additional_BR_Contributions__c = 0;
        appPC.Comment__c = 'Testing PC';
        appPC.Bypass_Validation_Rule__c = TRUE;
        System.debug('Get all the PD Request related IDs: ' + appPC.PD_Request__c);

        //make it approved
        System.debug('PD1 Position: ' + appPC.Position__c);
        appPC.Status__c = 'Approved';
        update appPC;

        //Second approval
        PD_Approval__c deptApproval = [SELECT id, Position__c, PD_Request__c FROM PD_Approval__c WHERE PD_Request__c =: appPC.PD_Request__c AND Position__c = 'Department Manager'];

        deptApproval.Comment__c = 'Testing PC';
        deptApproval.Bypass_Validation_Rule__c = TRUE;
        System.debug('Get all the PD Request related IDs: ' + deptApproval.PD_Request__c);

        //make it approved
        System.debug('PD1 Position: ' + deptApproval.Position__c);
        deptApproval.Status__c = 'Approved';
        update deptApproval;
        
        Test.stopTest();

        List<PD_Approval__c> allApprovals = [SELECT id, Position__c, PD_Request__c FROM PD_Approval__c WHERE PD_Request__c =: appPC.PD_Request__c];
        PD_Request__c req = [SELECT Id, Employee_Name__c, Status__c, Total_Subsidised_Cost__c FROM PD_Request__c WHERE Id =: appPC.PD_Request__c];
        Contact e = [SELECT Id, Annual_PD_Balance__c, Better_Rewards_PD_Balance__c FROM Contact WHERE Id =: req.Employee_Name__c];

        System.assertEquals(2, allApprovals.size());
        System.assertEquals('Approved', req.Status__c);
        System.assertEquals(0, req.Total_Subsidised_Cost__c);
        System.assertEquals(400, e.Annual_PD_Balance__c);
        System.assertEquals(0, e.Better_Rewards_PD_Balance__c);
    }

    @isTest static void testLeadershipDenial(){
        Test.startTest();
        PD_Approval__c appPC = [SELECT id, Position__c, PD_Request__c FROM PD_Approval__c WHERE PD_Request__r.RecordType.DeveloperName =: 'Leadership'];

        appPC.Cost_from_Employee_s_Total_PD__c = 0;
        appPC.Additional_BR_Contributions__c = 0;
        appPC.Comment__c = 'Testing PC';
        appPC.Bypass_Validation_Rule__c = TRUE;
        System.debug('Get all the PD Request related IDs: ' + appPC.PD_Request__c);

        //make it approved
        System.debug('PD1 Position: ' + appPC.Position__c);
        appPC.Status__c = 'Denied';
        update appPC;
        Test.stopTest();

        List<PD_Approval__c> allApprovals = [SELECT id, Position__c, PD_Request__c FROM PD_Approval__c WHERE PD_Request__c =: appPC.PD_Request__c];
        PD_Request__c req = [SELECT Id, Employee_Name__c, Status__c, Total_Subsidised_Cost__c FROM PD_Request__c WHERE Id =: appPC.PD_Request__c];
        Contact e = [SELECT Id, Annual_PD_Balance__c, Better_Rewards_PD_Balance__c FROM Contact WHERE Id =: req.Employee_Name__c];

        System.assertEquals(1, allApprovals.size());
        System.assertEquals('Denied', req.Status__c);
        System.assertEquals(0, req.Total_Subsidised_Cost__c);
        System.assertEquals(400, e.Annual_PD_Balance__c);
        System.assertEquals(0, e.Better_Rewards_PD_Balance__c);
    }

}