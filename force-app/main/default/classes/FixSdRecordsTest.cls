@IsTest
private class FixSdRecordsTest {
    @IsTest
    static void testBehavior() {
        enrtcr.BaseAPI.deactivateTrigger('Service_Delivered__c');
        TestLoadData data = new TestLoadData();
        data.LoadRecords();
        data.LoadServiceAgreements();
        data.LoadServiceDelivered();
        data.loadExtract();

        Test.startTest();
        FixSdRecords b = new FixSdRecords();
        Database.executeBatch(b);

        data.testClient.enrtcr__Status__c = 'Current';
        data.testClient.Use_Old_Rate__c = true;
        update data.testClient;

        b = new FixSdRecords();
        Database.executeBatch(b);

        b.populateOldServiceWithTheNew(new enrtcr__Support_Delivered__c(), new Map<String, enrtcr__Rate__c>(), new Map<String, enrtcr__Site_Service__c>());
        Test.stopTest();
    }
}