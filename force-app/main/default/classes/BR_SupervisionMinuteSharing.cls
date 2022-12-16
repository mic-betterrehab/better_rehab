public class BR_SupervisionMinuteSharing {
    List<Supervision_Minutes__Share> listOfShares;
    public final Id userId = UserInfo.getUserId();

    public BR_SupervisionMinuteSharing(List<Supervision_Minutes__c> listOfSupervisionMinutes) {
        listOfShares = new List<Supervision_Minutes__Share>();
        Id recordType = Schema.SObjectType.Supervision_Minutes__c.getRecordTypeInfosByDeveloperName().get('Supervision_Agenda').getRecordTypeId();
        Map<Id, Supervision_Minutes__c> supervisionMinutes = new Map<Id, Supervision_Minutes__c>([
                                                                                                    SELECT
                                                                                                        Id,
                                                                                                        OwnerId,
                                                                                                        CreatedById,
            																							RecordTypeId,
                                                                                                        Supervisor__r.enrtcr__User__c,
                                                                                                        Supervisee__r.enrtcr__User__c,
                                                                                                        Supervisee__r.Direct_Supervisor__c,
                                                                                                        Supervisee__r.Principal_Clinician__c,
                                                                                                        Supervisee__r.Direct_Supervisor__r.enrtcr__User__c,
                                                                                                        Supervisee__r.Direct_Supervisor__r.enrtcr__User__r.IsActive,
                                                                                                        Supervisee__r.Principal_Clinician__r.enrtcr__User__c,
                                                                                                        Supervisee__r.Principal_Clinician__r.enrtcr__User__r.IsActive
                                                                                                    FROM Supervision_Minutes__c
                                                                                                    WHERE Id
                                                                                                    IN :listOfSupervisionMinutes
                                                                                                ]);

        for (Supervision_Minutes__c sm : supervisionMinutes.values()) {
            if (sm.OwnerId != sm.Supervisee__r.enrtcr__User__c) { // User is the supervisee
                Supervision_Minutes__Share share = createShare(sm.Id, sm.Supervisee__r.enrtcr__User__c);
                listOfShares.add(share);
            }

            if (sm.OwnerId != sm.Supervisor__r.enrtcr__User__c) { // User is the supervisor
                Supervision_Minutes__Share share = createShare(sm.Id, sm.Supervisor__r.enrtcr__User__c);
                listOfShares.add(share);
            }

            // Check if record type is Supervision Agenda/Supervision Minutes
            if (sm.RecordTypeId == recordType) {
                if (sm.Supervisee__r.Direct_Supervisor__c != NULL && sm.Supervisee__r.Direct_Supervisor__r.enrtcr__User__r.IsActive) {
                    if (sm.OwnerId != sm.Supervisee__r.Direct_Supervisor__r.enrtcr__User__c) { // User is the supervisor
                        Supervision_Minutes__Share share = createShare(sm.Id, sm.Supervisee__r.Direct_Supervisor__r.enrtcr__User__c);
                        listOfShares.add(share);
                    }
                }
    
                if (sm.Supervisee__r.Principal_Clinician__c != NULL && sm.Supervisee__r.Principal_Clinician__r.enrtcr__User__r.IsActive) {
                    if (sm.OwnerId != sm.Supervisee__r.Principal_Clinician__r.enrtcr__User__c) { // User is the supervisor
                        Supervision_Minutes__Share share = createShare(sm.Id, sm.Supervisee__r.Principal_Clinician__r.enrtcr__User__c);
                        listOfShares.add(share);
                    }
                }
            }
        }

        // Insert sharing records and capture save result
        // The false parameter allows for partial processing if multiple records are passed
        // into the operation
        Database.SaveResult[] lsr = Database.insert(listOfShares, false);

        // Create counter
        Integer i = 0;

        // Process the save results
        for (Database.SaveResult sr : lsr) {
            if (!sr.isSuccess()) {
                // Get the first save result error
                Database.Error err = sr.getErrors()[0];

                // Check if the error is related to a trivial access level
                // Access levels equal or more permissive than the object's default
                // access level are not allowed.
                if (listOfShares.size() > 0) {
                    supervisionMinutes.get(listOfShares[i].ParentId).
                      addError(
                       'Unable to grant sharing access due to following exception: '
                       + err.getMessage());
                }
            }

            i++;
        }
    }

    // for creating the Read/Write sharing access
    public Supervision_Minutes__Share createShare(Id recordId, Id userOrGroupId) {
        Supervision_Minutes__Share caShare = new Supervision_Minutes__Share();

        if (userOrGroupId != NULL) {
            caShare.ParentId = recordId;
            caShare.UserOrGroupId = userOrGroupId;
            caShare.AccessLevel = 'Edit';
        }

        return caShare;
    }
}