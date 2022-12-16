trigger BR_ContentDocumentLink on ContentDocumentLink (before insert, after insert, before delete, after delete) {
	ContentDocumentLinkTriggerHandler.createHandler();
}