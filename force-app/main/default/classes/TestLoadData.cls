@IsTest
public class TestLoadData
{
    public void LoadSettings()
    {
        enrtcr__Settings__c settings = enrtcr__Settings__c.getOrgDefaults();

        if (settings.Id == null)
        {
            settings.enrtcr__Package_Namespace__c = 'enrtcr';
            settings.enrtcr__Notification_Enabled__c = true;
            settings.enrtcr__Service_Agreement_Show_Program__c = true;
            insert settings;
        }
    }

    public void LoadRecords()
    {
        boolean doInsert = true;
        // insert rate type reference data
        testReferenceData = new List<enrtcr__Reference_Data__c>();
        referenceData = new Map<String, enrtcr__Reference_Data__c>();
        referenceData.put('Rate_Type:NDIS', new enrtcr__Reference_Data__c(Id = findId(enrtcr__Reference_Data__c.sObjectType, doInsert), Name='NDIS', RecordTypeId = RecordTypes.get(enrtcr__Reference_Data__c.sObjectType.getDescribe().getName() + ':Rate_Type').Id, enrtcr__Funding_Type__c = 'NDIS'));
        referenceData.put('Rate_Type:Other', new enrtcr__Reference_Data__c(Id = findId(enrtcr__Reference_Data__c.sObjectType, doInsert), RecordTypeId = RecordTypes.get(enrtcr__Reference_Data__c.sObjectType.getDescribe().getName() + ':Rate_Type').Id, enrtcr__Funding_Type__c = 'Other'));
        referenceData.put('Rate_Type:Grant', new enrtcr__Reference_Data__c(Id = findId(enrtcr__Reference_Data__c.sObjectType, doInsert), RecordTypeId = RecordTypes.get(enrtcr__Reference_Data__c.sObjectType.getDescribe().getName() + ':Rate_Type').Id, enrtcr__Funding_Type__c = 'Grant'));
        referenceData.put('Rate_Type:DVA', new enrtcr__Reference_Data__c(Id = findId(enrtcr__Reference_Data__c.sObjectType, doInsert),Name='DVA', RecordTypeId = RecordTypes.get(enrtcr__Reference_Data__c.sObjectType.getDescribe().getName() + ':Rate_Type').Id, enrtcr__Funding_Type__c = 'Grant'));
        referenceData.put('Support_Category:Test Support Category', new enrtcr__Reference_Data__c(Id = findId(enrtcr__Reference_Data__c.sObjectType, doInsert), RecordTypeId = RecordTypes.get(enrtcr__Reference_Data__c.sObjectType.getDescribe().getName() + ':Support_Category').Id, Name = 'Test Support Category'));
        referenceData.put('Session_Region:SA', new enrtcr__Reference_Data__c(Id = findId(enrtcr__Reference_Data__c.sObjectType, doInsert), RecordTypeId = RecordTypes.get(enrtcr__Reference_Data__c.sObjectType.getDescribe().getName() + ':Session_Region').Id, Name = 'SA'));

        testReferenceData.addAll(referenceData.values());

        if (doInsert)
        {
            insert referenceData.values();
        }

        testSites = new List<enrtcr__Site__c>();
        testSites.add(new enrtcr__Site__c(Id = findId(enrtcr__Site__c.sObjectType, doInsert), Name = 'Test'));

        if (doInsert)
        {
            insert testSites;
        }

        enrtcr__Site_User__c siteUser = new enrtcr__Site_User__c(Id = findId(enrtcr__Site_User__c.sObjectType, doInsert), enrtcr__Site__c = testSites[0].Id, enrtcr__User__c = UserInfo.getUserId());

        if (doInsert)
        {
            insert siteUser;
        }

        testServices = new List<enrtcr__Service__c>();
        testServices.add(new enrtcr__Service__c(Id = findId(enrtcr__Service__c.sObjectType, doInsert),
                enrtcr__Support_CategoryId__c = referenceData.get('Support_Category:Test Support Category').Id,
                Name = 'Old Service', enrtcr__NMDS_Service_Code__c = '1234',
                enrtcr__Include_in_Services_Received_Extract__c = true,
                enrtcr__Include_in_Service_User_Extract__c = true,
                enrtcr__Support_Item_Code__c = '15_048_0128_1_3'));

        testServices.add(new enrtcr__Service__c(Id = findId(enrtcr__Service__c.sObjectType, doInsert),
                enrtcr__Support_CategoryId__c = referenceData.get('Support_Category:Test Support Category').Id,
                Name = 'New Service', enrtcr__NMDS_Service_Code__c = '1234',
                enrtcr__Include_in_Services_Received_Extract__c = true,
                enrtcr__Include_in_Service_User_Extract__c = true,
                enrtcr__Support_Item_Code__c = '15_056_0128_1_3'));


        if (doInsert)
        {
            insert testServices;
            update testServices;
        }

        testSiteServices = new List<enrtcr__Site_Service__c>();
        testSiteServices.add(new enrtcr__Site_Service__c(Id = findId(enrtcr__Site_Service__c.sObjectType, doInsert), RecordTypeId = RecordTypes.get(enrtcr__Site_Service__c.sObjectType.getDescribe().getName() + ':Service_Assignment').Id, enrtcr__Site__c = testSites[0].Id, enrtcr__Service__c = testServices[0].Id));
        testSiteServices.add(new enrtcr__Site_Service__c(Id = findId(enrtcr__Site_Service__c.sObjectType, doInsert), RecordTypeId = RecordTypes.get(enrtcr__Site_Service__c.sObjectType.getDescribe().getName() + ':Service_Type_Outlet').Id, enrtcr__Site__c = testSites[0].Id, enrtcr__Service__c = testServices[0].Id));
        testSiteServices.add(new enrtcr__Site_Service__c(Id = findId(enrtcr__Site_Service__c.sObjectType, doInsert), RecordTypeId = RecordTypes.get(enrtcr__Site_Service__c.sObjectType.getDescribe().getName() + ':Service_Type_Outlet').Id, enrtcr__Site__c = testSites[0].Id, enrtcr__Service__c = testServices[1].Id));

        if (doInsert)
        {
            insert testSiteServices;
        }

        testRates = new List<enrtcr__Rate__c>();
        testRates.add(new enrtcr__Rate__c(Id = findId(enrtcr__Rate__c.sObjectType, doInsert),
                Name = 'NDIS',
                enrtcr__Service__c = testServices[0].Id,
                enrtcr__RateType__c = referenceData.get('Rate_Type:NDIS').Id,
                enrtcr__Amount_ex_GST__c = 10,
                enrtcr__Quantity_Type__c = 'Hour',
                enrtcr__GST__c = 1,
                //Rate_Type__c = 'Purchased Service',
                enrtcr__Effective_Date__c = Date.today().addMonths(-1)));


        this.testDvaRate = new enrtcr__Rate__c(Id = findId(enrtcr__Rate__c.sObjectType, doInsert),
                Name = 'DVA',
                enrtcr__Service__c = testServices[0].Id,
                enrtcr__RateType__c = referenceData.get('Rate_Type:DVA').Id,
                enrtcr__Amount_ex_GST__c = 10,
                enrtcr__Quantity_Type__c = 'Hour',
                enrtcr__GST__c = 1,
                enrtcr__Effective_Date__c = Date.today().addMonths(-1));

        testRates.add(testDvaRate);

        testRates.add(new enrtcr__Rate__c(Id = findId(enrtcr__Rate__c.sObjectType, doInsert),
                Name = 'NDIS',
                enrtcr__Service__c = testServices[1].Id,
                enrtcr__RateType__c = referenceData.get('Rate_Type:NDIS').Id,
                enrtcr__Amount_ex_GST__c = 10,
                enrtcr__Quantity_Type__c = 'Hour',
                enrtcr__GST__c = 1,
                //Rate_Type__c = 'Purchased Service',
                enrtcr__Effective_Date__c = Date.today().addMonths(-1)));



        if (doInsert)
        {
            insert testRates;
        }

        this.testRates[0].This_rate_has_been_replaced_with__c = testRates[2].Id;

        update testRates;

        List<Contact> clients = new List<Contact>();

        // client
        testClient = new Contact(Id = findId(Contact.sObjectType, doInsert),
                LastName = 'test',
                enrtcr__Sex__c = 'Male',
                Birthdate = Date.parse('01/01/1940'),
                enrtcr__Photo__c = '<img src="test" />',
                enrtcr__Secondary_Disability__c = 'test',
                OtherStreet = '123 test Street',
                OtherCity = 'Adelaide',
                OtherState = 'SA',
                OtherPostalCode = '5112',
                enrtcr__Date_Client_Registered__c = Date.today(),
                Phone = '12333333',
                enrtcr__Preferred_Communication_Method__c = 'Phone',
                enrtcr__Primary_Disability__c = 'Autism',
                enrtcr__Status__c = 'Current',
                enrtcr__Summary_Disability__c = 'Autism',
                enrtcr__Requires_Support_for_Decision_Making__c = 'No',
                enrtcr__Client_Region__c = 'Northern',
                //Family_Complexity__c = 'High',
                MobilePhone = '04111111',
                enrtcr__Active__c=true
        );
        clients.add(testClient);

        // client
        testClient2 = new Contact(Id = findId(Contact.sObjectType, doInsert),
                LastName = 'test',
                enrtcr__Sex__c = 'Male',
                Birthdate = Date.parse('01/01/1940'),
                enrtcr__Secondary_Disability__c = 'test',
                OtherStreet = '123 test Street',
                OtherCity = 'Adelaide',
                OtherState = 'SA',
                OtherPostalCode = '5112',
                enrtcr__Date_Client_Registered__c = Date.today(),
                Phone = '12333333',
                enrtcr__Preferred_Communication_Method__c = 'Phone',
                enrtcr__Primary_Disability__c = 'Autism',
                enrtcr__Status__c = 'Current',
                enrtcr__Summary_Disability__c = 'Autism',
                enrtcr__Requires_Support_for_Decision_Making__c = 'No',
                enrtcr__Client_Region__c = 'Northern',
                enrtcr__Active__c=true
                /*Family_Complexity__c = 'High'*/);
        clients.add(testClient2);

        if (doInsert)
        {
            insert clients;
        }
    }

