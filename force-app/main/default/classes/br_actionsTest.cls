@isTest
public class br_actionsTest {
    //This test class is to test all the classes that are called in the br_actions controller page
    //For every method in br_actions, please create a new test method
	@testSetup
    static void setup(){
        List<Contact> contactsToAdd = new List<Contact>();
        List<Contact> contactsToUpdate = new List<Contact>();

        // get a user
        User supervisor = [SELECT id, Name, KPI__c FROM User WHERE Profile.Name = 'Enrite Care - Advanced' AND IsActive = true LIMIT 1];
        User teamLeaderUser = [SELECT id, Email, Name, KPI__c FROM User WHERE Profile.Name = 'Enrite Care - Advanced' AND IsActive = true LIMIT 1];

        // create an RM worker
       	Contact rm = TestObjects.createContact(6, 'NDIS');
        rm.LastName = 'Team Leader';
        rm.FirstName = teamLeaderUser.Name;
        rm.Clinician_Discipline__c = 'Occupational Therapy';
        rm.Internal_Banding__c = 'Senior Clinician';
        rm.Email = teamLeaderUser.Email;
        rm.FTE__c = 1;
        rm.enrtcr__User__c = teamLeaderUser.Id;

        insert rm;

        // create a regional manager supervision
        Contact RMSuper = TestObjects.createContact(1, 'NDIS');
        RMSuper.LastName = 'TL SUPERVISION';
        RMSuper.FirstName = teamLeaderUser.Name;
        RMSuper.Clinician_Discipline__c = 'Occupational Therapy';

        contactsToAdd.add(RMSuper);

        // create a worker profile in the OLD system
       	Contact supervisorContact = TestObjects.createContact(6, 'NDIS');
        supervisorContact.LastName = 'worker';
        supervisorContact.FirstName = supervisor.Name;
        supervisorContact.Clinician_Discipline__c = 'Occupational Therapy';
        supervisorContact.Internal_Banding__c = 'Senior Clinician';
        supervisorContact.enrtcr__Status__c = 'Current';
        supervisorContact.FTE__c = 0.8;
        supervisorContact.enrtcr__User__c = supervisor.Id;
        supervisorContact.Direct_Supervisor__c = rm.Id;

        contactsToAdd.add(supervisorContact);

        // create a worker supervision profile in the OLD system
        Contact supervisionProfile = TestObjects.createContact(1, 'NDIS');
        supervisionProfile.LastName = 'Worker SUPERVISION';
        supervisionProfile.FirstName = supervisor.Name;
        supervisionProfile.Clinician_Discipline__c = 'Occupational Therapy';

        contactsToAdd.add(supervisionProfile);

        // create a worker profile in the NEW system
       	Contact newFrameworkWorker = TestObjects.createContact(6, 'NDIS');
        newFrameworkWorker.LastName = 'NEW worker';
        newFrameworkWorker.FirstName = supervisor.Name;
        newFrameworkWorker.Clinician_Discipline__c = 'Occupational Therapy';
        newFrameworkWorker.Internal_Banding__c = 'Senior Clinician';
        newFrameworkWorker.FTE__c = 0.8;
        newFrameworkWorker.enrtcr__User__c = supervisor.Id;
        newFrameworkWorker.Direct_Supervisor__c = rm.Id;
        newFrameworkWorker.New_Framework__c = TRUE;

        contactsToAdd.add(newFrameworkWorker);

        // create a worker supervision profile in the NEW system
        Contact newWorkerSupervision = TestObjects.createContact(1, 'NDIS');
        newWorkerSupervision.LastName = 'NEW Worker SUPERVISION';
        newWorkerSupervision.FirstName = supervisor.Name;
        newWorkerSupervision.Clinician_Discipline__c = 'Occupational Therapy';

        contactsToAdd.add(newWorkerSupervision);

        //make someone with invalid IB and CD
        Contact otherWorker = TestObjects.createContact(6, 'NDIS');
        otherWorker.LastName = 'Non-Clinician';
        otherWorker.FirstName = supervisor.Name;
        otherWorker.Clinician_Discipline__c = 'Information Technology';
        otherWorker.Internal_Banding__c = 'IT Consultant';
        otherWorker.FTE__c = 0.8;
        otherWorker.enrtcr__User__c = supervisor.Id;
        contactsToAdd.add(otherWorker);

        // make invalid worker supervision
        Contact otherSupervision = TestObjects.createContact(1, 'NDIS');
        otherSupervision.LastName = 'Non-Clinician SUPERVISION';
        otherSupervision.FirstName = supervisor.Name;
        otherSupervision.Clinician_Discipline__c = 'Occupational Therapy';
        contactsToAdd.add(otherSupervision);

        // create a group supervision profile
        Contact groupProfile = TestObjects.createContact(6, 'NDIS');
        groupProfile.LastName = 'SUPERVISION';
        groupProfile.FirstName = 'Occupational Therapy';
        groupProfile.FTE__c = 1;
        groupProfile.Clinician_Discipline__c = 'Occupational Therapy';
        contactsToAdd.add(groupProfile);

        insert contactsToAdd;

        // link supervision profile to worker profile and vice versa
        supervisorContact.Supervision__c = supervisionProfile.Id;
        supervisionProfile.Supervision__c = supervisorContact.Id;
        otherWorker.Supervision__c = otherSupervision.Id;
        otherSupervision.Supervision__c = otherWorker.Id;
        RMSuper.Supervision__c = rm.Id;
        rm.Supervision__c = RMSuper.Id;
        newFrameworkWorker.Supervision__c = newWorkerSupervision.Id;
        newWorkerSupervision.Supervision__c = newFrameworkWorker.Id;

        contactsToUpdate.add(supervisorContact);
        contactsToUpdate.add(supervisionProfile);
        contactsToUpdate.add(otherWorker);
        contactsToUpdate.add(otherSupervision);
        contactsToUpdate.add(RMSuper);
        contactsToUpdate.add(rm);
        contactsToUpdate.add(newFrameworkWorker);
        contactsToUpdate.add(newWorkerSupervision);

        update contactsToUpdate;

        // create a supervision SA for the supervision profile
        List<enrtcr__Support_Contract__c> SAs = new List<enrtcr__Support_Contract__c>();
        SAs.add(TestObjectsSA.createServiceAgreement(supervisionProfile.Id, 'Supervision SA'));
        SAs.add(TestObjectsSA.createServiceAgreement(otherSupervision.Id, 'Supervision SA'));
        SAs.add(TestObjectsSA.createServiceAgreement(newWorkerSupervision.Id, 'Supervision SA'));
        SAs.add(TestObjectsSA.createServiceAgreement(RMSuper.Id, 'RM SA'));
        SAs.add(TestObjectsSA.createServiceAgreement(groupProfile.Id, 'Group Supervision SA'));

        insert SAs;

        // create support categories
        List<enrtcr__Reference_Data__c> SCs = new List<enrtcr__Reference_Data__c>();
        SCs.add(TestObjects.createRD(27, '1:1' , 'NDIS'));
        SCs.add(TestObjects.createRD(27, 'Joint Visit' , 'NDIS'));
        SCs.add(TestObjects.createRD(27, 'Operational Supervision' , 'NDIS'));
        SCs.add(TestObjects.createRD(27, 'QA Support' , 'NDIS'));
        SCs.add(TestObjects.createRD(27, 'Clinical Audit' , 'NDIS'));
        SCs.add(TestObjects.createRD(27, 'Onboarding' , 'NDIS'));
        SCs.add(TestObjects.createRD(27, 'Offboarding' , 'NDIS'));
        SCs.add(TestObjects.createRD(27, 'Mid Probation Review' , 'NDIS'));
        SCs.add(TestObjects.createRD(27, 'Probation Review' , 'NDIS'));
        SCs.add(TestObjects.createRD(27, 'Support Plan' , 'NDIS'));
        SCs.add(TestObjects.createRD(27, 'Performance Improvement Plan' , 'NDIS'));
        SCs.add(TestObjects.createRD(27, 'Business Development' , 'NDIS'));
        SCs.add(TestObjects.createRD(27, 'Supervisor Additional Travel' , 'NDIS'));
        SCs.add(TestObjects.createRD(27, 'RM Specific Task Allocation' , 'NDIS'));

        insert SCs;

        enrtcr__Support_Contract_Item__c groupSAI = new enrtcr__Support_Contract_Item__c();
        groupSAI.RecordTypeId = '0122v0000013ObbAAE';
        groupSAI.enrtcr__Support_Category_Amount__c = 20;
        groupSAI.enrtcr__Support_Category__c = TestObjects.createRD(27, 'Clinicial Group Supervision' , 'NDIS').Id;
        groupSAI.enrtcr__Support_Contract__c = SAs[3].Id;
        groupSAI.enrtcr__Item_Overclaim__c = 'Prevent';

        insert groupSAI;

        // create service agreement line items for the Supervision SA
        List<enrtcr__Support_Contract_Item__c> SAIs = new List<enrtcr__Support_Contract_Item__c>();
        SAIs.add(TestObjectsSA.createSAIs(SAs[0].id, SCs[0]));
        SAIs.add(TestObjectsSA.createSAIs(SAs[0].id, SCs[1]));
        SAIs.add(TestObjectsSA.createSAIs(SAs[0].id, SCs[2]));
        SAIs.add(TestObjectsSA.createSAIs(SAs[0].id, SCs[3]));
        SAIs.add(TestObjectsSA.createSAIs(SAs[0].id, SCs[4]));

        SAIs.add(TestObjectsSA.createSAIs(SAs[1].id, SCs[0]));
        SAIs.add(TestObjectsSA.createSAIs(SAs[1].id, SCs[1]));
        SAIs.add(TestObjectsSA.createSAIs(SAs[1].id, SCs[2]));
        SAIs.add(TestObjectsSA.createSAIs(SAs[1].id, SCs[3]));
        SAIs.add(TestObjectsSA.createSAIs(SAs[1].id, SCs[4]));

        SAIs.add(TestObjectsSA.createSAIs(SAs[2].id, SCs[0]));
        SAIs.add(TestObjectsSA.createSAIs(SAs[2].id, SCs[1]));
        SAIs.add(TestObjectsSA.createSAIs(SAs[2].id, SCs[2]));
        SAIs.add(TestObjectsSA.createSAIs(SAs[2].id, SCs[3]));
        SAIs.add(TestObjectsSA.createSAIs(SAs[2].id, SCs[4]));

        //for RM SA
        SAIs.add(TestObjectsSA.createSAIs(SAs[3].id, SCs[5]));
        SAIs.add(TestObjectsSA.createSAIs(SAs[3].id, SCs[6]));
        SAIs.add(TestObjectsSA.createSAIs(SAs[3].id, SCs[7]));
        SAIs.add(TestObjectsSA.createSAIs(SAs[3].id, SCs[8]));
        SAIs.add(TestObjectsSA.createSAIs(SAs[3].id, SCs[9]));
        SAIs.add(TestObjectsSA.createSAIs(SAs[3].id, SCs[10]));
        SAIs.add(TestObjectsSA.createSAIs(SAs[3].id, SCs[11]));
        SAIs.add(TestObjectsSA.createSAIs(SAs[3].id, SCs[12]));
        SAIs.add(TestObjectsSA.createSAIs(SAs[3].id, SCs[13]));

        insert SAIs;

        //create the settings values
        KPI__c kpiDates = new KPI__c();
        kpiDates.Date_Start__c = System.today();
        kpiDates.Date_End__c = System.today() + 30;

        insert kpiDates;

        //for KPI recal
        User[] users = [SELECT id, Name, Alias, KPI__c, Email, CommunityNickname FROM User LIMIT 5];

        List<Contact> contacts = new List<Contact>();

        for (User u : users) {
            Contact newWorker = new Contact();
            newWorker.LastName = 'super';
            newWorker.FirstName = u.Name;
            newWorker.RecordTypeId = '0122v0000013OcoAAE';
            newWorker.enrtcr__Gender_Detail__c = 'Male';
            newWorker.enrtcr__Client_Region__c = 'NSW';
            newWorker.enrtcr__Start_Date__c = System.today();
            newWorker.enrtcr__Status__c = 'Current';
            newWorker.enrtcr__Mobile__c = '04322355644';
            newWorker.Clinician_Discipline__c = 'Occupational Therapy';
        	newWorker.Internal_Banding__c = 'Graduate Clinician';
            newWorker.enrtcr__Start_Date__c = System.today().addDays(-200);
            newWorker.Email = u.Alias + '@betterrehab.com.au';
            newWorker.enrtcr__User__c = u.Id;
            newWorker.FTE__c = 0.9;
            newWorker.Clinical_Supervisor__c = supervisorContact.Id;
            contacts.add(newWorker);
        }

        insert contacts;

        List<Setting__c> settingsToInsert = new List<Setting__c>();

        Setting__c kpiflow = new Setting__c();
        kpiFlow.Name = 'kpiFlow';
        kpiFlow.Settings__c = '{"baseKPI":"25","AHA Early Service":"10","AHA Full Service":"15","AHA Community":"20","AHA Senior Service":"22","baseKPI NZ":"27.5"}';

        Setting__c misc = new Setting__c();
        misc.Name = 'Misc SA to Recalibrate';
        misc.Settings__c = '{"PBS SUPERVISION":"10","Speech Pathology SUPERVISION":"10","Physiotherapy Exercise Physiology SUPERVISION":"10","Occupational Therapy SUPERVISION":"20"}';

        Setting__c add = new Setting__c();
        add.Name = 'Additional SAs to Recalibrate';
        add.Settings__c = '{"Project SA":"10"}';

        settingsToInsert.add(kpiFlow);
        settingsToInsert.add(misc);
        settingsToInsert.add(add);

        insert settingsToInsert;
    }

