/**
 * Created by ersoz on 2019-06-27.
 */

public class SessionUtil {

    public enum TimeUnit{
        HOURS, MINUTES, SECONDS, DAYS
    }

    public static Long calculateTimeBetween(Datetime startTime, Datetime endTime, TimeUnit unit){

        Long duration = 0;

        if (unit == TimeUnit.DAYS) {
            duration = (endTime.getTime() - startTime.getTime()) / (3600000*24);
        }
        else if (unit == TimeUnit.HOURS){
            duration = (endTime.getTime() - startTime.getTime())/3600000;
        }
        else if (unit == TimeUnit.MINUTES) {
            duration = (endTime.getTime() - startTime.getTime())/60000;
        }
        else if (unit == TimeUnit.SECONDS){
            duration = (endTime.getTime() - startTime.getTime())/1000;
        }
        else{}

        return duration;
    }

    public static Session_Communication__c createSessionCommunicationForWorkerAppointments(
            Id sessionId,
            Id workerAppointmentId,
            Id contactId,
            Id recordTypeId
    ){
        return new Session_Communication__c(
                Session__c = sessionId,
                Worker_Appointment__c = workerAppointmentId,
                Contact__c = contactId,
                RecordTypeId = recordTypeId
        );
    }
}