    public void LoadServiceAgreements()
    {
        Boolean doInsert = true;
        supportContracts = new Map<String, enrtcr__Support_Contract__c>();
        // support contract
        testSupportContract = new enrtcr__Support_Contract__c(Id = findId(enrtcr__Support_Contract__c.sObjectType, doInsert),
                enrtcr__Client__c = testClient.Id,
                enrtcr__Start_Date__c = Date.today(),
                enrtcr__End_Date__c = Date.today().addYears(1),
                enrtcr__Status__c = 'Draft',
                RecordTypeId = RecordTypes.get(enrtcr__Support_Contract__c.sObjectType.getDescribe().getName() + ':Client').Id,
                enrtcr__Rate_Type__c = 'NDIS',
                enrtcr__Funding_Type__c = 'NDIS',
                enrtcr__Funding_Management__c = 'NDIA'
        );

        supportContracts.put('Client', testSupportContract);

        // support contract
        enrtcr__Support_Contract__c testSupportContractGrant = new enrtcr__Support_Contract__c(Id = findId(enrtcr__Support_Contract__c.sObjectType, doInsert),
                enrtcr__Client__c = testClient2.Id,
                enrtcr__Start_Date__c = Date.today(),
                enrtcr__End_Date__c = Date.today().addYears(1),
                enrtcr__Status__c = 'Current',
                RecordTypeId = RecordTypes.get(enrtcr__Support_Contract__c.sObjectType.getDescribe().getName() + ':Grant').Id,
                enrtcr__Rate_Type__c = 'Other',
                enrtcr__Funding_Type__c = referenceData.get('Rate_Type:Grant').Name
        );

        supportContracts.put('Grant', testSupportContractGrant);

        // support contract
        enrtcr__Support_Contract__c testSupportDvaContract = new enrtcr__Support_Contract__c(Id = findId(enrtcr__Support_Contract__c.sObjectType, doInsert),
                enrtcr__Start_Date__c = Date.today(),
                enrtcr__End_Date__c = Date.today().addYears(1),
                enrtcr__Status__c = 'Current',
                RecordTypeId = RecordTypes.get(enrtcr__Support_Contract__c.sObjectType.getDescribe().getName() + ':Grant').Id,
                enrtcr__Rate_Type__c = 'Other',
                enrtcr__Funding_Type__c = referenceData.get('Rate_Type:DVA').Name
        );

        supportContracts.put('DVA', testSupportDvaContract);

        if (doInsert)
        {
            insert supportContracts.values();
        }

        List<enrtcr__Support_Contract_Item__c> supportContractItems = new List<enrtcr__Support_Contract_Item__c>();

        testSupportContractItemCategory = new enrtcr__Support_Contract_Item__c(Id = findId(enrtcr__Support_Contract_Item__c.sObjectType, doInsert),
                enrtcr__Support_Contract__c = testSupportContract.Id,
                enrtcr__Site__c = testSites[0].Id,
                enrtcr__Service__c = testServices[0].Id,
                enrtcr__Rate__c = testRates[0].Id,
                enrtcr__Site_Service_Program__c = testSiteServices[0].Id,
                enrtcr__Quantity__c = 1,
                enrtcr__Exclude_Item_In_Totals__c = false,
                RecordTypeId = RecordTypes.get(enrtcr__Support_Contract_Item__c.sObjectType.getDescribe().getName() + ':Category').Id);

        supportContractItems.add(testSupportContractItemCategory);

        testSupportContractItem = new enrtcr__Support_Contract_Item__c(Id = findId(enrtcr__Support_Contract_Item__c.sObjectType, doInsert),
                enrtcr__Support_Contract__c = testSupportContract.Id,
                enrtcr__Site__c = testSites[0].Id,
                enrtcr__Service__c = testServices[0].Id,
                enrtcr__Site_Service_Program__c = testSiteServices[0].Id,
                enrtcr__Rate__c = testRates[0].Id,
                enrtcr__Quantity__c = 1,
                enrtcr__Category_Item__c = testSupportContractItemCategory.Id,
                enrtcr__Support_Category__c = referenceData.get('Support_Category:Test Support Category').Id,
                enrtcr__Exclude_Item_In_Totals__c = false,
                RecordTypeId = RecordTypes.get(enrtcr__Support_Contract_Item__c.sObjectType.getDescribe().getName() + ':Item').Id
        );

        supportContractItems.add(testSupportContractItem);


        enrtcr__Support_Contract_Item__c testSupportContractItemCategoryGrant = new enrtcr__Support_Contract_Item__c(Id = findId(enrtcr__Support_Contract_Item__c.sObjectType, doInsert),
                enrtcr__Support_Contract__c = supportContracts.put('Grant', testSupportContractGrant).Id,
                enrtcr__Site__c = testSites[0].Id,
                enrtcr__Service__c = testServices[0].Id,
                enrtcr__Rate__c = testRates[0].Id,
                enrtcr__Quantity__c = 1,
                enrtcr__Exclude_Item_In_Totals__c = false,
                RecordTypeId = RecordTypes.get(enrtcr__Support_Contract_Item__c.sObjectType.getDescribe().getName() + ':Category').Id);

        supportContractItems.add(testSupportContractItemCategoryGrant);

        if (doInsert)
        {
            insert supportContractItems;
        }


    }

