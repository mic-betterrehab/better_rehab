/**
 * Created by ersoz on 2019-11-29.
 */

trigger WorkerAppointmentTrigger on enrtcr__Worker_Appointment__c (after insert, after update, after delete ) {
    if(Trigger.isAfter) {
        if(Trigger.isUpdate || Trigger.isInsert){
            new WorkerAppointmentHandler().afterUpdate(Trigger.newMap);
        }
        else if(Trigger.isDelete){
            new WorkerAppointmentHandler().afterUpdate(Trigger.oldMap);
        }
    }
}