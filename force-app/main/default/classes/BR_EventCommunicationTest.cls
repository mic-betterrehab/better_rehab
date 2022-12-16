@isTest
public class BR_EventCommunicationTest {
    @testSetup
    static void setup(){
        User x = [SELECT id FROM User WHERE IsActive = TRUE AND ProfileId =: [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1] limit 1];
        
        //create site
        enrtcr__Site__c newSite = TestObjects.createSite(2);
        newSite.Office_Admin__c = x.Id;
        insert newSite;
        
        List<Contact> listOfContacts = new List<Contact>();
        
        Contact newWorker = new Contact();
        newWorker.LastName = 'Worker';
        newWorker.FirstName = 'newW';
        newWorker.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Employee').getRecordTypeId();
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
        contactsToShare.FirstName = 'Contact';
        contactsToShare.Email = 'testWorker@betterrehab.com.au';
        contactsToShare.LastName = 'to share events';
        listOfContacts.add(contactsToShare);
        
        //create 1 client 
        Contact newClient = TestObjects.createContact(1, 'NDIS');
        listOfContacts.add(newClient);
        
        insert listOfContacts;  
        
        //create custom setting
        Pendula_Triggers__c pendulaTriggerIndication = new Pendula_Triggers__c();
        pendulaTriggerIndication.isTriggerEnabled__c = TRUE;
        
        insert pendulaTriggerIndication;
    }
    
    //Single Create Pending + Update Pending - Book
    @isTest static void testPendingBook(){
        User x = [SELECT id FROM User WHERE IsActive = TRUE AND ProfileId =: [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1] limit 1];
        Contact worker = [SELECT Id FROM Contact WHERE Email = 'newWorker@betterrehab.com.au'];
        Contact client = [SELECT Id FROM Contact WHERE Email = 'testclient@betterrehab.com.au'];
        
        Test.startTest();
        
        //create an event
        Event newEvent = TestObjects.createEvent('Initial Appointment', 'Pending', x);        
        insert newEvent;
        
        //create a CER
        Client_Event_Relation__c newCER = TestObjects.createCER('Pending', client, newEvent);    
        insert newCER;
        
        //create an ER - no status here for now
        EventRelation newER = TestObjects.createER(worker, newEvent);
		insert newER;    
        
        //update the CER to Booked
        newCER.Status__c = 'Booked';
        update newCER;
        
        Test.stopTest();
        
        //Get the EC - ideally should give 2 EC: 1 for booking confirmation, 1 for SMS reminder
        List<Event_Communication__c> listOfECs = [SELECT Id, RecordTypeId FROM Event_Communication__c WHERE Client_Event_Relation__c =: newCER.Id];
        
        System.assertEquals(2, listOfECs.size());
        
        Event_Communication__c smsReminder = [SELECT Id, RecordTypeId FROM Event_Communication__c WHERE Client_Event_Relation__c =: newCER.Id AND RecordTypeId =: Schema.SObjectType.Event_Communication__c.getRecordTypeInfosByDeveloperName().get('X24_Hour_Reminder').getRecordTypeId()];
        
        System.assert(smsReminder != NULL);
        
        Event_Communication__c bookReminder = [SELECT Id, RecordTypeId FROM Event_Communication__c WHERE Client_Event_Relation__c =: newCER.Id AND RecordTypeId =: Schema.SObjectType.Event_Communication__c.getRecordTypeInfosByDeveloperName().get('Single_Appointment_Confirmation').getRecordTypeId()];
        
        System.assert(bookReminder != NULL);        
    }
    
