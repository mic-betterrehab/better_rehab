@isTest
private class BR_ResourceSlotControllerTest {
    @testSetup
    static void setup() {
        // Create Contact with a Client type record
        Contact client = TestObjects.createContact(1, 'NDIS');
        insert  client;

        // Create Site with an Other type record
        enrtcr__Site__c site = TestObjects.createSite(1);
        site.enrtcr__Business_State__c = getUser(UserInfo.getUserId()).State;
        insert site;

        // Create resources
        List<Resource__c> resources = TestObjects.createResource(1, 'Active', '1', site.Id);
        
        insert resources;
    }

    static testMethod void initTest() {
        User user = getUser(UserInfo.getUserId());
        String now = DateTime.now().format('yyyy-MM-dd');
        String resourceQuery = 'AND Status__c = \'Active\' AND Tier__c = \'1\' AND (Site__c = NULL OR Site__r.enrtcr__Business_State__c = \''+user.State+'\') AND (Expiry_Date__c = NULL OR Expiry_Date__c >= '+now+')';

        Test.startTest();
            Map<String, String> init = BR_ResourceSlotController.a_init();
        Test.stopTest();

        System.assertEquals(1, init.size());
        System.assertEquals(resourceQuery, init.get('resource'));
    }

    static testMethod void createSlotTest() {
        DateTime now = System.now();
        // Making the seconds in now to 00
        DateTime startDate = now.addSeconds(-now.second());
        DateTime endDate = startDate.addDays(7);

        User user = getUser(UserInfo.getUserId());
        Contact client = getClientWithClientDivision('NDIS');
        enrtcr__Site__c site = getSiteWithRecordType('0122v0000013OeOAAU');
        Resource__c resource = getResourceWithStatusAndTier('Active', '1');

        Map<String, String> requestMap = new Map<String, String>();
        requestMap.put('resourceId', String.valueOf(resource.Id));
        requestMap.put('userId', String.valueOf(user.Id));
        requestMap.put('clientId', String.valueOf(client.Id));
        requestMap.put('destinationSiteId', String.valueOf(site.Id));
        requestMap.put('startDt', startDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
        requestMap.put('endDt', endDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));

        String requestJson = JSON.serialize(requestMap);

        Test.startTest();
            Slot__c slot = BR_ResourceSlotController.a_createSlot(requestJson);
        Test.stopTest();

        System.assertEquals(resource.Id, slot.Resource__c);
        System.assertEquals(user.Id, slot.OwnerId);
        System.assertEquals(site.Id, slot.Destination_Site__c);
        System.assertEquals(client.Id, slot.Client__c);
        System.assertEquals(startDate, slot.Start_Time__c);
        System.assertEquals(endDate, slot.End_Time__c);
    }

    static testMethod void updateSlotDestinationSiteNullTest() {
        User user = getUser(UserInfo.getUserId());
        Contact client = getClientWithClientDivision('NDIS');
        enrtcr__Site__c site = getSiteWithRecordType('0122v0000013OeOAAU');
        Resource__c resource = getResourceWithStatusAndTier('Active', '1');
        // Create Slot record
        Slot__c newSlot = TestObjects.createSlot(user, resource, client, site);

        insert newSlot;

        DateTime startTime = newSlot.Start_Time__c.addHours(3);
        DateTime endTime = newSlot.End_Time__c.addHours(8);

        Map<String, String> requestMap = new Map<String, String>();
        requestMap.put('slotId', String.valueOf(newSlot.Id));
        requestMap.put('destinationSite', String.valueOf(site.Id));
        requestMap.put('startTime', startTime.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
        requestMap.put('endTime', endTime.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));

        String requestJson = JSON.serialize(requestMap);

        Test.startTest();
            Slot__c slot = BR_ResourceSlotController.a_updateSlot(requestJson);
        Test.stopTest();

        System.assertEquals(newSlot.Id, slot.Id);
        System.assertNotEquals(null, slot.Destination_Site__c);
        System.assertEquals(startTime, slot.Start_Time__c);
        System.assertEquals(endTime, slot.End_Time__c);
    }

