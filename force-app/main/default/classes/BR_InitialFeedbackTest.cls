@isTest
public class BR_InitialFeedbackTest {
	@testSetup
    static void setup(){
        User x = [SELECT id FROM User WHERE IsActive = TRUE AND ProfileId =: [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1] limit 1];
        
        List<Contact> contacts = new List<Contact>();
        
        //create 2 clients
        Contact clientOne = TestObjects.createContact(1, 'NDIS');
        Contact clientTwo = TestObjects.createContact(1, 'NDIS');
        contacts.add(clientOne);
        contacts.add(clientTwo);
        
        //create 2 workers
        Contact workerOne = TestObjects.createContact(6, 'NDIS');
        Contact workerTwo = TestObjects.createContact(6, 'NDIS');
        
        contacts.add(workerOne);
        contacts.add(workerTwo);
        
        //create the contacts to share events
        Contact contactsToShare = new Contact();
        contactsToShare.RecordTypeId = '0122v0000013OcoAAE';
        contactsToShare.Email = 'testWorker@betterrehab.com.au';
        contactsToShare.LastName = 'to share events';
        
        contacts.add(contactsToShare);        
        
        insert contacts;
        
        List<Event> eventsToAdd = new List<Event>();
        
        //create an event
        for(Integer i = 0; i < 10; i++){
            Event newEvent = new Event();
            newEvent.Subject = 'Test Event';
            newEvent.StartDateTime = DateTime.newInstance(System.today()-1, Time.newInstance(3, 0, 0, 0));
            newEvent.EndDateTime = DateTime.newInstance(System.today()-1, Time.newInstance(4, 0, 0, 0)); //gotta make this to end at 4am the day before (cause apex is using some other timezone)
            newEvent.Event_Type__c = 'Initial Appointment';
            newEvent.RecordTypeId = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('BR_Event').getRecordTypeId();
            newEvent.Event_Status__c = 'Booked';
            newEvent.OwnerId = x.Id;
            
            eventsToAdd.add(newEvent);
            i++;
        }
        
        insert eventsToAdd;
        
        //retrieve the added event
        List<Event> insertedEvents = [SELECT Id FROM Event WHERE Event_Type__c = 'Initial Appointment'];
        System.debug('InsertedEvents: ' + insertedEvents.size());
        
        List<Client_Event_Relation__c> cersToAdd = new List<Client_Event_Relation__c>();
        List<EventRelation> ersToAdd = new List<EventRelation>();
        
        //create a CER and ER
        for(Event e : insertedEvents){
            Client_Event_Relation__c newCEROne = TestObjects.createCER('Booked', clientOne, e);  
            Client_Event_Relation__c newCERTwo = TestObjects.createCER('Booked', clientTwo, e);  
            EventRelation newEROne = TestObjects.createER(workerOne, e);
            EventRelation newERTwo = TestObjects.createER(workerTwo, e);
            
            cersToAdd.add(newCEROne);
            cersToAdd.add(newCERTwo);
            ersToAdd.add(newEROne);
            ersToAdd.add(newERTwo);
        }
        
        insert cersToAdd;
        insert ersToAdd;      
        
        //create custom setting
        Pendula_Triggers__c pendulaTriggerIndication = new Pendula_Triggers__c();
        pendulaTriggerIndication.isTriggerEnabled__c = TRUE;
        
        insert pendulaTriggerIndication;
    }
    
    //this only testing that your scheduled job is scheduled, not executed
    @isTest
    static void testScheduled(){
        Test.startTest();
        
        // Schedule the test job
        BR_InitialFeedbackScheduleJob b = new BR_InitialFeedbackScheduleJob();
        String sch = '0 50 12 1 7 ? 2023';
        String jobId = System.schedule('Testing Initial Feedback Schedule Job', sch, b);
        
        Test.stopTest();
        
        // Get the information from the CronTrigger API object 
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId]; 
        
        // Verify the job has not run 
        System.assertEquals(0, ct.TimesTriggered); 
        // Verify the next time the job will run 
        System.assertEquals('2023-07-01 12:50:00', String.valueOf(ct.NextFireTime));
    }
    
    //this test that your batch will execute
    @isTest
    static void testBatch(){
        Test.startTest();
        Database.executeBatch(new BR_InitialFeedbackBatch());
        Test.stopTest();
        
        //check if 10 initial surveys are created
        List<Event> initialAppts = [SELECT Id FROM Event WHERE Event_Type__c = 'Initial Appointment'];
        
        Id initialSurveyId = Schema.SObjectType.Feedback_Survey__c.getRecordTypeInfosByDeveloperName().get('Initial_Client_Survey').getRecordTypeId();
        
        List<Feedback_Survey__c> listOfInitialSurveys = [SELECT Id FROM Feedback_Survey__c WHERE RecordTypeId =: initialSurveyId];
        
        //events have to be booked, ending yesterday, and 
        System.assertEquals(5, initialAppts.size());
        System.debug('initialAppts: ' + initialAppts.size());
        
        System.assertEquals(10, listOfInitialSurveys.size());
        System.debug('listOfInitialSurveys: ' + listOfInitialSurveys.size());
    }
        
}