    //Single Create Book + Update Book - Cancel
    @isTest static void testBookCancel(){
        User x = [SELECT id FROM User WHERE IsActive = TRUE AND ProfileId =: [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1] limit 1];
        Contact worker = [SELECT Id FROM Contact WHERE Email = 'newWorker@betterrehab.com.au'];
        Contact client = [SELECT Id FROM Contact WHERE Email = 'testclient@betterrehab.com.au'];
        
        Test.startTest();
        
        //create an event
        Event newEvent = TestObjects.createEvent('Initial Appointment', 'Booked', x);        
        insert newEvent;
        
        //create a CER
        Client_Event_Relation__c newCER = TestObjects.createCER('Booked', client, newEvent);    
        insert newCER;
        
        //create an ER - no status here for now
        EventRelation newER = TestObjects.createER(worker, newEvent);
		insert newER;
        
        //update the CER to Booked
        newCER.Status__c = 'Cancelled';
        update newCER;
        
        Test.stopTest();
        
        //Get the EC - ideally should give 3 EC: 1 for booking confirmation, 1 for SMS reminder, 1 for cancellation
        List<Event_Communication__c> listOfECs = [SELECT Id, RecordTypeId FROM Event_Communication__c WHERE Client_Event_Relation__c =: newCER.Id];
        
        System.assertEquals(3, listOfECs.size());
        
        Event_Communication__c smsReminder = [SELECT Id, RecordTypeId FROM Event_Communication__c WHERE Client_Event_Relation__c =: newCER.Id AND RecordTypeId =: Schema.SObjectType.Event_Communication__c.getRecordTypeInfosByDeveloperName().get('X24_Hour_Reminder').getRecordTypeId()];
        
        System.assert(smsReminder != NULL);
        
        Event_Communication__c bookReminder = [SELECT Id, RecordTypeId FROM Event_Communication__c WHERE Client_Event_Relation__c =: newCER.Id AND RecordTypeId =: Schema.SObjectType.Event_Communication__c.getRecordTypeInfosByDeveloperName().get('Single_Appointment_Confirmation').getRecordTypeId()];
        
        System.assert(bookReminder != NULL); 
        
        Event_Communication__c cancelReminder = [SELECT Id, RecordTypeId FROM Event_Communication__c WHERE Client_Event_Relation__c =: newCER.Id AND RecordTypeId =: Schema.SObjectType.Event_Communication__c.getRecordTypeInfosByDeveloperName().get('Single_Appointment_Cancellation').getRecordTypeId()];
        
        System.assert(cancelReminder != NULL);
    }
    
    //Update Single Time Changed
    @isTest static void testSingleTimeChanged(){
        User x = [SELECT id FROM User WHERE IsActive = TRUE AND ProfileId =: [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1] limit 1];
        Contact worker = [SELECT Id FROM Contact WHERE Email = 'newWorker@betterrehab.com.au'];
        Contact client = [SELECT Id FROM Contact WHERE Email = 'testclient@betterrehab.com.au'];
        
        Test.startTest();
        
        //create an event
        Event newEvent = TestObjects.createEvent('Initial Appointment', 'Booked', x);        
        insert newEvent;
        
        //create a CER
        Client_Event_Relation__c newCER = TestObjects.createCER('Booked', client, newEvent);    
        insert newCER;
        
        //create an ER - no status here for now
        EventRelation newER = TestObjects.createER(worker, newEvent);
		insert newER;      
        
        //update the Event start time
        newEvent.StartDateTime = System.now() + 5;
        newEvent.EndDateTime = System.now() + 10;
        newEvent.Event_Status__c = 'Pending';
        update newEvent;
        
        newCER.Status__c = 'Pending';
        newER.Status = 'New'; //new means pending
        
        update newCER;
        update newER;        
        
        //after you update, we will change the event to be booked
        newEvent.Event_Status__c = 'Booked';
        newCER.Status__c = 'Booked';
        newCER.Time_Changed__c = TRUE;
        newER.Status = 'Accepted';
        
        update newEvent;
        update newCER;
        update newER;
        
        System.debug('newEvent.status: ' + newEvent.Event_Status__c);
        System.debug('newCER.Time_Changed__c: ' + newCER.Time_Changed__c);
        
        Test.stopTest();
        
        Event_Communication__c smsReminder = [SELECT Id, RecordTypeId FROM Event_Communication__c WHERE Client_Event_Relation__c =: newCER.Id AND RecordTypeId =: Schema.SObjectType.Event_Communication__c.getRecordTypeInfosByDeveloperName().get('X24_Hour_Reminder').getRecordTypeId()];
        
        System.assert(smsReminder != NULL);
        
        Event_Communication__c bookReminder = [SELECT Id, RecordTypeId FROM Event_Communication__c WHERE Client_Event_Relation__c =: newCER.Id AND RecordTypeId =: Schema.SObjectType.Event_Communication__c.getRecordTypeInfosByDeveloperName().get('Single_Appointment_Confirmation').getRecordTypeId()];
        
        System.assert(bookReminder != NULL);   
        
        Event_Communication__c timeChangedReminder = [SELECT Id, RecordTypeId FROM Event_Communication__c WHERE Client_Event_Relation__c =: newCER.Id AND RecordTypeId =: Schema.SObjectType.Event_Communication__c.getRecordTypeInfosByDeveloperName().get('Single_Appointment_Time_Changed').getRecordTypeId()];
        
        System.assert(timeChangedReminder != NULL); 
    }
    
