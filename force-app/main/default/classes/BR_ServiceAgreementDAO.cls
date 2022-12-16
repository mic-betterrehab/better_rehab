public with sharing class BR_ServiceAgreementDAO {
    public static List<enrtcr__Support_Contract__c> getActiveServiceAgreementByName(String name) {
        return [
            SELECT Id, enrtcr__Client__c
            FROM enrtcr__Support_Contract__c
            WHERE Name =: name
            AND enrtcr__Status__c = 'Current'
        ];
    }
}