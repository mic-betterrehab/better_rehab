/**
 * Created by Enrite Solutions on 9/02/2021.
 */

@IsTest
private class XeroCallBackExtensionTest {
    @IsTest
    static void testFailCallback1() {
        insert new Xero_Private_Settngs__c(
                Private_Key_2_0__c = '11',
                Public_Key__c = '11',
                Public_Key_2_0__c = '11',
                Private_Key__c = '11',
                Endpoint__c = 'https://api.xero.com/api.xro/2.0/',
                Access_Token_URL__c = 'https://identity.xero.com/connect/token'
        );
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Account acc = XeroCallBackExtension.getDefaultXeroAccount();
        acc.Xero_Access_Token__c = '111';
        acc.Xero_Tenant_ID__c = '111';
        acc.Xero_Refresh_ID__c = '111';
        acc.Xero_Authorisation_Code__c = '111';

        upsert acc;


        Test.startTest();

        XeroCallBackExtension b = new XeroCallBackExtension();
        b.callback();

        Test.stopTest();
    }

    @IsTest
    static void testCallBack() {
        insert new Xero_Private_Settngs__c(
                Private_Key_2_0__c = '11',
                Public_Key__c = '11',
                Public_Key_2_0__c = '11',
                Private_Key__c = '11',
                Endpoint__c = 'https://api.xero.com/api.xro/2.0/',
                Access_Token_URL__c = 'https://identity.xero.com/connect/token'
        );
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Account acc = XeroCallBackExtension.getDefaultXeroAccount();
        acc.Xero_Access_Token__c = '111';
        acc.Xero_Tenant_ID__c = '111';
        acc.Xero_Refresh_ID__c = '111';
        acc.Xero_Authorisation_Code__c = '111';

        upsert acc;


        Test.startTest();
        PageReference pg = new PageReference('/apex/callback');
        pg.getParameters().put(XeroCallBackExtension.PARAM_CODE, '1122Code');

        Test.setCurrentPage(pg);
        XeroCallBackExtension b = new XeroCallBackExtension();
        b.callback();

        Test.stopTest();
    }
}