    //Misc SA
    @isTest static void testMiscSA(){
        Test.startTest();
        br_actions page = new br_actions();
        page.recalibrateMiscSABatch();

        Test.stopTest();

        Contact clinician = [select id from contact where Name = 'Occupational Therapy SUPERVISION'];

        enrtcr__Support_Contract_Item__c[] saisFound = [SELECT Id, enrtcr__Support_Category__r.Name ,enrtcr__Support_Category_Amount__c,
                                                        enrtcr__Support_Contract__r.enrtcr__Total_Allocated__c, enrtcr__Support_Contract__r.enrtcr__Client__c,
                                                        enrtcr__Support_Contract__r.enrtcr__Remaining_Balance__c, enrtcr__Support_Contract__r.enrtcr__Total_Allocation__c
                                                        FROM enrtcr__Support_Contract_Item__c
                                                        WHERE enrtcr__Support_Contract__r.Name != NULL AND enrtcr__Support_Contract__r.enrtcr__Client__c =: clinician.Id];

        for (enrtcr__Support_Contract_Item__c item : saisFound) {
            System.debug(item.enrtcr__Support_Category_Amount__c + item.enrtcr__Support_Category__r.Name);
            if (item.enrtcr__Support_Category__r.Name == 'Group Clinical Supervision') {
                System.assertEquals(20, item.enrtcr__Support_Category_Amount__c);
            }
        }
    }

