@isTest
public class ContentDocumentTriggerHelperTest {
    static testMethod void updateHasNotesFieldBeforeDeleteTest() {
        Contact client = TestObjects.createContact(1, 'NDIS');
        insert client;

        enrtcr__Assessment__c assessment = TestObjects.createAssessmentReview(1);
        assessment.enrtcr__Client__c = client.Id;
        assessment.Has_Notes__c = true;
        insert assessment;

        ContentVersion contentVersion = TestObjects.createContentVersion();
        contentVersion.FirstPublishLocationId = assessment.Id;
        insert contentVersion;

        List<ContentDocumentLink> cdl = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: assessment.Id];
        Set<Id> cdlIds = new Set<Id>();

        for (ContentDocumentLink doc : cdl) {
            cdlIds.add(doc.ContentDocumentId);
        }

        List<ContentDocument> contentDocuments = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument WHERE Id IN: cdlIds];

        Test.startTest();
            delete contentDocuments;
        Test.stopTest();

        List<enrtcr__Note__c> notes = CaseNotesDAO.getCaseNotesHasNotesById(new Set<Id>{assessment.Id});
        enrtcr__Assessment__c updatedAssessment = [SELECT Has_Notes__c FROM enrtcr__Assessment__c WHERE Id =: assessment.Id];

        System.assertEquals(0, notes.size());
        System.assertEquals(false, updatedAssessment.Has_Notes__c);
    }

    static testMethod void updateCaseNoteHasNotesFieldBeforeDeleteTest() {
        Contact client = TestObjects.createContact(1, 'NDIS');
        insert client;

        enrtcr__Note__c note = TestObjects.createCaseNotes(10, 1);
        note.enrtcr__Client__c = client.Id;
        note.Has_Notes__c = true;
        insert note;

        ContentVersion contentVersion = TestObjects.createContentVersion();
        contentVersion.FirstPublishLocationId = note.Id;
        insert contentVersion;

        List<ContentDocumentLink> cdl = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: note.Id];
        Set<Id> cdlIds = new Set<Id>();

        for (ContentDocumentLink doc : cdl) {
            cdlIds.add(doc.ContentDocumentId);
        }

        List<ContentDocument> contentDocuments = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument WHERE Id IN: cdlIds];

        Test.startTest();
            delete contentDocuments;
        Test.stopTest();

        List<enrtcr__Assessment__c> assessments = AssessmentDAO.getAssessmentHasNotesById(new Set<Id>{note.Id});
        enrtcr__Note__c updateNote = [SELECT Has_Notes__c FROM enrtcr__Note__c WHERE Id =: note.Id];

        System.assertEquals(0, assessments.size());
        System.assertEquals(false, updateNote.Has_Notes__c);
    }
}