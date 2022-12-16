@isTest
private class CalendarControllerTest {
    @testSetup
    //create all the test data
    static void setup(){

        //create the setting record
        Setting__c s = new Setting__c();
        s.Name = 'eventCutoffDate';
        s.Settings__c = '{"Better Calendar":"120","MCC":"20"}';
        insert s;

        //create the contacts to share events
        Contact contactsToShare = new Contact();
        contactsToShare.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Employee').getRecordTypeId();
        contactsToShare.Email = 'testWorker@betterrehab.com.au';
        contactsToShare.FirstName = 'Contact';
        contactsToShare.LastName = 'to share events';
        insert contactsToShare;

    }

    /*
     *
     * THIS SECTION IS FOR BR CALENDAR CMP
     *
     */

    static testMethod void testWorkerEvents() {
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
        List<Map<String,Object>> res = CalendarController.getEvents(worker.Id);
        Test.stopTest();

        System.assertEquals(5, res.size());
    }

    static testMethod void testClientEvents() {
        // create test site
        enrtcr__Site__c site = TestObjects.createSite(2);
        insert site;

        // pull a random user
        Id userId = UserInfo.getUserId();
        User u = [SELECT Id FROM User WHERE id =: userId];

        // create a worker 1
        Contact worker = TestObjects.createContact(6, 'NDIS');
        worker.enrtcr__Site__c = site.Id;
        worker.enrtcr__User__c = u.Id;
        insert worker;

        // create 3 clients
        List<Contact> clients = new List<Contact>();

        for (Integer i = 0 ; i < 3 ; i++) {
            Contact client = TestObjects.createContact(1, 'NDIS');
            client.LastName = 'Client ' + String.valueOf(i);
            client.enrtcr__NDIS_ID__c = '12345678';
            client.MMM_Score__c = '0';
            clients.add(client);
        }

        insert clients;

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

        // create client event relations
        List<Client_Event_Relation__c> cers = new List<Client_Event_Relation__c>();

        cers.add(TestObjects.createCER('Pending', clients[0], events[0]));
        cers.add(TestObjects.createCER('Pending', clients[1], events[0]));
        cers.add(TestObjects.createCER('Pending', clients[2], events[0]));
        cers.add(TestObjects.createCER('Pending', clients[1], events[1]));
        cers.add(TestObjects.createCER('Pending', clients[2], events[2]));

        insert cers;

        Test.startTest();
        List<Map<String,Object>> res = CalendarController.getEvents(clients[1].Id);
        Test.stopTest();

        System.assertEquals(2, res.size());
    }

