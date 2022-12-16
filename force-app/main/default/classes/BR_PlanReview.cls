public class BR_PlanReview {
    //This class to set what happens when someone creates a Plan Review Report
    /*List<enrtcr__Session__c> sessionsToInsert;
    
    public BR_PlanReview(List<enrtcr__Assessment__c> planReviewReports){
        
        sessionsToInsert = new List<enrtcr__Session__c>();
        
        //find the record type id of each of the new A/R
        List<enrtcr__Assessment__c> reports = [SELECT id, Clinician__c, Clinician_2__c, Clinician_3__c, Clinician_4__c, RecordTypeId FROM enrtcr__Assessment__c WHERE enrtcr__Assessment__c.Id IN :planReviewReports];
        
        //check the record type
        for(Integer i = 0; i < reports.size(); i++){
            if(reports[i].RecordTypeId == '0122v000001VTJVAA4'){
                System.debug('inside BR_PlanReview with Plan Review Report');
                createSession(reports[i], 56, reports[i].Clinician__c); //8 weeks from the created date
            }
            
            if(reports[i].RecordTypeId == '0122v000001VTK9AAO'){
                System.debug('inside BR_PlanReview with MDT Plan Review Report');
                createSession(reports[i], 56, reports[i].Clinician__c); //first clinician will always be filled in
                
                if(reports[i].Clinician_2__c != NULL){
                    createSession(reports[i], 57, reports[i].Clinician_2__c);
                }
                
                if(reports[i].Clinician_3__c != NULL){
                    createSession(reports[i], 58, reports[i].Clinician_3__c);
                }
                
                if(reports[i].Clinician_4__c != NULL){
                    createSession(reports[i], 59, reports[i].Clinician_4__c);
                }
            }
            
        }
        
        insert sessionsToInsert;
    }
    
    //function to create a session
    private void createSession(enrtcr__Assessment__c report, Integer days, Id workerId){
        enrtcr__Assessment__c usedReport = [SELECT id, RecordTypeId, CreatedDate, enrtcr__Client__c, enrtcr__Client__r.Id FROM enrtcr__Assessment__c WHERE id =: report.Id];
        Contact clientDetails = [SELECT id, FirstName, LastName FROM Contact WHERE id =: usedReport.enrtcr__Client__r.Id];
        
        //check the days that the start date will fall in to
        Datetime dT = usedReport.CreatedDate;        
        Datetime start_date = Datetime.newInstance(dT.year(), dT.month(), dT.day() + days, 10, 00, 00); //hardcode the start date to be 10am
        
        Datetime finalStartDate = getNextBusinessDays(start_date); //will ALWAYS return a business day for 10am
        Datetime finalEndDate = finalStartDate + 1.5/24;        
        
        //create the session here if its all within business hours
        enrtcr__Session__c newSession = new enrtcr__Session__c();       
        if(usedReport.RecordTypeId == '0122v000001VTJVAA4'){
            newSession.Name = clientDetails.FirstName + ' '+ clientDetails.LastName + ' - Re-engagement';
        }
        
        if(usedReport.RecordTypeId == '0122v000001VTK9AAO'){
            newSession.Name = 'MDT ' + clientDetails.FirstName + ' '+ clientDetails.LastName + ' - Re-engagement';
        }
         
        newSession.enrtcr__Start_Date__c = finalStartDate;
        newSession.enrtcr__End_Date__c = finalEndDate;
        newSession.enrtcr__Status__c = 'Draft';
        newSession.enrtcr__Service_Types__c = 'Re-engagement';
        newSession.enrtcr__Required_Workers__c = 1;
        newSession.Worker__c = workerId;
        newSession.Client__c = usedReport.enrtcr__Client__c;
        newSession.Plan_Review_Report__c = usedReport.Id;        
        
		sessionsToInsert.add(newSession);        
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
    }*/
}