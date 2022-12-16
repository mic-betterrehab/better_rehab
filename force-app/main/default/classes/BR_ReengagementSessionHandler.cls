public class BR_ReengagementSessionHandler {
	//This class is to set what happened when a session is created (Re-engagement)
	/*List<enrtcr__Worker_Appointment__c> wapToInsert;
    List<enrtcr__Client_Appointment__c> capToInsert;
    List<enrtcr__Session__c> sessionToUpdate;
    
    public BR_ReengagementSessionHandler(List<enrtcr__Session__c> sessions){
        wapToInsert = new List<enrtcr__Worker_Appointment__c>();
        capToInsert = new List<enrtcr__Client_Appointment__c>();
        sessionToUpdate = new List<enrtcr__Session__c>();
        
        //find the record type id of each of the new session
        List<enrtcr__Session__c> session = [SELECT id, enrtcr__Service_Types__c FROM enrtcr__Session__c WHERE enrtcr__Session__c.Id IN :sessions];        
        
        for(Integer i = 0; i < sessions.size(); i++){
            if(session[i].enrtcr__Service_Types__c == 'Re-engagement'){
                createWAP(session[i]);
                createCAP(session[i]);
                updateSession(session[i]);
            }            
        }
        

		insert wapToInsert;
		insert capToInsert;        
        update sessionToUpdate;
    }
    
    //function to create a WAP - each session will always only have 1 worker for this use case
    private void createWAP(enrtcr__Session__c session){
        enrtcr__Session__c associatedSession = [SELECT id, enrtcr__Start_Date__c, enrtcr__End_Date__c, Worker__c FROM enrtcr__Session__c WHERE id =: session.Id];
        
        //create the WAP here
        enrtcr__Worker_Appointment__c newWAP = new enrtcr__Worker_Appointment__c();
        newWAP.enrtcr__Start_Date__c = associatedSession.enrtcr__Start_Date__c ; 
        newWAP.enrtcr__End_Date__c = associatedSession.enrtcr__End_Date__c;
        newWAP.enrtcr__Session__c = associatedSession.id;
        newWAP.enrtcr__Worker__c = associatedSession.Worker__C;
        newWAP.enrtcr__Status__c = 'Rostered';
        
        wapToInsert.add(newWAP);        
    }
    
    //function to crate a CAP - each session will always have 1 client
    private void createCAP(enrtcr__Session__c session){
        enrtcr__Session__c associatedSession = [SELECT id, enrtcr__Start_Date__c, enrtcr__End_Date__c, Client__c FROM enrtcr__Session__c WHERE id =: session.Id];
        
        //create the CAP here
        enrtcr__Client_Appointment__c newCAP = new enrtcr__Client_Appointment__c();
        newCAP.enrtcr__Start_Date__c = associatedSession.enrtcr__Start_Date__c ; 
        newCAP.enrtcr__End_Date__c = associatedSession.enrtcr__End_Date__c;
        newCAP.enrtcr__Session__c = associatedSession.id;
        newCAP.enrtcr__Client__c = associatedSession.Client__c;
        
        capToInsert.add(newCAP);         
    }
    
    //update the address and workers and profession fields
    private void updateSession(enrtcr__Session__c session){
        enrtcr__Session__c associatedSession = [SELECT id, Workers_and_Professions__c, Worker__r.FirstName, Worker__r.LastName, Worker__r.Clinician_Discipline__c, Client__r.Id FROM enrtcr__Session__c WHERE id =: session.Id];
        Contact clientDetails = [SELECT id, OtherLatitude, OtherLongitude, OtherStreet, OtherCity, OtherState, OtherPostalCode FROM Contact WHERE id =: associatedSession.Client__r.Id];
        
        associatedSession.Workers_and_Professions__c = associatedSession.Worker__r.FirstName + ' ' + associatedSession.Worker__r.LastName + '(' + associatedSession.Worker__r.Clinician_Discipline__c + ')';
        associatedSession.enrtcr__Visit_Type__c = 'Home';
        associatedSession.enrtcr__Geolocation__Latitude__s = clientDetails.OtherLatitude;
        associatedSession.enrtcr__Geolocation__Longitude__s = clientDetails.OtherLongitude;
        associatedSession.enrtcr__Other_Street__c = clientDetails.OtherStreet;
        associatedSession.enrtcr__Other_City__c = clientDetails.OtherCity;
        associatedSession.enrtcr__Other_State__c = clientDetails.OtherState;
        associatedSession.enrtcr__Other_Postal_Code__c = clientDetails.OtherPostalCode;
        sessionToUpdate.add(associatedSession);
    }*/
}