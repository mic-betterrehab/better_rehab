@IsTest
private class RemoveOverclaimedItemsControllerTest {
    @testSetup
    static void setupTestdata()
    {
        enrtcr.BaseAPI.deactivateTrigger('Service_Delivered__c');
        TestLoadData data = new TestLoadData();
        data.LoadRecords();
        data.LoadServiceAgreements();
        data.LoadServiceDelivered();
        data.loadExtract();

        List<enrtcr__Support_Delivered__c> sdToAdd = new List<enrtcr__Support_Delivered__c>();
        enrtcr__Support_Delivered__c testSupportDelivered = new enrtcr__Support_Delivered__c(
                enrtcr__Client__c = data.testClient.Id,
                enrtcr__Support_Contract__c = data.testSupportContract.Id,
                enrtcr__Support_Contract_Item__c = data.testSupportContractItem.Id,
                enrtcr__Site_Service_Program__c = data.testSiteServices[0].Id,
                enrtcr__Rate__c = data.testRates[0].Id,
                enrtcr__Date__c = Date.today(),
                enrtcr__Adhoc_Service__c = data.testServices[0].Id,
                enrtcr__Site__c = data.testSites[0].Id,
                enrtcr__Quantity__c = 1);

        sdToAdd.add(testSupportDelivered);

        sdToAdd.add(new enrtcr__Support_Delivered__c(
                enrtcr__Client__c = data.testClient.Id,
                enrtcr__Support_Contract__c = data.testSupportContract.Id,
                enrtcr__Support_Contract_Item__c = data.testSupportContractItem.Id,
                enrtcr__Site_Service_Program__c = data.testSiteServices[2].Id,
                enrtcr__Rate__c = data.testRates[2].Id,
                enrtcr__Date__c = Date.today(),
                enrtcr__Adhoc_Service__c = data.testServices[1].Id,
                enrtcr__Site__c = data.testSites[0].Id,
                enrtcr__Quantity__c = 1));

        sdToAdd.add(new enrtcr__Support_Delivered__c(
                enrtcr__Client__c = data.testClient.Id,
                enrtcr__Support_Contract__c = data.testSupportContract.Id,
                enrtcr__Support_Contract_Item__c = data.testSupportContractItem.Id,
                enrtcr__Site_Service_Program__c = data.testSiteServices[2].Id,
                enrtcr__Rate__c = data.testRates[0].Id,
                enrtcr__Date__c = Date.today(),
                enrtcr__Adhoc_Service__c = data.testServices[1].Id,
                enrtcr__Site__c = data.testSites[0].Id,
                enrtcr__Quantity__c = 10));

        INSERT sdToAdd;
    }

    @IsTest
    static void testBehavior() {
//        enrtcr__Extract__c ext = new enrtcr__Extract__c(enrtcr__Start_Date__c=Date.today(), enrtcr__End_Date__c=Date.today());
//        insert ext;
//
//        enrtcr__Extract_Item__c item = new enrtcr__Extract_Item__c(enrtcr__Extract__c = ext.Id);
//        insert item;

        enrtcr__Extract__c ext = new enrtcr__Extract__c(enrtcr__Start_Date__c = Date.today().addYears(-1), enrtcr__End_Date__c=Date.today().addDays(5));
        insert ext;
        List<enrtcr__Extract_Item__c> items = new List<enrtcr__Extract_Item__c>();


        for (enrtcr__Support_Delivered__c sd : [SELECT Id, enrtcr__Client__c FROM enrtcr__Support_Delivered__c WHERE enrtcr__Current_NDIS_Extract_Item__c = null  LIMIT 1]) {
            system.debug('sd client: ' + sd.enrtcr__Client__c);
            items.add(new enrtcr__Extract_Item__c(enrtcr__Service_Delivered__c = sd.Id, enrtcr__Claim_Status__c = 'Error', enrtcr__Extract__c = ext.Id));
        }
        insert items;
        List<enrtcr__Support_Delivered__c> sdsToUpdate = new List<enrtcr__Support_Delivered__c>();

        Set<Id> clientIds = new Set<Id>();
        for (enrtcr__Extract_Item__c item : items) {
            sdsToUpdate.add(new enrtcr__Support_Delivered__c(Id=item.enrtcr__Service_Delivered__c, enrtcr__Current_NDIS_Extract_Item__c = item.Id));
            item.enrtcr__Claim_Status__c = 'Success';
            clientIds.add(item.enrtcr__Service_Delivered__r.enrtcr__Client__c);
        }

        update sdsToUpdate;
        update items;


        List<enrtcr__Extract_Item__c> exiList = new List<enrtcr__Extract_Item__c>( [SELECT Id, Name, enrtcr__Total_ex_GST__c,enrtcr__Service_Delivered__r.enrtcr__Client__c
        FROM enrtcr__Extract_Item__c
        WHERE enrtcr__Service_Delivered__r.enrtcr__Support_Contract__r.enrtcr__Funding_Management__c = 'NDIA'
        AND (enrtcr__Claim_Status__c = 'Success' OR enrtcr__Claim_Status__c = 'Paid' OR enrtcr__Claim_Status__c='')
                //AND enrtcr__Service_Delivered__r.enrtcr__Client__c IN :clientIds
                AND enrtcr__Extract__c != :ext.id]);
        system.debug(exiList.size());

        //RemoveOverclaimedItemsController.clearItems(item);
        RemoveOverclaimedItemsController.clearOverclaimedItems(ext.Id);

        //ZeroOutOverClaimedEXIBatch zoo = new ZeroOutOverClaimedEXIBatch(ext.Id);
        //database.executeBatch(zoo);

        //RemoveOverclaimedItemsController.removeOverclaimedItems(ext.Id);
    }

    @IsTest
    static void testBehavior2() {
        enrtcr__Extract__c ext = new enrtcr__Extract__c(enrtcr__Start_Date__c = Date.today().addYears(-1), enrtcr__End_Date__c=Date.today().addDays(5));
        insert ext;
        List<enrtcr__Extract_Item__c> items = new List<enrtcr__Extract_Item__c>();


        for (enrtcr__Support_Delivered__c sd : [SELECT Id, enrtcr__Client__c FROM enrtcr__Support_Delivered__c WHERE enrtcr__Current_NDIS_Extract_Item__c = null ]) {
        system.debug('sd client: ' + sd.enrtcr__Client__c);
        items.add(new enrtcr__Extract_Item__c(enrtcr__Service_Delivered__c = sd.Id, enrtcr__Claim_Status__c = 'Error', enrtcr__Extract__c = ext.Id));
        }
        insert items;
        List<enrtcr__Support_Delivered__c> sdsToUpdate = new List<enrtcr__Support_Delivered__c>();

        for (enrtcr__Extract_Item__c item : items) {
        sdsToUpdate.add(new enrtcr__Support_Delivered__c(Id=item.enrtcr__Service_Delivered__c, enrtcr__Current_NDIS_Extract_Item__c = item.Id));
        }

        update sdsToUpdate;

        RemoveOverclaimedItemsController.removeOverclaimedItems(ext.Id);
    }
}