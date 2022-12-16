/**
 * Created by ersoz on 25/10/20.
 */

public with sharing class PendulaUtility {

    public static Boolean isInboundSMSMessage(Pendula__Message__c message){

        return message.RecordTypeId == Schema.SObjectType.Pendula__Message__c.getRecordTypeInfosByDeveloperName().get('Inbound_SMS').getRecordTypeId();
    }
}