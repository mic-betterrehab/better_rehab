global with sharing class CreateClinicianTasksSchedule implements Schedulable
{
    global void execute(SchedulableContext ctx)
    {
        CreateClinicianTasksBatch b = new CreateClinicianTasksBatch();
        Database.executeBatch(b,100);
    }
}