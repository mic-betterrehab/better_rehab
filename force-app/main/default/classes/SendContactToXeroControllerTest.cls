/**
 * Created by Enrite Solutions on 5/01/2021.
 */

@IsTest
private class SendContactToXeroControllerTest {
    @IsTest
    static void testBehavior() {
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

        // the most legitimate Xero dets ever... ill just mock the response here if needed
        Account acc = XeroCallBackExtension.getDefaultXeroAccount();
        acc.Xero_Access_Token__c = '111';
        acc.Xero_Tenant_ID__c = '111';
        acc.Xero_Refresh_ID__c = '111';
        acc.Xero_Authorisation_Code__c = '111';

        upsert acc;


        Contact con = tld.testClient;
        Test.startTest();

        SendContactToXeroController.sendContactToXero(con.Id);

        Test.stopTest();
    }

    @IsTest
    static void insertContactNoAddress() {
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

        // the most legitimate Xero dets ever... ill just mock the response here if needed
        Account acc = XeroCallBackExtension.getDefaultXeroAccount();
        acc.Xero_Access_Token__c = '111';
        acc.Xero_Tenant_ID__c = '111';
        acc.Xero_Refresh_ID__c = '111';
        acc.Xero_Authorisation_Code__c = '111';

        upsert acc;


        Contact testClient = new Contact(
                FirstName ='NoAddressTest',
                LastName = 'NoAddressTest',
                enrtcr__Sex__c = 'Male',
                Birthdate = Date.parse('01/01/1970'),
                enrtcr__Photo__c = '<img src="test" />',
                enrtcr__Secondary_Disability__c = 'test',
                enrtcr__Date_Client_Registered__c = Date.today(),
                Phone = '12333333',
                enrtcr__Preferred_Communication_Method__c = 'Phone',
                enrtcr__Primary_Disability__c = 'Autism',
                enrtcr__Status__c = 'Current',
                enrtcr__Summary_Disability__c = 'Autism',
                enrtcr__Requires_Support_for_Decision_Making__c = 'No',
                enrtcr__Client_Region__c = 'Northern',
                //Family_Complexity__c = 'High',
                MobilePhone = '04111551',
                enrtcr__Active__c=true
        );

        insert testClient;
        Test.startTest();

        SendContactToXeroController.sendContactToXero(testClient.Id);

        Test.stopTest();
    }


    @IsTest
    static void updateContactXero() {
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
        Id packageIdentifierId = enrtcr__Personal_Identifier__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Accounting_Package_Identifier').recordTypeId;

        insert new enrtcr__Personal_Identifier__c(enrtcr__Client__c = tld.testClient.Id, RecordTypeId = packageIdentifierId, enrtcr__Number__c = '1234');

        // the most legitimate Xero dets ever... ill just mock the response here if needed
        Account acc = XeroCallBackExtension.getDefaultXeroAccount();
        acc.Xero_Access_Token__c = '111';
        acc.Xero_Tenant_ID__c = '111';
        acc.Xero_Refresh_ID__c = '111';
        acc.Xero_Authorisation_Code__c = '111';

        upsert acc;


        Contact con = tld.testClient;
        Test.startTest();

        SendContactToXeroController.sendContactToXero(con.Id);

        Test.stopTest();
    }

    @IsTest
    public static void testRefreshToken(){
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
        SendContactToXeroController controller = new SendContactToXeroController();
        SendContactToXeroController.refreshToken(acc);
        Test.stopTest();
    }

    @IsTest
    public static void testAuthXero(){
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
        SendContactToXeroController controller = new SendContactToXeroController();
        controller.authXero();
        Test.stopTest();
    }
}