/**
 * Created by Enrite Solutions on 24/07/2019.
 */

public class XeroInvoice {

    public String Type {get; set;}	//ACCREC
    public String InvoiceID {get; set;}	//920cce71-7495-4c93-a2d3-e4cf9b91a781
    public String InvoiceNumber {get; set;}	//INV-0002
    public String Reference {get; set;}
    public String DateString {get; set;}
    public String DueDateString {get; set;}
    public Payment[] Payments {get; set;}
    public CreditNote[] CreditNotes {get; set;}
    public PrePayment[] Prepayments {get; set;}
    public Overpayment[] Overpayments {get; set;}
    public Decimal AmountDue {get; set;}	//600
    public Decimal AmountPaid {get; set;}	//0
    public Boolean SentToContact {get; set;}
    public Decimal CurrencyRate {get; set;}	//1
    public Boolean HasErrors {get; set;}
    public Boolean IsDiscounted {get; set;}
    public XeroContact Contact {get; set;}
    public String Date_x {get; set;}	//2015-12-01T00:00:00
    public String DueDate {get; set;}	//2015-12-31T00:00:00
    public String Status {get; set;}	//DRAFT
    public String LineAmountTypes {get; set;}	//Exclusive
    public LineItem[] LineItems {get; set;}
    public Decimal SubTotal {get; set;}	//600
    public Decimal TotalTax {get; set;}	//0
    public Decimal Total {get; set;}	//600
    public String UpdatedDateUTC {get; set;}	///Date(1447665863507+1300)/
    public String CurrencyCode {get; set;}	//NZD
    public cls_Warnings[] Warnings {get; set;}
    public cls_ValidationErrors[] ValidationErrors {get; set;}
    @TestVisible
    class Payment {
    }
    @TestVisible
    class CreditNote {
    }
    @TestVisible
    class PrePayment {
    }
    @TestVisible
    class Overpayment {
    }
    @TestVisible
    class cls_ContactGroups {
    }
    @TestVisible
    class cls_SalesTrackingCategories {
    }
    @TestVisible
    class cls_PurchasesTrackingCategories {
    }
    @TestVisible
    class cls_PaymentTerms {
        public cls_Bills Bills {get; set;}
    }
    @TestVisible
    class cls_Bills {
        public Integer Day {get; set;}	//1
        public String Type {get; set;}	//OFFOLLOWINGMONTH
    }
    @TestVisible
    class cls_ContactPersons {
    }
    public class LineItem {
        public String ItemCode {get; set;}
        public String Description {get; set;}	//Consulting services as agreed
        public Decimal UnitAmount {get; set;}	//120
        public String TaxType {get; set;}	//NONE
        public Decimal TaxAmount {get; set;}	//0
        public Decimal LineAmount {get; set;}	//600
        public String AccountCode {get; set;}	//200
        public cls_Tracking[] Tracking {get; set;}
        public Decimal Quantity {get; set;}	//5
        public String LineItemID {get; set;}	//0d129d0d-4b3a-4567-afc5-0453f3457175
        public cls_ValidationErrors[] ValidationErrors {get; set;}
    }

    public class cls_Tracking {
        public String Name {get; set;}
        public String Option {get; set;}
    }
    public class cls_ValidationErrors {
        public String Message {get; set;}
    }
    @TestVisible
    class cls_Warnings {
    }

}