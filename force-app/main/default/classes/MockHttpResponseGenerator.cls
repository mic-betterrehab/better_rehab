/**
 * Created by Enrite Solutions on 9/02/2021.
 */
@IsTest
global with sharing class MockHttpResponseGenerator implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest req) {

        // mocking specific end points, these payloads are actual responses from a dev enviromnent
        if (req.getEndpoint() == 'https://api.xero.com/api.xro/2.0/Contacts'){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(getContactResponse());
            res.setStatusCode(200);
            return res;
        } else if (req.getEndpoint() == 'https://identity.xero.com/connect/token'){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(getTokenResponse());
            res.setStatusCode(200);
            return res;
        } else if (req.getEndpoint() == 'https://api.xero.com/connections'){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(getConnectionsResponse());
            res.setStatusCode(200);
            return res;
        } else {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(getInvoiceResponse());
            res.setStatusCode(200);
            return res;
        }
    }

    private static String getConnectionsResponse(){
        return '[\n' +
                '    {\n' +
                '        "id": "e1eede29-f875-4a5d-8470-17f6a29a88b1",\n' +
                '        "authEventId": "d99ecdfe-391d-43d2-b834-17636ba90e8d",\n' +
                '        "tenantId": "70784a63-d24b-46a9-a4db-0e70a274b056",\n' +
                '        "tenantType": "ORGANISATION",\n' +
                '        "tenantName": "Maple Florist",\n' +
                '        "createdDateUtc": "2019-07-09T23:40:30.1833130",\n' +
                '        "updatedDateUtc": "2020-05-15T01:35:13.8491980"\n' +
                '    },\n' +
                '    {\n' +
                '        "id": "32587c85-a9b3-4306-ac30-b416e8f2c841",\n' +
                '        "authEventId": "d0ddcf81-f942-4f4d-b3c7-f98045204db4",\n' +
                '        "tenantId": "e0da6937-de07-4a14-adee-37abfac298ce",\n' +
                '        "tenantType": "ORGANISATION",\n' +
                '        "tenantName": "Adam Demo Company (NZ)",\n' +
                '        "createdDateUtc": "2020-03-23T02:24:22.2328510",\n' +
                '        "updatedDateUtc": "2020-05-13T09:43:40.7689720"\n' +
                '    },\n' +
                '    {\n' +
                '        "id": "74305bf3-12e0-45e2-8dc8-e3ec73e3b1f9",\n' +
                '        "authEventId": "d0ddcf81-f942-4f4d-b3c7-f98045204db4",\n' +
                '        "tenantId": "c3d5e782-2153-4cda-bdb4-cec791ceb90d",\n' +
                '        "tenantType": "PRACTICEMANAGER",\n' +
                '        "tenantName": null,\n' +
                '        "createdDateUtc": "2020-01-30T01:33:36.2717380",\n' +
                '        "updatedDateUtc": "2020-02-02T19:21:08.5739590"\n' +
                '    }\n' +
                ']';
    }

    private static String getTokenResponse() {
        return '{\n' +
                '    "nbf": 1589363023,\n' +
                '    "exp": 1589364823,\n' +
                '    "iss": "https://identity.xero.com",\n' +
                '    "aud": "https://identity.xero.com/resources",\n' +
                '    "client_id": "91E5715B1199038080D6D0296EBC1648",\n' +
                '    "sub": "a3a4dbafh3495a808ed7a7b964388f53",\n' +
                '    "auth_time": 1589361892,\n' +
                '    "xero_userid": "1945393b-6eb7-4143-b083-7ab26cd7690b",\n' +
                '    "global_session_id": "ac2202575e824af3a181c50fcaa65c3c",\n' +
                '    "jti": "4e7747cec4ce54d6512b4b0775166c5f",\n' +
                '    "authentication_event_id": "d0ddcf81-f942-4f4d-b3c7-f98045204db4",\n' +
                '    "scope": [\n' +
                '      "email",\n' +
                '      "profile",\n' +
                '      "openid",\n' +
                '      "accounting.transactions",\n' +
                '      "accounting.settings",\n' +
                '      "offline_access"\n' +
                '    ]\n' +
                '  }';
    }

    private static String getInvoiceResponse(){
        return '{\n' +
                '"Id": "d164a047-5fae-444b-b926-092dab42781a",\n' +
                '"Status": "OK",\n' +
                '"ProviderName": "Outh 2",\n' +
                '"DateTimeUTC": "\\/Date(1612755617994)\\/",\n' +
                '"Invoices": [\n' +
                '{\n' +
                    '"Type": "ACCREC",\n' +
                    '"InvoiceID": "00000000-0000-0000-0000-000000000000",\n' +
                    '"InvoiceNumber": "INV-23733-1398",\n' +
                    '"Reference": "INV-23733-1398",\n' +
                    '"Payments": [],\n' +
                    '"CreditNotes": [],\n' +
                    '"Prepayments": [],\n' +
                    '"Overpayments": [],\n' +
                    '"IsDiscounted": false,\n' +
                    '"HasErrors": true,\n' +
                    '"Contact": {\n' +
                        '"ContactID": "232c43f1-aaa8-4530-93d4-6f2341c1f3ba",\n' +
                        '"Name": "Enrite Test Test",\n' +
                        '"FirstName": "Enrite",\n' +
                        '"LastName": "Test",\n' +
                        '"Addresses": [],\n' +
                        '"Phones": [],\n' +
                        '"ContactGroups": [],\n' +
                        '"ContactPersons": [],\n' +
                        '"HasValidationErrors": false,\n' +
                        '"ValidationErrors": []\n' +
                    '},\n' +
                    '"DateString": "2021-01-04T00:00:00",\n' +
                    '"Date": "\\/Date(1609718400000+0000)\\/",\n' +
                    '"DueDateString": "2021-01-18T00:00:00",\n' +
                    '"DueDate": "\\/Date(1610928000000+0000)\\/",\n' +
                    '"Status": "DRAFT",\n' +
                    '"LineAmountTypes": "Exclusive",\n' +
                    '"LineItems": [\n' +
                        '{\n' +
                            '"ItemCode": "200",\n' +
                            '"Description": "2021-01-04-Enrite Test Test-Not NDIS 1-11233",\n' +
                            '"UnitAmount": 20.008,\n' +
                            '"TaxType": "EXEMPTOUTPUT",\n' +
                            '"TaxAmount": 0.00,\n' +
                            '"LineAmount": 100.04,\n' +
                            '"AccountCode": "200",\n' +
                            '"Tracking": [\n' +
                                '{\n' +
                                '"Name": "Site",\n' +
                                '"Option": "Bankstown",\n' +
                                '"TrackingCategoryID": "00000000-0000-0000-0000-000000000000",\n' +
                                '"Options": [],\n' +
                                '"ValidationErrors": []\n' +
                            '},\n' +
                            '{\n' +
                                '"Name": "Site",\n' +
                                '"Option": "Blacktown",\n' +
                                '"TrackingCategoryID": "00000000-0000-0000-0000-000000000000",\n' +
                                '"Options": [],\n' +
                                '"ValidationErrors": []\n' +
                            '},\n' +
                            '{\n' +
                                '"Name": "State",\n' +
                                '"Option": "NSW",\n' +
                                '"TrackingCategoryID": "00000000-0000-0000-0000-000000000000",\n' +
                                '"Options": [],\n' +
                                '"ValidationErrors": []\n' +
                            '}\n' +
                        '],\n' +
                            '"Quantity": 5.0000,\n' +
                            '"AccountID": "2c442875-828f-4b05-a38d-5f0c5f0cb4f1",\n' +
                            '"ValidationErrors": []\n' +
                        '},\n' +
                        '{\n' +
                            '"ItemCode": "988",\n' +
                            '"Description": "2021-01-04-Enrite Test Test-Not NDIS 1-11233",\n' +
                            '"UnitAmount": 20.0,\n' +
                            '"TaxType": "EXEMPTOUTPUT",\n' +
                            '"TaxAmount": 0.00,\n' +
                            '"LineAmount": 120.00,\n' +
                            '"Tracking": [\n' +
                            '{\n' +
                                '"Name": "Site",\n' +
                                '"Option": "Bankstown",\n' +
                                '"TrackingCategoryID": "00000000-0000-0000-0000-000000000000",\n' +
                                '"Options": [],\n' +
                                '"ValidationErrors": []\n' +
                            '},\n' +
                            '{\n' +
                                '"Name": "Site",\n' +
                                '"Option": "Blacktown",\n' +
                                '"TrackingCategoryID": "00000000-0000-0000-0000-000000000000",\n' +
                                '"Options": [],\n' +
                                '"ValidationErrors": []\n' +
                            '},\n' +
                            '{\n' +
                                '"Name": "State",\n' +
                                '"Option": "NSW",\n' +
                                '"TrackingCategoryID": "00000000-0000-0000-0000-000000000000",\n' +
                                '"Options": [],\n' +
                                '"ValidationErrors": []\n' +
                            '}\n' +
                        '],\n' +
                        '"Quantity": 6.0000,\n' +
                        '"ValidationErrors": []\n' +
                    '},\n' +
                    '{\n' +
                        '"ItemCode": "988",\n' +
                        '"Description": "2021-01-04-Enrite Test Test-Not NDIS 1-11233",\n' +
                        '"UnitAmount": 20.008,\n' +
                        '"TaxType": "EXEMPTOUTPUT",\n' +
                        '"TaxAmount": 0.00,\n' +
                        '"LineAmount": 100.04,\n' +
                        '"Tracking": [\n' +
                            '{\n' +
                                '"Name": "Site",\n' +
                                '"Option": "Bankstown",\n' +
                                '"TrackingCategoryID": "00000000-0000-0000-0000-000000000000",\n' +
                                '"Options": [],\n' +
                    '"ValidationErrors": []\n' +
                '},\n' +
                '{\n' +
                '"Name": "Site",\n' +
                '"Option": "Blacktown",\n' +
                '"TrackingCategoryID": "00000000-0000-0000-0000-000000000000",\n' +
                '"Options": [],\n' +
                '"ValidationErrors": []\n' +
                '},\n' +
                '{\n' +
                '"Name": "State",\n' +
                '"Option": "NSW",\n' +
                '"TrackingCategoryID": "00000000-0000-0000-0000-000000000000",\n' +
                '"Options": [],\n' +
                '"ValidationErrors": []\n' +
                '}\n' +
                '],\n' +
                '"Quantity": 5.0000,\n' +
                '"ValidationErrors": []\n' +
                '}\n' +
                '],\n' +
                '"SubTotal": 320.08,\n' +
                '"TotalTax": 0.00,\n' +
                '"Total": 320.08,\n' +
                '"CurrencyCode": "AUD",\n' +
                '"StatusAttributeString": "ERROR",\n' +
                '"ValidationErrors": [\n' +
                '{\n' +
                '"Message": "Item code \'988\' is not valid"\n' +
                '},\n' +
                '{\n' +
                '"Message": "Item code \'988\' is not valid"\n' +
                '}\n' +
                '],\n' +
                '"Warnings": [\n' +
                '{\n' +
                '"Message": "Account code \'988\' has been removed as it does not match a recognised account."\n' +
                '},\n' +
                '{\n' +
                '"Message": "Account code \'988\' has been removed as it does not match a recognised account."\n' +
                '}\n' +
                ']\n' +
                '}' +
                ']\n' +
                '}';
    }

    private static String getContactResponse(){
        return '{\n' +
                '"Id": "b46b37c7-d307-408b-bb5b-2145e2d13f39",\n' +
                '"Status": "OK",\n' +
                '"ProviderName": "Outh 2",\n' +
                '"DateTimeUTC": "\\/Date(1609990155126)\\/",\n' +
                '"Contacts": [\n' +
                '{\n' +
                '"ContactID": "c53d0d54-e37b-48ae-8f7a-0da04c0d8aed",\n' +
                '"ContactStatus": "ACTIVE",\n' +
                '"Name": "Enrite Test Test",\n' +
                '"FirstName": "Enrite",\n' +
                '"LastName": "Test",\n' +
                '"EmailAddress": "test@test.com",\n' +
                '"BankAccountDetails": "",\n' +
                '"Addresses": [\n' +
                '{\n' +
                '"AddressType": "STREET",\n' +
                '"City": "",\n' +
                '"Region": "",\n' +
                '"PostalCode": "",\n' +
                '"Country": ""\n' +
                '},\n' +
                '{\n' +
                '"AddressType": "POBOX",\n' +
                '"AddressLine1": "120 Angas Street",\n' +
                '"City": "Adelaide",\n' +
                '"Region": "SA",\n' +
                '"PostalCode": "5000",\n' +
                '"Country": ""\n' +
                '}\n' +
                '],\n' +
                '"Phones": [\n' +
                '{\n' +
                '"PhoneType": "DEFAULT",\n' +
                '"PhoneNumber": "",\n' +
                '"PhoneAreaCode": "",\n' +
                '"PhoneCountryCode": ""\n' +
                '},\n' +
                '{\n' +
                '"PhoneType": "DDI",\n' +
                '"PhoneNumber": "",\n' +
                '"PhoneAreaCode": "",\n' +
                '"PhoneCountryCode": ""\n' +
                '},\n' +
                '{\n' +
                '"PhoneType": "FAX",\n' +
                '"PhoneNumber": "",\n' +
                '"PhoneAreaCode": "",\n' +
                '"PhoneCountryCode": ""\n' +
                '},\n' +
                '{\n' +
                '"PhoneType": "MOBILE",\n' +
                '"PhoneNumber": "",\n' +
                '"PhoneAreaCode": "",\n' +
                '"PhoneCountryCode": ""\n' +
                '}\n' +
                '],\n' +
                '"UpdatedDateUTC": "\\/Date(1609796020380+0000)\\/",\n' +
                '"ContactGroups": [],\n' +
                '"IsSupplier": false,\n' +
                '"IsCustomer": true,\n' +
                '"SalesTrackingCategories": [],\n' +
                '"PurchasesTrackingCategories": [],\n' +
                '"ContactPersons": [],\n' +
                '"HasValidationErrors": false\n' +
                '},\n' +
                '{\n' +
                '"ContactID": "2e57a040-404e-4555-b924-3d268baa69d2",\n' +
                '"ContactStatus": "ACTIVE",\n' +
                '"Name": "sixth The Test",\n' +
                '"FirstName": "sixth",\n' +
                '"LastName": "Test",\n' +
                '"EmailAddress": "",\n' +
                '"BankAccountDetails": "",\n' +
                '"Addresses": [\n' +
                '{\n' +
                '"AddressType": "STREET",\n' +
                '"City": "",\n' +
                '"Region": "",\n' +
                '"PostalCode": "",\n' +
                '"Country": ""\n' +
                '},\n' +
                '{\n' +
                '"AddressType": "POBOX",\n' +
                '"AddressLine1": "120 Angas Street",\n' +
                '"City": "Adelaide",\n' +
                '"Region": "SA",\n' +
                '"PostalCode": "5000",\n' +
                '"Country": ""\n' +
                '}\n' +
                '],\n' +
                '"Phones": [\n' +
                '{\n' +
                '"PhoneType": "DEFAULT",\n' +
                '"PhoneNumber": "",\n' +
                '"PhoneAreaCode": "",\n' +
                '"PhoneCountryCode": ""\n' +
                '},\n' +
                '{\n' +
                '"PhoneType": "DDI",\n' +
                '"PhoneNumber": "",\n' +
                '"PhoneAreaCode": "",\n' +
                '"PhoneCountryCode": ""\n' +
                '},\n' +
                '{\n' +
                '"PhoneType": "FAX",\n' +
                '"PhoneNumber": "",\n' +
                '"PhoneAreaCode": "",\n' +
                '"PhoneCountryCode": ""\n' +
                '},\n' +
                '{\n' +
                '"PhoneType": "MOBILE",\n' +
                '"PhoneNumber": "",\n' +
                '"PhoneAreaCode": "",\n' +
                '"PhoneCountryCode": ""\n' +
                '}\n' +
                '],\n' +
                '"UpdatedDateUTC": "\\/Date(1609976724373+0000)\\/",\n' +
                '"ContactGroups": [],\n' +
                '"IsSupplier": false,\n' +
                '"IsCustomer": false,\n' +
                '"SalesTrackingCategories": [],\n' +
                '"PurchasesTrackingCategories": [],\n' +
                '"ContactPersons": [],\n' +
                '"HasValidationErrors": false\n' +
                '},\n' +
                '{\n' +
                '"ContactID": "977b9fd4-0409-405f-b215-d158abd98c17",\n' +
                '"ContactStatus": "ACTIVE",\n' +
                '"Name": "seventh The Test",\n' +
                '"FirstName": "seventh",\n' +
                '"LastName": "Test",\n' +
                '"EmailAddress": "",\n' +
                '"BankAccountDetails": "",\n' +
                '"Addresses": [\n' +
                '{\n' +
                '"AddressType": "STREET",\n' +
                '"City": "",\n' +
                '"Region": "",\n' +
                '"PostalCode": "",\n' +
                '"Country": ""\n' +
                '},\n' +
                '{\n' +
                '"AddressType": "POBOX",\n' +
                '"AddressLine1": "120 Angas Street",\n' +
                '"City": "Adelaide",\n' +
                '"Region": "SA",\n' +
                '"PostalCode": "5000",\n' +
                '"Country": ""\n' +
                '}\n' +
                '],\n' +
                '"Phones": [\n' +
                '{\n' +
                '"PhoneType": "DEFAULT",\n' +
                '"PhoneNumber": "",\n' +
                '"PhoneAreaCode": "",\n' +
                '"PhoneCountryCode": ""\n' +
                '},\n' +
                '{\n' +
                '"PhoneType": "DDI",\n' +
                '"PhoneNumber": "",\n' +
                '"PhoneAreaCode": "",\n' +
                '"PhoneCountryCode": ""\n' +
                '},\n' +
                '{\n' +
                '"PhoneType": "FAX",\n' +
                '"PhoneNumber": "",\n' +
                '"PhoneAreaCode": "",\n' +
                '"PhoneCountryCode": ""\n' +
                '},\n' +
                '{\n' +
                '"PhoneType": "MOBILE",\n' +
                '"PhoneNumber": "",\n' +
                '"PhoneAreaCode": "",\n' +
                '"PhoneCountryCode": ""\n' +
                '}\n' +
                '],\n' +
                '"UpdatedDateUTC": "\\/Date(1609976724483+0000)\\/",\n' +
                '"ContactGroups": [],\n' +
                '"IsSupplier": false,\n' +
                '"IsCustomer": false,\n' +
                '"SalesTrackingCategories": [],\n' +
                '"PurchasesTrackingCategories": [],\n' +
                '"ContactPersons": [],\n' +
                '"HasValidationErrors": false\n' +
                '},\n' +
                '{\n' +
                '"ContactID": "d8fd6fe2-fa42-464f-b8cd-244eecd578b9",\n' +
                '"ContactStatus": "ACTIVE",\n' +
                '"Name": "Second The Test",\n' +
                '"FirstName": "Second",\n' +
                '"LastName": "Test",\n' +
                '"EmailAddress": "",\n' +
                '"BankAccountDetails": "",\n' +
                '"Addresses": [\n' +
                '{\n' +
                '"AddressType": "STREET",\n' +
                '"City": "",\n' +
                '"Region": "",\n' +
                '"PostalCode": "",\n' +
                '"Country": ""\n' +
                '},\n' +
                '{\n' +
                '"AddressType": "POBOX",\n' +
                '"AddressLine1": "120 Angas Street",\n' +
                '"City": "Adelaide",\n' +
                '"Region": "SA",\n' +
                '"PostalCode": "5000",\n' +
                '"Country": ""\n' +
                '}\n' +
                '],\n' +
                '"Phones": [\n' +
                '{\n' +
                '"PhoneType": "DEFAULT",\n' +
                '"PhoneNumber": "",\n' +
                '"PhoneAreaCode": "",\n' +
                '"PhoneCountryCode": ""\n' +
                '},\n' +
                '{\n' +
                '"PhoneType": "DDI",\n' +
                '"PhoneNumber": "",\n' +
                '"PhoneAreaCode": "",\n' +
                '"PhoneCountryCode": ""\n' +
                '},\n' +
                '{\n' +
                '"PhoneType": "FAX",\n' +
                '"PhoneNumber": "",\n' +
                '"PhoneAreaCode": "",\n' +
                '"PhoneCountryCode": ""\n' +
                '},\n' +
                '{\n' +
                '"PhoneType": "MOBILE",\n' +
                '"PhoneNumber": "",\n' +
                '"PhoneAreaCode": "",\n' +
                '"PhoneCountryCode": ""\n' +
                '}\n' +
                '],\n' +
                '"UpdatedDateUTC": "\\/Date(1609965641910+0000)\\/",\n' +
                '"ContactGroups": [],\n' +
                '"IsSupplier": false,\n' +
                '"IsCustomer": true,\n' +
                '"SalesTrackingCategories": [],\n' +
                '"PurchasesTrackingCategories": [],\n' +
                '"ContactPersons": [],\n' +
                '"HasValidationErrors": false\n' +
                '}\n' +
                ']\n' +
                '}';
    }
}