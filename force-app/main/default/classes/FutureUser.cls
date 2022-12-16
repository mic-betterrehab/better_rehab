public class FutureUser {
    //This class is run through the "Create User" button on Onboarding object
    //It creates a new user and assigning the correct Role and Profile depending on the onboarder's attributes
    @future
    public static void insertUser(ID OnboarderID) {
        //Get the profile ID for system Admin
        Profile Basic = [SELECT Id FROM Profile WHERE Name='Enrite Care - Basic' limit 1];
        Profile Standard = [SELECT Id FROM Profile WHERE Name='Enrite Care - Standard' limit 1];
        Profile SysAdmin = [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1];
        Profile studentProfile = [SELECT Id FROM Profile WHERE Name='Student' limit 1];
        
        UserRole ClinBasic = [SELECT Id FROM UserRole WHERE Name='Clinicians (Basic)' limit 1];
        UserRole TLStandard = [SELECT Id FROM UserRole WHERE Name='Team Lead (Standard)' limit 1];
        UserRole TLNZ = [SELECT Id FROM UserRole WHERE Name='Team Leader (Standard) - NZ' limit 1];
        UserRole student = [SELECT Id FROM UserRole WHERE Name='Student' limit 1];
        UserRole MgmtAdvanced = [SELECT Id FROM UserRole WHERE Name='Management/Finance (Advanced)' limit 1];
        
        
        //initialise a new user using User object
        User newUser = new User();
        
        //grab the onboarder from the list view, should be only one incoming onboarder for every trigger
        Onboarding__c OnboarderDetails = [SELECT Regional_Manager__c, User_Apex_Run__c, Last_Name__c, First_Name__c,Email__c , Phone_Number__c, FTE__c, State__c, Department__c, Site__r.Name, Site__c, Site__r.Business_Country__c, Site__r.enrtcr__Organisation_Name__r.Name,
                                          Office__c, Role_Title__c, isTeamLeader__c, Start_Date__c, Internal_Banding__c, Principal_Clinician__r.FirstName, Principal_Clinician__r.LastName, Clinical_Supervisor__r.FirstName, 
                                          Clinical_Supervisor__r.LastName, Direct_Supervisor__r.FirstName, Direct_Supervisor__r.LastName
                                          FROM Onboarding__c 
                                          WHERE Id =: OnboarderID];
        
        Id UserRoleId = null;
        Id ProfileId = null;
        Integer KPI = 0;
        String Site = OnboarderDetails.Office__c;
        String TimeZone = '';
        String Locale = '';
        String UserAlias = getAlias(OnboarderDetails.First_Name__c, OnboarderDetails.Last_Name__c);
        String orgName = OnboarderDetails.Site__r.enrtcr__Organisation_Name__r.Name;
        //check if onboarder is TL or not
        Boolean isTL = OnboarderDetails.isTeamLeader__c;
        
        //Set the userRoleId based on their department and job title (for TL)
        if(OnboarderDetails.Site__r.Business_Country__c == 'New Zealand' || OnboarderDetails.Site__r.Name == 'Philippines'){
            UserRoleId = TLNZ.Id;
        } else if(OnboarderDetails.Internal_Banding__c == 'Student'){
            UserRoleId = student.Id;
        } else {
            if (isTL == TRUE || OnboarderDetails.Department__c == 'Marketing' || OnboarderDetails.Department__c == 'Human Resources' || OnboarderDetails.Department__c == 'Talent'
                || OnboarderDetails.Department__c == 'Learning & Development'|| OnboarderDetails.Department__c == 'Business Development') {
                    UserRoleId = TLStandard.Id;
                } else if (OnboarderDetails.Department__c == 'Management' || OnboarderDetails.Department__c == 'Information Technology' || OnboarderDetails.Department__c == 'Administration') {
                    UserRoleId = MgmtAdvanced.Id;
                } else {
                    UserRoleId = ClinBasic.Id;
                }   
        }    
        
        
        //set the Profile based on their department and job title (for TL)        
        if (OnboarderDetails.Site__r.Business_Country__c == 'New Zealand' || isTL == TRUE || OnboarderDetails.Department__c == 'Management' || OnboarderDetails.Department__c == 'Business Development') {
            ProfileId = Standard.Id;
        } else if (OnboarderDetails.Department__c == 'Information Technology' || OnboarderDetails.Department__c == 'Administration') {
            ProfileId = SysAdmin.Id;
        } else if (OnboarderDetails.Internal_Banding__c == 'Student'){
            ProfileId = studentProfile.Id;
        } else {
            ProfileId = Basic.Id;
        }       
        
        //Get the correct TimeZone
        switch on OnboarderDetails.State__c {
            when 'NSW','VIC', 'ACT' {
                TimeZone = 'Australia/Sydney';
                Locale = 'en_AU';
            }
            when 'QLD' {
                TimeZone = 'Australia/Brisbane';
                Locale = 'en_AU';
            }
            when 'WA' {
                TimeZone = 'Australia/Perth';
                Locale = 'en_AU';
            }
            when 'SA' {
                TimeZone = 'Australia/Adelaide';   
                Locale = 'en_AU'; 
            }
            when 'TAS' {
                TimeZone = 'Australia/Hobart';   
                Locale = 'en_AU'; 
            }
            when 'NT' {
                TimeZone = 'Australia/Darwin';   
                Locale = 'en_AU'; 
            }
            when 'NZ' {
                TimeZone = 'Pacific/Auckland';   
                Locale = 'en_NZ';
            }
            when else {
                TimeZone = 'Australia/Sydney';
                Locale = 'en_AU';
            }
        } 
        
        
        //initialise the new user with the details of the onboarder
        newUser.LastName = OnboarderDetails.Last_Name__c;
        newUser.FirstName = OnboarderDetails.First_Name__c;
		newUser.Country = OnboarderDetails.Site__r.Business_Country__c;        
        newUser.Email = OnboarderDetails.Email__c;
        newUser.MobilePhone = OnboarderDetails.Phone_Number__c;
        newUser.CompanyName = orgName;
        newUser.Title = OnboarderDetails.Role_Title__c;
        newUser.Start_Date__c = OnboarderDetails.Start_Date__c;
        newUser.State = OnboarderDetails.State__c;
        newUser.Site__c = Site;
        newUser.Internal_Banding__c = OnboarderDetails.Internal_Banding__c;
        newUser.Username = OnboarderDetails.Email__c; 
        newUser.Clinical_Supervisor__c = OnboarderDetails.Clinical_Supervisor__r.FirstName + ' ' + OnboarderDetails.Clinical_Supervisor__r.LastName;
        newUser.Direct_Supervisor__c = OnboarderDetails.Direct_Supervisor__r.FirstName + ' ' + OnboarderDetails.Direct_Supervisor__r.LastName;
        newUser.FTE__c = OnboarderDetails.FTE__c;
        newUser.Principal_Clinician__c = OnboarderDetails.Principal_Clinician__r.FirstName + ' ' +  OnboarderDetails.Principal_Clinician__r.LastName;
        newUser.Regional_Manager__c = OnboarderDetails.Regional_Manager__c;
                            
        //set department for non-management people
        if (OnboarderDetails.Department__c != 'Management') {
            newUser.Department = OnboarderDetails.Department__c;
        }
        
        //set base KPI
        switch on OnboarderDetails.Internal_Banding__c{
            when 'AHA Early Service' {
                newUser.BaseKPI__c = 10;                
            }
            when 'AHA Full Service' {
                newUser.BaseKPI__c = 14;
            }
            when 'AHA Community' {
                newUser.BaseKPI__c = 20;
            }
            when 'AHA Senior Service' {
                newUser.BaseKPI__c = 22;
            }
            when else {
                if(newUser.Country == 'New Zealand'){
                    newUser.BaseKPI__c = 27.5;
                } else {
                    newUser.BaseKPI__c = 25;
                }
            }
        }
        
        //newUser.CommunityNickName = OnboarderDetails.First_Name__c;
        newUser.EmailEncodingKey = 'ISO-8859-1';
        newUser.ProfileId = ProfileId;
        newUser.UserRoleId = UserRoleId;
        newUser.TimeZoneSidKey = TimeZone;  
        newUser.LocaleSidKey = Locale;
        newUser.LanguageLocaleKey = 'en_US';
        newUser.UserPreferencesReceiveNoNotificationsAsApprover = false;
        newUser.Alias = UserAlias;  
        newUser.FederationIdentifier = OnboarderDetails.Email__c;
        System.debug('inserting the user');
        //insert the newUser
        
        insert newUser;
        User u_user = newUser;
        if (u_user.Id != null) {
            //Get the package license
            PackageLicense pckgLicense = [SELECT Id, NamespacePrefix FROM PackageLicense WHERE NamespacePrefix = 'enrtcr'];
            System.debug('pckgLicense: ' + pckgLicense.Id + ' ' + pckgLicense.NamespacePrefix);            
            
            
            insert new UserPackageLicense(UserId = u_user.id, PackageLicenseId = pckgLicense.id);
        }  
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