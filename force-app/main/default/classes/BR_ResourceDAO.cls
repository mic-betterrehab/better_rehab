public with sharing class BR_ResourceDAO {
    public static List<Resource__c> getActiveAndTierOneResourcesByState(String state) {
        return [
            SELECT id, Name, Site__c, Site__r.enrtcr__Business_State__c, Status__c, Tier__c, Type__c FROM Resource__c
            WHERE Status__c = 'Active'
            AND Tier__c = '1'
            AND (Expiry_Date__c = NULL OR Expiry_Date__c >= : System.today())
            AND Site__r.enrtcr__Business_State__c =: state
        ];
    }

    public static List<Resource__c> getActiveAndTierOneResources() {
        return [
            SELECT id, Name, Site__c, Site__r.enrtcr__Business_State__c, Status__c, Tier__c, Type__c FROM Resource__c
            WHERE Status__c = 'Active'
            AND Tier__c = '1'
            AND (Expiry_Date__c = NULL OR Expiry_Date__c >= : System.today())
        ];
    }

    public static List<Resource__c> getActiveAndTierOneResourcesWithNullSite() {
        return [
            SELECT id, Name, Site__c, Status__c, Tier__c, Type__c FROM Resource__c
            WHERE Status__c = 'Active'
            AND Tier__c = '1'
            AND (Expiry_Date__c = NULL OR Expiry_Date__c >= : System.today())
            AND Site__c = NULL
        ];
    }
}