/**
 * Created by georgehalteh on 16/10/19.
 */

public with sharing class FixSdRecords implements Database.Batchable<SObject>, Database.stateful {
    private final static String NEW_SERVICE_CODE = '15_056_0128_1_3';
    private final static String OLD_SERVICE_CODE = '15_048_0128_1_3';
    private final static String CLAIM_STATUS_ERROR = 'Error';
    private final static String EMPTY_CLAIM_STATUS = '';
    private final static Date THIRTY_JUNE = Date.newInstance(2019,6,30);
    private final static Set<String> ITEM_CODES = new Set<String>{NEW_SERVICE_CODE, OLD_SERVICE_CODE};
    private final static Set<String> CLAIM_STATUSES = new Set<String> {CLAIM_STATUS_ERROR, EMPTY_CLAIM_STATUS};

    private Set<String> errors = new Set<String>();
    private Integer numberOfSuccessfulRecords = 0;
    private Integer numberOfFailedRecords = 0;

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([
                SELECT  ID,
                        Name,
                        enrtcr__Rate__c,
                        enrtcr__Rate__r.Id,
                        enrtcr__Rate__r.This_rate_has_been_replaced_with__c,
                        enrtcr__Rate__r.This_rate_has_been_replaced_with__r.Id,
                        enrtcr__Rate__r.This_rate_has_been_replaced_with__r.enrtcr__Service__c,
                        enrtcr__Rate__r.This_rate_has_been_replaced_with__r.enrtcr__Rate__c,
                        enrtcr__Rate__r.This_rate_has_been_replaced_with__r.enrtcr__GST__c,
                        enrtcr__Rate__r.This_rate_has_been_replaced_with__r.Support_Item_Code__c,
                        enrtcr__Rate__r.Related_Replacement_Service__c,
                        enrtcr__Rate__r.Related_Replacement_Support_Item_Code__c,
                        enrtcr__Rate__r.enrtcr__Service__c,
                        enrtcr__Rate__r.Support_Item_Code__c,
                        enrtcr__Rate__r.enrtcr__Service__r.enrtcr__Support_Item_Code__c,
                        enrtcr__Adhoc_Service__r.Id,
                        enrtcr__Adhoc_Service__r.enrtcr__Support_Item_Code__c,
                        New_Adhoc_Service__c,
                        New_Rate__c,
                        New_Rate_ex_GST__c,
                        New_Rate_GST__c,
                        New_Total_ex_GST__c,
                        New_Total_GST__c,
                        New_Site_Service_Program__c,
                        Error_Message__c,
                        enrtcr__Site__c,
                        enrtcr__Quantity__c,
                        enrtcr__Client__c,
                        enrtcr__Client__r.Use_Old_Rate__c
                FROM enrtcr__Support_Delivered__c
                WHERE enrtcr__Adhoc_Service__r.enrtcr__Support_Item_Code__c in :ITEM_CODES
                AND enrtcr__Current_NDIS_Extract_Item__r.enrtcr__Claim_status__c IN :CLAIM_STATUSES
                AND enrtcr__Date__c > :THIRTY_JUNE
                AND enrtcr__Current_NDIS_Extract_Item__c != ''
        ]);
    }

    public void execute(Database.BatchableContext context, List<SObject> records) {

        enrtcr.BaseAPI.deactivateTrigger('Service_Delivered__c');
        Map<Id, enrtcr__Rate__c> newToOldReplacementMap = new Map<Id, enrtcr__Rate__c>();
        Map<String, enrtcr__Rate__c> ratesMap = getRateMap(newToOldReplacementMap);
        Map<String, enrtcr__Site_Service__c> siteServiceProgramsMap = getSiteServiceProgramsFromRates(ratesMap);

        for (enrtcr__Support_Delivered__c sd : (List<enrtcr__Support_Delivered__c>)records) {
            if (sd.enrtcr__Rate__r.Support_Item_Code__c == OLD_SERVICE_CODE &&  !sd.enrtcr__Client__r.Use_Old_Rate__c) {
                populateOldServiceWithTheNew(sd, ratesMap, siteServiceProgramsMap);
            } else if (sd.enrtcr__Rate__r.Support_Item_Code__c == NEW_SERVICE_CODE && sd.enrtcr__Client__r.Use_Old_Rate__c) {
                populateNewServiceWithTheOld(sd, ratesMap, siteServiceProgramsMap, newToOldReplacementMap);
            } else {
                sd.New_Rate__c = null;
                sd.New_Site_Service_Program__c = null;
                sd.New_Adhoc_Service__c = null;
                sd.New_Rate_GST__c = null;
                sd.New_Rate_ex_GST__c = null;
                sd.New_Total_GST__c = null;
                sd.New_Total_ex_GST__c = null;
            }
        }

        Integer counter = 0;
        for (Database.SaveResult res : Database.update(records, false)) {
            enrtcr__Support_Delivered__c sd = (enrtcr__Support_Delivered__c) records.get(0);
            if (!res.success) {
                if (res.errors != null && res.errors.size() > 0) this.errors.add('Failed to update ' + sd + ': ' + res.errors.get(0).message);
                this.numberOfFailedRecords = this.numberOfFailedRecords + 1;
            } else {
                this.numberOfSuccessfulRecords = this.numberOfSuccessfulRecords + 1;
            }
            counter++;
        }
    }

    public void finish(Database.BatchableContext records) {
        String subject = this.errors.isEmpty() ? 'FixSDRecords finished successfully' : 'FixSDREcords failed with errors';


        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        String htmlBody = '<h1>FixSDRecords Results</h1>';
        htmlBody += '<strong>Number of SDs fixed Successfully:</strong> ' + String.valueOf(this.numberOfSuccessfulRecords) + '<br/>';
        htmlBody += '<strong>Number of SD Failed:</strong> ' + String.valueOf(this.numberOfFailedRecords) + '<br/>';

        if (!this.errors.isEmpty()) {
            String errorsStr = String.join(new List<String>(this.errors), '<br/>');
            htmlBody += '<h2>Errors</h2>' + errorsStr;
        }

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSaveAsActivity(false);
        email.setTargetObjectId(UserInfo.getUserId());
        email.setHtmlBody(htmlBody);
        email.setSubject(subject);

        emails.add(email);

        Messaging.sendEmail(emails);
    }

    private Map<String, enrtcr__Rate__c> getRateMap(Map<Id, enrtcr__Rate__c> newToOldReplacementMap) {
        Map<String, enrtcr__Rate__c> ratesMap = new Map<String, enrtcr__Rate__c>();
        for (enrtcr__Rate__c r : [
                                SELECT ID, enrtcr__Service__c, enrtcr__Service__r.enrtcr__Support_Item_Code__c, Support_Item_Code__c, enrtcr__Rate__c, enrtcr__GST__c,
                                        This_rate_has_been_replaced_with__c,
                                        This_rate_has_been_replaced_with__r.Id,
                                        This_rate_has_been_replaced_with__r.enrtcr__Service__c,
                                        This_rate_has_been_replaced_with__r.enrtcr__Rate__c,
                                        This_rate_has_been_replaced_with__r.enrtcr__GST__c,
                                        This_rate_has_been_replaced_with__r.Support_Item_Code__c,
                                        Related_Replacement_Support_Item_Code__c
                                FROM enrtcr__Rate__c
                                WHERE enrtcr__Service__r.enrtcr__Support_Item_Code__c IN :ITEM_CODES]) {

            if (String.isNotBlank(r.Support_Item_Code__c) && String.isNotBlank(r.enrtcr__Service__c)) {

                String key = r.Support_Item_Code__c + ':' + r.enrtcr__Service__c;
                if (String.isNotBlank(r.This_rate_has_been_replaced_with__c)) { //&& r.Support_Item_Code__c == OLD_SERVICE_CODE) {
                    String replacewithkey = r.Related_Replacement_Support_Item_Code__c + ':' + r.This_rate_has_been_replaced_with__r.enrtcr__Service__c;
                    ratesMap.put(key, r);
                    ratesMap.put(replacewithkey, r.This_rate_has_been_replaced_with__r);
                    newToOldReplacementMap.put(r.This_rate_has_been_replaced_with__c, r);
                }
//                String key = r.Support_Item_Code__c + ':' + r.enrtcr__Service__c;
//                ratesMap.put(key, r);
            }

//            if (String.isNotBlank(r.This_rate_has_been_replaced_with__c)) { //&& r.Support_Item_Code__c == OLD_SERVICE_CODE) {
//                newToOldReplacementMap.put(r.This_rate_has_been_replaced_with__c, r);
//            }
        }
        return ratesMap;
    }

    private Map<String, enrtcr__Site_Service__c> getSiteServiceProgramsFromRates(Map<String,enrtcr__Rate__c> rateMap) {
        Map<String, enrtcr__Site_Service__c> siteServiceMap = new Map<String, enrtcr__Site_Service__c>();
        Set<Id> serviceIds = new Set<Id>();

        for (enrtcr__Rate__c r : rateMap.values()) {
            serviceIds.add(r.enrtcr__Service__c);
        }

        for (enrtcr__Site_Service__c sp : [SELECT ID, enrtcr__Service__c, enrtcr__Site__c FROM enrtcr__Site_Service__c WHERE enrtcr__Service__c IN :serviceIds]) {
            String key = sp.enrtcr__Service__c + ':' + sp.enrtcr__Site__c;
            siteServiceMap.put(key, sp);
        }

        return siteServiceMap;
    }

    @TestVisible
    private void populateOldServiceWithTheNew(enrtcr__Support_Delivered__c sd, Map<String, enrtcr__Rate__c> ratesMap, Map<String, enrtcr__Site_Service__c> siteServiceProgramsMap) {
        if (sd.enrtcr__Rate__r == null || String.isBlank(sd.enrtcr__Rate__r.This_rate_has_been_replaced_with__c) || String.isBlank(sd.enrtcr__Rate__r.This_rate_has_been_replaced_with__r.enrtcr__Service__c)) {
            sd.Error_Message__c = 'No rate or replacement found';
            return;
        }

        sd.Error_Message__c = '';

        String key = sd.enrtcr__Rate__r.This_rate_has_been_replaced_with__r.Support_Item_Code__c + ':' + sd.enrtcr__Rate__r.This_rate_has_been_replaced_with__r.enrtcr__Service__c;
        if (!ratesMap.containsKey(key)) {
            sd.Error_Message__c += 'Rate not found for new service';
            return;
        }

        String siteKey = sd.enrtcr__Rate__r.This_rate_has_been_replaced_with__r.enrtcr__Service__c + ':' + sd.enrtcr__SIte__c;
        if (!siteServiceProgramsMap.containsKey(siteKey)) {
            sd.Error_Message__c = 'Could not find the site service program';
            return;
        }

        enrtcr__Rate__c newRate = ratesMap.get(key);
        populateNewSdFields(sd, newRate, siteServiceProgramsMap, siteKey);
//        sd.New_Rate__c = newRate.Id;
//        sd.New_Site_Service_Program__c = siteServiceProgramsMap.get(siteKey).Id;
//        sd.New_Adhoc_Service__c = newRate.enrtcr__Service__c;
//        sd.New_Rate_GST__c = newRate.enrtcr__GST__c;
//        sd.New_Rate_ex_GST__c = newRate.enrtcr__Rate__c;
//        sd.New_Total_GST__c = sd.enrtcr__Quantity__c * newRate.enrtcr__GST__c;
//        sd.New_Total_ex_GST__c = sd.enrtcr__Quantity__c * newRate.enrtcr__Rate__c;
    }

    private void populateNewServiceWithTheOld(enrtcr__Support_Delivered__c sd,
            Map<String, enrtcr__Rate__c> ratesMap, Map<String, enrtcr__Site_Service__c> siteServiceProgramsMap,
            Map<Id, enrtcr__Rate__c> newToOldReplacementMap) {

        enrtcr__Rate__c r = (newToOldReplacementMap.containsKey(sd.enrtcr__Rate__c)) ? newToOldReplacementMap.get(sd.enrtcr__Rate__c) : null;

        if (r == null) {
            sd.Error_Message__c = 'Could not find the old rate';
            return;
        }

        String key = r.Support_Item_Code__c + ':' + r.enrtcr__Service__c;
        if (!ratesMap.containsKey(key)) {
            sd.Error_Message__c += 'Rate not found for new service';
            return;
        }

        String siteKey = r.enrtcr__Service__c + ':' + sd.enrtcr__SIte__c;
        if (!siteServiceProgramsMap.containsKey(siteKey)) {
            sd.Error_Message__c = 'Could not find the site service program';
            return;
        }

        enrtcr__Rate__c newRate = ratesMap.get(key);
        populateNewSdFields(sd, newRate, siteServiceProgramsMap, siteKey);
    }

    private void populateNewSdFields(enrtcr__Support_Delivered__c sd, enrtcr__Rate__c newRate, Map<String, enrtcr__Site_Service__c> siteServiceProgramsMap, String siteKey) {
        sd.New_Rate__c = newRate.Id;
        sd.New_Site_Service_Program__c = siteServiceProgramsMap.get(siteKey).Id;
        sd.New_Adhoc_Service__c = newRate.enrtcr__Service__c;
        sd.New_Rate_GST__c = newRate.enrtcr__GST__c;
        sd.New_Rate_ex_GST__c = newRate.enrtcr__Rate__c;
        sd.New_Total_GST__c = sd.enrtcr__Quantity__c * newRate.enrtcr__GST__c;
        sd.New_Total_ex_GST__c = sd.enrtcr__Quantity__c * newRate.enrtcr__Rate__c;
    }
}