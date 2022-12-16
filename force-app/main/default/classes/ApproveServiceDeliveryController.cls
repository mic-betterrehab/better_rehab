public with sharing class ApproveServiceDeliveryController {

    @AuraEnabled
    public static FormDefault getFormDefaults() {
        FormDefault def = new FormDefault();

        List<Site> sites = new List<Site>();
        sites.add(new Site(new enrtcr__Site__c(Name='All My Sites')));
        for (enrtcr__Site_User__c su : getLoggedInUserSites()) {
            sites.add(new Site(su.enrtcr__Site__r));
        }

        def.sites = sites;
        //def.startDate = Date.newInstance(2019,1,1);
        def.startDate = Date.today().addMonths(-3);
        def.endDate = Date.today();

        return def;
    }


    @AuraEnabled
    public static List<SdWrapper> getSdRecords(String siteId, Date startDate, Date endDate, String workerId) {
        List<SdWrapper> sdRecords = new List<SdWrapper>();
        Set<Id> siteIds = (String.isNotBlank(siteId)) ? new Set<Id> {siteId} : getUserSiteIds();
        Set<Id> serviceAgreementIds = new Set<id>();
        List<enrtcr__Support_Delivered__c> serviceDeliveryRecords = getSdRecords(siteIds, startDate, endDate, workerId);

        for (enrtcr__Support_Delivered__c sd : serviceDeliveryRecords) {
            sdRecords.add(new SdWrapper(sd));
            serviceAgreementIds.add(sd.enrtcr__Support_Contract__c);
        }

        Map<Id, Decimal> totalExtractedQuantityMap = new Map<Id, Decimal>();

        List<enrtcr__Extract_Item__c> itemsExtracted = [SELECT ID, enrtcr__GST__c, enrtcr__Total_ex_GST__c, enrtcr__Quantity__c,  enrtcr__Service_Delivered__r.enrtcr__Support_Contract__c, enrtcr__Service_Delivered__c
                                                        FROM enrtcr__Extract_Item__c
                                                        WHERE enrtcr__Service_Delivered__r.enrtcr__Support_Contract__c IN :serviceAgreementIds
                                                        AND RecordType.DeveloperName IN ('NDIS', 'Financial_Extract')
                                                        AND enrtcr__Service_Delivered__c != null
                                                        AND enrtcr__Service_Delivered__r.enrtcr__Support_Contract__c != null];

        for (enrtcr__Extract_Item__c item : itemsExtracted) {
            Id serviceAgreementId = item.enrtcr__Service_Delivered__r.enrtcr__Support_Contract__c;

            if (!totalExtractedQuantityMap.containsKey(serviceAgreementId)) {
                totalExtractedQuantityMap.put(serviceAgreementId, 0);
            }
            Decimal quantity = (item.enrtcr__Quantity__c == null) ? 0 : item.enrtcr__Quantity__c;
            Decimal total = totalExtractedQuantityMap.get(serviceAgreementId) + quantity;
            totalExtractedQuantityMap.put(serviceAgreementId, total);
        }

        for (SdWrapper wrap : sdRecords) {
            wrap.setTotalExtracted((totalExtractedQuantityMap.get(wrap.saId)));
        }
        return sdRecords;
    }

    @AuraEnabled
    public static String approveRecords(String requestStr) {
        String msg = 'The service delivery records have been successfully approved.';
        try {
            ApprovalRequest request = (ApprovalRequest)JSON.deserialize(requestStr, ApprovalRequest.class);
            List<Record_Approval__c> approvalsToCreated = new List<Record_Approval__c>();
            Id userId = UserInfo.getUserId();
            Datetime now = Datetime.now();

            for (SdWrapper sd : request.approvals) {
                approvalsToCreated.add(new Record_Approval__c(Approved_By__c = userId, Approved_On__c = now, Service_Delivered__c = sd.id));
            }

            insert approvalsToCreated;
        } catch (Exception e) {
//            throw new AuraHandledException(e.getMessage());
            msg = e.getMessage();
        }
        return msg;
    }

    private static Set<Id> getUserSiteIds() {
        Set<Id> ids = new Set<Id>();

        for (enrtcr__Site_User__c su : getLoggedInUserSites()) {
            ids.add(su.enrtcr__Site__r.Id);
        }

        return ids;
    }

    private static List<enrtcr__Site_User__c> getLoggedInUserSites() {
        return [SELECT enrtcr__Site__r.Id, enrtcr__Site__r.Name FROM enrtcr__Site_User__c WHERE enrtcr__User__c = :UserInfo.getUserId() ORDER BY enrtcr__Site__r.Name];
    }

    public static List<enrtcr__Support_Delivered__c> getSdRecords(Set<Id> siteIds, Date startDate, Date endDate, String workerId) {
        return [SELECT
                ID,
                Name,
                enrtcr__Client__r.Name,
                enrtcr__Services__c,
                enrtcr__Quantity__c,
                enrtcr__Rate_Quantity_Type__c,
                enrtcr__Cancellation__c,
                enrtcr__Cancellation_reason__c,
                enrtcr__Comments__c,
                enrtcr__Worker__r.Name,
                enrtcr__Total__c,
                enrtcr__Total_ex_GST__c,
                enrtcr__GST__c,
                enrtcr__Date__c,
                enrtcr__Support_Contract__c,
                enrtcr__Support_Contract__r.Name,
                SD_Status__c
        FROM  enrtcr__Support_Delivered__c
        WHERE enrtcr__Site__c IN :siteIds AND enrtcr__Date__c >= :startDate AND enrtcr__Date__c <= :endDate
        AND (enrtcr__Worker__c = :workerId OR Name Like:(String.isBlank(workerId) ? '%' : '~'))
        AND enrtcr__Support_Contract__c != null
        AND Is_Approved__c = false
        ORDER BY Name];
    }
    public class SdWrapper {
        @AuraEnabled
        public String id {get;set;}
        @AuraEnabled
        public String name {get;set;}
        @AuraEnabled
        public String clientName {get;set;}
        @AuraEnabled
        public String serviceName {get;set;}
        @AuraEnabled
        public String quantity {get;set;}
        @AuraEnabled
        public String comments {get;set;}
        @AuraEnabled
        public String workerName {get;set;}
        @AuraEnabled
        public Decimal totalCost {get;set;}
        @AuraEnabled
        public boolean cancelled {get;set;}
        @AuraEnabled
        public Date deliveryDate {get;set;}
        @AuraEnabled
        public String saId {get;set;}
        @AuraEnabled
        public String saName {get;set;}
        @AuraEnabled
        public String totalExtractedQuantity {get;set;}
        @AuraEnabled
        public String totalExtractedCost {get;set;}
        @AuraEnabled
        public String sdStatus {get;set;}

        public SdWrapper(){}

        public SdWrapper(enrtcr__Support_Delivered__c sd) {
            this.id = sd.Id;
            this.name = sd.Name;
            this.clientName = (sd.enrtcr__Client__r == null) ? '' : sd.enrtcr__Client__r.Name;
            this.serviceName = sd.enrtcr__Services__c;
            this.quantity = getNumberValue(sd.enrtcr__Quantity__c) + ' ' + sd.enrtcr__Rate_Quantity_Type__c;
            this.comments = (sd.enrtcr__Cancellation__c) ? 'Cancelled: ' + sd.enrtcr__Cancellation_reason__c : sd.enrtcr__Comments__c;
            this.workerName = (sd.enrtcr__Worker__r == null) ? '' : sd.enrtcr__Worker__r.Name;
            this.totalCost = sd.enrtcr__Total__c;
            this.cancelled = sd.enrtcr__Cancellation__c;
            this.deliveryDate = sd.enrtcr__Date__c;
            this.saName = (sd.enrtcr__Support_Contract__r == null) ? '' : sd.enrtcr__Support_Contract__r.Name;
            this.saId = sd.enrtcr__Support_Contract__c;
            this.totalExtractedCost = '';
            this.totalExtractedQuantity = '';
            this.sdStatus = sd.SD_Status__c == null ? 'Ready to Approve' : sd.SD_Status__c;
        }

        public void setTotalExtracted(Decimal d) {
            this.totalExtractedQuantity = getNumberValue(d);
        }

        private String getNumberValue(Decimal d) {
            d = (d == null) ? 0 : d;
            List<String> args = new String[]{'0','number','###,###,##0.00'};
            return String.format(d.format(), args);
        }
    }

    public class ApprovalRequest {
        @AuraEnabled
        public List<SdWrapper> approvals {get;set;}
    }

    public class FormDefault {
        @AuraEnabled
        public List<Site> sites {get;set;}
        @AuraEnabled
        public Date startDate {get;set;}
        @AuraEnabled
        public Date endDate {get;set;}
    }

    public class Site {
        @AuraEnabled
        public string value {get;set;}
        @AuraEnabled
        public string label {get;set;}
        public Site(enrtcr__Site__c site) {
            this.value = (site.id == null) ? '' : site.id;
            this.label = site.Name;
        }
    }
}