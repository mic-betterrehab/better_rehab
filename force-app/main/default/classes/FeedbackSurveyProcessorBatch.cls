/***********************************************************************************************************************
 * Name: FeedbackSurveyProcessorBatch
 * Description: Batch class of Feedback Survey Processor Job.
 *
 * Version History
 * Date             Developer           Comments
 * --------------- ------------------- -------------------------------------------------------------------------------
 * 2020-02-11      Can Ersoz           Created. Create Survey records for the clients sit on the related sessions
 **********************************************************************************************************************/

global without sharing class FeedbackSurveyProcessorBatch implements Database.Batchable<SObject> {

    global FeedbackSurveyProcessorBatch(){}

    global Database.QueryLocator start(Database.BatchableContext ctx){

        return Database.getQueryLocator(
        [
                SELECT Id,
                        enrtcr__Start_Date__c,
                        enrtcr__End_Date__c,
                        enrtcr__Service_Types__c,
                        Worker_Site__c,
                        Workers_and_Professions__c,
                (
                        SELECT Id,
                                enrtcr__Client__c,
                                enrtcr__Session__c,
                                enrtcr__Client__r.Client_Division__c,
                                enrtcr__Client__r.Pendula_Survey_Opt_Out__c
                        FROM enrtcr__Client_Appointments__r
                        WHERE enrtcr__Client__r.Client_Division__c = 'NDIS'
                        AND enrtcr__Client__r.Pendula_Survey_Opt_Out__c = FALSE
                ),
                (
                        SELECT Id,
                                enrtcr__Worker__r.Id
                        FROM enrtcr__Worker_Appointments__r
                )
                FROM enrtcr__Session__c
                WHERE  enrtcr__Status__c != 'Cancelled'
                AND Days_After_End_Date__c = 1
                ORDER BY enrtcr__End_Date__c DESC
        ]);
    }

    global void execute(Database.BatchableContext ctx, List<enrtcr__Session__c> scope){

        FeedbackSurveyProcessorUtils.SurveyMapping surveyMapping = FeedbackSurveyProcessorUtils.buildMappings(scope);

        Set<Id> clientIds = surveyMapping.clientIds;
        Map<Id,enrtcr__Session__c> sessionMap = surveyMapping.sessionMap;
        Map<Id,List<Id>> sessionIdToClientsForFollowUp = surveyMapping.sessionIdToClientsForFollowUp;
        Map<Id,Set<Id>> sessionIdToClientsForInitial = surveyMapping.sessionIdToClientsForInitial;
        Map<Id,List<Id>> clientIdToSessionsForInitial = surveyMapping.clientIdToSessionsForInitial;
        Map<Id,List<Id>> clientIdToSessionsForFollowUp = surveyMapping.clientIdToSessionsForFollowUp;
        Map<Id,Id> sessionToWorker = surveyMapping.sessionToWorker;

        Map<Id,List<Customer_Feedback_Survey__c>> clientIdToFollowUpSurveys = surveyMapping.clientIdToFollowUpSurveys;

        // clients to their all sessions map for followup surveys
        Map<Id,List<enrtcr__Session__c>> clientIdToAllSessions = surveyMapping.clientIdToSessions;

        //follow up surveys to generate
        Set<Id> clientsForFollowUpSurvey = new Set<Id>();

        //surveys to generate
        List<Customer_Feedback_Survey__c> surveysToInsert = new List<Customer_Feedback_Survey__c>();

        //iterate over requests (sessions)
        for (enrtcr__Session__c session : (List<enrtcr__Session__c>)scope) {

            //get the client list that we generate initial survey for
            Set<Id> clientsAssignedToThisSessionForInitial = sessionIdToClientsForInitial.get(session.Id);

            System.debug('clientsAssignedToThisSessionForInitial ===> ' + clientsAssignedToThisSessionForInitial);

            //fill the list with initial surveys
            if(clientsAssignedToThisSessionForInitial != null){

                for (Id clientId : clientsAssignedToThisSessionForInitial) {

                    Id workerId = sessionToWorker.get(session.Id);

                    surveysToInsert.add(
                            FeedbackSurveyProcessorUtils.createSurvey(
                                    session,
                                    clientId,
                                    workerId,
                                    'Initial'
                            )
                    );
                }
            }

            //get the client list that we generate follow up survey for
            List<Id> clientsAssignedToThisSessionForFollowUp = sessionIdToClientsForFollowUp.get(session.Id);

            System.debug('clientsAssignedToThisSessionForFollowUp ===> ' + clientsAssignedToThisSessionForFollowUp);

            if(clientsAssignedToThisSessionForFollowUp != null){

                for (Id clientId : clientsAssignedToThisSessionForFollowUp) {

                    List<enrtcr__Session__c> clientSessions = clientIdToAllSessions.get(clientId);
                    List<Customer_Feedback_Survey__c> followUpSurveys = clientIdToFollowUpSurveys.get(clientId);
                    Long daysElapsedFromTheLast = 0;

                    System.debug('clientSessions ===> ' + clientSessions);
                    System.debug('followUpSurveys ===> ' + followUpSurveys);
                    System.debug('clientSessions.size() ===> ' + clientSessions.size());

                    if(followUpSurveys != null){

                        //get the most recent follow up survey for this client
                        //the list comes through in descending order, so we can get the first element
                        //and calculate the days elapsed from the last follow up survey sent out to this client
                        daysElapsedFromTheLast = SessionUtil.calculateTimeBetween(
                                followUpSurveys[0].First_Question_Sent__c,
                                Datetime.now(),
                                SessionUtil.TimeUnit.DAYS
                        );

                        System.debug('daysElapsedFromTheLast ' + daysElapsedFromTheLast);
                    }

                    //check that clients have at least 6 sessions
                    //and create follow up surveys for those who have follow up surveys and 8 weeks passed from the last sent
                    // OR have no follow up survey
                    if (clientSessions != null && clientSessions.size() >= 6 && (followUpSurveys == null || daysElapsedFromTheLast == 56)){

                        clientsForFollowUpSurvey.add(clientId);
                    }
                }
            }
        }

        System.debug('Initial Surveys To Insert ===> '+ surveysToInsert.size());
        System.debug('Follow Up Surveys To Insert ===> '+ clientsForFollowUpSurvey.size());

        //iterate over clients to generate follow up survey
        for(Id clientId :clientsForFollowUpSurvey){

            //get the sessions of the client
            List<Id> sessionIds = clientIdToSessionsForFollowUp.get(clientId);

            //we grab the first created Session
            enrtcr__Session__c relatedSession = sessionMap.get(sessionIds[0]);

            Id workerId = sessionToWorker.get(relatedSession.Id);

            surveysToInsert.add(
                    FeedbackSurveyProcessorUtils.createSurvey(
                            relatedSession,
                            clientId,
                            workerId,
                            'Follow up'
                    )
            );
        }

        if(!surveysToInsert.isEmpty()) insert surveysToInsert;

        update scope;
    }

    // The batch job finishes
    global void finish(Database.BatchableContext ctx){ }
}