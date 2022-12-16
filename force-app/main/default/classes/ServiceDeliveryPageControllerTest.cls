//Author - Nad
//Date - 26/11/2020
//Contact - 0432 256 298
@isTest
private class ServiceDeliveryPageControllerTest {
    static testMethod void testDelivery() {
        
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
        //overclaimRate.enrtcr__Amount_Ex_GST__c = 0;
        //overclaimRate.Status__c = 'Expired';
        //overclaimRate.enrtcr__Force_Update_of_Rate__c = TRUE;
        //update overclaimRate;
        System.debug('rate = ' + rate);
        System.debug('oc rate = ' + overclaimRate);
        //enrtcr__Rate__c rate = TestObjects.createRate(2, service.Id, NDISRate.Id);
        //insert rate;
        
        //enrtcr__Site_Service__c siteService = TestObjects.createSS(1, site.Id, service.ID);
        //insert siteService;
        
        Test.startTest();
        serviceDeliveryPageController page = new serviceDeliveryPageController();
        page.selectedWorker = worker.Id;
        page.workerListAction();
        
        dateTime start = System.now();
        while(System.now() < start.addSeconds(5));
        
        page.selectedClient = client.Id;
        page.clientListAction();
        
        page.selectedSAI = NDISSAI.Id;
        page.SAIListAction();
        
        page.sde1.service = service.Id;
        page.serviceListAction1();
        //page.sde1.rate = rate.Id;
        page.sde1.hours = 0;
        page.sde1.minutes = 06;
        page.sde1.comments= 'Test comments1';
        page.sde1.caseNotes = 'Test caseNotes1';
        
        page.sde2.service = service.Id;
        page.serviceListAction2();
        //page.sde1.rate = rate.Id;
        page.sde2.hours = 0;
        page.sde2.minutes = 06;
        page.sde2.comments= 'Test comments2';
        page.sde2.caseNotes = 'Test caseNotes2';
        
        page.sde3.service = service.Id;
        page.serviceListAction3();
        //page.sde1.rate = rate.Id;
        page.sde3.hours = 0;
        page.sde3.minutes = 06;
        page.sde3.comments= 'Test comments3';
        page.sde3.caseNotes = 'Test caseNotes3';
        
        page.sde4.service = service.Id;
        page.serviceListAction4();
        //page.sde1.rate = rate.Id;
        page.sde4.hours = 0;
        page.sde4.minutes = 06;
        page.sde4.comments= 'Test comments4';
        page.sde4.caseNotes = 'Test caseNotes4';
        
        page.sde5.service = service1.Id;
        page.serviceListAction5();
        //page.sde1.rate = rate.Id;
        page.sde5.hours = 30;
        page.sde5.minutes = 06;
        page.sde5.comments= 'Test comments5';
        page.sde5.caseNotes = 'Test caseNotes5';
        
        page.sde6.service = service.Id;
        page.serviceListAction6();
        //page.sde1.rate = rate.Id;
        page.sde6.hours = 0;
        page.sde6.minutes = 06;
        page.sde6.comments= 'Test comments6';
        page.sde6.caseNotes = 'Test caseNotes6';
        
        
        page.saveAction();
        page.submitAction();
        Test.stopTest();
        
        enrtcr__Support_Delivered__c[] sds = [SELECT Id, enrtcr__Client__r.Id, enrtcr__Comments__c, enrtcr__Quantity__c, Uncapped_Quantity__c  FROM enrtcr__Support_Delivered__c WHERE enrtcr__Client__r.Id =: client.Id AND enrtcr__Comments__c = 'Test comments1' ];
        System.assertEquals(1, sds.size());
        System.debug('sd entered = ' + sds[0]);
        enrtcr__Note__c[] cns = [SELECT Id, Name FROM enrtcr__Note__c WHERE enrtcr__Client__r.Id =: client.Id AND enrtcr__Support_Delivered__r.Id =: sds[0].Id];
        System.assertEquals(1, cns.size());
        System.assertEquals('Test comments1', cns[0].Name);
        
        Audit__c[] auditForms = [SELECT Id, SD1__c, SD2__c, Time_Spent__c, Client__c, Worker__c, Number_of__c, Status__c, Error_Message__c, User_Input__c FROM Audit__c WHERE Worker__r.Id =: worker.Id AND Client__r.Id =: client.Id];
        System.debug('Test audit = ' + auditForms[0]);
        System.debug('user input = ' + auditForms[0].User_Input__c);
        System.assertEquals(2, auditForms.size());

		    
        
        
    }
}