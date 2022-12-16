/**
 * Created by Enrite Solutions on 23/12/2020.
 */

public with sharing class sendExtractToXeroController {

    public static final String EXTRACT_STATUS_EXTRACTING_DATA = 'Extracting Data';
    public static final String EXTRACT_STATUS_DATA_FAILED = 'Data Extract Failed';

    @AuraEnabled(Continuation=true)
    public static String sendExtractToXero(final Id extractId){
        Boolean isSuccess = true;
        String payload = 'Sending Extract Items to Xero, an Email will be sent when complete.';
        try {
            if (extractId == null){
                throw new CustomException('Extract Id Is Null');
            }
            sendXeroBatch(extractId);
        } catch (Exception e){
            isSuccess = false;
            payload = e.getMessage() + '\n' + e.getStackTraceString();
            update new enrtcr__Extract__c(Id = extractId, enrtcr__Status__c = EXTRACT_STATUS_DATA_FAILED);
        }
        return SendContactToXeroController.getResponse(isSuccess,payload);
    }

    private static void sendXeroBatch(final Id extractId){
        // we query contacts in this extract that dont have personal idntifiers... for each of those we
        // store them in a Set and pass onto a batch to put the errors on the Extract items...
        Set<Id> clientIdsWithoutAccounting = ValidateExtractItemsBatch.getClientsWithoutPersonalIdentifiers(extractId);
        // we check for atleast one valid item here... if there are no valid items we pass a bolean saying not to bother posting to Xero...
        // saves Salesforce resources and We communicate that to the user.
        List<enrtcr__Extract_Item__c> validExtractItem = checkForValidExtractItemsQuery(extractId, clientIdsWithoutAccounting);
        if (validExtractItem == null || validExtractItem.isEmpty()){
            ValidateExtractItemsBatch b = new ValidateExtractItemsBatch(extractId, true);
            if (!Test.isRunningTest()){
                Database.executeBatch(b);
            }
            throw new CustomException('No Valid Extract Items where found to send to Xero.');
        }
        ValidateExtractItemsBatch b = new ValidateExtractItemsBatch(extractId, false);
        if (!Test.isRunningTest()){
            Database.executeBatch(b);
        }

        update new enrtcr__Extract__c(Id = extractId, enrtcr__Status__c = EXTRACT_STATUS_EXTRACTING_DATA);
    }


    // limit query to one, if there are any valid items we pas the check or we notify the user
    private static List<enrtcr__Extract_Item__c> checkForValidExtractItemsQuery(final Id extractId, Set<Id> clientIdsWithoutAccounting){
        return [SELECT Id,
                Name,
                Error_Status_Message__c,
                Invoice_ID__c,
                Invoice_Line_Item_ID__c,
                enrtcr__Service_Delivered__c,
                enrtcr__Service_Delivered__r.enrtcr__Client__c,
                enrtcr__Service_Delivered__r.enrtcr__Rate__c,
                enrtcr__Service_Delivered__r.enrtcr__Rate__r.enrtcr__Accounting_Package_Id__c
        FROM enrtcr__Extract_Item__c
        WHERE enrtcr__Extract__c = :extractId
        AND enrtcr__Service_Delivered__r.enrtcr__Client__c != NULL
        AND enrtcr__Service_Delivered__r.enrtcr__Client__c NOT IN :clientIdsWithoutAccounting
        AND enrtcr__Service_Delivered__r.enrtcr__Rate__r.enrtcr__Accounting_Package_Id__c != NULL
        AND Unit_Price_Number__c > 0
        AND enrtcr__Quantity__c > 0
        AND enrtcr__Total_ex_GST__c > 0
        LIMIT 1];
    }
}