    public void LoadServiceDelivered()
    {
        Boolean doInsert = true;
        this.testServicesDelivered = new List<enrtcr__Support_Delivered__c>();

        testSupportDelivered = new enrtcr__Support_Delivered__c(Id = findId(enrtcr__Support_Delivered__c.sObjectType, doInsert),
                enrtcr__Client__c = testClient.Id,
                enrtcr__Support_Contract__c = testSupportContract.Id,
                enrtcr__Support_Contract_Item__c = testSupportContractItem.Id,
                enrtcr__Site_Service_Program__c = testSiteServices[0].Id,
                enrtcr__Rate__c = testRates[0].Id,
                enrtcr__Date__c = Date.today(),
                enrtcr__Adhoc_Service__c = testServices[0].Id,
                enrtcr__Site__c = testSites[0].Id,
                enrtcr__Quantity__c = 1);

        this.testServicesDelivered.add(testSupportDelivered);

        this.testServicesDelivered.add(new enrtcr__Support_Delivered__c(Id = findId(enrtcr__Support_Delivered__c.sObjectType, doInsert),
                enrtcr__Client__c = testClient.Id,
                enrtcr__Support_Contract__c = testSupportContract.Id,
                enrtcr__Support_Contract_Item__c = testSupportContractItem.Id,
                enrtcr__Site_Service_Program__c = testSiteServices[2].Id,
                enrtcr__Rate__c = testRates[2].Id,
                enrtcr__Date__c = Date.today(),
                enrtcr__Adhoc_Service__c = testServices[1].Id,
                enrtcr__Site__c = testSites[0].Id,
                enrtcr__Quantity__c = 1));

        this.testServicesDelivered.add(new enrtcr__Support_Delivered__c(Id = findId(enrtcr__Support_Delivered__c.sObjectType, doInsert),
                enrtcr__Client__c = testClient.Id,
                enrtcr__Support_Contract__c = testSupportContract.Id,
                enrtcr__Support_Contract_Item__c = testSupportContractItem.Id,
                enrtcr__Site_Service_Program__c = testSiteServices[2].Id,
                enrtcr__Rate__c = testRates[0].Id,
                enrtcr__Date__c = Date.today(),
                enrtcr__Adhoc_Service__c = testServices[1].Id,
                enrtcr__Site__c = testSites[0].Id,
                enrtcr__Quantity__c = 1));


        if (doInsert)
        {
            insert testServicesDelivered;//testSupportDelivered;
        }
    }

