@isTest
public class TestObjects {
    //Creates record of type Contact
    //Type 1 = Client
    //Type 2 = General
    //Type 3 = Intake
    //Type 4 = Participant
    //Type 5 = Provider
    //Type 6 = Worker
    static public Contact createContact(Integer type, String ClientDivision) {
        //Make sure client division input is valid
        Set<String> clientDivisions = new Set<String>();
        clientDivisions.add('NDIS');
        clientDivisions.add('HSTP');
        clientDivisions.add('Private');
        clientDivisions.add('NSW Schools Program');
        clientDivisions.add('Aged Care');
        if (!clientDivisions.contains(ClientDivision) && type == 1) {
            System.debug('Client Division specified not available in the picklist for this client creation');
            return null;
        }
        //make sure type input is valid
        if (type > 6 || type  < 1) {
            System.debug('Invalid type. Type can only be 1,2,3,4,5 or 6');
            return null;
        }

        Contact c = new Contact();
        switch on type {
            when 1 {
                c.RecordTypeId = '0122v0000013ObcAAE';
                c.Client_Division__c = ClientDivision;
                if (ClientDivision == 'HSTP') {
                    c.Provider__c = 'HCF';
                }
                c.Method__c = 'Face to Face';
                c.Site_Allocation__c = 'Maroubra';
                c.enrtcr__Client_Region__c = 'NSW';
                c.enrtcr__Indigenous_Status__c = '5 - Unknown/Did Not Share';
                c.Email = 'testclient@betterrehab.com.au';
                c.LastName = 'Client';
                c.RAPT_Score__c = '6-9';
            }
            when 2 {
                c.RecordTypeId = '0122v0000013ObdAAE';
                c.Referrer_Postcode__c = 2035;
                c.MobilePhone = '0432256298';
                Account a = createAccount(1);
                insert a;
                c.AccountId = a.Id;
                c.Email = 'testgeneral@betterrehab.com.au';
            }
            when 3 {
                c.RecordTypeId = '0122v0000013ObeAAE';
                c.Email = 'testIntake@betterrehab.com.au';
            }
            when 4 {
                c.RecordTypeId = '0122v000001Ud74AAC';
                c.Email = 'testParticipant@betterrehab.com.au';
            }
            when 5 {
                c.RecordTypeId = '0122v0000013ObfAAE';
                Account a = createAccount(1);
                insert a;
                c.AccountId = a.Id;
                c.Email = 'testProvider@betterrehab.com.au';
            }
            when 6 {
                c.RecordTypeId = '0122v0000013OcoAAE';
                //TestObjectsFuture.createUser();
                //User u = [SELECT Id FROM User WHERE Email = 'testUser@betterrehab.com.au'];
                //c.enrtcr__User__c = u.Id;
                c.Email = 'testWorker@betterrehab.com.au';
                c.LastName = 'Worker';
            }
        }
        c.FirstName = 'Test';
        c.enrtcr__Gender_Detail__c = 'Male';
        c.enrtcr__Client_Region__c = 'NSW';
        c.enrtcr__Start_Date__c = System.today();
        c.enrtcr__Status__c = 'Current';
        c.enrtcr__Mobile__c = '04322355644';


        return c;
    }

    //Creates record of type Account
    //Type 1 = Agency/Other
    //Type 2 = Clinic
    //Type 3 = Education Setting
    //Type 4 = Household
    static public Account createAccount(Integer type) {
        if (type < 1 || type > 4) {
            System.debug('Invalid type. Type can only be 1,2,3, or 4');
            return null;
        }
        Account a = new Account();
        a.Name = 'Test Account';
        switch on type {
            when 1 {
                a.RecordTypeId = '0122v0000013ObsAAE';
            }
            when 2 {
                a.RecordTypeId = '0122v0000013ObrAAE';
            }
            when 3 {
                a.RecordTypeId = '0122v0000013ObqAAE';
            }
            when 4 {
                a.RecordTypeId = '0122v000001Ud5EAAS';
            }
        }
        return a;
    }

