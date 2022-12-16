/**
 * Created by Enrite Solutions on 23/12/2020.
 */

@IsTest
private class sendExtractToXeroBatchTest {

    @IsTest
    static void testValidateExtractItems() {
        insert new Xero_Private_Settngs__c(
                Private_Key_2_0__c = '11',
                Public_Key__c = '11',
                Public_Key_2_0__c = '11',
                Private_Key__c = '11',
                Endpoint__c = 'https://api.xero.com/api.xro/2.0/'
        );
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        TestLoadData tld = new TestLoadData();
        tld.LoadRecords();
        tld.LoadServiceAgreements();
        tld.LoadServiceDelivered();

        Account acc = XeroCallBackExtension.getDefaultXeroAccount();
        acc.Xero_Access_Token__c = '111';
        acc.Xero_Tenant_ID__c = '111';
        acc.Xero_Refresh_ID__c = '111';
        acc.Xero_Authorisation_Code__c = '111';

        upsert acc;
        Id packageIdentifierId = enrtcr__Personal_Identifier__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Accounting_Package_Identifier').recordTypeId;

        insert new enrtcr__Personal_Identifier__c(enrtcr__Client__c = tld.testClient.Id, RecordTypeId = packageIdentifierId, enrtcr__Number__c = '1234');

        Test.startTest();
        tld.loadExtract();

        for (enrtcr__Extract__c ext : [SELECT Id FROM enrtcr__Extract__c LIMIT 1]){
            sendExtractToXeroController.sendExtractToXero(ext.Id);
            ValidateExtractItemsBatch b = new ValidateExtractItemsBatch(ext.Id, true);
            Database.executeBatch(b);
        }

        Test.stopTest();
    }

    @IsTest
    static void testSendExtractItemsBatch() {
        insert new Xero_Private_Settngs__c(
                Private_Key_2_0__c = '11',
                Public_Key__c = '11',
                Public_Key_2_0__c = '11',
                Private_Key__c = '11',
                Endpoint__c = 'https://api.xero.com/api.xro/2.0/'
        );
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        TestLoadData tld = new TestLoadData();
        tld.LoadRecords();
        tld.LoadServiceAgreements();
        tld.LoadServiceDelivered();


        Account acc = XeroCallBackExtension.getDefaultXeroAccount();
        acc.Xero_Access_Token__c = '111';
        acc.Xero_Tenant_ID__c = '111';
        acc.Xero_Refresh_ID__c = '111';
        acc.Xero_Authorisation_Code__c = '111';

        upsert acc;
        Id packageIdentifierId = enrtcr__Personal_Identifier__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Accounting_Package_Identifier').recordTypeId;
        List<enrtcr__Personal_Identifier__c> piToInsert = new List<enrtcr__Personal_Identifier__c>();

        for (Contact con : [SELECT id FROM Contact]){
            piToInsert.add(new enrtcr__Personal_Identifier__c(enrtcr__Client__c = tld.testClient.Id, RecordTypeId = packageIdentifierId, enrtcr__Number__c = '232c43f1-aaa8-4530-93d4-6f2341c1f3ba'));
        }

        insert piToInsert;

        List<enrtcr__Rate__c> ratesToUpdate = new List<enrtcr__Rate__c>();
        for (enrtcr__Rate__c rate : [SELECT Id, Name, enrtcr__Accounting_Package_Id__c FROM enrtcr__Rate__c WHERE enrtcr__Accounting_Package_Id__c = NULL]){
            rate.enrtcr__Accounting_Package_Id__c = '111';
            ratesToUpdate.add(rate);
        }
        /*update ratesToUpdate;*/

        Test.startTest();
        Id recordTypeFinExtract = enrtcr__Extract__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Financial_Extract').recordTypeId;
        Id recordTypeFinExtractItem = enrtcr__Extract_Item__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Financial_Extract').recordTypeId;

        enrtcr__Extract__c ext = new enrtcr__Extract__c(enrtcr__Start_Date__c = Date.today().addYears(-1), enrtcr__End_Date__c=Date.today().addDays(5), RecordTypeId = recordTypeFinExtract);
        insert ext;
        List<enrtcr__Extract_Item__c> items = new List<enrtcr__Extract_Item__c>();

        for (enrtcr__Support_Delivered__c sd : tld.testServicesDelivered) {
            items.add(new enrtcr__Extract_Item__c(enrtcr__Service_Delivered__c = sd.Id,
                    enrtcr__Claim_Status__c = 'Error',
                    enrtcr__Extract__c = ext.Id,
                    RecordTypeId = recordTypeFinExtractItem,
                    enrtcr__Quantity__c = sd.enrtcr__Quantity__c,
                    enrtcr__Unit_Price__c = String.valueOf(tld.testRates[0].enrtcr__Amount_Ex_GST__c),
                    enrtcr__Total_ex_GST__c = sd.enrtcr__Quantity__c * tld.testRates[0].enrtcr__Amount_Ex_GST__c));
        }
        insert items;

        List<enrtcr__Support_Delivered__c> sdsToUpdate = new List<enrtcr__Support_Delivered__c>();

        for (enrtcr__Extract_Item__c item : items) {
            sdsToUpdate.add(new enrtcr__Support_Delivered__c(Id=item.enrtcr__Service_Delivered__c,
                    enrtcr__Financial_Extract__c = item.Id));
        }
        update sdsToUpdate;

        sendExtractToXeroController.sendExtractToXero(ext.Id);
        sendExtractToXeroBatch b = new sendExtractToXeroBatch(ext.Id);
        Database.executeBatch(b);
        Test.stopTest();
    }

}