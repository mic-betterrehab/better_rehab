/**
 * Created by ersoz on 2019-05-15.
 */

public class SessionHandler {

    private enum SessionType {
        BOOKED, TIME_CHANGED, CANCELLED
    }

    private final Id NON_RECURRING_RECORDTYPE_ID_BOOKED = Schema.SObjectType.Session_Communication__c.getRecordTypeInfosByDeveloperName().get('Appointment_Booked').getRecordTypeId();
    private final Id RECURRING_RECORDTYPE_ID_BOOKED = Schema.SObjectType.Session_Communication__c.getRecordTypeInfosByDeveloperName().get('Recurrence_Confirmation').getRecordTypeId();
    private final Id NON_RECURRING_RECORDTYPE_ID_TIMECHANGED = Schema.SObjectType.Session_Communication__c.getRecordTypeInfosByDeveloperName().get('Appointment_Time_Changed').getRecordTypeId();
    private final Id RECURRING_RECORDTYPE_ID_TIMECHANGED = Schema.SObjectType.Session_Communication__c.getRecordTypeInfosByDeveloperName().get('Recurrence_Changed').getRecordTypeId();
    private final Id RECORD_TYPE_ID_CANCELLED = Schema.SObjectType.Session_Communication__c.getRecordTypeInfosByDeveloperName().get('Appointment_Cancelled').getRecordTypeId();

    private final String STATUS_ROSTERED = 'Rostered';
    private final String STATUS_CANCELLED = 'Cancelled';

    //Mapping Session Id to Recurrence Id
    private Map<Id, Id> sessionIdToRecurrenceId;
    //Mapping parent session Id to its appointments
    private Map<Id, List<enrtcr__Client_Appointment__c>> parentSessionIdToAppointments;
    //Mapping child session Id to its appointments
    private Map<Id, List<enrtcr__Client_Appointment__c>> childSessionIdToAppointments;

    public SessionHandler(Map<Id, enrtcr__Session__c> newMap, Map<Id, enrtcr__Session__c> oldMap){

        this.parentSessionIdToAppointments = new Map<Id, List<enrtcr__Client_Appointment__c>>();
        this.sessionIdToRecurrenceId = new Map<Id, Id>();
        this.childSessionIdToAppointments = new Map<Id, List<enrtcr__Client_Appointment__c>>();
        this.afterUpdate(newMap, oldMap);
    }

    private void afterUpdate(Map<Id, enrtcr__Session__c> newMap, Map<Id, enrtcr__Session__c> oldMap) {

        List<enrtcr__Session__c> sessionsRostered = new List<enrtcr__Session__c>();
        List<enrtcr__Session__c> sessionsCancelled = new List<enrtcr__Session__c>();
        List<enrtcr__Session__c> sessionsTimeChanged = new List<enrtcr__Session__c>();

        Set<Id> parentSessionIds = new Set<Id>();
        Set<Id> childSessionIds = new Set<Id>();

        for (enrtcr__Session__c session : newMap.values()) {

            enrtcr__Session__c oldSession = oldMap.get(session.Id);

            //List of Rostered Sessions
            if (session.enrtcr__Status__c != oldSession.enrtcr__Status__c && session.enrtcr__Status__c == STATUS_ROSTERED) {
                sessionsRostered.add(session);
            }
            //List of Time Changed Sessions
            if (session.enrtcr__Start_Date__c != oldSession.enrtcr__Start_Date__c && oldSession.enrtcr__Status__c == STATUS_ROSTERED) {
                sessionsTimeChanged.add(session);
            }
            //List of Cancelled Sessions
            if (session.enrtcr__Status__c != oldSession.enrtcr__Status__c && session.enrtcr__Status__c == STATUS_CANCELLED) {
                sessionsCancelled.add(session);
            }

            //List of Parent Session Ids to find their appointments in below
            if (session.enrtcr__Parent_Session__c == null) {
                parentSessionIds.add(session.Id);

                //Mapping Session Id to Recurrence Id in order to pull information on Session Communication
                if (session.enrtcr__Recurrence__c != null) sessionIdToRecurrenceId.put(session.Id, session.enrtcr__Recurrence__c);
            }
            else{
                parentSessionIds.add(session.enrtcr__Parent_Session__c);
                childSessionIds.add(session.Id);
            }
        }

        //Mapping parent and child sessions Ids to their appointments
        if (!parentSessionIds.isEmpty()) {
            parentSessionIdToAppointments = getAppointmentsOfSessionsBySessionId(parentSessionIds);
        }

        if (!childSessionIds.isEmpty()) {
            childSessionIdToAppointments = getAppointmentsOfSessionsBySessionId(childSessionIds);
        }

        categorizeSessions(sessionsRostered, SessionType.BOOKED);
        categorizeSessions(sessionsTimeChanged, SessionType.TIME_CHANGED);
        categorizeSessions(sessionsCancelled, SessionType.CANCELLED);
    }

