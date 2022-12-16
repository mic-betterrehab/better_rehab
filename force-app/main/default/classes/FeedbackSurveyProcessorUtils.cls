/**
 * Created by ersoz on 9/12/20.
 */

public with sharing class FeedbackSurveyProcessorUtils {

    public static final Id recordTypeIdInitial = Schema.SObjectType.Customer_Feedback_Survey__c.getRecordTypeInfosByDeveloperName().get('Initial').getRecordTypeId();
    public static final Id recordTypeIdFollowUp = Schema.SObjectType.Customer_Feedback_Survey__c.getRecordTypeInfosByDeveloperName().get('Follow_up').getRecordTypeId();

    public static Customer_Feedback_Survey__c createSurvey (
            enrtcr__Session__c session,
            Id clientId,
            Id workerId,
            String surveyType) {

        return new Customer_Feedback_Survey__c(
                Session__c = session.Id,
                Session_End_Datetime__c = session.enrtcr__End_Date__c,
                Send_First_Question__c = true,
                First_Question_Sent__c = Datetime.now(),
                Recipient__c = clientId,
                Profession__c = !String.isEmpty(session.Workers_and_Professions__c) ? session.Workers_and_Professions__c.substringBetween('(', ')') : null,
                Worker_Site__c = session.Worker_Site__c,
                Worker__c = workerId,
                RecordTypeId = surveyType == 'Initial' ? recordTypeIdInitial : recordTypeIdFollowUp,
                Survey_Type__c = surveyType
        );
    }

    public class SurveyMapping {

        public Map<Id, List<Id>> sessionIdToClientsForFollowUp;
        public Map<Id, Set<Id>> sessionIdToClientsForInitial;
        public Map<Id, List<Id>> clientIdToSessionsForInitial;
        public Map<Id, List<Id>> clientIdToSessionsForFollowUp;

        public Map<Id, enrtcr__Session__c> sessionMap;
        public Map<Id, Id> sessionToWorker;
        public Set<Id> clientIds;

        public Map<Id,List<enrtcr__Session__c>> clientIdToSessions;
        public Map<Id,List<Customer_Feedback_Survey__c>> clientIdToFollowUpSurveys;
    }

    public static SurveyMapping buildMappings ( List<enrtcr__Session__c> sessions ) {

        SurveyMapping surveyMapping = new SurveyMapping();

        Map<Id, enrtcr__Session__c> sessionMap = new Map<Id, enrtcr__Session__c>();
        Map<Id, List<Id>> sessionIdToClientsForFollowUp = new Map<Id, List<Id>>();
        Map<Id, Set<Id>> sessionIdToClientsForInitial = new Map<Id, Set<Id>>();
        Map<Id, List<Id>> clientIdToSessionsForInitial = new Map<Id, List<Id>>();
        Map<Id, List<Id>> clientIdToSessionsForFollowUp = new Map<Id, List<Id>>();
        Map<Id, Id> sessionToWorker = new Map<Id, Id>();
        Set<Id> clientIds = new Set<Id>();

        /**
         ********************************************* General mappings **********************************************
        */

        for (enrtcr__Session__c session : sessions) {

            //create a session map
            sessionMap.put(session.Id, session);

            for (enrtcr__Client_Appointment__c clientAppointment : session.enrtcr__Client_Appointments__r) {

                //grab client ids
                clientIds.add(clientAppointment.enrtcr__Client__c);

                if (session.enrtcr__Service_Types__c == 'Initial Assessment') {

                    //mapping clients to their sessions for initial survey
                    List<Id> sessionIds = clientIdToSessionsForInitial.get(clientAppointment.enrtcr__Client__c);

                    if (sessionIds == null) {

                        sessionIds = new List<Id>();
                        clientIdToSessionsForInitial.put(clientAppointment.enrtcr__Client__c, sessionIds);
                    }
                    sessionIds.add(clientAppointment.enrtcr__Session__c);


                    //mapping sessions to their clients for initial survey
                    Set<Id> clientIdsForInitial = sessionIdToClientsForInitial.get(clientAppointment.enrtcr__Session__c);

                    if (clientIdsForInitial == null) {

                        clientIdsForInitial = new Set<Id>();
                        sessionIdToClientsForInitial.put(clientAppointment.enrtcr__Session__c, clientIdsForInitial);
                    }
                    clientIdsForInitial.add(clientAppointment.enrtcr__Client__c);
                } else {

                    //mapping clients to their sessions for followup survey
                    List<Id> sessionIds = clientIdToSessionsForFollowUp.get(clientAppointment.enrtcr__Client__c);

                    if (sessionIds == null) {

                        sessionIds = new List<Id>();
                        clientIdToSessionsForFollowUp.put(clientAppointment.enrtcr__Client__c, sessionIds);
                    }
                    sessionIds.add(clientAppointment.enrtcr__Session__c);


                    //mapping sessions to their clients for followup survey
                    List<Id> clientIdsForFollowUp = sessionIdToClientsForFollowUp.get(clientAppointment.enrtcr__Session__c);

                    if (clientIdsForFollowUp == null) {

                        clientIdsForFollowUp = new List<Id>();
                        sessionIdToClientsForFollowUp.put(clientAppointment.enrtcr__Session__c, clientIdsForFollowUp);
                    }
                    clientIdsForFollowUp.add(clientAppointment.enrtcr__Client__c);
                }
            }

            //since a session may have multiple workers, we grab the first one
            //and map the session to that worker
            for (enrtcr__Worker_Appointment__c workerAppointment : session.enrtcr__Worker_Appointments__r) {

                sessionToWorker.put(session.Id, workerAppointment.enrtcr__Worker__r.Id);
                break;
            }
        }

        /**
        ****************************** Mappings specific to Follow up Survey creation ******************************
        *  1-Find all sessions of the clients within 8 weeks
        *  2-Find all follow up surveys of the clients
        */

        // mapping sessions to their appointments
        Map<Id,List<enrtcr__Client_Appointment__c>> sessionToAppointments = new Map<Id, List<enrtcr__Client_Appointment__c>>();

        for(enrtcr__Client_Appointment__c clientAppointment : QueryTool.findClientAppointmentsByClientIds(clientIds)){

            List<enrtcr__Client_Appointment__c> appointments = sessionToAppointments.get(clientAppointment.enrtcr__Session__c);

            if (appointments == null) {

                appointments = new List<enrtcr__Client_Appointment__c>();

                sessionToAppointments.put(clientAppointment.enrtcr__Session__c, appointments);
            }
            appointments.add(clientAppointment);
        }

        //clients to sessions map
        Map<Id,List<enrtcr__Session__c>> clientIdToSessions = new Map<Id, List<enrtcr__Session__c>>();

        //find all the sessions within 8 weeks that the clients have
        for(enrtcr__Session__c newSession : QueryTool.findAllSessionsWithinEightWeeksByIds(sessionToAppointments.keySet())){

            // get the appointments
            List<enrtcr__Client_Appointment__c> appointments = sessionToAppointments.get(newSession.Id);

            if(appointments != null){

                // loop over appointments
                for(enrtcr__Client_Appointment__c clientAppointment : appointments){

                    // and clients to sessions
                    List<enrtcr__Session__c> newSessions = clientIdToSessions.get(clientAppointment.enrtcr__Client__c);

                    if (newSessions == null) {

                        newSessions = new List<enrtcr__Session__c>();

                        clientIdToSessions.put(clientAppointment.enrtcr__Client__c, newSessions);
                    }
                    newSessions.add(newSession);
                }
            }
        }

        //clients to Follow up surveys map
        Map<Id,List<Customer_Feedback_Survey__c>> clientIdToFollowUpSurveys = new Map<Id, List<Customer_Feedback_Survey__c>>();

        //find existing follow up surveys of the clients
        //and map the clients to those surveys
        for(Customer_Feedback_Survey__c followUpSurvey : QueryTool.findFollowUpSurveysByClientIds(clientIds)){

            List<Customer_Feedback_Survey__c> followUpSurveys = clientIdToFollowUpSurveys.get(followUpSurvey.Recipient__c);

            if (followUpSurveys == null) {

                followUpSurveys = new List<Customer_Feedback_Survey__c>();

                clientIdToFollowUpSurveys.put(followUpSurvey.Recipient__c, followUpSurveys);
            }
            followUpSurveys.add(followUpSurvey);
        }

        /******************************** Set the Survey Mapping properties *******************************/

        surveyMapping.clientIds = clientIds;
        surveyMapping.sessionMap = sessionMap;
        surveyMapping.sessionIdToClientsForInitial = sessionIdToClientsForInitial;
        surveyMapping.sessionIdToClientsForFollowUp = sessionIdToClientsForFollowUp;
        surveyMapping.clientIdToSessionsForInitial = clientIdToSessionsForInitial;
        surveyMapping.clientIdToSessionsForFollowUp = clientIdToSessionsForFollowUp;
        surveyMapping.sessionToWorker = sessionToWorker;
        surveyMapping.clientIdToSessions = clientIdToSessions;
        surveyMapping.clientIdToFollowUpSurveys = clientIdToFollowUpSurveys;

        System.debug('surveyMapping.clientIds ===> ' + clientIds);
        System.debug('surveyMapping.sessionMap ===> ' + sessionMap);
        System.debug('surveyMapping.sessionIdToClientsForInitial ===> ' + sessionIdToClientsForInitial);
        System.debug('surveyMapping.sessionIdToClientsForFollowUp ===> ' + sessionIdToClientsForFollowUp);
        System.debug('surveyMapping.clientIdToSessionsForInitial ===> ' + clientIdToSessionsForInitial);
        System.debug('surveyMapping.clientIdToSessionsForFollowUp ===> ' + clientIdToSessionsForFollowUp);
        System.debug('surveyMapping.sessionToWorker ===> ' + sessionToWorker);
        System.debug('surveyMapping.clientIdToSessions ===> ' + clientIdToSessions);
        System.debug('surveyMapping.clientIdToFollowUpSurveys ===> ' + clientIdToFollowUpSurveys);

        return surveyMapping;
    }
}