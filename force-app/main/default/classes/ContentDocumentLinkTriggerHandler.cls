public class ContentDocumentLinkTriggerHandler {
    public static void createHandler() {
        if (Trigger.isAfter) {
            if (Trigger.isInsert) {
            	ContentDocumentLinkTriggerHelper.updateHasNotesFieldAfterInsert(Trigger.New);
            }
        }
    }
}