    private void categorizeSessions(List<enrtcr__Session__c> sessions, SessionType flowType) {

        List<enrtcr__Session__c> nonRecurringSessions = new List<enrtcr__Session__c>();
        Map<Id, List<enrtcr__Session__c>> parentSessionIdToChildren = new Map<Id, List<enrtcr__Session__c>>();
        for (enrtcr__Session__c session : sessions) {

            //Categorize Sessions as Non Recurring and Recurring
            if (session.enrtcr__Parent_Session__c == null) {
                nonRecurringSessions.add(session);
            }
            else {
                Id parentSessionId = session.enrtcr__Parent_Session__c;
                List<enrtcr__Session__c> childRecurringSessions = parentSessionIdToChildren.get(parentSessionId);

                //Mapping ParentId to its Children
                if (childRecurringSessions == null) {
                    childRecurringSessions = new List<enrtcr__Session__c>();
                    parentSessionIdToChildren.put(parentSessionId, childRecurringSessions);
                }
                childRecurringSessions.add(session);
            }
        }

        List<enrtcr__Session__c> oneOffTimeChangedSessions = new List<enrtcr__Session__c>();
        List<enrtcr__Session__c> oneOffCancelledSessions= new List<enrtcr__Session__c>();
        List<List<enrtcr__Session__c>> recurringSessions = new List<List<enrtcr__Session__c>>();

        for (Id parentSessionId : parentSessionIdToChildren.keySet()) {

            List<enrtcr__Session__c> childSessions = parentSessionIdToChildren.get(parentSessionId);

            //Determine whether it is one off time change or it effects the future
            if (flowType == SessionType.TIME_CHANGED && childSessions.size() == 1){
                oneOffTimeChangedSessions.add(childSessions[0]);
            }
            //We want to cancel the sessions individually, not to effect the future
            else if (flowType == SessionType.CANCELLED && childSessions.size() == 1){

                oneOffCancelledSessions.add(childSessions[0]);
            }
            else{
                recurringSessions.add(childSessions);
            }
        }

        //Creation of Session Communications and their Recurrences
        if (flowType == SessionType.BOOKED) {

            if (!nonRecurringSessions.isEmpty()) {
                createSessionCommunicationsForNonRecurringSessions(nonRecurringSessions, NON_RECURRING_RECORDTYPE_ID_BOOKED);
            }
            if (!recurringSessions.isEmpty()) {
                createSessionCommunicationsForRecurringSessions(recurringSessions, RECURRING_RECORDTYPE_ID_BOOKED);
            }
        }
        if (flowType == SessionType.TIME_CHANGED) {

            if (!nonRecurringSessions.isEmpty()) {
                createSessionCommunicationsForNonRecurringSessions(nonRecurringSessions, NON_RECURRING_RECORDTYPE_ID_TIMECHANGED);
            }
            if (!oneOffTimeChangedSessions.isEmpty()) {
                createSessionCommunicationsForOneOffRecurringSessions(oneOffTimeChangedSessions, NON_RECURRING_RECORDTYPE_ID_TIMECHANGED);
            }
            if (!recurringSessions.isEmpty()) {
                createSessionCommunicationsForRecurringSessions(recurringSessions, RECURRING_RECORDTYPE_ID_TIMECHANGED);
            }
        }
        if(flowType == SessionType.CANCELLED) {

            if (!nonRecurringSessions.isEmpty()) {
                createSessionCommunicationsForNonRecurringSessions(nonRecurringSessions, RECORD_TYPE_ID_CANCELLED);
            }
            if (!oneOffCancelledSessions.isEmpty()) {
                createSessionCommunicationsForOneOffCancelledRecurringSessions(oneOffCancelledSessions, RECORD_TYPE_ID_CANCELLED);
            }
        }
    }

    private void createSessionCommunicationsForNonRecurringSessions(
            List<enrtcr__Session__c> sessions,
            Id recordTypeId
    ) {

        List<Session_Communication__c> sComsToInsert = new List<Session_Communication__c>();

        for (enrtcr__Session__c session : sessions) {
            //List of appointments of Parent Session Id to create Session Communication
            List<enrtcr__Client_Appointment__c> appointments = parentSessionIdToAppointments.get(session.Id);

            if(appointments != null) {
                for (enrtcr__Client_Appointment__c appointment : appointments) {

                    Session_Communication__c newScom = createSessionCommunication(
                            appointment.enrtcr__Session__c,
                            appointment.Id,
                            appointment.enrtcr__Client__c,
                            null,
                            recordTypeId
                    );
                    sComsToInsert.add(newScom);
                }
            }
        }
        if (!sComsToInsert.isEmpty()) insert sComsToInsert;
    }

    private void createSessionCommunicationsForOneOffCancelledRecurringSessions(
            List<enrtcr__Session__c> sessions,
            Id recordTypeId
    ) {

        List<Session_Communication__c> sComsToInsert = new List<Session_Communication__c>();

        for (enrtcr__Session__c session : sessions) {
            //List of appointments of Child Session Id to create Session Communication
            List<enrtcr__Client_Appointment__c> appointments = childSessionIdToAppointments.get(session.Id);

            if(appointments != null) {
                for (enrtcr__Client_Appointment__c appointment : appointments) {

                    Session_Communication__c newScom = createSessionCommunication(
                            appointment.enrtcr__Session__c,
                            appointment.Id,
                            appointment.enrtcr__Client__c,
                            null,
                            recordTypeId
                    );
                    sComsToInsert.add(newScom);
                }
            }
        }
        if (!sComsToInsert.isEmpty()) insert sComsToInsert;
    }

