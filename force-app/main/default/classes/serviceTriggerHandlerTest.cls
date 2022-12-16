@isTest
private class serviceTriggerHandlerTest {
    static testMethod void validateRateSSCreation() {
        enrtcr__Reference_Data__c rate = TestObjects.createRD(27, 'NDIS', 'NDIS');
        rate.RecordTypeId = '0122v0000013OeTAAU';
        enrtcr__Reference_Data__c gst = TestObjects.createRD(7, 'Tax Free (0%)', '');
        enrtcr__Site__c site = TestObjects.createSite(2);
        insert site;
        insert rate;
        insert gst;
        
        enrtcr__Service__c service = new enrtcr__Service__c();
        
        service.Name = 'PBS Specialist 1';
        service.RecordTypeId = '0122v0000013OeEAAU';
        service.Accounting_Package_Id__c = '111';
        service.Better_Rehab__c = true;
        service.enrtcr__Support_Item_Code__c = 'aaa';
        service.Rate_Type__c = rate.Id;
        service.enrtcr__Status__c = 'Active';
        service.State__c = 'NSW';
        
        
        Test.startTest();
        insert service;
        Test.stopTest();
        
        enrtcr__Rate__c[] rates = [SELECT id, enrtcr__Amount_Ex_GST__c FROM enrtcr__Rate__c WHERE enrtcr__Service__r.Id =: service.Id];
        enrtcr__Site_Service__c[] SS = [SELECT id FROM enrtcr__Site_Service__c WHERE enrtcr__Service__r.Id =: service.Id];
        System.assertEquals(1, rates.size());
        System.assertEquals(1, SS.size());
        System.assertEquals(214.41, rates[0].enrtcr__Amount_Ex_GST__c);
        
        
        
    }
}