    //Supervision SA Batch
    @isTest static void testClinicianOldFramework(){
        Contact clinician = [select id from contact where LastName = 'Worker SUPERVISION'];

        Test.startTest();
        br_actions page = new br_actions();
        page.recalibrateSABatch();

        Test.stopTest();

        enrtcr__Support_Contract_Item__c[] saisFound = [SELECT Id, enrtcr__Support_Category__r.Name ,enrtcr__Support_Category_Amount__c,
                                                        enrtcr__Support_Contract__r.enrtcr__Total_Allocated__c, enrtcr__Support_Contract__r.enrtcr__Client__c,
                                                        enrtcr__Support_Contract__r.enrtcr__Remaining_Balance__c, enrtcr__Support_Contract__r.enrtcr__Total_Allocation__c
                                                        FROM enrtcr__Support_Contract_Item__c
                                                        WHERE enrtcr__Support_Contract__r.Name = 'Supervision SA' AND enrtcr__Support_Contract__r.enrtcr__Client__c =: clinician.Id];

        System.debug('How many SAIs found for this SA?: ' + saisFound.size());

        for (enrtcr__Support_Contract_Item__c item : saisFound) {
            System.debug(item.enrtcr__Support_Category_Amount__c + item.enrtcr__Support_Category__r.Name);
            if (item.enrtcr__Support_Category__r.Name == 'QA Support') {
                System.assertEquals(6 * 0.8, item.enrtcr__Support_Category_Amount__c);
            }
            if (item.enrtcr__Support_Category__r.Name == 'Operational Supervision') {
                System.assertEquals(0.5 * 0.8, item.enrtcr__Support_Category_Amount__c);
            }
            if (item.enrtcr__Support_Category__r.Name == 'Joint Visit') {
                System.assertEquals(2, item.enrtcr__Support_Category_Amount__c);
            }
            if (item.enrtcr__Support_Category__r.Name == '1:1') {
                System.assertEquals(1, item.enrtcr__Support_Category_Amount__c);
            }
            if (item.enrtcr__Support_Category__r.Name == 'Clinical Audit') {
                System.assertEquals(1 * 0.8, item.enrtcr__Support_Category_Amount__c);
            }
        }

        System.assertEquals((6 * 0.8) + (0.5*0.8) + (2) + (1) + (1*0.8), saisFound[0].enrtcr__Support_Contract__r.enrtcr__Total_Allocation__c);
    }

