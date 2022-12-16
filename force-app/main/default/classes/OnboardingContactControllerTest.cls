@isTest
public class OnboardingContactControllerTest {
	@testSetup
    static void setup(){
        List<Contact> contactsToAdd = new List<Contact>();
        List<Contact> contactsToUpdate = new List<Contact>();

        User x = [SELECT id, Email FROM User WHERE Profile.Name = 'Enrite Care - Advanced' AND IsActive = true LIMIT 1];
        User teamLeaderUser = [SELECT id, Email, Name, KPI__c FROM User WHERE IsActive = TRUE LIMIT 1];

        // Better Rehab Profile
        Contact betterRehab = new Contact();
        betterRehab.LastName = 'Rehab';
        betterRehab.FirstName = 'Better';
        betterRehab.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Client').getRecordTypeId();
        betterRehab.enrtcr__Gender_Detail__c = 'Male';
        betterRehab.enrtcr__Client_Region__c = 'NSW';
        betterRehab.enrtcr__Start_Date__c = System.today();
        betterRehab.enrtcr__Status__c = 'Current';
        betterRehab.enrtcr__Mobile__c = '04322355644';

        insert betterRehab;

        // create a worker profile
       	Contact regionalManager = new Contact();
        regionalManager.LastName = 'super';
        regionalManager.FirstName = teamLeaderUser.Name;
        regionalManager.RecordTypeId = '0122v0000013OcoAAE';
        regionalManager.enrtcr__Gender_Detail__c = 'Male';
        regionalManager.enrtcr__Client_Region__c = 'NSW';
        regionalManager.enrtcr__Start_Date__c = System.today();
        regionalManager.enrtcr__Status__c = 'Current';
        regionalManager.enrtcr__Mobile__c = '04322355644';
        regionalManager.Clinician_Discipline__c = 'Occupational Therapy';
        regionalManager.Internal_Banding__c = 'Senior Clinician';
        regionalManager.Email = teamLeaderUser.Email;
        regionalManager.FTE__c = 1;
        regionalManager.enrtcr__User__c = teamLeaderUser.Id;

        insert regionalManager;

        // create a supervision profile for supervisee
        Contact rmSuper = new Contact();
        rmSuper.LastName = 'SUPERVISION';
        rmSuper.FirstName = teamLeaderUser.Name;
        rmSuper.RecordTypeId = '0122v0000013ObcAAE';
        rmSuper.enrtcr__Gender_Detail__c = 'Male';
        rmSuper.enrtcr__Client_Region__c = 'NSW';
        rmSuper.enrtcr__Start_Date__c = System.today();
        rmSuper.enrtcr__Status__c = 'Current';
        rmSuper.enrtcr__Mobile__c = '04322355644';
        rmSuper.Clinician_Discipline__c = 'Occupational Therapy';
        rmSuper.Email = teamLeaderUser.Email;

        contactsToAdd.add(rmSuper);

        Contact newWorker = new Contact();
        newWorker.LastName = 'super';
        newWorker.FirstName = 'clin';
        newWorker.RecordTypeId = '0122v0000013OcoAAE';
        newWorker.enrtcr__Gender_Detail__c = 'Male';
        newWorker.enrtcr__Client_Region__c = 'NSW';
        newWorker.enrtcr__Start_Date__c = System.today();
        newWorker.enrtcr__Status__c = 'Current';
        newWorker.enrtcr__Mobile__c = '04322355644';
        newWorker.Email = x.Email;
        newWorker.Internal_Banding__c = 'Senior Clinician';
        newWorker.enrtcr__User__c = x.Id;
        newWorker.Clinician_Discipline__c = 'Occupational Therapy';
        contactsToAdd.add(newWorker);

        insert contactsToAdd;

        enrtcr__Site__c site = TestObjects.createSite(2);
        site.Office_Admin__c = x.id;
        site.Name = 'Mulgrave';
        site.enrtcr__Business_State__c = 'VIC';
        insert site;

        // link supervision profile to worker profile and the direct supervisor
        rmSuper.Supervision__c = regionalManager.Id;
        regionalManager.Supervision__c = rmSuper.Id;

        contactsToUpdate.add(rmSuper);
        contactsToUpdate.add(regionalManager);

        update contactsToUpdate;

        //create the settings values
        KPI__c kpiDates = new KPI__c();
        kpiDates.Date_Start__c = System.today();
        kpiDates.Date_End__c = System.today() + 30;

        insert kpiDates;

        // create a supervision SA for the supervision profile
        List<enrtcr__Support_Contract__c> SAs = new List<enrtcr__Support_Contract__c>();
        SAs.add(TestObjectsSA.createServiceAgreement(rmSuper.Id, 'RM SA'));
        SAs.add(TestObjectsSA.createServiceAgreement(betterRehab.Id, 'SA-00004530'));

        insert SAs;

        // create support categories
        List<enrtcr__Reference_Data__c> SCs = new List<enrtcr__Reference_Data__c>();
        SCs.add(TestObjects.createRD(27, '1:1' , 'NDIS'));
        SCs.add(TestObjects.createRD(27, 'Joint Visit' , 'NDIS'));
        SCs.add(TestObjects.createRD(27, 'QA Support' , 'NDIS'));
        SCs.add(TestObjects.createRD(27, 'Clinical Audit' , 'NDIS'));
        SCs.add(TestObjects.createRD(27, 'Ramp Up' , 'NDIS'));

        insert SCs;

        Onboarding__c newOnboarder = new Onboarding__c();

        newOnboarder.User_Apex_Run__c = true;
        newOnboarder.Contact_Apex_Run__c = false;
        newOnboarder.Email__c = x.Email;
        newOnboarder.First_Name__c = 'newP';
        newOnboarder.Last_Name__c = 'person';
        newOnboarder.Site__c = site.Id;
        //newOnboarder.State__c = 'NSW';
        newOnboarder.FTE__c = 0.5;
        newOnboarder.Department__c = 'Physiotherapy';
        newOnboarder.Phone_Number__c = '0432 256 298';
        newOnboarder.Clinical_Supervisor__c = newWorker.Id;
        newOnboarder.Direct_Supervisor__c = regionalManager.Id;
        //newOnboarder.Office__c = 'Eastern Sydney';
        newOnboarder.Gender__c = 'Male';
        newOnboarder.Start_Date__c = System.today();
        newOnboarder.Internal_Banding__c = 'Senior Clinician';
        newOnboarder.Role_Title__c = 'Physiotherapy';

        insert newOnboarder;
    }