    //Update Recurring Time Changed
    @isTest static void testRecurringTimeChanged(){
        User x = [SELECT id FROM User WHERE IsActive = TRUE AND ProfileId =: [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1] limit 1];
        Contact worker = [SELECT Id FROM Contact WHERE Email = 'newWorker@betterrehab.com.au'];
        Contact client = [SELECT Id FROM Contact WHERE Email = 'testclient@betterrehab.com.au'];
        
        Test.startTest();
        
        //create the event recurrence first
        Event_Recurrence__c newRecurrence = new Event_Recurrence__c();
        insert newRecurrence;
        
        List<Event> events = new List<Event>();
        List<Client_Event_Relation__c> cers = new List<Client_Event_Relation__c>();
        List<EventRelation> ers = new List<EventRelation>();
        
        for(Integer i = 0; i < 3; i++){
            Event newEvent = TestObjects.createEvent('Therapy Session', 'Booked', x); 
            newEvent.Event_Recurrence__c = newRecurrence.Id;            
            
            events.add(newEvent);
        }
        
        insert events;
        
        for(Event e : events){            
            Client_Event_Relation__c newCER = TestObjects.createCER('Booked', client, e);            
            EventRelation newER = TestObjects.createER(worker, e);
            
            cers.add(newCER);
            ers.add(newER);
        }
        
        System.debug('Size of cers recurring: ' + cers.size());
        insert cers;
        insert ers;
        
        //changed the time for all 3 events
        for(Event e : events){
            e.StartDateTime = System.now() + 5;
            e.EndDateTime = System.now() + 10;
            e.Event_Status__c = 'Pending';
            update e;
        }  
        
        for(Client_Event_Relation__c cer : cers){
            cer.Status__c = 'Pending';
            update cer;
        }
        
        for(EventRelation er : ers){
            er.Status = 'New';
            update er;
        }
        
        //after time change, book them all
        for(Event e : events){
            e.Event_Status__c = 'Booked';
            update e;
            System.debug('e.status: ' + e.Event_Status__c);
        }  
        
        List<Client_Event_Relation__c> finalCERs = new List<Client_Event_Relation__c>();
        
        for(Client_Event_Relation__c cer : cers){
            cer.Status__c = 'Booked';
            cer.Time_Changed__c = TRUE;
            finalCERs.add(cer);
            System.debug('cer.Time_Changed__c: ' + cer.Time_Changed__c);
        }
        
        update finalCERs;
        
        for(EventRelation er : ers){
            er.Status = 'Accepted';
            update er;
        }
        
        Test.stopTest();
        
        List<Event_Communication__c> smsReminder = [SELECT Id, RecordTypeId FROM Event_Communication__c WHERE Client_Event_Relation__c IN: cers AND RecordTypeId =: Schema.SObjectType.Event_Communication__c.getRecordTypeInfosByDeveloperName().get('X24_Hour_Reminder').getRecordTypeId()];
        
        System.assertEquals(3, smsReminder.size());
        
        List<Event_Communication__c> bookReminder = [SELECT Id, RecordTypeId FROM Event_Communication__c WHERE Client_Event_Relation__c IN: cers AND RecordTypeId =: Schema.SObjectType.Event_Communication__c.getRecordTypeInfosByDeveloperName().get('Recurring_Appointment_Confirmation').getRecordTypeId()];
        
        System.assertEquals(1, bookReminder.size());   
        
        List<Event_Communication__c> timeChangedReminder = [SELECT Id, RecordTypeId FROM Event_Communication__c WHERE Client_Event_Relation__c IN: cers AND RecordTypeId =: Schema.SObjectType.Event_Communication__c.getRecordTypeInfosByDeveloperName().get('Recurring_Appointment_Time_Changed').getRecordTypeId()];
        
        System.assertEquals(1, timeChangedReminder.size());
    }
    
