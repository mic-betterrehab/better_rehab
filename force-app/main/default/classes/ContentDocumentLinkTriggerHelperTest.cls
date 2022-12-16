@isTest
public class ContentDocumentLinkTriggerHelperTest {
    static testMethod void updateHasNotesFieldAfterInsertTest() {
        Contact client = TestObjects.createContact(1, 'NDIS');
        insert client;

        enrtcr__Assessment__c assessment = TestObjects.createAssessmentReview(1);
        assessment.enrtcr__Client__c = client.Id;
        insert assessment;

        ContentVersion contentVersion = TestObjects.createContentVersion();
        contentVersion.FirstPublishLocationId = assessment.Id;

        Test.startTest();
        	insert contentVersion;

        	ContentDocumentLinkTriggerHelper.updateHasNotesFieldAfterInsert(new List<ContentDocumentLink>());
        Test.stopTest();

        List<enrtcr__Note__c> notes = CaseNotesDAO.getCaseNotesHasNotesById(new Set<Id>{assessment.Id});
        enrtcr__Assessment__c updatedAssessment = [SELECT Id, Has_Notes__c FROM enrtcr__Assessment__c WHERE Id =: assessment.Id];

        System.assertEquals(0, notes.size());
        System.assertEquals(true, updatedAssessment.Has_Notes__c);
    }

    static testMethod void updateCaseNotesHasNotesFieldAfterInsertTest() {
        Contact client = TestObjects.createContact(1, 'NDIS');
        insert client;

        enrtcr__Note__c note = TestObjects.createCaseNotes(10, 1);
        note.enrtcr__Client__c = client.Id;
        insert note;

        ContentVersion contentVersion = TestObjects.createContentVersion();
        contentVersion.FirstPublishLocationId = note.Id;

        Test.startTest();
        	insert contentVersion;

        	ContentDocumentLinkTriggerHelper.updateHasNotesFieldAfterInsert(new List<ContentDocumentLink>());
        Test.stopTest();

        List<enrtcr__Assessment__c> assessments = AssessmentDAO.getAssessmentHasNotesById(new Set<Id>{note.Id});
        enrtcr__Note__c updatedNote = [SELECT Id, Has_Notes__c FROM enrtcr__Note__c WHERE Id =: note.Id];

        System.assertEquals(0, assessments.size());
        System.assertEquals(true, updatedNote.Has_Notes__c);
    }
}