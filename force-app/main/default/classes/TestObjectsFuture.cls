@isTest
public with sharing class TestObjectsFuture {
    @future
    public static void createUser() {
        UserRole ClinBasic = [SELECT Id FROM UserRole WHERE Name='Clinicians (Basic)' limit 1];
        Profile Basic = [SELECT Id FROM Profile WHERE Name='Enrite Care - Basic' limit 1];
        User u = new User();
        u.LastName = 'User';
        u.FirstName = 'Test';
        u.Country = 'Australia';
        u.Email = 'testUser@betterrehab.com.au';
        u.MobilePhone = '0432256298';
        u.KPI__c = 30;
        u.State = 'NSW';
        u.Site__c = 'Eastern Sydney';
        u.Username = 'Test@betterrehab.com.au';
        u.CommunityNickname = 'Test';
        u.EmailEncodingKey = 'ISO-8859-1';
        u.ProfileId = Basic.Id;
        u.UserRoleId = ClinBasic.Id;
        u.TimeZoneSidKey = 'Australia/Sydney';
        u.LocaleSidKey = 'en_AU';
        u.UserPreferencesReceiveNoNotificationsAsApprover = false;
        u.Alias = 'testper';
        u.LanguageLocaleKey = 'en_US';
        
        insert u;
    }
}