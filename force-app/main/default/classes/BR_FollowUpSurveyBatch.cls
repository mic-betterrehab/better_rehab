public class BR_FollowUpSurveyBatch implements Database.Batchable<SObject> {
	//this batch class will be scheduled weekly to check clients that fulfill the follow up criteria
	//what if 1 or more client doesn't get enough to meet the criteria in any batch? but should be fine since this will be run every week?

    private final Id FOLLOWUP_SURVEY = Schema.SObjectType.Feedback_Survey__c.getRecordTypeInfosByDeveloperName().get('Follow_Up_Client_Survey').getRecordTypeId();
    private final Id INITIAL_SURVEY = Schema.SObjectType.Feedback_Survey__c.getRecordTypeInfosByDeveloperName().get('Initial_Client_Survey').getRecordTypeId();

    Contact contactToShareEvent = [SELECT Id FROM Contact WHERE LastName = 'to share events'];

    Map<Id, Id> cerToClient = new Map<Id, Id>();
    Map<Id, Id> cerToEvent = new Map<Id, Id>();
    Map<Id, Client_Event_Relation__c> cerMapOnly = new Map<Id, Client_Event_Relation__c>();
    Map<Id, Event> eventDetailsMap = new Map<Id, Event>();
    Map<Id, Event> newEventDetailsMap;
    Map<Id, Client_Event_Relation__c> validCER;
    Map<Id, Boolean> clientHasEnoughSessions = new Map<Id, Boolean>();
    Map<Id, Boolean> clientLastSurveyWeeksValid = new Map<Id, Boolean>();
    Map<Id, DateTime> eventIdAndEndDate = new Map<Id, DateTime>();
    Map<Id, Contact> mapOfWorkers;
    Map<Id, Id> eventWorker = new Map<Id, Id>();

    List<Feedback_Survey__c> surveysToInsert = new List<Feedback_Survey__c>();
    Set<Id> clientsToFollowUp = new Set<Id>();
    Map<Id, Client_Event_Relation__c> cerToFollowUp = new Map<Id, Client_Event_Relation__c>();

    List<Event> listOfEvents = new List<Event>();
    Map<Id, Id> smallClientToCERMap = new Map<Id,Id>();
    Map<Id, Map<Id,Id>> bigEventToClientToCERMap = new Map<Id,Map<Id,Id>>();

    List<Client_Event_Relation__c> validCERForCriteria = new List<Client_Event_Relation__c>();

    static final Integer numberOfValidEvents = 6;
    static final Integer numberOfValidWeeks = 8;

    public BR_FollowUpSurveyBatch(){

    }

    //max of 50 million records
    public Database.QueryLocator start(Database.BatchableContext BC){
        //criteria is as set below
        //this query will only get last week's events (scheduled to run weekly)
        //around 1k or more events per week
        return Database.getQueryLocator(
        [
            SELECT Id, Subject, Event_Type__c, StartDateTime, EndDateTime
            FROM Event
                WHERE StartDateTime = LAST_WEEK AND (Event_Type__c = 'Initial Appointment' OR Event_Type__c = 'Therapy Session') AND Event_Status__c = 'Booked'
        ]);
    }

    //by default will process 200 records at once
    public void execute(Database.BatchableContext BC, List<Event> scope){
        System.debug('Executing now...');

        for(Event ev: scope){
            eventDetailsMap.put(ev.Id, ev);
        }

        //this will only contains event from last week, but when you use it in getLatestEventForValidClientsToFollowUp method, you are looking for events beyond last week (older than last week)
        System.debug('Content of eventDetailsMap: ' + eventDetailsMap);

        //getWorker(scope);
        getClients(eventDetailsMap.keySet());
        checkFollowUpCriteria(cerToClient);

        //insert the surveys here
        Database.SaveResult[] surveys = Database.insert(surveysToInsert, false);
        logResult(surveys);
    }

    //process 200 events at once
    private void getWorker(List<Event> eventIds){

        //could retrieve >200 records
        for(EventRelation er : [SELECT Id, RelationId, EventId, CreatedDate FROM EventRelation WHERE EventId IN: eventIds AND RelationId != :contactToShareEvent.Id ORDER BY EventId, CreatedDate DESC]){
            eventWorker.put(er.EventId, er.RelationId); //only the earliest created worker will be added here
        }

        //would retrieve >200 but no more than the SOQL For Loop above
        mapOfWorkers = new Map<Id, Contact>([SELECT Id, enrtcr__Site__c FROM Contact WHERE Id IN: eventWorker.values()]);
    }

    private void getClients(Set<Id> eventIds){
        //making sure that only booked CER are considered
        //could retrieve >200 records
        //criteria: NDIS clients, Opt out = FALSE, Status = Booked
        validCER = new Map<Id, Client_Event_Relation__c>([SELECT Id, Event_Id__c, Client__c, Status__c FROM Client_Event_Relation__c
                                                          WHERE Event_Id__c IN: eventIds AND Status__c = 'Booked'
                                                         AND Client__r.Client_Division__c = 'NDIS'
                                                         AND Client__r.Pendula_Survey_Opt_Out__c = FALSE
                                                         AND Client__r.enrtcr__Status__c = 'Current']);   //make sure that we don't consider inactive clients since the beginning

        //would map >200 records to 2 other maps
        for(Client_Event_Relation__c cer : validCER.values()){
            cerToEvent.put(cer.Id, cer.Event_Id__c);
            //to get the clients in this last week's events
            cerToClient.put(cer.Id, cer.Client__c);
        }
    }

    //process >200 valid CER and >200 cer to client pairs
    private void checkFollowUpCriteria(Map<Id, Id> mapOfCERToClient){
        // get other client deets from this query
        // would retrieve either EQUAL TO or LOWER than the >200 cer to client pairs
        // List<Contact> listOfClients = [SELECT Id FROM Contact WHERE Id IN: mapOfCERToClient.values()];
        Set<Id> uniqueEventId = new Set<Id>();

        //CRITERIA 1
        //find the number of valid cer that each client in the set has based on the valid CER map
        Map<Id, Integer> numberOfValidCERForEachClient = new Map<Id, Integer>();

        //STEP 1: find the number of previous cer from initial/therapy event from ALL TIME for all last week's clients
        List<Client_Event_Relation__c> lists = [SELECT Id, Event_Id__c, Client__c FROM Client_Event_Relation__c WHERE Status__c = 'Booked' AND Client__c IN: mapOfCERToClient.values()
                                                AND Client__r.Client_Division__c = 'NDIS' AND Client__r.Pendula_Survey_Opt_Out__c = FALSE];
        // Map<Id, Client_Event_Relation__c> eventIdToCER = new Map<Id, Client_Event_Relation__c>();

        for (Client_Event_Relation__c cer : lists) {
            uniqueEventId.add(cer.Event_Id__c);
            // eventIdToCER.put(cer.Event_Id__c, cer);
        }

        //filter it to be on the last 8 weeks
        newEventDetailsMap = new Map<Id, Event>([
                                                    SELECT
                                                        Id,
                                                        Event_Type__c,
                                                        Subject,
                                                        StartDateTime,
                                                        EndDateTime,
                                                        WhatId
                                                    FROM Event
                                                    WHERE Id IN: uniqueEventId
                                                    AND EndDateTime = LAST_N_WEEKS:8
                                                    AND (Event_Type__c = 'Initial Appointment' OR Event_Type__c = 'Therapy Session')
                                                ]);

        for(Event e : newEventDetailsMap.values()){
           for (Client_Event_Relation__c cer : lists) {
               if(cer.Event_Id__c == e.Id){
                    //the CER in this map will only be CER from events in the past x weeks
                    validCERForCriteria.add(cer);
               }
            }
        }

        //STEP 2: find the number of valid CER and put them in a map
        for(AggregateResult ar : [SELECT Client__c, COUNT(Id) FROM Client_Event_Relation__c WHERE Id IN: validCERForCriteria AND Client__c IN: mapOfCERToClient.values() GROUP BY Client__c]){
            //will have a list of cliet name - number of cer in the past (in this batch of 200?)
            numberOfValidCERForEachClient.put((Id)ar.get('Client__c'), (Integer)ar.get('expr0'));
        }

        //CRITERIA 2
        //find when is the latest survey that each client has
        Map<Id, Feedback_Survey__c> clientToLastSurvey = new Map<Id, Feedback_Survey__c>();
        Map<Id, Integer> clientToPreviousSurveys = new Map<Id, Integer>();

        for(Feedback_Survey__c s : [SELECT Id, Recipient__c, Survey_Sent_Time__c FROM Feedback_Survey__c WHERE Recipient__c IN: mapOfCERToClient.values() AND (RecordTypeId =: INITIAL_SURVEY OR RecordTypeId =: FOLLOWUP_SURVEY)
                                    ORDER BY Recipient__c, Survey_Sent_Time__c ASC]){
            //ideally this survey should only has 1 entry of client - LATEST survey
            clientToLastSurvey.put(s.Recipient__c, s);
        }

        for(AggregateResult arFS : [SELECT Recipient__c, COUNT(Id) FROM Feedback_Survey__c WHERE Recipient__c IN: mapOfCERToClient.values() AND (RecordTypeId =: INITIAL_SURVEY OR RecordTypeId =: FOLLOWUP_SURVEY) GROUP BY Recipient__c]){
            //will have a list of client name - number of surveys in the past
            clientToPreviousSurveys.put((Id)arFS.get('Recipient__c'), (Integer)arFS.get('expr0'));
        }

        for(Id c : mapOfCERToClient.values()){

            System.debug('Currently processed client id in checking criteria: ' + c);

            //check for criteria 1

            // a safe way to make sure that it's not NULL (but logically all clients will have at least 1 survey (initial survey sent out on their initial assessment))
            if(clientToPreviousSurveys.get(c) != NULL){
                System.debug('Client ID: ' + c + ' has at least 1 Feedback Survey in the past');

                if(numberOfValidCERForEachClient.get(c) >= numberOfValidEvents){
                    clientHasEnoughSessions.put(c, TRUE);
                    System.debug('Client ID: ' + c + ' has enough sessions');
                } else {
                    clientHasEnoughSessions.put(c, FALSE);
                }
            } else {
                System.debug('Client ID: ' + c + ' does NOT have any Feedback Survey in the past');
            }


            //check for criteria 2
            if(clientToLastSurvey.get(c)?.Survey_Sent_Time__c.addDays(numberOfValidWeeks * 7) <= System.now()){
                clientLastSurveyWeeksValid.put(c, TRUE);
                System.debug('Client ID: ' + c + ' has last survey weeks valid');
            } else {
                clientLastSurveyWeeksValid.put(c, FALSE);
            }
        }

        //COMPILING LIST OF CLIENTS
        //add the eligible clients to the surveys
        for(Id eligibleClient : mapOfCERToClient.values()){
            if(clientHasEnoughSessions.get(eligibleClient) == TRUE && clientLastSurveyWeeksValid.get(eligibleClient) == TRUE){
                System.debug('This client is eligible for follow up surveys: ' + eligibleClient);
                clientsToFollowUp.add(eligibleClient);
            } else {
                System.debug('This client is NOT eligible for follow up surveys: ' + eligibleClient);
            }
        }

        getLatestEventForValidClientsToFollowUp(clientsToFollowUp);
    }

    private void getLatestEventForValidClientsToFollowUp(Set<Id> uniqueClient){
        //get the latest cer and event for each client
        // Set<Id> uniqueClient = (new Map<Id,SObject>(validClients)).keySet();
        Map<Id, List<BR_EventSortHelper>> uniqueClientToListEventsSorted = new Map<Id, List<BR_EventSortHelper>>();

        for(Id c : uniqueClient){
            List<Event> eventsForAClient = new List<Event>();

            System.debug('In getLatestEventForValidClientsToFollowUp, current uniqueClient ID is: ' + c);
            System.debug('In getLatestEventForValidClientsToFollowUp, size of validCERForCriteria: ' + validCERForCriteria.size());

            for(Client_Event_Relation__c cer : [SELECT Id, Event_Id__c, Client__c FROM Client_Event_Relation__c WHERE Id IN: validCERForCriteria AND Client__c IN: uniqueClient]){
                if(cer.Client__c == c){
                    System.debug('In getLatestEventForValidClientsToFollowUp, content of cer.Event_Id__c: ' + cer.Event_Id__c);
                    System.debug('In getLatestEventForValidClientsToFollowUp, content of newEventDetailsMap.get(cer.Event_Id__c): ' + newEventDetailsMap.get(cer.Event_Id__c));
                    eventsForAClient.add(newEventDetailsMap.get(cer.Event_Id__c));
                }
            }

            System.debug('In getLatestEventForValidClientsToFollowUp, size of eventsForAClient: ' + eventsForAClient.size());
            System.debug('In getLatestEventForValidClientsToFollowUp, content of eventsForAClient: ' + eventsForAClient);


            //sort the list of events based on end date (latest event will be at the start)
            BR_EventSortHelper[] evList = new List<BR_EventSortHelper>();
            //Check the list of events
            for (Event e : eventsForAClient){
                System.debug('In getLatestEventForValidClientsToFollowUp, currently processing this event: ' + e.Id); //why is the event id null?
                evList.add(new BR_EventSortHelper(e));
            }

            System.debug('In getLatestEventForValidClientsToFollowUp, size of evList: ' + evList.size());

            //Check result of the sorting
            evList.sort();
            //System.debug(evList); //this should be sorted now

            //after you are done sorting, put it in a map
            uniqueClientToListEventsSorted.put(c, evList); //after the uniqueClient loop ends, this map should have a key of client ID - value of list of events sorted by end date desc
        }

        List<Event> finalLatestEvents = new List<Event>();

        //create the survey for each client in the map
        for(Id clientId : uniqueClientToListEventsSorted.keySet()){
            finalLatestEvents.add(uniqueClientToListEventsSorted.get(clientId)[0].e);
        }

        //call getworker here to find the workers to be put in the survey
        getWorker(finalLatestEvents);

        //create the survey for each client in the map
        for(Id clientId : uniqueClientToListEventsSorted.keySet()){
            createSurvey(clientId, uniqueClientToListEventsSorted.get(clientId)[0]);
        }

    }

    public void createSurvey(Id clientId, BR_EventSortHelper latestEvent){
        System.debug('Now inside createSurvey for client ID: ' + clientId);

        //create the survey
        //Follow up surveys DO NOT have CER connected to them. Just a client contact and the latest event that they attended (booked)
        Feedback_Survey__c survey = new Feedback_Survey__c();
        survey.Survey_Sent_Time__c = System.now();
        survey.RecordTypeId = FOLLOWUP_SURVEY;
        survey.Event_Subject__c = latestEvent.e.Subject;
        survey.Event_End_DateTime__c = latestEvent.e.EndDateTime;
        survey.Event_Start_DateTime__c = latestEvent.e.StartDateTime;
        survey.Recipient__c = clientId;
        survey.Worker_Site__c = mapOfWorkers.get(eventWorker.get(latestEvent.e.Id))?.enrtcr__Site__c;
        survey.Worker__c = eventWorker.get(latestEvent.e.Id);

        surveysToInsert.add(survey);
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
        //query the table that lists information about batch jobs
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors,
                            JobItemsProcessed,
                            JobType,
                            TotalJobItems, CreatedBy.Email
                            FROM AsyncApexJob
                            WHERE Id = :bc.getJobId()];
        // call some utility to print
        System.debug(job);
    }
}