public with sharing class overclaimConverter {
	// Constructor - this is only required/used if the autoRun function does not work
	private enrtcr__Support_Delivered__c sde;
    public String error {get; set;}
    public String theId {get; set;}
    public Id selectedSA {get;set;}
    public Id selectedSAI {get;set;}
    
    public List<String> newSAerrors {get;set;}
    public List<SelectOption> SAs {get;set;}
    public List<SelectOption> SAIs {get;set;}   
    
    private enrtcr__Rate__c toConvertRate;
    private enrtcr__Site_Service__c NewSSP;
    public overclaimConverter(ApexPages.StandardController stdController) {
        this.sde = (enrtcr__Support_Delivered__c) stdController.getRecord();
    }
    
    //VF Page will invoke this method
    public PageReference autoRun() {
        this.theId = ApexPages.currentPage().getParameters().get('id');
        
        if (theId == null) {
            //no id was given from button to VF page to this controller - display VF page content
            this.error = 'Internal Error! No id was passed from the record to the page.';
            return null;
        }
        
        this.sde = [SELECT id, 
                    	enrtcr__Service_Name__c, 
                    	enrtcr__Site_Service_Program__c, 
                    	enrtcr__Adhoc_Service__r.Id, 
                    	enrtcr__Site__r.Id, 
                    	enrtcr__Rate__c, 
                    	enrtcr__Rate__r.enrtcr__Rate__c, 
                    	Original_Quantity__c, 
                    	enrtcr__Quantity__c, 
                    	Original_Service__r.Id, 
                    	enrtcr__Support_Contract_Item__r.enrtcr__Support_Category_Remaining__c, 
                    	enrtcr__Total__c,
                    	enrtcr__Client__r.Id
                    FROM enrtcr__Support_Delivered__c 
                    WHERE id =: theId 
                    LIMIT 1];
        
        if (this.sde.enrtcr__Service_Name__c != 'Overclaim') {
            System.debug('This service delivery is not an overclaim service.');
            this.error = 'The service delivery which initiated this flow is not an Overclaim service delivery. Cannot convert a non-overclaim service delivery.';
            return null;
        } else if (this.sde.Original_Service__c == null) {
            System.debug('This service delivery does not have an original service listed.');
            this.error = 'This service delivery which initiated this flow does not have an original service listed in the "Original Service" field. This field is required to convert the service delivery.';
            return null;
        } else if (this.sde.Original_Quantity__c == null) {
			System.debug('This service delivery does not have an original quantity listed.');
            this.error = 'This service delivery which initiated this flow does not have an original quantity listed in the "Original Quantity" field. This field is required to convert the service delivery.';
            return null;
        } 
        
        this.toConvertRate = [SELECT id, enrtcr__Rate__c, enrtcr__Service__r.Id FROM enrtcr__Rate__c WHERE enrtcr__Service__r.Id =: this.sde.Original_Service__r.Id LIMIT 1];
        if (toConvertRate == null) {
            System.debug('Failed to find the rate for the original indicated service.');
            this.error = 'We failed to find a rate for the original service which is indicated. A rate is required to complete a service delivery.';
            return null;
        }
        
        this.NewSSP = [SELECT id FROM enrtcr__Site_Service__c WHERE enrtcr__Service__r.Id =: this.sde.Original_Service__r.Id AND enrtcr__Site__r.Id =: this.sde.enrtcr__Site__r.Id LIMIT 1];
        if (NewSSP == null) {
            System.debug('Failed to find the site service program for the original indicated service.');
            this.error = 'The original service indicated on the overclaim service delivery does not have an association with the site that is indicated on the overclaim service delivery. A site service association must be created for the original service and site.';
            return null;
        }
        
        Double totalToBill = this.sde.Original_Quantity__c * toConvertRate.enrtcr__Rate__c;
        Double totalRemaining = this.sde.enrtcr__Support_Contract_Item__r.enrtcr__Support_Category_Remaining__c;
        
        if (totalToBill == null) {
            System.debug('Failed to calculate the total amount to bill. Please check the original quantity and the rate of the original service. If this persists, please contact IT.');
            this.error = 'Failed to calculate the total amount to bill. Please check the original quantity and the rate of the original service. If this persists, please contact IT.';
            return null;
        } else if (totalRemaining == null) {
            System.debug('The service agreements total remaining balance could not be retrieved.');
            this.error = 'Failed to retrieve the remaning balance of the associated service agreement.';
            return null;
        } else if (totalToBill > totalRemaining) {
            System.debug('There still is not enough money in the service agreement item listed.');
            this.error = 'There still is not enough money in the service agreement item listed. Total to convert = $' + totalToBill.round() + ' and there is only $' + totalRemaining + ' remaining in the service agreement.' ;
            //getSAs();
            return null;
        }
        
        
        convertBase();
        return updateSDE();
        
    }
    
    private PageReference updateSDE() {
        PageReference pageRef = new PageReference('/' + theId);
        pageRef.setRedirect(true);
        
        try {
        	update this.sde;
            
        } catch (Exception e) {
            System.debug('Exception = ' + e.getMessage());
            this.error = e.getMessage();
            return null;
        }
        
        return pageRef;
    }
    /*
    public void getSAs() {
        if (this.sde != null) {
            SAs = new List<SelectOption>();
            List<enrtcr__Support_Contract__c> pulledSAs = [SELECT id, Name FROM enrtcr__Support_Contract__c WHERE enrtcr__Client__r.Id =: this.sde.enrtcr__Client__r.Id];
            
            if (pulledSAs.size() > 0) {
                pulledSAs.sort();
                for (enrtcr__Support_Contract__c SA : pulledSAs) {
                    SAs.add(new SelectOption(SA.Id,'['+SA.Name +']'));
                }
            } else {
                this.SAs = null;
            }
        }
    }
    
    public void getSAIs() {
        if (this.selectedSA != null) {
            SAIs = new List<SelectOption>();
            List<enrtcr__Support_Contract_Item__c> pulledSAIs = [SELECT id, Name, 
                                                                 	enrtcr__Support_Contract__r.enrtcr__Status__c, 
                                                                 	enrtcr__Support_Category_Remaining__c, 
                                                                 	enrtcr__Support_Contract__r.Name, 
                                                                 	enrtcr__Support_Category__r.Name,
                                                                 	enrtcr__Support_Contract__r.enrtcr__Rate_Type_Display__c
                                                                 FROM enrtcr__Support_Contract_Item__c 
                                                                 WHERE enrtcr__Support_Contract__r.Id =: this.selectedSA
                                                                 	AND enrtcr__Support_Category__c != null
                                                                ];
            
            if (pulledSAIs.size() > 0) {
                pulledSAIs.sort();
                for (enrtcr__Support_Contract_Item__c SAI : pulledSAIs) {
                    SAIs.add(new SelectOption(SAI.Id,'['+SAI.enrtcr__Support_Contract__r.enrtcr__Status__c+']'+ '[$'+SAI.enrtcr__Support_Category_Remaining__c+']'+ SAI.enrtcr__Support_Contract__r.Name + ' - ' + SAI.enrtcr__Support_Contract__r.enrtcr__Rate_Type_Display__c ));
                }
            } else {
                this.SAIs = null;
            }
        }
    }*/
    
    public void convertBase() {
        this.sde.enrtcr__Quantity__c = this.sde.Original_Quantity__c;
        this.sde.enrtcr__Adhoc_Service__c = this.sde.Original_Service__c;
        this.sde.enrtcr__Rate__c = this.toConvertRate.Id;
        this.sde.enrtcr__Site_Service_Program__c = this.NewSSP.id;
        this.sde.SD_Status__c = '';
    }
	/*
    public void convertSA() {
        this.sde.enrtcr__Support_Contract__c = this.selectedSA;
        this.sde.enrtcr__Support_Contract_Item__c = this.selectedSAI;
    }
    
    public PageReference newSAconvert() {
        if (this.selectedSA == null) {
            System.debug('You must select a service agreement to convert the delivery to');
            this.error = 'You must select a service agreement to convert the delivery to';
            return null;
        }

        if (this.selectedSAI == null) {
            System.debug('You must select a service agreement item to convert the delivery to');
            this.error = 'You must select a service agreement item to convert the delivery to';
            return null;
        }

        convertBase();
        convertSA();
        return updateSDE();
    }*/
}