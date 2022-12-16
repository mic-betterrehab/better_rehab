/**
 * Created by Enrite Solutions on 11/12/2020.
 */

public with sharing class SendContactToXeroController {

    public static Integer PAYLOAD_STRING_LIMIT = 128000;
    public static Integer RESPONSE_STRING_LIMIT = 131072;

    public static final String STRING_TOO_LARGE_RESPONSE = 'Response is too large. please see attached response file.';
    public static final String STRING_TOO_LARGE_PAYLOAD = 'Payload is too large. please see attached Payload File.';


    @AuraEnabled(Continuation=true)
    public static String sendContactToXero(final Id contactId){
        Boolean isSuccess = true;
        String payload = '';
        try {
            if (contactId == null){
                throw new CustomException('Contact Id Is Null');
            }
            Contact queriedContact = getContact(contactId);
            upsertContactToXero(queriedContact);
        } catch (Exception e){
            isSuccess = false;
            payload = e.getMessage() + '\n' + e.getStackTraceString();
        }
        return getResponse(isSuccess,payload);
    }

    private static Boolean isSObjectListNotEmpty(final List<SObject> sObjectList){
        return sObjectList != null &&
                !sObjectList.isEmpty();
    }

    private static void upsertContactToXero(final Contact contactToUpsertToXero){
        // the default account stores information used to send data to Xero, hence why it is queried (OUATH2.0)
        Account defaultAccount = XeroCallBackExtension.getDefaultXeroAccount();
        XeroContact xeroContact = createXeroContact(contactToUpsertToXero);
        HttpResponse response;
        // we store Xero Ids as perosnal Identifiers... small differences in the request but essentially if they have a personal identifier update xero con, or else we insert a new one
        if (isSObjectListNotEmpty(contactToUpsertToXero.enrtcr__Personal_Identifiers__r)){
            response = updateContactToXero(contactToUpsertToXero, xeroContact, defaultAccount);
        } else {
            response = insertContactToXero(contactToUpsertToXero, xeroContact, defaultAccount);
        }
        processResponseForError(response);
    }

    private static void processResponseForError(HttpResponse res){
        if (res == null){
            throw new CustomException('No Response.');
        } else if (res.getStatusCode() != RetrieveInvoiceDataBatch.OK_STATUS_CODE){
            throw new CustomException(res.getBody());
        }
    }

    public static void buildNewLog(HttpResponse response, String endPoint, HTTPRequest req){
        // we insert a log, if the response text is too long to store in the response field, we minise text first, if we still cannot fit it on the field we create text files against the Intgration log
        enrtcr__Integration_Log__c log = new enrtcr__Integration_Log__c();
        log.enrtcr__Status__c = response.getStatus() == RetrieveInvoiceDataBatch.OK_STATUS ? RetrieveInvoiceDataBatch.COMPLETE_STATUS : RetrieveInvoiceDataBatch.ERROR_STATUS;
        log.enrtcr__Error_Message__c = response.getStatus() == RetrieveInvoiceDataBatch.OK_STATUS ? '' : response.getBody();
        log.enrtcr__Method__c = XeroConstants.POST_METHOD;
        log.enrtcr__Source_System__c = RetrieveInvoiceDataBatch.LUMARY_SOURCE;
        log.enrtcr__Destination_System__c = RetrieveInvoiceDataBatch.XERO_DESTINATION;

        List<Attachment> attachmentsToInsert = new List<Attachment>();


        String responseBody = response.getBody();
        if (responseBody.length() >= RESPONSE_STRING_LIMIT){
            responseBody = minimiseJsonString(responseBody);
            if (responseBody.length() >= RESPONSE_STRING_LIMIT){
                log.enrtcr__Response__c = STRING_TOO_LARGE_RESPONSE;
                attachmentsToInsert.add(createLogAttachment(responseBody, 'Response.txt'));
            } else {
                log.enrtcr__Response__c = responseBody;
            }
        } else {
            log.enrtcr__Response__c = responseBody;
        }

        String payloadString = endPoint + '\n' + req.getBody();
        if (payloadString.length() >= PAYLOAD_STRING_LIMIT){
            payloadString = endPoint + '\n' + minimiseJsonString(req.getBody());
            if (payloadString.length() >= PAYLOAD_STRING_LIMIT){
                log.enrtcr__Payload__c = STRING_TOO_LARGE_PAYLOAD;
                attachmentsToInsert.add(createLogAttachment(responseBody, 'Request.txt'));
            } else {
                log.enrtcr__Payload__c = payloadString;
            }
        } else {
            log.enrtcr__Payload__c = payloadString;
        }

        insert log;

        if (attachmentsToInsert != null && !attachmentsToInsert.isEmpty()){
            for (Attachment attLog : attachmentsToInsert){
                attLog.ParentId = log.Id;
            }
            insert attachmentsToInsert;
        }
    }

    private static Attachment createLogAttachment(String attBody, String attachName){
        Attachment attToInsert = new Attachment();
        attToInsert.Name = attachName;
        attToInsert.Body = Blob.valueOf(attBody);
        attToInsert.ContentType = 'text/plain';
        return attToInsert;
    }

    private static String minimiseJsonString(String jsonString){
        return JSON.serialize(JSON.deserializeUntyped(jsonString));
    }

    private static HttpResponse insertContactToXero(final Contact contactToUpsertToXero, XeroContact xeroContact, Account defaultAccount) {
        String requestBody = JSON.serialize(xeroContact);
        HttpRequest request = XeroCalloutUtility.createRequestForOUATH2(XeroConstants.POST_METHOD, 'Contacts', requestBody , defaultAccount.Xero_Access_Token__c);
        HttpResponse response = XeroCalloutUtility.sendRequest(request);
        Http client = new Http();
        response = client.send(request);
        Integer statusCode = response.getStatusCode();

        // if the httprequest fails, we assume that is because of the bad access token, we do a call out to refresh the token and then try again... Token information is saved onto defaultAccount
        if (statusCode != XeroCallBackExtension.STATUS_CODE_GOOD_REQUEST) {
            String accessToken = refreshToken(defaultAccount);
            if (String.isNotBlank(accessToken)) {
                request = XeroCalloutUtility.createRequestForOUATH2(XeroConstants.POST_METHOD, 'Contacts', requestBody , defaultAccount.Xero_Access_Token__c);
                response = client.send(request);
            }
        }
        insertPersonalIdentifier(response, contactToUpsertToXero.Id);
        update defaultAccount;
        buildNewLog(response, request.getEndpoint(), request);
        return response;
    }

    private static void insertPersonalIdentifier(HttpResponse hhtpRes, final Id clientId){
        if (hhtpRes.getStatusCode() == XeroCallBackExtension.STATUS_CODE_GOOD_REQUEST){
            Id packageIdentifierId = enrtcr__Personal_Identifier__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Accounting_Package_Identifier').recordTypeId;
            List<XeroContact> contacts = XeroCalloutResponseParser.parseContacts(hhtpRes.getBody());
            insert new enrtcr__Personal_Identifier__c(
                    RecordTypeId = packageIdentifierId,
                    enrtcr__Client__c = clientId,
                    enrtcr__Number__c = contacts.get(0).ContactID
            );
        }
    }

    public static String refreshToken(Account defaultAccount) {
        String accessToken = '';
        String auth = EncodingUtil.base64Encode(Blob.valueOf( XeroOAuthUtility.XERO_SETTINGS.Public_Key_2_0__c + ':' + XeroOAuthUtility.XERO_SETTINGS.Private_Key_2_0__c));

        Http client = new Http();
        HttpRequest request = new HttpRequest();

        request.setHeader(XeroCallBackExtension.PARAM_AUTHORIZATION, XeroCallBackExtension.PARAM_BASIC + auth);
        request.setHeader(XeroCallBackExtension.PARAM_CONTENT_TYPE, XeroCallBackExtension.PARAM_CONTENT_TYPE_FORM_DATA);
        request.setMethod('POST');
        request.setEndpoint(XeroOAuthUtility.XERO_SETTINGS.Access_Token_URL__c);

        // CALL REFRESH TOKEN TO GET A NEW TOKEN FOR THE TRANSACTION.
        request.setBody(getRefreshTokenBody(defaultAccount));
        HttpResponse response = client.send(request);

        if (response.getStatusCode() == XeroCallBackExtension.STATUS_CODE_GOOD_REQUEST) {
            XeroCallBackExtension.AccessToken token = (XeroCallBackExtension.AccessToken)
                    JSON.deserialize(response.getBody(), XeroCallBackExtension.AccessToken.class);
            if (token != null) {
                accessToken = token.access_token;
                defaultAccount.Xero_Refresh_ID__c = token.refresh_token;
                defaultAccount.Xero_Access_Token__c = accessToken;
            }
        }
        return accessToken;
    }

    public static String getRefreshTokenBody(Account defaultAccount) {
        String body = '';
        body += XeroCallBackExtension.paramVal(XeroCallBackExtension.PARAM_GRANT_TYPE, XeroCallBackExtension.PARAM_REFRESH_TOKEN, true);
        body += XeroCallBackExtension.paramVal(XeroCallBackExtension.PARAM_REFRESH_TOKEN, defaultAccount.Xero_Refresh_ID__c, false);
        return body;
    }


    private static List<XeroPhone> createXeroMobileNumber(final Contact contactToUpsertToXero){
        List<XeroPhone> xeroPhones = new List<XeroPhone>();
        if (String.isNotBlank(contactToUpsertToXero.MobilePhone)) {
            xeroPhones.add(createXeroPhone(contactToUpsertToXero.MobilePhone, XeroConstants.XERO_PHONE_TYPE_MOBILE));
        }
        return xeroPhones;
    }

    private static XeroPhone createXeroPhone(final String phoneNumber, final String phoneType){
        XeroPhone xeroPhone = new XeroPhone();
        xeroPhone.PhoneNumber = getNonNullStringValue(phoneNumber);
        xeroPhone.PhoneType = getNonNullStringValue(phoneType);
        return xeroPhone;
    }

    private static XeroAddress createXeroAddress(final String street, final String city, final String postalCode, final String state, final String country, final String type, final String ndisNumber){
        XeroAddress xeroAddress = new XeroAddress();
        xeroAddress.AddressLine1 = getNonNullStringValue(street);
        xeroAddress.City = getNonNullStringValue(city);
        xeroAddress.PostalCode = getNonNullStringValue(postalCode);
        xeroAddress.Country = getNonNullStringValue(country);
        xeroAddress.Region = getNonNullStringValue(state);
        xeroAddress.AddressType = getNonNullStringValue(type);
        xeroAddress.AttentionTo = getNonNullStringValue(ndisNumber);
        return xeroAddress;
    }

    // i noticed if we assigned something null in the request it would assign 'mul' instead of empty, so this method is here
    private static String getNonNullStringValue(String strValue){
        return strValue != null ? strValue : '';
    }

    public static XeroContact createXeroContact(final Contact contactToUpsertToXero){
        XeroContact xeroContact = new XeroContact();
        xeroContact.ContactID = getXeroIdFromContact(contactToUpsertToXero);
        xeroContact.FirstName = contactToUpsertToXero.FirstName;
        xeroContact.LastName = contactToUpsertToXero.LastName;
        xeroContact.Name = contactToUpsertToXero.enrtcr__Display_Full_Name__c;
        xeroContact.EmailAddress = getEmailFromContact(contactToUpsertToXero);
        xeroContact.Phones = createXeroMobileNumber(contactToUpsertToXero);
        xeroContact.Addresses = createXeroAddresses(contactToUpsertToXero);
        return xeroContact;
    }

    private static String getEmailFromContact(final Contact contactToUpsertToXero){
        if (contactToUpsertToXero.How_is_the_NDIS_Plan_funding_managed__c == 'Registered Plan Manager Provider' &&
                contactToUpsertToXero.Funding_Manager__c != null){
            return String.isNotBlank(contactToUpsertToXero.Funding_Manager__r.Invoicing_Email__c) ? contactToUpsertToXero.Funding_Manager__r.Invoicing_Email__c : '';
        }
        return contactToUpsertToXero.Email;
    }

    private static List<XeroAddress> createXeroAddresses(final Contact contactToUpsertToXero){
        List<XeroAddress> xeroAddresses = new List<XeroAddress>();
        addBillingAddress(contactToUpsertToXero, xeroAddresses);
        addOtherAddress(contactToUpsertToXero, xeroAddresses);
        return xeroAddresses;
    }


    private static void addBillingAddress(final Contact contactToUpsertToXero, List<XeroAddress> xeroAddresses){
        if (String.isNotBlank(contactToUpsertToXero.MailingState) ||
                String.isNotBlank(contactToUpsertToXero.MailingCity) ||
                String.isNotBlank(contactToUpsertToXero.MailingPostalCode) ||
                String.isNotBlank(contactToUpsertToXero.MailingState) ||
                String.isNotBlank(contactToUpsertToXero.MailingCountry) ||
           		String.isNotBlank(contactToUpsertToXero.enrtcr__NDIS_ID__c)){
            xeroAddresses.add(createXeroAddress(contactToUpsertToXero.MailingStreet, contactToUpsertToXero.MailingCity, contactToUpsertToXero.MailingPostalCode, contactToUpsertToXero.MailingState, contactToUpsertToXero.MailingCountry, XeroConstants.XERO_ADDRESS_TYPE_MAILING, contactToUpsertToXero.enrtcr__NDIS_ID__c));
        }
    }

    private static void addOtherAddress(final Contact contactToUpsertToXero, List<XeroAddress> xeroAddresses){
        if (String.isNotBlank(contactToUpsertToXero.OtherStreet) ||
                String.isNotBlank(contactToUpsertToXero.OtherCity) ||
                String.isNotBlank(contactToUpsertToXero.OtherPostalCode) ||
                String.isNotBlank(contactToUpsertToXero.OtherState) ||
                String.isNotBlank(contactToUpsertToXero.OtherCountry) ||
            	String.isNotBlank(contactToUpsertToXero.enrtcr__NDIS_ID__c)){
            xeroAddresses.add(createXeroAddress(contactToUpsertToXero.OtherStreet, contactToUpsertToXero.OtherCity, contactToUpsertToXero.OtherPostalCode, contactToUpsertToXero.OtherState, contactToUpsertToXero.OtherCountry, XeroConstants.XERO_ADDRESS_TYPE_OTHER, contactToUpsertToXero.enrtcr__NDIS_ID__c));
        }
    }


    private static HttpResponse updateContactToXero(final Contact contactToUpdateToXero, XeroContact xeroContact, Account defaultAccount) {
        String requestBody = JSON.serialize(xeroContact);
        HttpRequest request = XeroCalloutUtility.createRequestForOUATH2(XeroConstants.POST_METHOD, XeroConstants.XERO_TYPE_CONTACTS, requestBody , defaultAccount.Xero_Access_Token__c);
        HttpResponse response = XeroCalloutUtility.sendRequest(request);
        Http client = new Http();
        response = client.send(request);
        Integer statusCode = response.getStatusCode();

        // if the httprequest fails, we assume that is because of the bad access token, we do a call out to refresh the token and then try again... Token information is saved onto defaultAccount
        if (statusCode != XeroCallBackExtension.STATUS_CODE_GOOD_REQUEST) {
            String accessToken = refreshToken(defaultAccount);
            if (String.isNotBlank(accessToken)) {
                request = XeroCalloutUtility.createRequestForOUATH2(XeroConstants.POST_METHOD, XeroConstants.XERO_TYPE_CONTACTS, requestBody , defaultAccount.Xero_Access_Token__c);
                response = client.send(request);
            }
        }
        update defaultAccount;
        buildNewLog(response, request.getEndpoint(), request);
        if (response.getStatusCode() == XeroCallBackExtension.STATUS_CODE_GOOD_REQUEST) {
            List<XeroContact> contactsReturned = XeroCalloutResponseParser.parseContacts(response.getBody());
            insertNewPersonalIdentifierInUpdate(contactsReturned, xeroContact, contactToUpdateToXero.Id);
        }

        return response;
    }

    private static void insertNewPersonalIdentifierInUpdate(List<XeroContact> contacts, XeroContact xeroContact, final Id contactId){
        Id packageIdentifierId = enrtcr__Personal_Identifier__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Accounting_Package_Identifier').recordTypeId;
        if (contacts != null &&
                !contacts.isEmpty() &&
                contacts.get(0).ContactID != xeroContact.ContactID){
            insert new enrtcr__Personal_Identifier__c(RecordTypeId = packageIdentifierId,
                                                        enrtcr__Number__c = contacts.get(0).ContactID,
                                                        enrtcr__Client__c = contactId);
        }
    }

    private static String getXeroIdFromContact(final Contact contactToUpdateToXero){
        String xeroId = null;
        if (isSObjectListNotEmpty(contactToUpdateToXero.enrtcr__Personal_Identifiers__r)){
            for (enrtcr__Personal_Identifier__c pi : contactToUpdateToXero.enrtcr__Personal_Identifiers__r){
                xeroId = pi.enrtcr__Number__c;
            }
        }
        return xeroId;
    }

    private static Contact getContact(final Id contactId){
        for (Contact con : getContactQuery(contactId)){
            return con;
        }
        throw new CustomException('Could find Contact.');
    }

    private static List<Contact> getContactQuery(final Id contactId){
        Id packageIdentifierId = enrtcr__Personal_Identifier__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Accounting_Package_Identifier').recordTypeId;
        return [SELECT Id,
                        Name,
                        enrtcr__Full_Name__c,
                        enrtcr__Display_Full_Name__c,
                        Salutation,
                        FirstName,
                        LastName,
                        enrtcr__Middle_Name__c,
                        MiddleName,
                        Email,
                        Fax,
                        Phone,
                        HomePhone,
                        MobilePhone,
                        enrtcr__Mobile__c,
                        MailingAddress,
                        MailingCity,
                        MailingCountry,
                        MailingPostalCode,
                        MailingStreet,
                        MailingState,
                        OtherAddress,
                        OtherCity,
                        OtherCountry,
                        OtherPostalCode,
                        OtherStreet,
                        OtherState,
                        How_is_the_NDIS_Plan_funding_managed__c,
                        Funding_Manager__c,
                        Funding_Manager__r.Invoicing_Email__c,
                		enrtcr__NDIS_ID__c,
                        (SELECT
                                Id,
                                Name,
                                enrtcr__Number__c
                        FROM enrtcr__Personal_Identifiers__r
                        WHERE RecordTypeId = :packageIdentifierId
                        AND enrtcr__Number__c != NULL
                        ORDER BY CreatedDate DESC
                        LIMIT 1)
                FROM Contact
                WHERE Id = :contactId
                LIMIT 1];
    }

    public static String getResponse(final Boolean isSuccess, final String result){
        return JSON.serialize(getResponseObj(isSuccess, result));
    }


    private static RequestResponce getResponseObj(final Boolean isSuccess, final String result){
        if (isSuccess){
            return new RequestResponce('',isSuccess,result);
        } else {
            return new RequestResponce(result,isSuccess,'');
        }
    }

    // we need to intially authorise with xero to allow salesforce to make callouts to Xero, This is only used during intial
    // install/deploy
    public PageReference authXero() {
        // construct the url, the configurred URL is stored in the Login_URL__c field of the configuration. It contains
        // a string that has 2 parameters the client id and the callback URL, need to populate this on the URL
        List<String> urlParameters = new List<String>{
                XeroOAuthUtility.XERO_SETTINGS.Public_Key_2_0__c,
                EncodingUtil.urlEncode(XeroOAuthUtility.XERO_SETTINGS.Callback_URL__c, XeroOAuthUtility.ENCODING_UTF8)};
        String endpoint = String.format(XeroOAuthUtility.XERO_SETTINGS.Log_In_URL__c,
            urlParameters
        );

        endpoint = endpoint.replaceAll(XeroOAuthUtility.MERGE_FIELD_CLIENTID, XeroOAuthUtility.XERO_SETTINGS.Public_Key_2_0__c);
        endpoint = endpoint.replaceAll(XeroOAuthUtility.MERGE_FIELD_REDIRECTURL, EncodingUtil.urlEncode(XeroOAuthUtility.XERO_SETTINGS.Callback_URL__c, XeroOAuthUtility.ENCODING_UTF8));
        System.debug('client Id: ' + XeroOAuthUtility.XERO_SETTINGS.Public_Key_2_0__c);
        System.debug('login URL: ' + XeroOAuthUtility.XERO_SETTINGS.Log_In_URL__c);
        System.debug('callback URL: ' + XeroOAuthUtility.XERO_SETTINGS.Callback_URL__c);
        System.debug('URL Params: ' + urlParameters);
        System.debug(endpoint);

        PageReference ref = new PageReference(endpoint);
        ref.setRedirect(true);
        return ref;
    }

    public class RequestResponce{
        String errorMessage;
        Boolean isSuccess;
        String payLoad;

        RequestResponce(final String errorMessage, final Boolean isSuccess, final String payLoad){
            this.errorMessage = errorMessage;
            this.isSuccess = isSuccess;
            this.payLoad = payLoad;
        }
    }
}