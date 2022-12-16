public class ContentDocumentTriggerHandler {
    public static void createHandler() {
        if (Trigger.isBefore) {
            if (Trigger.isDelete) {
            	ContentDocumentTriggerHelper.updateHasNotesFieldBeforeDelete(Trigger.Old);
            }
        }
    }
}