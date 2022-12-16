public class FutureListUser {
	@future
    public static void insertUsers(List<Id> OnboarderIDs) {
        //Get the profile ID for system Admin
        Profile Basic = [SELECT Id FROM Profile WHERE Name='Enrite Care - Basic' limit 1];
        Profile Standard = [SELECT Id FROM Profile WHERE Name='Enrite Care - Standard' limit 1];
        Profile SysAdmin = [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1];
        
        UserRole ClinBasic = [SELECT Id FROM UserRole WHERE Name='Clinicians (Basic)' limit 1];
        UserRole TLStandard = [SELECT Id FROM UserRole WHERE Name='Team Lead (Standard)' limit 1];
        UserRole MgmtAdvanced = [SELECT Id FROM UserRole WHERE Name='Management/Finance (Advanced)' limit 1];
        
        List<User> usersToCreate = new List<User>();
        for (Id OnboarderID : OnboarderIDs) {
            //initialise a new user using User object
            User newUser = new User();
            
            //grab the onboarder from the list view, should be only one incoming onboarder for every trigger
            Onboarding__c OnboarderDetails = [SELECT User_Apex_Run__c, Last_Name__c, First_Name__c,Email__c , Phone_Number__c, State__c, Department__c, Site__c, Office__c, Role_Title__c FROM Onboarding__c WHERE Id =: OnboarderID];
            
            Id UserRoleId = null;
            Id ProfileId = null;
            Integer KPI = 0;
            String Site = OnboarderDetails.Office__c;
            String TimeZone = '';
            String UserAlias = getAlias(OnboarderDetails.First_Name__c, OnboarderDetails.Last_Name__c);
            
            //Set the userRoleId based on their department
            if (OnboarderDetails.Department__c == 'Team Leaders' || OnboarderDetails.Department__c == 'Marketing' || OnboarderDetails.Department__c == 'Human Resources') {
                UserRoleId = TLStandard.Id;
            } else if (OnboarderDetails.Department__c == 'Management' || OnboarderDetails.Department__c == 'Information Technology' || OnboarderDetails.Department__c == 'Administration') {
                UserRoleId = MgmtAdvanced.Id;
            } else {
                UserRoleId = ClinBasic.Id;
            }
            
            //set the Profile based on their department
            if (OnboarderDetails.Department__c == 'Team Leaders' || OnboarderDetails.Department__c == 'Management') {
                ProfileId = Standard.Id;
            } else if (OnboarderDetails.Department__c == 'Information Technology' || OnboarderDetails.Department__c == 'Administration') {
                ProfileId = SysAdmin.Id;
            } else {
                ProfileId = Basic.Id;
            }
            
            //Get the correct KPI
            if (OnboarderDetails.Department__c == 'Occupational Therapy') {
                KPI = 30;
            } else if (OnboarderDetails.Department__c == 'Physiotherapy' || OnboarderDetails.Department__c == 'Speech Pathology' || OnboarderDetails.Department__c == 'PBS' || OnboarderDetails.Department__c == 'Exercise Physiology' || OnboarderDetails.Department__c == 'Social Work' || OnboarderDetails.Department__c == 'Allied Health Assistant') {
                KPI = 28;
            }
            
            //Get the correct TimeZone
            if (OnboarderDetails.State__c == 'NSW' || OnboarderDetails.State__c == 'VIC' || OnboarderDetails.State__c == 'ACT') {
                TimeZone = 'Australia/Sydney';
            } else if (OnboarderDetails.State__c == 'QLD') {
                TimeZone = 'Australia/Brisbane';
            } else if (OnboarderDetails.State__c == 'WA') {
                TimeZone = 'Australia/Perth';
            }
            
            
            //initialise the new user with the details of the onboarder
            newUser.LastName = OnboarderDetails.Last_Name__c;
            newUser.FirstName = OnboarderDetails.First_Name__c;
            newUser.Country = 'Australia';
            newUser.CompanyName = 'Better Rehab';
            newUser.Email = OnboarderDetails.Email__c;
            newUser.MobilePhone = OnboarderDetails.Phone_Number__c;
            newUser.Title = OnboarderDetails.Role_Title__c;
            newUser.KPI__c = KPI;
            newUser.State = OnboarderDetails.State__c;
            newUser.Site__c = Site;
            newUser.Username = OnboarderDetails.Email__c;
            if (OnboarderDetails.Department__c != 'Management' && OnboarderDetails.Department__c != 'Team Leaders') {
                    newUser.Department = OnboarderDetails.Department__c;
                }
            newUser.CommunityNickName = OnboarderDetails.First_Name__c + OnboarderDetails.Last_Name__c;
            newUser.EmailEncodingKey = 'ISO-8859-1';
            newUser.ProfileId = ProfileId;
            newUser.UserRoleId = UserRoleId;
            newUser.TimeZoneSidKey = TimeZone;
            newUser.LocaleSidKey = 'en_AU';
            newUser.LanguageLocaleKey = 'en_US';
            newUser.UserPreferencesReceiveNoNotificationsAsApprover = false;
            newUser.Alias = UserAlias;
            
            usersToCreate.add(newUser);
        }
        //insert the newUser
       	insert usersToCreate;
    }
    
    private static String getAlias(String First, String Last) {
        String initalFirst = First.substring(0, 1);
        String LastBit = 'Failed';
        if (Last.length() < 7) {
            LastBit = Last;
        } else {
            LastBit = Last.substring(0, 7);
        }
        
        String alias = initalFirst + LastBit;
        
        return alias;
    }
}