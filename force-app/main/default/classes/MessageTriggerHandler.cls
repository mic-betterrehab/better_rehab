/***********************************************************************************************************************
 * Name: MessageTriggerHandler
 * Description: Handler class of Pendula Message trigger.
 *
 * Version History
 * Date             Developer           Comments
 * --------------- ------------------- -------------------------------------------------------------------------------
 * 2020-10-25      Can Ersoz           Created. Handles Invalid Response
 * 2022-01-25	   Rafella Angeline	   Edited this class to accommodate for the new Feedback Survey object
 **********************************************************************************************************************/

public with sharing class MessageTriggerHandler {

    public static void afterInsert ( List<Pendula__Message__c> newMessageList ) {

        Map<Id, Pendula__Message__c> messageMap = new Map<Id, Pendula__Message__c>();

        for (Pendula__Message__c newMessage : newMessageList) {

            System.debug('newMessage ====> ' + newMessage);

            //we ensure that it's inbound sms
            if (PendulaUtility.isInboundSMSMessage(newMessage)) {

                //build a message map
                messageMap.put(newMessage.Id, newMessage);
            }
        }

        //relate the inbound message to survey record
        relateMessageToSurvey(messageMap);
    }

    private static void relateMessageToSurvey ( Map<Id, Pendula__Message__c> messageMap ) {

        Map<Id, Id> contactToInboundMessage = new Map<Id, Id>();

        //find the contacts that have sent the inbound Sms
        for (Pendula__Message_Recipient__c messageRecipient : QueryTool.findMessageRecipientsByMessageIds(messageMap.keySet())) {

            //map contact to inbound message
            contactToInboundMessage.put(messageRecipient.Pendula__Contact__c, messageRecipient.Pendula__Message__c);
        }

        System.debug('contactToMessage ====> ' + contactToInboundMessage);

        Map<Id, Id> recordIdToContactId = new Map<Id, Id>();

        //find the outbound messages related to the Survey flow by the contact ids
        //add the new pendula flows for now
        for (Pendula__Message__c newMessage : QueryTool.findSurveyRelatedOutboundMessagesByRecipientIds(contactToInboundMessage.keySet())) {

            //map survey to contact
            recordIdToContactId.put(newMessage.Pendula__Record_Id__c, newMessage.Pendula__Recipient_Id__c);
        }

        System.debug('recordIdToContactId =====> ' + recordIdToContactId);

        populateUnrecognizedResponse(messageMap,contactToInboundMessage,recordIdToContactId);
    }

    private static void populateUnrecognizedResponse(
            Map<Id, Pendula__Message__c> messageMap,
            Map<Id, Id> contactToInboundMessage,
            Map<Id, Id> recordIdToContactId
    ){

        List<Feedback_Survey__c> surveysToUpdate = new List<Feedback_Survey__c>();

        //find incomplete surveys by ids
        for (Feedback_Survey__c survey : [SELECT Id, Unrecognised_Response__c FROM Feedback_Survey__c WHERE Id IN: recordIdToContactId.keySet() AND Survey_is_Completed__c = FALSE]) {

            //get the contact ids
            Id outboundMessageContactId = recordIdToContactId.get(survey.Id);

            System.debug('outboundMessageContactId =====> ' + outboundMessageContactId);

            //check whether the contact exist in inbound message map
            if (contactToInboundMessage.get(outboundMessageContactId) != null) {

                //get the inbound message id
                Id inboundMessageId = contactToInboundMessage.get(outboundMessageContactId);

                System.debug('inboundMessageId  =====> ' + inboundMessageId);

                //get the inbound message
                Pendula__Message__c inboundMessage = messageMap.get(inboundMessageId);

                System.debug('inboundMessage  =====> ' + inboundMessage);

                //make sure that the Sms is in correct format
                if (!isRecognisable(inboundMessage.Pendula__SMS_Body__c)) {

                    System.debug('********* Unrecognized *********');

                    survey.Unrecognised_Response__c = Datetime.now();
                    surveysToUpdate.add(survey);
                }
            }
        }

        System.debug('surveysToUpdate  =====> ' + surveysToUpdate);

        if (!surveysToUpdate.isEmpty()) update surveysToUpdate;
    }

    private static Boolean isRecognisable ( String smsBody ) {

        if (String.isEmpty(smsBody)) return false;

        smsBody = smsBody.deleteWhitespace();

        if(smsBody.isAlpha() && smsBody.equalsIgnoreCase('stop')) return true;

        if (!smsBody.isNumeric()) return false;

        Integer smsBodyInt = Integer.valueOf(smsBody);

        if (smsBodyInt < 1 || smsBodyInt > 10) return false;

        return true;
    }
}