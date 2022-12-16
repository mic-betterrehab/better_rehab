@isTest
public class BR_TablePaginationTest {

    /*@testSetup
    public static void setup(){
        User x = [SELECT id FROM User WHERE IsActive = TRUE AND ProfileId =: [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1] limit 1];
        
        //create site
        enrtcr__Site__c newSite = TestObjects.createSite(2);
        newSite.Office_Admin__c = x.Id;
        insert newSite;
        
        List<Contact> listOfContacts = new List<Contact>();
        
        for(Integer i = 0; i < 3; i++){
            Contact newWorker = TestObjects.createContact(6, 'NDIS');
            newWorker.LastName = 'Worker ' + i;
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
        }
        
        //create the contacts to share events
        Contact contactsToShare = new Contact();
        contactsToShare.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Employee').getRecordTypeId();
        contactsToShare.Email = 'testWorker@betterrehab.com.au';
        contactsToShare.FirstName = 'Contact';
        contactsToShare.LastName = 'to share events';
        listOfContacts.add(contactsToShare);
        
        //create 3 clients        
        for(Integer i = 0; i < 3; i++){
            Contact newClient = TestObjects.createContact(1, 'NDIS');
            newClient.LastName = 'Client ' + i;
            listOfContacts.add(newClient);
        }
        
        insert listOfContacts;   
        
        Contact client = [SELECT Id FROM Contact WHERE LastName = 'Client 0'];
        Contact worker = [SELECT Id FROM Contact WHERE LastName = 'Worker 0'];
        
        //create a single event
        Event newEvent = TestObjects.createEvent('Initial Appointment', 'Pending', x);
        newEvent.Number_of_Clients__c = 1;
        newEvent.Number_of_Workers__c = 1;        
        insert newEvent;
        
        //create a CER
        Client_Event_Relation__c newCER = TestObjects.createCER('Pending', client, newEvent);    
        insert newCER;
        
        //create an ER - no status here for now
        EventRelation newER = TestObjects.createER(worker, newEvent);
        insert newER;   
        
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
        
        System.debug('Size of cers recurring: ' + cers.size());
        insert cers;
        insert ers;
    }   
   
    
    @isTest static void testCreateSaveOne(){
        Event e = [SELECT Id, Event_Status__c, OwnerId, Event_Type__c FROM Event where isRecurrence__c = FALSE];        
        Contact worker = [SELECT Id FROM Contact WHERE LastName = 'Worker 1'];
        Contact client = [SELECT Id FROM Contact WHERE LastName = 'Client 1'];
        
        List<String> listOfWorkerIds = new List<String>();
        listOfWorkerIds.add(worker.Id);
        
        List<String> listOfClientIds = new List<String>();
        listOfClientIds.add(client.Id);
        
        Test.startTest();
        
        List<Map<String, Object>> cerCreated = TablePagination.createCERs(listOfClientIds, e.Id, 'saveOne');  
        List<Map<String, Object>> erCreated = TablePagination.createERs(listOfWorkerIds, e.Id, 'saveOne');
            
        //test update the cer and er and event
        TablePagination.updateEvent(e.Id, 'Booked');
        
        Test.stopTest();
        
        Event updatedEvent = [SELECT Id, Number_of_Workers__c, Number_of_Clients__c, Event_Status__c, OwnerId, Event_Type__c FROM Event WHERE Id =: e.Id];
        
        System.assertEquals(2, updatedEvent.Number_of_Clients__c);
        System.assertEquals(2, updatedEvent.Number_of_Workers__c);
        System.assertEquals('Booked', updatedEvent.Event_Status__c);
    }    
    
    @isTest static void testCreateSaveAll(){
        //add 1 worker to all the events in the recurrence
        Event e = [SELECT Id, Number_of_Workers__c, Event_Status__c, OwnerId, Event_Type__c FROM Event WHERE isRecurrence__c = TRUE LIMIT 1];
        System.debug('previous no of workers: ' + e.Number_of_Workers__c);
        
        Contact worker = [SELECT Id FROM Contact WHERE LastName = 'Worker 1'];
        Contact client = [SELECT Id FROM Contact WHERE LastName = 'Client 1'];
        
        List<String> listOfWorkerIds = new List<String>();
        listOfWorkerIds.add(worker.Id);
        
        List<String> listOfClientIds = new List<String>();
        listOfClientIds.add(client.Id);
        
        Test.startTest();
        
        List<Map<String, Object>> cerCreated = TablePagination.createCERs(listOfClientIds, e.Id, 'saveAll');  
        List<Map<String, Object>> erCreated = TablePagination.createERs(listOfWorkerIds, e.Id, 'saveAll');
            
        //test update the cer and er and event
        //TablePagination.updateEvent(e.Id, 'Booked');
        
        Test.stopTest();        
        
        Event updatedEvent = [SELECT Id, Number_of_Workers__c, Number_of_Clients__c, Event_Status__c, OwnerId, Event_Type__c FROM Event WHERE Id =: e.Id];
        
        System.assertEquals(2, updatedEvent.Number_of_Clients__c);
        System.assertEquals(2, updatedEvent.Number_of_Workers__c);
    }    
    
    @isTest static void testHandleUpdateSaveOne(){
        Event e = [SELECT Id, Event_Status__c, OwnerId, Event_Type__c FROM Event WHERE isRecurrence__c = FALSE];
        Client_Event_Relation__c cer = [SELECT Id FROM Client_Event_Relation__c WHERE Event_Id__c =: e.Id];
        EventRelation er = [SELECT Id FROM EventRelation WHERE EventId =: e.Id];
        
        Test.startTest();
        //run through all these to make sure code coverage
        //from pending to booked
        TablePagination.handleCERchange('update', cer.Id, 'Booked', 'saveOne');
        TablePagination.handleERchange('update', er.Id, 'Booked', 'saveOne');
        
        //from booked to cancelled
        TablePagination.handleCERchange('update', cer.Id, 'Cancelled', 'saveOne');
        TablePagination.handleERchange('update', er.Id, 'Cancelled', 'saveOne');
        
        //from cancelled to booked
        TablePagination.handleCERchange('update', cer.Id, 'Booked', 'saveOne');
        TablePagination.handleERchange('update', er.Id, 'Booked', 'saveOne');
        
        Test.stopTest();
        
        Client_Event_Relation__c updatedCER = [SELECT Id, Status__c FROM Client_Event_Relation__c WHERE Event_Id__c =: e.Id];
        EventRelation updatedER = [SELECT Id, Status FROM EventRelation WHERE EventId =: e.Id];
        Event updatedEvent = [SELECT Id, Number_of_Workers__c, Number_of_Clients__c FROM Event WHERE Id =: e.Id];
        
        System.assertEquals('Booked', updatedCER.Status__c);
        System.assertEquals('Accepted', updatedER.Status);
        
        System.assertEquals(1, updatedEvent.Number_of_Clients__c);
        System.assertEquals(1, updatedEvent.Number_of_Workers__c); 
        
    }
    
    @isTest static void testHandleUpdateSaveAll(){
        //find existing cer and er AND update all recurring cer and ers to booked
        Event e = [SELECT Id, Event_Status__c, OwnerId, Event_Type__c FROM Event WHERE isRecurrence__c = TRUE LIMIT 1];
        Client_Event_Relation__c cer = [SELECT Id FROM Client_Event_Relation__c WHERE Event_Id__c =: e.Id];
        EventRelation er = [SELECT Id FROM EventRelation WHERE EventId =: e.Id];
        
        Test.startTest();
        
        //run through all these to make sure code coverage
        //from pending to booked
        TablePagination.handleCERchange('update', cer.Id, 'Booked', 'saveAll');
        TablePagination.handleERchange('update', er.Id, 'Booked', 'saveAll');
        
        //from booked to cancelled
        TablePagination.handleCERchange('update', cer.Id, 'Cancelled', 'saveAll');
        TablePagination.handleERchange('update', er.Id, 'Cancelled', 'saveAll');
        
        //from cancelled to booked
        TablePagination.handleCERchange('update', cer.Id, 'Booked', 'saveAll');
        TablePagination.handleERchange('update', er.Id, 'Booked', 'saveAll');
        
        Test.stopTest();
        
        Client_Event_Relation__c updatedCER = [SELECT Id, Status__c FROM Client_Event_Relation__c WHERE Event_Id__c =: e.Id];
        EventRelation updatedER = [SELECT Id, Status FROM EventRelation WHERE EventId =: e.Id]; 
        Event updatedEvent = [SELECT Id, Number_of_Workers__c, Number_of_Clients__c FROM Event WHERE Id =: e.Id];
        
        System.assertEquals('Booked', updatedCER.Status__c);
        System.assertEquals('Accepted', updatedER.Status);
        System.assertEquals(1, updatedEvent.Number_of_Clients__c);
        System.assertEquals(1, updatedEvent.Number_of_Workers__c);        
    }
    
    @isTest static void testDeleteSaveOne(){
        Event e = [SELECT Id, Event_Status__c, OwnerId, Event_Type__c FROM Event where isRecurrence__c = FALSE];
        Client_Event_Relation__c cer = [SELECT Id FROM Client_Event_Relation__c WHERE Event_Id__c =: e.Id LIMIT 1];
        EventRelation er = [SELECT Id FROM EventRelation WHERE EventId =: e.Id LIMIT 1];
        
        Test.startTest();
        TablePagination.deleteCER(cer.Id, 'saveOne');
        TablePagination.deleteER(er.Id, 'saveOne');
        
        Test.stopTest();
        
        List<Client_Event_Relation__c> updatedCER = [SELECT Id, IsDeleted  FROM Client_Event_Relation__c WHERE Event_Id__c =: e.Id];
        List<EventRelation> updatedER = [SELECT Id, IsDeleted  FROM EventRelation WHERE EventId =: e.Id]; 
        
        System.assertEquals(0, updatedCER.size());
        System.assertEquals(0, updatedER.size());
        
    }
    
    @isTest static void testDeleteSaveAll(){
        Event e = [SELECT Id, Event_Status__c, OwnerId, Event_Type__c FROM Event where isRecurrence__c = TRUE LIMIT 1];
        Client_Event_Relation__c cer = [SELECT Id FROM Client_Event_Relation__c WHERE Event_Id__c =: e.Id];
        EventRelation er = [SELECT Id FROM EventRelation WHERE EventId =: e.Id];
        
        Test.startTest();
        TablePagination.deleteCER(cer.Id, 'saveAll');
        TablePagination.deleteER(er.Id, 'saveAll');
        
        Test.stopTest();
        
        List<Client_Event_Relation__c> updatedCER = [SELECT Id, IsDeleted  FROM Client_Event_Relation__c WHERE Event_Id__c =: e.Id];
        List<EventRelation> updatedER = [SELECT Id, IsDeleted  FROM EventRelation WHERE EventId =: e.Id]; 
        Event updatedEvent = [SELECT Id, Number_of_Workers__c, Number_of_Clients__c FROM Event WHERE Id =: e.Id];
        
        System.assertEquals(0, updatedCER.size());
        System.assertEquals(0, updatedER.size());
        System.assertEquals(0, updatedEvent.Number_of_Clients__c);
        System.assertEquals(0, updatedEvent.Number_of_Workers__c);        
    }
    
    @isTest static void testEvent(){
        Event e = [SELECT Id, Event_Status__c, OwnerId, Event_Type__c FROM Event where isRecurrence__c = FALSE];
        
        Test.startTest();
        
        //get event
        Event newEvent = TablePagination.getEvent(e.Id);
        Event updatedEvent = TablePagination.updateEvent(newEvent.Id, 'Booked');
        
        Test.stopTest();
        
        Event bookedEvent = [SELECT Id, Event_Status__c FROM Event WHERE Id =: updatedEvent.Id];
        
        System.assertEquals(bookedEvent.Id, e.Id);
        System.assertEquals('Booked', bookedEvent.Event_Status__c);
    }
    
    @isTest static void testPermissionChecker(){
        Event e = [SELECT Id, Event_Status__c, OwnerId, Event_Type__c FROM Event where isRecurrence__c = FALSE];
    }*/
}