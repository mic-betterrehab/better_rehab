public with sharing class RecordApprovalTriggerHandler  implements ITrigger, Database.Stateful{
    public void bulkBefore() {
    }

    public void bulkAfter() {
        if (!Trigger.isInsert && !Trigger.isDelete) return;
        Set<Id> serviceDeliveryIds = new Set<Id>();
        Set<Id> existingApprovedDeliveredRecordIds = new Set<Id>();
        List<Record_Approval__c> approvals = (Trigger.isInsert) ? Trigger.new : Trigger.old;
        Map<Id, enrtcr__Support_Delivered__c> sdRecordsToUpdate = new Map<Id, enrtcr__Support_Delivered__c>();

        for (Record_Approval__c app : approvals) {
            serviceDeliveryIds.add(app.Service_Delivered__c);
        }

        if (Trigger.isDelete) {
            for (Record_Approval__c app : [SELECT Id, Service_Delivered__c FROM Record_Approval__c WHERE Service_Delivered__c IN :serviceDeliveryIds]) {
                existingApprovedDeliveredRecordIds.add(app.Service_Delivered__c);
            }
        }

        for (Id sdId : serviceDeliveryIds) {
            if (Trigger.isInsert) {
                sdRecordsToUpdate.put(sdId, new enrtcr__Support_Delivered__c(Id=sdId, Is_Approved__c=true));
            } else if (Trigger.isDelete) {
                sdRecordsToUpdate.put(sdId, new enrtcr__Support_Delivered__c(Id=sdId, Is_Approved__c=existingApprovedDeliveredRecordIds.contains(sdId)));
            }
        }

        enrtcr.BaseAPI.deactivateTrigger('Service_Delivered__c');
        update sdRecordsToUpdate.values();
    }

    public void beforeInsert(SObject so) {
    }

    public void beforeUpdate(SObject oldSo, SObject so) {
    }

    public void beforeDelete(SObject so) {
    }

    public void afterInsert(SObject so) {
    }

    public void afterUpdate(SObject oldSo, SObject so) {
    }

    public void afterDelete(SObject so) {
    }

    public void andFinally() {
    }

}