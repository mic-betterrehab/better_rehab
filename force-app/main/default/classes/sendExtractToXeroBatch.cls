/**
 * Created by Enrite Solutions on 23/12/2020.
 */

public with sharing class sendExtractToXeroBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {

    public static final String EXTRACT_STATUS_FINISHED = 'Finished';
    public static final String DEFAULT_ACCOUNT_CODE = '200';
    public static final String DEFAULT_ITEM_CODE = '200';
    public static final String REGEX_DATE_FORMAT_STRING = 'YYYY-MM-dd';

    public static Send_Invoice_To_Extract_Settings__c BATCH_SETTINGS {
        get {
            if (BATCH_SETTINGS == null) {
                BATCH_SETTINGS = Send_Invoice_To_Extract_Settings__c.getOrgDefaults();
            }
            return BATCH_SETTINGS;
        }
        set;
    }

    public static Integer BATCH_SIZE {
        get {
            if (BATCH_SIZE == null) {
                BATCH_SIZE = 40;
                if (BATCH_SETTINGS != null &&
                        BATCH_SETTINGS.Send_Invoice_To_Xero_Batch_Size__c != null &&
                        BATCH_SETTINGS.Send_Invoice_To_Xero_Batch_Size__c > 0) {
                    BATCH_SIZE = Integer.valueOf(BATCH_SETTINGS.Send_Invoice_To_Xero_Batch_Size__c);
                }
            }
            return BATCH_SIZE;
        }
        set;
    }

    public Id extractId;
    public enrtcr__Extract__c extract;

    public sendExtractToXeroBatch(final Id extractId) {
        this.extractId = extractId;
        this.extract = getExtract(extractId);
    }

    public Database.QueryLocator start(Database.BatchableContext param1) {
        // we Query Conyacts in the query locator not Extract items, this is mainly so we can use a custom Setting to Configure
        // how many Invoices we send in a single Request/Callout (1 contact spawns 1 Invoice with multiple Line items), each Extract item = 1 Line item
        Id packageIdentifierId = enrtcr__Personal_Identifier__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Accounting_Package_Identifier').recordTypeId;
        return Database.getQueryLocator([
                SELECT Id,
                        Name,
                        FirstName,
                        LastName,
                        enrtcr__Display_Full_Name__c,
                        Lumary_Auto_number__c, (
                        SELECT
                                Id,
                                Name,
                                enrtcr__Number__c
                        FROM enrtcr__Personal_Identifiers__r
                        WHERE RecordTypeId = :packageIdentifierId
                        AND enrtcr__Number__c != NULL
                        ORDER BY CreatedDate DESC
                        LIMIT 1
                )
                FROM Contact
                WHERE Id IN (SELECT enrtcr__Client__c FROM enrtcr__Support_Delivered__c WHERE (enrtcr__Financial_Extract__r.enrtcr__Extract__c = :this.extractId) AND enrtcr__Total__c > 0 AND enrtcr__Rate__r.enrtcr__Accounting_Package_Id__c != NULL)
                AND Id IN (SELECT enrtcr__Client__c FROM enrtcr__Personal_Identifier__c WHERE RecordTypeId = :packageIdentifierId)
        ]);
    }

    public void execute(Database.BatchableContext param1, List<Contact> contacts) {
        List<XeroInvoice> xeroInvoicesToPost = new List<XeroInvoice>();
        Map<String, Id> mapOfClientAndXeroIds = createMapOfXeroIds(contacts);
        Map<Id, List<enrtcr__Extract_Item__c>> extractItemMap = getExtractItemsMap(contacts, this.extractId);

        // each each contact make an invoice and create a line item for each Extract item in extract
        // Note here, When creating they are not posted to Xero, that are simply stored in a List and then all posted
        // at once with the sendInvoicesToXeroAndUpdateExtItems method
        for (Contact con : contacts) {
            if (hasXeroId(con) && extractItemMap.containsKey(con.Id)) {
                xeroInvoicesToPost.add(createInvoice(this.extract, con, extractItemMap.get(con.Id)));
            }
        }
        sendInvoicesToXeroAndUpdateExtItems(xeroInvoicesToPost, mapOfClientAndXeroIds, extractItemMap, this.extract);
    }

    private static Map<String, Id> createMapOfXeroIds(List<Contact> contacts) {
        Map<String, Id> mapOfClientAndXeroIds = new Map<String, Id>();
        for (Contact con : contacts) {
            if (hasXeroId(con)) {
                mapOfClientAndXeroIds.put(con.enrtcr__Personal_Identifiers__r.get(0).enrtcr__Number__c, con.Id);
            }
        }
        return mapOfClientAndXeroIds;
    }

    private static void sendInvoicesToXeroAndUpdateExtItems(List<XeroInvoice> xeroInvoicesToPost, Map<String, Id> mapOfClientAndXeroIds, Map<Id, List<enrtcr__Extract_Item__c>> extractItemMap, enrtcr__Extract__c extract) {
        // Xero reqires we send it up in a certain format, easiest way is to serialise a map
        Map<String, List<XeroInvoice>> xeroInvoicesMap = new Map<String, List<XeroInvoice>>();
        xeroInvoicesMap.put('Invoices', xeroInvoicesToPost);
        sendInvoiceToXero(xeroInvoicesMap, mapOfClientAndXeroIds, extractItemMap, extract, false, null);
    }

    private static XeroInvoice createInvoice(final enrtcr__Extract__c extract, final Contact con, List<enrtcr__Extract_Item__c> extItems) {
        XeroInvoice xeroInvoice = new XeroInvoice();
        xeroInvoice.Type = XeroConstants.XERO_INVOICE_TYPE_ACCREC;
        xeroInvoice.InvoiceNumber = generateInvoiceNumber(extract, con);
        xeroInvoice.Reference = generateInvoiceNumber(extract, con);
        xeroInvoice.Date_x = extract.CreatedDate.format(REGEX_DATE_FORMAT_STRING);
        xeroInvoice.DateString = extract.CreatedDate.format(REGEX_DATE_FORMAT_STRING) + 'T00:00:00';
        xeroInvoice.DueDate = extract.CreatedDate.addDays(14).format(REGEX_DATE_FORMAT_STRING);
        xeroInvoice.Contact = createXeroContact(con);
        xeroInvoice.LineItems = createXeroLineItems(extItems);
        return xeroInvoice;
    }

//    INV-[Enrite Care Client ID]-[The Number component of the Extract Name]
//    To illustrate if the Client has an Client ID value of 56789 and Extract Name is EXT-00001234, the generated invoice number would be, this will allow the invoices to be matched to the client and the extract that created:
//    INV-56789-1234

    private static String generateInvoiceNumber(final enrtcr__Extract__c extract, final Contact con) {
        return 'INV-' + removeNonNumericAndLeadingZeros(con.Lumary_Auto_number__c) + '-' + removeNonNumericAndLeadingZeros(extract.Name);
    }

    private static String removeNonNumericAndLeadingZeros(final String str) {
        String strNumOnly = str.replaceAll('[^0-9]', '');
        return strNumOnly.replaceFirst('^0+(?!$)', '');
    }

    private static List<XeroInvoice.LineItem> createXeroLineItems(List<enrtcr__Extract_Item__c> extItems) {
        List<XeroInvoice.LineItem> xeroLineItems = new List<XeroInvoice.LineItem>();
        for (enrtcr__Extract_Item__c extItem : extItems) {
            xeroLineItems.add(createXeroLineItem(extItem));
        }
        return xeroLineItems;
    }

    private static XeroInvoice.LineItem createXeroLineItem(enrtcr__Extract_Item__c extItem) {
        XeroInvoice.LineItem lineItem = new XeroInvoice.LineItem();
        lineItem.Quantity = extItem.enrtcr__Quantity__c;
        lineItem.UnitAmount = extItem.enrtcr__Unit_Price__c == null ? 0.00 : Decimal.valueOf(extItem.enrtcr__Unit_Price__c);
        lineItem.Description = createLineItemDescription(extItem);
        lineItem.AccountCode = extItem.enrtcr__Service_Delivered__c != null && extItem.enrtcr__Service_Delivered__r.enrtcr__Rate__c != null && extItem.enrtcr__Service_Delivered__r.enrtcr__Rate__r.enrtcr__Service__c != null && String.isNotBlank(extItem.enrtcr__Service_Delivered__r.enrtcr__Rate__r.enrtcr__Service__r.Xero_Account_Code__c) ? extItem.enrtcr__Service_Delivered__r.enrtcr__Rate__r.enrtcr__Service__r.Xero_Account_Code__c : '200';
        lineItem.ItemCode = extItem.enrtcr__Service_Delivered__c != null && extItem.enrtcr__Service_Delivered__r.enrtcr__Rate__c != null && String.isNotBlank(extItem.enrtcr__Service_Delivered__r.enrtcr__Rate__r.enrtcr__Accounting_Package_Id__c) ? extItem.enrtcr__Service_Delivered__r.enrtcr__Rate__r.enrtcr__Accounting_Package_Id__c : '200';
        lineItem.TaxType = XeroConstants.INVOICE_LINE_ITEM_TYPE;
        lineItem.Tracking = createTrackingItems(extItem);
        lineItem.LineAmount = extItem.enrtcr__Total_ex_GST__c;
        return lineItem;
    }

    private static List<XeroInvoice.cls_Tracking> createTrackingItems(enrtcr__Extract_Item__c extItem){
        List<XeroInvoice.cls_Tracking> trackingItems = new List<XeroInvoice.cls_Tracking>();
        if (String.isNotBlank(extItem.enrtcr__Service_Delivered__r.enrtcr__Worker__r.Site__c)) {
            XeroInvoice.cls_Tracking siteTracking = new XeroInvoice.cls_Tracking();
            siteTracking.Name = 'Site';
            siteTracking.Option = extItem.enrtcr__Service_Delivered__r.enrtcr__Worker__r.Site__c;
            trackingItems.add(siteTracking);
        }
        
        if (String.isNotBlank(extItem.enrtcr__Service_Delivered__r.enrtcr__Worker__r.State)){
            XeroInvoice.cls_Tracking stateTracking = new XeroInvoice.cls_Tracking();
            stateTracking.Name = 'State';
            stateTracking.Option = extItem.enrtcr__Service_Delivered__r.enrtcr__Worker__r.State;
            trackingItems.add(stateTracking);
        }

        // if (String.isNotBlank(extItem.enrtcr__Service_Delivered__r.enrtcr__Client__r.Site_Allocation__c)){
        //     List<String> siteAllocations = extItem.enrtcr__Service_Delivered__r.enrtcr__Client__r.Site_Allocation__c.split(';');
        //     for (String siteAll : siteAllocations){
        //         XeroInvoice.cls_Tracking siteTracking = new XeroInvoice.cls_Tracking();
        //         siteTracking.Name = 'Site';
        //         siteTracking.Option = siteAll;
        //         trackingItems.add(siteTracking);
        //     }
        // }

        // if (String.isNotBlank(extItem.enrtcr__Service_Delivered__r.enrtcr__Client__r.enrtcr__Client_Region__c)){
        //     XeroInvoice.cls_Tracking stateTracking = new XeroInvoice.cls_Tracking();
        //     stateTracking.Name = 'State';
        //     stateTracking.Option = extItem.enrtcr__Service_Delivered__r.enrtcr__Client__r.enrtcr__Client_Region__c;
        //     trackingItems.add(stateTracking);
        // }
        return trackingItems;
    }

//    Description = A string containing service delivery date, client name, service name, service support item code separated by “ - “
    private static String createLineItemDescription(enrtcr__Extract_Item__c extItem) {
        return formatDate(extItem.enrtcr__Service_Delivered__r.enrtcr__Date__c) +
        getHypothenAndNotNullString(extItem.enrtcr__Service_Delivered__r.enrtcr__Client__r.enrtcr__Display_Full_Name__c) +
        getHypothenAndNotNullString(extItem.enrtcr__Service_Delivered__r.enrtcr__Rate__r.enrtcr__Service__r.Name) +
        getHypothenAndNotNullString(extItem.enrtcr__Service_Delivered__r.enrtcr__Rate__r.enrtcr__Service__r.enrtcr__Support_Item_Code__c);
    }

    private static String getHypothenAndNotNullString(final String str){
        return '-' + (String.isNotBlank(str) ? str : '');
    }

    private static String formatDate(final Date dt) {
        if (dt != null) {
            Datetime dateTimeOfDt = Datetime.newInstance(dt, Time.newInstance(0, 0, 0, 0));
            return dateTimeOfDt.format('dd-MM-YYYY');
        }
        return '';
    }

    private static XeroContact createXeroContact(final Contact con) {
        XeroContact xeroCon = new XeroContact();
        xeroCon.ContactID = getXeroId(con);
//        xeroCon.FirstName = con.FirstName;
//        xeroCon.LastName = con.LastName;
//        xeroCon.Name = con.enrtcr__Display_Full_Name__c;
        return xeroCon;
    }

    private static String getXeroId(final Contact con) {
        for (enrtcr__Personal_Identifier__c pi : con.enrtcr__Personal_Identifiers__r) {
            return pi.enrtcr__Number__c;
        }
        return '';
    }

    private static Boolean hasXeroId(final Contact con) {
        return isSObjectListNotEmpty(con.enrtcr__Personal_Identifiers__r) && con.enrtcr__Personal_Identifiers__r[0].enrtcr__Number__c != null;
    }

    //Extract Items By Client
    private static Map<Id, List<enrtcr__Extract_Item__c>> getExtractItemsMap(final List<Contact> contacts, final Id extractId) {
        Set<Id> contactIds = getContactIds(contacts);
        Map<Id, List<enrtcr__Extract_Item__c>> extractItemMap = new Map<Id, List<enrtcr__Extract_Item__c>>();
        for (enrtcr__Extract_Item__c extItem : getExtractItemsQuery(contactIds, extractId)) {
            if (!extractItemMap.containsKey(extItem.enrtcr__Service_Delivered__r.enrtcr__Client__c)) {
                extractItemMap.put(extItem.enrtcr__Service_Delivered__r.enrtcr__Client__c, new List<enrtcr__Extract_Item__c>());
            }
            extractItemMap.get(extItem.enrtcr__Service_Delivered__r.enrtcr__Client__c).add(extItem);
        }
        return extractItemMap;
    }

    private static Set<Id> getContactIds(final List<Contact> contacts) {
        Set<Id> contactIds = new Set<Id>();
        for (Contact con : contacts) {
            contactIds.add(con.Id);
        }
        return contactIds;
    }

    private static List<enrtcr__Extract_Item__c> getExtractItemsQuery(final Set<Id> contactIds, final Id extractId) {
        return [
                SELECT Id,
                        Name,
                        enrtcr__Quantity__c,
                        enrtcr__Unit_Price__c,
                        enrtcr__Total_ex_GST__c,
                        enrtcr__Extract__c,
                        enrtcr__Extract__r.Name,
                        enrtcr__Extract__r.CreatedDate,
                        enrtcr__Service_Delivered__c,
                        enrtcr__Service_Delivered__r.Name,
                        enrtcr__Service_Delivered__r.enrtcr__Date__c,
                        enrtcr__Service_Delivered__r.enrtcr__Quantity__c,
                        enrtcr__Service_Delivered__r.enrtcr__Rate__c,
                        enrtcr__Service_Delivered__r.enrtcr__Rate__r.Name,
                        enrtcr__Service_Delivered__r.enrtcr__Rate__r.enrtcr__Service__c,
                        enrtcr__Service_Delivered__r.enrtcr__Rate__r.enrtcr__Service__r.Name,
                        enrtcr__Service_Delivered__r.enrtcr__Rate__r.enrtcr__Service__r.enrtcr__Item_Code__c,
                        enrtcr__Service_Delivered__r.enrtcr__Rate__r.enrtcr__Service__r.enrtcr__Support_Item_Code__c,
                        enrtcr__Service_Delivered__r.enrtcr__Rate__r.enrtcr__Accounting_Package_Id__c,
                        enrtcr__Service_Delivered__r.enrtcr__Rate__r.enrtcr__Service__r.Xero_Account_Code__c,
                        enrtcr__Service_Delivered__r.enrtcr__Client__c,
                        enrtcr__Service_Delivered__r.enrtcr__Client__r.Lumary_Auto_number__c,
                        enrtcr__Service_Delivered__r.enrtcr__Client__r.enrtcr__Display_Full_Name__c,
                        enrtcr__Service_Delivered__r.enrtcr__Client__r.FirstName,
                        enrtcr__Service_Delivered__r.enrtcr__Client__r.LastName,
                        enrtcr__Service_Delivered__r.enrtcr__Client__r.Name,
                        enrtcr__Service_Delivered__r.enrtcr__Client__r.enrtcr__Client_Region__c,
                        enrtcr__Service_Delivered__r.enrtcr__Client__r.Site_Allocation__c,
                        enrtcr__Service_Delivered__r.enrtcr__Worker__r.Site__c,
                        enrtcr__Service_Delivered__r.enrtcr__Worker__r.State
                FROM enrtcr__Extract_Item__c
                WHERE enrtcr__Service_Delivered__r.enrtcr__Client__c IN :contactIds
                AND enrtcr__Extract__c = :extractId
                AND enrtcr__Service_Delivered__c != NULL
                AND enrtcr__Service_Delivered__r.enrtcr__Client__c != NULL
                AND Unit_Price_Number__c > 0
                AND enrtcr__Quantity__c > 0
                AND enrtcr__Total_ex_GST__c > 0
                ORDER BY CreatedDate DESC
        ];
    }

    public static enrtcr__Extract__c getExtract(final Id extractId) {
        for (enrtcr__Extract__c ext : getExtractQuery(extractId)) {
            return ext;
        }
        return null;
    }

    private static List<enrtcr__Extract__c> getExtractQuery(final Id extractId) {
        return [
                SELECT Id,
                        Name,
                        CreatedDate,
                        All_Items_For_Extract_Report__c,
                        All_Items_For_Extract_Report_HyperLink__c,
                        Extract_Items_With_Errors_Report__c,
                        Extract_Items_With_Errors_Report_HTML__c,
                        Extract_Items_Sent_To_Xero_Report__c,
                        Extract_Items_Sent_To_Xero_Report_HTML__c
                FROM enrtcr__Extract__c
                WHERE Id = :extractId
                LIMIT 1
        ];
    }

    private static Boolean isSObjectListNotEmpty(final List<SObject> sObjectList) {
        return sObjectList != null &&
                !sObjectList.isEmpty();
    }

    private static void reSendForAccountingCode(Map<String, List<XeroInvoice>> xeroInvoices, Map<String, Id> mapOfClientAndXeroIds, Map<Id, List<enrtcr__Extract_Item__c>> extractItemMap, enrtcr__Extract__c extract, Account defAccount, HttpResponse response, HttpRequest request, Datetime requestSentDateTime, Datetime responseReceivedDateTime){
        Boolean resend = false;
        // we check all returned items for a blank Account or item Code, if they are blank it means Xero didnt find the code (doesnt exist)
        // so we set the default value of 200, then we need to resend the invoices up (mnarked bu setting resend = true)
        for (List<XeroInvoice> xeroInvoiceList : xeroInvoices.values()){
            if (xeroInvoiceList != null){
                if (setDefaultAccountCodForInvoiceItems(xeroInvoiceList)){
                    resend = true;
                }
            }
        }

        // if we need to resend call previous method, and after which insert the Log/Log Files for the original callout
        if (resend){
            sendInvoiceToXero(xeroInvoices, mapOfClientAndXeroIds, extractItemMap, extract, true, defAccount);
            SendContactToXeroController.buildNewLog(response, request.getEndpoint(), request);
            createCalloutFiles(extract, response, request.getEndpoint(), request, requestSentDateTime, responseReceivedDateTime);
        } else {
            // if we dont need to resend we dont, just make log files and update Default Account with new Xero token Details
            SendContactToXeroController.buildNewLog(response, request.getEndpoint(), request);
            createCalloutFiles(extract, response, request.getEndpoint(), request, requestSentDateTime, responseReceivedDateTime);
            updateExtractItems(response, mapOfClientAndXeroIds, extractItemMap);
            update defAccount;
        }
    }

    private static Boolean setDefaultAccountCodForInvoiceItems(List<XeroInvoice> xeroInvoiceList){
        Boolean resend = false;
        for (XeroInvoice xeroInv : xeroInvoiceList){
            if (setDefaultAccountCodeAndItemCodeForLineItems(xeroInv)){
                resend = true;
            }
        }
        return resend;
    }


    // if xero responds saying the Line Item Item Code or Account Code is Blank, we set it to the default AcountCode or ItemCode
    private static Boolean setDefaultAccountCodeAndItemCodeForLineItems(XeroInvoice xeroInv){
        Boolean resend = false;
        if (xeroInv.LineItems != null &&
                !xeroInv.LineItems.isEmpty()){
            for (XeroInvoice.LineItem lineItem : xeroInv.LineItems){
                if (String.isBlank(lineItem.AccountCode)){
                    resend = true;
                    lineItem.AccountCode = DEFAULT_ACCOUNT_CODE;
                }
                if (String.isBlank(lineItem.ItemCode)){
                    resend = true;
                    lineItem.ItemCode = DEFAULT_ITEM_CODE;
                }
            }
        }
        return resend;
    }

    public void finish(Database.BatchableContext param1) {
        sendEmail(' Send To Xero Process Complete', this.extract);
        update new enrtcr__Extract__c(Id = this.extractId, enrtcr__Status__c = EXTRACT_STATUS_FINISHED);
    }

    public static void sendEmail(final String subject, enrtcr__Extract__c extract){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new List<String>{UserInfo.getUserEmail()};
        mail.setToAddresses(toAddresses);
        mail.setSenderDisplayName('Salesforce');
        String emailBodyPT = 'Please See Below Reports for ' + extract.Name + '.' + '\n\n';
        String emailBodyHTML = 'Please See Below Reports for ' + extract.Name + '.' + '<br><br>';
        emailBodyPT += 'All Extract Items: ' + extract.All_Items_For_Extract_Report__c + '\n';
        emailBodyHTML += extract.All_Items_For_Extract_Report_HyperLink__c + '<br>';
        emailBodyPT += 'Extract Items with Errors: ' + extract.Extract_Items_With_Errors_Report__c + '\n';
        emailBodyHTML += extract.Extract_Items_With_Errors_Report_HTML__c + '<br>';
        emailBodyPT += 'Extract Items Sent To Xero: ' + extract.Extract_Items_Sent_To_Xero_Report__c + '\n';
        emailBodyHTML += extract.Extract_Items_Sent_To_Xero_Report_HTML__c + '<br>';
        mail.setPlainTextBody(emailBodyPT);
        mail.setHtmlBody(emailBodyHTML);
// Specify the subject line for your email address.
        mail.setSubject(extract.Name + subject);
        if (!Test.isRunningTest()){
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{
                    mail
            });
        }
    }

    private static void createCalloutFiles(enrtcr__Extract__c extract, HttpResponse response, String endPoint, HTTPRequest req, Datetime requestSentDateTime,Datetime responseReceivedDateTime){
        if (requestSentDateTime != null){
            Attachment requestFile = new Attachment();
            requestFile.ParentId = extract.Id;
            requestFile.Name = 'Request-' + requestSentDateTime.format('yyyyMMdd-hh:mm:ss');
            requestFile.ContentType = 'text/plain';
            requestFile.Body = Blob.valueOf(req.getBody());

            insert requestFile;
        }

        if (responseReceivedDateTime != null){
            Attachment requestFile = new Attachment();
            requestFile.ParentId = extract.Id;
            requestFile.Name = 'Response-' + responseReceivedDateTime.format('yyyyMMdd-hh:mm:ss');
            requestFile.ContentType = 'text/plain';
            requestFile.Body = Blob.valueOf(response.getBody());

            insert requestFile;
        }
    }

    private static void updateExtractItems(HttpResponse response, Map<String, Id> mapOfClientAndXeroIds, Map<Id, List<enrtcr__Extract_Item__c>> extractItemMap) {
        // if we get a bad code, it means that the post was not succesful (as in the request is not valid), even if every invoice fails to be inserted,
        // aslong as the request is valid structure wise then we will still get a OKAY status
        if (response == null ||
                response.getStatusCode() != XeroCallBackExtension.STATUS_CODE_GOOD_REQUEST) {
            updateExtractItemsFailed(extractItemMap);
        } else {
            updateExtractItemsSuccess(response, mapOfClientAndXeroIds, extractItemMap);
        }
    }

    private static void sendInvoiceToXero(Map<String, List<XeroInvoice>> xeroInvoices, Map<String, Id> mapOfClientAndXeroIds, Map<Id, List<enrtcr__Extract_Item__c>> extractItemMap, enrtcr__Extract__c extract, Boolean alreadySent, Account defAccount) {
        Datetime requestSentDateTime;
        Datetime responseReceivedDateTime;
        Account defaultAccount = defAccount == null ? XeroCallBackExtension.getDefaultXeroAccount() : defAccount;
        String requestBody = JSON.serialize(xeroInvoices);
        HttpRequest request = XeroCalloutUtility.createRequestForOUATH2(XeroConstants.POST_METHOD, XeroConstants.XERO_TYPE_INVOICES_SUMMARISE_ERRORS, requestBody, defaultAccount.Xero_Access_Token__c);
        requestSentDateTime = Datetime.now();
        HttpResponse response = XeroCalloutUtility.sendRequest(request);

        Http client = new Http();
        response = client.send(request);
        responseReceivedDateTime = Datetime.now();
        Integer statusCode = response.getStatusCode();


        // if bad assume we need to refresh token
        if (statusCode != XeroCallBackExtension.STATUS_CODE_GOOD_REQUEST) {
            String accessToken = SendContactToXeroController.refreshToken(defaultAccount);
            if (String.isNotBlank(accessToken)) {
                request = XeroCalloutUtility.createRequestForOUATH2(XeroConstants.POST_METHOD, XeroConstants.XERO_TYPE_INVOICES_SUMMARISE_ERRORS, requestBody, defaultAccount.Xero_Access_Token__c);
                response = client.send(request);
                responseReceivedDateTime = Datetime.now();
            }
        }

        // we potentially send the invoices twice, on the first time, we check Invoice items, Second time we recall this same method.
        // Salesforce wont let us to DML > Callout > DML > Callout > DML so when we do our first callout we save all DML Operations
        // until we have done all callouts
        if (alreadySent){
            // if we have already sent just finish up by updating extract items and creating log/log files
            SendContactToXeroController.buildNewLog(response, request.getEndpoint(), request);
            createCalloutFiles(extract, response, request.getEndpoint(), request, requestSentDateTime, responseReceivedDateTime);
            updateExtractItems(response, mapOfClientAndXeroIds, extractItemMap);
            update defAccount;
        } else {
            // pass everything we need to make a second call out
            List<XeroInvoice> xeroInvoicesFromResponse = XeroCalloutResponseParser.parseInvoices(response.getBody());
            Map<String, List<XeroInvoice>> xeroInvoicesFromResponseMap = new Map<String, List<XeroInvoice>>();
            xeroInvoicesFromResponseMap.put('Invoices', xeroInvoicesFromResponse);
            reSendForAccountingCode(xeroInvoicesFromResponseMap, mapOfClientAndXeroIds, extractItemMap, extract, defaultAccount, response, request, requestSentDateTime, responseReceivedDateTime);
        }
    }

    private static void updateExtractItemsSuccess(HttpResponse response, Map<String, Id> mapOfClientAndXeroIds, Map<Id, List<enrtcr__Extract_Item__c>> extractItemMap) {
        // Good status does not mean all invoices success, we loop through each Invoice return and check if they are successful,
        // if they fail pooulate errors on Extract item and into a List of String used later to send an email.
        // if success we just populate Xero ids onto Extract item
        List<XeroInvoice> xeroInvoices = XeroCalloutResponseParser.parseInvoices(response.getBody());

        Map<Id, enrtcr__Extract_Item__c> extractItemsToUpdate = new Map<Id, enrtcr__Extract_Item__c>();
        for (XeroInvoice invoice : xeroInvoices){
            Id clientId = getSalesforceClientId(invoice, mapOfClientAndXeroIds);
            List<enrtcr__Extract_Item__c> extractItems = extractItemMap.get(clientId);
            String invoiceErrors = getValidationErrors(invoice.ValidationErrors);
            String listOfExtractItemsNames = '';
            for (Integer index = 0; index < invoice.LineItems.size(); index++){
                if (String.isBlank(listOfExtractItemsNames)){
                    listOfExtractItemsNames += extractItems.get(index).Name;
                } else {
                    listOfExtractItemsNames += ', ' + extractItems.get(index).Name;
                }
                updateExtractItemWithLineItemsValues(invoice.InvoiceID, invoice.LineItems.get(index), extractItems.get(index), extractItemsToUpdate, invoiceErrors);
            }
            if (String.isNotBlank(invoiceErrors)){
                listOfExtractItemsNames += ' has run into the following Error(s); \n' + invoiceErrors + '\n\n';
            }
        }
        update extractItemsToUpdate.values();
    }

    private static void updateExtractItemWithLineItemsValues(String invoiceId, XeroInvoice.LineItem xeroLineItem, enrtcr__Extract_Item__c extItem, Map<Id, enrtcr__Extract_Item__c> extractItemsToUpdate, final String validationErrors){
        if (xeroLineItem.LineItemID != null &&
                String.isNotBlank(xeroLineItem.LineItemID) &&
                String.isBlank(validationErrors)) {
            extItem.Invoice_ID__c = invoiceId;
            extItem.Invoice_Line_Item_ID__c = xeroLineItem.LineItemID;
            extItem.Error_Status_Message__c = '';
        } else {
            String lineItemValidationErrors = getValidationErrors(xeroLineItem.ValidationErrors);
            extItem.Invoice_ID__c = '';
            extItem.Invoice_Line_Item_ID__c = '';
            extItem.Error_Status_Message__c = lineItemValidationErrors + '\n' + validationErrors;
        }
        extractItemsToUpdate.put(extItem.Id, extItem);
    }

    private static String getValidationErrors(List<XeroInvoice.cls_ValidationErrors> valErrors){
        String valErrorsString = '';
        if (valErrors != null &&
                !valErrors.isEmpty()){
            for (XeroInvoice.cls_ValidationErrors valErr : valErrors){
                if (String.isNotBlank(valErr.Message)){
                    valErrorsString += valErr.Message + '\n';
                }
            }
        }
        return valErrorsString;
    }

    private static Id getSalesforceClientId(XeroInvoice invoice, Map<String, Id> mapOfClientAndXeroIds){
        String clientXeroId = invoice.Contact.ContactID;
        return mapOfClientAndXeroIds.get(clientXeroId);
    }

    private static void updateExtractItemsFailed(Map<Id, List<enrtcr__Extract_Item__c>> extractItemMap) {
        // at this point, the error needs to be fixed by a sys admin looing at the integration log,
        // we take the easy option here by just saying the sync failed completely
        List<enrtcr__Extract_Item__c> itemsToUpdate = new List<enrtcr__Extract_Item__c>();
        for (Id clientId : extractItemMap.keySet()) {
            for (enrtcr__Extract_Item__c extItem : extractItemMap.get(clientId)) {
                extItem.Error_Status_Message__c = 'There was an Error Posting to Xero. Sync Failed';
                extItem.Invoice_Line_Item_ID__c = '';
                extItem.Invoice_ID__c = '';
                itemsToUpdate.add(extItem);

            }
        }
        update itemsToUpdate;
    }
}