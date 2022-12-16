/**
 * Created by ersoz on 2019-12-05.
 */

public with sharing class TestData {

    public static Contact createTestContact(){
        return new Contact(
                LastName='TestClient',
                MobilePhone='+61400000000',
                RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Client').getRecordTypeId()
        );
    }

    public static Contact createTestWorkerContact() {

        return new Contact(
                LastName='TestWorker',
                MobilePhone='+61400000000',
                RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Employee').getRecordTypeId()
        );
    }

    public static enrtcr__Site__c createTestSite(){

        return new enrtcr__Site__c(Name='Test Site');
    }

    public static enrtcr__Session__c createTestSession(Id sessionId, String statusType, Id recurrenceId, Datetime startDateTime, Datetime endDateTime){

        if (startDateTime == null) startDateTime = Datetime.now();
        if (endDateTime == null) endDateTime = startDateTime.addDays(1);

        return new enrtcr__Session__c(
                enrtcr__Status__c = statusType,
                enrtcr__Parent_Session__c = sessionId,
                enrtcr__Recurrence__c = recurrenceId,
                enrtcr__Start_Date__c = startDateTime,
                enrtcr__End_Date__c = endDateTime
        );
    }

    public static enrtcr__Client_Appointment__c createTestClientAppointment(Id sessionId, Id contactId, Datetime startDateTime, Datetime endDateTime){
        if (startDateTime == null) startDateTime = Datetime.now();
        if (endDateTime == null) endDateTime = startDateTime.addDays(1);

        return new enrtcr__Client_Appointment__c(
                enrtcr__Session__c = sessionId,
                enrtcr__Client__c = contactId,
                enrtcr__Start_Date__c = startDateTime,
                enrtcr__End_Date__c = endDateTime
        );
    }

    public static enrtcr__Recurrence__c createTestRecurrence(){
        return new enrtcr__Recurrence__c(
                enrtcr__Start_Date__c = date.today(),
                enrtcr__End_Date__c = date.today().addMonths(1),
                enrtcr__Frequency__c = 10,
                enrtcr__Frequency_Unit__c = 'Day(s)'
        );
    }

    public static enrtcr__Worker_Appointment__c createTestWorkerAppointment(Id contactId, Id sessionId, Datetime startDateTime, Datetime endDateTime){
        if (startDateTime == null) startDateTime = Datetime.now();
        if (endDateTime == null) endDateTime = startDateTime.addDays(1);
        return new enrtcr__Worker_Appointment__c(
                enrtcr__Worker__c = contactId,
                enrtcr__Session__c = sessionId,
                enrtcr__Start_Date__c = startDateTime,
                enrtcr__End_Date__c = endDateTime
        );
    }
    /*
    public static Zipline__Message__c createMessage(Boolean isInbound, String smsBody) {

        String direction;
        Id recordTypeId;

        if (isInbound) {
            direction = 'Inbound';
            recordTypeId = Schema.SObjectType.Zipline__Message__c.getRecordTypeInfosByName().get('Inbound SMS').getRecordTypeId();
        } else {
            direction = 'Outbound';
            recordTypeId = Schema.SObjectType.Zipline__Message__c.getRecordTypeInfosByName().get('Outbound SMS').getRecordTypeId();
        }
        return new Zipline__Message__c(
                Zipline__Direction__c = direction,
                RecordTypeId = recordTypeId,
                Zipline__SMS_Message__c = smsBody,
                Zipline__Message_Date_Time__c = DateTime.now(),
                Zipline__From_Number__c = '+61400000000'
        );
    }

    public static Zipline__Contact_Matching__c createContactMatching(Id contactId, Id messageId) {
        return new Zipline__Contact_Matching__c(
                Zipline__Contact__c = contactId,
                Zipline__Message__c = messageId
        );
    }*/

    public static Session_Communication__c createSessionCommunication(Id recordTypeId){

        return new Session_Communication__c(
                RecordTypeId = recordTypeId
        );
    }

    public static Pendula__Message__c createPendulaMessage(String messageDirection, String messageType, String pendulaId, Id recordId, Id contactId, Datetime pendulaTimeStamp){

        return new Pendula__Message__c(
                Pendula__Direction__c = messageDirection,
                Pendula__Type__c = messageType,
                Pendula__Pendula_Id__c = pendulaId,
                Pendula__Record_Id__c = recordId,
                Pendula__Recipient_Id__c = contactId,
                Pendula__Timestamp__c = pendulaTimeStamp
        );
    }
}