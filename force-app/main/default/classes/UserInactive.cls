public with sharing class UserInactive {
	// Constructor - this is only required/used if the autoRun function does not work\
	
	private offboarding__c offboarder;
    public String message {get; set;}
    
    public UserInactive(ApexPages.StandardController stdController) {
        this.offboarder = (offboarding__C)stdController.getRecord();
    }
    
    
    //VF Page will invoke this method
    public PageReference autoRun() {
        String theId = ApexPages.currentPage().getParameters().get('id');
        
        if (theId == null) {
            //no id was given from button to VF page to this controller - display VF page content
            message = 'No offboarding record is detected. Please open an offboarding record and try again.';
            return null;
        }
        
        this.offboarder = [SELECT id, Name, User__c, Exit_Date__c, Offboarding_Name__c, User_Inactive_Run__c FROM offboarding__c WHERE id =: theId LIMIT 1];
        if (this.offboarder.User_Inactive_Run__c == true) {
            System.debug('User Inactive Run has been completed');
            message = 'This user has been offboarded. If you believe this is wrong, please untick the User Inactive Run tickbox and try again.';
            return null;
        }      
 
        //deleteWorkerAppointments(this.offboarder.Offboarding_Name__c);
        inactiveClientClinician(this.offboarder.Offboarding_Name__c);
        inactiveUser(this.offboarder.User__c);
        removeLicense(this.offboarder.User__c);
        changeContactStatus(this.offboarder.Offboarding_Name__c, this.offboarder.Exit_Date__c);

        offboarder.User_Inactive_Run__c	 = true;        
        update offboarder;
        
        PageReference pageRef = new PageReference('/' + theId);
        pageRef.setRedirect(true);
        return pageRef;
    }
    
    public String getNoIssue(){
        return 'Issue cannot be detected. Please contact your Salesforce Developer.';
    }
    
    /*@future
    private static void deleteWorkerAppointments(String OId) {
        //get all that worker's appointment
        List<enrtcr__Worker_Appointment__c> apptList = [SELECT id FROM enrtcr__Worker_Appointment__c WHERE enrtcr__Worker__c =: OId];
        
        //Make a list to store the to-be removed appt
        List<enrtcr__Worker_Appointment__c> appt_removeList = new List<enrtcr__Worker_Appointment__c>();       
        
        //Add the to-be removed appt to the list
        for(enrtcr__Worker_Appointment__c ux : apptList) {
            appt_removeList.add(ux);
        }
        
        delete appt_removeList; //DML operation        
    }*/
    
    @future
    private static void inactiveClientClinician(String OId){
        //get all the relationship
        List<enrtcr__Staff_Allocation__c> clientClinicianList = [SELECT id, Clinician_Status__c FROM enrtcr__Staff_Allocation__c WHERE Clinician__c =: OId AND Clinician_Status__c = 'Active' AND (Service_Agreement__c = NULL OR Service_Agreement__r.enrtcr__Status__c = 'Current')];   
        System.debug(clientClinicianList.size());
        
        if(clientClinicianList.size() > 0){
            //Make a list to store the to-be inactive client clinician
            List<enrtcr__Staff_Allocation__c> inactiveList = new List<enrtcr__Staff_Allocation__c>();       
            
            //Update each relationship to be inactive
            for (enrtcr__Staff_Allocation__c relationship : clientClinicianList){            
                relationship.Clinician_Status__c = 'Inactive';
                inactiveList.add(relationship);
            }
            
            //update the list of inactive employees
            update inactiveList; 
            System.debug('Size of inactiveList: ' + inactiveList.size());   
        }     
    }
    
    @future
    private static void inactiveUser(String OId) {
        User Employee = [SELECT id FROM User WHERE id =: OId];        
        
        if (Employee.id != null) {         
            Employee.IsActive = False;
            update Employee;
        }
    }
    
    @future
    private static void removeLicense(String userId){
        User Employee = [SELECT id FROM User WHERE id =: userId];
        if (Employee.id != null) {
            //Get the package license
            PackageLicense pckgLicense = [SELECT Id, NamespacePrefix FROM PackageLicense WHERE NamespacePrefix = 'enrtcr'];
            System.debug('pckgLicense: ' + pckgLicense.Id + ' ' + pckgLicense.NamespacePrefix);            
            
            //Get the package license assignment
            UserPackageLicense upl = [SELECT id,PackageLicenseid,Userid from UserPackageLicense where PackageLicenseid =: pckgLicense.Id AND userId =: userId];
            System.debug('License Assignment ID: ' + upl.id);
            
            delete upl; //DML operation                        
        }
	} 
      

	@future
    private static void changeContactStatus(String OId, Date exitDate) {
        Contact employeeContact = [SELECT id FROM Contact WHERE id =: OId];        
        
        if (employeeContact.id != null) {         
            employeeContact.enrtcr__Status__c = 'Inactive';
            employeeContact.enrtcr__End_Date__c = exitDate;
            update employeeContact;
        }
    }    
}