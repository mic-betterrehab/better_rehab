@isTest
public class AnalyticsControllerTest {
    
    @isTest static void testPullDataClinicalAudit(){
        User y = [SELECT Id FROM User WHERE IsActive = TRUE AND ProfileId =: [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1] LIMIT 1]; //find a sys admin user
        
        List<Contact> listOfContacts = new List<Contact>();
        
       	Contact newWorker = TestObjects.createContact(6, 'NDIS');
        newWorker.enrtcr__User__c = y.Id;
        newWorker.Next_Audit__c = System.today();
        listOfContacts.add(newWorker);
        
        Contact newClient = TestObjects.createContact(1, 'NDIS');
        listOfContacts.add(newClient);
        
        insert listOfContacts;  
        
        //Create the clinical audit entry
        Clinical_Audit__c newAudit = new Clinical_Audit__c();
        newAudit.Name = 'Test Audit';
        newAudit.Client__c = newClient.Id;
        newAudit.Clinician__c = newWorker.Id;
        newAudit.Auditor__c = y.Id;
        newAudit.Audit_Type__c = 'Clinical Audit';
        insert newAudit;
        
        Test.startTest();
        //List<Object> data = AnalyticsController.pullData('Clinical Audit', '29-03-2022' , '30-03-2022');
        
        Test.stopTest();
        
        //System.assertEquals(1, data.size());
        
    }
    
    @isTest static void testGetUserKPI(){
        User x = [SELECT id, KPI__c, Title, Name FROM User WHERE IsActive = TRUE AND ProfileId =: [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1] limit 1];
        
        Test.startTest();
        List<User> currentUser = AnalyticsController.getCurrentUserKPI(x.Id);
        Test.stopTest();
        
        System.assertEquals(x, currentUser[0]);
        
    }
    
    @isTest static void testGetAggregate(){
        User x = [SELECT id FROM User WHERE IsActive = TRUE AND ProfileId =: [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1] limit 1];
        
        List<Contact> listOfContacts = new List<Contact>();
        
       	Contact newWorker = TestObjects.createContact(6, 'NDIS');
        newWorker.enrtcr__User__c = x.Id;
        listOfContacts.add(newWorker);
        
        Contact newClient = TestObjects.createContact(1, 'NDIS');
        listOfContacts.add(newClient);
        
        insert listOfContacts;  
        
        //create some dummy events (1 for each event type)
        //create an event
        
        List<Event> eventsToAdd = new List<Event>();
        List<EventRelation> erToAdd = new List<EventRelation>();
        List<Client_Event_Relation__c> cerToAdd = new List<Client_Event_Relation__c>();
        
        //Initial Appt
        Event initialAppt = TestObjects.createEvent('Initial Appointment', 'Booked', x);       
        eventsToAdd.add(initialAppt);
        
        //Therapy
        Event therapy = TestObjects.createEvent('Therapy Session', 'Booked', x);        
        eventsToAdd.add(therapy);        
        
		insert eventsToAdd;
        
        for(Event e : eventsToAdd){
            Client_Event_Relation__c cerOne = TestObjects.createCER('Booked', newClient, e);   
            cerToAdd.add(cerOne);
        
            EventRelation erOne = TestObjects.createER(newWorker, e);
            erToAdd.add(erOne);	
        }        
        
        insert erToAdd;
        insert cerToAdd;
        
        Test.startTest();
        Map<String, List<AggregateResult>> results = AnalyticsController.getAggregateEvents(x.Id);
        Test.stopTest();
        
        System.assertEquals(4, results.size());
    }
    
