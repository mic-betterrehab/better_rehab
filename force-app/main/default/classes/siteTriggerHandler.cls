public with sharing class siteTriggerHandler {
    private List<enrtcr__Site_Service__c> ss = new List<enrtcr__Site_Service__c>();
    
    public siteTriggerHandler(List<enrtcr__Site__c> sites) {
        if (sites.size() == 0) {
            System.debug('No sites came through the trigger');
        }
        enrtcr__Service__c[] services = [SELECT id, State__c FROM enrtcr__Service__c WHERE Better_Rehab__c = TRUE AND enrtcr__Status__c = 'Active'];
        for (enrtcr__Site__c site : sites) {
            for (enrtcr__Service__c service : services) {
                
                //find the index of the site's state
                Integer index = service.State__c?.split(';').indexOf(site.enrtcr__Business_State__c); //if the service's state is empty, index will be null (no ss will be created)
                
                //if the site's state is in the service's state
                if(index != null && index != -1) {
                    System.debug('This site and service state matches');
                    
                    enrtcr__Site_Service__c siteserve = new enrtcr__Site_Service__c();
                    siteserve.enrtcr__Service__c = service.Id;
                    siteserve.enrtcr__Site__c = site.Id;
                    siteserve.enrtcr__Operating_Start_Date__c = Date.today();
                    
                    ss.add(siteserve);
                }
            }
        }
        
        insert ss;
    }
}