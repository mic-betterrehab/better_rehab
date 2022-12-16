@isTest
private class br_settingsTest {
    static testMethod void validateAddKeyToMap() {
      	Setting__c kpiflow = new Setting__c();
        kpiFlow.Name = 'kpiFlow';
        kpiFlow.Settings__c = '{"baseKPI":"25","testKey2":"test value 2","testKey1":"test value 1","prevStartPeriod":"12/12/2020","repetition":"20","startDate":"12/12/2020","project":"kpiFlow","endDate":"12/13/2022"}';
        
        insert kpiFlow;
        
        Test.startTest();
        PageReference userPage = Page.BR_Settings;
        Test.setCurrentPage(userPage);
        userPage.getParameters().put('Id', String.valueOf(kpiFlow.Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(kpiFlow);
        br_settings page = new br_settings(sc);
        
        page.newKeyName = 'thisNewKey';
        page.addKeyToMap();
        page.submit();
        
        Test.stopTest();
        
        System.assertEquals(true, Utility.JSONtoMap(kpiFlow.Settings__c).keyset().contains('thisNewKey')); 
    }
}