    //Creates record of type User
    static public User createUser() {
        UserRole ClinBasic = [SELECT Id FROM UserRole WHERE Name='Clinicians (Basic)' limit 1];
        Profile Basic = [SELECT Id FROM Profile WHERE Name='Enrite Care - Basic' limit 1];
        User u = new User();
        u.LastName = 'User';
        u.FirstName = 'Test';
        u.Country = 'Australia';
        u.Email = 'testUser@betterrehab.com.au';
        u.MobilePhone = '0432256298';
        u.KPI__c = 30;
        u.State = 'NSW';
        u.Site__c = 'Eastern Sydney';
        u.Username = 'Test@betterrehab.com.au';
        u.CommunityNickname = 'Test';
        u.EmailEncodingKey = 'ISO-8859-1';
        u.ProfileId = Basic.Id;
        u.UserRoleId = ClinBasic.Id;
        u.TimeZoneSidKey = 'Australia/Sydney';
        u.LocaleSidKey = 'en_AU';
        u.UserPreferencesReceiveNoNotificationsAsApprover = false;
        u.Alias = 'testper';
        u.LanguageLocaleKey = 'en_US';

        return u;
    }

    //Creates record of type Site
    //Type 1 = Accomodation Services
    //Type 2 = Other
    static public enrtcr__Site__c createSite(Integer type) {
        if (type < 1 || type > 2) {
            System.debug('Invalid type provided. Type must either be 1 or 2');
            return null;
        }
        enrtcr__Site__c s = new enrtcr__Site__c();
        Account a = createAccount(1);
        insert a;
        switch on type {
            when 1 {
                s.RecordTypeId = '0122v0000013OeOAAU';
            }
            when 2 {
                s.RecordTypeId = '0122v0000013OeLAAU';
                s.enrtcr__Organisation_Name__c = a.Id;
            }
        }
        s.Name = 'Eastern Sydney';
        s.enrtcr__Site_Name__c = 'Eastern Sydney';
        s.enrtcr__Business_State__c = 'NSW';

        return s;
    }

    //Creates record of type Service Agreement
    static public enrtcr__Support_Contract__c createSA(Id clientID) {
        Contact client = [SELECT id FROM Contact WHERE id =: clientID];
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

        return SA;
    }

    //Creates record of type Reference Data
    //Type 7 = GST Code
    //Type 21 = Rate Type
    //Type 27 = Support Category
    static public enrtcr__Reference_Data__c createRD(Integer type, String Name, String FundingType) {
        Set<Integer> types = new Set<Integer>();
        types.add(7);
        types.add(21);
        types.add(27);
        if (!types.contains(type)) {
            System.debug('Invalid type provided. Only types supported currently are 21 and 27');
            return null;
        }
        Set<String> fundingTypes = new Set<String>();
        fundingTypes.add('Other');
        fundingTypes.add('Grant');
        fundingTypes.add('NDIS');
        fundingTypes.add('HCF');
        if (type == 21 && !fundingTypes.contains(FundingType)) {
            System.debug('Invalid Funding type provided for Rate Type');
            return null;
        }

        enrtcr__Reference_Data__c RD = new enrtcr__Reference_Data__c();
        switch on type {
            when 7 {
                RD.RecordTypeId = '0122v0000013OeaAAE';
                RD.enrtcr__GST_Code__c = 'GST';
            }
            when 21 {
                RD.RecordTypeId = '0122v0000013OeTAAU';
                RD.enrtcr__Funding_Type__c = FundingType;
                RD.enrtcr__Bypass_Quote_Generation__c = true;
            }
            when 27 {
                RD.RecordTypeId = '0122v0000013ObjAAE';
                RD.enrtcr__Support_Category_Number__c = 20;
            }
        }
        RD.Name = Name;

        return RD;
    }