    @isTest static void testGetEvents(){
        User x = [SELECT id FROM User WHERE IsActive = TRUE AND ProfileId =: [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1] limit 1];
        
        List<Contact> listOfContacts = new List<Contact>();
        
        enrtcr__Site__c testSite = TestObjects.createSite(2);
        insert testSite;
        
       	Contact newWorker = TestObjects.createContact(6, 'NDIS');
        newWorker.enrtcr__User__c = x.Id;
        newWorker.Internal_Banding__c = 'Graduate Clinician';
        newWorker.Clinician_Discipline__c = 'Occupational Therapy';
        newWorker.enrtcr__Site__c = testSite.Id;
        newWorker.enrtcr__Status__c = 'Current';
        listOfContacts.add(newWorker);
        
        Contact newClient = TestObjects.createContact(1, 'NDIS');
        listOfContacts.add(newClient);
        
        insert listOfContacts;  
        
        //create some dummy events (1 for each event type)
        //create an event
        
        List<Event> eventsToAdd = new List<Event>();
        List<EventRelation> erToAdd = new List<EventRelation>();
        List<Client_Event_Relation__c> cerToAdd = new List<Client_Event_Relation__c>();
        
        //Initial Appt
        Event initialAppt = TestObjects.createEvent('Initial Appointment', 'Booked', x);       
        eventsToAdd.add(initialAppt);
        
        //Therapy
        Event therapy = TestObjects.createEvent('Therapy Session', 'Booked', x);        
        eventsToAdd.add(therapy);        
        
		insert eventsToAdd;
        
        for(Event e : eventsToAdd){
            Client_Event_Relation__c cerOne = TestObjects.createCER('Booked', newClient, e);   
            cerToAdd.add(cerOne);
        
            EventRelation erOne = TestObjects.createER(newWorker, e);
            erToAdd.add(erOne);	
        }        
        
        insert erToAdd;
        insert cerToAdd;
        
        Test.startTest();
        Map<String, List<AnalyticsController.EventDetail>> results = AnalyticsController.getEvents();
        Test.stopTest();
        
        System.assertEquals(1, results.size());
    }
    
    @isTest static void testGetSites(){
        enrtcr__Site__c testSite = TestObjects.createSite(2);
        insert testSite;
        
        Test.startTest();
        List<enrtcr__Site__c> results = AnalyticsController.getAllSites();
        Test.stopTest();
        
        System.assertEquals(1, results.size());
    }
    
    @isTest static void testGetTeamLeaderEvents(){
        User x = [SELECT id, FirstName, LastName, TeamLeader__c FROM User WHERE Title = 'Team Leader' AND IsActive = TRUE limit 1];
        
        System.debug('x team leader: ' + x.TeamLeader__c);
        
        List<Contact> listOfContacts = new List<Contact>();
        
        enrtcr__Site__c testSite = TestObjects.createSite(2);
        insert testSite;
        
       	Contact newWorker = TestObjects.createContact(6, 'NDIS');
        newWorker.FirstName = x.FirstName;
        newWorker.LastName = x.LastName;
        newWorker.enrtcr__User__c = x.Id;
        newWorker.Internal_Banding__c = 'Senior Clinician';
        newWorker.Clinician_Discipline__c = 'Occupational Therapy';
        newWorker.enrtcr__Site__c = testSite.Id;
        newWorker.enrtcr__Status__c = 'Current';
        listOfContacts.add(newWorker);
        
        Contact newClient = TestObjects.createContact(1, 'NDIS');
        listOfContacts.add(newClient);
        
        insert listOfContacts;  
        
        //create some dummy events (1 for each event type)
        //create an event
        
        List<Event> eventsToAdd = new List<Event>();
        List<EventRelation> erToAdd = new List<EventRelation>();
        List<Client_Event_Relation__c> cerToAdd = new List<Client_Event_Relation__c>();
        
        //Initial Appt
        Event initialAppt = TestObjects.createEvent('Initial Appointment', 'Booked', x);       
        eventsToAdd.add(initialAppt);
        
        //Therapy
        Event therapy = TestObjects.createEvent('Therapy Session', 'Booked', x);        
        eventsToAdd.add(therapy);        
        
		insert eventsToAdd;
        
        for(Event e : eventsToAdd){
            Client_Event_Relation__c cerOne = TestObjects.createCER('Booked', newClient, e);   
            cerToAdd.add(cerOne);
        
            EventRelation erOne = TestObjects.createER(newWorker, e);
            erToAdd.add(erOne);	
        }        
        
        insert erToAdd;
        insert cerToAdd;
        
        Test.startTest();
        Map<String, List<AnalyticsController.EventDetail>> results = AnalyticsController.getTeamLeaderEvents(x.Id);
        Test.stopTest();
        
        System.assertEquals(1, results.size());
    }
    
}