    //Supervision SA Batch
    @isTest static void testNonClinicianOldFramework(){
        Contact other = [select id from contact where LastName = 'Non-Clinician SUPERVISION'];

        Test.startTest();
        br_actions page = new br_actions();

        page.recalibrateSABatch();
        Test.stopTest();

        enrtcr__Support_Contract_Item__c[] saisFound = [SELECT Id, enrtcr__Support_Category__r.Name ,enrtcr__Support_Category_Amount__c,
                                                        enrtcr__Support_Contract__r.enrtcr__Total_Allocated__c, enrtcr__Support_Contract__r.enrtcr__Client__c,
                                                        enrtcr__Support_Contract__r.enrtcr__Remaining_Balance__c, enrtcr__Support_Contract__r.enrtcr__Total_Allocation__c
                                                        FROM enrtcr__Support_Contract_Item__c
                                                        WHERE enrtcr__Support_Contract__r.Name = 'Supervision SA' AND enrtcr__Support_Contract__r.enrtcr__Client__c =: other.Id];

        System.assertEquals(0, saisFound[0].enrtcr__Support_Contract__r.enrtcr__Total_Allocation__c);
    }

    //NEW Supervision SA Batch
    @isTest static void testClinicianNewFramework(){
        Contact clinician = [select id from contact where LastName = 'NEW Worker SUPERVISION'];

        Test.startTest();
        br_actions page = new br_actions();

        page.recalibrateSABatch();

        Test.stopTest();

        enrtcr__Support_Contract_Item__c[] saisFound = [SELECT Id, enrtcr__Support_Category__r.Name ,enrtcr__Support_Category_Amount__c,
                                                        enrtcr__Support_Contract__r.enrtcr__Total_Allocated__c, enrtcr__Support_Contract__r.enrtcr__Client__c,
                                                        enrtcr__Support_Contract__r.enrtcr__Remaining_Balance__c, enrtcr__Support_Contract__r.enrtcr__Total_Allocation__c
                                                        FROM enrtcr__Support_Contract_Item__c
                                                        WHERE enrtcr__Support_Contract__r.Name = 'Supervision SA' AND enrtcr__Support_Contract__r.enrtcr__Client__c =: clinician.Id];

        for (enrtcr__Support_Contract_Item__c item : saisFound) {
            System.debug(item.enrtcr__Support_Category_Amount__c + item.enrtcr__Support_Category__r.Name);
            if (item.enrtcr__Support_Category__r.Name == 'QA Support') {
                System.assertEquals(6 * 0.8, item.enrtcr__Support_Category_Amount__c);
            }
            if (item.enrtcr__Support_Category__r.Name == 'Joint Visit') {
                System.assertEquals(2, item.enrtcr__Support_Category_Amount__c);
            }
            if (item.enrtcr__Support_Category__r.Name == '1:1') {
                System.assertEquals(1, item.enrtcr__Support_Category_Amount__c);
            }
            if (item.enrtcr__Support_Category__r.Name == 'Clinical Audit') {
                System.assertEquals(1 * 0.8, item.enrtcr__Support_Category_Amount__c);
            }
        }

        System.assertEquals(4.8 + 2 + 1 + 0.8, saisFound[0].enrtcr__Support_Contract__r.enrtcr__Total_Allocation__c);
    }

