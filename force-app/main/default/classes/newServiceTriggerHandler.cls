public with sharing class newServiceTriggerHandler {
	private List<enrtcr__Rate__c> rates = new List<enrtcr__Rate__c>();
    private List<enrtcr__Site_Service__c> SS = new List<enrtcr__Site_Service__c>();
    
    public newServiceTriggerHandler(List<enrtcr__Service__c> input) {
		// return if no service came through
        if (input.size() == 0) {
            return;
        }
        
        for (enrtcr__Service__c service : input) {
            if (service != NULL && service.Better_Rehab__c == TRUE) {
                createRates(service);
                createSS(service);
            }
        }

        insert rates;
        insert SS;
    }
    
    private void createRates(enrtcr__Service__c service) {
        enrtcr__Rate__c rate = new enrtcr__Rate__c();
        
        rate.Name = service.Name;
        rate.enrtcr__Service__c = service.Id;
        rate.enrtcr__Effective_Date__c = System.today() - 10;
        rate.enrtcr__End_Date__c = System.today() + 365;
        rate.Status__c = 'Active';
        rate.enrtcr__Quantity_Type__c = 'Hours';
        
        if (service.Rate_Type__c != NULL) {
            rate.enrtcr__RateType__c = service.Rate_Type__c;
        }
        if (service.Accounting_Package_Id__c != NULL) {
            rate.enrtcr__Accounting_Package_Id__c = service.Accounting_Package_Id__c;
        }

        rate.enrtcr__GST_Code__c = [SELECT id FROM enrtcr__Reference_Data__c WHERE Name = 'Tax Free (0%)' LIMIT 1][0].Id;
        
        Double amount;
        String serviceName = service.Name;
        
        if (serviceName.contains('HST')) {
            amount = 190;
        } else if (serviceName.contains('AHA') && serviceName.contains('1')) {
            amount = 56.16;
        } else if (serviceName.contains('AHA') && serviceName.contains('2')) {
            amount = 86.79;
        } else if (serviceName.contains('PBS') && serviceName.contains('Specialist')) {
            amount = 214.41;
        } else if (serviceName.contains('EP')) {
            amount = 166.99;
        } else if (serviceName.contains('HSTP')) {
            amount = 0;
        } else if (serviceName.contains('WA') && serviceName.contains('Physio')) {
            amount = 224.62;
        } else {
            amount = 193.99;
        }
       	rate.enrtcr__Amount_Ex_GST__c = amount;
        
        rates.add(rate);
        
    }
    
    private void createSS(enrtcr__Service__c service) {
        List<enrtcr__Site__c> sites = [SELECT id, enrtcr__Business_State__c FROM enrtcr__Site__c];
        
        for (enrtcr__Site__c site : sites) {
            //find the index of the site's state
            Integer index = service.State__c?.split(';').indexOf(site.enrtcr__Business_State__c); //if the service's state is empty, index will be null (no ss will be created)
            
            //if the site's state is in the service's state
            if(index != null && index != -1) {
                enrtcr__Site_Service__c siteservice = new enrtcr__Site_Service__c();
                
                siteservice.enrtcr__Operating_Start_Date__c = System.today() - 7;
                siteservice.enrtcr__Service__c = service.Id;
                siteservice.enrtcr__Site__c = site.Id;
                siteservice.RecordTypeId = '0122v0000013Oe8AAE';
                
                this.SS.add(siteservice);
            }
            
        }        
    }
}