    static testMethod void testUpdateEventTimeSaveOne() {
        // create test site
        enrtcr__Site__c site = TestObjects.createSite(2);
        insert site;

        // pull a random user
        Id userId = UserInfo.getUserId();
        User u = [SELECT Id FROM User WHERE id =: userId];

        // create events
        Event e = TestObjects.createEvent('Internal', 'Pending', u);
        e.Subject = 'My Event';

        insert e;

        Map<String, Object> eventJSON = new Map<String, Object>();

        eventJSON.put('eventId', e.Id);
        eventJSON.put('startTime', '2022-01-25T12:30:00+11:00');
        eventJSON.put('endTime', '2022-01-25T12:45:00+11:00');

        String eventString = JSON.serialize(eventJSON);

        Test.startTest();
        List<Map<String, String>> res = CalendarController.updateEventTime(eventString, 'saveOne');
        Test.stopTest();

        Event updatedEvent = [SELECT Id, StartDateTime, EndDateTime, Event_Status__c, OwnerId, Event_Type__c FROM Event WHERE Id =: e.Id];

        System.assertEquals(updatedEvent.EndDateTime.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''), res[0].get('EndDateTime'));
    }

    static testMethod void testUpdateEventTimeSaveAll(){
        //find existing cer and er AND update all recurring cer and ers to booked
        User x = [SELECT id FROM User WHERE IsActive = TRUE AND ProfileId =: [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1] limit 1];

        List<Contact> listOfContacts = new List<Contact>();

        //create site
        enrtcr__Site__c newSite = TestObjects.createSite(2);
        newSite.Office_Admin__c = x.Id;
        insert newSite;

        Contact newWorker = TestObjects.createContact(6, 'NDIS');
        newWorker.LastName = 'Worker';
        newWorker.FirstName = 'newW';
        newWorker.RecordTypeId = '0122v0000013OcoAAE';
        newWorker.enrtcr__Site__c = newSite.Id;
        newWorker.enrtcr__Gender_Detail__c = 'Male';
        newWorker.enrtcr__Client_Region__c = 'NSW';
        newWorker.enrtcr__Start_Date__c = System.today();
        newWorker.enrtcr__Status__c = 'Current';
        newWorker.enrtcr__Mobile__c = '04322355644';
        newWorker.Email = 'newWorker@betterrehab.com.au';
        newWorker.enrtcr__User__c = x.Id;
        listOfContacts.add(newWorker);

        //create the contacts to share events
        Contact contactsToShare = new Contact();
        contactsToShare.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Employee').getRecordTypeId();
        contactsToShare.Email = 'testWorker@betterrehab.com.au';
        contactsToShare.FirstName = 'Contact';
        contactsToShare.LastName = 'to share events';
        listOfContacts.add(contactsToShare);

        //create 3 clients
        Contact newClient = TestObjects.createContact(1, 'NDIS');
        newClient.LastName = 'Client';
        listOfContacts.add(newClient);

        insert listOfContacts;

        Contact client = [SELECT Id FROM Contact WHERE LastName = 'Client'];
        Contact worker = [SELECT Id FROM Contact WHERE LastName = 'Worker'];

        //create recurring events
        List<Client_Event_Relation__c> cers = new List<Client_Event_Relation__c>();
        List<EventRelation> ers = new List<EventRelation>();

        List<Event> recurringEvents  = TestObjects.createEventRecur('Therapy Session', 'Pending', x);
        for(Event ev : recurringEvents){
            ev.Number_of_Clients__c = 1;
            ev.Number_of_Workers__c = 1;
        }

        insert recurringEvents;

        for(Event e : recurringEvents){
            Client_Event_Relation__c c = TestObjects.createCER('Pending', client, e);
            EventRelation er = TestObjects.createER(worker, e);

            cers.add(c);
            ers.add(er);
        }

        insert cers;
        insert ers;

        Test.startTest();

        Event e = [SELECT Id, StartDateTime, EndDateTime, Event_Status__c, OwnerId, Event_Type__c FROM Event WHERE isRecurrence__c = TRUE LIMIT 1];
        Client_Event_Relation__c cer = [SELECT Id FROM Client_Event_Relation__c WHERE Event_Id__c =: e.Id];
        EventRelation er = [SELECT Id FROM EventRelation WHERE EventId =: e.Id];

        Map<String, Object> eventJSON = new Map<String, Object>();

        eventJSON.put('eventId', e.Id);
        eventJSON.put('startTime', '2022-01-25T12:30:00+11:00');
        eventJSON.put('endTime', '2022-01-25T12:45:00+11:00');

        String eventString = JSON.serialize(eventJSON);

        //test changing the time for all recurring events
        List<Map<String, String>> res = CalendarController.updateEventTime(eventString, 'saveAll');

        Test.stopTest();

        System.debug('result of handle update all: ' + res);

        Event updatedEvent = [SELECT Id, StartDateTime, EndDateTime, Event_Status__c, OwnerId, Event_Type__c FROM Event WHERE Id =: e.Id];

        System.assertEquals(updatedEvent.EndDateTime.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''), res[0].get('EndDateTime'));
    }

    static testMethod void testGetWorker() {

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
        Map<String, String> loggedInUser = CalendarController.getWorker(worker.Id);
        Test.stopTest();

        System.assertEquals(u.Id, loggedInUser.get('userId'));
        System.assertEquals(worker.Id, loggedInUser.get('id'));

    }

    /*
     *
     * THIS SECTION IS FOR BR CALENDAR CREATE CMP
     *
     */

    static testMethod void testCreateEventSingle() {
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

        List<Map<String, String>> workers = new List<Map<String, String>>();
        workers.add(new Map<String, String>{'Id' => worker.Id, 'Name' => worker.Name});

        Map<String, String> siteMap = new Map<String, String>();
        siteMap.put('Id', site.Id);
        siteMap.put('Name', site.Name);

        Map<String, Object> eventJSON = new Map<String, Object>();
        Map<String, Object> repeatJSON = new Map<String, Object>();

        Set<String> setDays = new Set<String>();

		eventJSON.put('subject', 'Test');
        eventJSON.put('startTime', '2022-01-25T12:30:00+11:00');
        eventJSON.put('endTime', '2022-01-25T12:45:00+11:00');
        eventJSON.put('eventType', 'Initial Appointment');
        eventJSON.put('clients', '[]');
        eventJSON.put('workers', JSON.serialize(workers));
        eventJSON.put('serviceId', 'filler');
        eventJSON.put('address', '123 Right Street');
        eventJSON.put('status', 'Pending');
        eventJSON.put('allDay', false);
        eventJSON.put('reengagement', false);
        eventJSON.put('site', JSON.serialize(siteMap));

        repeatJSON.put('numberEvents', null);
        repeatJSON.put('onAfter', 'After');
        repeatJSON.put('onDate', '2022-01-22');
        repeatJSON.put('repeat', false);
        repeatJSON.put('repeatTime', null);
        repeatJSON.put('repeatFrequency', null);
        repeatJSON.put('repeatDays', setDays);

        String eventString = JSON.serialize(eventJSON);
        String repeatString = JSON.serialize(repeatJSON);

        Test.startTest();
        List<Event> res = CalendarController.createEvents(eventString, repeatString, worker.Id);
        Test.stopTest();


        System.assertEquals(1, res.size());
        System.assertEquals('Test', res[0].Subject);

    }

    static testMethod void testCreateEventRecurrence() {
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

        List<Map<String, String>> workers = new List<Map<String, String>>();
        workers.add(new Map<String, String>{'Id' => worker.Id, 'Name' => worker.Name});

        Map<String, String> siteMap = new Map<String, String>();
        siteMap.put('Id', site.Id);
        siteMap.put('Name', site.Name);

        Map<String, Object> eventJSON = new Map<String, Object>();
        Map<String, Object> repeatJSON = new Map<String, Object>();
        Set<String> setDays = new Set<String>();

		eventJSON.put('subject', 'Test');
        eventJSON.put('startTime', '2022-01-25T12:30:00+11:00');
        eventJSON.put('endTime', '2022-01-25T12:45:00+11:00');
        eventJSON.put('eventType', 'Initial Appointment');
        eventJSON.put('clients', '[]');
        eventJSON.put('workers', JSON.serialize(workers));
        eventJSON.put('serviceId', 'filler');
        eventJSON.put('address', '123 Right Street');
        eventJSON.put('status', 'Booked');
        eventJSON.put('allDay', false);
        eventJSON.put('reengagement', false);
        eventJSON.put('site', JSON.serialize(siteMap));

        repeatJSON.put('numberEvents', 2);
        repeatJSON.put('onAfter', 'After');
        repeatJSON.put('onDate', '2022-01-22');
        repeatJSON.put('repeat', true);
        repeatJSON.put('repeatTime', 'Day');
        repeatJSON.put('repeatFrequency', 1);
        repeatJSON.put('repeatDays', setDays);

        String eventString = JSON.serialize(eventJSON);
        String repeatString = JSON.serialize(repeatJSON);

        Test.startTest();
        List<Event> res = CalendarController.createEvents(eventString, repeatString, worker.Id);
        Test.stopTest();


        System.assertEquals(2, res.size());
        System.assertEquals('Test', res[0].Subject);

    }

    static testMethod void testCreateEventRecurrenceAllDay() {
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

        List<Map<String, String>> workers = new List<Map<String, String>>();
        workers.add(new Map<String, String>{'Id' => worker.Id, 'Name' => worker.Name});

        Map<String, String> siteMap = new Map<String, String>();
        siteMap.put('Id', site.Id);
        siteMap.put('Name', site.Name);

        Map<String, Object> eventJSON = new Map<String, Object>();
        Map<String, Object> repeatJSON = new Map<String, Object>();
        Set<String> setDays = new Set<String>();

		eventJSON.put('subject', 'Test AD');
        eventJSON.put('startTime', '2022-01-25');
        eventJSON.put('endTime', '2022-01-25');
        eventJSON.put('eventType', 'Out of Office');
        eventJSON.put('clients', '[]');
        eventJSON.put('workers', JSON.serialize(workers));
        eventJSON.put('serviceId', 'filler');
        eventJSON.put('address', '123 Right Street');
        eventJSON.put('status', 'Booked');
        eventJSON.put('allDay', true);
        eventJSON.put('reengagement', false);
        eventJSON.put('site', JSON.serialize(siteMap));

        repeatJSON.put('numberEvents', 2);
        repeatJSON.put('onAfter', 'On');
        repeatJSON.put('onDate', '2022-01-30');
        repeatJSON.put('repeat', true);
        repeatJSON.put('repeatTime', 'Day');
        repeatJSON.put('repeatFrequency', 1);
        repeatJSON.put('repeatDays', setDays);

        String eventString = JSON.serialize(eventJSON);
        String repeatString = JSON.serialize(repeatJSON);

        Test.startTest();
        List<Event> res = CalendarController.createEvents(eventString, repeatString, worker.Id);
        Test.stopTest();


        System.assertEquals(6, res.size());

    }

    static testMethod void testClientWorkerClash(){

        //create 1 event
        User x = [SELECT id FROM User WHERE IsActive = TRUE AND ProfileId =: [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1] limit 1];

        //create site
        enrtcr__Site__c newSite = TestObjects.createSite(2);
        newSite.Office_Admin__c = x.Id;
        insert newSite;

        List<Contact> listOfContacts = new List<Contact>();

        Contact newWorker = TestObjects.createContact(6, 'NDIS');
        newWorker.enrtcr__User__c = x.Id;
        listOfContacts.add(newWorker);

        //create 1 client
        Contact newClient = TestObjects.createContact(1, 'NDIS');
        listOfContacts.add(newClient);

        insert listOfContacts;

        String clashingStart = '2022-01-25 12:30:00';
        String clashingEnd = '2022-01-25 12:45:00';

        //create 1 event with 1 client and 1 worker
        Event newEvent = TestObjects.createEvent('Initial Appointment', 'Pending', x);
        newEvent.StartDateTime = Datetime.valueOf(clashingStart);
        newEvent.EndDateTime = Datetime.valueOf(clashingEnd);
        insert newEvent;

        Client_Event_Relation__c newCER = TestObjects.createCER('Pending', newClient, newEvent);
        insert newCER;

        EventRelation newER = TestObjects.createER(newWorker, newEvent);
		insert newER;

        Test.startTest();

        Contact worker = [SELECT Id, Name FROM Contact WHERE LastName = 'Worker'];
        Contact client = [SELECT Id, Name FROM Contact WHERE LastName = 'Client'];

        //prep the String JSON
        List<Map<String, String>> workers = new List<Map<String, String>>();
        workers.add(new Map<String, String>{'Id' => worker.Id, 'Name' => worker.Name});

        List<Map<String, String>> clients = new List<Map<String, String>>();
        clients.add(new Map<String, String>{'Id' => client.Id, 'Name' => client.Name});

        Map<String, Object> eventJSON = new Map<String, Object>();
        Map<String, Object> repeatJSON = new Map<String, Object>();

		eventJSON.put('subject', 'Test');
        eventJSON.put('startTime', '2022-01-25T12:30:00+11:00');
        eventJSON.put('endTime', '2022-01-25T12:45:00+11:00');
        eventJSON.put('eventType', 'Initial Appointment');
        eventJSON.put('clients', JSON.serialize(clients));
        eventJSON.put('workers', JSON.serialize(workers));
        eventJSON.put('serviceId', 'filler');
        eventJSON.put('address', '123 Right Street');
        eventJSON.put('status', 'Pending');
        eventJSON.put('allDay', false);
        eventJSON.put('reengagement', false);

        String eventString = JSON.serialize(eventJSON);

        String[] clashes = CalendarController.findClashingWorkerAndClientEvents(eventString);
        Test.stopTest();

        System.assertEquals(2, clashes.size());
    }

    static testMethod void testClashAllDay(){
        //create 1 event
        User x = [SELECT id FROM User WHERE IsActive = TRUE AND ProfileId =: [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1] limit 1];

        //create site
        enrtcr__Site__c newSite = TestObjects.createSite(2);
        newSite.Office_Admin__c = x.Id;
        insert newSite;

        List<Contact> listOfContacts = new List<Contact>();

        Contact newWorker = TestObjects.createContact(6, 'NDIS');
        newWorker.enrtcr__User__c = x.Id;
        listOfContacts.add(newWorker);

        //create 1 client
        Contact newClient = TestObjects.createContact(1, 'NDIS');
        listOfContacts.add(newClient);

        insert listOfContacts;

        String clashingStart = '2022-01-25 12:30:00';
        String clashingEnd = '2022-01-25 12:45:00';

        //create 1 event with 1 client and 1 worker
        Event newEvent = TestObjects.createEvent('Initial Appointment', 'Pending', x);
        newEvent.StartDateTime = Datetime.valueOf(clashingStart);
        newEvent.EndDateTime = Datetime.valueOf(clashingEnd);
        insert newEvent;

        Client_Event_Relation__c newCER = TestObjects.createCER('Pending', newClient, newEvent);
        insert newCER;

        EventRelation newER = TestObjects.createER(newWorker, newEvent);
		insert newER;


        Test.startTest();

        Contact worker = [SELECT Id, Name FROM Contact WHERE LastName = 'Worker'];

        //prep the String JSON
        List<Map<String, String>> workers = new List<Map<String, String>>();
        workers.add(new Map<String, String>{'Id' => worker.Id, 'Name' => worker.Name});

        Map<String, Object> eventJSON = new Map<String, Object>();

		eventJSON.put('subject', 'Test AD');
        eventJSON.put('startTime', '2022-01-25');
        eventJSON.put('endTime', '2022-01-25');
        eventJSON.put('eventType', 'Out of Office');
        eventJSON.put('clients', '[]');
        eventJSON.put('workers', JSON.serialize(workers));
        eventJSON.put('serviceId', 'filler');
        eventJSON.put('address', '123 Right Street');
        eventJSON.put('status', 'Booked');
        eventJSON.put('allDay', true);
        eventJSON.put('reengagement', false);

        String eventString = JSON.serialize(eventJSON);

        String[] clashes = CalendarController.findClashingWorkerAndClientEvents(eventString);
        Test.stopTest();

        System.assertEquals(1, clashes.size());
    }

    /*
     *
     * THIS SECTION IS FOR BR EVENT DETAIL CMP
     *
     * */

    static testMethod void testDeleteEvent() {
        // create test site
        enrtcr__Site__c site = TestObjects.createSite(2);
        insert site;

        // pull a random user
        Id userId = UserInfo.getUserId();
        User u = [SELECT Id FROM User WHERE id =: userId];

        // create events
        Event e = TestObjects.createEvent('Internal', 'Pending', u);
        e.Subject = 'My Event';

        insert e;

        // create events
        Event ev= TestObjects.createEvent('Initial Appointment', 'Booked', u);
        ev.Subject = 'My Event 1';

        insert ev;

        // create a worker
        Contact worker = TestObjects.createContact(6, 'NDIS');
        worker.enrtcr__Site__c = site.Id;
        worker.enrtcr__User__c = u.Id;
        insert worker;

        EventRelation er = TestObjects.createER(worker, e);
        er.Status = 'New';
        insert er;

        EventRelation er1 = TestObjects.createER(worker, ev);
        er1.Status = 'Accepted';
        insert er1;

        Contact client = TestObjects.createContact(1, 'NDIS');
        client.enrtcr__NDIS_ID__c = '12345678';
        client.MMM_Score__c = '0';

        insert client;

        Client_Event_Relation__c cer = TestObjects.createCER('Pending', client, e);

        insert cer;

        Client_Event_Relation__c cer1 = TestObjects.createCER('Booked', client, ev);

        insert cer1;

        Test.startTest();
        String res = CalendarController.deleteAnEvent(e.Id, 'ww');
        String res1 = CalendarController.deleteAnEvent(ev.Id, 'ww');
        Test.stopTest();

        System.assertEquals('DELETED', res);
        System.assertEquals('CANCELLED', res1);

    }

    static testMethod void testBookEvent() {
        // create test site
        enrtcr__Site__c site = TestObjects.createSite(2);
        insert site;

        // pull a random user
        Id userId = UserInfo.getUserId();
        User u = [SELECT Id FROM User WHERE id =: userId];

        // create events
        Event e = TestObjects.createEvent('Internal', 'Pending', u);
        e.Subject = 'My Event';

        insert e;


        // create a worker
        Contact worker = TestObjects.createContact(6, 'NDIS');
        worker.enrtcr__Site__c = site.Id;
        worker.enrtcr__User__c = u.Id;
        insert worker;

        EventRelation er = TestObjects.createER(worker, e);
        er.Status = 'New';
        insert er;

        Contact client = TestObjects.createContact(1, 'NDIS');
        client.enrtcr__NDIS_ID__c = '12345678';
        client.MMM_Score__c = '0';

        insert client;

        Client_Event_Relation__c cer = TestObjects.createCER('Pending', client, e);

        insert cer;

        Test.startTest();
        String res = CalendarController.bookAnEvent(e.Id);
        Test.stopTest();

        System.assertEquals('BOOKED', res);

    }

    static testMethod void testDeleteRecurrenceNonSpecial() {
        // create test site
        enrtcr__Site__c site = TestObjects.createSite(2);
        insert site;

        // pull a random user
        Id userId = UserInfo.getUserId();
        User u = [SELECT Id FROM User WHERE id =: userId];

        // create events
        List<Event> events = TestObjects.createEventRecur('Internal', 'Pending', u);

        insert events;


        // create a worker
        Contact worker = TestObjects.createContact(6, 'NDIS');
        worker.enrtcr__Site__c = site.Id;
        worker.enrtcr__User__c = u.Id;
        insert worker;

        List<EventRelation> ers = new List<EventRelation>();
        for (Event e : events) {
            EventRelation er = TestObjects.createER(worker, e);
            er.Status = 'New';
            ers.add(er);
        }

        insert ers;


        Test.startTest();
        Map<String, String> res = CalendarController.deleteARecurrence(events[0].Id, 'Nothing');
        Test.stopTest();

        System.assertEquals(2, res.size());
        System.assertEquals('DELETED', res.get(events[0].Id));
        System.assertEquals('DELETED', res.get(events[1].Id));

    }

    static testMethod void testDeleteRecurrenceSpecial() {
        // create test site
        enrtcr__Site__c site = TestObjects.createSite(2);
        insert site;

        // pull a random user
        Id userId = UserInfo.getUserId();
        User u = [SELECT Id FROM User WHERE id =: userId];

        // create events
        List<Event> events = TestObjects.createEventRecur('Initial Appointment', 'Booked', u);

        insert events;


        // create a worker
        Contact worker = TestObjects.createContact(6, 'NDIS');
        worker.enrtcr__Site__c = site.Id;
        worker.enrtcr__User__c = u.Id;
        insert worker;

        List<EventRelation> ers = new List<EventRelation>();
        for (Event e : events) {
            EventRelation er = TestObjects.createER(worker, e);
            er.Status = 'Accepted';
            ers.add(er);
        }

        insert ers;


        Test.startTest();
        Map<String, String> res = CalendarController.deleteARecurrence(events[0].Id, 'Nothing');
        Test.stopTest();

        System.assertEquals(2, res.size());
        System.assertEquals('CANCELLED', res.get(events[0].Id));
        System.assertEquals('CANCELLED', res.get(events[1].Id));

    }

    static testMethod void testBookRecurrenceNonSpecial() {
        // create test site
        enrtcr__Site__c site = TestObjects.createSite(2);
        insert site;

        // pull a random user
        Id userId = UserInfo.getUserId();
        User u = [SELECT Id FROM User WHERE id =: userId];

        // create events
        List<Event> events = TestObjects.createEventRecur('Internal', 'Pending', u);

        insert events;


        // create a worker
        Contact worker = TestObjects.createContact(6, 'NDIS');
        worker.enrtcr__Site__c = site.Id;
        worker.enrtcr__User__c = u.Id;
        insert worker;

        List<EventRelation> ers = new List<EventRelation>();
        for (Event e : events) {
            EventRelation er = TestObjects.createER(worker, e);
            er.Status = 'New';
            ers.add(er);
        }

        insert ers;


        Test.startTest();
        Map<String, String> res = CalendarController.bookARecurrence(events[0].Id);
        Test.stopTest();

        System.assertEquals(2, res.size());
        System.assertEquals('BOOKED', res.get(events[0].Id));
        System.assertEquals('BOOKED', res.get(events[1].Id));

    }

    static testMethod void testGetRelationship(){
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

        Contact worker1 = TestObjects.createContact(6, 'NDIS');
        worker1.enrtcr__Site__c = site.Id;
        worker1.FirstName = 'Contact';
        worker1.LastName = 'to share events';
        worker1.enrtcr__User__c = u.Id;
        insert worker1;

        //create an event
        Event e = TestObjects.createEvent('Initial Appointment', 'Pending', u);
        insert e;
        EventRelation er = TestObjects.createER(worker, e);
        insert er;

        Test.startTest();

        String rel = CalendarController.getEventRelationship(e.Id);

        Test.stopTest();

        System.assertEquals('owner', rel);
    }

    static testMethod void testUpdateEditFormSaveOne(){
        User x = [SELECT id FROM User WHERE IsActive = TRUE AND ProfileId =: [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1] limit 1];
        List<Contact> listOfContacts = new List<Contact>();

        //create site
        enrtcr__Site__c newSite = TestObjects.createSite(2);
        newSite.Office_Admin__c = x.Id;
        insert newSite;

        Contact newWorker = TestObjects.createContact(6, 'NDIS');
        newWorker.LastName = 'Worker';
        newWorker.FirstName = 'newW';
        newWorker.RecordTypeId = '0122v0000013OcoAAE';
        newWorker.enrtcr__Site__c = newSite.Id;
        newWorker.enrtcr__Gender_Detail__c = 'Male';
        newWorker.enrtcr__Client_Region__c = 'NSW';
        newWorker.enrtcr__Start_Date__c = System.today();
        newWorker.enrtcr__Status__c = 'Current';
        newWorker.enrtcr__Mobile__c = '04322355644';
        newWorker.Email = 'newWorker@betterrehab.com.au';
        newWorker.enrtcr__User__c = x.Id;
        listOfContacts.add(newWorker);

        //create the contacts to share events
        Contact contactsToShare = new Contact();
        contactsToShare.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Employee').getRecordTypeId();
        contactsToShare.Email = 'testWorker@betterrehab.com.au';
        contactsToShare.FirstName = 'Contact';
        contactsToShare.LastName = 'to share events';
        listOfContacts.add(contactsToShare);

        //create 3 clients
        Contact newClient = TestObjects.createContact(1, 'NDIS');
        newClient.LastName = 'Client';
        listOfContacts.add(newClient);

        insert listOfContacts;

        // create events
        Event e = TestObjects.createEvent('Internal', 'Pending', x);
        e.Subject = 'My Event';

        insert e;

        Contact client = [SELECT Id, Name FROM Contact WHERE LastName = 'Client'];
        Contact worker = [SELECT Id, Name FROM Contact WHERE LastName = 'Worker'];
        Event insertedEvent = [SELECT Id, Subject, OwnerId FROM Event];

        //prep the String JSON
        List<Map<String, String>> workers = new List<Map<String, String>>();
        workers.add(new Map<String, String>{'Id' => worker.Id, 'Name' => worker.Name});

        List<Map<String, String>> clients = new List<Map<String, String>>();
        clients.add(new Map<String, String>{'Id' => client.Id, 'Name' => client.Name});

        Map<String, Object> eventJSON = new Map<String, Object>();

        eventJSON.put('eventId', insertedEvent.Id);
		eventJSON.put('subject', 'Test Test');
        eventJSON.put('startTime', '2022-01-25T12:30:00+11:00');
        eventJSON.put('endTime', '2022-01-25T12:45:00+11:00');
        eventJSON.put('eventType', 'Initial Appointment');
        eventJSON.put('address', '123 Right Street');
        eventJSON.put('status', 'Booked');
        eventJSON.put('owner', insertedEvent.OwnerId);

        String eventString = JSON.serialize(eventJSON);

        Test.startTest();

        List<Map<String, String>> updateEventResult = CalendarController.updateEventEditForm(eventString, 'saveOne');

        Test.stopTest();

        Event updatedEvent = [SELECT Id, Subject, OwnerId FROM Event];

        System.assertEquals(updatedEvent.Subject, updateEventResult[0].get('Subject'));
    }

    static testMethod void testUpdateEditFormSaveAll(){
        User x = [SELECT id FROM User WHERE IsActive = TRUE AND ProfileId =: [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1] limit 1];
        List<Contact> listOfContacts = new List<Contact>();

        //create site
        enrtcr__Site__c newSite = TestObjects.createSite(2);
        newSite.Office_Admin__c = x.Id;
        insert newSite;

        Contact newWorker = TestObjects.createContact(6, 'NDIS');
        newWorker.LastName = 'Worker';
        newWorker.FirstName = 'newW';
        newWorker.RecordTypeId = '0122v0000013OcoAAE';
        newWorker.enrtcr__Site__c = newSite.Id;
        newWorker.enrtcr__Gender_Detail__c = 'Male';
        newWorker.enrtcr__Client_Region__c = 'NSW';
        newWorker.enrtcr__Start_Date__c = System.today();
        newWorker.enrtcr__Status__c = 'Current';
        newWorker.enrtcr__Mobile__c = '04322355644';
        newWorker.Email = 'newWorker@betterrehab.com.au';
        newWorker.enrtcr__User__c = x.Id;
        listOfContacts.add(newWorker);

        //create the contacts to share events
        Contact contactsToShare = new Contact();
        contactsToShare.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Employee').getRecordTypeId();
        contactsToShare.Email = 'testWorker@betterrehab.com.au';
        contactsToShare.FirstName = 'Contact';
        contactsToShare.LastName = 'to share events';
        listOfContacts.add(contactsToShare);

        //create 3 clients
        Contact newClient = TestObjects.createContact(1, 'NDIS');
        newClient.LastName = 'Client';
        listOfContacts.add(newClient);

        insert listOfContacts;

        Contact client = [SELECT Id, Name FROM Contact WHERE LastName = 'Client'];
        Contact worker = [SELECT Id, Name FROM Contact WHERE LastName = 'Worker'];

        //create recurring events
        List<Client_Event_Relation__c> cers = new List<Client_Event_Relation__c>();
        List<EventRelation> ers = new List<EventRelation>();

        List<Event> recurringEvents  = TestObjects.createEventRecur('Therapy Session', 'Pending', x);
        for(Event ev : recurringEvents){
            ev.Number_of_Clients__c = 1;
            ev.Number_of_Workers__c = 1;
        }

        insert recurringEvents;

        for(Event e : recurringEvents){
            Client_Event_Relation__c c = TestObjects.createCER('Pending', client, e);
            EventRelation er = TestObjects.createER(worker, e);

            cers.add(c);
            ers.add(er);
        }

        insert cers;
        insert ers;

        //prep the String JSON
        List<Map<String, String>> workers = new List<Map<String, String>>();
        workers.add(new Map<String, String>{'Id' => worker.Id, 'Name' => worker.Name});

        List<Map<String, String>> clients = new List<Map<String, String>>();
        clients.add(new Map<String, String>{'Id' => client.Id, 'Name' => client.Name});


        Test.startTest();

        Event insertedEvent = [SELECT Id, StartDateTime, EndDateTime, Event_Status__c, OwnerId, Event_Type__c FROM Event WHERE isRecurrence__c = TRUE LIMIT 1];
        Client_Event_Relation__c cer = [SELECT Id FROM Client_Event_Relation__c WHERE Event_Id__c =: insertedEvent.Id];
        EventRelation er = [SELECT Id FROM EventRelation WHERE EventId =: insertedEvent.Id];

        Map<String, Object> eventJSON = new Map<String, Object>();

        eventJSON.put('eventId', insertedEvent.Id);
		eventJSON.put('subject', 'Test Test');
        eventJSON.put('startTime', '2022-01-25T12:30:00+11:00');
        eventJSON.put('endTime', '2022-01-25T12:45:00+11:00');
        eventJSON.put('eventType', 'Initial Appointment');
        eventJSON.put('address', '123 Right Street');
        eventJSON.put('status', 'Booked');
        eventJSON.put('owner', insertedEvent.OwnerId);

        String eventString = JSON.serialize(eventJSON);

        List<Map<String, String>> updateEventResult = CalendarController.updateEventEditForm(eventString, 'saveAll');

        Test.stopTest();

        Event updatedEvent = [SELECT Id, Subject, OwnerId FROM Event WHERE isRecurrence__c = TRUE LIMIT 1];

        System.assertEquals(updatedEvent.Subject, updateEventResult[0].get('Subject'));
    }

    static testMethod void testEventMap(){
        // create events
        User x = [SELECT id FROM User WHERE IsActive = TRUE AND ProfileId =: [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1] limit 1];
        Event e = TestObjects.createEvent('Internal', 'Pending', x);
        e.Subject = 'My Event';

        insert e;

        Test.startTest();

        Map<String, Object> eventMapResult = CalendarController.getEventMap(e.Id);
        String result = CalendarController.getEventRelationship(e.Id);

        Test.stopTest();

        Event insertedEvent = [SELECT Id FROM Event];

        System.assertEquals(e.Id, eventMapResult.get('id'));
        System.assertEquals('editors', result);
    }


    /*
     *
     * THIS SECTION IS FOR TABLE PAGINATION, WORKER EVENT RELATIONS, AND CLIENT EVENT RELATIONS CMP
     *
     * */

    static testMethod void testGetCERsERs(){
        User x = [SELECT id FROM User WHERE IsActive = TRUE AND ProfileId =: [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1] limit 1];

        //create a single event
        Event e = TestObjects.createEvent('Initial Appointment', 'Pending', x);
        e.Number_of_Clients__c = 1;
        e.Number_of_Workers__c = 1;
        insert e;

        //create a client and worker;
        Contact worker = TestObjects.createContact(6, 'NDIS');
        Contact client = TestObjects.createContact(1, 'NDIS');

        //create the contacts to share events
        Contact contactsToShare = new Contact();
        contactsToShare.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Employee').getRecordTypeId();
        contactsToShare.Email = 'testWorker@betterrehab.com.au';
        contactsToShare.FirstName = 'Contact';
        contactsToShare.LastName = 'to share events';

        List<Contact> listOfContacts = new List<Contact>{worker, client, contactsToShare};
            insert listOfContacts;

        Client_Event_Relation__c newCER = TestObjects.createCER('Pending', client, e);
        insert newCER;

        EventRelation newER = TestObjects.createER(worker, e);
        insert newER;

        Test.startTest();

        Event insertedEvent = [SELECT Id, Event_Status__c, OwnerId, Event_Type__c FROM Event where isRecurrence__c = FALSE];

        List<Map<String, Object>> cerCreated = CalendarController.getCERs(insertedEvent.Id);
        List<Map<String, Object>> erCreated = CalendarController.getERs(insertedEvent.Id);

        Test.stopTest();

        System.assertEquals(newCER.Id, cerCreated[0].get('id'));
        System.assertEquals(newER.Id, erCreated[0].get('id'));
    }

    static testMethod void testCreateCERsERsSaveOne(){
       User x = [SELECT id FROM User WHERE IsActive = TRUE AND ProfileId =: [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1] limit 1];

       //create a single event
       Event e = TestObjects.createEvent('Initial Appointment', 'Pending', x);
       e.Number_of_Clients__c = 1;
       e.Number_of_Workers__c = 1;
       insert e;

       //create a client and worker;
       Contact worker = TestObjects.createContact(6, 'NDIS');
       Contact client = TestObjects.createContact(1, 'NDIS');
       List<Contact> listOfContacts = new List<Contact>{worker, client};
           insert listOfContacts;

       Test.startTest();

       Event insertedEvent = [SELECT Id, Event_Status__c, OwnerId, Event_Type__c FROM Event where isRecurrence__c = FALSE];
       Contact w = [SELECT Id FROM Contact WHERE LastName = 'Worker'];
       Contact c = [SELECT Id FROM Contact WHERE LastName = 'Client'];

       List<String> listOfWorkerIds = new List<String>{w.Id};

       List<String> listOfClientIds = new List<String>{c.Id};

       List<Map<String, Object>> cerCreated = CalendarController.createCERs(listOfClientIds, insertedEvent.Id, 'saveOne');
       List<Map<String, Object>> erCreated = CalendarController.createERs(listOfWorkerIds, insertedEvent.Id, 'saveOne');

       Test.stopTest();

       Event updatedEvent = [SELECT Id, Number_of_Workers__c, Number_of_Clients__c, Event_Status__c, OwnerId, Event_Type__c FROM Event WHERE Id =: e.Id];

       System.assertEquals(2, updatedEvent.Number_of_Clients__c);
       System.assertEquals(2, updatedEvent.Number_of_Workers__c);
   }

    static testMethod void testCreateCERsERsSaveAll(){
        User x = [SELECT id FROM User WHERE IsActive = TRUE AND ProfileId =: [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1] limit 1];
        List<Contact> listOfContacts = new List<Contact>();

        //create site
        enrtcr__Site__c newSite = TestObjects.createSite(2);
        newSite.Office_Admin__c = x.Id;
        insert newSite;

        Contact newWorker = TestObjects.createContact(6, 'NDIS');
        newWorker.enrtcr__User__c = x.Id;
        listOfContacts.add(newWorker);

        //create clients
        Contact newClient = TestObjects.createContact(1, 'NDIS');
        listOfContacts.add(newClient);

        insert listOfContacts;

        Contact client = [SELECT Id, Name FROM Contact WHERE LastName = 'Client'];
        Contact worker = [SELECT Id, Name FROM Contact WHERE LastName = 'Worker'];

        //create recurring events
        List<Client_Event_Relation__c> cers = new List<Client_Event_Relation__c>();
        List<EventRelation> ers = new List<EventRelation>();

        List<Event> recurringEvents  = TestObjects.createEventRecur('Therapy Session', 'Pending', x);
        for(Event ev : recurringEvents){
            ev.Number_of_Clients__c = 1;
            ev.Number_of_Workers__c = 1;
        }

        insert recurringEvents;

        Test.startTest();

        //add 1 worker to all the events in the recurrence
        Event e = [SELECT Id, Number_of_Workers__c, Event_Status__c, OwnerId, Event_Type__c FROM Event WHERE isRecurrence__c = TRUE LIMIT 1];
        System.debug('previous no of workers: ' + e.Number_of_Workers__c);

        Contact w = [SELECT Id FROM Contact WHERE LastName = 'Worker'];
        Contact c = [SELECT Id FROM Contact WHERE LastName = 'Client'];

        List<String> listOfWorkerIds = new List<String>();
        listOfWorkerIds.add(w.Id);

        List<String> listOfClientIds = new List<String>();
        listOfClientIds.add(c.Id);

        List<Map<String, Object>> cerCreated = CalendarController.createCERs(listOfClientIds, e.Id, 'saveAll');
        List<Map<String, Object>> erCreated = CalendarController.createERs(listOfWorkerIds, e.Id, 'saveAll');

        Test.stopTest();

        Event updatedEvent = [SELECT Id, Number_of_Workers__c, Number_of_Clients__c, Event_Status__c, OwnerId, Event_Type__c FROM Event WHERE Id =: e.Id];

        System.assertEquals(2, updatedEvent.Number_of_Clients__c);
        System.assertEquals(2, updatedEvent.Number_of_Workers__c);
    }


    static testMethod void testHandleUpdateCERsERsSaveOne(){

        User x = [SELECT id FROM User WHERE IsActive = TRUE AND ProfileId =: [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1] limit 1];

        //create a single event
        Event e = TestObjects.createEvent('Initial Appointment', 'Pending', x);
        e.Number_of_Clients__c = 1;
        e.Number_of_Workers__c = 1;
        insert e;

        //create a client and worker;
        Contact worker = TestObjects.createContact(6, 'NDIS');
        Contact client = TestObjects.createContact(1, 'NDIS');

        List<Contact> listOfContacts = new List<Contact>{worker, client};
            insert listOfContacts;

        //create a CER
        Client_Event_Relation__c newCER = TestObjects.createCER('Pending', client, e);
        insert newCER;

        //create an ER - no status here for now
        EventRelation newER = TestObjects.createER(worker, e);
        insert newER;

        Test.startTest();

        Event insertedEvent = [SELECT Id, Event_Status__c, OwnerId, Event_Type__c FROM Event WHERE isRecurrence__c = FALSE];
        Client_Event_Relation__c cer = [SELECT Id FROM Client_Event_Relation__c WHERE Event_Id__c =: insertedEvent.Id];
        EventRelation er = [SELECT Id FROM EventRelation WHERE EventId =: insertedEvent.Id];

        //run through all these to make sure code coverage
        //from pending to booked
        CalendarController.handleCERchange('update', cer.Id, 'Booked', 'saveOne');
        CalendarController.handleERchange('update', er.Id, 'Booked', 'saveOne');

        //from booked to cancelled
        CalendarController.handleCERchange('update', cer.Id, 'Cancelled', 'saveOne');
        CalendarController.handleERchange('update', er.Id, 'Cancelled', 'saveOne');

        //from cancelled to booked - backend code allows for changing from cancelled to booked
        CalendarController.handleCERchange('update', cer.Id, 'Booked', 'saveOne');
        CalendarController.handleERchange('update', er.Id, 'Booked', 'saveOne');

        Test.stopTest();

        Client_Event_Relation__c updatedCER = [SELECT Id, Status__c FROM Client_Event_Relation__c WHERE Event_Id__c =: e.Id];
        EventRelation updatedER = [SELECT Id, Status FROM EventRelation WHERE EventId =: e.Id];
        Event updatedEvent = [SELECT Id, Number_of_Workers__c, Number_of_Clients__c FROM Event WHERE Id =: e.Id];

        System.assertEquals('Booked', updatedCER.Status__c);
        System.assertEquals('Accepted', updatedER.Status);

        System.assertEquals(1, updatedEvent.Number_of_Clients__c);
        System.assertEquals(1, updatedEvent.Number_of_Workers__c);
    }

    static testMethod void testHandleUpdateCERsERsSaveAll(){
        User x = [SELECT id FROM User WHERE IsActive = TRUE AND ProfileId =: [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1] limit 1];
        List<Contact> listOfContacts = new List<Contact>();

        //create site
        enrtcr__Site__c newSite = TestObjects.createSite(2);
        newSite.Office_Admin__c = x.Id;
        insert newSite;

        Contact newWorker = TestObjects.createContact(6, 'NDIS');
        newWorker.enrtcr__User__c = x.Id;
        listOfContacts.add(newWorker);

        Contact newClient = TestObjects.createContact(1, 'NDIS');
        newClient.LastName = 'Client';
        listOfContacts.add(newClient);

        insert listOfContacts;

        Contact client = [SELECT Id, Name FROM Contact WHERE LastName = 'Client'];
        Contact worker = [SELECT Id, Name FROM Contact WHERE LastName = 'Worker'];

        //create recurring events
        List<Client_Event_Relation__c> cers = new List<Client_Event_Relation__c>();
        List<EventRelation> ers = new List<EventRelation>();

        List<Event> recurringEvents  = TestObjects.createEventRecur('Therapy Session', 'Pending', x);
        for(Event ev : recurringEvents){
            ev.Number_of_Clients__c = 1;
            ev.Number_of_Workers__c = 1;
        }

        insert recurringEvents;

        for(Event e : recurringEvents){
            Client_Event_Relation__c c = TestObjects.createCER('Pending', client, e);
            EventRelation er = TestObjects.createER(worker, e);

            cers.add(c);
            ers.add(er);
        }

        insert cers;
        insert ers;

        Test.startTest();

        //find existing cer and er AND update all recurring cer and ers to booked
        Event e = [SELECT Id, Event_Status__c, OwnerId, Event_Type__c FROM Event WHERE isRecurrence__c = TRUE LIMIT 1];
        Client_Event_Relation__c cer = [SELECT Id FROM Client_Event_Relation__c WHERE Event_Id__c =: e.Id];
        EventRelation er = [SELECT Id FROM EventRelation WHERE EventId =: e.Id];

        //run through all these to make sure code coverage
        //from pending to booked
        CalendarController.handleCERchange('update', cer.Id, 'Booked', 'saveAll');
        CalendarController.handleERchange('update', er.Id, 'Booked', 'saveAll');

        //from booked to cancelled
        CalendarController.handleCERchange('update', cer.Id, 'Cancelled', 'saveAll');
        CalendarController.handleERchange('update', er.Id, 'Cancelled', 'saveAll');

        //from cancelled to booked
        CalendarController.handleCERchange('update', cer.Id, 'Booked', 'saveAll');
        CalendarController.handleERchange('update', er.Id, 'Booked', 'saveAll');

        Test.stopTest();

        Client_Event_Relation__c updatedCER = [SELECT Id, Status__c FROM Client_Event_Relation__c WHERE Event_Id__c =: e.Id];
        EventRelation updatedER = [SELECT Id, Status FROM EventRelation WHERE EventId =: e.Id];
        Event updatedEvent = [SELECT Id, Number_of_Workers__c, Number_of_Clients__c FROM Event WHERE Id =: e.Id];

        System.assertEquals('Booked', updatedCER.Status__c);
        System.assertEquals('Accepted', updatedER.Status);
        System.assertEquals(1, updatedEvent.Number_of_Clients__c);
        System.assertEquals(1, updatedEvent.Number_of_Workers__c);
    }

    static testMethod void testPullSingleEvent() {
        // create test site
        enrtcr__Site__c site = TestObjects.createSite(2);
        insert site;

        // pull a random user
        Id userId = UserInfo.getUserId();
        User u = [SELECT Id FROM User WHERE id =: userId];

        // create events
        Event e = TestObjects.createEvent('Initial Appointment', 'Pending', u);
        e.Subject = 'My Event';

        insert e;

        Test.startTest();
        Event res = CalendarController.getEvent(e.Id);
        Test.stopTest();

        System.assertEquals(e.Subject, res.Subject);
    }

}