@isTest
private class BR_ResourceControllerTest {
    static testMethod void getResourceTest() {
        // Get Random User
        User user = [SELECT Id, State FROM User WHERE id =: UserInfo.getUserId()];

        // Create Contact with a Client type record
        Contact client = TestObjects.createContact(1, 'NDIS');
        insert  client;

        // Create Site with an Other type record
        enrtcr__Site__c site = TestObjects.createSite(1);
        site.enrtcr__Business_State__c = user.State;
        insert site;

        // Create resources
        List<Resource__c> resources = TestObjects.createResource(5, 'Active', '1', site.Id);
        resources[0].Site__c = null;

        insert resources;

        // Create slots
        List<Slot__c> slots = new List<Slot__c>();

        for (Integer i = 0; i < 5; i++) {
            Slot__c slot = TestObjects.createSlot(user, resources[i], client, site);
            slots.add(slot);
        }

        insert slots;

        Test.startTest();
            Map<String, Object> res = BR_ResourceController.getResources(site.Id);
        Test.stopTest();

        System.assertEquals(2, res.size());
        System.assertNotEquals(null, res.get('resources'));
        System.assertNotEquals(null, res.get('slots'));
    }

    static testMethod void getActiveAndTierOneResourcesTest() {

        // Get Random User
        User user = createGroupWithUser(true);

        // Create Contact with a Client type record
        Contact client = TestObjects.createContact(1, 'NDIS');
        insert  client;

        // Create Site with an Other type record
        enrtcr__Site__c site = TestObjects.createSite(1);
        insert site;

        // Create resources
        List<Resource__c> resources = TestObjects.createResource(5, 'Active', '1', site.Id);
        insert resources;

        // Create slots
        List<Slot__c> slots = new List<Slot__c>();

        for (Integer i = 0; i < 5; i++) {
            Slot__c slot = TestObjects.createSlot(user, resources[i], client, site);
            slots.add(slot);
        }

        insert slots;

        Map<String, Object> res;
        Boolean isAdmin = false;

        System.runAs(user) {
            Test.startTest();
            	res = BR_ResourceController.getResources(site.Id);
            	isAdmin = BR_ResourceController.isResourceAdmin();
            Test.stopTest();
        }

        List<Object> listResources = (List<Object>) res.get('resources');
        Map<String, Object> mapResources = (Map<String, Object>) listResources[0];
        String state = (String) mapResources.get('stateName');

        System.assertEquals('NSW', state);
        System.assertEquals(true, isAdmin);
    }

    static testMethod void loadAdminUserTest() {
        Map<String, Object> userMap = new Map<String, Object>();

        // Create site
        enrtcr__Site__c site = TestObjects.createSite(1);
        insert site;

        User user = createGroupWithUser(true);

        System.runAs(user) {
            Test.startTest();
                userMap = BR_ResourceController.a_loadUser(site.Id);
            Test.stopTest();
        }

        System.assertEquals(2, userMap.size());
    }

    static testMethod void loadNonAdminUserTest() {
        Map<String, Object> userMap = new Map<String, Object>();

        // Create site
        enrtcr__Site__c site = TestObjects.createSite(1);
        insert site;

        User user = createGroupWithUser(false);

        System.runAs(user) {
            Test.startTest();
                userMap = BR_ResourceController.a_loadUser(site.Id);
            Test.stopTest();
        }

        System.assertEquals(2, userMap.size());
    }

    static User createGroupWithUser(Boolean isAdmin) {
        // Get Random User
        User user = isAdmin ?
                    [SELECT Id, State FROM User WHERE (Profile.Name = 'System Administrator' AND Profile.Name != NULL) AND IsActive = true LIMIT 1] :
                    [SELECT Id, State FROM User WHERE (Profile.Name != 'System Administrator' AND Profile.Name != NULL) AND IsActive = true LIMIT 1];

        // Create Group
        Group g = new Group();
        g.Name = 'Resource Admins';
        g.Type = 'Regular';
        insert g;

        // Create GroupMember
        GroupMember groupMember = new GroupMember();
        groupMember.GroupId = g.Id;
        groupMember.UserOrGroupId = getAdminUser().Id;

        System.runAs(getAdminUser()) {
            insert groupMember;
        }

        return user;
    }

    static User getAdminUser() {
        return [SELECT Id, Name FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
    }
}