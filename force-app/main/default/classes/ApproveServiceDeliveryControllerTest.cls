@IsTest
private class ApproveServiceDeliveryControllerTest {
    @IsTest
    static void testGetFormDefaults() {
        enrtcr__Site__c site = new enrtcr__Site__c(Name='test');
        insert site;

        enrtcr__Site_User__c su = new enrtcr__Site_User__c(enrtcr__Site__c=site.id, enrtcr__User__c = UserInfo.getUserId());
        insert su;

        ApproveServiceDeliveryController.FormDefault formDefault = ApproveServiceDeliveryController.getFormDefaults();
        System.assert(formDefault != null);
        System.assertEquals(2, formDefault.sites.size());
        //System.assertEquals(Date.newInstance(2019,1,1), formDefault.startDate);
        System.assertEquals(Date.today().addMonths(-3), formDefault.startDate);
        System.assertEquals(Date.today(), formDefault.endDate);
    }

    @IsTest
    static void testApprove() {
        ApproveServiceDeliveryController.ApprovalRequest request = new ApproveServiceDeliveryController.ApprovalRequest();
        request.approvals = new List<ApproveServiceDeliveryController.SdWrapper>();
        ApproveServiceDeliveryController.SdWrapper sdWrapper = new ApproveServiceDeliveryController.SdWrapper();
        sdWrapper.serviceName = 'Test';
        sdWrapper.id = null;
        sdWrapper.name = 'sd name';
        sdWrapper.clientName = 'johnny';
        sdWrapper.serviceName = 'sname';
        sdWrapper.quantity = '1 Hour';
        sdWrapper.comments = 'comment';
        sdWrapper.workerName = 'worker';
        sdWrapper.totalCost = 100;
        sdWrapper.cancelled = false;
        sdWrapper.deliveryDate = Date.today();
        sdWrapper.saName = 'SA-00001';
        sdWrapper.saId = null;
        sdWrapper.totalExtractedCost = '';
        sdWrapper.totalExtractedQuantity = '';
        sdWrapper.setTotalExtracted(10);
        request.approvals.add(sdWrapper);
        request.approvals.add(new ApproveServiceDeliveryController.SdWrapper(new enrtcr__Support_Delivered__c()));

        ApproveServiceDeliveryController.approveRecords(JSON.serialize(request));

        TestLoadData data = new TestLoadData();
        data.LoadRecords();
        data.LoadServiceAgreements();
        data.LoadServiceDelivered();

        Test.startTest();
        request.approvals = new List<ApproveServiceDeliveryController.SdWrapper>();
        request.approvals.add(new ApproveServiceDeliveryController.SdWrapper(data.testSupportDelivered));
        ApproveServiceDeliveryController.approveRecords(JSON.serialize(request));

        List<Record_Approval__c> approvals = [SELECT ID FROM Record_Approval__c];
        update approvals;
        delete approvals;

        Test.stopTest();
    }

    @IsTest
    static void testGetSdRecords() {
        enrtcr__Site__c site = new enrtcr__Site__c(Name='test');
        insert site;

        enrtcr__Site_User__c su = new enrtcr__Site_User__c(enrtcr__Site__c=site.id, enrtcr__User__c = UserInfo.getUserId());
        insert su;

        List<ApproveServiceDeliveryController.SdWrapper> records = ApproveServiceDeliveryController.getSdRecords('', Date.today(), Date.today(), '');
        System.assertEquals(0, records.size());
    }
}