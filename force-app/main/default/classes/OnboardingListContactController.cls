public with sharing class OnboardingListContactController {
	// Constructor - this is only required/used if the autoRun function does not work
    /*private ApexPages.StandardSetController standardController;
	private Account brAcc;
    private enrtcr__Reference_Data__c IDLS;
    public OnboardingListContactController(ApexPages.StandardSetController standardController) {
        this.standardController = standardController;
        System.debug('the controller ' + standardController);
    }

    //VF Page will invoke this method
    public PageReference autoRun() {
        List<Onboarding__c> a = (List<Onboarding__c>) standardController.getSelected();
        List<Onboarding__c> selectedIds = (List<Onboarding__c>) standardController.getRecords();
        System.debug('selectedIds ' + standardController);
        System.debug('a ' + a);
        for (Onboarding__c o : selectedIds) {
            System.debug(o);
        }
        if (selectedIds.size() < 1) {
            //no id was given from button to VF page to this controller - display VF page content
            return null;
        }
        Account[] accs = [SELECT Id FROM Account WHERE Name = 'Better Rehab' LIMIT 1];
        this.brAcc = accs[0];
        enrtcr__Reference_Data__c[] supportCategory = [SELECT id FROM enrtcr__Reference_Data__c WHERE Name = 'Improved daily living skills' LIMIT 1];
        this.IDLS = supportCategory[0];
        List<Onboarding__c> toOnboard = new List<Onboarding__c>();
        for(Onboarding__c selectedOnboarder : selectedIds) {
            //selectedOnboarder = [SELECT id, Start_Date__c, Contact_Apex_Run__c, User_Apex_Run__c, Email__c, Name, First_Name__c, Last_Name__c, Phone_Number__c, State__c, Department__c, Office__c, Clinical_Supervisor__c, Gender__c, Direct_Supervisor__c, Site__c FROM onboarding__c WHERE id =: selectedOnboarder.Id LIMIT 1];
            if (selectedOnboarder.User_Apex_Run__c == false) {
                System.debug('The user Apex Run checkbox for ' + selectedOnboarder.Name + ' is marked as false. Please create the user account for this peron first');
                continue;
            } else if (selectedOnboarder.Contact_Apex_Run__c == true) {
            	System.debug('The contact Apex Run checkbox for ' + selectedOnboarder.Name +  ' is marked as true. It looks like Apex contact creation code has been run on this new starter already');
            	continue;
        	} else {
                selectedOnboarder.Contact_Apex_Run__c = true;
                toOnboard.add(selectedOnboarder);
            }
        }

        if (toOnboard.size() == 0) {
            System.debug('It looks like your selection of contacts to onboard have all been made');
            return null;
        }

        createContact(toOnboard, 0);
        createContact(toOnboard, 1);
        update toOnboard;

        return standardController.save();
    }


    private void createContact(List<Onboarding__c> onboarders, Integer Supervision) {
        List<Contact> newContacts = new List<Contact>();
        Map<Id, String> psas = new Map<Id, String>();
        User u = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        for (Onboarding__c onboarder : onboarders) {
            User Employee = [SELECT id, Email FROM User WHERE Email =: onboarder.Email__c];
            if (Employee.id != null) {
                Contact newWorker = new Contact();

                if (onboarder.Site__c != null) {
                    newWorker.enrtcr__Site__c = onboarder.Site__c;
                }
                if (Supervision == 0) {
                    psas.put(Employee.id, onboarder.Department__c);
                    newWorker.FirstName = onboarder.First_Name__c;
                    newWorker.LastName = onboarder.Last_Name__c;
                    //worker record ID
                    newWorker.RecordTypeId = '0122v0000013OcoAAE';
                    //Better Rehab Account ID
                    newWorker.AccountId = this.brAcc.Id;
                    newWorker.Caseload_Preference__c = 'Mixed Cohort (All ages)';
                	newWorker.enrtcr__User__c = Employee.Id;
                    if (onboarder.Clinical_Supervisor__c != null) {
                    	newWorker.Clinical_Supervisor__c = onboarder.Clinical_Supervisor__c;
                    }
                    if (onboarder.Direct_Supervisor__c != null) {
                        newWorker.Direct_Supervisor__c = onboarder.Direct_Supervisor__c;
                    }
                    if (onboarder.Department__c != 'Management' && onboarder.Department__c != 'Team Leaders') {
                        newWorker.Clinician_Discipline__c = onboarder.Department__c;
                    }
                } else if (Supervision == 1) {
                    newWorker.FirstName = onboarder.First_Name__c + ' ' + onboarder.Last_Name__c;
                    newWorker.LastName = 'SUPERVISION';
                    //client record ID
                    newWorker.RecordTypeId = '0122v0000013ObcAAE';
                    newWorker.Method__c = 'Face to Face';
                    newWorker.Client_Division__c = 'Private';

                    Account newacc = new Account();
                    newacc.OwnerId = u.Id;
                    newacc.Name = Onboarder.Last_Name__c + ' SUPERVISION Household';
                    insert newacc;
                    Id accid = newacc.Id;

                    newWorker.AccountId = accid;
                }


                newWorker.enrtcr__Gender_Detail__c = onboarder.Gender__c;
                newWorker.enrtcr__Client_Region__c = onboarder.State__c;
                newWorker.enrtcr__Start_Date__c = onboarder.Start_Date__c;
                newWorker.enrtcr__Status__c = 'Current';
                newWorker.enrtcr__Mobile__c = onboarder.Phone_Number__c;
                newWorker.MobilePhone = onboarder.Phone_Number__c;
                newWorker.Email = onboarder.Email__c;
                newWorker.FTE__c = onboarder.FTE__c;

                newContacts.add(newWorker);
        	}
        }
        assignPermissionSets(psas);
        insert newContacts;
        System.debug('inserting');
        if (Supervision == 1) {
            List<enrtcr__Support_Contract_Item__c> toInsertSAI = new List<enrtcr__Support_Contract_Item__c>();
            List<enrtcr__Support_Contract__c> toInsertSA = new List<enrtcr__Support_Contract__c>();
            for (Contact supervisionClient : newContacts) {
                System.debug(supervisionClient);
                enrtcr__Support_Contract__c SA = new enrtcr__Support_Contract__c();
                SA.enrtcr__Client__c = supervisionClient.Id;
                SA.enrtcr__Funding_Type__c = 'NDIS';
                SA.enrtcr__Rate_Type__c = 'NDIS';
                SA.enrtcr__Start_Date__c = System.today() - 3;
                SA.enrtcr__End_Date__c = System.today() + 1822;
                SA.enrtcr__Total_Allocation__c = 1;
                SA.enrtcr__Service_Agreement_Overclaim__c = 'Prevent';
                SA.enrtcr__Funding_Management__c = 'Participant';
                SA.enrtcr__Status__c = 'Current';
                SA.enrtcr__Client_Approved_Date__c = System.today();
                SA.enrtcr__Status__c = 'Current';
                toInsertSA.add(SA);
                System.debug(SA);
            }
            insert toInsertSA;
            for (enrtcr__Support_Contract__c p : toInsertSA) {
                System.debug(p);
                enrtcr__Support_Contract_Item__c SAI = new enrtcr__Support_Contract_Item__c();
                SAI.RecordTypeId = '0122v0000013ObaAAE';
                SAI.enrtcr__Support_Contract__c = p.Id;
                SAI.enrtcr__Support_Category__c = this.IDLS.Id;
                SAI.enrtcr__Support_Category_Amount__c = p.enrtcr__Total_Allocation__c;
                SAI.enrtcr__Support_Category_Allocated__c = p.enrtcr__Total_Allocation__c;
                SAI.enrtcr__Support_Category_Unallocated__c = 0;
                SAI.enrtcr__Restrict_delivery_to_Service_Line_Item__c = false;
                SAI.enrtcr__Support_Category_Delivered__c = 0;
                SAI.enrtcr__Delivered__c = 0;
                SAI.enrtcr__Support_Category_Overclaim__c = 'Allow';
                System.debug(SAI);
                toInsertSAI.add(SAI);
            }
            System.debug('before');
            insert toInsertSAI;
            System.debug('after');
        }
    }

    private void assignPermissionSets(Map<Id, String> psas) {
        FutureListPSA.insertPSAs(psas);
    }*/
}