@isTest
public class BR_EventDetailControllerTest {
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
        
        //create 1 event with 1 client and 1 worker
        Event newEvent = TestObjects.createEvent('Initial Appointment', 'Pending', x);
        insert newEvent;   
        
        Client_Event_Relation__c newCER = TestObjects.createCER('Pending', newClient, newEvent);    
        insert newCER;
        
        EventRelation newER = TestObjects.createER(newWorker, newEvent);
        insert newER;   
    }
    
    @isTest static void testEventMap(){
        Event e = [SELECT Id FROM Event];
        
        Test.startTest();
        
        Map<String, Object> eventMapResult = BR_EventDetailController.getEventMap(e.Id);
        String result = BR_EventDetailController.getEventRelationship(e.Id);
        
        Test.stopTest();
        
        System.assertEquals(e.Id, eventMapResult.get('id'));
        System.assertEquals('sysAdmin', result);
    }
    
    @isTest static void updateEvent(){
        User x = [SELECT id FROM User WHERE IsActive = TRUE AND ProfileId =: [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1] limit 1];
        Contact worker = [SELECT Id, Name FROM Contact WHERE Email = 'newWorker@betterrehab.com.au'];
        Contact client = [SELECT Id, Name FROM Contact WHERE Email = 'testclient@betterrehab.com.au'];
        Event e = [SELECT Id, OwnerId FROM Event];
        
        //prep the String JSON        
        List<Map<String, String>> workers = new List<Map<String, String>>();
        workers.add(new Map<String, String>{'Id' => worker.Id, 'Name' => worker.Name});
        
        List<Map<String, String>> clients = new List<Map<String, String>>();
        clients.add(new Map<String, String>{'Id' => client.Id, 'Name' => client.Name});
        
        Map<String, Object> eventJSON = new Map<String, Object>();
        
        eventJSON.put('eventId', e.Id);
		eventJSON.put('subject', 'Test Test');
        eventJSON.put('startTime', '2022-01-25T12:30:00+11:00'); 
        eventJSON.put('endTime', '2022-01-25T12:45:00+11:00');
        eventJSON.put('eventType', 'Initial Appointment');
        eventJSON.put('address', '123 Right Street');
        eventJSON.put('status', 'Booked');
        eventJSON.put('owner', e.OwnerId);
        
        String eventString = JSON.serialize(eventJSON);
        
        Test.startTest();
        
        List<Map<String, String>> updateEventResult = BR_EventDetailController.updateEvent(eventString, 'saveOne');
        
        Test.stopTest();
        
        System.assertEquals(e.Id, updateEventResult[0].get('Id'));
    }*/
}