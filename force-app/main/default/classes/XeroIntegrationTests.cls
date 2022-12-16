/**
 * Created by Enrite Solutions on 13/08/2019.
 */

@IsTest
private class XeroIntegrationTests {
    @IsTest
    static void testBehavior() {
        Xero_Private_Settngs__c settings = new Xero_Private_Settngs__c();
        settings.Private_Key__c = 'fakeKet';
        settings.Public_Key__c = 'fakeKet';
        settings.Endpoint__c = 'https://api.xero.com/api.xro/2.0/';
        settings.Certificate_Developer_Name__c = 'SelfSignedCert_16May2019_064215';
        settings.Default_Account_Name__c = 'Test Account';
        insert settings;

        Account defaultAccount = XeroCallBackExtension.getDefaultXeroAccount();
        defaultAccount.Xero_Access_Token__c='234234234';
        defaultAccount.Xero_Tenant_ID__c ='123123123';
        defaultAccount.Name=settings.Default_Account_Name__c;

        insert defaultAccount;

        Id packageIdentifierId = enrtcr__Personal_Identifier__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Accounting_Package_Identifier').recordTypeId;
        Contact c = new Contact(FirstName = 'Test', LastName = 'Test');
        insert c;

        enrtcr__Personal_Identifier__c pi = new enrtcr__Personal_Identifier__c();
        pi.enrtcr__Client__c = c.Id;
        pi.enrtcr__Number__c = 'b7dbd7b5-df12-4eb0-af10-ea31cff989e7';
        pi.RecordTypeId = packageIdentifierId;
        insert pi;


        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new XeroHttpCallMockimpl());
        RetrievePersonalIdentifiersBatch b = new RetrievePersonalIdentifiersBatch();
        Database.executeBatch(b);

        Map<String, Contact> contactRegister =  new Map<String, Contact>();
        contactRegister.put(pi.enrtcr__Number__c, new Contact(Id = pi.enrtcr__Client__c, Total_Amount_Overdue__c = 0, Total_Amount_Outstanding__c = 0, Items_Outstanding__c = 0, Items_Overdue__c = 0));
        RetrieveInvoiceDataBatch b2 = new RetrieveInvoiceDataBatch(contactRegister, 1);
        b2.createAttachment('blah blah');
        Database.executeBatch(b2);

