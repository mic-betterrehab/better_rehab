/**
 * Created by ersoz on 25/10/20.
 */

trigger PendulaMessageTrigger on Pendula__Message__c (after insert) {

    if(Trigger.isAfter) {

        if (Trigger.isInsert) {

            MessageTriggerHandler.afterInsert(Trigger.new);
        }
    }
}