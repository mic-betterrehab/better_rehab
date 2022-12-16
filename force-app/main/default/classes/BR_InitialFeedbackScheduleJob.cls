public without sharing class BR_InitialFeedbackScheduleJob implements Schedulable {
    public void execute ( SchedulableContext ctx ) {        
        BR_InitialFeedbackBatch batch = new BR_InitialFeedbackBatch();
        ID batchId = Database.executeBatch(batch);
        System.debug('in BR_InitialFeedbackBatch schedule job class: ' + batchId);
    } 

}