    public void loadExtract() {
        enrtcr__Extract__c ext = new enrtcr__Extract__c(enrtcr__Start_Date__c = Date.today().addYears(-1), enrtcr__End_Date__c=Date.today().addDays(5));
        insert ext;
        List<enrtcr__Extract_Item__c> items = new List<enrtcr__Extract_Item__c>();

        for (enrtcr__Support_Delivered__c sd : this.testServicesDelivered) {
            items.add(new enrtcr__Extract_Item__c(enrtcr__Service_Delivered__c = sd.Id, enrtcr__Claim_Status__c = 'Error', enrtcr__Extract__c = ext.Id));
        }
        insert items;
        List<enrtcr__Support_Delivered__c> sdsToUpdate = new List<enrtcr__Support_Delivered__c>();

        for (enrtcr__Extract_Item__c item : items) {
            sdsToUpdate.add(new enrtcr__Support_Delivered__c(Id=item.enrtcr__Service_Delivered__c, enrtcr__Current_NDIS_Extract_Item__c = item.Id));
        }

        update sdsToUpdate;
    }
    public void loadExtract2() {
        enrtcr__Extract__c ext = new enrtcr__Extract__c(enrtcr__Start_Date__c = Date.today().addYears(-1), enrtcr__End_Date__c=Date.today().addDays(5));
        insert ext;
        List<enrtcr__Extract_Item__c> items = new List<enrtcr__Extract_Item__c>();

        for (enrtcr__Support_Delivered__c sd : this.testServicesDelivered) {
            items.add(new enrtcr__Extract_Item__c(enrtcr__Service_Delivered__c = sd.Id, enrtcr__Claim_Status__c = 'Error', enrtcr__Extract__c = ext.Id));
        }
        insert items;
        List<enrtcr__Support_Delivered__c> sdsToUpdate = new List<enrtcr__Support_Delivered__c>();

        for (enrtcr__Extract_Item__c item : items) {
            sdsToUpdate.add(new enrtcr__Support_Delivered__c(Id=item.enrtcr__Service_Delivered__c));
        }

        update sdsToUpdate;
    }
    public void LoadPersonalSupportPlans()
    {
        Boolean doInsert = true;
        // support plans
        testSupportPlans = new List<enrtcr__Personal_Support_Plan__c>();

        enrtcr__Personal_Support_Plan__c testSP = new enrtcr__Personal_Support_Plan__c(Id = findId(enrtcr__Personal_Support_Plan__c.sObjectType, doInsert),
                enrtcr__Client__c = testClient.Id,
                enrtcr__Domain__c = 'Behaviours of Concern',
                enrtcr__Sub_Domain__c = 'Absconding',
                enrtcr__Plan_Type__c = 'HEALTH PLAN',
                enrtcr__Status__c = 'Awaiting Approval',
                enrtcr__Display_as_Alert__c = true);

        if (doInsert)
        {
            insert testSP;
        }

        testSupportPlans.add(testSP);
    }

