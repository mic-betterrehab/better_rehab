public class BR_ResourceSlotController {
    @AuraEnabled
    public static Map<String, String> a_init(){
        Map<String, String> queries = new Map<String, String>();
        User u = [SELECT id, State FROM User WHERE id =: UserInfo.getUserId()];
        System.debug('----------' + u.State);
        //
        try {
            String now = DateTime.now().format('yyyy-MM-dd');
            String userState = u.State;
            System.debug(userState);
            String resourceQuery = 'AND Status__c = \'Active\' AND Tier__c = \'1\' AND (Site__c = NULL OR Site__r.enrtcr__Business_State__c = \''+userState+'\') AND (Expiry_Date__c = NULL OR Expiry_Date__c >= '+now+')';

            queries.put('resource', resourceQuery);

            return queries;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

	@AuraEnabled
    public static Slot__c a_createSlot(String requestObject) {
        SlotCreate req = (SlotCreate)JSON.deserialize(requestObject, SlotCreate.Class);

        Slot__c s = new Slot__c();
        s.OwnerId = req.userId;
        s.Resource__c = req.resourceId;
        s.Client__c = req.clientId;
        s.Destination_Site__c = req.destinationSiteId;
        s.Start_Time__c = Utility.GMTStringToGMTdt(req.startDt);
        s.End_Time__c = Utility.GMTStringToGMTdt(req.endDt);

        try {
        	insert s;
        } catch (DMLException err) {
            System.debug(err.getMessage());
            throw new AuraHandledException(err.getMessage());
        }


        return getSlot(s.Id);
    }

    @AuraEnabled
    public static Slot__c a_updateSlot(String updateJSON) {
        SlotUpdate req = (SlotUpdate)JSON.deserialize(updateJSON, SlotUpdate.Class);

        Slot__c s = getSlot(req.slotId);
        if (req.destinationSite != 'NULL') {
        	s.Destination_Site__c = req.destinationSite;
        }
        s.Start_Time__c = Utility.GMTStringToGMTdt(req.startTime);
        s.End_Time__c = Utility.GMTStringToGMTdt(req.endTime);

        try {
        	update s;
        } catch (DMLException err) {
            System.debug(err.getMessage());
            throw new AuraHandledException(err.getMessage());
        }


        return getSlot(s.Id);
    }

    @AuraEnabled
    public static void a_deleteSlot(Id slotId) {
    	Slot__c slot = [SELECT id FROM Slot__c WHERE id =: slotId];

        try {
            delete slot;
        } catch (DMLException err) {
            throw new AuraHandledException(err.getMessage());
        }
    }

    @AuraEnabled
    public static Slot__c a_getSlot(Id slotId) {
        return getSlot(slotId);
    }

    private static Slot__c getSlot(Id slotId) {
        return [SELECT id, OwnerId, Owner.Name, Destination_Site__c, Destination_Site__r.Name, Resource__c,Resource__r.Name, Start_Time__c, End_Time__c, Client__c, Client__r.Name FROM Slot__c WHERE id =: slotId];
    }
    class SlotCreate {
        String resourceId;
        String userId;
        String clientId;
        String destinationSiteId;
        String startDt;
        String endDt;
    }

    class SlotUpdate {
        String slotId;
        String startTime;
        String endTime;
        String destinationSite;
    }
}