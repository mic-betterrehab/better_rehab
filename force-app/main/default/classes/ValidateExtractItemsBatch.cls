/**
 * Created by Enrite Solutions on 25/01/2021.
 */

public with sharing class ValidateExtractItemsBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {

    public Id extractId;
    public Set<Id> clientIdsWithoutAccounting;
    public Boolean onlyValidateItems;

    public ValidateExtractItemsBatch(final Id extractId, Boolean onlyValidateItems){
        this.extractId = extractId;
        this.clientIdsWithoutAccounting = getClientsWithoutPersonalIdentifiers(this.extractId);
        this.onlyValidateItems = onlyValidateItems;

    }

    public Database.QueryLocator start(Database.BatchableContext param1) {
        return Database.getQueryLocator([
                SELECT Id,
                        Name,
                        enrtcr__Quantity__c,
                        Unit_Price_Number__c,
                        enrtcr__Unit_Price__c,
                        enrtcr__Total_ex_GST__c,
                        Error_Status_Message__c,
                        enrtcr__Service_Delivered__c,
                        Invoice_ID__c,
                        Invoice_Line_Item_ID__c,
                        enrtcr__Service_Delivered__r.enrtcr__Client__c,
                        enrtcr__Service_Delivered__r.enrtcr__Rate__c,
                        enrtcr__Service_Delivered__r.enrtcr__Rate__r.enrtcr__Accounting_Package_Id__c,
                        enrtcr__Service_Delivered__r.enrtcr__Rate__r.enrtcr__Service__c,
                        enrtcr__Service_Delivered__r.enrtcr__Rate__r.enrtcr__Service__r.Xero_Account_Code__c
                FROM enrtcr__Extract_Item__c
                WHERE enrtcr__Extract__c = :this.extractId
                AND (enrtcr__Service_Delivered__r.enrtcr__Client__c IN :clientIdsWithoutAccounting
                OR enrtcr__Service_Delivered__r.enrtcr__Rate__r.enrtcr__Accounting_Package_Id__c = NULL
                OR enrtcr__Total_ex_GST__c = NULL
                OR enrtcr__Total_ex_GST__c <= 0
                OR enrtcr__Quantity__c = NULL
                OR enrtcr__Quantity__c <= 0
                OR Unit_Price_Number__c = NULL
                OR Unit_Price_Number__c <= 0)
        ]);
    }

    public void execute(Database.BatchableContext param1, List<enrtcr__Extract_Item__c> items) {
        for (enrtcr__Extract_Item__c extItem : items){
            String errorMessage = '';
            if (extItem.enrtcr__Service_Delivered__c != null && clientIdsWithoutAccounting.contains(extItem.enrtcr__Service_Delivered__r.enrtcr__Client__c)){
                errorMessage += 'Error: Client does not have Accounting Package Record.' + '\n';
            }
            if (extItem.enrtcr__Service_Delivered__c == null){
                errorMessage += 'Error: Extract item is not linked to a Service Delivered Record.' + '\n';
            } else if (extItem.enrtcr__Service_Delivered__r.enrtcr__Rate__c == null){
                errorMessage += 'Error: Service Delivered Record does not have a Rate.' + '\n';
            } else if (String.isBlank(extItem.enrtcr__Service_Delivered__r.enrtcr__Rate__r.enrtcr__Accounting_Package_Id__c)){
                errorMessage += 'Error: Item Code Not found.' + '\n';
            }
            if (extItem.enrtcr__Total_ex_GST__c == null ||
                    extItem.enrtcr__Total_ex_GST__c <= 0){
                errorMessage += 'Error: Total is equal or less than 0.' + '\n';
            }
            if (extItem.enrtcr__Quantity__c == null ||
                    extItem.enrtcr__Quantity__c <= 0){
                errorMessage += 'Error: Quantity is equal or less than 0.' + '\n';
            }
            if (extItem.Unit_Price_Number__c == null ||
                    extItem.Unit_Price_Number__c <= 0){
                errorMessage += 'Error: Unit Price is equal or less than 0.' + '\n';
            }

            extItem.Error_Status_Message__c = errorMessage;
            extItem.Invoice_ID__c = '';
            extItem.Invoice_Line_Item_ID__c = '';
        }
        update items;
    }

    public void finish(Database.BatchableContext param1) {
        //only send email if we are not posting to xero... or else we send the email after posting to Xero
        if (this.onlyValidateItems){
            sendExtractToXeroBatch.sendEmail(' Errors', sendExtractToXeroBatch.getExtract(this.extractId));
        } else {
            // important note here, BATCH SIZE is the amount of CONTACTS we do per batch note Extract items... Each Contact spawns one invoice,
            // so by controlling how many contact we batch, we control how many invoices we send per callout/request

            sendExtractToXeroBatch b = new sendExtractToXeroBatch(extractId);
            if (!Test.isRunningTest()){
                Database.executeBatch(b, sendExtractToXeroBatch.BATCH_SIZE);
            }
        }
    }

    public static Set<Id> getClientsWithoutPersonalIdentifiers(final Id extractId){
        Set<Id> clientIds = new Set<Id>();
        List<Contact> contactsForExtract = getClientsWithoutPersonalIdentifiersQuery(extractId);
        if (contactsForExtract != null && !contactsForExtract.isEmpty()){
            for (Contact con : contactsForExtract){
                if (con.enrtcr__Personal_Identifiers__r == null || con.enrtcr__Personal_Identifiers__r.isEmpty()){
                    clientIds.add(con.Id);
                }
            }
        }
        return clientIds;
    }

    private static List<Contact> getClientsWithoutPersonalIdentifiersQuery(final Id extractId){
        Id packageIdentifierId = enrtcr__Personal_Identifier__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Accounting_Package_Identifier').recordTypeId;
        return [SELECT Id,
                Name,
        (SELECT
                Id,
                Name,
                enrtcr__Number__c
        FROM enrtcr__Personal_Identifiers__r
        WHERE RecordTypeId = :packageIdentifierId
        AND enrtcr__Number__c != NULL
        ORDER BY CreatedDate DESC
        LIMIT 1)
        FROM Contact
        WHERE Id IN (SELECT enrtcr__Client__c
        FROM enrtcr__Support_Delivered__c
        WHERE enrtcr__Financial_Extract__r.enrtcr__Extract__c = :extractId)
        ];
    }
}