    //Create Record of type Service Agreement Item
    //Type 1 = Category
    //Type 2 = Item
    static public enrtcr__Support_Contract_Item__c createSAI(Integer type, Id SA, Id SC) {
        if (type < 1 || type > 2) {
            System.debug('Invalid type provided. Type can only be 1 or 2');
            return null;
        }
        enrtcr__Support_Contract_Item__c SAI = new enrtcr__Support_Contract_Item__c();
        enrtcr__Support_Contract__c agreement = [SELECT id, enrtcr__Total_Allocation__c FROM enrtcr__Support_Contract__c WHERE id =: SA];
        enrtcr__Reference_Data__c supportCategory = [SELECT id FROM enrtcr__Reference_Data__c WHERE id =: SC];
        switch on type {
            when 1 {
                SAI.RecordTypeId = '0122v0000013ObaAAE';SAI.enrtcr__Support_Category__c = supportCategory.Id;
                SAI.enrtcr__Support_Category_Amount__c = agreement.enrtcr__Total_Allocation__c;
                SAI.enrtcr__Support_Category_Allocated__c = 0;
                SAI.enrtcr__Support_Category_Unallocated__c = agreement.enrtcr__Total_Allocation__c;
                SAI.enrtcr__Restrict_delivery_to_Service_Line_Item__c = false;
                SAI.enrtcr__Support_Category_Delivered__c = 0;
                SAI.enrtcr__Delivered__c = 0;
                SAI.enrtcr__Support_Category_Overclaim__c = 'Allow';
            }
            when 2 {
                SAI.RecordTypeId = '0122v0000013ObbAAE';
                System.debug('We do not support creating Service Agreement Line Items yet. Sorry');
                return null;
            }
        }
        SAI.enrtcr__Support_Contract__c = agreement.Id;

        return SAI;
    }

    //Create Record of type service
    //Type 1 = HSTP
    //Type 2 = Income
    //Type 3 = NDIS
    //Type 4 = Other
    static public enrtcr__Service__c createService(Integer type, Id SCid) {
        if (type < 1 || type > 4) {
            System.debug('Invalid type. Type must be 1,2,3 or 4');
            return null;
        }
        enrtcr__Reference_Data__c SC = [SELECT id FROM enrtcr__Reference_Data__c WHERE id =: SCid];
        enrtcr__Service__c s = new enrtcr__Service__c();
        switch on type {
            when 1 {
                s.RecordTypeId = '0122v000001OP6ZAAW';
                s.Name = 'HSTP - Initial Episode';
            }
            when 2 {
                s.RecordTypeId = '0122v000001Ud7kAAC';
                System.debug('The "Income" record type is not supported at the moment. Sorry');
                return null;
            }
            when 3 {
                s.RecordTypeId = '0122v0000013OeEAAU';
                s.Name = 'Lvl 1 - Physio Appointment';
                s.enrtcr__Support_Item_Code__c = '15_055_0128_1_3';
            }
            when 4 {
                s.RecordTypeId = '0122v0000013OeBAAU';
                System.debug('The "other" record type is not supported at the moment. Sorry');
                return null;
            }
        }
        s.enrtcr__Support_CategoryId__c = SC.id;

        s.enrtcr__Status__c = 'Active';
        s.Better_Rehab__c = true;
        s.State__c = 'NSW';

        return s;
    }

    //Create a record of type Rate
    //Type 1 = HSTP rate
    //Type 2 = NDIS Rate
    static public enrtcr__Rate__c createRate(Integer type, Id serviceID, Id RateType) {
        if (type != 1 && type != 2) {
            System.debug('Invalid Rate type. Please use rate type of 1 or 2');
            return null;
        }
        enrtcr__Reference_Data__c GST = createRD(7,'GST free', '');
        insert GST;
        enrtcr__Reference_Data__c RType = [SELECT id FROM enrtcr__Reference_Data__c WHERE id =: RateType];
        enrtcr__Service__c service = [SELECT Id FROM enrtcr__Service__c WHERE Id =: serviceID];

        enrtcr__Rate__c r = new enrtcr__Rate__c();
        if (type == 1) {
            r.enrtcr__Amount_Ex_GST__c = 0;
        } else if (type == 2) {
            r.enrtcr__Amount_Ex_GST__c = 193.99;
        }
        r.Name = 'Test Rate';
        r.enrtcr__Service__c = service.Id;
        r.enrtcr__RateType__c = RType.Id;
        r.enrtcr__GST_Code__c = GST.Id;
        r.enrtcr__Effective_Date__c = System.today() - 3;
        r.enrtcr__End_Date__c = System.today() + 365;
        r.enrtcr__GST__c = 0;
        r.enrtcr__Quantity_Type__c = 'Hours';

        return r;
    }

