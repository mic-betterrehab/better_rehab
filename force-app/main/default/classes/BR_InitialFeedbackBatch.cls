public class BR_InitialFeedbackBatch implements Database.Batchable<SObject> {
	//this batch class will be scheduled to create initial survey    

    private final Id FOLLOWUP_SURVEY = Schema.SObjectType.Feedback_Survey__c.getRecordTypeInfosByDeveloperName().get('Follow_Up_Client_Survey').getRecordTypeId();
	private final Id INITIAL_SURVEY = Schema.SObjectType.Feedback_Survey__c.getRecordTypeInfosByDeveloperName().get('Initial_Client_Survey').getRecordTypeId();
    private final Id BR_EVENT = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('BR_Event').getRecordTypeId();
    
    Map<Id, Id> cerToClient = new Map<Id, Id>();  
    Map<Id, Id> cerToEvent = new Map<Id, Id>();  
    Map<Id, Client_Event_Relation__c> cerMapOnly = new Map<Id, Client_Event_Relation__c>();
    Map<Id, Event> eventDetailsMap = new Map<Id, Event>();    
    Map<Id, Client_Event_Relation__c> validCER;  
    Map<Id, Boolean> clientHasEnoughSessions = new Map<Id, Boolean>();
    Map<Id, Boolean> clientLastSurveyWeeksValid = new Map<Id, Boolean>();
    Map<Id, DateTime> eventIdAndEndDate = new Map<Id, DateTime>();
    Map<Id, Contact> mapOfWorkers;
    List<Feedback_Survey__c> surveyToInsert = new List<Feedback_Survey__c>();
    Map<Id, Id> eventToWorker = new Map<Id, Id>();

    List<Feedback_Survey__c> surveysToInsert = new List<Feedback_Survey__c>();
    List<Contact> clientsToFollowUp = new List<Contact>();
    Map<Id, Client_Event_Relation__c> cerToFollowUp = new Map<Id, Client_Event_Relation__c>();

    List<Event> listOfEvents = new List<Event>();
    Map<Id, Id> smallClientToCERMap = new Map<Id,Id>();
    Map<Id, Map<Id,Id>> bigEventToClientToCERMap = new Map<Id,Map<Id,Id>>();

    static final Integer numberOfValidEvents = 6;
    static final Integer numberOfValidWeeks = 8;
	
    public BR_InitialFeedbackBatch(){
        
    }
    
    //max of 50 million records
    public Database.QueryLocator start(Database.BatchableContext BC){
        //criteria is as set below        
        return Database.getQueryLocator(
        [
            SELECT Id, Subject, Event_Type__c, EndDate, EndDateTime, StartDateTime
            FROM Event 
            WHERE RecordTypeId =: BR_EVENT AND EndDateTime = YESTERDAY AND Event_Type__c = 'Initial Appointment' AND Event_Status__c = 'Booked' //will be run every day
        ]);
    }
    
    //by default will process 200 records at once
    public void execute(Database.BatchableContext BC, List<Event> scope){
        System.debug('Executing now...');      
        
        //only run initial feedback if the indicator is on
        if(BR_EventCommunicationHelper.isPendulaActive()){
            
            for(Event ev: scope){
                //everything that comes through the query would be days of event = 1 automatically because the query is based on YESTERDAY
                //so no need additional if statement here (apex datetime calculation seems to be using different timezones)            
                eventDetailsMap.put(ev.Id, ev);
            }
            
            System.debug('Size of eventDetailsMap in execute: ' + eventDetailsMap.size());
            
            //Prepping the data
            getWorker(eventDetailsMap.values());
            getClients(eventDetailsMap.keySet());
            
            //For processing initial survey
            getTheInitialEventToBeSurveyed(validCER);
            
            //insert the surveys here
            Database.SaveResult[] surveys = Database.insert(surveyToInsert, false);
            logResult(surveys); 
        }
    }

    private void getWorker(List<Event> eventIds){
        
        Contact contactToShareEvent = [SELECT Id FROM Contact WHERE LastName = 'to share events'];
        
        for(EventRelation er : [SELECT Id, RelationId, EventId, CreatedDate FROM EventRelation WHERE EventId IN: eventIds AND RelationId != :contactToShareEvent.Id ORDER BY EventId, CreatedDate DESC]){
            eventToWorker.put(er.EventId, er.RelationId); //you only need the earliest created worker for both initial and follow up
        }      

        mapOfWorkers = new Map<Id, Contact>([SELECT Id, enrtcr__Site__c FROM Contact WHERE Id IN: eventToWorker.values()]);
        System.debug('Size of Worker Details map in get workers: ' + mapOfWorkers.size());
    }

    private void getClients(Set<Id> eventIds){       
        //criteria: NDIS clients, Opt out = FALSE, Status = Booked
        validCER = new Map<Id, Client_Event_Relation__c>([SELECT Id, Event_Id__c, Client__c, Status__c FROM Client_Event_Relation__c 
                                                          WHERE Event_Id__c IN: eventIds AND Status__c = 'Booked'
                                                         AND Client__r.Client_Division__c = 'NDIS'
                                                         AND Client__r.Pendula_Survey_Opt_Out__c = FALSE]);        
        
        for(Client_Event_Relation__c cer : validCER.values()){
            cerToEvent.put(cer.Id, cer.Event_Id__c);
            cerToClient.put(cer.Id, cer.Client__c);            
        }
        
        System.debug('Size of validCER map in get clients: ' + validCER.size());
    }    
    
    private void getTheInitialEventToBeSurveyed(Map<Id, Client_Event_Relation__c> allValidCER){
        //This method will run for EACH CER
        //create an initial survey for each valid CER

        for(Client_Event_Relation__c eachCER : allValidCER.values()) {
            //get the event details
            Event events = eventDetailsMap.get(eachCER.Event_Id__c); 

            //get the EARLIEST worker created for that ONE latest event
            //Id earliestWorker = eventToWorker.get(events.Id);
            Contact earliestWorker = mapOfWorkers.get(eventToWorker.get(events.Id));
            
            //create the survey
            createSurvey(events, eachCER, earliestWorker);
        }
    }
    
    private void createSurvey(Event relatedEvent, Client_Event_Relation__c relatedCER, Contact relatedWorker){
        Feedback_Survey__c survey = new Feedback_Survey__c();
        survey.Survey_Sent_Time__c = System.now();
        survey.RecordTypeId = INITIAL_SURVEY;
        survey.Event_Subject__c = relatedEvent.Subject;
        survey.Event_End_DateTime__c = relatedEvent.EndDateTime;        
        survey.Event_Start_DateTime__c = relatedEvent.StartDateTime;
        survey.Recipient__c = relatedCER.Client__c;
        survey.Client_Event_Relation__c = relatedCER.Id;
        survey.Worker__c = relatedWorker.Id;
        survey.Worker_Site__c = relatedWorker?.enrtcr__Site__c;
        surveyToInsert.add(survey); 
    }
    
     //log the database operation result
    private void logResult(Database.SaveResult[] srList){
        // Iterate through each returned result
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                System.debug('Successfully inserted record. Record ID: ' + sr.getId());
            }
            else {
                // Operation failed, so get all errors                
                for(Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Record fields that affected this error: ' + err.getFields());
                }
            }
        }
    }
    
    public void finish(Database.BatchableContext BC){
        System.debug('FINISHING now...');
    }
}