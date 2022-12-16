/**
 * Created by Enrite Solutions on 24/07/2019.
 */
 public with sharing class XeroCalloutUtility {

     public static final Integer READ_TIME_OUT = 120000;
     public static Xero_Private_Settngs__c xeroSettings {

        get {
            if (xeroSettings == null) {
                xeroSettings = Xero_Private_Settngs__c.getOrgDefaults();
            }
            return xeroSettings;
        } set; }


     public static HttpRequest createRequestForOUATH2(String method, String resourceName, String requestBody, String accessToken) {
         String endpoint = xeroSettings.Endpoint__c + resourceName;
         return createRequestForEndpointOUATH2(endpoint, method, requestBody, accessToken);
     }

     public static HttpRequest createRequestForEndpointOUATH2(String endpoint, String method, String requestBody, String accessToken) {
         HttpRequest request = new HttpRequest();

         // Set request parameters
         request.setMethod(method);
         request.setEndpoint(endpoint);

         // Accept a JSON response from the call
         request.setHeader('Accept', 'application/json');

         // Set the body to the callout
         if (String.isNotBlank(requestBody)) {
             request.setBody(requestBody);
         }

         Account defaultAccount = XeroCallBackExtension.getDefaultXeroAccount();

         // Set the content to JSON
         request.setHeader('Content-Type', 'text/xml');
         request.setHeader(XeroCallBackExtension.PARAM_AUTHORIZATION, XeroCallBackExtension.PARAM_BEARER + accessToken);
         request.setHeader(XeroCallBackExtension.HEADER_XERO_TENANT_ID, defaultAccount.Xero_Tenant_ID__c);
         request.setTimeout(READ_TIME_OUT);

         return request;
     }

     public static HttpRequest createCallout (String method, String resourceName, String requestBody) {

         // Instantiate a new request
         HttpRequest request = new HttpRequest();

         // Set request parameters
         request.setMethod(method);
         request.setEndpoint(xeroSettings.Endpoint__c + resourceName);

         // Accept a JSON response from the call
         request.setHeader('Accept', 'application/json');

         // If the callout includes a body (POST and PUT requests)
         if (String.isNotBlank(requestBody)) {

             // Set the body to the callout
             request.setBody(requestBody);

             // Set the content to XML
             request.setHeader('Content-Type', 'text/xml');
         }
         request.setTimeout(READ_TIME_OUT);
         // Sign the request based on OAuth 1.0a
         request = XeroOAuthUtility.signRequest(request, xeroSettings.Public_Key__c,xeroSettings.Certificate_Developer_Name__c);
         return request;
     }

     public static HttpResponse executeCallout (String method, String resourceName, String requestBody) {
        HttpRequest request = createCallout(method, resourceName, requestBody);

        // Execute callout and return
        return sendRequest(request);
    }

     public static HttpResponse executeCalloutWithPaging (String method, String resourceName, String requestBody, String pageNum) {

         // Instantiate a new request
         HttpRequest request = new HttpRequest();

         // Set request parameters
         request.setMethod(method);
         request.setEndpoint(xeroSettings.Endpoint__c + resourceName + '?page=' + pageNum);

         // Accept a JSON response from the call
         request.setHeader('Accept', 'application/json');

         // If the callout includes a body (POST and PUT requests)
         if (String.isNotBlank(requestBody)) {

             // Set the body to the callout
             request.setBody(requestBody);

             // Set the content to XML
             request.setHeader('Content-Type', 'text/xml');
         }

         // Sign the request based on OAuth 1.0a
         request.setTimeout(READ_TIME_OUT);
         request = XeroOAuthUtility.signRequest(request, xeroSettings.Public_Key__c, xeroSettings.Certificate_Developer_Name__c);
         return sendRequest(request);
     }

     public static HttpRequest createCalloutInvoiceWithPagingStatus (String method, String resourceName, String requestBody, String pageNum, String statuses, String contactIds, Account defaultAccount) {
         // Instantiate a new request
         String endpoint = xeroSettings.Endpoint__c + resourceName
                 + '?page=' + pageNum
                 + '&Statuses=' + statuses
                 + '&ContactIDs=' + contactIds;

         HttpRequest request = createRequestForEndpointOUATH2(endpoint, method, requestBody, defaultAccount.Xero_Access_Token__c);

         HttpResponse response = XeroCalloutUtility.sendRequest(request);
         Http client = new Http();
         response = client.send(request);
         Integer statusCode = response.getStatusCode();

         if (statusCode != XeroCallBackExtension.STATUS_CODE_GOOD_REQUEST) {
             String accessToken = SendContactToXeroController.refreshToken(defaultAccount);
             if (String.isNotBlank(accessToken)) {
                 request = createRequestForEndpointOUATH2(endpoint, method, requestBody, defaultAccount.Xero_Access_Token__c);
                 response = client.send(request);
             }
         }

//         HttpRequest request = new HttpRequest();
//         // Set request parameters
//         request.setMethod(method);
//         request.setEndpoint(endpoint);
//
//         // Accept a JSON response from the call
//         request.setHeader('Accept', 'application/json');
//
//         // If the callout includes a body (POST and PUT requests)
//         if (String.isNotBlank(requestBody)) {
//
//             // Set the body to the callout
//             request.setBody(requestBody);
//
//             // Set the content to XML
//             request.setHeader('Content-Type', 'text/xml');
//         }
//         request.setTimeout(READ_TIME_OUT);
//         request = XeroOAuthUtility.signRequest(request, xeroSettings.Public_Key__c, xeroSettings.Certificate_Developer_Name__c);
         return request;
     }
     public static HttpResponse sendRequest(HttpRequest request){
         return new Http().send(request);
     }

}