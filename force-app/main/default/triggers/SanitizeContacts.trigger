trigger SanitizeContacts on Contact (before insert, before update) {
    for (Contact contactToUpdate : Trigger.New) {
        if (contactToUpdate.MobilePhone != NULL) {
            contactToUpdate.MobilePhone = DataSanitizer.sanitizeMobileNumber(contactToUpdate.MobilePhone);
        }
    }
}