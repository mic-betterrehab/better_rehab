/**
 * Created by Enrite Solutions on 24/07/2019.
 */

global with sharing class RetrieveInvoiceDataBatch implements Database.Batchable<Integer>,Database.AllowsCallouts,Database.Stateful {
    public Map<String, Contact> xeroContactRegister =  new Map<String, Contact>();
    public List<String> xeroContactIdsToRegister = new List<String>();
    public Boolean processMoreinvoices = false;
    public Integer startPageNum = 1;
    public static final String COMPLETE_STATUS = 'Complete';
    public static final String ERROR_STATUS = 'Error';
    public static final String XERO_DESTINATION = 'Xero';
    public static final String GET_METHOD = 'GET';
    public static final String LUMARY_SOURCE = 'Lumary';
    public static final String OK_STATUS = 'OK';
    public static final Integer OK_STATUS_CODE = 200;
    public static final Integer XeroDelayMinutes = 1;
    // xero has a 1600 WHERE query character limit, so we just fit as many as we can into it so we can get about 42 Ids in
    public static final Integer XERO_ID_LIMIT = 42;
    public static final String DATE_REGEX = '[0-9]{4}\\-[0-9]{2}\\-[0-9]{2}';
    public static final String STRING_TOO_LARGE = 'Response is too large. please see attached response.json file for the JSON response.';
    public static final String RESPONSE_FILE_NAME = 'response.txt';
    public static final String RESPONSE_FILE_TYPE = 'text/plain';

    public Integer getResponseFieldMaxLength {get{
        if (this.getResponseFieldMaxLength == null){
            this.getResponseFieldMaxLength = Schema.SObjectType.enrtcr__Integration_Log__c.fields.enrtcr__Response__c.getLength();
        }
        return this.getResponseFieldMaxLength;
    }set;}

    global RetrieveInvoiceDataBatch (Map<String, Contact> personalIdentifier, Integer pageNum){
        this.xeroContactRegister = personalIdentifier;
        this.startPageNum = pageNum;
    }

    global Iterable<Integer> start(Database.BatchableContext BC) {
        List<Integer> pageNumbers = new List<Integer>();
        for (Integer k = this.startPageNum; k <= this.startPageNum+9; k++){
            pageNumbers.add(k);
        }
        return pageNumbers;
    }

    global void execute(Database.BatchableContext BC, List<Integer> scope) {
        Account defaultAccount = XeroCallBackExtension.getDefaultXeroAccount();
        List<enrtcr__Integration_Log__c> logsToInsert = new List<enrtcr__Integration_Log__c>();
        Map<Integer, Attachment> attachmentsToInsert = new Map<Integer, Attachment>();
        for (Integer i : scope) {
            Boolean doRetrieve = true;
            doRetrieve = processInvoices(i, logsToInsert, attachmentsToInsert, defaultAccount);
            if (!doRetrieve || Test.isRunningTest()){
                break;
            }
        }
        try {
            if (!logsToInsert.isEmpty()) {
                insert logsToInsert;
                if (!attachmentsToInsert.isEmpty()){
                    for (Integer mapKey : attachmentsToInsert.keySet()){
                        attachmentsToInsert.get(mapKey).ParentId = logsToInsert.get(mapKey).Id;
                    }
                    insert attachmentsToInsert.values();
                }
            }

            update defaultAccount;
        } catch (Exception e){
            // catch error and do something
            throw e;
        }
    }

    global void finish(Database.BatchableContext BC) {
        if (this.processMoreinvoices == true){
            RetrieveInvoiceDataBatch b = new RetrieveInvoiceDataBatch(this.xeroContactRegister, this.startPageNum+10);
//            Database.executeBatch(b);
            System.scheduleBatch(b,'RetrieveInvoiceDataBatch', XeroDelayMinutes);
        } else {
            removeProccessedInvoies();
            if (!this.xeroContactRegister.isEmpty()){
                RetrieveInvoiceDataBatch b = new RetrieveInvoiceDataBatch(this.xeroContactRegister, 0);
//                Database.executeBatch(b);
                System.scheduleBatch(b,'RetrieveInvoiceDataBatch', XeroDelayMinutes);
            }
        }
    }

    private List<XeroInvoice> getInvoices(Integer pageNum, List<enrtcr__Integration_Log__c> logsToinsert, Map<Integer, Attachment> attachmentsToInsert, Account defaultAccount){
        String xeroContactIds = '';
        xeroContactIds = getContactIdsString();
        if (xeroContactIds.length() > 0
                && xeroContactIds.endsWith(',')){
            xeroContactIds = xeroContactIds.removeEnd(',');
        }
        HttpRequest request = XeroCalloutUtility.createCalloutInvoiceWithPagingStatus('GET','Invoices','',String.valueOf(pageNum), 'AUTHORISED', xeroContactIds, defaultAccount);
        HttpResponse response = XeroCalloutUtility.sendRequest(request);
        enrtcr__Integration_Log__c logToInsert = buildNewLog(response, request.getEndpoint());
        logsToinsert.add(logToInsert);
        if (logToInsert.enrtcr__Response__c == STRING_TOO_LARGE){
            Integer indexOfLog = logsToinsert.size() - 1;
            attachmentsToInsert.put(indexOfLog, createAttachment(response.getBody()));
        }
        return response.getStatus() == 'OK' && response.getStatusCode() == OK_STATUS_CODE ? XeroCalloutResponseParser.parseInvoices(response.getBody()) : null;
    }

    private enrtcr__Integration_Log__c buildNewLog(HttpResponse response, String endPoint){
        enrtcr__Integration_Log__c log = new enrtcr__Integration_Log__c();
        log.enrtcr__Status__c = response.getStatus() == OK_STATUS ? COMPLETE_STATUS : ERROR_STATUS;
        log.enrtcr__Error_Message__c = response.getStatus() == OK_STATUS ? '' : response.getBody();
        log.enrtcr__Method__c = GET_METHOD;
        log.enrtcr__Source_System__c = LUMARY_SOURCE;
        log.enrtcr__Destination_System__c = XERO_DESTINATION;
        log.enrtcr__Payload__c = endPoint;
        String responseBody = response.getBody();
        if (responseBody.length() >= this.getResponseFieldMaxLength){
            responseBody = minimiseJsonString(responseBody);
            if (responseBody.length() >= this.getResponseFieldMaxLength){
                log.enrtcr__Response__c = STRING_TOO_LARGE;
            } else {
                log.enrtcr__Response__c = responseBody;
            }
        } else {
            log.enrtcr__Response__c = responseBody;
        }
        return log;
    }

    private void setOverDueAmount(Contact c, XeroInvoice invoice, String regexDate){
        if (invoice.DueDateString != null &&
                String.isNotBlank(invoice.DueDateString)){
            Pattern datePattern = Pattern.compile(regexDate);
            Matcher dateMatches = datePattern.matcher(invoice.DueDateString);
            if (dateMatches.find()){
                Date dueDate = Date.valueOf(dateMatches.group().split(',').get(0).substring(0,10));
                if (dueDate < Date.today()){
                    c.Total_Amount_Overdue__c = c.Total_Amount_Overdue__c == null ? invoice.AmountDue : c.Total_Amount_Overdue__c + invoice.AmountDue;
                    c.Items_Overdue__c += invoice.LineItems != null ? invoice.LineItems.size() : 0;
                }
            }
        }
    }

    private void setContactFields(XeroInvoice invoice){
        if (invoice.AmountDue > 0) {
            Contact c = this.xeroContactRegister.get(invoice.Contact.ContactID);
            c.Date_Last_Retrieved__c = Date.today();
            c.Total_Amount_Outstanding__c = c.Total_Amount_Outstanding__c == null ? invoice.AmountDue : c.Total_Amount_Outstanding__c + invoice.AmountDue;
            c.Items_Outstanding__c += invoice.LineItems != null ? invoice.LineItems.size() : 0;
            setOverDueAmount(c, invoice, DATE_REGEX);
        }
    }

    private Boolean processInvoices(Integer i, List<enrtcr__Integration_Log__c> logsToinsert, Map<Integer, Attachment> attachmentsToInsert, Account defaultAccount){
            Boolean doRetrieve = false;
            List<XeroInvoice> xeroInvoices = getInvoices(i, logsToinsert, attachmentsToInsert, defaultAccount);
            if (xeroInvoices != null) {
                for (XeroInvoice invoice : xeroInvoices) {
                    setContactFields(invoice);
                }
                if (i != 0 &&
                        math.mod(i, 10) == 0 &&
                        xeroInvoices.size() == 100) {
                    this.processMoreInvoices = true;
                }
                if (xeroInvoices.size() >= 100){
                    doRetrieve = true;
                }
            }
        return doRetrieve;
    }

    private String getContactIdsString(){
        String xeroContactIds = '';
        if (this.xeroContactIdsToRegister.isEmpty()){
            Integer count = 0;
            for(String xeroContactId : this.xeroContactRegister.keySet()) {
                if (count <= XERO_ID_LIMIT){
                    count++;
                    if (xeroContactId != null &&
                            String.isNotBlank(xeroContactId)){
                        xeroContactIds += (String.isBlank(xeroContactId) ?'': xeroContactId + ',');
                        xeroContactIdsToRegister.add(xeroContactId);
                    }
                }
            }
        } else {
            for(String xeroContactId : this.xeroContactIdsToRegister) {
                if (xeroContactId != null &&
                        String.isNotBlank(xeroContactId)){
                    xeroContactIds += (String.isBlank(xeroContactId) ?'': xeroContactId + ',');
                }
            }
        }
        return xeroContactIds;
    }

    private void removeProccessedInvoies(){
        Map<Id, Contact> contactsToUpdate = new Map<Id, Contact>();
        for (String proccessedId : this.xeroContactIdsToRegister){
            if (this.xeroContactRegister.containsKey(proccessedId)){
                Contact contactToAdd = xeroContactRegister.get(proccessedId);
                contactsToUpdate.put(contactToAdd.Id, contactToAdd);
                this.xeroContactRegister.remove(proccessedId);
            }
        }
        updateAndSendErrors(contactsToUpdate.values());
    }

    private void updateAndSendErrors(List<Contact> contactsToUpdate){
        System.debug('updating following contacts: ' + contactsToUpdate);
        Database.SaveResult[] saveResults = Database.update(contactsToUpdate, false);

        List<String> errors = new List<String>();
        Integer contactsToUpdateIndex = 0;
        for (Database.SaveResult result : saveResults){
            if (!result.isSuccess()){
                for(Database.Error err : result.getErrors()) {
                    String clientError = '';
                    clientError += 'Contact Id: ' + contactsToUpdate.get(contactsToUpdateIndex).Id + 'failed to update with status code:  ' + err.getStatusCode() + ' due to: ' + err.getMessage();
                    errors.add(clientError);
                }

            }
            contactsToUpdateIndex++;
        }
        if (!errors.isEmpty()){
            sendErrorEmail(errors);
        }
    }

    private void sendErrorEmail(List<String> errors){
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = new String[] { 'admin@enrite.com.au' };
        message.subject = 'Xero Integration Errors';

        message.plainTextBody = '';
        for (String error : errors){
            message.plainTextBody += error + '\n';
        }
        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
        Messaging.sendEmail(messages);
    }

    @TestVisible
    private Attachment createAttachment(String jsonResponce){
        Attachment attToInsert = new Attachment();
        attToInsert.Name = RESPONSE_FILE_NAME;
        attToInsert.Body = Blob.valueOf(jsonResponce);
        attToInsert.ContentType = RESPONSE_FILE_TYPE;
        return attToInsert;
    }

    private String minimiseJsonString(String jsonString){
        return JSON.serialize(JSON.deserializeUntyped(jsonString));
    }
}