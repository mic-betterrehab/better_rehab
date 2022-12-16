public class ContentDocumentLinkDAO {
    public static List<ContentDocumentLink> getLinkedEntityIdByDocumentId(Set<Id> documentSetId) {
        return [SELECT LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN: documentSetId];
    }


    public static List<ContentDocumentLink> getLinkedEntityIdByLinkedEntityId(
        Set<Id> documentSetId,
        Set<Id> entitySetId
    ) {
        return [
            SELECT
                LinkedEntityId
            FROM ContentDocumentLink
            WHERE
            LinkedEntityId IN: entitySetId
        ];
    }
}