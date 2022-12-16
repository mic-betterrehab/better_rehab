/**
 * Created by ersoz on 2020-02-11.
 */

global without sharing class FeedbackSurveyProcessorJob implements Schedulable {

    global void execute ( SchedulableContext ctx ) {
        Database.executeBatch(new FeedbackSurveyProcessorBatch());
    }
}