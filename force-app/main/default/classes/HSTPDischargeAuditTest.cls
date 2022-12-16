//create discharge form
@isTest
private class HSTPDischargeAuditTest {
    static testMethod void validateHSTPForm() {
        List<User> u = [SELECT Id FROM User LIMIT 1];
        
        //next 2 lines to silence warning for newServiceTrigger 
        enrtcr__Reference_Data__c gst = TestObjects.createRD(7, 'Tax Free (0%)', '');  
        insert gst;
        
        //create worker and client
    	Contact client = TestObjects.createContact(1, 'HSTP');
        Contact worker = TestObjects.createContact(6, '');
        worker.enrtcr__User__c = u[0].Id;
        insert client;
        insert worker;
        System.debug(client);
        System.debug(worker);
        //create support category = hstp
        enrtcr__Reference_Data__c HSTPSC = TestObjects.CreateRD(27, 'HSTP', '');
        insert HSTPSC;
        System.debug(HSTPSC);
        //create SA
        enrtcr__Support_Contract__c HSTPSA = TestObjects.createSA(client.Id);
        insert HSTPSA;
        System.debug(HSTPSA);
        //create SAI with support category = hstp
        enrtcr__Support_Contract_Item__c HSTPSAI = TestObjects.createSAI(1, HSTPSA.Id, HSTPSC.Id);
        insert HSTPSAI;
        System.debug(HSTPSAI);
        //create site
        enrtcr__Site__c site = TestObjects.createSite(2);
        insert site;
        System.debug(site);
        //create service
        enrtcr__Service__c service = TestObjects.createService(1, HSTPSC.Id);
        insert service;
        System.debug(service);
        //create HSTP rate type reference data
        enrtcr__Reference_Data__c HSTPRate = TestObjects.CreateRD(21, 'HSTP', 'Other');
        insert HSTPRate;
        System.debug(HSTPRate);
        //create rate (no longer need to create because of newServiceTrigger)
        enrtcr__Rate__c rate = [SELECT id FROM enrtcr__Rate__c WHERE enrtcr__Service__r.Id =: service.Id LIMIT 1][0];
        //enrtcr__Rate__c rate = TestObjects.createRate(1, service.Id, HSTPRate.Id);
        //insert rate;
        //System.debug(rate);
        //create site service (no longer need to create because of newServiceTrigger)
        enrtcr__Site_Service__c siteService = [SELECT id FROM enrtcr__Site_Service__c WHERE enrtcr__Service__r.Id =: service.Id LIMIT 1][0];
        //enrtcr__Site_Service__c siteService = TestObjects.createSS(1, site.Id, service.ID);
        //insert siteService;
        //System.debug(siteService);
        //create service deliveriescreateSDE
        Double quant = 0.5;
        enrtcr__Support_Delivered__c SDE = TestObjects.createSDE(u[0].Id, client.Id, HSTPSC.Id, service.Id, site.Id, HSTPSAI.Id, rate.Id,quant, siteService.Id, HSTPSA.Id);
        insert SDE;
        System.debug(SDE);
        
        
        
        Test.startTest();
        //create discharge form
        enrtcr__Assessment__c dischargeForm = new enrtcr__Assessment__c();
        dischargeForm.RecordTypeId = '0122v000001eZulAAE';
        dischargeForm.enrtcr__Client__c = client.Id;
        dischargeForm.Number_of_sessions__c = '1';
        dischargeForm.Telehealth_Session_Completed__c = 'No';
        dischargeForm.HSTP_Cancellation_Reason__c = 'Medical';
        dischargeForm.HSTP_Client_Cancelled__c = 'Yes';
        dischargeForm.Did_the_client_have_extra_sessions__c = 'No';
        dischargeForm.Related_Joint__c = 'Knee';
        dischargeForm.Initial_Extension_Knee__c = 5;
        dischargeForm.Initial_Flexion_Knee__c = 5;
        dischargeForm.Final_Extension_Knee__c = 5;
        dischargeForm.Final_Flexion_Knee__c = 5;
        dischargeForm.HSTP_Cancellation_Comments__c = 'Client cancelled the sessions';
        //dischargeForm.Number_of_extra_sessions__c = '0';
        dischargeForm.Discharge_Comments__c = 'test';
        try { 
            insert dischargeForm;
        } catch (Exception e) {
            System.debug(e.getMessage());
            Boolean expectedExceptionThrown = e.getMessage().contains('Wrong number of sessions indicated') ? true : false;
            System.debug('Inside the catch. boolean = ' + expectedExceptionThrown);
            System.assertEquals(expectedExceptionThrown, true);
        }
        Test.stopTest();
        List<enrtcr__Assessment__c> forms = [SELECT Id 
                                             FROM enrtcr__Assessment__c 
                                             WHERE enrtcr__Client__r.Id =: client.Id
                                            ];
        System.debug(forms + ' ' +  client.Id);
        System.assertEquals(1, forms.size());
        
    }
}