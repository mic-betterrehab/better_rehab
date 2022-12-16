public with sharing class HSTPDischargeTaskHandler {
    /*
    private List<Task> tasks = new List<Task>();
    private List<enrtcr__Support_Delivered__c> SDs = new List<enrtcr__Support_Delivered__c>();

    public HSTPDischargeTaskHandler(List<enrtcr__Assessment__c> dischargeForms) {
        for (enrtcr__Assessment__c form : dischargeForms) {

            createTask(form);
        }

        insert tasks;


    }

    private double calculateInvoice(Integer baseSessions, Integer numExtraSession, String CancellationReason, String RaptScore, String ExtraSessionIndicate ) {
        Double invoiceAmount = 0;
        User u = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        if (RaptScore == '9+') {
            if (baseSessions == 1 || baseSessions == 2) {
                invoiceAmount = 350;
            } else if(baseSessions == 3 || baseSessions == 4) {
                invoiceAmount = 700;
            } else {
                invoiceAmount = 0;
            }
        } else if (RaptScore == '6-9' || RaptScore == '0-6') {
            if (baseSessions == 0) {
                invoiceAmount = 0;
            } else if (baseSessions == 1) {
                if (CancellationReason == 'Medical') {
                    invoiceAmount = 475;
                } else if (CancellationReason == 'Non-Medical') {
                    invoiceAmount = 250;
                }
            } else if (baseSessions == 5) {
                invoiceAmount = 2700;
            } else {
                invoiceAmount = baseSessions * 475;
            }
        }

        if (ExtraSessionIndicate == 'Yes') {
            if (RaptScore == '9+') {
                invoiceAmount = invoiceAmount + (numExtraSession * 175);
            } else if (RaptScore == '6-9' || RaptScore == '0-6') {
                invoiceAmount = invoiceAmount + (numExtraSession * 400);
            }
        }

        return invoiceAmount;

    }

    private void createTask(enrtcr__Assessment__c form) {
		Double invoice = 0;
        invoice = calculateInvoice(
            integer.valueOf(form.Number_of_sessions__c),
            integer.valueOf(form.Number_of_extra_sessions__c),
            form.HSTP_Cancellation_Reason__c,
            form.Auto_RAPT__c,
            form.Did_the_client_have_extra_sessions__c
        );

        Task InvoiceTask = new Task();
        InvoiceTask.OwnerId = u.Id;
        InvoiceTask.Priority = 'High';
        InvoiceTask.RecordTypeId = '0129D000000ezQgQAI';
        InvoiceTask.Status = 'Not Started';
        InvoiceTask.Subject = 'HSTP Invoice';
        InvoiceTask.WhatId = form.Id;
        InvoiceTask.WhoId = form.enrtcr__Client__c;
        InvoiceTask.Comments__c = form.Discharge_Comments__c;
        InvoiceTask.ActivityDate = form.CreatedDate.date() + 3;
        InvoiceTask.Invoice_Amount__c = invoice;

        tasks.add(InvoiceTask);
    }

    private void createSD(enrtcr__Assessment__c form) {

    }
*/
}