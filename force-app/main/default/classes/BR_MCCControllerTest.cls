@isTest
public with sharing class BR_MCCControllerTest {
    /**
     * MCC Added test methods
     */
    static testMethod void getClinicianAndEventsTest() {
        // create test site
        enrtcr__Site__c site = TestObjects.createSite(2);
        insert site;

        // pull a random user
        Id userId = UserInfo.getUserId();
        User u = [SELECT Id FROM User WHERE id =: userId];

        // create a worker
        Contact worker = TestObjects.createContact(6, 'NDIS');
        worker.enrtcr__Site__c = site.Id;
        worker.enrtcr__User__c = u.Id;
        insert worker;

        Test.startTest();
            Map<String, Object> res = BR_MCCController.getClinicianAndEvents('2022-09-20T00:00:00+00:00');
        Test.stopTest();

        System.assertEquals(true, res.containsKey('clinicians'));
        System.assertEquals(true, res.containsKey('events'));
        System.assertEquals(true, res.containsKey('loggedInUser'));
    }

    static testMethod void getClinicianAndEventsBySiteTest() {
        // create test site
        enrtcr__Site__c site = TestObjects.createSite(2);
        insert site;

        // pull a random user
        Id userId = UserInfo.getUserId();
        User u = [SELECT Id FROM User WHERE id =: userId];

        // create a worker
        Contact worker = TestObjects.createContact(6, 'NDIS');
        worker.enrtcr__Site__c = site.Id;
        worker.enrtcr__User__c = u.Id;
        insert worker;

        Test.startTest();
            Map<String, Object> res = BR_MCCController.getClinicianAndEventsBySite('2022-09-20T00:00:00+00:00', site.Name);
        Test.stopTest();

        System.assertEquals(true, res.containsKey('clinicians'));
        System.assertEquals(true, res.containsKey('events'));
        System.assertEquals(true, res.containsKey('loggedInUser'));
    }

    static testMethod void getClinicianAndEventsByDisciplineTest() {
        // create test site
        enrtcr__Site__c site = TestObjects.createSite(2);
        insert site;

        // pull a random user
        Id userId = UserInfo.getUserId();
        User u = [SELECT Id FROM User WHERE id =: userId];

        // create a worker
        Contact worker = TestObjects.createContact(6, 'NDIS');
        worker.enrtcr__Site__c = site.Id;
        worker.enrtcr__User__c = u.Id;
        insert worker;

        Test.startTest();
            Map<String, Object> res = BR_MCCController.getClinicianAndEventsByDiscipline('2022-09-20T00:00:00+00:00', 'Occupational Therapist');
        Test.stopTest();

        System.assertEquals(true, res.containsKey('clinicians'));
        System.assertEquals(true, res.containsKey('events'));
        System.assertEquals(true, res.containsKey('loggedInUser'));
    }

    static testMethod void getClinicianAndEventsBySiteAndDisciplineTest() {
        // create test site
        enrtcr__Site__c site = TestObjects.createSite(2);
        insert site;

        // pull a random user
        Id userId = UserInfo.getUserId();
        User u = [SELECT Id FROM User WHERE id =: userId];

        // create a worker
        Contact worker = TestObjects.createContact(6, 'NDIS');
        worker.enrtcr__Site__c = site.Id;
        worker.enrtcr__User__c = u.Id;
        insert worker;

        Test.startTest();
            Map<String, Object> res = BR_MCCController.getClinicianAndEventsBySiteAndDiscipline('2022-09-20T00:00:00+00:00', site.Name, 'Occupational Therapist');
        Test.stopTest();

        System.assertEquals(true, res.containsKey('clinicians'));
        System.assertEquals(true, res.containsKey('events'));
        System.assertEquals(true, res.containsKey('loggedInUser'));
    }

    static testMethod void getClinicianAndEventsByMultiLookupTest() {
        // create test site
        enrtcr__Site__c site = TestObjects.createSite(2);
        insert site;

        // pull a random user
        Id userId = UserInfo.getUserId();
        User u = [SELECT Id FROM User WHERE id =: userId];

        // create a worker
        Contact worker = TestObjects.createContact(6, 'NDIS');
        worker.enrtcr__Site__c = site.Id;
        worker.enrtcr__User__c = u.Id;
        insert worker;

        Test.startTest();
            Map<String, Object> res = BR_MCCController.getClinicianAndEventsByMultiLookup('2022-09-20T00:00:00+00:00', JSON.serialize(new List<Contact>{worker}));
        Test.stopTest();

        System.assertEquals(true, res.containsKey('clinicians'));
        System.assertEquals(true, res.containsKey('events'));
        System.assertEquals(true, res.containsKey('loggedInUser'));
    }

    static testMethod void getContactWithMultipleFilterTest() {
        // create test site
        enrtcr__Site__c site = TestObjects.createSite(2);
        insert site;

        // pull a random user
        Id userId = UserInfo.getUserId();
        User u = [SELECT Id FROM User WHERE id =: userId];

        // create a worker
        Contact worker = TestObjects.createContact(6, 'NDIS');
        worker.enrtcr__Site__c = site.Id;
        worker.enrtcr__User__c = u.Id;
        insert worker;

        Test.startTest();
            Map<String, Object> res = BR_MCCController.getContactWithMultipleFilter('2022-09-20T00:00:00+00:00', site.Name, 'Occupational Therapist', JSON.serialize(new List<Contact>{worker}));
            Map<String, Object> res1 = BR_MCCController.getContactWithMultipleFilter('2022-09-20T00:00:00+00:00', '', 'Occupational Therapist', JSON.serialize(new List<Contact>{worker}));
            Map<String, Object> res2 = BR_MCCController.getContactWithMultipleFilter('2022-09-20T00:00:00+00:00', site.Name, '', JSON.serialize(new List<Contact>{worker}));
        Test.stopTest();

        System.assertEquals(true, res.containsKey('clinicians'));
        System.assertEquals(true, res.containsKey('events'));
        System.assertEquals(true, res.containsKey('loggedInUser'));

        System.assertEquals(true, res1.containsKey('clinicians'));
        System.assertEquals(true, res1.containsKey('events'));
        System.assertEquals(true, res1.containsKey('loggedInUser'));

        System.assertEquals(true, res2.containsKey('clinicians'));
        System.assertEquals(true, res2.containsKey('events'));
        System.assertEquals(true, res2.containsKey('loggedInUser'));
    }

    static testMethod void formatResponseTest() {
        // create test site
        enrtcr__Site__c site = TestObjects.createSite(2);
        insert site;

        // pull a random user
        Id userId = UserInfo.getUserId();
        User u = [SELECT Id FROM User WHERE id =: userId];

        // create a worker
        Contact worker = TestObjects.createContact(6, 'NDIS');
        worker.enrtcr__Site__c = site.Id;
        worker.enrtcr__User__c = u.Id;
        insert worker;

        // create events
        List<Event> events = new List<Event>();

        for (Integer i = 0 ; i < 5; i++) {
            Event e = TestObjects.createEvent('Initial Appointment', 'Pending', u);
            e.Subject = String.valueOf(i) + ' Event';
            events.add(e);
        }

        insert events;

        // create event relations
        List<EventRelation> ers = new List<EventRelation>();

        for (Integer i = 0; i < 5; i++) {
            EventRelation er = TestObjects.createER(worker, events[i]);
            ers.add(er);
        }

        insert ers;

        Test.startTest();
            Map<String, Object> res = BR_MCCController.formatResponse(new List<Contact>{worker}, '2022-09-20T00:00:00+00:00');
        Test.stopTest();

        System.assertEquals(true, res.containsKey('clinicians'));
        System.assertEquals(true, res.containsKey('events'));
        System.assertEquals(3, res.size());
        System.assertEquals(true, res.containsKey('loggedInUser'));
    }

    static testMethod void formatResponseNoCliniciansTest() {
        // create test site
        enrtcr__Site__c site = TestObjects.createSite(2);
        insert site;

        // pull a random user
        Id userId = UserInfo.getUserId();
        User u = [SELECT Id FROM User WHERE id =: userId];

        // create a contact
        Contact contact = TestObjects.createContact(6, 'NDIS');
        contact.enrtcr__Site__c = site.Id;
        contact.enrtcr__User__c = u.Id;
        insert contact;

        Test.startTest();
            Map<String, Object> res = BR_MCCController.formatResponse(new List<Contact>(), '2022-09-20T00:00:00+00:00');
        Test.stopTest();

        System.assertEquals('()', res.get('clinicians').toString());
        System.assertEquals('()', res.get('events').toString());
        System.assertEquals(true, res.containsKey('loggedInUser'));
    }

    static testMethod void formatResponseNoEventsTest() {
        // create test site
        enrtcr__Site__c site = TestObjects.createSite(2);
        insert site;

        // pull a random user
        Id userId = UserInfo.getUserId();
        User u = [SELECT Id FROM User WHERE id =: userId];

        // create a worker
        Contact worker = TestObjects.createContact(6, 'NDIS');
        worker.enrtcr__Site__c = site.Id;
        worker.enrtcr__User__c = u.Id;
        insert worker;

        Test.startTest();
            Map<String, Object> res = BR_MCCController.formatResponse(new List<Contact>{worker}, '2022-09-20T00:00:00+00:00');
        Test.stopTest();

        System.assertEquals(true, res.containsKey('clinicians'));
        System.assertEquals('()', res.get('events').toString());
        System.assertEquals(true, res.containsKey('loggedInUser'));
    }

    static testMethod void getWorkerEventsByDate() {
        // create test site
        enrtcr__Site__c site = TestObjects.createSite(2);
        insert site;

        // pull a random user
        Id userId = UserInfo.getUserId();
        User u = [SELECT Id FROM User WHERE id =: userId];

        // create a worker
        Contact worker = TestObjects.createContact(6, 'NDIS');
        worker.enrtcr__Site__c = site.Id;
        worker.enrtcr__User__c = u.Id;
        insert worker;

        // create events
        List<Event> events = new List<Event>();

        for (Integer i = 0 ; i < 5; i++) {
            Event e = TestObjects.createEvent('Initial Appointment', 'Pending', u);
            e.Subject = String.valueOf(i) + ' Event';
            events.add(e);
        }

        insert events;

        // create event relations
        List<EventRelation> ers = new List<EventRelation>();

        for (Integer i = 0; i < 5; i++) {
            EventRelation er = TestObjects.createER(worker, events[i]);
            ers.add(er);
        }

        insert ers;

        String startDate = '2022-08-05T00:00:00+0800';
        String endDate = '2022-08-05T00:00:00+0800';

        Test.startTest();
            Map<String, Object> res = BR_MCCController.getEventsByDate(startDate, endDate, new List<String>{worker.Id});
        Test.stopTest();

        System.assertEquals(true, res.containsKey('events'));
    }
}