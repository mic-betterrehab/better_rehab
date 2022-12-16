@isTest
public class BR_EventWAPTest {
    static testMethod void prepareTestData(){
        User x = [SELECT id, IsActive FROM User WHERE id = '0052v00000ckcK7AAI'];
        
        //create a worker
        Contact newWorker = TestObjects.createContact(6,'NDIS');
        insert newWorker;
        
        //create a session
        enrtcr__Session__c newSession = new enrtcr__Session__c();
        newSession.Name = 'Test Session';
        newSession.enrtcr__Start_Date__c = System.today();
        newSession.enrtcr__End_Date__c = System.today() + 1;
        newSession.enrtcr__Status__c = 'Rostered';
        newSession.enrtcr__Service_Types__c = 'Initial Assessment';
        insert newSession;
        
        //create a WAP
        enrtcr__Worker_Appointment__c newWAP = new enrtcr__Worker_Appointment__c();
        newWAP.enrtcr__Start_Date__c = newSession.enrtcr__Start_Date__c ; 
        newWAP.enrtcr__End_Date__c = newSession.enrtcr__End_Date__c;
        newWAP.enrtcr__Session__c = newSession.id;
        newWAP.enrtcr__Worker__c = newWorker.Id;
        newWAP.enrtcr__Status__c = 'Rostered';
        insert newWAP;
        
        Test.startTest();
        
        //change the Session status to complete - this should automatically change the WAP status too
        enrtcr__Session__c updatedSession = [SELECT Id, enrtcr__Status__c FROM enrtcr__Session__c WHERE Id =: newSession.Id];
        updatedSession.enrtcr__Status__c = 'Complete';
        update updatedSession;
        
        System.debug('updatedSession status: ' + updatedSession.enrtcr__Status__c);
        
        enrtcr__Worker_Appointment__c updatedWAP = [SELECT Id, enrtcr__Status__c FROM enrtcr__Worker_Appointment__c WHERE Id =: newWAP.Id];
        updatedWAP.enrtcr__Status__c = 'Complete';
        update updatedWAP;
        System.debug('updatedWAP status: ' + updatedWAP.enrtcr__Status__c);
        
        Test.stopTest();
        
        enrtcr__Worker_Appointment__c updatedWAP1 = [SELECT Id, enrtcr__Status__c FROM enrtcr__Worker_Appointment__c WHERE Id =: updatedWAP.Id];
        System.assertEquals('Rostered', updatedWAP1.enrtcr__Status__c);
        
        //Event event = [SELECT Id, Worker_Appointment__c, Event_Status__c FROM Event WHERE Worker_Appointment__c =: updatedWAP.Id];
        //System.assertEquals('Rostered', event.Event_Status__c);
       
    }
}