//Nad
public with sharing class SDEPackage {
	public Id service {get;set;}
    public Id rate  {get;set;}
    public List<SelectOption> rates {get;set;}
    public Double quantity {get;set;}
    public Date sdeDate {get;set;}
    public String comments {get;set;}
    public String caseNotes {get;set;}
    public Integer hours {get;set;}
    public Integer minutes {get;set;}
    public boolean lastClient {get; set;}
    
    public boolean deliver {get;set;}
    public boolean split {get;set;}
    public Double totalDollar {get;set;}
    public Double rateDollar {get;set;}
    public Double inputtedTravel {get;set;}
    public Double originalQuantity {get;set;}
    public Integer numRates {get;set;}
    
    private List<String> dontCapService {get;set;}
    
    public SDEPackage() {
        this.sdeDate = System.today();
        this.hours = 0;
        this.totalDollar = 0;
        this.minutes = 0;
        this.lastClient = false;
        this.deliver = true;
        this.originalQuantity = 0;
        this.split = false;
        
        dontCapService = new List<String>();
        dontCapService.add('Senior Support - Travel');
    }
    
    public Integer validateQuantity() {
        if (this.hours < 0 || this.hours > 99 || this.minutes < 0 || this.minutes > 59 || this.hours == null || this.minutes == null) {
            return 0;
        }
        //createQuantity();
        return 1;
    }
    
    public void calculateTotal() {
        Double rateDollar = [SELECT id, enrtcr__Rate__c FROM enrtcr__Rate__c WHERE id =: this.rate LIMIT 1][0].enrtcr__Rate__c;
        System.debug('rateDollar  = ' + rateDollar);
        this.rateDollar = rateDollar;
        this.totalDollar = this.quantity * rateDollar;
    }
    
    public void calcTotal() { 
        if ( this.rateDollar != null ) {
            this.totalDollar = this.quantity * this.rateDollar;
        }
    }
    
    public void travelCheck(String serviceName, Integer MMM) {
        if (MMM != null) {
            if (validateQuantity() == 1) {
                if (serviceName.contains('Travel') && !dontCapService.contains(serviceName)) {
                    if (this.hours == 0 && this.minutes >= 0 && this.minutes < 15) {
                        createQuantity(0,15,1);
                    } else if (MMM >= 0 && MMM <= 3) {
                        if (lastClient == true) {
                            //cap it at 1 hour (MM 1-3 and last client)
                            if (this.hours >= 1 && this.minutes >= 0) {
                                createQuantity(1,0,1);
                            } else if (this.hours == 0 && this.minutes >= 15) {
                                createQuantity(this.hours, this.minutes, 1);
                            } else {
                                System.debug('Invalid Quantity for travel provided');
                            }
                        } else if (lastClient == false) {
                            //cap it at 30 minutes (MM 1-3 and not last client)
                            if ((this.hours == 0 && this.minutes > 30) || this.hours > 0) {
                                createQuantity(0,30,1);
                            } else if (this.hours == 0 && this.minutes <= 30 && this.minutes >= 15) {
                                createQuantity(this.hours, this.minutes, 1);
                            } else {
                                System.debug('Invalid Quantity provided for non last client.');
                            }
                        }
                    } else if (MMM > 3 && MMM <= 7) {
                        if (lastClient == true) {
                            //cap it at 2 hours (MM 4 & 5 and last client)
                            if (this.hours >= 2 && this.minutes >= 0) {
                                createQuantity(2,0,1);
                            } else if ((this.hours == 0 && this.minutes >= 15) || (this.hours == 1) || (this.hours == 2 && this.minutes == 0)) {
                                createQuantity(this.hours, this.minutes, 1);
                            } else {
                                System.debug('Invalid Quantity provided for non last client.');
                            }
                        } else if (lastClient == false) {
                            if (this.hours >= 1 && this.minutes >= 0) {
                                createQuantity(1,0,1);
                            } else if (this.hours == 0 && this.minutes >= 15) {
                                createQuantity(this.hours, this.minutes, 1);
                            } else {
                                System.debug('Invalid Quantity for travel provided');
                            }
                        }
                    }
                } else {
                    createQuantity(this.hours, this.minutes, 0);
                }
            } else {
                System.debug('Invalid Quantity input.');
            }
        } else {
            System.debug('Client must have a valid MMM Score!');
        }
        
    }

    public void createQuantity(Integer hrs, Integer mnts, Integer travelFinal) {
        if (travelFinal == 1) {
            this.quantity = roundQuant(quantityManipulation(hrs,mnts));
            this.inputtedTravel = quantityManipulation(this.hours, this.minutes);
            System.debug('quant = ' + this.quantity + 'inputted travel = ' + this.inputtedTravel);
        } else if (travelFinal == 0) {
            Double quant = quantityManipulation(hrs,mnts);
            this.quantity = quant;
            this.inputtedTravel = quant;
        }
    }
    
    public Double quantityManipulation(Integer hrs, Integer mnts) {
        String Hours = String.valueOf(hrs);
        Decimal ratio = Decimal.valueOf(String.valueOf(mnts)).divide(60,2);
        String Minutes = String.valueOf(ratio);
        String justMinutes = Minutes.substringAfter('.');
        String quant = Hours  + '.' + justMinutes;
        return Double.valueOf(quant);
    }
    
    public Double roundQuant(Double quantity) {
        String quant = String.valueOf(quantity);
        String justMinutes = quant.substringAfter('.');
        String hours = quant.substringBefore('.');
        Double minutes = Double.valueOf('.'+justMinutes);
        Double incrementHours = 0;
        Double incrementedMinutes = Double.valueOf('.'+justMinutes);
        System.debug('quant = ' + quant);
        System.debug('justminutes = ' + justMinutes);
        System.debug('hours = ' + hours);
        System.debug('Minutes = ' + minutes);
        if (minutes > 0 && minutes < 0.25) {
            if (minutes < 0.13) {
                incrementedMinutes = 0;
            } else {
                incrementedMinutes = 0.25;
            }
        } else if (minutes > 0.25 && minutes < 0.5) {
            if (minutes < 0.38) {
                incrementedMinutes = 0.25;
            } else {
                incrementedMinutes = 0.5;
            }
        } else if (minutes > 0.5 && minutes < 0.75) {
            if (minutes < 0.63) {
                incrementedMinutes = 0.5;
            } else {
                incrementedMinutes = 0.75;
            }
        } else if (minutes > 0.75 && minutes < 1) {
            if (minutes < 0.88) {
                incrementedMinutes = 0.75;
            } else {
                incrementHours = incrementHours + 1;
                incrementedMinutes = 0;
            }
        }
        //String finishIncrement = hours + '.' + incrementedMinutes;
        return (Double.valueOf(hours) + incrementHours) + Double.valueOf(incrementedMinutes);
    }
    
    public void reset(Integer x) {
        if (x == 0) {
            this.service = null;
        } else if (x == 1) {
            this.rate = null;
        } else if (x == 2) {
            this.service = null;
            this.rate = null;
        } else if (x == 3) {
            this.service = null;
            this.rate = null;
            this.rates = null;
        } else if (x == 4) {
            this.service = null;
            this.rate = null;
            this.rates = null;
            this.hours = 0;
            this.minutes = 0;
            this.lastClient = false;
            this.totalDollar = 0;
            this.inputtedTravel = 0;
            this.quantity = null;
            this.sdeDate = System.today();
            this.comments = null;
            this.caseNotes = null;
            this.deliver = true;
            this.split = false;
            this.totalDollar = 0;
            this.originalQuantity = 0;
        } else if (x == 5) {
            this.deliver = true;
            this.split = false;
            this.totalDollar = 0;
            this.originalQuantity = 0;
        }
    }
    
    public void getRates() {
        if (service != null) {
            rates = new List<SelectOption>();
            List<enrtcr__Rate__c> pulledRates = [SELECT Id, Name
                                                 FROM enrtcr__Rate__c 
                                                 WHERE enrtcr__Service__r.Id =:service 
                                                    AND enrtcr__Effective_Date__c < TODAY 
                                                    AND enrtcr__End_Date__c > TODAY
                                                 	AND Status__c = 'Active'
                                                ];
            if (pulledRates.size() > 0) {
                pulledRates.sort();
                for (enrtcr__Rate__c rate: pulledRates) {
                    rates.add(new SelectOption(rate.id, rate.Name));
                }
                this.rate = pulledRates[0].Id;
                
                if (pulledRates.size() > 1) {
                    createAudit(pulledRates.size());
                }
            } else {
               this.rate = null;
               createAudit(pulledRates.size());
            }
            this.numRates = pulledRates.size();
        }
    }
    
    public void createAudit(Integer rateSize) {
        Id recordTypeId = [select Id from RecordType where DeveloperName = 'Service_Audit' AND sObjectType = 'Audit__c' limit 1].Id;
        Audit__c auditForm = new Audit__c();
        auditForm.RecordTypeId = recordTypeId;
        auditForm.Service__c = this.service;
        auditForm.Number_of_Rates__c = rateSize;
        try {
           insert auditForm; 
        } catch(Exception e) {
            System.debug('Error = ' + e.getMessage());
        }
        
    }
}

/*
 public void travelCheck(String serviceName) {
        if (validateQuantity() == 1) {
            if (serviceName.contains('Travel')) {
                if (this.hours == 0 && this.minutes >= 0 && this.minutes < 15) {
                    createQuantity(0,15,1);
                } else if (lastClient == true) {
                    if (this.hours >= 1 && this.minutes >= 0) {
                        createQuantity(1,0,1);
                    } else if (this.hours == 0 && this.minutes >= 15) {
                        createQuantity(this.hours, this.minutes, 1);
                    } else {
                        System.debug('Invalid Quantity for travel provided');
                    }
                } else if(lastClient == false) {
                    if ((this.hours == 0 && this.minutes > 30) || this.hours > 0) {
                        createQuantity(0,30,1);
                    } else if (this.hours == 0 && this.minutes <= 30 && this.minutes >= 15) {
                        createQuantity(this.hours, this.minutes, 1);
                    } else {
                        System.debug('Invalid Quantity provided for non last client.');
                    }
                }
            } else {
                createQuantity(this.hours, this.minutes, 0);
            }
        } else {
            System.debug('Invalid Quantity input.');
        }
    }

*/