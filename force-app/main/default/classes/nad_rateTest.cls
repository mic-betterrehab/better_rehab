@isTest
private with sharing class nad_rateTest {
    static testMethod void testRate() {
        enrtcr__Reference_Data__c sc = TestObjects.createRD(27, 'support', '');
        insert sc;
        
        enrtcr__Reference_Data__c rateType = TestObjects.createRD(21, 'NDIS', 'NDIS');
        insert rateType;
        
        enrtcr__Reference_Data__c gst = TestObjects.createRD(7, 'Tax Free (0%)', '');
        insert gst;
        
        List<enrtcr__Service__c> servs = new List<enrtcr__Service__c>();
        for (Integer i = 0; i < 6 ; i++) {
            enrtcr__Service__c service = TestObjects.createService(3, sc.Id);
            service.Name = 'service' + String.valueOf(i);
            service.enrtcr__Status__c = 'Active';
            service.Better_Rehab__c = TRUE;
            servs.add(service);
        }
        
        insert servs;
        
        List<Id> ids = new List<Id>();
        ids.add(servs[0].Id);
        ids.add(servs[1].Id);
        ids.add(servs[2].Id);
        ids.add(servs[3].Id);
        ids.add(servs[4].Id);
        ids.add(servs[5].Id);
        
        List<enrtcr__Rate__c> rates = new List<enrtcr__Rate__c>();
        enrtcr__Rate__c r0 = TestObjects.createRate(2, servs[0].Id, rateType.Id);r0.Status__c='Active';r0.Name = 'Nad';
        enrtcr__Rate__c r1 = TestObjects.createRate(2, servs[1].Id, rateType.Id);r1.Status__c='Active';
        enrtcr__Rate__c r2 = TestObjects.createRate(2, servs[2].Id, rateType.Id);r2.Status__c='Active';
        enrtcr__Rate__c r3 = TestObjects.createRate(2, servs[3].Id, rateType.Id);r3.Status__c='Active';
        enrtcr__Rate__c r4 = TestObjects.createRate(2, servs[2].Id, rateType.Id);r4.Status__c='Active';
        enrtcr__Rate__c r5 = TestObjects.createRate(2, servs[3].Id, rateType.Id);r5.Status__c='Active';
        rates.add(r4);
        rates.add(r5);
        
        enrtcr__Rate__c autoRate = [SELECT id, Status__c FROM enrtcr__Rate__c WHERE enrtcr__Service__r.Id =: servs[0].Id][0];
        System.debug('autoRate = ' + autoRate);
        autoRate.Name = 'Wrong';
        autoRate.Status__c = 'Expired';
        autoRate.enrtcr__GST__c = 0;
        autoRate.enrtcr__Force_Update_of_Rate__c = TRUE; 
        update autoRate;
        Test.startTest();
        try { 
            insert r0;
        } catch (Exception e) {
            System.debug(e.getMessage());
            Boolean expectedExceptionThrown = e.getMessage().contains('The service associated with this rate already has an active rate.') ? true : false;
            System.assertEquals(expectedExceptionThrown, true);
        }
        Test.stopTest();
        
        enrtcr__Rate__c[] rates1 = [SELECT id, Name FROM enrtcr__Rate__c WHERE enrtcr__Service__r.Id =: servs[0].Id AND Status__c = 'Active'];
        System.assertEquals(1, rates1.size());
        System.assertEquals('Nad', rates1[0].Name);
        //enrtcr__Rate__c[] ratess = [SELECT id FROM enrtcr__Rate__c WHERE enrtcr__Service__r.Id IN: ids];
        //System.assertEquals(6, ratess.size());
        
    }
}