    private void createSessionCommunicationsForOneOffRecurringSessions(
            List<enrtcr__Session__c> sessions,
            Id recordTypeId
    ) {

        List<Session_Communication__c> sComsToInsert = new List<Session_Communication__c>();

        for (enrtcr__Session__c session : sessions) {
            //List of appointments of Parent Session Id to create Session Communication
            //Parent Session Id is used to get the appointments as the session is a part of the Series
            List<enrtcr__Client_Appointment__c> appointments = parentSessionIdToAppointments.get(session.enrtcr__Parent_Session__c);

            if(appointments != null) {
                for (enrtcr__Client_Appointment__c appointment : appointments) {

                    Session_Communication__c newScom = createSessionCommunication(
                            appointment.enrtcr__Session__c,
                            appointment.Id,
                            appointment.enrtcr__Client__c,
                            null,
                            recordTypeId
                    );
                    sComsToInsert.add(newScom);
                }
            }
        }
        if (!sComsToInsert.isEmpty()) insert sComsToInsert;
    }

    private void createSessionCommunicationsForRecurringSessions(
            List<List<enrtcr__Session__c>> sessions,
            Id recordTypeId
    ) {

        Map<Id, Session_Communication__c> sessionCommunicationMasterDetails = new Map<Id, Session_Communication__c>();

        for (List<enrtcr__Session__c> recurringSessionsList : sessions) {

            //Iterate over every Child sessions list of lists, so we can get the first element and make the Master Detail object
            enrtcr__Session__c recurring = recurringSessionsList.get(0);
            Id recurrenceId = sessionIdToRecurrenceId.get(recurring.enrtcr__Parent_Session__c);

            //List of appointments of Parent Session Id to create Session Communication
            List<enrtcr__Client_Appointment__c> apps = parentSessionIdToAppointments.get(recurring.enrtcr__Parent_Session__c);

            if(apps != null) {
                for (enrtcr__Client_Appointment__c app : apps) {

                    Session_Communication__c newScom = createSessionCommunication(
                            app.enrtcr__Session__c,
                            app.Id,
                            app.enrtcr__Client__c,
                            recurrenceId,
                            recordTypeId
                    );

                    //Mapping appointment Id to the new object we're going to create
                    sessionCommunicationMasterDetails.put(
                            app.Id,
                            newScom
                    );
                }
            }
        }

        insert sessionCommunicationMasterDetails.values();

        List<Session_Recurrence_Communication__c> sComRecurrenceToInsert = new List<Session_Recurrence_Communication__c>();

        for (List<enrtcr__Session__c> recurringSessionsList : sessions) {

            for (enrtcr__Session__c session : recurringSessionsList) {

                List<enrtcr__Client_Appointment__c> apps = parentSessionIdToAppointments.get(session.enrtcr__Parent_Session__c);

                if(apps != null) {
                    for (enrtcr__Client_Appointment__c app : apps) {
                        //Getting related Session Communication Id to create Session Recurrence Communications
                        Session_Communication__c masterDetailSession = sessionCommunicationMasterDetails.get(app.Id);
                        sComRecurrenceToInsert.add(
                                new Session_Recurrence_Communication__c(
                                        Session_Communication__c = masterDetailSession.Id
                                )
                        );
                    }
                }
            }
        }
        if (!sComRecurrenceToInsert.isEmpty()) insert sComRecurrenceToInsert;
    }

    private Map<Id, List<enrtcr__Client_Appointment__c>> getAppointmentsOfSessionsBySessionId(Set<Id> sessionIds) {

        //Mapping Parent Session Id to it Appointments
        Map<Id, List<enrtcr__Client_Appointment__c>> sessionIdToAppointments = new Map<Id, List<enrtcr__Client_Appointment__c>>();

        for (enrtcr__Client_Appointment__c app : [SELECT Id,enrtcr__Session__c,enrtcr__Client__c
                                                  FROM enrtcr__Client_Appointment__c
                                                  WHERE enrtcr__Session__c IN :sessionIds]
        ) {

            List<enrtcr__Client_Appointment__c> clientAppointments = sessionIdToAppointments.get(app.enrtcr__Session__c);
            if (clientAppointments == null) {

                clientAppointments = new List<enrtcr__Client_Appointment__c>();
                sessionIdToAppointments.put(app.enrtcr__Session__c, clientAppointments);
            }
            clientAppointments.add(app);
        }
        return sessionIdToAppointments;
    }

    private Session_Communication__c createSessionCommunication(Id sessionId,
            Id clientAppointmentId,
            Id contactId,
            Id recurrenceId,
            Id recordTypeId){
        return new Session_Communication__c(Session__c = sessionId,
                Client_Appointment__c = clientAppointmentId,
                Contact__c = contactId,
                Recurrence__c = recurrenceId,
                RecordTypeId = recordTypeId
        );
    }
}