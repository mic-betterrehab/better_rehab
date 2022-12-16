/**
 * Created by ersoz on 2019-05-30.
 */
global class SessionReminderJob implements Schedulable {

    private final Id RECORD_TYPE_ID_LATE_CHECK_IN = Schema.SObjectType.Session_Communication__c.getRecordTypeInfosByDeveloperName().get('Late_Checkin').getRecordTypeId();
    private final Id RECORD_TYPE_ID_LATE_CHECK_OUT = Schema.SObjectType.Session_Communication__c.getRecordTypeInfosByDeveloperName().get('Late_Checkout').getRecordTypeId();

    public SessionReminderJob() {}

    public void execute(SchedulableContext ctx) {

        List<enrtcr__Worker_Appointment__c> workerAppointments = QueryTool.findAllWorkerAppointmentsForLateChecks();

        Set<Id> workerAppointmentIds = new Set<Id>();

        for (enrtcr__Worker_Appointment__c workerAppointment : workerAppointments){

            workerAppointmentIds.add(workerAppointment.Id);
        }

        Map<Id, List<Session_Communication__c>> appIdToSessionComms = new Map<Id, List<Session_Communication__c>>();

        for(Session_Communication__c sessionCommunication : QueryTool.findSessionCommunicationsByWorkerAppId(
                workerAppointmentIds,
                RECORD_TYPE_ID_LATE_CHECK_IN,
                RECORD_TYPE_ID_LATE_CHECK_OUT)){


            List<Session_Communication__c> sessionCommunications = appIdToSessionComms.get(sessionCommunication.Worker_Appointment__c);

            if (sessionCommunications == null) {

                sessionCommunications = new List<Session_Communication__c>();
                appIdToSessionComms.put(sessionCommunication.Worker_Appointment__c, sessionCommunications);
            }
            sessionCommunications.add(sessionCommunication);
        }

        Set<Session_Communication__c> sessionComToInsert = new Set<Session_Communication__c>();

        for (enrtcr__Worker_Appointment__c appt : workerAppointments) {

            Boolean isExistLateCheckin = false;
            Boolean isExistLateCheckout = false;

            if(appIdToSessionComms.get(appt.Id) != null) {

                for (Session_Communication__c sessionCommunication : appIdToSessionComms.get(appt.Id)) {

                    if (sessionCommunication.RecordTypeId == RECORD_TYPE_ID_LATE_CHECK_IN) {

                        isExistLateCheckin = true;

                    } else if (sessionCommunication.RecordTypeId == RECORD_TYPE_ID_LATE_CHECK_OUT) {

                        isExistLateCheckout = true;

                    }
                }
            }

            System.debug('isExistLateCheckin = '+isExistLateCheckin);
            System.debug('isExistLateCheckout = '+isExistLateCheckout);

            Long startDuration = SessionUtil.calculateTimeBetween(
                    appt.enrtcr__Start_Date__c,
                    Datetime.now(),
                    SessionUtil.TimeUnit.MINUTES
            );
            Long endDuration = SessionUtil.calculateTimeBetween(
                    appt.enrtcr__End_Date__c,
                    Datetime.now(),
                    SessionUtil.TimeUnit.MINUTES
            );

            System.debug('startDuration = '+startDuration);
            System.debug('endDuration = '+endDuration);

            if (!isExistLateCheckin && appt.enrtcr__Session_Status__c == 'Rostered' && startDuration >= 30
                    && appt.enrtcr__Actual_Start_Date__c == NULL) {

                Session_Communication__c newScom = SessionUtil.createSessionCommunicationForWorkerAppointments(
                        appt.enrtcr__Session__c,
                        appt.Id,
                        appt.enrtcr__Worker__c,
                        RECORD_TYPE_ID_LATE_CHECK_IN);
                sessionComToInsert.add(newScom);
            }

            if (!isExistLateCheckout && (appt.enrtcr__Session_Status__c == 'In Progress' || appt.enrtcr__Session_Status__c == 'Rostered')
                    && endDuration >= 30
                    && appt.enrtcr__Actual_End_Date__c == NULL) {

                Session_Communication__c newScom = SessionUtil.createSessionCommunicationForWorkerAppointments(
                        appt.enrtcr__Session__c,
                        appt.Id,
                        appt.enrtcr__Worker__c,
                        RECORD_TYPE_ID_LATE_CHECK_OUT);
                sessionComToInsert.add(newScom);
            }
        }

        if (!sessionComToInsert.isEmpty()) insert new List<Session_Communication__c>(sessionComToInsert);
    }
}