@isTest
public class BR_reUsableMultiSelectLookupTest {
	@testSetup
    public static void setup(){        
        List<Contact> contactsToInsert = new List<Contact>();
        
        for(Integer i = 0; i < 5; i++){
            Contact worker = TestObjects.createContact(6, 'NDIS');
            worker.OtherStreet = 'Suite 102 / 806 Anzac Parade';
            contactsToInsert.add(worker);
            
            Contact client = TestObjects.createContact(1, 'NDIS');
            client.OtherStreet = 'Suite 102 / 806 Anzac Parade';
            contactsToInsert.add(client);
        }
        
        insert contactsToInsert;        
    }
    
    @isTest static void testMultiLookup(){
        Contact worker = [SELECT Id, Name, enrtcr__Other_Address__c FROM Contact WHERE Record_Type_Name__c = 'Employee' LIMIT 1];
        
        List<sObject> listOfSObjects = new List<sObject>();
        listOfSObjects.add((sObject)worker);      
        
        List<sObject> workerLookupResult = reUsableMultiSelectLookupCtrl.fetchLookUpValues('Test', 'Contact', listOfSObjects, '');
        System.assertEquals(5, workerLookupResult.size());
    }
}