    public void LoadPersonalIdentifiers()
    {
        List<enrtcr__Personal_Identifier__c> pis = new List<enrtcr__Personal_Identifier__c>();
        for(RecordTypeInfo rti : enrtcr__Personal_Identifier__c.SObjectType.getDescribe().getRecordTypeInfos())
        {
            if(rti.isAvailable() && !rti.isMaster())
            {
                enrtcr__Personal_Identifier__c pi = new enrtcr__Personal_Identifier__c(enrtcr__Client__c = testClient.ID);
                pi.RecordTypeId = rti.getRecordTypeId();
                pi.enrtcr__Number__c = 'test';
                pis.add(pi);
            }
        }
        insert pis;
    }

    public void LoadRisks()
    {
        Boolean doInsert = true;
        // personal and environmental factors
        testPEFactors = new List<enrtcr__Risk__c>();

        enrtcr__Risk__c testPEF = new enrtcr__Risk__c(Id = findId(enrtcr__Risk__c.sObjectType, doInsert),
                enrtcr__Client__c = testClient.Id,
                enrtcr__Domain__c = 'Behaviours of Concern',
                enrtcr__Sub_Domain__c = 'Absconding',
                enrtcr__Status__c = 'Active',
                enrtcr__Display_as_Alert__c = true);

        if (doInsert)
        {
            insert testPEF;
        }

        testPEFactors.add(testPEF);
    }