    //Recurring Create Pending + Update Pending - Book
    @isTest static void testRecurringPendingBook(){
        User x = [SELECT id FROM User WHERE IsActive = TRUE AND ProfileId =: [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1] limit 1];
        Contact worker = [SELECT Id FROM Contact WHERE Email = 'newWorker@betterrehab.com.au'];
        Contact client = [SELECT Id FROM Contact WHERE Email = 'testclient@betterrehab.com.au'];
        
        Test.startTest();
        
        //create the event recurrence first
        Event_Recurrence__c newRecurrence = new Event_Recurrence__c();
        insert newRecurrence;
        
        List<Event> events = new List<Event>();
        List<Client_Event_Relation__c> cers = new List<Client_Event_Relation__c>();
        List<EventRelation> ers = new List<EventRelation>();
        
        for(Integer i = 0; i < 3; i++){
            Event newEvent = TestObjects.createEvent('Therapy Session', 'Pending', x); 
            newEvent.Event_Recurrence__c = newRecurrence.Id;            
            
            events.add(newEvent);
        }
        
        insert events;
        
        for(Event e : events){            
            Client_Event_Relation__c newCER = TestObjects.createCER('Pending', client, e);            
            EventRelation newER = TestObjects.createER(worker, e);
            
            cers.add(newCER);
            ers.add(newER);
        }
        
        insert cers;
        insert ers;
        
        //change it to cancel for all 3
        List<Client_Event_Relation__c> bookedCER = new List<Client_Event_Relation__c>();
        for(Client_Event_Relation__c cer : cers){
            cer.Status__c = 'Booked';
            bookedCER.add(cer);
        }
        
        update bookedCER;
        
        Test.stopTest();
        
        //check how many ECs are created - should only be 1 for when it's booked
        Event_Communication__c bookReminder = [SELECT Id, RecordTypeId FROM Event_Communication__c WHERE RecordTypeId =: Schema.SObjectType.Event_Communication__c.getRecordTypeInfosByDeveloperName().get('Recurring_Appointment_Confirmation').getRecordTypeId()];
        
        System.assert(bookReminder != NULL);   
        
        List<Event_Communication__c> dailyReminder = [SELECT Id, RecordTypeId FROM Event_Communication__c WHERE RecordTypeId =: Schema.SObjectType.Event_Communication__c.getRecordTypeInfosByDeveloperName().get('X24_Hour_Reminder').getRecordTypeId()];
        
        System.assertEquals(3, dailyReminder.size());  
    }
    
    //Recurring Create Book + Update Book - Cancel
    @isTest static void testRecurringBookCancel(){
        User x = [SELECT id FROM User WHERE IsActive = TRUE AND ProfileId =: [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1] limit 1];
        Contact worker = [SELECT Id FROM Contact WHERE Email = 'newWorker@betterrehab.com.au'];
        Contact client = [SELECT Id FROM Contact WHERE Email = 'testclient@betterrehab.com.au'];
        
        Test.startTest();
        
        //create the event recurrence first
        Event_Recurrence__c newRecurrence = new Event_Recurrence__c();
        insert newRecurrence;
        
        //create the 3 recurring events
        //associate the event recurrence with each event
        //create 3 recurring events
        
        List<Event> events = new List<Event>();
        List<Client_Event_Relation__c> cers = new List<Client_Event_Relation__c>();
        List<EventRelation> ers = new List<EventRelation>();
        
        for(Integer i = 0; i < 3; i++){
            Event newEvent = TestObjects.createEvent('Therapy Session', 'Booked', x); 
            newEvent.Event_Recurrence__c = newRecurrence.Id;            
            
            events.add(newEvent);
        }
        
        insert events;
        
        for(Event e : events){            
            Client_Event_Relation__c newCER = TestObjects.createCER('Booked', client, e);            
            EventRelation newER = TestObjects.createER(worker, e);
            
            cers.add(newCER);
            ers.add(newER);
        }
        
        insert cers;
        insert ers;
        
        //change it to cancel for all 3
        List<Client_Event_Relation__c> cancelledCER = new List<Client_Event_Relation__c>();
        for(Client_Event_Relation__c cer : cers){
            cer.Status__c = 'Cancelled';
            cancelledCER.add(cer);
        }
        
        update cancelledCER;
        
        Test.stopTest();
        
        //check how many ECs are created - should only be 2 - 1 for when it's booked, 1 for when it's cancelled
        Event_Communication__c bookReminder = [SELECT Id, RecordTypeId FROM Event_Communication__c WHERE RecordTypeId =: Schema.SObjectType.Event_Communication__c.getRecordTypeInfosByDeveloperName().get('Recurring_Appointment_Confirmation').getRecordTypeId()];
        
        System.assert(bookReminder != NULL);   
        
        Event_Communication__c cancelReminder = [SELECT Id, RecordTypeId FROM Event_Communication__c WHERE RecordTypeId =: Schema.SObjectType.Event_Communication__c.getRecordTypeInfosByDeveloperName().get('Recurring_Appointment_Cancellation').getRecordTypeId()];
        
        System.assert(cancelReminder != NULL); 
        
        List<Event_Communication__c> dailyReminder = [SELECT Id, RecordTypeId FROM Event_Communication__c WHERE RecordTypeId =: Schema.SObjectType.Event_Communication__c.getRecordTypeInfosByDeveloperName().get('X24_Hour_Reminder').getRecordTypeId()];
        
        System.assertEquals(3, dailyReminder.size());         
    }  
    
}