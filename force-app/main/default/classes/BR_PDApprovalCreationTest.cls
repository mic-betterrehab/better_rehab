@isTest
public class BR_PDApprovalCreationTest {
    static testMethod void prepareTestData(){
        //Prep the data
        List<RecordType> pdRequestList = new List<RecordType>();
        Map<String,Id> pdRequestType = new Map<String,Id>();

        pdRequestList = [SELECT Id, DeveloperName, SObjectType FROM RecordType WHERE SObjectType = 'PD_Request__c'];
        for(RecordType ids : pdRequestList){
            pdRequestType.put(ids.DeveloperName, ids.Id);
        }

        //Create 6 worker contacts (1 employee, 6 supervisors)
        User x = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        List<Contact> listOfContacts = new List<Contact>();

        for (Integer i = 0 ; i < 8; i++){
            Contact newWorker = TestObjects.createContact(6, 'NDIS');
            newWorker.LastName = 'Worker';
            newWorker.FirstName = 'newW' + String.valueOf(i);
            newWorker.Email = 'newWorker'+ String.valueOf(i) + '@betterrehab.com.au';
            newWorker.enrtcr__User__c = x.Id;

            listOfContacts.add(newWorker);
        }

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

        employee.Clinical_Supervisor__c = cs.Id;
        employee.Direct_Supervisor__c = ds.Id;
        updatedContacts.add(employee);
        ds.Direct_Supervisor__c = rm.Id;
        updatedContacts.add(ds);
        rm.Direct_Supervisor__c = sm.Id;
        updatedContacts.add(rm);

        update updatedContacts;

        List<PD_Request__c> PDList = new List<PD_Request__c>();

        Test.startTest();

        //Create PD Request
        PD_Request__c newPD = new PD_Request__c();
        newPD.RecordTypeID = pdRequestType.get('Clinician'); //CLINICIAN
        newPD.Employee_Name__c = employee.Id;
        newPD.Course_Name__c = 'First Aid / CPR';
        newPD.Course_Date_1__c = System.today() + 20;
        newPD.Cost_of_Course__c = 500;
        newPD.Principal_Clinician__c = pc.Id;
        newPD.Regional_Manager__c = rm.Id;
        newPD.Approved_by_Clinical_Supervisor__c = TRUE;
        newPD.Approved_by_Direct_Supervisor__c = TRUE;
        PDList.add(newPD);

        insert PDList;

        Test.stopTest();

        //Get the request based on the known ID
        PD_Request__c request1 = [SELECT id, Status__c FROM PD_Request__c WHERE id =: newPD.Id];

        //Get the list of all approvals with the request ID
        List<PD_Approval__c> allApprovals = [SELECT id FROM PD_Approval__c WHERE PD_Request__c =: request1.Id];

        //There should be 1 PC approval created initially
        System.assertEquals(1, allApprovals.size());
    }
}