    //Create a record of type site service
    //Type 1 = Service Assignment
    //Type 2 = Service Type Outlet
    static public enrtcr__Site_Service__c createSS(Integer type, Id siteId, Id serviceId) {
        if (type < 1 && type > 2) {
            System.debug('Invalid type provided. types allowed are only 1 or 2');
            return null;
        }

        if (type == 2) {
            System.debug('We are currently not supporting this type of site service. Please use type 1');
            return null;
        }
        enrtcr__Site__c site = [SELECT Id FROM enrtcr__Site__c WHERE Id =: siteId];
        enrtcr__Service__c service = [SELECT Id FROM enrtcr__Service__c WHERE Id =: serviceId];

        enrtcr__Site_Service__c SS = new enrtcr__Site_Service__c();
        SS.enrtcr__Service__c = service.Id;
        SS.enrtcr__Site__c = site.Id;
        SS.enrtcr__Operating_Start_Date__c = System.today() - 3;

        return SS;
    }

    //Create a record of type service delivery entry
    static public enrtcr__Support_Delivered__c createSDE(Id WorkerId, Id ClientId, Id SC, Id serviceId, Id siteId, Id SAIId, Id RateId, Double Quantity, Id SSPr, Id SA) {
        User worker = [SELECT id FROM User WHERE id =: workerId];
        Contact client = [SELECT id FROM Contact WHERE id =: ClientId];
        enrtcr__Reference_Data__c support = [SELECT id FROM enrtcr__Reference_Data__c WHERE id =: SC];
        enrtcr__Service__c service = [SELECT id FROM enrtcr__Service__c WHERE id =: serviceId];
        enrtcr__Site__c site = [SELECT id FROM enrtcr__Site__c WHERE id =: siteId];
        enrtcr__Support_Contract_Item__c SAI = [SELECT id FROM enrtcr__Support_Contract_Item__c WHERE id =: SAIId];
        enrtcr__Rate__c rate = [SELECT id FROM enrtcr__Rate__c WHERE id =: RateId];
        enrtcr__Site_Service__c SSP = [SELECT id FROM enrtcr__Site_Service__c WHERE id =: SSPr];
        enrtcr__Support_Contract__c ServiceAgreement = [SELECT id FROM enrtcr__Support_Contract__c WHERE id =: SA];

        enrtcr__Support_Delivered__c SDE = new enrtcr__Support_Delivered__c();
        SDE.enrtcr__Date__c = System.today();
        SDE.enrtcr__Worker__c = worker.Id;
        SDE.enrtcr__Client__c = client.Id;
        SDE.enrtcr__Support_CategoryId__c = support.Id;
        SDE.enrtcr__Adhoc_Service__c = service.Id;
        SDE.enrtcr__Site__c = site.Id;
        SDE.enrtcr__Support_Contract_Item__c = SAI.Id;
        SDE.enrtcr__Rate__c = rate.Id;
        SDE.enrtcr__Quantity__c = Quantity;
        SDE.enrtcr__Ad_hoc__c = FALSE;
        SDE.enrtcr__Cancellation__c = FALSE;
        SDE.enrtcr__Client_Rep_Accepted__c = TRUE;
        SDE.enrtcr__Client_Rep_Accepted_Date__c = System.today();
        SDE.enrtcr__Site_Service_Program__c = SSP.Id;
        SDE.enrtcr__Support_Contract__c = ServiceAgreement.Id;

        return SDE;
    }

    static public Event createEvent(String eventType, String status, User owner){

        Event newEvent = new Event();
        newEvent.Subject = 'Test Event';
        newEvent.StartDateTime = System.now();
        newEvent.EndDateTime = System.now() + 5;
        newEvent.Event_Type__c = eventType;
        newEvent.RecordTypeId = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('BR_Event').getRecordTypeId();
        newEvent.Event_Status__c = status;
        newEvent.OwnerId = owner.Id;
        newEvent.Number_of_Workers__c = 0;
        newEvent.Number_of_Clients__c = 0;

        return newEvent;
    }

    static public Client_Event_Relation__c createCER(String status, Contact client, Event e){
        Client_Event_Relation__c newCER = new Client_Event_Relation__c();
        newCER.Client__c = client.Id;
        newCER.Status__c = status;
        newCER.Event_Id__c = e.Id;
        newCER.Name = 'Test CER';

        return newCER;
    }

    static public EventRelation createER(Contact worker, Event e){
        EventRelation newER = new EventRelation();
        newER.EventId = e.Id;
        newER.RelationId = worker.Id;

        return newER;
    }

