@isTest
private class siteTriggerHandlerTest {
    static testMethod void validateSiteServiceCreation() {
        enrtcr__Reference_Data__c sc = TestObjects.createRD(27, 'Support', '');
        insert sc;
        
        enrtcr__Reference_Data__c gst = TestObjects.createRD(7, 'Tax Free (0%)', '');
        insert gst;
        
        List<enrtcr__Service__c> services = new List<enrtcr__Service__c>();
        for (Integer i = 0; i < 5; i++) {
            enrtcr__Service__c serv = TestObjects.createService(3, sc.Id);
            serv.Name = 'Service ' + String.valueOf(i);
            serv.Better_Rehab__c = TRUE;
            serv.enrtcr__Status__c = 'Active';
            serv.State__c = 'NSW';
            
            services.add(serv);
        }
        
        insert services;
        
        enrtcr__Site__c site = TestObjects.createSite(2);
        site.Name = 'Eastern Sydney';
        site.enrtcr__Business_State__c = 'NSW';
        
        Test.startTest();
        insert site;
        Test.stopTest();
        
        enrtcr__Site_Service__c[] ss = [SELECT id FROM enrtcr__Site_Service__c WHERE enrtcr__Site__c =: site.Id];
        System.assertEquals(5, ss.size());
    }
}