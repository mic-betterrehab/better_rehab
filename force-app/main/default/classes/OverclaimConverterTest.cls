@isTest
private class OverclaimConverterTest {
    static testMethod void validateConversion() {
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
        service1.Name = 'OT Notes';
        insert service1;
        
        enrtcr__Service__c overclaim = TestObjects.createService(3, IDLSSC.Id);
        overclaim.Name = 'Overclaim';
        insert overclaim;
        
        
        enrtcr__Rate__c rate = [SELECT Id,Status__c, enrtcr__Effective_Date__c, enrtcr__End_Date__c FROM enrtcr__Rate__c rate WHERE rate.enrtcr__Service__r.Id =: service.Id LIMIT 1][0];
        enrtcr__Rate__c rate1 = [SELECT Id,Status__c, enrtcr__Effective_Date__c, enrtcr__End_Date__c FROM enrtcr__Rate__c rate WHERE rate.enrtcr__Service__r.Id =: service1.Id LIMIT 1][0];
        enrtcr__Rate__c overclaimRate = [SELECT Id,Status__c, enrtcr__Effective_Date__c, enrtcr__End_Date__c FROM enrtcr__Rate__c rate WHERE rate.enrtcr__Service__r.Id =: overclaim.Id LIMIT 1][0];
		
        enrtcr__Site_Service__c ocssp = [SELECT id, enrtcr__Service__r.Id FROM enrtcr__Site_Service__c WHERE enrtcr__Service__r.Id =: overclaim.Id AND enrtcr__Site__r.Id =: site.Id LIMIT 1][0];
        enrtcr__Support_Delivered__c sde = TestObjects.createSDE(u[0].Id, client.Id, IDLSSC.Id, overclaim.Id, site.Id, NDISSAI.Id, overclaimRate.Id, Double.valueOf(0.5), ocssp.Id, NDISSA.Id);
        sde.Original_Service__c = service.Id;
        sde.Original_Quantity__c = 2;
        insert sde;
        
        Test.startTest();
        PageReference convertPage = Page.ConvertOverclaim;
        Test.setCurrentPage(convertPage);
        convertPage.getParameters().put('Id', String.valueOf(sde.Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(sde);
        overclaimConverter UC = new overclaimConverter(sc);
        UC.autoRun();
        
        Test.stopTest();
        
        enrtcr__Support_Delivered__c sdeConverted = [SELECT id, enrtcr__Adhoc_Service__r.Name ,enrtcr__Quantity__c FROM enrtcr__Support_Delivered__c WHERE id =: sde.Id];
        System.assertEquals('Travel service', sdeConverted.enrtcr__Adhoc_Service__r.Name);
        System.assertEquals(2, sdeConverted.enrtcr__Quantity__c);
        
    }
}