    static public List<Event> createEventRecur(String eventType, String status, User owner){
        Event_Recurrence__c event_recur = new Event_Recurrence__c();
        insert event_recur;

        List<Event> events = new List<Event>();

        for (Integer i = 0 ; i < 2 ; i++ ) {
            Event newEvent = new Event();
            newEvent.Subject = 'Test Event' + String.valueOf(i);
            newEvent.StartDateTime = System.now() + 1 + i;
            newEvent.EndDateTime = System.now() + 1 + i;
            newEvent.Event_Type__c = eventType;
            newEvent.RecordTypeId = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('BR_Event').getRecordTypeId();
            newEvent.Event_Status__c = status;
            newEvent.OwnerId = owner.Id;
            newEvent.Number_of_Workers__c = 0;
            newEvent.Number_of_Clients__c = 0;
            newEvent.Event_Recurrence__c = event_recur.Id;
            newEvent.isRecurrence__c = TRUE;

            events.add(newEvent);
        }

        return events;
    }

    // Creatas a List of Resource
    static public List<Resource__c> createResource(Integer numberOfResources, String status, String tier, String site) {
        List<Resource__c> resources = new List<Resource__c>();

        for (Integer i = 0; i < numberOfResources; i++) {
            Resource__c resource = new Resource__c();
            resource.Name = 'Test Resource Name ' + String.valueOf(i);
            resource.Status__c = status;
            resource.Tier__c = tier;
            resource.Site__c = site;

            resources.add(resource);
        }

        return resources;
    }

    // Creates a record of Slot
    static public Slot__c createSlot(User user, Resource__c resource, Contact client, enrtcr__Site__c site) {
        Date startDate = System.today();
        Date endDate = startDate + 7;

        Slot__c slot = new Slot__c();
        slot.OwnerId = user.Id;
        slot.Resource__c = resource.Id;
        slot.Client__c = client.Id;
        slot.Destination_Site__c = site.Id;
        slot.Start_Time__c = startDate;
        slot.End_Time__c = endDate;

        return slot;
    }
    static public enrtcr__Extract__c createExtract(Integer rollUp, Integer status) {
        enrtcr__Extract__c extract = new enrtcr__Extract__c();
        extract.enrtcr__Error__c = 'This is a test error extract.';

        switch on rollUp {
            when 1 {
                extract.enrtcr__Rollup_Option__c = 'No rollup';
            } when 2 {
                extract.enrtcr__Rollup_Option__c = 'Rollup per day';
            } when 3 {
                extract.enrtcr__Rollup_Option__c = 'Rollup per date range';
            }
        }

        switch on status {
            when 1 {
                extract.enrtcr__Status__c = 'Generating';
            } when 2 {
                extract.enrtcr__Status__c = 'Ready to extract';
            } when 3 {
                extract.enrtcr__Status__c = 'Failed';
            } when 4 {
                extract.enrtcr__Status__c = 'Extracting Data';
            } when 5 {
                extract.enrtcr__Status__c = 'Data Extract Failed';
            } when 6 {
                extract.enrtcr__Status__c = 'Ready to Generate';
            } when 7 {
                extract.enrtcr__Status__c = 'Finished';
            }
        }

        return extract;
    }

    static public enrtcr__Extract_Item__c createExtractItem(Id extractId, String unitPrice) {
        enrtcr__Extract_Item__c extractItem = new enrtcr__Extract_Item__c();
        extractItem.enrtcr__Extract__c = extractId;
        extractItem.enrtcr__Unit_Price__c = unitPrice;

        return extractItem;
    }

