/***********************************************************************************************************************
 * Name: WorkerAppointmentHandler
 * Description: Handler class of worker appointment trigger.
 *
 * Version History
 * Date             Developer           Comments
 * --------------- ------------------- -------------------------------------------------------------------------------
 * 2019-11-29      Can Ersoz           Created. Align Worker Info to Session
 **********************************************************************************************************************/
public class WorkerAppointmentHandler {

    public void afterUpdate(Map<Id, enrtcr__Worker_Appointment__c> workerAppointmentMap){

        alignWorkerInfoToSession(workerAppointmentMap);
    }

    private void alignWorkerInfoToSession(Map<Id, enrtcr__Worker_Appointment__c> workerAppointmentMap){

        List<enrtcr__Session__c> sessionsToUpdate = new List<enrtcr__Session__c>();
        Set<Id> sessionIds = new Set<Id>();

        //grab session ids of the worker appointments
        for(enrtcr__Worker_Appointment__c workerAppointment : workerAppointmentMap.values()){
            sessionIds.add(workerAppointment.enrtcr__Session__c);
        }

        //loop through the related sessions
        for(enrtcr__Session__c session : QueryTool.findSessionsWithWorkerInfo(sessionIds)){

            Boolean isSite = false;
            String workerSite = '';

            //iterate over each worker appointments of the related sessions
            //and get worker name and profession
            List<String> workerInfos = new List<String>();
            for (enrtcr__Worker_Appointment__c workerAppointment : session.enrtcr__Worker_Appointments__r){

                if(workerAppointment.enrtcr__Worker__r.Clinician_Discipline__c != null) {
                    workerInfos.add(workerAppointment.enrtcr__Worker__r.Name + '(' + workerAppointment.enrtcr__Worker__r.Clinician_Discipline__c +')');
                }

                //we need the first worker's site to pull across to Customer Feedback Survey record
                if(!isSite && workerAppointment.enrtcr__Worker__r.enrtcr__Site__c != null){

                    workerSite = workerAppointment.enrtcr__Worker__r.enrtcr__Site__c;
                    isSite = true;
                }
            }

            session.Workers_and_Professions__c = String.join(workerInfos, ', ');
            session.Worker_Site__c = !String.isEmpty(workerSite) ? Id.valueOf(workerSite) : null;
            sessionsToUpdate.add(session);
        }
        if(!sessionsToUpdate.isEmpty()) update sessionsToUpdate;
    }
}