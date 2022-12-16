/**
 * Created by ersoz on 2020-02-11.
 */

public with sharing class QueryTool {

    public static List<enrtcr__Worker_Appointment__c> findAllWorkerAppointmentsForLateChecks(){
        return [SELECT Id,
                enrtcr__Session__c,
                enrtcr__Start_Date__c,
                enrtcr__End_Date__c,
                enrtcr__Session_Status__c,
                enrtcr__Worker__c,
                enrtcr__Actual_Start_Date__c,
                enrtcr__Actual_End_Date__c
        FROM enrtcr__Worker_Appointment__c
        WHERE (enrtcr__Session_Status__c = 'Rostered' OR enrtcr__Session_Status__c = 'In Progress')
        AND (enrtcr__Start_Date__c = TODAY OR enrtcr__End_Date__c = TODAY)
        AND (enrtcr__Actual_Start_Date__c = NULL OR enrtcr__Actual_End_Date__c = NULL)
        ];
    }

    public static List<enrtcr__Session__c> findSessionsWithWorkerInfo(Set<Id> sessionIds){
        return [SELECT Id,
        (SELECT Id,
                enrtcr__Worker__r.Name,
                enrtcr__Worker__r.Clinician_Discipline__c,
                enrtcr__Worker__r.enrtcr__Site__c
        FROM enrtcr__Worker_Appointments__r),
                enrtcr__Required_Workers__c,
                Workers_and_Professions__c
        FROM enrtcr__Session__c
        WHERE Id IN: sessionIds];
    }

    public static List<Session_Communication__c> findSessionCommunicationsByWorkerAppId(
            Set<Id> workerAppointmentIds,
            Id recordTypeIdCheckin,
            Id recordTypeIdCheckout
    ){

        return [SELECT Id,
                RecordTypeId,
                Worker_Appointment__c
        FROM Session_Communication__c
        WHERE Worker_Appointment__c IN :workerAppointmentIds
        AND CreatedDate = TODAY
        AND (RecordTypeId = :recordTypeIdCheckin
        OR RecordTypeId = :recordTypeIdCheckout)
        ];
    }

    /*
    public static List<Zipline__Message__c> getInboundMessages(Set<Id> messageIds){

        return [SELECT Id,
                Zipline__SMS_Message__c
        FROM Zipline__Message__c
        WHERE Zipline__Direction__c = 'Inbound'
        AND RecordType.Name = 'Inbound SMS'
        AND Id IN :messageIds
        ];
    }

    public static List<Customer_Feedback_Survey__c> getSurveysByContactId(Set<Id> contactIds){
        return [SELECT Id,
                Session__c,
                Recipient__c,
                Survey_Response__c,
                Unrecognised_Response__c
        FROM Customer_Feedback_Survey__c
        WHERE Recipient__c IN :contactIds
        AND Survey_is_Completed__c = FALSE
        ORDER BY Id DESC
        LIMIT 1];
    }


    public static List<Customer_Feedback_Survey__c> getExistingInitialSurveysByContactIds(Set<Id> contactIds){

        return [SELECT Id,
                Recipient__c,
                CreatedDate
        FROM Customer_Feedback_Survey__c
        WHERE CreatedDate = LAST_N_DAYS:180
        AND Recipient__c = :contactIds
        AND Survey_Type__c = 'Initial'
        ];
    }*/

    public static List<Pendula__Message_Recipient__c> findMessageRecipientsByMessageIds(Set<Id> messageIds){

        return [
                SELECT Id, Pendula__Contact__c,Pendula__Message__c FROM Pendula__Message_Recipient__c
                WHERE Pendula__Message__c IN :messageIds
                AND Pendula__Contact__c != NULL
        ];
    }

    public static List<Pendula__Message__c> findSurveyRelatedOutboundMessagesByRecipientIds(Set<Id> contactIds){

        Set<String> flowIds = new Set<String>();

        //there are multiple flow ids in Custom Settings within Salesforce
        //so 1 client should have 1 incomplete survey otherwise it will error
        for (Survey_Settings__c setting : findSurveySettingRecord()){

            flowIds.add(setting.Flow_Id__c);
        }

        if(flowIds == null) return null;

        return [
                SELECT Id,Pendula__Record_Id__c,Pendula__Recipient_Id__c,Pendula__SMS_Body__c
                FROM Pendula__Message__c
                WHERE Pendula__Recipient_Id__c IN :contactIds
                AND RecordTypeId = :Schema.SObjectType.Pendula__Message__c.getRecordTypeInfosByDeveloperName().get('Outbound_SMS').getRecordTypeId()
                AND Pendula__Flow_Id__c IN :flowIds
        ];
    }

    public static List<Customer_Feedback_Survey__c> findIncompleteSurveysByIds(Set<Id> surveyIds) {

        return [
                SELECT Id,
                        Unrecognised_Response__c
                FROM Customer_Feedback_Survey__c
                WHERE Id IN :surveyIds
                AND Survey_is_Completed__c = FALSE
        ];
    }

    public static List<Survey_Settings__c> findSurveySettingRecord(){

        return [SELECT Id,Flow_Id__c,Flow_Name__c,Name FROM Survey_Settings__c];
    }

    /*public static String findSessions(){

        return 'SELECT Id,' +
                'enrtcr__Start_Date__c,' +
                'enrtcr__End_Date__c,' +
                'enrtcr__Service_Types__c,' +
                'Worker_Site__c, ' +
                '(SELECT Id,enrtcr__Client__c,enrtcr__Session__c,enrtcr__Client__r.Client_Division__c,enrtcr__Client__r.Pendula_Survey_Opt_Out__c FROM enrtcr__Client_Appointments__r), Workers_and_Professions__c, ' +
                '(SELECT Id,enrtcr__Worker__r.Id FROM enrtcr__Worker_Appointments__r) ' +
                'FROM enrtcr__Session__c ' +
                'WHERE  enrtcr__Status__c != \'Cancelled\' ' +
                'AND enrtcr__Service_Types__c = \'Initial Assessment\' ' +
                'AND Days_After_End_Date__c = 1';
    }*/

    public static List<Customer_Feedback_Survey__c> findFollowUpSurveysByClientIds(Set<Id> clientIds){

        return [
                SELECT Id,
                        Recipient__c,
                        First_Question_Sent__c,
                        CreatedDate
                FROM Customer_Feedback_Survey__c
                WHERE Recipient__c IN :clientIds
                AND Survey_Type__c = 'Follow up' ORDER BY First_Question_Sent__c DESC
        ];
    }

    public static List<enrtcr__Client_Appointment__c> findClientAppointmentsByClientIds(Set<Id> clientIds){

        return [
                SELECT enrtcr__Session__c, enrtcr__Client__c
                FROM enrtcr__Client_Appointment__c
                WHERE enrtcr__Client__c IN :clientIds
                AND enrtcr__Status__c != 'Cancelled'
        ];
    }

    public static List<enrtcr__Session__c> findAllSessionsWithinEightWeeksByIds(Set<Id> sessionIds){

        return [
                SELECT Id FROM enrtcr__Session__c
                WHERE Id IN :sessionIds
                AND enrtcr__Status__c != 'Cancelled'
                AND Days_After_End_Date__c > 0
                AND Days_After_End_Date__c <= 56
        ];
    }
}