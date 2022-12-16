public with sharing class OnboardingContactController {
    //This class is run through the "Create Contact" button on Onboarding object
    //It creates the contact profile, contact supervision profile, service agreements, and assign the correct KPI based on the onboarder's attributes

    // Constructor - this is only required/used if the autoRun function does not work
	private onboarding__c onboarder;
    public Date startKPIDates;
    public Date endKPIDates;
    public String message {get; set;}

    public static KPI__c KPI_SETTINGS {
        get {
            if (KPI_SETTINGS == null) {
                KPI_SETTINGS = KPI__c.getOrgDefaults();
            }
            return KPI_SETTINGS;
        }
        set;
    }

    public String getNoIssue(){
        return 'Issue cannot be detected. Please contact your Salesforce Developer.';
    }

    public OnboardingContactController(ApexPages.StandardController stdController) {
        this.onboarder = (onboarding__c)stdController.getRecord();
    }

    //VF Page will invoke this method
    public PageReference autoRun() {
        String theId = ApexPages.currentPage().getParameters().get('id');

        if (theId == null) {
            //no id was given from button to VF page to this controller - display VF page content
            message = 'No onboarding record is detected. Please open an onboarding record and try again.';
            return null;
        }

        this.onboarder = [SELECT id, Name, Birth_date__c, Internal_Banding__c, Work_Day_s__c, Start_Date__c, Contact_Apex_Run__c, User_Apex_Run__c, Email__c, First_Name__c, Last_Name__c, Phone_Number__c, State__c, Department__c, Office__c,
                          Clinical_Supervisor__c, Gender__c, isTeamLeader__c, Principal_Clinician__c, Direct_Supervisor__c, Site__c, Site__r.Business_Country__c, Site__r.enrtcr__Organisation_Name__c, Contract_Type__c, FTE__c FROM onboarding__c WHERE id =: theId LIMIT 1];

        if (this.onboarder.Contact_Apex_Run__c == true) {
            System.debug('The contact Apex Run checkbox is marked as true. It looks like Apex contact creation code has been run on this new starter already');
            message = 'It looks like this action has been run on this new starter. If you believe this is wrong, please double check that their Worker profile has not been created. After that, untick the Contact Apex Run tickbox and try again.';
            return null;
        }

        if (this.onboarder.User_Apex_Run__c == false) {
            System.debug('It looks like the user has not been created for this new starter yet. Please "Create User" then click the Create Contact Button');
            message = 'You need to create the User profile first. Please click the "Create User" button then click the "Create Contact" Button';
            return null;
        }

        String onboarderEmail = this.onboarder.Email__c;

        if(this.onboarder.Internal_Banding__c != 'Student'){
            Contact workerProfile = createContact(onboarderEmail, 0);
            Contact supervisionProfile = createContact(onboarderEmail, 1);

            // link worker and supervision profiles together - student
            addSupervision(workerProfile.id);
            addSupervision(supervisionProfile.id);

            // recalibrate KPI's of worker, DS and CS
            recalibrateKPI(workerProfile.Id, this.onboarder.Start_Date__c);
            if (workerProfile.Direct_Supervisor__c != null) recalibrateKPI(workerProfile.Direct_Supervisor__c, this.onboarder.Start_Date__c);
            if (workerProfile.Clinical_Supervisor__c != null) recalibrateKPI(workerProfile.Clinical_Supervisor__c, this.onboarder.Start_Date__c);

            // create Supervision SA
            enrtcr__Support_Contract__c supervisionSA = supervisionSAHandler(supervisionProfile.Id, workerProfile);

            //create ramp up SA
            enrtcr__Support_Contract__c rampUpSA = rampUpSAHandler(supervisionProfile.Id, workerProfile);

            //create and insert the client clinicians
            insertClientClinicians(workerProfile, supervisionProfile, supervisionSA, rampUpSA);

            System.debug('Supervision fields for worker profile: ' + workerProfile.Supervision__c);
            System.debug('Supervision fields for supervision profile: ' + supervisionProfile.Supervision__c);

        } else if(this.onboarder.Internal_Banding__c == 'Student'){
            Contact workerProfile = createContact(onboarderEmail, 0);
        }

        PageReference pageRef = new PageReference('/' + theId);
        pageRef.setRedirect(true);

        try {
        	update onboarder;
            onboarder.Contact_Apex_Run__c = true;
        } catch (Exception e) {
            System.debug('Exception = ' + e.getMessage());
            return null;
        }

        return pageRef;
    }

    private void insertClientClinicians(Contact workerProfile, Contact supervisionProfile, enrtcr__Support_Contract__c supervisionSA, enrtcr__Support_Contract__c rampUpSA){
        List<enrtcr__Staff_Allocation__c> ccToInsert = new List<enrtcr__Staff_Allocation__c>();

        //create client clinician for supervision sa
        if (workerProfile.Direct_Supervisor__c != null) ccToInsert.add(createClientClinician(supervisionProfile.Id, workerProfile.Direct_Supervisor__c, supervisionSA.Id, 'Direct Supervisor'));
        if (workerProfile.Clinical_Supervisor__c != null) ccToInsert.add(createClientClinician(supervisionProfile.Id, workerProfile.Clinical_Supervisor__c, supervisionSA.Id, 'Site Supervisor'));
        if (workerProfile.Principal_Clinician__c != null) ccToInsert.add(createClientClinician(supervisionProfile.Id, workerProfile.Principal_Clinician__c, supervisionSA.Id, 'Principal Clinician'));

        //create CC for ramp up sa
        ccToInsert.add(createClientClinician(supervisionProfile.Id, workerProfile.Id, rampUpSA.Id, 'Ramp Up'));

        //create cc for better rehab leave sa
        Contact betterRehabClient = BR_ContactDAO.getContactByFirstNameLastName('Better', 'Rehab')[0];
        enrtcr__Support_Contract__c betterRehabSA = BR_ServiceAgreementDAO.getActiveServiceAgreementByName('SA-00004530')[0];
        ccToInsert.add(createClientClinician(betterRehabClient.Id, workerProfile.Id, betterRehabSA.Id, 'Leave'));

        insert ccToInsert;
    }

    private enrtcr__Staff_Allocation__c createClientClinician(Id client, Id workerProfile, Id serviceAgreement, String clientClinicianName) {
        List<enrtcr__Staff_Allocation__c> toInsert = new List<enrtcr__Staff_Allocation__c>();
        enrtcr__Staff_Allocation__c clientClinician = new enrtcr__Staff_Allocation__c();

        if (serviceAgreement != null) {
            clientClinician.Client__c = client;
            clientClinician.Clinician_Status__c = 'Active';
            clientClinician.Service_Agreement__c = serviceAgreement;
            clientClinician.Name = clientClinicianName;
            clientClinician.Clinician__c = workerProfile;
            System.debug('clientClinician created: ' + clientClinician);
        }

        return clientClinician;
    }


    private Contact createContact(String OEmail, Integer Supervision) {
        User Employee = [SELECT id, Email, Profile.Name FROM User WHERE Email =: OEmail];
        User u = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        Contact newWorker;

        if (Employee.id != null) {
            newWorker = new Contact();

            if (this.onboarder.Site__c != null) {
                newWorker.enrtcr__Site__c = this.onboarder.Site__c;
            }
            if (Supervision == 0) {
                assignPermissionSets(Employee.id, Employee.Profile.Name);
                newWorker.FirstName = this.onboarder.First_Name__c;
                newWorker.LastName = this.onboarder.Last_Name__c;
                //worker record ID
                newWorker.RecordTypeId = '0122v0000013OcoAAE';
                //Better Rehab or Better Days account ID
                newWorker.AccountId = this.onboarder.Site__r.enrtcr__Organisation_Name__c;
                newWorker.Caseload_Preference__c = 'Mixed Cohort (All ages)';
                newWorker.enrtcr__User__c = Employee.Id;
                newWorker.Working_Type__c = this.onboarder.Contract_Type__c;
                newWorker.Internal_Banding__c = this.onboarder.Internal_Banding__c;
                newWorker.Birthdate = this.onboarder.Birth_date__c;
                newWorker.New_Framework__c = TRUE;
                newWorker.Next_Audit__c = this.onboarder.Start_Date__c;
				newWorker.Legal_Name__c = this.onboarder.Name;
				newWorker.Preferred_Name__c = this.onboarder.First_Name__c + ' ' + this.onboarder.Last_Name__c;                
                
                if(this.onboarder.Principal_Clinician__c != null){
                    newWorker.Principal_Clinician__c = this.onboarder.Principal_Clinician__c;
                }
                if (this.onboarder.Work_Day_s__c != null) {
                	newWorker.Work_day__c = this.onboarder.Work_Day_s__c;
                }
                if (this.onboarder.Direct_Supervisor__c != null) {
                    newWorker.Direct_Supervisor__c = this.onboarder.Direct_Supervisor__c;
                }
                if (this.onboarder.Clinical_Supervisor__c != null) {
                    newWorker.Clinical_Supervisor__c = this.onboarder.Clinical_Supervisor__c;
                }
                if (this.onboarder.Department__c != 'Management') {
                    newWorker.Clinician_Discipline__c = this.onboarder.Department__c;
                }

                newWorker.QA_reporting__c = populateQAReporting(newWorker.Clinician_Discipline__c);
                
                newWorker.Better_Rewards_PD_Balance__c = 0;
                
                if(this.onboarder.Site__r.Business_Country__c == 'Australia' && this.onboarder.Internal_Banding__c != 'Student'){
                    newWorker.Annual_PD_Balance__c = 400;
                } else {
                    newWorker.Annual_PD_Balance__c = 0;
                }
                
            } else if (Supervision == 1) {
                newWorker.FirstName = this.onboarder.First_Name__c + ' ' + this.onboarder.Last_Name__c;
                newWorker.LastName = 'SUPERVISION';
                //client record ID
                newWorker.RecordTypeId = '0122v0000013ObcAAE';
                newWorker.Method__c = 'Face to Face';
                newWorker.Client_Division__c = 'Private';
                newWorker.Site_Allocation__c = this.onboarder.Office__c;
                newWorker.MMM_Score__c = '0';
                newWorker.Funding_Confirmed__c = 'Yes';
                newWorker.enrtcr__Indigenous_Status__c = '5 - Unknown/Did Not Share';

                Account newacc = new Account();
                newacc.OwnerId = u.Id;
                newacc.Name = this.onboarder.Last_Name__c + ' SUPERVISION Household';
                insert newacc;
                Id accid = newacc.Id;

                newWorker.AccountId = accid;
            }

            newWorker.enrtcr__Sex__c = this.onboarder.Gender__c;
            newWorker.enrtcr__Gender_Detail__c = this.onboarder.Gender__c;
            newWorker.enrtcr__Client_Region__c = this.onboarder.State__c;
            newWorker.enrtcr__Start_Date__c = this.onboarder.Start_Date__c;
            newWorker.enrtcr__Status__c = 'Current';
            newWorker.MobilePhone = this.onboarder.Phone_Number__c;
            newWorker.enrtcr__Mobile__c = this.onboarder.Phone_Number__c;
            newWorker.Email = this.onboarder.Email__c;
            newWorker.FTE__c = this.onboarder.FTE__c;

            insert newWorker;

        }

        return newWorker;
    }

    // Populate value to be assign to QA_reporting__c field depending on worker's discipline
    @TestVisible
    private static String populateQAReporting(String discipline) {
        switch on discipline {
            when 'Occupational Therapy' {
                QA_Reporting_Setting__mdt mdt = QA_Reporting_Setting__mdt.getInstance('Occupational_Therapy');

                return mdt.QA_Reporting__c;
            } when 'PBS' {
                QA_Reporting_Setting__mdt mdt = QA_Reporting_Setting__mdt.getInstance('PBS');

                return mdt.QA_Reporting__c;
            } when 'Speech Pathology' {
                QA_Reporting_Setting__mdt mdt = QA_Reporting_Setting__mdt.getInstance('Speech_Pathology');

                return mdt.QA_Reporting__c;
            } when 'Physiotherapy' {
                QA_Reporting_Setting__mdt mdt = QA_Reporting_Setting__mdt.getInstance('Physiotherapy');

                return mdt.QA_Reporting__c;
            } when 'Exercise Physiology' {
                QA_Reporting_Setting__mdt mdt = QA_Reporting_Setting__mdt.getInstance('Exercise_Physiology');

                return mdt.QA_Reporting__c;
            } when else {
                return '';
            }
        }
    }

    private void assignPermissionSets(Id UserId, String profileName) {
        FuturePSA.insertPSAs(UserId, profileName, this.onboarder.Department__c, this.onboarder.isTeamLeader__c, this.onboarder.Internal_Banding__c);
        FuturePSA.assignGroup(UserId, this.onboarder.Department__c, this.onboarder.State__c, this.onboarder.Internal_Banding__c);
    }

	//method to add connection between worker and their supervision profile
   	@future
    private static void addSupervision(Id ContactId){
        Contact relatedContact = [SELECT id, FirstName, LastName, Supervision__c FROM Contact WHERE id =: ContactId];

        if(relatedContact.LastName == 'SUPERVISION'){
            //Find the normal contact's profile
            String[] name = relatedContact.FirstName.split(' ');
            String fName, lName;

            //if they have a middle name
            if(name.size() == 3) {
                fName = name[0] + ' ' + name[1];
           		lName = name[2];
            } else if(name.size() == 2) {
                fName = name[0];
           		lName = name[1];
            }

            //assuming that if someone has a middle name, their first and mid name will be tgt in the FirstName field
            Contact workerProfile = [SELECT id, FirstName, LastName FROM Contact WHERE FirstName =: fName AND LastName =: lName];
            relatedContact.Supervision__c = workerProfile.Id;
            System.debug('Supervision in worker profile: ' + relatedContact.Supervision__c);
        }

        if(relatedContact.LastName != 'SUPERVISION'){
            //it's a normal user
            //find the supervision profile and add it to its supervision fields
            Contact supervisionProfile = [SELECT id, FirstName, LastName FROM Contact WHERE FirstName =: relatedContact.FirstName + ' ' + relatedContact.LastName];
            relatedContact.Supervision__c = supervisionProfile.Id;
            System.debug('Supervision in supervision profile: ' + relatedContact.Supervision__c);
        }

        update relatedContact;
    }

    @future
    private static void recalibrateKPI(Id clinician, Date workerStartDate) {
        //find the KPI setting first
        KPI__c kpiDates = KPI__c.getInstance();
        Date startKPIDates = kpiDates.Date_Start__c;
        Date endKPIDates = kpiDates.Date_End__c;

        if(workerStartDate >= startKPIDates && workerStartDate <= endKPIDates){
            System.debug('This new worker starts within the current KPI dates');
            br_kpiRecalibration KPIClassInstance = new br_kpiRecalibration(clinician);
            if (KPIClassInstance.classContructionValid == true) {
                String result = KPIClassInstance.performChecks(clinician);

                Action_Log__c audit = new Action_Log__c();
                audit.Action__c = 'KPI Recalibration Single';
                if (result == 'Success') {
                    audit.Status__c = 'Success';
                    audit.Response__c = Utility.maptoJSON(KPIClassInstance.auditMap);
                } else {
                    audit.Status__c = 'Error';
                    audit.Response__c = result;
                }
                insert audit;
            }
        } else {
            System.debug('This new worker DOES NOT start within the current KPI dates');
        }
    }

    //need to change the start and end date to based on which KPI period they start at
    private enrtcr__Support_Contract__c supervisionSAHandler(Id supervisionProfile, Contact workerProfile) {
        Double JointVisit = calculateSupSAIAmount(workerProfile, 'Joint Visit');
        Double oneOnOne = calculateSupSAIAmount(workerProfile, '1:1');
        Double QA = calculateSupSAIAmount(workerProfile, 'QA Support') * workerProfile.FTE__c;
        Double ClinAudit = calculateSupSAIAmount(workerProfile, 'Clinical Audit') * workerProfile.FTE__c;

        System.debug('What are the sup sai amount? ' + JointVisit  + ' + ' + oneOnOne + ' + ' + ClinAudit + ' + ' + QA);

        Double totalSAAllocation = JointVisit + oneOnOne + ClinAudit + QA;

        enrtcr__Support_Contract__c SA = new enrtcr__Support_Contract__c();

        SA.enrtcr__Client__c = supervisionProfile;
        SA.enrtcr__Funding_Type__c = 'NDIS';
        SA.enrtcr__Rate_Type__c = 'NDIS';
        SA.enrtcr__Start_Date__c = KPI_SETTINGS.Date_Start__c;
        SA.enrtcr__End_Date__c = KPI_SETTINGS.Date_End__c;
        SA.enrtcr__Total_Allocation__c = totalSAAllocation;
        SA.enrtcr__Service_Agreement_Overclaim__c = 'Prevent';
		SA.enrtcr__Funding_Management__c = 'Participant';
        SA.enrtcr__Status__c = 'Current';
        SA.enrtcr__Client_Approved_Date__c = System.today() - 1;
        SA.Name = 'Supervision SA';

        insert SA;

        enrtcr__Support_Contract_Item__c jvItem = createSAI('Joint Visit', JointVisit, SA);
        enrtcr__Support_Contract_Item__c oneOnOneItem = createSAI('1:1', oneOnOne, SA);
        enrtcr__Support_Contract_Item__c caItem = createSAI('Clinical Audit', ClinAudit, SA);
        enrtcr__Support_Contract_Item__c QAItem = createSAI('QA Support', QA, SA);

        System.debug('What are the support contract items? ' + jvItem  + ' + ' + oneOnOneItem + ' + ' + caItem  + ' + ' + QAItem);

        List<enrtcr__Support_Contract_Item__c> supportItems = new List<enrtcr__Support_Contract_Item__c>{jvItem, caItem, QAItem, oneOnOneItem};
        insert supportItems;

        return SA;
    }

    private enrtcr__Support_Contract__c rampUpSAHandler(Id supervisionProfile, Contact workerProfile) {

        Date start_date = workerProfile.enrtcr__Start_Date__c;
        Date end_date;

        if(workerProfile.Internal_Banding__c == 'Graduate Clinician'){
            end_date = start_date + 63;
        } else if(workerProfile.Internal_Banding__c == 'Early Practicing Clinician'){
            end_date = start_date + 56;
        } else if(workerProfile.Internal_Banding__c == 'Practicing Clinician'){
            end_date = start_date + 49;
        } else if(workerProfile.Internal_Banding__c == 'Senior Clinician'){
            end_date = start_date + 35;
        } else {
            end_date = start_date + 1;
        }

        Double RampUp = calculateRampUpAmount(workerProfile);

        Double totalSAAllocation = RampUp;

        enrtcr__Support_Contract__c SA = new enrtcr__Support_Contract__c();

        SA.enrtcr__Client__c = supervisionProfile;
        SA.enrtcr__Funding_Type__c = 'NDIS';
        SA.enrtcr__Rate_Type__c = 'NDIS';
        SA.enrtcr__Start_Date__c = start_date; //new starter's start date
        SA.enrtcr__End_Date__c = end_date; //depends on their internal banding
        SA.enrtcr__Total_Allocation__c = totalSAAllocation;
        SA.enrtcr__Service_Agreement_Overclaim__c = 'Prevent';
		SA.enrtcr__Funding_Management__c = 'Participant';
        SA.enrtcr__Status__c = 'Current';
        SA.enrtcr__Client_Approved_Date__c = System.today() - 1;
        SA.Name = 'Ramp Up SA';

        insert SA;

        enrtcr__Support_Contract_Item__c RampUpItem = createSAI('Ramp Up', RampUp, SA);

        List<enrtcr__Support_Contract_Item__c> supportItems = new List<enrtcr__Support_Contract_Item__c>{RampUpItem};
        insert supportItems;

        return SA;
    }

    private enrtcr__Support_Contract_Item__c createSAI(String supportCategory , Double allocation, enrtcr__Support_Contract__c SA) {
        enrtcr__Reference_Data__c[] SC = [SELECT id FROM enrtcr__Reference_Data__c WHERE Name =: supportCategory];
        if (SC.size() == 0)  {
            return null;
        }
        enrtcr__Support_Contract_Item__c SAI = new enrtcr__Support_Contract_Item__c();
        SAI.RecordTypeId = '0122v0000013ObaAAE';
        SAI.enrtcr__Support_Category_Amount__c = allocation;
        SAI.enrtcr__Support_Category__c = SC[0].id;
        SAI.enrtcr__Support_Contract__c = SA.id;
        SAI.enrtcr__Item_Overclaim__c = 'Prevent';

        return SAI;
    }

    private Double calculateSupSAIAmount(Contact worker, String LineItem) {
        List<String> allowedCD = new List<String>{'Occupational Therapy', 'Speech Pathology', 'Physiotherapy', 'PBS', 'Exercise Physiology', 'Allied Health Assistant'};
        List<String> allowedCSIB = new List<String>{'Graduate Clinician', 'Early Practicing Clinician', 'Practicing Clinician', 'Senior Clinician', 'AHA Early Service', 'AHA Full Service', 'AHA Community', 'AHA Senior Service'};
        List<String> allowedOSIB = new List<String>{'Graduate Clinician', 'Early Practicing Clinician', 'Practicing Clinician', 'Senior Clinician'};
         switch on (LineItem) {
             when 'QA Support' {
                 // do calculation
                 switch on (worker.Clinician_Discipline__c) {
                     when 'Speech Pathology' {return 4;}
                     when 'Physiotherapy' {return 4;}
                     when 'Exercise Physiology' {return 4;}
                     when 'Occupational Therapy' {return 6;}
                     when 'PBS' {return 6;}
                 }
             }
             when '1:1' {
                 // CD check
                 if (!allowedCD.contains(worker.Clinician_Discipline__c)) {
                     return 0;
                 }
                 // IB check
                 if (!allowedCSIB.contains(worker.Internal_Banding__c)) {
                     return 0;
                 }

                 switch on (worker.Internal_Banding__c) {
                     when 'Graduate Clinician' {return 2;}
                     when 'Early Practicing Clinician' {return 2;}
                     when 'Practicing Clinician' {return 1;}
                     when 'Senior Clinician' {return 1;}
                     when 'AHA Early Service' {return 1;}
                     when 'AHA Full Service' {return 1;}
                     when 'AHA Community' {return 1;}
                     when 'AHA Senior Service' {return 1;}
                     when else {
                         return 0;
                     }
                 }
             }
             when 'Joint Visit' {

                 switch on (worker.Internal_Banding__c) {
                     when 'Graduate Clinician' {return 4;}
                     when 'Early Practicing Clinician' {return 2;}
                     when 'Practicing Clinician' {return 2;}
                     when 'Senior Clinician' {return 2;}
                     when else {
                         return 0;
                     }
                 }

             }
             when 'Clinical Audit' {
                    // IB check
                    if (!allowedOSIB.contains(worker.Internal_Banding__c)) {
                        return 0;
                    } else {
                        return 1;
                    }
                }
             when else {
                 return 0;
             }
         }
        return 0;
    }

    private Double calculateRampUpAmount(Contact worker) {
        Double totalRampUp;
        Double fte = worker.FTE__c;

        List<String> allowedCD = new List<String>{'Occupational Therapy', 'Speech Pathology', 'Physiotherapy', 'PBS', 'Exercise Physiology'};
        List<String> allowedCSIB = new List<String>{'Graduate Clinician', 'Early Practicing Clinician', 'Practicing Clinician', 'Senior Clinician'};
        List<String> allowedOSIB = new List<String>{'Graduate Clinician', 'Early Practicing Clinician', 'Practicing Clinician', 'Senior Clinician', 'AHA Early Service', 'AHA Full Service', 'AHA Community', 'AHA Senior Service'};
            switch on (worker.Internal_Banding__c) {
                when 'Graduate Clinician' {totalRampUp = 120 * fte;}
                when 'Early Practicing Clinician' {totalRampUp = 102 * fte;}
                when 'Practicing Clinician' {totalRampUp = 82 * fte;}
                when 'Senior Clinician' {totalRampUp = 65 * fte;}
                when else {
                    totalRampUp = 0;
                }
            }

        return totalRampUp;
    }
}