        Test.stopTest();
    }

    @IsTest
    static void testCallouts(){
        Xero_Private_Settngs__c settings = new Xero_Private_Settngs__c();
        settings.Private_Key__c = 'fakeKet';
        settings.Public_Key__c = 'fakeKet';
        settings.Endpoint__c = 'https://api.xero.com/api.xro/2.0/';
        settings.Certificate_Developer_Name__c = 'SelfSignedCert_16May2019_064215';
        insert settings;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new XeroHttpCallMockimpl());
        XeroCalloutUtility.executeCalloutWithPaging('test', 'test', 'test', 'test');
        Test.stopTest();
    }

    @IsTest
    static void testCallouts2(){
        Xero_Private_Settngs__c settings = new Xero_Private_Settngs__c();
        settings.Private_Key__c = 'fakeKet';
        settings.Public_Key__c = 'fakeKet';
        settings.Endpoint__c = 'https://api.xero.com/api.xro/2.0/';
        settings.Certificate_Developer_Name__c = 'SelfSignedCert_16May2019_064215';
        insert settings;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new XeroHttpCallMockimpl());
        XeroCalloutUtility.executeCallout('test', 'test', 'test');
        Test.stopTest();
    }

    @IsTest
    static void testXeroObjects(){
        XeroAddress xA = new XeroAddress();
        xA.AddressType = 'test';
        xA.AddressLine1 = 'test';
        xA.AddressLine2 = 'test';
        xA.AddressLine3 = 'test';
        xA.AddressLine4 = 'test';
        xA.City = 'test';
        xA.Region = 'test';
        xA.PostalCode = 'test';
        xA.Country = 'test';
        xA.AttentionTo = 'test';

        XeroPhone xP = new XeroPhone();
        xP.PhoneAreaCode = 'test';
        xP.PhoneCountryCode = 'test';
        xP.PhoneNumber = 'test';
        xP.PhoneType = 'test';

        XeroContact.AccountsPayable accountsPayable = new XeroContact.AccountsPayable();
        accountsPayable.Overdue = 1.1;
        accountsPayable.Outstanding = 1.1;

        XeroContact.AccountsReceivable accountsReceivable = new XeroContact.AccountsReceivable();
        accountsReceivable.Overdue = 1.1;
        accountsReceivable.Outstanding = 1.1;

        XeroContact.XeroBalance balance = new XeroContact.XeroBalance();
        balance.AccountsPayable = accountsPayable;
        balance.AccountsReceivable = accountsReceivable;

        XeroContact.XeroContactPerson contactPerson = new XeroContact.XeroContactPerson();
        contactPerson.FirstName = 'test';
        contactPerson.LastName = 'test';
        contactPerson.EmailAddress = 'test';
        contactPerson.IncludeInEmails = true;

        XeroContact.XeroAttachment xeroAttachment = new XeroContact.XeroAttachment();
        xeroAttachment.AttachmentID = 'Test';
        xeroAttachment.FileName = 'Test';
        xeroAttachment.Url = 'Test';
        xeroAttachment.MimeType = 'Test';
        xeroAttachment.ContentLength = 1177;

        XeroAddress[] addressList = new XeroAddress[]{xA};

        XeroContact xC = new XeroContact();
        xC.ContactID = 'Test';
        xC.ContactStatus = 'Test';
        xC.Name = 'Test';
        xC.FirstName = 'Test';
        xC.LastName = 'Test';
        xC.EmailAddress = 'Test';
        xC.BankAccountDetails = 'Test';
        xC.SkypeUserName = 'Test';
        xC.Addresses = addressList;
        xC.Phones = new XeroPhone[]{xP};
        xC.UpdatedDateUTC = 'Test';
        xC.ContactGroups = new XeroContact.XeroContactGroup[]{new XeroContact.XeroContactGroup()};
        xC.IsCustomer = true;
        xC.IsSupplier = false;
        xC.DefaultCurrency = 'test';
        xC.Balances = balance;
        xC.ContactPersons = new XeroContact.XeroContactPerson[]{contactPerson};
        xC.HasAttachments = false;
        xC.Attachments = new XeroContact.XeroAttachment[]{xeroAttachment};
        xC.HasValidationErrors = false;

        XeroInvoice.Payment payment = new XeroInvoice.Payment();
        XeroInvoice.CreditNote creditNote = new XeroInvoice.CreditNote();
        XeroInvoice.PrePayment prePayment = new XeroInvoice.PrePayment();
        XeroInvoice.Overpayment overPayment = new XeroInvoice.Overpayment();
        XeroInvoice.cls_Tracking tracking = new XeroInvoice.cls_Tracking();
        XeroInvoice.cls_ValidationErrors validationErrors = new XeroInvoice.cls_ValidationErrors();
        XeroInvoice.cls_Warnings warnings = new XeroInvoice.cls_Warnings();

        XeroInvoice.LineItem lineItem = new XeroInvoice.LineItem();
        lineItem.ItemCode = 'Test';
        lineItem.Description = 'Test';
        lineItem.UnitAmount = 1.1;
        lineItem.TaxType = 'Test';
        lineItem.TaxAmount = 1.1;
        lineItem.LineAmount = 1.1;
        lineItem.AccountCode = 'Test';
        lineItem.Tracking = new XeroInvoice.cls_Tracking[]{tracking};
        lineItem.Quantity = 1.1;
        lineItem.LineItemID = 'Test';
        lineItem.ValidationErrors = new XeroInvoice.cls_ValidationErrors[]{validationErrors};

        XeroInvoice xI = new XeroInvoice();
        xI.Type = 'Test';
        xI.InvoiceID = 'Test';
        xI.InvoiceNumber = 'Test';
        xI.Reference = 'Test';
        xI.DateString = 'Test';
        xI.DueDateString = 'Test';
        xI.DueDateString = 'Test';
        xI.Payments = new XeroInvoice.Payment[]{payment};
        xI.Overpayments = new XeroInvoice.Overpayment[]{overPayment};
        xI.AmountDue = 1.1;
        xI.AmountPaid = 1.0;
        xI.SentToContact = true;
        xI.CurrencyRate = 1.1;
        xI.HasErrors = false;
        xI.IsDiscounted = false;
        xI.Contact = xC;
        xI.Date_x = 'Test';
        xI.DueDateString = 'Test';
        xI.Status = 'Test';
        xI.LineAmountTypes = 'Test';
        xI.LineItems = new XeroInvoice.LineItem[]{lineItem};
        xI.SubTotal = 1.1;
        xI.TotalTax = 1.1;
        xI.Total = 1.1;
        xI.UpdatedDateUTC = 'Test';
        xI.CurrencyCode = 'Test';
        xI.Warnings = new XeroInvoice.cls_Warnings[]{warnings};
        xI.ValidationErrors = new XeroInvoice.cls_ValidationErrors[]{validationErrors};
    }

    @IsTest
    static void testParser(){
        String contactJSON = '{ "ContactID": "b7dbd7b5-df12-4eb0-af10-ea31cff989e7", "Name": "Enrite Test", "Addresses": [], "Phones": [], "ContactGroups": [], "ContactPersons": [], "HasValidationErrors": false }';
        XeroCalloutResponseParser.parseContacts(contactJSON);
    }
}