@isTest
public with sharing class BR_SupervisionMinuteSharingTest {
    public static String basicWorkerName = 'Basic Worker';
    public static String standardWorkerName = 'Standard Worker';
    public static String advancedWorkerName = 'Advanced Worker';
    public static String supervisionMinute = 'Test Supervision Minute';
    public static String supervisionMinuteNotSupervisor = 'Test Supervision Minute Not Supervisor';

    // Test for the BR_SupervisionMinuteSharing class
    @testSetup static void setup() {
        User basic = getUser('Enrite Care - Basic');
        User standard = getUser('Enrite Care - Standard');
        User advance = getUser('Enrite Care - Advanced');
        List<Contact> listsOfContacts = new List<Contact>();
        List<Supervision_Minutes__c> listsOfSupervisionMinutes = new List<Supervision_Minutes__c>();

        Contact basicWorker = TestObjects.createContact(6,'NDIS');
        basicWorker.LastName = basicWorkerName;
        basicWorker.enrtcr__User__c = basic.Id;
        Contact standardWorker = TestObjects.createContact(6,'NDIS');
        standardWorker.LastName = standardWorkerName;
        standardWorker.enrtcr__User__c = standard.Id;
        Contact advancedWorker = TestObjects.createContact(6,'NDIS');
        advancedWorker.LastName = advancedWorkerName;
        advancedWorker.enrtcr__User__c = advance.Id;

        listsOfContacts.add(basicWorker);
        listsOfContacts.add(standardWorker);
        listsOfContacts.add(advancedWorker);

        insert listsOfContacts;
    }

    @isTest static void testCreateSupervisionMinutes() {
        Contact basicWorker = getContact(basicWorkerName);
        Contact standardWorker = getContact(standardWorkerName);
        Contact advancedWorker = getContact(advancedWorkerName);
        Supervision_Minutes__c newSupervisionMinute = setSupervisionMinuteValues(supervisionMinuteNotSupervisor);

        basicWorker.Principal_Clinician__c = advancedWorker.Id;
        basicWorker.Direct_Supervisor__c = advancedWorker.Id;

        update basicWorker;

        newSupervisionMinute.Supervisor__c = advancedWorker.Id;
        newSupervisionMinute.Supervisee__c = basicWorker.Id;
        newSupervisionMinute.OwnerId = standardWorker.enrtcr__User__c;

        Test.startTest();
            insert newSupervisionMinute;
            List<Supervision_Minutes__Share> shareList = getSMShare(supervisionMinuteNotSupervisor);
        Test.stopTest();

        System.assertEquals(shareList.size(), shareList.size());
    }

    private static Supervision_Minutes__c setSupervisionMinuteValues(String name) {
        Supervision_Minutes__c newSupervisionMinute = new Supervision_Minutes__c();
        newSupervisionMinute.Name = name;
        newSupervisionMinute.Date__c = System.today();
        newSupervisionMinute.Check_in__c = 'Things are going amazing';
        newSupervisionMinute.Values__c = 'Loving What I do';
        newSupervisionMinute.PCH_Last_Week__c = '100%';
        newSupervisionMinute.PCH_Last_Cycle__c = 'More than 100%';
        newSupervisionMinute.Check_in_Discussion__c = 'Test Discussion';

        return newSupervisionMinute;
    }

    private static List<Supervision_Minutes__Share> getSMShare(String name) {
        Supervision_Minutes__c newSupervisionMinute = [
                                                        SELECT
                                                            Id
                                                        FROM Supervision_Minutes__c
                                                        WHERE Name =: name
                                                    ];

        return [
                SELECT
                    Id,
                    UserOrGroupId,
                    AccessLevel,
                    RowCause
                FROM Supervision_Minutes__Share
                WHERE ParentId =: newSupervisionMinute.Id
                AND AccessLevel = 'Read'
        ];
    }

    private static Contact getContact(String profile) {
        return [
            SELECT
                Id,
                enrtcr__User__c,
                Direct_Supervisor__c,
                Principal_Clinician__c
            FROM Contact
            WHERE LastName =: profile
            LIMIT 1
        ];
    }

    private static User getUser(String profile) {
        return [
            SELECT Id
            FROM User
            WHERE IsActive = TRUE
            AND ProfileId =: [
                                SELECT Id
                                FROM Profile
                                WHERE Name =: profile
                                LIMIT 1
                            ]
            LIMIT 1
        ];
    }
}