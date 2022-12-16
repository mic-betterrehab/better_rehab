trigger SanitizeUsers on User (before insert, before update) {
    for (User userToUpdate : Trigger.New) {
        if (userToUpdate.MobilePhone != NULL) {
            userToUpdate.MobilePhone = DataSanitizer.sanitizeMobileNumber(userToUpdate.MobilePhone);
        }
    }
}