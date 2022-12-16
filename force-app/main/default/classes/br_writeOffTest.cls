@isTest
private class br_writeOffTest {
    static testMethod void testWriteOff() {
        enrtcr__Site__c site = TestObjects.createSite(2);
        insert site;
        
        Contact client = TestObjects.createContact(1, 'NDIS');
        client.enrtcr__NDIS_ID__c = '12345678';
        client.MMM_Score__c = '0';
        insert client;
        
        List<User> u = [SELECT Id FROM User LIMIT 1];
        Contact worker = TestObjects.createContact(6, '');
        worker.enrtcr__Site__c = site.Id;
        worker.enrtcr__User__c = u[0].Id;
        insert worker;
        
        enrtcr__Reference_Data__c IDLSSC = TestObjects.CreateRD(27, 'NDIS', 'NDIS');
        insert IDLSSC;
        
        enrtcr__Support_Contract__c NDISSA = TestObjects.createSA(client.Id);
        insert NDISSA;
        
        enrtcr__Staff_Allocation__c clientClinician = new enrtcr__Staff_Allocation__c();
        clientClinician.Client__c = client.Id;
        clientClinician.Clinician__c = worker.Id;
        clientClinician.Clinician_Status__c = 'Active';
        clientClinician.Service_Agreement__c = NDISSA.Id;
        clientClinician.Name = 'Occupational Therapist';
        insert clientClinician;
	        
        enrtcr__Reference_Data__c NDISRate = TestObjects.CreateRD(21, 'NDIS', 'NDIS');
        insert NDISRate;
        
        enrtcr__Reference_Data__c GST = TestObjects.CreateRD(7, 'Tax Free (0%)', '');
        insert GST;
        
        enrtcr__Support_Contract_Item__c NDISSAI = TestObjects.createSAI(1,NDISSA.Id, IDLSSC.Id);
        insert NDISSAI;
        
        enrtcr__Service__c service = TestObjects.createService(3, IDLSSC.Id);
        service.Name = 'Travel service';
        insert service;
        
        enrtcr__Service__c service1 = TestObjects.createService(3, IDLSSC.Id);
        service1.Name = 'Write Off - RMs';
        insert service1;
        
        enrtcr__Rate__c rate = [SELECT Id,Status__c, enrtcr__Effective_Date__c, enrtcr__End_Date__c FROM enrtcr__Rate__c rate WHERE rate.enrtcr__Service__r.Id =: service.Id LIMIT 1][0];
        enrtcr__Rate__c rate1 = [SELECT Id,Status__c, enrtcr__Effective_Date__c, enrtcr__End_Date__c FROM enrtcr__Rate__c rate WHERE rate.enrtcr__Service__r.Id =: service1.Id LIMIT 1][0];
        
        rate1.enrtcr__Amount_Ex_GST__c = 0;
        rate1.enrtcr__GST__c = 0;
        rate1.Status__c = 'Expired';
        update rate1;
        
        rate1.Status__c = 'Active';
        update rate1;
        enrtcr__Site_Service__c SSP = [SELECT id FROM enrtcr__Site_Service__c WHERE enrtcr__Site__r.Id =: site.Id AND enrtcr__Service__r.Id =: service.Id LIMIT 1][0]; 
        
        enrtcr__Support_Delivered__c SDE = TestObjects.createSDE(u[0].Id, client.Id, IDLSSC.Id, service.Id, site.Id, NDISSAI.Id, rate.Id, Double.valueOf(0.5), SSP.Id , NDISSA.Id);
        insert SDE;
        
        Test.startTest();
        SDE.Write_Off__c = TRUE;
        SDE.enrtcr__Quantity__c = Double.valueOf(0.2);
        
        update SDE;
        Test.stopTest();
        
        enrtcr__Support_Delivered__c[] sds = [SELECT Id, enrtcr__Client__r.Id, enrtcr__Quantity__c, Original_Service__c, Parent_SDE__c FROM enrtcr__Support_Delivered__c WHERE  Parent_SDE__r.Id =: SDE.Id];
        System.assertEquals(1, sds.size());
        System.assertEquals(SDE.enrtcr__Adhoc_Service__c, sds[0].Original_Service__c);
        
    }
}