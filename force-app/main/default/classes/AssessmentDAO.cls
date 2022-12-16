public class AssessmentDAO {
    public static List<enrtcr__Assessment__c> getAssessmentHasNotesById(Set<Id> assessmentSetId) {
        return [
            SELECT
            	Id,
            	Has_Notes__c
            FROM enrtcr__Assessment__c
            WHERE Id IN: assessmentSetId
        ];
    }
}