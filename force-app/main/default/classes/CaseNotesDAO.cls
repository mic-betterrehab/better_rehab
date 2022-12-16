public with sharing class CaseNotesDAO {
    public static List<enrtcr__Note__c> getCaseNotesHasNotesById(Set<Id> caseNotesSetId) {
        return [
            SELECT
                Id,
                Has_Notes__c
            FROM enrtcr__Note__c
            WHERE Id IN: caseNotesSetId
        ];
    }
}