public with sharing class RemoveOverclaimedItemsController {

    @AuraEnabled
    public static void removeOverclaimedItems(Id recordId) {
        delete [SELECT Id FROM enrtcr__Extract_Item__c WHERE enrtcr__Extract__c = :recordId AND Overclaimed_Client__c = true];
    }

    @AuraEnabled
    public static void clearOverclaimedItems(Id recordId) {
        ZeroOutOverClaimedEXIBatch zoo = new ZeroOutOverClaimedEXIBatch(recordId);
        database.executeBatch(zoo);
    }

}