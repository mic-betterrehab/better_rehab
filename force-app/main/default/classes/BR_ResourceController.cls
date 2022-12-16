public class BR_ResourceController {
	@AuraEnabled
    public static Map<String, Object> getResources(Id siteId) {
        User u = [SELECT id, State FROM User WHERE id =: UserInfo.getUserId()];

        // get all active resources for a specific site and mobile resources shared across multiple sites
    	List<Resource__c> resources = isResourceAdmin() ?
                                            BR_ResourceDAO.getActiveAndTierOneResources() :
                                            BR_ResourceDAO.getActiveAndTierOneResourcesByState(u.state);

        // get all slots taken for the resources pulled
        List<Slot__c> slots = getSlots(resources);

        // prepare FullCalendar compatible resources
        List<Map<String, Object>> resourcesFinal = new List<Map<String, Object>>();
        List<Map<String, Object>> formattedNationalResource = new List<Map<String, Object>>();
        List<Map<String, Object>> defaultResource = formatResources(resources);

        // prepare FullCalendar compatible slots
        List<Map<String, Object>> slotsFinal = new List<Map<String, Object>>();
        List<Map<String, Object>> formattedNationalSlots = new List<Map<String, Object>>();
        List<Map<String, Object>> defaultSlots = formatSlots(slots);

        if (!isResourceAdmin()) {
            List<Resource__c> nationalResources = BR_ResourceDAO.getActiveAndTierOneResourcesWithNullSite();
            List<Slot__c> nationalSlots = getSlots(nationalResources);
            formattedNationalResource = formatResources(nationalResources);
            formattedNationalSlots = formatSlots(nationalSlots);
        }

        resourcesFinal.addAll(defaultResource);
        resourcesFinal.addAll(formattedNationalResource);
        slotsFinal.addAll(defaultSlots);
        slotsFinal.addAll(formattedNationalSlots);

        return new Map<String, Object>{'resources' => resourcesFinal, 'slots' => slotsFinal};
    }

    @TestVisible private static List<Map<String, Object>> formatResources(List<Resource__c> resources) {
        List<Map<String, Object>> resourcesFinal = new List<Map<String, Object>>();

        for (Resource__c r : resources) {
            String stateName = r.Site__c == null ? 'National' :  r.Site__r.enrtcr__Business_State__c;
            Map<String,Object> o = new Map<String,Object>();
           	o.put('id', r.id);
            o.put('title', r.Name);
            o.put('groupId', r.Site__c);
            o.put('status', r.Status__c);
            o.put('tier', r.Tier__c);
            o.put('type', r.Type__c);
            o.put('stateName', stateName);

            resourcesFinal.add(o);
        }

        return resourcesFinal;
    }

    @TestVisible private static List<Map<String, Object>> formatSlots(List<Slot__c> slots) {
        List<Map<String, Object>> slotsFinal = new List<Map<String, Object>>();

        for (Slot__c s : slots) {
            Map<String,Object> o = new Map<String,Object>();
            String site = s.Destination_Site__r.Name == NULL ? 'NONE' : s.Destination_Site__r.Name;
            String title = s.Owner.Name + ' (' + site + ')';

            o.put('id', s.id);
            o.put('title', title);
            o.put('siteId', s.Destination_Site__c);
            o.put('siteName', s.Destination_Site__r.Name);
            o.put('resourceId', s.Resource__c);
            o.put('ownerId', s.OwnerId);
            o.put('ownerName', s.Owner.Name);
            o.put('start', s.Start_Time__c);
            o.put('end', s.End_Time__c);
            o.put('worker', s.Worker__c);
            o.put('client', s.Client__c);
            slotsFinal.add(o);
        }

        return slotsFinal;
    }

    @TestVisible private static Boolean isResourceAdmin() {
        Boolean isResourceAdmin = false;

        for (GroupMember gm : [SELECT id, UserOrGroupId
                                FROM GroupMember
                                WHERE UserOrGroupId != null
                                AND Group.Name = 'Resource Admins'
        ]) {
            if (gm.UserOrGroupId == UserInfo.getUserId()) {
                isResourceAdmin = true;
            }
        }

        return isResourceAdmin;
    }

    @AuraEnabled
    public static Map<String, Object> a_loadUser(Id siteId) {
        Map<String, Object> res = new Map<String, Object>();

        res.put('userId', UserInfo.getUserId());
        String profileName = [SELECT id, Name FROM Profile WHERE id =: UserInfo.getProfileId()].Name;

        if (profileName == 'System Administrator') {
            res.put('permissionLevel', 'SYSADMIN');
        } else {
            for (GroupMember gm : [SELECT id, UserOrGroupId
                                     FROM GroupMember
                                     WHERE UserOrGroupId != null
                                        AND Group.Type = 'Regular'
                                        AND Group.Name = 'Resource Admins'
                                  ]) {
                                      if (gm.UserOrGroupId == UserInfo.getUserId()) {
                                          res.put('permissionLevel', 'RESADMIN');
                                          break;
                                      }
                                  }
        }
        if (!res.containsKey('permissionLevel')) {
            res.put('permissionLevel', 'CLINICIAN');
        }


        return res;
    }

    public static List<Slot__c> getSlots(List<Resource__c> resources) {
        DateTime cutoff = System.today() - 120;
        return [SELECT id, OwnerId, Owner.Name, Resource__c, Name, Destination_Site__r.Name, Start_Time__c, End_Time__c, Worker__c, Client__c FROM Slot__c WHERE Resource__c IN :resources AND Start_Time__c > :cutoff];
    }
}