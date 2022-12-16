@isTest
public class BR_CustomLookUpControllerTest {
    @testSetup
    public static void setup(){
        //create site
        enrtcr__Site__c newSite = TestObjects.createSite(2);
        newSite.enrtcr__Business_Address_1__c = 'Suite 102 / 806 Anzac Parade';
        insert newSite;
    }
    
    @isTest static void testController(){
        enrtcr__Site__c easternSydneySite = [SELECT Id, Name, enrtcr__Business_Address_1__c FROM enrtcr__Site__c WHERE Name = 'Eastern Sydney'];
        List<sObject> listOfSiteResult = customLookUpController.fetchLookUpValues('Eastern', 'enrtcr__Site__c', ',enrtcr__Business_Address_1__c', '');
        
        System.assertEquals(1, listOfSiteResult.size());
        System.assertEquals(easternSydneySite, listOfSiteResult[0]);
    }
}