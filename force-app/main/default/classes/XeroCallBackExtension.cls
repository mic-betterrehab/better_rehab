/**
 * Created by Enrite Solutions on 22/12/2020.
 */

public with sharing class XeroCallBackExtension {


    public static final String ENCODING_UTF8 = 'UTF-8';
    public static final String PARAM_GRANT_TYPE = 'grant_type';
    public static final String PARAM_AUTHORIZATION_CODE = 'authorization_code';
    public static final String PARAM_CODE = 'code';
    public static final String PARAM_REDIRECT_URI = 'redirect_uri';
    public static final String PARAM_REFRESH_TOKEN = 'refresh_token';
    public static final String PARAM_AUTHORIZATION = 'Authorization';
    public static final String PARAM_BEARER = 'Bearer '; // space is intentional
    public static final String PARAM_BASIC = 'Basic '; // space is intentional
    public static final String PARAM_CONTENT_TYPE = 'Content-Type';
    public static final String PARAM_CONTENT_TYPE_JSON = 'application/json';
    public static final String PARAM_CONTENT_TYPE_FORM_DATA = 'application/x-www-form-urlencoded';
    public static final String EQUALS = '=';
    public static final String AMPERSAND = '&';
    public static final String HEADER_XERO_TENANT_ID = 'Xero-tenant-id';
    public static final String HEADER_ACCEPT = 'Accept';
    public static final String FORWARD_SLASH = '/';


    public static final String XERO_NOT_AUTHORISED = 'Salesforce has not been authorised to access Xero. Contact your System Administrator for help';
    public static final Integer READ_TIME_OUT = 120000;
    public static final String NO_RESPONSE_BODY_RECEIVED = 'No response data';
    public static final String ERROR_KEY = 'ValidationErrors';
    public static final String ERROR_MESSAGE_KEY = 'Message';

    public static final Integer STATUS_CODE_GOOD_REQUEST = 200;
    public static final Integer STATUS_CODE_BAD_REQUEST = 400;
    public static final Integer STATUS_CODE_UNAUTHORISED = 401;

    public String msg {get;set;}


    // after attempting to authorise with Xero, Xero will send Salesforce a response, this method is used to process that response.
    public PageReference callback() {
        Account defaultAccount = getDefaultXeroAccount();


        String code = ApexPages.currentPage().getParameters().get(PARAM_CODE);
        PageReference pageRef = null;

        // if we don't have a code as the parameter we cannot proceed any further add the message to be displayed on the page
        if (String.isBlank(code)) {
            msg = XERO_NOT_AUTHORISED;
            return pageRef;
        }

        // set the code on the account object for usage
        defaultAccount.Xero_Authorisation_Code__c = code;
        // The authentication call made to xero must be done using Basic authentication the header is in the format of
        // [username]:[password], in our case the [Client ID]:[Client Secret]
        String auth = EncodingUtil.base64Encode(Blob.valueOf( XeroCalloutUtility.xeroSettings.Public_Key_2_0__c + ':' + XeroCalloutUtility.xeroSettings.Private_Key_2_0__c));

        Http client = new Http();

        HttpRequest request = new HttpRequest();
        request.setHeader(PARAM_AUTHORIZATION, PARAM_BASIC + auth);
        request.setHeader(PARAM_CONTENT_TYPE, PARAM_CONTENT_TYPE_FORM_DATA);
        request.setMethod('POST');
        request.setEndpoint(XeroCalloutUtility.xeroSettings.Access_Token_URL__c);
        request.setBody(getNewTokenBody(code, XeroCalloutUtility.xeroSettings.Callback_URL__c));

        // make the authentication request
        HttpResponse response = client.send(request);
        // if we get status 200 then we've been authenticated correctly. we can retrieve the access token received from
        // this process, this will be stoered on the default account object.

        System.debug('calback response 1: ' + response);
        System.debug('calback response 1: ' + response.getBody());

        if (response.getStatusCode() == STATUS_CODE_GOOD_REQUEST) {
            AccessToken token = (AccessToken) JSON.deserialize(response.getBody(), AccessToken.class);
            if (token != null) {
                getTenantIdFromXero(token, defaultAccount);
            }
            pageRef = new PageReference('/');
            pageRef.setRedirect(true);
        } else {
            this.msg = XERO_NOT_AUTHORISED;
        }

        upsert defaultAccount;
        return pageRef;
    }


    private void getTenantIdFromXero(AccessToken token, Account defaultAccount) {
        String accessToken = token.access_token;
        defaultAccount.Xero_Refresh_ID__c = token.refresh_token;
        defaultAccount.Xero_Access_Token__c = accessToken;

        // now we need to make the call the get the tenant id we are connected to.
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setHeader(PARAM_AUTHORIZATION, PARAM_BEARER + accessToken);
        request.setHeader(PARAM_CONTENT_TYPE, PARAM_CONTENT_TYPE_JSON);
        request.setEndpoint(XeroCalloutUtility.xeroSettings.Connections_End_point__c);

        Http client = new Http();
        // make the call to the connections web service to get our tenant id we need to store it on the account object
        HttpResponse response = client.send(request);

        System.debug('calback response 2: ' + response);
        System.debug('calback response 2: ' + response.getBody());

        if (response.getStatusCode() == STATUS_CODE_GOOD_REQUEST) {
            List<TenantConnection> tenantConnections = (List<TenantConnection>) JSON.deserialize(response.getBody(), List<TenantConnection>.class);
            if (tenantConnections.size() > 0) {
                String tenantId = tenantConnections.get(0).tenantId;
                defaultAccount.Xero_Tenant_ID__c = tenantId;
            }
        }
    }




    /**
 * This method returns a string containing the request body that will be added to the authorization url in Xero.
 * @param code the code sent to the callback url by Xero
 * @param url the redirect url that Xero will call on authorization
 *
 * @return  a string containing the request body that will be added to the authorization url in Xero
 */
    public static String getNewTokenBody(String code, String url) {
        String body = '';
        body += paramVal(PARAM_GRANT_TYPE, PARAM_AUTHORIZATION_CODE, true);
        body += paramVal(PARAM_CODE, code, true);
        body += paramVal(PARAM_REDIRECT_URI, url, false);
        return body;
    }

    public static String paramVal(String key, String value, Boolean addAmperstand) {
        String str = key
                + EQUALS
                + (String.isBlank(value) ? '' : EncodingUtil.urlEncode(value, ENCODING_UTF8));

        return (addAmperstand) ? str + AMPERSAND : str;
    }

    public static Account getDefaultXeroAccount(){
        List<Account> defaultAccounts = [SELECT Id,
                                                Name,
                                                Xero_Access_Token__c,
                                                Xero_Authorisation_Code__c,
                                                Xero_Refresh_ID__c,
                                                Xero_Tenant_ID__c
                                        FROM Account
                                        WHERE Name = :XeroOAuthUtility.XERO_SETTINGS.Default_Account_Name__c
                                        ORDER BY CreatedDate ASC];
        if (defaultAccounts != null && !defaultAccounts.isEmpty()){
            return defaultAccounts.get(0);
        }
        return new Account(Name = XeroOAuthUtility.XERO_SETTINGS.Default_Account_Name__c);
    }

    public class AccessToken {
        public String id_token {get;set;}
        public String access_token {get;set;}
        public Integer expires_in {get;set;}
        public String token_type {get;set;}
        public String refresh_token {get;set;}
    }

    /**
     * Inner class that used to deserialise the payload received from Xero connections call
     */
    public class TenantConnection {
        public String id {get;set;}
        public String tenantId {get;set;}
    }
}