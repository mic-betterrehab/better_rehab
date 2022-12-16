trigger BR_ContentDocumentTrigger on ContentDocument (before delete) {
	ContentDocumentTriggerHandler.createHandler();
}