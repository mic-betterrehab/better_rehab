@isTest
public class ActivationScriptTest {
    /*static testMethod void updateUsersTest() {
        User u = [SELECT Id, Email FROM User WHERE Email = 'mickale@betterrehab.com.au'];
        // Force update email to invalid for testing purposes
        u.Email = 'mickale@betterrehab.com.au.invalid';
		update u;
   
        Test.startTest();
            ActivationScript.updateUsers();
        Test.stopTest();
        
        User updatedUser = [SELECT Id, Email FROM User WHERE Id =: u.Id];

        System.assertEquals('mickale@betterrehab.com.au', updatedUser.Email);
    }

    static testMethod void createSiteTest() {
        Test.startTest();
            ActivationScript.createSites();
        Test.stopTest();

        List<String> listOfStrings = new List<String>{'Stones Corner', 'Moonee Ponds', 'Cockburn'};
        List<enrtcr__Site__c> sites = [SELECT Id, Name FROM enrtcr__Site__c WHERE Name IN: listOfStrings];

        System.assertEquals(3, sites.size());
    }

    static testMethod void createNoSiteTest() {
        Test.startTest();
            ActivationScript.createSites();
    
        Test.stopTest();

        List<String> listOfStrings = new List<String>{'Robina', 'Auckland'};
        List<enrtcr__Site__c> sites = [SELECT Id, Name FROM enrtcr__Site__c WHERE Name IN: listOfStrings];

        System.assertEquals(0, sites.size());
    }

    static testMethod void createWorkersTest() {
        createInvalidUsers(false);

        Test.startTest();
            ActivationScript.createWorkers();
        Test.stopTest();

        String workerRecordType = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Employee').getRecordTypeId();
        List<Contact> workers = [SELECT Id, Name FROM Contact WHERE RecordTypeId =: workerRecordType];

        System.assertEquals(5, workers.size());
    }

    static testMethod void createClientsTest() {
        createInvalidUsers(true);

        Test.startTest();
            ActivationScript.createClients();
        Test.stopTest();

        String clientRecordType = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Client').getRecordTypeId();
        List<Contact> clients = [SELECT Id, Name FROM Contact WHERE RecordTypeId =: clientRecordType];

        System.assertEquals(5, clients.size());
    }

    static testMethod void createClientCliniciansTest() {
        Contact worker = TestObjects.createContact(6, 'NDIS');
        Contact client = TestObjects.createContact(1, 'NDIS');
        insert worker;
        insert client;

        Test.startTest();
            ActivationScript.createClientClinicians();
        Test.stopTest();

 		List<enrtcr__Staff_Allocation__c> clientClinicians = [
            													SELECT Id
            													FROM enrtcr__Staff_Allocation__c
            													WHERE Clinician__c =: worker.Id AND Client__c =: client.Id
        													 ];

        System.assertEquals(1, clientClinicians.size());
    }

    static testMethod void createClientCliniciansNoWorkerTest() {
        Contact client = TestObjects.createContact(1, 'NDIS');
        insert client;

        Test.startTest();
            ActivationScript.createClientClinicians();
        Test.stopTest();

 		List<enrtcr__Staff_Allocation__c> clientClinicians = [
            													SELECT Id
            													FROM enrtcr__Staff_Allocation__c
            													WHERE Client__c =: client.Id
        													 ];

        System.assertEquals(0, clientClinicians.size());
    }

    static testMethod void createClientCliniciansNoClientTest() {
        Contact worker = TestObjects.createContact(6, 'NDIS');
        insert worker;

        Test.startTest();
            ActivationScript.createClientClinicians();
        Test.stopTest();

 		List<enrtcr__Staff_Allocation__c> clientClinicians = [
            													SELECT Id
            													FROM enrtcr__Staff_Allocation__c
            													WHERE Clinician__c =: worker.Id
        													 ];

        System.assertEquals(0, clientClinicians.size());
    }

    static testMethod void createSupportCategoriesTest() {
        Test.startTest();
        	ActivationScript.createSupportCategory();
        Test.stopTest();

        String sc = Schema.SObjectType.enrtcr__Reference_Data__c.getRecordTypeInfosByDeveloperName().get('Support_Category').getRecordTypeId();
        List<enrtcr__Reference_Data__c> supportCategories = [SELECT Id FROM enrtcr__Reference_Data__c WHERE RecordTypeId =: sc];

        System.assertEquals(5, supportCategories.size());
    }

    static testMethod void createRateTypeTest() {
        Test.startTest();
        	ActivationScript.createRateType();
        Test.stopTest();

        String rate = Schema.SObjectType.enrtcr__Reference_Data__c.getRecordTypeInfosByDeveloperName().get('Rate_Type').getRecordTypeId();
        List<enrtcr__Reference_Data__c> rateTypes = [SELECT Id FROM enrtcr__Reference_Data__c WHERE RecordTypeId =: rate];

        System.assertEquals(3, rateTypes.size());
    }

    static testMethod void createServicesTest() {
        enrtcr__Reference_Data__c support1 = TestObjects.createRD(27, 'BR Private Services', '');
        enrtcr__Reference_Data__c support2 = TestObjects.createRD(27, 'Improved daily living skills', '');
        enrtcr__Reference_Data__c support3 = TestObjects.createRD(27, 'Support Plan', '');
        enrtcr__Reference_Data__c support4 = TestObjects.createRD(27, 'QA Support', '');
        enrtcr__Reference_Data__c support5 = TestObjects.createRD(27, 'Ad Hoc Support', '');
        enrtcr__Reference_Data__c support6 = TestObjects.createRD(7, 'Tax Free (0%)', '');
        List<enrtcr__Reference_Data__c> supports = new List<enrtcr__Reference_Data__c>{
                                                        support1,
                                                        support2,
                                                        support3,
                                                        support4,
                                                        support5,
                                                        support6
                                                    };
        insert supports;

        Test.startTest();
        	ActivationScript.createServices();
        Test.stopTest();
		String ndis = Schema.SObjectType.enrtcr__Service__c.getRecordTypeInfosByDeveloperName().get('NDIS').getRecordTypeId();
        List<enrtcr__Service__c> rateTypes = [SELECT Id FROM enrtcr__Service__c WHERE RecordTypeId =: ndis];

        System.assertEquals(5, rateTypes.size());
    }

    static testMethod void createServiceAgreementTest() {
        Contact client = TestObjects.createContact(1, 'NDIS');
        insert client;

        Test.startTest();
        	ActivationScript.createServiceAgreement();
        Test.stopTest();
        
        List<enrtcr__Support_Contract__c> serviceAgreements = [
            													SELECT Id, enrtcr__Client__c
            													FROM enrtcr__Support_Contract__c
            													WHERE enrtcr__Client__c =: client.Id
        													  ];
        System.assertEquals(1, serviceAgreements.size());
        System.assertEquals(client.Id, serviceAgreements[0].enrtcr__Client__c);
    }

    static testMethod void createServiceAgreementItemsTest() {
        Contact client = TestObjects.createContact(1, 'NDIS');
        insert client;

        enrtcr__Support_Contract__c serviceAgreement = TestObjects.createSA(client.Id);
        insert serviceAgreement;

        Test.startTest();
        	ActivationScript.createServiceAgreementItems();
        Test.stopTest();

        List<enrtcr__Support_Contract_Item__c> items = [
                                                       		SELECT Id, enrtcr__Support_Contract__c
            												FROM enrtcr__Support_Contract_Item__c
            												WHERE enrtcr__Support_Contract__c =: serviceAgreement.Id
                                                       ];
        System.assertEquals(1, items.size());
        System.assertEquals(serviceAgreement.Id, items[0].enrtcr__Support_Contract__c);
    }
//--------------------------------------------------------------------------//
    static testMethod void createAllServiceTypeTest() {
        enrtcr__Service__c serviceType1;
        enrtcr__Service__c serviceType2;
        enrtcr__Service__c serviceType3;
        enrtcr__Service__c serviceType4;
        enrtcr__Reference_Data__c support = TestObjects.createRD(27, 'Support Plan', '');
        insert support;

        Test.startTest();
        	serviceType1 = ActivationScript.createServiceType(1, support.Id);
        	serviceType2 = ActivationScript.createServiceType(2, support.Id);
        	serviceType3 = ActivationScript.createServiceType(3, support.Id);
        	serviceType4 = ActivationScript.createServiceType(4, support.Id);
        Test.stopTest();
        
        System.assertEquals(support.Id, serviceType1.enrtcr__Support_CategoryId__c);
        System.assertEquals(null, serviceType2);
        System.assertEquals(support.Id, serviceType3.enrtcr__Support_CategoryId__c);
        System.assertEquals(null, serviceType4);
    }

    static testMethod void createNoServiceTypeTest() {
        enrtcr__Service__c serviceType;

        Test.startTest();
        	serviceType = ActivationScript.createServiceType(5, Schema.SObjectType.enrtcr__Service__c.getRecordTypeInfosByDeveloperName().get('NDIS').getRecordTypeId());
        Test.stopTest();
        
        System.assertEquals(null, serviceType);
    }

    static testMethod void createReferenceDataTest() {
        List<enrtcr__Reference_Data__c> referenceData = new List<enrtcr__Reference_Data__c>();

        Test.startTest();
        	referenceData.add(ActivationScript.createReferenceData(7, 'Tax Free (0%)', ''));
        	referenceData.add(ActivationScript.createReferenceData(27, 'Support Plan', ''));
        	referenceData.add(ActivationScript.createReferenceData(21, 'Support Plan', 'NDIS'));
        Test.stopTest();
        
        System.assertEquals(3, referenceData.size());
    }

    static testMethod void createNoReferenceDataTest() {
        enrtcr__Reference_Data__c supportCategory = new enrtcr__Reference_Data__c();
        enrtcr__Reference_Data__c rateType = new enrtcr__Reference_Data__c();
        enrtcr__Reference_Data__c gst = new enrtcr__Reference_Data__c();

        Test.startTest();
        	gst = ActivationScript.createReferenceData(1, 'Tax Free (0%)', '');
        	supportCategory = ActivationScript.createReferenceData(25, 'Support Plan', '');
        	rateType = ActivationScript.createReferenceData(21, 'Support Plan', 'ASD');
        Test.stopTest();
        
        System.assertEquals(null, supportCategory);
        System.assertEquals(null, rateType);
        System.assertEquals(null, gst);
    }

    static testMethod void allDisciplineTest() {
       	String ot;
        String sp;
        String physiotherapy;
        String ep;
        String aha;

        Test.startTest();
            ot = ActivationScript.discipline(1);
            sp = ActivationScript.discipline(2);
            physiotherapy = ActivationScript.discipline(3);
            ep = ActivationScript.discipline(4);
            aha = ActivationScript.discipline(5);
        Test.stopTest();

        List<String> allDiscipline = new List<String>{ot, sp, physiotherapy, ep, aha};

        System.assertEquals('Occupational Therapy', ot);
        System.assertEquals('Speech Pathology', sp);
        System.assertEquals('Physiotherapy', physiotherapy);
        System.assertEquals('Exercise Physiology', ep);
        System.assertEquals('Allied Health Assistant', aha);
        System.assertEquals(5, allDiscipline.size());
    }

    static testMethod void noDisciplineTest() {
       	String discipline;

        Test.startTest();
            discipline = ActivationScript.discipline(6);
        Test.stopTest();

        System.assertEquals(null, discipline);
    }

    static testMethod void removeInvalidSuffixTest() {
        createInvalidUsers(false);
 
        List<User> userList = [SELECT 
                                 	Id,
                                 	Email,
                                 	Username
                                 FROM User 
                                 WHERE Email LIKE '%.invalid' 
                                 AND IsActive = TRUE
                               	 LIMIT 5
                                ];

        System.assertNotEquals(0, 5);

        List<User> users = new List<User>();
		
        Test.startTest();
            users = ActivationScript.removeInvalidSuffix(userList);
        Test.stopTest();

        System.assertEquals(5, users.size());
    }

    static testMethod void removeInvalidSuffixNoUserTest() {
        List<User> userList = [SELECT 
                                 	Id,
                                 	Email,
                                 	Username
                                 FROM User 
                                 WHERE Email LIKE 'valid' 
                                 AND IsActive = TRUE
                               	 LIMIT 5
                                ];

        List<User> users = new List<User>();

        Test.startTest();
            users = ActivationScript.removeInvalidSuffix(userList);
        Test.stopTest();

        System.assertEquals(0, users.size());
    }

	static testMethod void createAccountAllRecordTypeTest() {
        Account agency = new Account();
        Account clinic = new Account();
        Account educationSetting = new Account();
        Account household = new Account();
        String agencyRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Agency_Other').getRecordTypeId();
        String clinicRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Clinic').getRecordTypeId();
        String educationRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Education_Setting').getRecordTypeId();
        String householdRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Household').getRecordTypeId();

        Test.startTest();
            agency = ActivationScript.createAccount(1);
            clinic = ActivationScript.createAccount(2);
            educationSetting = ActivationScript.createAccount(3);
            household = ActivationScript.createAccount(4);
        Test.stopTest();
        List<String> listOfStrings = new List<String>{agencyRT, clinicRT, educationRT, householdRT};
        List<Account> allAccounts = [SELECT Id FROM Account WHERE RecordTypeId IN: listOfStrings];
 
        System.assertNotEquals(null, agency);
        System.assertNotEquals(null, clinic);
        System.assertNotEquals(null, educationSetting);
        System.assertNotEquals(null, household);
        System.assertEquals(4, allAccounts.size());
    }

    static testMethod void createNoAccountTest() {
        Account agency = new Account();
        String agencyRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Agency_Other').getRecordTypeId();
        String clinic = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Clinic').getRecordTypeId();
        String education = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Education_Setting').getRecordTypeId();
        String household = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Household').getRecordTypeId();

        Test.startTest();
            agency = ActivationScript.createAccount(5);
        Test.stopTest();
        List<String> listOfStrings = new List<String>{agencyRT, clinic, education, household};
        List<Account> allAccounts = [SELECT Id FROM Account WHERE RecordTypeId IN: listOfStrings];

        System.assertEquals(null, agency);
        System.assertEquals(0, allAccounts.size());
    }
    
    private static void createInvalidUsers(Boolean isClient) {
        // Set up .invalid users
        
        Profile p = isClient ?
            			[SELECT Id FROM Profile WHERE Name NOT IN (
                                                            'Enrite Care - Standard',
                                                            'Enrite Care - Basic',
                                                            'Enrite Care - Advanced',
                                                            'System Administrator'
                                                        ) LIMIT 1] :
        				[SELECT Id FROM Profile WHERE Name = 'Enrite Care - Standard'];
        List<User> users = new List<User>();
        
        while (users.size() < 6) {
            Blob b = Crypto.GenerateAESKey(128);
            String h = EncodingUtil.ConvertTohex(b);
            String uid = h.SubString(0,8);
            User u = new User(Alias = uid, Email= uid + '@betterrehab.com.invalid', 
                              EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                              LocaleSidKey='en_AU', ProfileId = p.Id, 
                              TimeZoneSidKey='Australia/Sydney', UserName= uid + '@betterrehab.com');
            
            users.add(u);
        }
        
        insert users;
    }*/
}