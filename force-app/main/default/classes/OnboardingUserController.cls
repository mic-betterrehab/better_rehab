public with sharing class OnboardingUserController {
	// Constructor - this is only required/used if the autoRun function does not work
	private onboarding__c onboarder;
    public String message {get; set;}    
    
    public OnboardingUserController(ApexPages.StandardController stdController) {
        this.onboarder = (onboarding__c)stdController.getRecord();
    }
    
    //VF Page will invoke this method
    public PageReference autoRun() {
        String theId = ApexPages.currentPage().getParameters().get('id');
        
        if (theId == null) {
            //no id was given from button to VF page to this controller - display VF page content
            message = 'No onboarding record is detected. Please open an onboarding record and try again.';
            return null;
        }
        
        this.onboarder = [SELECT id, User_Apex_Run__c, Email__c, First_Name__c, Last_Name__c, Phone_Number__c, State__c, Department__c, Office__c, Clinical_Supervisor__c, Gender__c FROM onboarding__c WHERE id =: theId LIMIT 1];
        if (this.onboarder.User_Apex_Run__c == true) {
            System.debug('The user Apex Run checkbox is marked as true. It looks like Apex user creation code has been run on this new starter already');
            message = 'It looks like this action has been run on this new starter. If you believe this is wrong, please double check that their User profile has not been created. After that, untick the User Apex Run tickbox and try again.';
        	return null;
        }
        
        String onboarderEmail = this.onboarder.Email__c;
        User[] users = [SELECT Id FROM User WHERE Email =: onboarderEmail];
        
        if ( users.size() > 0 ) {
            System.debug('We found a user with the same email address as this onboarder');
            message = 'We found a user with the same email address as this onboarder. Please double check the email address and try again.';
            return null;
        }
        
        if(checkRemainingLicenses() == FALSE){
            System.debug('checkRemainingLicense Result: ' + checkRemainingLicenses());
            message = 'There is no remaining Lumary license. Please order new Lumary basic licenses and try again.';
            return null;
        }
        
        createUser(theId);
        onboarder.User_Apex_Run__c = true;
        update onboarder;
        PageReference pageRef = new PageReference('/' + theId);
        pageRef.setRedirect(true);
        return pageRef;
    }
    
    public String getNoIssue(){
        return 'Issue cannot be detected. Please contact your Salesforce Developer.';
    }
    
    private void createUser(Id onboarderID) {
        FutureUser.insertUser(onboarderID);
    }
    
    public boolean checkRemainingLicenses(){
        //Get the package license
        Organization sandbox = [SELECT IsSandbox FROM Organization LIMIT 1];
        PackageLicense pckgLicense = [SELECT Id, AllowedLicenses, UsedLicenses FROM PackageLicense WHERE NamespacePrefix = 'enrtcr'];
        if(sandbox.IsSandbox == FALSE){            
            if(pckgLicense.AllowedLicenses - pckgLicense.UsedLicenses <= 0){
                return FALSE;
            } else {
                return TRUE;
            } 
        } else {
            return TRUE;
        }
    }
}