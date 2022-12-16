global without sharing class BR_FollowUpSurveyScheduleJob implements Schedulable {
    global void execute ( SchedulableContext ctx ) {        
        BR_FollowUpSurveyBatch batch = new BR_FollowUpSurveyBatch();
        ID batchId = Database.executeBatch(batch, 100);
        System.debug('in BR_FollowUpSurvey schedule job class: ' + batchId);
    }
}