    //RM SA Batch
    @isTest static void testRMSABatch(){
        Contact clinician = [select id from contact where LastName = 'TL SUPERVISION'];

        Test.startTest();
        br_actions page = new br_actions();
        enrtcr__Support_Contract_Item__c[] saisFoundOld = [SELECT Id, enrtcr__Support_Category__r.Name ,enrtcr__Support_Category_Amount__c,
                                                        enrtcr__Support_Contract__r.enrtcr__Total_Allocated__c, enrtcr__Support_Contract__r.enrtcr__Client__c,
                                                        enrtcr__Support_Contract__r.enrtcr__Remaining_Balance__c, enrtcr__Support_Contract__r.enrtcr__Total_Allocation__c
                                                        FROM enrtcr__Support_Contract_Item__c
                                                        WHERE enrtcr__Support_Contract__r.Name = 'RM SA' AND enrtcr__Support_Contract__r.enrtcr__Client__c =: clinician.Id];

        page.recalibrateRMSABatch();

        Test.stopTest();



        enrtcr__Support_Contract_Item__c[] saisFound = [SELECT Id, enrtcr__Support_Category__r.Name ,enrtcr__Support_Category_Amount__c,
                                                        enrtcr__Support_Contract__r.enrtcr__Total_Allocated__c, enrtcr__Support_Contract__r.enrtcr__Client__c,
                                                        enrtcr__Support_Contract__r.enrtcr__Remaining_Balance__c, enrtcr__Support_Contract__r.enrtcr__Total_Allocation__c
                                                        FROM enrtcr__Support_Contract_Item__c
                                                        WHERE enrtcr__Support_Contract__r.Name = 'RM SA' AND enrtcr__Support_Contract__r.enrtcr__Client__c =: clinician.Id];

        System.assertEquals(210 + saisFoundOld[0].enrtcr__Support_Contract__r.enrtcr__Total_Allocation__c, saisFound[0].enrtcr__Support_Contract__r.enrtcr__Total_Allocation__c);
    }

    //KPI Recalibration + recalibrate clinician
    @isTest static void testKPIRecalibration(){

        Contact supervisorContact = [SELECT Id, enrtcr__User__c FROM Contact WHERE LastName = 'Worker'];
        Test.startTest();

        br_actions page = new br_actions();
        page.KPIEmployeeId = supervisorContact.Id;
        page.recalibrateClinician();
        page.recalibrateKPIAll();

        Test.stopTest();
		
        User newSup = [SELECT id, Name,	KPI__c FROM User WHERE Id =: supervisorContact.enrtcr__User__c];
        Action_Log__c[] actionLogs = [SELECT id, Status__c FROM Action_Log__c LIMIT 1];
        System.assertEquals(12.50, newSup.KPI__c);
        System.assertEquals(1, actionLogs.size());
        System.assertEquals('Success', actionLogs[0].Status__c);
    }

}