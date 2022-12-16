public class ContentDocumentTriggerHelper {
    public static void updateHasNotesFieldBeforeDelete(List<ContentDocument> oldDocuments) {
        Set<Id> documentSetId = new Set<Id>();
        Set<Id> entitySetId = new Set<Id>();
        Set<Id> parentEntitySetId = new Set<Id>();
        Set<Id> newEntitySetId = new Set<Id>();
        
        for (ContentDocument document : oldDocuments) {
            documentSetId.add(document.Id);
        }
        
        for (ContentDocumentLink document : ContentDocumentLinkDAO.getLinkedEntityIdByDocumentId(documentSetId)) {
            entitySetId.add(document.LinkedEntityId);
        }
        
        for (enrtcr__Assessment__c assessments : AssessmentDAO.getAssessmentHasNotesById(entitySetId)) {
            newEntitySetId.add(assessments.Id);
        }
        
        for (enrtcr__Note__c notes : CaseNotesDAO.getCaseNotesHasNotesById(entitySetId)) {
            newEntitySetId.add(notes.Id);
        }
        
        if(!newEntitySetId.isEmpty()){
            List<ContentDocumentLink> parentContentDocumentLinkList = ContentDocumentLinkDAO.getLinkedEntityIdByLinkedEntityId(documentSetId, newEntitySetId);
            
            for (ContentDocumentLink document : parentContentDocumentLinkList) {
                parentEntitySetId.add(document.LinkedEntityId);
            }
            
            if (parentContentDocumentLinkList.size() < 2) {
                List<enrtcr__Assessment__c> assessmentToUpdate = new List<enrtcr__Assessment__c>();
                List<enrtcr__Note__c> notesToUpdate = new List<enrtcr__Note__c>();
                List<enrtcr__Assessment__c> assessments = AssessmentDAO.getAssessmentHasNotesById(parentEntitySetId);
                List<enrtcr__Note__c> notes = CaseNotesDAO.getCaseNotesHasNotesById(entitySetId);
                
                if (assessments.size() > 0) {
                    for (enrtcr__Assessment__c assessment : assessments) {
                        assessment.Has_Notes__c = false;
                        assessmentToUpdate.add(assessment);
                    }
                    
                    update assessmentToUpdate;
                    
                    System.debug('assessment after updating:' + assessmentToUpdate);
                }
                
                if (notes.size() > 0) {
                    for (enrtcr__Note__c note : notes) {
                        note.Has_Notes__c = false;
                        notesToUpdate.add(note);
                    }
                    
                    update notesToUpdate;
                    System.debug('notes after updating:' + notesToUpdate);
                }
            }
        }        
        
        
    }
}