    static public enrtcr__Assessment__c createAssessmentReview(Integer recordType) {
        enrtcr__Assessment__c assessment = new enrtcr__Assessment__c();
        assessment.Plan_Review_Report_Date__c = System.today();
        assessment.Passed_QA__c = true;
        assessment.Completed_By__c = UserInfo.getUserId();

        switch on recordType {
            when 1 {
                assessment.RecordTypeId = '0122v000001X408AAC';
            } when 2 {
                assessment.RecordTypeId = '0122v000001X36JAAS';
            } when 3 {
                assessment.RecordTypeId = '0122v000001eZulAAE';
            } when 4 {
                assessment.RecordTypeId = '0122v000001cBAAAA2';
            } when 5 {
                assessment.RecordTypeId = '0122v000001cBAFAA2';
            } when 6 {
                assessment.RecordTypeId = '0122v000001c9p1AAA';
            } when 7 {
                assessment.RecordTypeId = '0122v000001VTK9AAO';
            } when 8 {
                assessment.RecordTypeId = '0122v000001VRaUAAW';
            } when 9 {
                assessment.RecordTypeId = '0122v000001OQ2VAAW';
            } when 10 {
                assessment.RecordTypeId = '0122v000001VTIwAAO';
            } when 11 {
                assessment.RecordTypeId = '0122v000001VTJVAA4';
            } when 12 {
                assessment.RecordTypeId = '0122v000001X40DAAS';
            } when 13 {
                assessment.RecordTypeId = '0122v000001VmFZAA0';
            } when 14 {
                assessment.RecordTypeId = '0122v000001V3QVAA0';
            } when 15 {
                assessment.RecordTypeId = '0122v000001VTJ1AAO';
            } when 16 {
                assessment.RecordTypeId = '0128u0000004HquAAE';
            }
        }

        return assessment;
    }

    static public ContentVersion createContentVersion() {
        ContentVersion content = new ContentVersion(
            Title          = 'a picture',
            PathOnClient   = 'Pic.jpg',
            VersionData    = Blob.valueOf('Test Content'),
            origin = 'H'
        );

        return content;
    }

    static public Setting__c createSetting(String Name, String setting) {
        Setting__c newSetting = new Setting__c();
        newSetting.Name = Name;
        newSetting.Settings__c = setting;

        return newSetting;
    }

    public static enrtcr__Note__c createCaseNotes(Integer type, Integer recordType) {
        enrtcr__Note__c note = new enrtcr__Note__c();
        note.Name = 'Test Case Note';

        switch on type {
            when 1 {
                note.enrtcr__Type__c = 'Email';
            } when 2 {
                note.enrtcr__Type__c = 'Phone Call';
            } when 3 {
                note.enrtcr__Type__c = 'Phone Call Reportable';
            } when 4 {
                note.enrtcr__Type__c = 'SMS';
            } when 5 {
                note.enrtcr__Type__c = 'Assessment';
            } when 6 {
                note.enrtcr__Type__c = 'Initial Assessment Summary';
            } when 7 {
                note.enrtcr__Type__c = 'Risk Assessment';
            } when 8 {
                note.enrtcr__Type__c = 'Attachment';
            } when 9 {
                note.enrtcr__Type__c = 'Case Conference';
            } when 10 {
                note.enrtcr__Type__c = 'Case Note';
            } when 11 {
                note.enrtcr__Type__c = 'Centre Visit';
            } when 12 {
                note.enrtcr__Type__c = 'Childcare Visit';
            } when 13 {
                note.enrtcr__Type__c = 'Clinical Notes';
            } when 14 {
                note.enrtcr__Type__c = 'Event';
            } when 15 {
                note.enrtcr__Type__c = 'Group';
            } when 16 {
                note.enrtcr__Type__c = 'Home Visit';
            } when 17 {
                note.enrtcr__Type__c = 'Intake';
            } when 18 {
                note.enrtcr__Type__c = 'ISP';
            } when 19 {
                note.enrtcr__Type__c = 'Kindergarten Visit';
            } when 20 {
                note.enrtcr__Type__c = 'Letter Sent';
            } when 21 {
                note.enrtcr__Type__c = 'Migrated Client Info';
            } when 22 {
                note.enrtcr__Type__c = 'Progress Note';
            } when 23 {
                note.enrtcr__Type__c = 'Report Received';
            } when 24 {
                note.enrtcr__Type__c = 'Report Sent';
            } when 25 {
                note.enrtcr__Type__c = 'Report Writing';
            } when 26 {
                note.enrtcr__Type__c = 'School Visit';
            } when 27 {
                note.enrtcr__Type__c = 'Equipment';
            }
        }

        switch on recordType {
            when 1 {
                note.RecordTypeId = Schema.SObjectType.enrtcr__Note__c.getRecordTypeInfosByDeveloperName().get('Clinical_Note').getRecordTypeId();
            } when 2 {
                note.RecordTypeId = Schema.SObjectType.enrtcr__Note__c.getRecordTypeInfosByDeveloperName().get('Activity').getRecordTypeId();
            }
        }

        return note;
    }
}