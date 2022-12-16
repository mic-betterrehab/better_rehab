@IsTest
public class UpdateClientNDIAFundingTotalsTest
{
    @testSetup
    static void setupTestdata()
    {
        enrtcr.BaseAPI.deactivateTrigger('Service_Delivered__c');
        TestLoadData data = new TestLoadData();
        data.LoadRecords();
        data.LoadServiceAgreements();
        data.LoadServiceDelivered();
        data.loadExtract2();
    }

    @IsTest
    static void test1()
    {
        UpdateClientNDIAFundingTotalsBatch batch = new UpdateClientNDIAFundingTotalsBatch();
        Database.executeBatch(batch, 10);
    }

    @IsTest
    static void test2()
    {
        UpdateClientNDIAFundingTotalsScheduler sh1 = new UpdateClientNDIAFundingTotalsScheduler();
        String sch = '0 0 23 * * ?';
        system.schedule('Test SDScheduler', sch, sh1);
    }
}