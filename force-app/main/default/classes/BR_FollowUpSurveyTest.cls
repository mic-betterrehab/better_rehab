@isTest
public class BR_FollowUpSurveyTest {
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
        
        //create an event - the rule is 6 events at least in the last 8 weeks
        for(Integer i = 0; i < 10; i++){
            Event newEvent = new Event();
            newEvent.Subject = 'Test Event';
            newEvent.StartDateTime = DateTime.newInstance(System.today()-56, Time.newInstance(3, 0, 0, 0));
            newEvent.EndDateTime = DateTime.newInstance(System.today()-56, Time.newInstance(4, 0, 0, 0)); //gotta make this to end at 4am the day before (cause apex is using some other timezone)
            newEvent.Event_Type__c = 'Therapy Session';
            newEvent.RecordTypeId = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('BR_Event').getRecordTypeId();
            newEvent.Event_Status__c = 'Booked';
            newEvent.OwnerId = x.Id;
            
            eventsToAdd.add(newEvent);
            i++;
        }
        
        //create an event just for last week for the batch to run
        Event lastWeekEvent = new Event();
        lastWeekEvent.Subject = 'Test Event';
        lastWeekEvent.StartDateTime = DateTime.newInstance(System.today()-7, Time.newInstance(3, 0, 0, 0));
        lastWeekEvent.EndDateTime = DateTime.newInstance(System.today()-7, Time.newInstance(4, 0, 0, 0)); //gotta make this to end at 4am the day before (cause apex is using some other timezone)
        lastWeekEvent.Event_Type__c = 'Initial Appointment';
        lastWeekEvent.RecordTypeId = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('BR_Event').getRecordTypeId();
        lastWeekEvent.Event_Status__c = 'Booked';
        lastWeekEvent.OwnerId = x.Id;
        
        eventsToAdd.add(lastWeekEvent);
        
        insert eventsToAdd;       
        
        //retrieve the added event
        List<Event> insertedEvents = [SELECT Id FROM Event WHERE Event_Type__c = 'Therapy Session'];
        System.debug('InsertedEvents: ' + insertedEvents.size());
        
        List<Client_Event_Relation__c> cersToAdd = new List<Client_Event_Relation__c>();
        List<EventRelation> ersToAdd = new List<EventRelation>();
        
        Client_Event_Relation__c initialCER = TestObjects.createCER('Booked', clientOne, lastWeekEvent);
        cersToAdd.add(initialCER);
        Client_Event_Relation__c initialCERTwo = TestObjects.createCER('Booked', clientTwo, lastWeekEvent);  
        cersToAdd.add(initialCERTwo);
        
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
        
        List<Feedback_Survey__c> listOfFS = new List<Feedback_Survey__c>();
        
        //create a initial feedback survey dating back to 8 weeks ago
        Feedback_Survey__c fs = new Feedback_Survey__c();
        fs.Recipient__c = clientOne.Id;
        fs.Worker__c = workerOne.Id;
        fs.Survey_Sent_Time__c = DateTime.newInstance(System.today()-56, Time.newInstance(3, 0, 0, 0));
        listOfFS.add(fs);
        
        Feedback_Survey__c fsTwo = new Feedback_Survey__c();
        fsTwo.Recipient__c = clientTwo.Id;
        fsTwo.Worker__c = workerOne.Id;
        fsTwo.Survey_Sent_Time__c = DateTime.newInstance(System.today()-56, Time.newInstance(3, 0, 0, 0));
        listOfFS.add(fsTwo);
        
        insert listOfFS;
        
    }
    
    //this only testing that your scheduled job is scheduled, not executed
    @isTest
    static void testScheduled(){
        Test.startTest();
        
        // Schedule the test job
        BR_FollowUpSurveyScheduleJob b = new BR_FollowUpSurveyScheduleJob();
        String sch = '0 50 12 1 7 ? 2023';
        String jobId = System.schedule('Testing Follow Up Survey Schedule Job', sch, b);
        
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
        Database.executeBatch(new BR_FollowUpSurveyBatch());
        Test.stopTest();
        
        List<Event> therapyAppts = [SELECT Id, Subject, Event_Type__c, StartDateTime, EndDateTime FROM Event 
                                    WHERE StartDateTime = LAST_WEEK AND (Event_Type__c = 'Initial Appointment' OR Event_Type__c = 'Therapy Session') AND Event_Status__c = 'Booked'];
        
        Id followUpSurvey = Schema.SObjectType.Feedback_Survey__c.getRecordTypeInfosByDeveloperName().get('Follow_Up_Client_Survey').getRecordTypeId();
        
        List<Feedback_Survey__c> listOfFollowUpSurveys = [SELECT Id FROM Feedback_Survey__c WHERE RecordTypeId =: followUpSurvey];
        
        //events have to be booked, ending last week
        System.assertEquals(1, therapyAppts.size());
        System.debug('initialAppts: ' + therapyAppts.size());
        
        //1 follow up survey should be created
        System.assertEquals(2, listOfFollowUpSurveys.size());
        System.debug('listOfFollowUpSurveys: ' + listOfFollowUpSurveys.size());
    }
}