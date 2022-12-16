public with sharing class OnboardingListUserController {
	// Constructor - this is only required/used if the autoRun function does not work
    /*private ApexPages.StandardSetController standardController;

    public OnboardingListUserController(ApexPages.StandardSetController standardController) {
        this.standardController = standardController;
    }
    
    //VF Page will invoke this method
    public PageReference autoRun() {
        List<Onboarding__c> selectedIds = (List<Onboarding__c>) standardController.getRecords();
        
        if (selectedIds.size() < 1) {
            //no id was given from button to VF page to this controller - display VF page content
            return null;
        }
        
        List<Onboarding__c> toOnboard = new List<Onboarding__c>();
        List<Id> toOnboardIds = new List<Id>();
        for(Onboarding__c selectedOnboarder : selectedIds) {
            System.debug('selected onboarder = ' + selectedOnboarder);
            selectedOnboarder = [SELECT id, User_Apex_Run__c, Name FROM onboarding__c WHERE id =: selectedOnboarder.Id LIMIT 1];
            if (selectedOnboarder.User_Apex_Run__c == true) {
                System.debug('The user Apex Run checkbox for ' + selectedOnboarder.Name + ' is marked as true. It looks like Apex user creation code has been run on this new starter already');
                continue;
            } else {
                selectedOnboarder.User_Apex_Run__c = true;
                toOnboard.add(selectedOnboarder);
                toOnboardIds.add(selectedOnboarder.Id);
            }
        }
        
        if (toOnboard.size() == 0) {
            System.debug('It looks like your selection of users to onboard have all been made');
            return null;
        }
        
        createUsers(toOnboardIds);
        update toOnboard;
        
        //PageReference pageRef = new PageReference();
        //pageRef.setRedirect(true);
        return standardController.save();
    }
    
    private void createUsers(List<Id> onboarders) {
        FutureListUser.insertUsers(onboarders);
    }*/
}