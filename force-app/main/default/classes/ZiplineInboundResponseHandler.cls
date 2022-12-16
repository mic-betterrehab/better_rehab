/***********************************************************************************************************************
 * Name: ZiplineInboundResponseHandler
 * Description: Handler class of Zipline Contact Matching trigger.
 *
 * Version History
 * Date             Developer           Comments
 * --------------- ------------------- -------------------------------------------------------------------------------
 * 2020-02-11      Can Ersoz           Created. Align inbound sms to Survey record
 **********************************************************************************************************************/
public with sharing class ZiplineInboundResponseHandler {

/* logic moved to new Pendula, decommissioned 12/12/2020

    private Map<Id,Zipline__Contact_Matching__c> newMap;
    private Map<Id, Id> contactIdToMessageId;
    private Map<Id, Zipline__Message__c> messageIdToMessage;

    public ZiplineInboundResponseHandler(Map<Id,Zipline__Contact_Matching__c> newMap){

        this.newMap = newMap;
        this.contactIdToMessageId = new Map<Id, Id>();
        this.messageIdToMessage = new Map<Id, Zipline__Message__c>();

        processTriggerContext();
    }

    private void processTriggerContext(){

        Set<Id> messageIds = new Set<Id>();

        for (Zipline__Contact_Matching__c contactMatching : newMap.values()) {

            messageIds.add(contactMatching.Zipline__Message__c);
            contactIdToMessageId.put(contactMatching.Zipline__Contact__c, contactMatching.Zipline__Message__c);
        }

        //Find the related inbound messages
        for (Zipline__Message__c message : QueryTool.getInboundMessages(messageIds)) {

            messageIdToMessage.put(message.Id, message);
        }

        alignMessagesToSurvey();
    }

    private void alignMessagesToSurvey() {

        List<Customer_Feedback_Survey__c> surveysToUpdate = new List<Customer_Feedback_Survey__c>();
        for (Customer_Feedback_Survey__c surveyResponse : QueryTool.getSurveysByContactId(contactIdToMessageId.keySet())){

            Id inboundMessageId = contactIdToMessageId.get(surveyResponse.Recipient__c);

            Zipline__Message__c inboundMessage = messageIdToMessage.get(inboundMessageId);

            if(inboundMessage != null) {

                //Check if the response message is recognizable
                if (!ZiplineInboundUtil.isRecognisable(inboundMessage.Zipline__SMS_Message__c)) {

                    //Populate Unrecognised field
                    surveyResponse.Unrecognised_Response__c = Datetime.now();
                } else if (ZiplineInboundUtil.isOptOut(inboundMessage.Zipline__SMS_Message__c)) {

                    //tick the survey opt out checkbox and close the survey
                    surveyResponse.Opt_out__c = true;
                    surveyResponse.Survey_is_Completed__c = true;
                } else {

                    //Populate Survey Response
//                    surveyResponse.Survey_Response__c = Integer.valueOf(inboundMessage.Zipline__SMS_Message__c);

                    //close the survey when the response has been received
                    surveyResponse.Survey_is_Completed__c = true;
                }

                surveysToUpdate.add(surveyResponse);
            }
        }
        if(!surveysToUpdate.isEmpty())
            update surveysToUpdate;
    }
 */
}