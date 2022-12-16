public class ActivationScript {
    /*public static void updateUsers() {
        List<String> selectedUsers = new List<String>{
                                                        'nad@betterrehab.com.au%',
                                                        'rafella@betterrehab.com.au%',
                                                        'aravind@betterrehab.com.au%',
                                                        'mickale@betterrehab.com.au%'
                                                     };
        List<User> adminUsers = [SELECT Id, Email, Username FROM User WHERE Email LIKE: selectedUsers];

        List<User> updatedAdminUsers = removeInvalidSuffix(adminUsers);
    }
    
    public static void createSites() {
        String other = Schema.SObjectType.enrtcr__Site__c.getRecordTypeInfosByDeveloperName().get('Other').getRecordTypeId();
        List<enrtcr__Site__c> sites = new List<enrtcr__Site__c>();
		//
        enrtcr__Site__c site1 = new enrtcr__Site__c();
        site1.RecordTypeId = other;
        site1.Name = 'Cockburn';
        site1.enrtcr__Site_Name__c = 'Cockburn';
        site1.enrtcr__Business_State__c = 'WA';

        enrtcr__Site__c site2 = new enrtcr__Site__c();
        site2.RecordTypeId = other;
        site2.Name = 'Moonee Ponds';
        site2.enrtcr__Site_Name__c = 'Moonee Ponds';
        site2.enrtcr__Business_State__c = 'VIC';

        enrtcr__Site__c site3 = new enrtcr__Site__c();
        site3.RecordTypeId = other;
        site3.Name = 'Stones Corner';
        site3.enrtcr__Site_Name__c = 'Stones Corner';
        site3.enrtcr__Business_State__c = 'QLD';

        sites.add(site1);
        sites.add(site2);
        sites.add(site3);
        
        insert sites;
    }
    
    public static void createWorkers() {
        List<User> userWorkers = [SELECT 
                                 	Id,
                                 	Email,
                                  	FirstName,
                                  	LastName,
                                 	Username
                                 FROM User 
                                 WHERE Email LIKE '%.invalid' 
                                 AND IsActive = TRUE 
                                 AND Profile.Name = 'Enrite Care - Standard' LIMIT 5
                                ];
        
        if (userWorkers.size() > 0) {
            List<User> updatedWorkers = removeInvalidSuffix(userWorkers);
            List<Contact> workers = new List<Contact>();
            Integer i = 1;
    
            for (User u : updatedWorkers) {
                Contact con = new Contact();
                Account acc = createAccount(2);
                con.AccountId = acc.Id;
                con.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Employee').getRecordTypeId();
                con.Clinician_Discipline__c = discipline(i);
                con.Email = u.Email;
                con.FirstName = u.FirstName;
                con.LastName = u.LastName;
                con.enrtcr__Gender_Detail__c = 'Male';
                con.enrtcr__Client_Region__c = 'NSW';
                con.enrtcr__Start_Date__c = System.today();
                con.enrtcr__Status__c = 'Current';
                con.enrtcr__Mobile__c = '04322355644';
                
                workers.add(con);
                i++;
            }
    
            insert workers;
        }
    }

    public static void createClients() {
        List<User> userClients = [SELECT 
                                 	Id,
                                 	Email,
                                  	FirstName,
                                  	LastName,
                                 	Username
                                 FROM User 
                                 WHERE Email LIKE '%.invalid' 
                                 AND IsActive = TRUE 
                                 AND Profile.Name NOT IN (
                                                            'Enrite Care - Standard',
                                                            'Enrite Care - Basic',
                                                            'Enrite Care - Advanced',
                                                            'System Administrator'
                                                        )
                                 LIMIT 5
                                ];
        
        if (userClients.size() > 0) {
            List<User> updatedClients = removeInvalidSuffix(userClients);
            List<Contact> clients = new List<Contact>();
            
            for (User u : updatedClients) {
                Contact con = new Contact();
                con.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Client').getRecordTypeId();
                con.Client_Division__c = 'NDIS';
                con.Site_Allocation__c = 'Maroubra';
                con.Method__c = 'Face to Face';
                con.RAPT_Score__c = '6-9';
                con.enrtcr__Client_Region__c = 'NSW';
                con.enrtcr__Indigenous_Status__c = '5 - Unknown/Did Not Share';
                con.Email = u.Email;
                con.FirstName = u.FirstName;
                con.LastName = u.LastName;
                con.enrtcr__Gender_Detail__c = 'Male';
                con.enrtcr__Client_Region__c = 'NSW';
                con.enrtcr__Start_Date__c = System.today();
                con.enrtcr__Status__c = 'Current';
                con.enrtcr__Mobile__c = '04322355644';
                
                clients.add(con);
            }
    
            insert clients;
        }
    }
    
    public static void createClientClinicians() {
        String workerRecordType = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Employee').getRecordTypeId();
        String clientRecordType = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Client').getRecordTypeId();
        List<Contact> workers = [SELECT Id, Clinician_Discipline__c FROM Contact WHERE RecordTypeId =: workerRecordType];
        List<Contact> clients = [SELECT Id FROM Contact WHERE RecordTypeId =: clientRecordType];
        List<enrtcr__Staff_Allocation__c> clientClinicians = new List<enrtcr__Staff_Allocation__c>();
        Set<Id> workerIds = new Set<Id>();
        Set<Id> clientsIds = new Set<Id>();

        for (Contact con : workers) {
            workerIds.add(con.Id);
        }

        for (Contact con : clients) {
            clientsIds.add(con.Id);
        }

        if (workers.size() == clients.size()) {
            for (Integer i = 0; i < workers.size(); i++) {
                enrtcr__Staff_Allocation__c clientClinician = new enrtcr__Staff_Allocation__c();
                clientClinician.Clinician_Status__c = 'Active';
                clientClinician.Name = workers[i].Clinician_Discipline__c;
                clientClinician.Clinician__c = workers[i].Id;
                clientClinician.Client__c = clients[i].Id;

                clientClinicians.add(clientClinician);
            }

            insert clientClinicians;
        }
    }

    public static void createSupportCategory() {
        List<enrtcr__Reference_Data__c> supportCategories = new List<enrtcr__Reference_Data__c>();
        List<String> categoryNames = new List<String>{
                                        'BR Private Services',
                                        'Improved daily living skills',
                                        'Support Plan',
                                        'QA Support',
                                        'Ad Hoc Support'
                                     };

        for (String name : categoryNames) {
            enrtcr__Reference_Data__c category = createReferenceData(27, name, '');
            supportCategories.add(category);
        }

        insert supportCategories;
    }

    public static void createRateType() {
        List<enrtcr__Reference_Data__c> rateTypes = new List<enrtcr__Reference_Data__c>();
        List<String> categoryNames = new List<String>{
                                        'BR Private Services',
                                        'Improved daily living skills',
                                        'Support Plan',
                                        'QA Support',
                                        'Ad Hoc Support'
                                     };
        List<String> fundingTypes = new List<String>{
                                        'Other',
                                        'Grant',
                                        'NDIS'
                                     };
        Integer i = 0;

        for (String funding : fundingTypes) {
            enrtcr__Reference_Data__c rate = createReferenceData(21, categoryNames[i], funding);
            rateTypes.add(rate);
            i++;
        }

        insert rateTypes;
    }

    public static void createServices() {
        String sc = Schema.SObjectType.enrtcr__Reference_Data__c.getRecordTypeInfosByDeveloperName().get('Support_Category').getRecordTypeId();
        List<enrtcr__Reference_Data__c> supportCategories = [SELECT Id, Name FROM enrtcr__Reference_Data__c WHERE RecordTypeId =: sc];
        List<enrtcr__Service__c> services = new List<enrtcr__Service__c>();

        for (enrtcr__Reference_Data__c support : supportCategories) {
            enrtcr__Service__c service = createServiceType(3, support.Id);
            service.Name = support.Name;
            
            services.add(service);
        }

        insert services;
    }
    
    public static void createServiceAgreement() {
        String clientRecordType = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Client').getRecordTypeId();
        List<Contact> clients = [SELECT Id FROM Contact WHERE RecordTypeId =: clientRecordType];
        List<enrtcr__Support_Contract__c> serviceAgreements = new List<enrtcr__Support_Contract__c>();

        for (Contact client : clients) {
            enrtcr__Support_Contract__c SA = new enrtcr__Support_Contract__c();
            SA.enrtcr__Client__c = client.Id;
            SA.enrtcr__Funding_Type__c = 'Other';
            SA.enrtcr__Rate_Type__c = 'HSTP';
            SA.enrtcr__Start_Date__c = System.today() - 3;
            SA.enrtcr__End_Date__c = System.today() + 365;
            SA.enrtcr__Total_Allocation__c = 3000;
            SA.enrtcr__Service_Agreement_Overclaim__c = 'Allow';
            SA.enrtcr__Funding_Management__c = 'Participant';
            SA.enrtcr__Status__c = 'Current';
            SA.enrtcr__Client_Approved_Date__c = System.today();
            
            serviceAgreements.add(SA);
        }
        
        insert serviceAgreements;
    }

    public static void createServiceAgreementItems() {
        List<enrtcr__Support_Contract__c> serviceAgreements = [SELECT Id FROM enrtcr__Support_Contract__c WHERE enrtcr__Status__c = 'Current'];
        List<enrtcr__Support_Contract_Item__c> items = new List<enrtcr__Support_Contract_Item__c>();

        for (enrtcr__Support_Contract__c agreement : serviceAgreements) {
            enrtcr__Support_Contract_Item__c item = new enrtcr__Support_Contract_Item__c();
            item.RecordTypeId = '0122v0000013ObbAAE';
            item.enrtcr__Support_Contract__c = agreement.Id;

            items.add(item);
        }

        insert items;
    }
//-------------------------------------------------------------------------------//
// Predefined private methods
    //Type 1 = HSTP
    //Type 2 = Income
    //Type 3 = NDIS
    //Type 4 = Other
	@testVisible
    private static enrtcr__Service__c createServiceType(Integer type, Id supportCategory) {
        if (type < 1 || type > 4) {
            System.debug('Invalid type. Type must be 1,2,3 or 4');
            return null;
        }

        enrtcr__Service__c service = new enrtcr__Service__c();
        String htsp = Schema.SObjectType.enrtcr__Service__c.getRecordTypeInfosByDeveloperName().get('HSTP').getRecordTypeId();
        String income = Schema.SObjectType.enrtcr__Service__c.getRecordTypeInfosByDeveloperName().get('Income').getRecordTypeId();
        String ndis = Schema.SObjectType.enrtcr__Service__c.getRecordTypeInfosByDeveloperName().get('NDIS').getRecordTypeId();
        String other = Schema.SObjectType.enrtcr__Service__c.getRecordTypeInfosByDeveloperName().get('Other').getRecordTypeId();

        switch on type {
            when 1 {
                service.RecordTypeId = htsp;
                service.Name = 'HSTP - Initial Episode';
            } when 2 {
                service.RecordTypeId = income;
                System.debug('The "Income" record type is not supported at the moment. Sorry');
                return null;
            } when 3 {
                service.RecordTypeId = ndis;
                service.Name = 'Lvl 1 - Physio Appointment';
                service.enrtcr__Support_Item_Code__c = '15_055_0128_1_3';
            } when 4 {
                service.RecordTypeId = other;
                System.debug('The "other" record type is not supported at the moment. Sorry');
                return null;
            }
        }

        service.enrtcr__Support_CategoryId__c = supportCategory;
        service.enrtcr__Status__c = 'Active';
        service.Better_Rehab__c = true;

        return service;
    }
    //Type 21 = Rate Type
    //Type 27 = Support Category
    @testVisible
    private static enrtcr__Reference_Data__c createReferenceData(Integer type, String name, String fundingType) {
        Set<Integer> types = new Set<Integer>{7, 21, 27};
        Set<String> fundingTypes = new Set<String>{'Other', 'Grant', 'NDIS'};

        if (!types.contains(type)) {
            System.debug('Invalid type provided. Only types supported currently are 21 and 27');
            return null;
        }

        if (type == 21 && !fundingTypes.contains(fundingType)) {
            System.debug('Invalid Funding type provided for Rate Type');
            return null;
        }

        enrtcr__Reference_Data__c referenceData = new enrtcr__Reference_Data__c();
        String gst = Schema.SObjectType.enrtcr__Reference_Data__c.getRecordTypeInfosByDeveloperName().get('GST_Code').getRecordTypeId();
        String rate = Schema.SObjectType.enrtcr__Reference_Data__c.getRecordTypeInfosByDeveloperName().get('Rate_Type').getRecordTypeId();
        String sc = Schema.SObjectType.enrtcr__Reference_Data__c.getRecordTypeInfosByDeveloperName().get('Support_Category').getRecordTypeId();

        switch on type {
            when 7 {
                referenceData.RecordTypeId = gst;
                referenceData.enrtcr__GST_Code__c = 'GST';
            } when 21 {
                referenceData.RecordTypeId = rate;
                referenceData.enrtcr__Funding_Type__c = FundingType;
                referenceData.enrtcr__Bypass_Quote_Generation__c = true;
            } when 27 {
                referenceData.RecordTypeId = sc;
                referenceData.enrtcr__Support_Category_Number__c = 20;
            }
        }

        referenceData.Name = name;

        return referenceData;
    }

	@testVisible
    private static String discipline(Integer type) {
        if (type < 1 || type > 5) {
            return null;
        }

        String discipline = '';

        switch on type {
            when 1 {
                discipline = 'Occupational Therapy';
            } when 2 {
                discipline = 'Speech Pathology';
            } when 3 {
                discipline = 'Physiotherapy';
            } when 4 {
                discipline = 'Exercise Physiology';
            } when 5 {
                discipline = 'Allied Health Assistant';
            }
        }
        
        return discipline;
    }
    
    @testVisible
    private static List<User> removeInvalidSuffix(List<User> users) {
        List<User> updateUsers = new List<User>();

        for (User u : users) {
            if (u.Email.endsWithIgnoreCase('.invalid')) {
                u.Email = u.Email.removeEndIgnoreCase('.invalid');

            	updateUsers.add(u);
            }
        }

        update updateUsers;

        return updateUsers;
    }
    
    //Type 1 = Agency/Other
    //Type 2 = Clinic
    //Type 3 = Education Setting
    //Type 4 = Household
    @testVisible
    private static Account createAccount(Integer type) {
        if (type < 1 || type > 4) {
            return null;
        }

        Account a = new Account();
        a.Name = 'Activation Account ' + String.valueOf(type);
        String agency = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Agency_Other').getRecordTypeId();
        String clinic = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Clinic').getRecordTypeId();
        String education = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Education_Setting').getRecordTypeId();
        String household = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Household').getRecordTypeId();

        switch on type {
            when 1 {
                a.RecordTypeId = agency;
            } when 2 {
                a.RecordTypeId = clinic;
            } when 3 {
                a.RecordTypeId = education;
            } when 4 {
                a.RecordTypeId = household;
            }
        }

        insert a;

        return a;
    }*/
}