    public void LoadConsents()
    {
        Boolean doInsert = true;
        // consents
        testConsents = new List<enrtcr__Consent__c>();

        enrtcr__Consent__c testConsent = new enrtcr__Consent__c(Id = findId(enrtcr__Consent__c.sObjectType, doInsert),
                enrtcr__Client__c = testClient.Id,
                enrtcr__Life_Issue__c = 'All',
                enrtcr__Consent_Arrangement__c = 'Client',
                enrtcr__Status__c = 'Active',
                enrtcr__Relationship__c = 'Self',
                enrtcr__Consent_Date__c = Date.today(),
                enrtcr__Display_as_Alert__c = true,
                enrtcr__Alert_Summary__c = 'test');

        if (doInsert)
        {
            insert testConsent;
        }
        testConsents.add(testConsent);

        enrtcr__Consent__c testConsent2 = new enrtcr__Consent__c(Id = findId(enrtcr__Consent__c.sObjectType, doInsert),
                enrtcr__Client__c = testClient.Id,
                enrtcr__Life_Issue__c = 'Chemical Restraint',
                enrtcr__Status__c = 'Active');

        if (doInsert)
        {
            insert testConsent2;
        }
        testConsents.add(testConsent2);

        enrtcr__Consent__c testConsent3 = new enrtcr__Consent__c(Id = findId(enrtcr__Consent__c.sObjectType, doInsert),
                enrtcr__Client__c = testClient.Id,
                enrtcr__Life_Issue__c = 'Chemical Restraint',
                enrtcr__Status__c = 'Active');

        if (doInsert)
        {
            insert testConsent3;
        }
        testConsents.add(testConsent3);
    }

    public void LoadHealthConditions()
    {
        Boolean doInsert = true;
        enrtcr__Health_Condition__c testHR = new enrtcr__Health_Condition__c(Id = findId(enrtcr__Health_Condition__c.sObjectType, doInsert),
                enrtcr__Client__c = testClient.Id,
                enrtcr__Status__c = 'Active',
                enrtcr__Display_as_Alert__c = true,
                enrtcr__Alert_Summary__c = 'test');
        testHealthConditions = new List<enrtcr__Health_Condition__c>();
        testHealthConditions.add(testHR);

        if (doInsert)
        {
            insert testHealthConditions;
        }
    }

    public void LoadNotes()
    {
        Boolean doInsert = true;
        testNotes = new List<enrtcr__Note__c>();
        testNotes.add(new enrtcr__Note__c(Id = findId(enrtcr__Note__c.sObjectType, doInsert), enrtcr__Client__c = testClient.Id));

        if (doInsert)
        {
            insert testNotes;
        }
    }

    public void LoadCarts()
    {
        Boolean doInsert = true;
        testCart = new enrtcr__Cart__c(Id = findId(enrtcr__Cart__c.sObjectType, doInsert), enrtcr__Client__c = testClient.Id,
                enrtcr__Service_Agreement__c = testSupportContract.Id, enrtcr__Amount_Due_ex_GST__c = 0, enrtcr__GST__c = 0);

        if (doInsert)
        {
            insert testCart;
        }

        testSupportDelivered.enrtcr__Cart__c = testCart.Id;
        update testSupportDelivered;
    }

