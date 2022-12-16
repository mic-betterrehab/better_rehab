public class FuturePSA {

    //This class is called from OnboardingContactController
    //It delegates the permission sets to the correct users depending on the onboarder's attributes
	@future
    public static void insertPSAs(Id UserId, String profileName, String Department, Boolean teamLeader, String internalBanding) {
        List<PermissionSetAssignment> psas = new List<PermissionSetAssignment>();
        PermissionSet rosteringId = [SELECT Id FROM PermissionSet WHERE Label =: 'Lumary - Rostering' Limit 1];
        PermissionSet clientSessionId = [SELECT Id FROM PermissionSet WHERE Label =: 'Lumary - Client Session' Limit 1];
        PermissionSet basicId = [SELECT Id FROM PermissionSet WHERE Label =: 'Lumary - Basic' Limit 1];
        PermissionSet standardId = [SELECT Id FROM PermissionSet WHERE Label =: 'Lumary - Standard' Limit 1];
        PermissionSet advancedId = [SELECT Id FROM PermissionSet WHERE Label =: 'Lumary - Advanced' Limit 1];
        List<PermissionSet> hrPermissions = [SELECT Id FROM PermissionSet WHERE Label =: 'HR Birthday Permission' OR Label =: 'Onboarding' OR Label =: 'Offboarding'];
        PermissionSet caAdmin = [SELECT Id FROM PermissionSet WHERE Label =: 'Clinical Audit Admin' Limit 1];
        PermissionSet docusign = [SELECT Id FROM PermissionSet WHERE Label =: 'DocuSign User' Limit 1];       
        PermissionSet diaryEditor = [SELECT Id FROM PermissionSet WHERE Label =: 'Diary Editors' Limit 1];

		//This is for everyone
        PermissionSetAssignment rostering = new PermissionSetAssignment(PermissionSetId = rosteringId.Id, AssigneeId = UserId);
        PermissionSetAssignment clientsession = new PermissionSetAssignment(PermissionSetId = clientSessionId.Id, AssigneeId = UserId);
        psas.add(rostering);
        psas.add(clientsession);

        //assign docusign permission to everyone
        if(internalBanding != 'Student'){
            PermissionSetAssignment docusignUser = new PermissionSetAssignment(PermissionSetId = docusign.Id, AssigneeId = UserId);
            psas.add(docusignUser);
        }

        //Assign permission set based on their TL status and department
        if (teamLeader == TRUE || Department == 'Business Development') {
            PermissionSetAssignment standard = new PermissionSetAssignment(PermissionSetId = standardId.Id, AssigneeId = UserId);
            psas.add(standard);
        } else {
            if (Department == 'Information Technology' || Department == 'Administration' || Department == 'Management') {
                PermissionSetAssignment advanced = new PermissionSetAssignment(PermissionSetId = advancedId.Id, AssigneeId = UserId);
                psas.add(advanced);
            } else {
                PermissionSetAssignment basic = new PermissionSetAssignment(PermissionSetId = basicId.Id, AssigneeId = UserId);
                psas.add(basic);
            }
        }

        if(Department == 'Human Resources' || Department == 'Talent' || Department == 'Learning & Development'){
            for(Integer i = 0; i < hrPermissions.size(); i++){
                PermissionSetAssignment hr = new PermissionSetAssignment();
                hr.PermissionSetId = hrPermissions[i].Id;
                hr.AssigneeId = UserId;
                psas.add(hr);
            }

        }
        
        if(Department == 'Allied Health Assistant'){
            PermissionSetAssignment diaryAHA = new PermissionSetAssignment(PermissionSetId = diaryEditor.Id, AssigneeId = UserId);
            psas.add(diaryAHA);
        }
        
        if (profileName == 'System Administrator' || profileName == 'Enrite Care - Standard' || profileName == 'Enrite Care - Advanced') {  
            PermissionSetAssignment de = new PermissionSetAssignment(
                PermissionSetId = diaryEditor.Id,
                AssigneeId = UserId
            );

            psas.add(de);
        }

        //gives clinical audit admin access to all PCs and NCLs
        if(internalBanding == 'Principal Clinician' || internalBanding == 'National Clinical Lead'){
            PermissionSetAssignment ca = new PermissionSetAssignment(PermissionSetId = caAdmin.Id, AssigneeId = UserId);
            psas.add(ca);
        }

        try{
            insert psas;
        } catch (DmlException e){
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
    }
	
    //only use this method to assign group to users
    @future
    public static void assignGroup(Id UserId, String Department, String State, String internalBanding){
        Map<String, Id> ahaGroups = new Map<String, Id>();
        List<GroupMember> groupMembersToAdd = new List<GroupMember>();

        //For AHA
        if(Department == 'Allied Health Assistant'){
            for(Group grp : [SELECT Id, DeveloperName FROM Group WHERE DeveloperName LIKE '%AHA%']){
                ahaGroups.put(grp.DeveloperName, grp.Id);
            }
            
            if(State == 'NSW'){
                GroupMember nswAHA = new GroupMember(GroupId = ahaGroups.get('NSW_AHA_Queue'), UserOrGroupId = UserId);
                groupMembersToAdd.add(nswAHA);
            } else if(State == 'ACT'){
                GroupMember actAHA = new GroupMember(GroupId = ahaGroups.get('ACT_AHA_Queue'), UserOrGroupId = UserId);
                groupMembersToAdd.add(actAHA);
            } else if(State == 'VIC'){
                GroupMember vicAHA = new GroupMember(GroupId = ahaGroups.get('VIC_AHA_Queue'), UserOrGroupId = UserId);
                groupMembersToAdd.add(vicAHA);
            } else if(State == 'QLD'){
                GroupMember qldAHA = new GroupMember(GroupId = ahaGroups.get('QLD_AHA_Queue'), UserOrGroupId = UserId);
                groupMembersToAdd.add(qldAHA);
            } else if(State == 'WA' || State == 'SA'){
                GroupMember waAHA = new GroupMember(GroupId = ahaGroups.get('WA_AHA_Queue'), UserOrGroupId = UserId);
                groupMembersToAdd.add(waAHA);
            }
        }

        //For RM and SM
        if(internalBanding == 'Regional Manager' || internalBanding == 'State Manager'){
            Group caGroup = [SELECT Id FROM Group where DeveloperName = 'Clinical_Audit_RM_and_SM' LIMIT 1];
            GroupMember groupMember = new GroupMember(GroupId = caGroup.Id, UserOrGroupId = UserId);
            groupMembersToAdd.add(groupMember);
        }

        insert groupMembersToAdd;
    }
}