/**
 * Created by Enrite Solutions on 26/07/2019.
 */

global with sharing class RetrievePersonalIdentifiersBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    public static final String regexGuid = '(\\{){0,1}[0-9a-fA-F]{8}\\-[0-9a-fA-F]{4}\\-[0-9a-fA-F]{4}\\-[0-9a-fA-F]{4}\\-[0-9a-fA-F]{12}(\\}){0,1}';
    public Map<String, Contact> contactRegister =  new Map<String, Contact>();

    global Database.QueryLocator start(Database.BatchableContext BC) {
        Id packageIdentifierId = enrtcr__Personal_Identifier__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Accounting_Package_Identifier').recordTypeId;
        return Database.getQueryLocator([SELECT Id,
                Name,
                enrtcr__Number__c,
                enrtcr__Client__c
        FROM enrtcr__Personal_Identifier__c
        WHERE RecordTypeId = :packageIdentifierId
        AND enrtcr__Number__c != null
        AND enrtcr__Number__c != ''
        AND enrtcr__Client__c != null
        ORDER BY CreatedDate ASC]);
    }

    global void execute(Database.BatchableContext BC, List<enrtcr__Personal_Identifier__c> scope) {
        for (enrtcr__Personal_Identifier__c pi : scope){
            if (pi.enrtcr__Number__c != null &&
                    String.isNotBlank(pi.enrtcr__Number__c) &&
                    isGuidId(pi.enrtcr__Number__c)){
                contactRegister.put(pi.enrtcr__Number__c, new Contact(Id = pi.enrtcr__Client__c, Total_Amount_Overdue__c = 0, Total_Amount_Outstanding__c = 0, Items_Outstanding__c = 0, Items_Overdue__c = 0));
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
        if (!Test.isRunningTest()){
            RetrieveInvoiceDataBatch b = new RetrieveInvoiceDataBatch(this.contactRegister, 1);
            Database.executeBatch(b);
        }
    }

    private static Boolean isGuidId(String xeroContactId){
        Pattern guidPattern = Pattern.compile(regexGuid);
        Matcher matches = guidPattern.matcher(xeroContactId);
        if (xeroContactId.length() == 36 &&
                matches.matches()){
            return true;
        }
        return false;
    }
}