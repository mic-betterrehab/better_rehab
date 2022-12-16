@isTest
public class BR_CalendarClashTest {
    /*@testSetup
    static void setup(){
        //create 1 event
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
    }
    
    @isTest static void testClientWorkerClash(){
        User x = [SELECT id FROM User WHERE IsActive = TRUE AND ProfileId =: [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1] limit 1];
        Contact worker = [SELECT Id, Name FROM Contact WHERE Email = 'newWorker@betterrehab.com.au'];
        Contact client = [SELECT Id, Name FROM Contact WHERE Email = 'testclient@betterrehab.com.au'];
        
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
		
        repeatJSON.put('numberEvents', null);
        repeatJSON.put('onAfter', 'After');
        repeatJSON.put('onDate', '2022-01-22');
        repeatJSON.put('repeat', false);
        repeatJSON.put('repeatTime', null);
        repeatJSON.put('repeatFrequency', null);
        
        String eventString = JSON.serialize(eventJSON);
        String repeatString = JSON.serialize(repeatJSON);
        
        Test.startTest();
        String[] clashes = BR_CalendarClashController.findClashingWorkerAndClientEvents(eventString, repeatString);
        Test.stopTest();
        
        System.assertEquals(2, clashes.size());   
    }
    
    @isTest static void testClashAllDay(){
        User x = [SELECT id FROM User WHERE IsActive = TRUE AND ProfileId =: [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1] limit 1];
        Contact worker = [SELECT Id, Name FROM Contact WHERE Email = 'newWorker@betterrehab.com.au'];
        Contact client = [SELECT Id, Name FROM Contact WHERE Email = 'testclient@betterrehab.com.au'];
        
        //prep the String JSON        
        List<Map<String, String>> workers = new List<Map<String, String>>();
        workers.add(new Map<String, String>{'Id' => worker.Id, 'Name' => worker.Name});
        
        List<Map<String, String>> clients = new List<Map<String, String>>();
        clients.add(new Map<String, String>{'Id' => client.Id, 'Name' => client.Name});
        
        Map<String, Object> eventJSON = new Map<String, Object>();
        Map<String, Object> repeatJSON = new Map<String, Object>();
       	
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
		
        repeatJSON.put('numberEvents', 2);
        repeatJSON.put('onAfter', 'On');
        repeatJSON.put('onDate', '2022-01-30');
        repeatJSON.put('repeat', true);
        repeatJSON.put('repeatTime', 'Day');
        repeatJSON.put('repeatFrequency', 1);
        
        String eventString = JSON.serialize(eventJSON);
        String repeatString = JSON.serialize(repeatJSON);
        
        Test.startTest();
        String[] clashes = BR_CalendarClashController.findClashingWorkerAndClientEvents(eventString, repeatString);
        Test.stopTest();
        
        System.assertEquals(1, clashes.size());   
    }*/
}