    static testMethod void updateSlotDestinationSiteNotNullTest() {
        User user = getUser(UserInfo.getUserId());
        Contact client = getClientWithClientDivision('NDIS');
        enrtcr__Site__c site = getSiteWithRecordType('0122v0000013OeOAAU');
        Resource__c resource = getResourceWithStatusAndTier('Active', '1');
        // Create Slot record
        Slot__c newSlot = TestObjects.createSlot(user, resource, client, site);

        insert newSlot;

        DateTime startTime = newSlot.Start_Time__c.addHours(3);
        DateTime endTime = newSlot.End_Time__c.addHours(8);

        Map<String, String> requestMap = new Map<String, String>();
        requestMap.put('slotId', String.valueOf(newSlot.Id));
        requestMap.put('startTime', startTime.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
        requestMap.put('endTime', endTime.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));

        String requestJson = JSON.serialize(requestMap);

        Test.startTest();
            Slot__c slot = BR_ResourceSlotController.a_updateSlot(requestJson);
        Test.stopTest();

        System.assertEquals(newSlot.Id, slot.Id);
        System.assertEquals(null, slot.Destination_Site__c);
        System.assertEquals(startTime, slot.Start_Time__c);
        System.assertEquals(endTime, slot.End_Time__c);
    }

    static testMethod void deleteSlotTest() {
        User user = getUser(UserInfo.getUserId());
        Contact client = getClientWithClientDivision('NDIS');
        enrtcr__Site__c site = getSiteWithRecordType('0122v0000013OeOAAU');
        Resource__c resource = getResourceWithStatusAndTier('Active', '1');
        // Create Slot record
        Slot__c newSlot = TestObjects.createSlot(user, resource, client, site);
    
        insert newSlot;
    
        Test.startTest();
            BR_ResourceSlotController.a_deleteSlot(newSlot.Id);
        Test.stopTest();
    
        List<Slot__c> listOfSlot = getSlot(newSlot.Id);
    
        System.assertEquals(0, listOfSlot.size());
    }

    static testMethod void getSlotTest() {
        User user = getUser(UserInfo.getUserId());
        Contact client = getClientWithClientDivision('NDIS');
        enrtcr__Site__c site = getSiteWithRecordType('0122v0000013OeOAAU');
        Resource__c resource = getResourceWithStatusAndTier('Active', '1');
        // Create Slot record
        Slot__c newSlot = TestObjects.createSlot(user, resource, client, site);
    
        insert newSlot;
    
        Test.startTest();
            Slot__c slot = BR_ResourceSlotController.a_getSlot(newSlot.Id);
        Test.stopTest();
    
        System.assertEquals(newSlot.Resource__c, slot.Resource__c);
        System.assertEquals(newSlot.OwnerId, slot.OwnerId);
        System.assertEquals(newSlot.Destination_Site__c, slot.Destination_Site__c);
        System.assertEquals(newSlot.Client__c, slot.Client__c);
        System.assertEquals(newSlot.Start_Time__c, slot.Start_Time__c);
        System.assertEquals(newSlot.End_Time__c, slot.End_Time__c);
    }

    static List<Slot__c> getSlot(Id slotId) {
        List<Slot__c> listOfSlot = [SELECT Id FROM Slot__c WHERE Id =: slotId];
    
        return listOfSlot;
    }

    static User getUser(Id userId) {
        return [SELECT Id, State FROM User WHERE Id =: userId];
    }

    static Contact getClientWithClientDivision(String clientDivision) {
        return [SELECT Id FROM Contact WHERE Client_Division__c =: clientDivision LIMIT 1];
    }

    static enrtcr__Site__c getSiteWithRecordType(String recordType) {
        return [SELECT Id FROM enrtcr__Site__c WHERE RecordTypeId =: recordType];
    }

    static Resource__c getResourceWithStatusAndTier(String status, String tier) {
        return [SELECT Id FROM Resource__c WHERE Status__c =: status AND Tier__c =: tier];
    }
}