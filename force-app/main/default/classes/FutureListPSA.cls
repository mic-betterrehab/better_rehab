public class FutureListPSA {
	@future
    public static void insertPSAs(Map<Id, String> iDdeps) {
        List<PermissionSetAssignment> psas = new List<PermissionSetAssignment>();
        PermissionSet rosteringId = [SELECT Id FROM PermissionSet WHERE Label =: 'Lumary - Rostering' Limit 1];
        PermissionSet clientSessionId = [SELECT Id FROM PermissionSet WHERE Label =: 'Lumary - Client Session' Limit 1];
        PermissionSet basicId = [SELECT Id FROM PermissionSet WHERE Label =: 'Lumary - Basic' Limit 1];
        PermissionSet standardId = [SELECT Id FROM PermissionSet WHERE Label =: 'Lumary - Standard' Limit 1];
        PermissionSet advancedId = [SELECT Id FROM PermissionSet WHERE Label =: 'Lumary - Advanced' Limit 1];
        
        for (Id UserId : iDdeps.keySet()) {
            String Department = iDdeps.get(UserId);
            PermissionSetAssignment rostering = new PermissionSetAssignment(PermissionSetId = rosteringId.Id, AssigneeId = UserId);
        	PermissionSetAssignment clientsession = new PermissionSetAssignment(PermissionSetId = clientSessionId.Id, AssigneeId = UserId);
            psas.add(rostering);
            psas.add(clientsession);
            if (Department == 'Information Technology' || Department == 'Administration' || Department == 'Management') {
                PermissionSetAssignment advanced = new PermissionSetAssignment(PermissionSetId = advancedId.Id, AssigneeId = UserId);
                psas.add(advanced);
            } else if (Department == 'Team Leaders') {
                PermissionSetAssignment standard = new PermissionSetAssignment(PermissionSetId = standardId.Id, AssigneeId = UserId);
                psas.add(standard);
            } else {
                PermissionSetAssignment basic = new PermissionSetAssignment(PermissionSetId = basicId.Id, AssigneeId = UserId);
                psas.add(basic);
            }
        }
		insert psas;
    }
}