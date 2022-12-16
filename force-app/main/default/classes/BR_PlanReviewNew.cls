public class BR_PlanReviewNew {
    //This class to set what happens when someone creates a Plan Review Report - this is a new version to be used with the new calendar
    List<Event> eventsToInsert;
    
    Contact clientDetails;
    List<Id> c;
    
    private final Id Plan_Review = Schema.SObjectType.enrtcr__Assessment__c.getRecordTypeInfosByDeveloperName().get('Plan_Review').getRecordTypeId();
    private final Id MDT_Plan_Review = Schema.SObjectType.enrtcr__Assessment__c.getRecordTypeInfosByDeveloperName().get('MDT_Plan_Review').getRecordTypeId();
    private final Id BR_Event = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('BR_Event').getRecordTypeId(); 
    private Contact contactToShareEvent;
    
    public BR_PlanReviewNew(List<enrtcr__Assessment__c> planReviewReports){
        
        eventsToInsert = new List<Event>();
        c = new List<Id>();     
        
        //only call BR_PlanReviewNew for Plan Review or MDT
        List<enrtcr__Assessment__c> validAR = new List<enrtcr__Assessment__c>();
        
        for(enrtcr__Assessment__c ar : planReviewReports){
            if(ar.RecordTypeId == Plan_Review || ar.RecordTypeId == MDT_Plan_Review){
                validAR.add(ar);
            }
        }
        
        if(!validAR.isEmpty()){
            contactToShareEvent = [SELECT Id FROM Contact WHERE LastName = 'to share events' LIMIT 1];
            
            List<enrtcr__Assessment__c> newAR = [SELECT Id, RecordTypeId, CreatedDate, enrtcr__Client__c, Clinician__c, Clinician__r.enrtcr__User__c,
                                                 Clinician_2__c, Clinician_2__r.enrtcr__User__c, Clinician_3__c, Clinician_3__r.enrtcr__User__c, 
                                                 Clinician_4__c, Clinician_4__r.enrtcr__User__c FROM enrtcr__Assessment__c WHERE Id IN: validAR];
            
            for(enrtcr__Assessment__c report : newAR){
                c.add(report.enrtcr__Client__c);
            }
            
            Map<Id, Contact> clientDetailsMap = new Map<Id, Contact>([SELECT id, FirstName, LastName FROM Contact WHERE id IN: c]);
            
            //check the record type
            for(enrtcr__Assessment__c report : newAR){
                if(report.RecordTypeId == Plan_Review){
                    clientDetails = clientDetailsMap.get(report.enrtcr__Client__c);
                    System.debug('inside BR_PlanReview with Plan Review Report');
                    createEvent(report, 56, report.Clinician__c, report.Clinician__r.enrtcr__User__c, clientDetails); //8 weeks from the created date
                }
                
                if(report.RecordTypeId == MDT_Plan_Review){
                    clientDetails = clientDetailsMap.get(report.enrtcr__Client__c);
                    System.debug('inside BR_PlanReview with MDT Plan Review Report');
                    
                    //there might be >1 clinician here so will need to check
                    List<Id> listOfClinicians = new List<Id>();    
                    Map<Id, Id> workerToUser = new Map<Id,Id>();
                    
                    listOfClinicians.add(report.Clinician__c);
                    workerToUser.put(report.Clinician__c, report.Clinician__r.enrtcr__User__c);
                    
                    if(report.Clinician_2__c != NULL){
                        listOfClinicians.add(report.Clinician_2__c);
                        workerToUser.put(report.Clinician_2__c, report.Clinician_2__r.enrtcr__User__c);
                    }
                    
                    if(report.Clinician_3__c != NULL){
                        listOfClinicians.add(report.Clinician_3__c);
                        workerToUser.put(report.Clinician_3__c, report.Clinician_3__r.enrtcr__User__c);
                    }
                    
                    if(report.Clinician_4__c != NULL){
                        listOfClinicians.add(report.Clinician_4__c);
                        workerToUser.put(report.Clinician_4__c, report.Clinician_4__r.enrtcr__User__c);
                    }
                    
                    //call the createEvent method based on the size of the list
                    for(Integer z = 0; z < listOfClinicians.size(); z++){
                        //the first clinician will get 56 + 0 days, the second one will be 56 + 1 (until z = 3 max) 
                        createEvent(report, 56 + z, listOfClinicians[z], workerToUser.get(listOfClinicians[z]), clientDetails); 
                    }
                    
                }
                
            }
            
            System.debug('Size of events to be inserted in BR_PlanReviewNew: ' + eventsToInsert.size());
            insert eventsToInsert;
        }
        
        
    }
    
    //function to create an event
    private void createEvent(enrtcr__Assessment__c report, Integer days, Id workerId, Id workerUserId, Contact client){     
        System.debug('Creating the re-engagement event!');
        
        //check the days that the start date will fall in to
        Datetime dT = report.CreatedDate;        
        Datetime start_date = Datetime.newInstance(dT.year(), dT.month(), dT.day() + days, 10, 00, 00); //hardcode the start date to be 10am
        
        Datetime finalStartDate = getNextBusinessDays(start_date); //will ALWAYS return a business day for 10am
        Datetime finalEndDate = finalStartDate + 1.5/24;  
        
        //create the event here if its all within business hours
        Event newEvent = new Event();
        if(report.RecordTypeId == Plan_Review){
            newEvent.Subject = client.FirstName + ' '+ client.LastName + ' - Re-engagement';
        }
        
        if(report.RecordTypeId == MDT_Plan_Review){
            newEvent.Subject = 'MDT ' + client.FirstName + ' '+ client.LastName + ' - Re-engagement';
        }
        
        newEvent.StartDateTime = finalStartDate;
        newEvent.EndDateTime = finalEndDate;
        newEvent.Event_Status__c = 'Pending';
        newEvent.Event_Type__c = 'Therapy Session';
        newEvent.RecordTypeId = BR_Event;
        newEvent.Is_Re_engagement__c = TRUE;
        newEvent.Re_engagement_Worker_ID__c = workerId;
        newEvent.Plan_Review_Report__c = report.Id; 
        newEvent.OwnerId = workerUserId;
        newEvent.WhoId = contactToShareEvent.Id;
        newEvent.Number_of_Clients__c = 1;
        newEvent.Number_of_Workers__c = 1;
        
        eventsToInsert.add(newEvent);        
    }
    
    private Datetime getNextBusinessDays(Datetime dT){
        Datetime finalDate;
        String dayOfWeek = dT.format('E');
        System.debug('Day of the week: ' + dayOfWeek);
        
        switch on dayOfWeek {
            when 'Sat' {		
                finalDate = dT.addDays(2); 
            }	
            when 'Sun' {		
                finalDate = dT.addDays(1);
            }            
            when else {		
                finalDate = dT;
            }
        }
        
        return finalDate;
    }
}