    @isTest static void test(){
        Onboarding__c newOnboarder = [select id, Email__c from onboarding__c where Last_Name__c = 'person'];

        Test.startTest();
        PageReference userPage = Page.OnboardContact_Button_Controller;
        Test.setCurrentPage(userPage);
        userPage.getParameters().put('Id', String.valueOf(newOnboarder.Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(newOnboarder);
        OnboardingContactController UC = new OnboardingContactController(sc);
        UC.autoRun();
        Test.stopTest();

        Contact[] contacts = [SELECT id, Email, Supervision__c FROM Contact WHERE Email =: newOnboarder.Email__c];
        Contact[] supervision = [SELECT id, Supervision__c FROM Contact WHERE LastName =: 'SUPERVISION'];

        System.debug('Did worker contact gets created? ' + contacts[0].Id + 'The supervision: ' + contacts[0].Supervision__c);
        System.debug('Did SUPERVISION contact gets created? ' + supervision[0].Id + 'The supervision: ' + supervision[0].Supervision__c);

        for (Integer i = 0 ; i < contacts.size() ; i++) {
            System.assertEquals(newOnboarder.Email__c, contacts[i].Email);
        }
    }

    @isTest static void populateQAReportingTest() {
        Contact ot = TestObjects.createContact(6, 'NDIS');
        Contact pbs = TestObjects.createContact(6, 'NDIS');
        Contact sp = TestObjects.createContact(6, 'NDIS');
        Contact p = TestObjects.createContact(6, 'NDIS');
        Contact ep = TestObjects.createContact(6, 'NDIS');
        Contact none = TestObjects.createContact(6, 'NDIS');
        String otQAReporting;
        String pbsQAReporting;
        String spQAReporting;
        String pQAReporting;
        String epQAReporting;
        String noneQAReporting;

        ot.Clinician_Discipline__c = 'Occupational Therapy';
        pbs.Clinician_Discipline__c = 'PBS';
        sp.Clinician_Discipline__c = 'Speech Pathology';
        p.Clinician_Discipline__c = 'Physiotherapy';
        ep.Clinician_Discipline__c = 'Exercise Physiology';
        none.Clinician_Discipline__c = '';

        List<Contact> contacts = new List<Contact>{ot, pbs, sp, p, ep};

        Test.startTest();
            otQAReporting = OnboardingContactController.populateQAReporting(ot.Clinician_Discipline__c);
            pbsQAReporting = OnboardingContactController.populateQAReporting(pbs.Clinician_Discipline__c);
            spQAReporting = OnboardingContactController.populateQAReporting(sp.Clinician_Discipline__c);
            pQAReporting = OnboardingContactController.populateQAReporting(p.Clinician_Discipline__c);
            epQAReporting = OnboardingContactController.populateQAReporting(ep.Clinician_Discipline__c);
            noneQAReporting = OnboardingContactController.populateQAReporting(none.Clinician_Discipline__c);
        Test.stopTest();

        System.assertEquals(QA_Reporting_Setting__mdt.getInstance('Occupational_Therapy').QA_Reporting__c, otQAReporting);
        System.assertEquals(QA_Reporting_Setting__mdt.getInstance('PBS').QA_Reporting__c, pbsQAReporting);
        System.assertEquals(QA_Reporting_Setting__mdt.getInstance('Speech_Pathology').QA_Reporting__c, spQAReporting);
        System.assertEquals(QA_Reporting_Setting__mdt.getInstance('Physiotherapy').QA_Reporting__c, pQAReporting);
        System.assertEquals(QA_Reporting_Setting__mdt.getInstance('Exercise_Physiology').QA_Reporting__c, epQAReporting);
        System.assertEquals('', noneQAReporting);
    }
}