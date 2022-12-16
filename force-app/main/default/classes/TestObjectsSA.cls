@isTest
public class TestObjectsSA {    
    static public enrtcr__Support_Contract__c createServiceAgreement(Id supervisionProfile, String serviceAgreementName){
        enrtcr__Support_Contract__c SA = new enrtcr__Support_Contract__c();
        SA.enrtcr__Client__c = supervisionProfile;
        SA.enrtcr__Funding_Type__c = 'NDIS';
        SA.enrtcr__Rate_Type__c = 'NDIS';
        SA.enrtcr__Start_Date__c = System.today() - 3;
        SA.enrtcr__End_Date__c = System.today() + 365;
        SA.enrtcr__Total_Allocation__c = 10;
        SA.enrtcr__Service_Agreement_Overclaim__c = 'Prevent';
        SA.enrtcr__Funding_Management__c = 'Participant';
        SA.enrtcr__Status__c = 'Current';
        SA.Name = serviceAgreementName;
        SA.enrtcr__Client_Approved_Date__c = System.today() - 1;
        
        return SA;
    }
    
    static public enrtcr__Support_Contract_Item__c createSAIs(Id serviceAgreement, enrtcr__Reference_Data__c supportCategory){
        enrtcr__Support_Contract_Item__c lineItems = new enrtcr__Support_Contract_Item__c();
        lineItems.RecordTypeId = '0122v0000013ObbAAE';
        lineItems.enrtcr__Support_Category_Amount__c = 3;
        lineItems.enrtcr__Support_Category__c = supportCategory.id;
        lineItems.enrtcr__Support_Contract__c = serviceAgreement;
        lineItems.enrtcr__Item_Overclaim__c = 'Prevent';
        
        return lineItems;
    }
}