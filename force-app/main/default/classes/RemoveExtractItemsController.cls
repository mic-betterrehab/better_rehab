public with sharing class RemoveExtractItemsController {

    @TestVisible
    private final static String NUMBER_RECORDS_REMOVED = '{0} records were successfully deleted';

    @TestVisible
    private final static String NO_RECORDS_DELETED = 'No records were deleted';

    private final static Decimal QUANTITY_TOTAL_THRESHHOLD = 0.75;

    @AuraEnabled
    public static String removeExtractItems(Id recordId) {
        List<enrtcr__Extract_Item__c> itemsToDelete = new List<enrtcr__Extract_Item__c>();
        Map<Id, List<enrtcr__Extract_Item__c>> extractItemsByClient = getExtractItemMap(recordId);

        Integer numberOfRecordsDeleted = 0;

        for (Id clientId : extractItemsByClient.keySet()) {
            List<enrtcr__Extract_Item__c> items = extractItemsByClient.get(clientId);
            if (isTotalBelowThreshhold(items)) {
                itemsToDelete.addAll(items);
            }
        }

        if (itemsToDelete.size() > 0) {
            for (Database.DeleteResult delRes : Database.delete(itemsToDelete, false)) {
                if (delRes.success) numberOfRecordsDeleted++;
            }
        }

        return (numberOfRecordsDeleted == 0) ? NO_RECORDS_DELETED : String.format(NUMBER_RECORDS_REMOVED, new List<String> {String.valueOf(numberOfRecordsDeleted)});
    }

    @AuraEnabled
    public static String deleteAllExtractItemsNotApproved(Id extractId) {
        String msg = '';
        try {
            List<enrtcr__Extract_Item__c> itemsToDelete = [SELECT ID, enrtcr__Service_Delivered__c FROM enrtcr__Extract_Item__c WHERE enrtcr__Extract__c = :extractId AND enrtcr__Service_Delivered__r.Is_Approved__c = false];
            delete itemsToDelete;
            msg = String.format(NUMBER_RECORDS_REMOVED, new List<String> {String.valueOf(itemsToDelete.size())});
        } catch (Exception ex) {
            msg = NO_RECORDS_DELETED;
        }
        return msg;
    }

    private static Map<Id, List<enrtcr__Extract_Item__c>> getExtractItemMap(Id recordId) {
        Map<Id, List<enrtcr__Extract_Item__c>> extractItemsByClient = new Map<Id, List<enrtcr__Extract_Item__c>>();

        for (enrtcr__Extract_Item__c item : [SELECT ID, enrtcr__Client_ID__c, enrtcr__Quantity__c FROM enrtcr__Extract_Item__c WHERE enrtcr__Extract__c = :recordId]) {
            Id clientId = item.enrtcr__Client_ID__c;
            if (String.isBlank(clientId)) continue;

            if (!extractItemsByClient.containsKey(clientId)) {
                extractItemsByClient.put(clientId, new List<enrtcr__Extract_Item__c>());
            }

            extractItemsByClient.get(clientId).add(item);
        }

        return extractItemsByClient;
    }

    private static boolean isTotalBelowThreshhold(List<enrtcr__Extract_Item__c> items) {
        Decimal totalQuantity = 0;

        for (enrtcr__Extract_Item__c item : items) {
            if (item.enrtcr__Quantity__c == null) continue;

            totalQuantity += item.enrtcr__Quantity__c;
        }

        return totalQuantity < QUANTITY_TOTAL_THRESHHOLD;
    }
}