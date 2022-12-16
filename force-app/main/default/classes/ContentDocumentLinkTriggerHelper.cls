public class ContentDocumentLinkTriggerHelper {
    public static void updateHasNotesFieldAfterInsert(List<ContentDocumentLink> newDocuments) {
        Set<Id> entitySetId = new Set<Id>();
        List<enrtcr__Assessment__c> assessmentToUpdate = new List<enrtcr__Assessment__c>();
        List<enrtcr__Note__c> notesToUpdate = new List<enrtcr__Note__c>();

        for (ContentDocumentLink document : newDocuments) {
            entitySetId.add(document.LinkedEntityId);
        }

        List<enrtcr__Assessment__c> assessments = AssessmentDAO.getAssessmentHasNotesById(entitySetId);
        List<enrtcr__Note__c> notes = CaseNotesDAO.getCaseNotesHasNotesById(entitySetId);

        System.debug('before updating:' + assessments);
        if (assessments.size() > 0) {
            for (enrtcr__Assessment__c assessment : assessments) {
                assessment.Has_Notes__c = true;
                assessmentToUpdate.add(assessment);
            }

            System.debug('assessments after updating: ' + assessmentToUpdate);
            update assessmentToUpdate;
        }

        if (notes.size() > 0) {
            for (enrtcr__Note__c note : notes) {
                note.Has_Notes__c = true;
                notesToUpdate.add(note);
            }

            System.debug('notes after updating: ' + notesToUpdate);
            update notesToUpdate;
        }
    }
}