    public Contact testClient;
    public Contact testClient2;
    public List<enrtcr__Reference_Data__c> testReferenceData;
    public Map<String, enrtcr__Reference_Data__c> referenceData;
    public List<enrtcr__Site__c> testSites;
    public List<enrtcr__Service__c> testServices;
    public List<enrtcr__Rate__c> testRates;
    public List<enrtcr__Personal_Support_Plan__c> testSupportPlans;
    //public List<Client__c> testClientAssets { get; set; } replace with Client Possession
    public List<enrtcr__Risk__c> testPEFactors;
    //public List<Annual_Service_Lifestyle_Review__c> testAnnualServiceReviews { get; set; }
    public List<enrtcr__Consent__c> testConsents;
    //public List<Client_Contact__c> testContacts { get; set; }
    public List<enrtcr__Health_Condition__c> testHealthConditions;
    public enrtcr__Support_Contract__c testSupportContract;
    public enrtcr__Support_Contract_Item__c testSupportContractItem;
    public enrtcr__Support_Contract_Item__c testSupportContractItemCategory;
    public enrtcr__Support_Delivered__c testSupportDelivered;
    public enrtcr__Cart__c testCart;
    public List<enrtcr__Note__c> testNotes;
    public List<enrtcr__Site_Service__c> testSiteServices;
    public Map<String, enrtcr__Support_Contract__c> supportContracts;
    public Event testEvent;
    public Task testTask;
    public enrtcr__Rate__c testDvaRate;
    public List<enrtcr__Support_Delivered__c> testServicesDelivered;
    public List<enrtcr__Session__c> testSessions;

    public enrtcr__Cart__c getTestCart()
    {
        return testCart;
    }

    public Contact getTestClient()
    {
        return testClient;
    }

    public Contact getTestClient2()
    {
        return testClient2;
    }

    public Map<String, RecordType> RecordTypes
    {
        get
        {
            if (RecordTypes == null)
            {
                RecordTypes = new Map<String, RecordType>();

                for (RecordType rt :
                [
                        SELECT Id,
                                sObjectType,
                                DeveloperName
                        FROM RecordType
                ])
                {
                    RecordTypes.put(rt.sObjectType + ':' + rt.DeveloperName, rt);
                }
            }
            return RecordTypes;
        }
        set;
    }

    public String findId(Schema.SObjectType sobjectType, Boolean doInsert)
    {
        return null;
//        if (doInsert)
//        {
//            return null;
//        }

        //return fflib_IDGenerator_Temp.generate(sobjectType);
    }

    public void LoadEvent() {
        boolean doInsert = true;
        testEvent = new Event();
        testEvent.Subject = 'test';
        testEvent.ActivityDateTime = Datetime.now();
        testEvent.DurationInMinutes = 60;
        testEvent.WhoId = testClient.Id;
        testEvent.enrtcr__Client__c = testClient.Id;
        testEvent.enrtcr__Home_Vist__c = true;

        if(doInsert)
        {
            insert testEvent;
        }
    }

    public void LoadTask()
    {

        testTask = new Task();
        testTask.Subject = 'test';
        testTask.ActivityDate = Date.today();
        testTask.WhoId = testClient.Id;
        testTask.Description = 'test';
        insert testTask;
    }

    public void LoadSessions()
    {
        testSessions = new List<enrtcr__Session__c>();
        enrtcr__Session__c session = new enrtcr__Session__c();
        session.enrtcr__Status__c = 'Draft';
        session.Name = 'Test Session';
        session.enrtcr__Required_Workers__c = 1;
        session.enrtcr__Visit_Type__c = 'Other';
        session.enrtcr__Other_Street__c = '70 Pirie Street';
        session.enrtcr__Other_State__c = 'SA';
        session.enrtcr__Other_City__c = 'Adelaide';
        session.enrtcr__Other_Country__c = 'Australia';
        session.enrtcr__Other_Postal_Code__c = '5000';
        session.enrtcr__Service_Types__c = 'Support Coordination';
        session.enrtcr__Start_Date__c = System.now();
        session.enrtcr__End_Date__c = System.now().addMinutes(60);
        session.enrtcr__Employee_Message__c = 'employee message';
        session.enrtcr__Comments__c = 'comments';
        testSessions.add(session);

        insert testSessions;

    }
}