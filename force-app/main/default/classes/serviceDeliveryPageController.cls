//Author - Nad
//Date - 23/11/2020
//Contact - 0432 256 298
//Version 1.1.1
public with sharing class serviceDeliveryPageController {
    //user input
    public Id selectedWorker {get;set;}
    public Id selectedClient {get;set;}
    public Id selectedSAI {get;set;}

    //auto-populated
    public Id selectedSite {get;set;}
    public Id selectedSA {get;set;}
    public Id selectedSupport {get;set;}

    //indication of new/old framework
    public Boolean workerNewFramework;
    public Boolean workerEligibleForQA;
    public Boolean workerEligibleForCA;
    public Map<Id, Boolean> clientNewFrameworkMap = new Map<Id, Boolean>();

    //list options
    public List<SelectOption> workers {get;set;}
    public List<SelectOption> clients {get;set;}
    public List<SelectOption> SAIs {get;set;}
    public List<SelectOption> services {get;set;}

    //service delivery objects
    public SDEPackage sde1 {get;set;}
    public SDEPackage sde2 {get;set;}
    public SDEPackage sde3 {get;set;}
    public SDEPackage sde4 {get;set;}
    public SDEPackage sde5 {get;set;}
    public SDEPackage sde6 {get;set;}
    public SDEPackage overclaim {get;set;}

    //FINAL FIELDS ONCE SAVED
    public Contact worker {get;set;}
    public Contact client {get;set;}
    public enrtcr__Reference_Data__c SC {get;set;}
    public enrtcr__Site__c site {get;set;}
    public enrtcr__Support_Contract_Item__c   serviceAgreementItem {get;set;}
    public enrtcr__Service__c s1 {get;set;}
    public enrtcr__Rate__c r1 {get;set;}
    public enrtcr__Service__c s2 {get;set;}
    public enrtcr__Rate__c r2 {get;set;}
    public enrtcr__Service__c s3 {get;set;}
    public enrtcr__Rate__c r3 {get;set;}
    public enrtcr__Service__c s4 {get;set;}
    public enrtcr__Rate__c r4 {get;set;}
    public enrtcr__Service__c s5 {get;set;}
    public enrtcr__Rate__c r5 {get;set;}
    public enrtcr__Service__c s6 {get;set;}
    public enrtcr__Rate__c r6 {get;set;}
    public enrtcr__Service__c s7 {get;set;}
    public enrtcr__Rate__c r7 {get;set;}

    public enrtcr__Rate__c overclaimRate {get;set;}
    public enrtcr__Site_Service__c OCSSP {get;set;}
    public String overclaimStatus {get;set;}

    public boolean submitDisabled {get ; set;}
    public DateTime start {get ; set;}
    public boolean displayPopUp {get;set;}

    private Map<Id,Id> cIdSAId;
    private Map<Id,Id> SAIIdSCId;
    Map<Id, Contact> clientInfo = new Map<Id, Contact>();
    Map<String,String> scShorten;

    public Double totalAmount {get;set;}
    public Double remainingBalance {get;set;}
    public List<String> errors {get;set;}
    public List<String> messages {get;set;}
    public boolean submissionError {get;set;}
    public String department {get;set;}
    public String clientDivision {get;set;}
    public String additional {get;set;}
    public Integer ocAmountDisplay {get;set;}
    public Double KPIFactor {get;set;}

    //----------------------------------------------------------- CONTROLLER FUNCTION && VF PAGE ACTIONS ------------------------------------------------------------//
    public serviceDeliveryPageController() {
        toggleDisabled(1);
        this.submissionError = false;
        this.displayPopUp = false;
        instantiateSDEs();
        getWorkers();
        setGlobal();
        //Get the time the user loaded the page
        TimeZone tz = UserInfo.getTimeZone();
        DateTime dt = DateTime.now();
        this.start = dt.addSeconds((tz.getOffset(dt)/1000));
        //if auto-worker works do the following
        if (selectedWorker != null) {setSite();getClients();}
    }

    public void workerListAction() {
        toggleDisabled(1);
        //main
        setSite();
        getClients();

        //reset lists
        this.services = null;
        this.selectedClient = null;
        resetServiceRates(3);
        this.selectedSAI = null;
        this.selectedSupport = null;
        this.SAIs = null;
    }

    public void clientListAction() {
        toggleDisabled(1);
        //first set any previous SA and SAI selections to null.
        this.selectedSA = null;
        this.selectedSAI = null;
        //set the service lists to null as SC has changed. Also set rate Lists and previous service selections to null
        resetServiceRates(3);
        this.services = null;
        this.selectedSupport = null;
        //grab the new SA and list all the SAIs for that SA
        setSA();
        getSAIs();
        setClientDivision();
    }

    public void SAIListAction() {
        toggleDisabled(1);
        resetServiceRates(3);
        setSC();
        getServices();

    }

    public void serviceListAction1() {
        toggleDisabled(1);
        //sde1.getRates();
    }

    public void serviceListAction2() {
        toggleDisabled(1);
        //sde2.getRates();
    }

    public void serviceListAction3() {
        toggleDisabled(1);
        //sde3.getRates();
    }

    public void serviceListAction4() {
        toggleDisabled(1);
        //sde4.getRates();
    }

    public void serviceListAction5() {
        toggleDisabled(1);
        //sde5.getRates();
    }

    public void serviceListAction6() {
        toggleDisabled(1);
        //sde6.getRates();
    }

    //----------------------------------------------------------- USER-FACING ACTION FUNCTIONS ------------------------------------------------------------//

    //run this function at the start of page load.
    public void getWorkers() {
        workers = new List<SelectOption>();

        List<Contact> contactWorkers = [SELECT Id, Name, enrtcr__User__r.Id, Clinician_Discipline__c, Additional_Disciplines__c FROM Contact
                                        WHERE RecordTypeId = '0122v0000013OcoAAE' AND
                                        (enrtcr__Status__c IN ('Current','Extended Leave'))
                                        ORDER BY Name];
        contactWorkers.sort();
        for (Contact c : contactWorkers) {
            if (c.enrtcr__User__r.Id == UserInfo.getUserId()) {
                selectedWorker = c.Id;
                department = c.Clinician_Discipline__c;
                additional = c.Additional_Disciplines__c;
            }
            workers.add(new SelectOption(c.Id, c.Name));
        }
    }

    //run this function everytime selectedWorker changes.
    public void getClients() {
        if (selectedWorker != null) {
            clients = new List<SelectOption>();
            cIdSAId = new Map<Id,Id>();
            List<enrtcr__Staff_Allocation__c> contactClients = [SELECT   Id,
                                                                Client__r.Id,
                                                                Client__r.Name,
                                                                Service_Agreement__r.Id,Clinician__r.Clinician_Discipline__c,
                                                                Client__r.Client_Division__c,
                                                                Client__r.enrtcr__Client_Region__c,
                                                                Client__r.is_New_Framework__c
                                                                FROM enrtcr__Staff_Allocation__c
                                                                WHERE Clinician__r.Id =: selectedWorker
                                                                AND Clinician_Status__c = 'Active'
                                                                AND  Client_Status__c = 'Current'
                                                               ];

            contactClients.sort();
            if (contactClients.size() > 0) {
                department = contactClients[0].Clinician__r.Clinician_Discipline__c;
                // clientDivision = contactClients[0].Client__r.Client_Division__c;
            }
            for (enrtcr__Staff_Allocation__c cc : contactClients) {
                cIdSAId.put(cc.Client__r.Id, cc.Service_Agreement__r.Id);
                clients.add(new SelectOption(cc.Client__r.Id, cc.Client__r.Name ));
                clientInfo.put(cc.Client__r.Id, cc.Client__r);
                clientNewFrameworkMap.put(cc.Client__r.Id, cc.Client__r.is_New_Framework__c);
            }
        }
    }

    public void getSAIs() {
        System.debug('Inside getSAIs');
        System.debug('who is the selected client: ' + selectedClient);
        System.debug('selectedSA: ' + selectedSA);
        System.debug('workerNewFramework: ' + workerNewFramework);
        System.debug('clientnewframework: ' + clientNewFrameworkMap.get(selectedClient));
        System.debug('QA: ' + workerEligibleForQA);
        System.debug('CA: ' + workerEligibleForCA);

       	List<String> scNamesToExclude = new List<String>();

        if (selectedClient != null && selectedSA != null) {
            SAIs = new List<SelectOption>();
            SAIIdSCId = new Map<Id,Id>();
            List<enrtcr__Support_Contract_Item__c> pulledSAIs = [SELECT Id,
                                                                 Name,
                                                                 enrtcr__Support_Contract__r.Id,
                                                                 enrtcr__Support_Contract__r.Name,
                                                                 enrtcr__Support_Contract__r.enrtcr__Status__c,
                                                                 enrtcr__Support_Contract__r.enrtcr__Rate_Type_Display__c,
                                                                 enrtcr__Support_Category__r.Id,
                                                                 enrtcr__Support_Category__r.Name,
                                                                 enrtcr__Support_Category_Remaining__c
                                                                 FROM enrtcr__Support_Contract_Item__c
                                                                 WHERE enrtcr__Support_Contract__r.Id =: selectedSA
                                                                 AND enrtcr__Support_Category__c != null
                                                                ];

            //conditionally display line items
            if (pulledSAIs.size() > 0) {
                pulledSAIs.sort();
                //client is in a new framework
                if(clientNewFrameworkMap.get(selectedClient)){
                    scNamesToExclude.add('Operational Supervision');
                }

                if(!workerEligibleForQA){
                    scNamesToExclude.add('QA Support');
                }

                if(!workerEligibleForCA){
                    scNamesToExclude.add('Clinical Audit');
                }

                System.debug('List of support categories to exclude for this worker: ' + scNamesToExclude);

                for (enrtcr__Support_Contract_Item__c SAI : pulledSAIs) {
                    if(!scNamesToExclude.contains(SAI.enrtcr__Support_Category__r.Name)){
                        SAIIdSCId.put(SAI.id,SAI.enrtcr__Support_Category__r.Id);
                        SAIs.add(new SelectOption(SAI.Id,'['+SAI.enrtcr__Support_Contract__r.enrtcr__Status__c+']'+ '[$'+SAI.enrtcr__Support_Category_Remaining__c+']'+ SAI.enrtcr__Support_Contract__r.Name + ' - ' + scShorten.get(SAI.enrtcr__Support_Category__r.Name) + ' - ' + SAI.enrtcr__Support_Contract__r.enrtcr__Rate_Type_Display__c ));
                    }
                }

            }
        } else {
            this.SAIs = null;
        }
    }

    //run this everytime selectedSupport and selectedSite changes
    public void getServices() {
        if (selectedSite != null && selectedSupport != null) {
            List<String> departments = new List<String>();
            if (additional != null) {
                departments = additional.split(';');
            }
            departments.add('Various');
            departments.add(department);

            List<String> divisions = new List<String>();
            divisions.add('Internal');
            divisions.add(clientDivision);

            List<String> recordtypes = new List<String>();
            recordtypes.add('0122v0000013OeEAAU');
            recordtypes.add('0122v000001OP6ZAAW');
            recordtypes.add('0122v0000013OeBAAU');
            services = new List<SelectOption>();
            //Date todays = System.today().format('dd/mm/yyyy');

            /*List<enrtcr__Site_Service__c> pulledServices = [SELECT Id, enrtcr__Service__r.Id, enrtcr__Service__r.Name
                                                            FROM enrtcr__Site_Service__c
                                                            WHERE enrtcr__Operating_Start_Date__c < TODAY
                                                            AND (enrtcr__Operating_End_Date__c > TODAY OR enrtcr__Operating_End_Date__c = null)
                                                            AND enrtcr__Site__r.Id =: selectedSite
                                                            AND enrtcr__Service__r.RecordTypeId IN: recordtypes
                                                            AND enrtcr__Service__r.Better_Rehab__c =: true
                                                            AND enrtcr__Service__r.enrtcr__Support_CategoryId__r.Id =: selectedSupport
                                                            AND enrtcr__Service__r.enrtcr__Status__c = 'Active'
                                                            AND enrtcr__Service__r.Department__c IN: departments
                                                            AND enrtcr__Service__r.Service_Division__c IN: divisions
                                                            AND enrtcr__Service__r.State__c =: clientInfo.get(selectedClient).enrtcr__Client_Region__c
                                                           ];*/


            List<enrtcr__Service__c> pulledServices = [SELECT Id, Name
                                                        FROM enrtcr__Service__c
                                                        WHERE RecordTypeId IN: recordTypes
                                                        AND Better_Rehab__c =: true
                                                        AND enrtcr__Support_CategoryId__r.Id =: selectedSupport
                                                        AND enrtcr__Status__c = 'Active'
                                                        AND Department__c IN: departments
                                                        AND Service_Division__c IN: divisions
                                                        AND State__c INCLUDES(:clientInfo.get(selectedClient).enrtcr__Client_Region__c)
                                                      ];

            System.debug(pulledServices);
            System.debug(clientInfo.get(selectedClient).enrtcr__Client_Region__c);
            System.debug(selectedSupport);
            System.debug(departments);
            System.debug(clientDivision);

            //find all private division service
            List<enrtcr__Service__c> agedCareServices = [SELECT Id, Name
                                                         FROM enrtcr__Service__c
                                                         WHERE RecordTypeId IN: recordTypes
                                                         AND Better_Rehab__c =: true
                                                         AND enrtcr__Support_CategoryId__r.Id =: selectedSupport
                                                         AND enrtcr__Status__c = 'Active'
                                                         AND Department__c IN: departments
                                                         AND Service_Division__c = 'Private'
                                                         AND State__c INCLUDES(:clientInfo.get(selectedClient).enrtcr__Client_Region__c)
                                                        ];

            if (pulledServices.size() > 0) {
                pulledServices.sort();
                for (enrtcr__Service__c service : pulledServices) {
                    services.add(new SelectOption(service.Id, service.Name));
                }

                //add private services to the list options
                if(clientDivision == 'Aged Care'){
                    for (enrtcr__Service__c acServices : agedCareServices) {
                        services.add(new SelectOption(acServices.Id, acServices.Name));
                    }
                }
            } else {
                System.debug('Did not pull any services from Site services');
            }
        }
    }

    //----------------------------------------------------------- SERVER-FACING ACTION FUNCTIONS ------------------------------------------------------------//

    //run this function everytime selectedWorker changes.
    public void setSite() {
        if (selectedWorker != NULL) {
            List<Contact> siteFromContact = [SELECT Id, Name, enrtcr__Site__r.Id, New_Framework__c, enrtcr__Site__r.Business_Country__c FROM Contact WHERE Id =: selectedWorker LIMIT 1];
            if (siteFromContact.size() > 0) {
                selectedSite = siteFromContact[0].enrtcr__Site__r.Id;
            }
            workerNewFramework = siteFromContact[0].New_Framework__c;

            if(siteFromContact[0].enrtcr__Site__r.Business_Country__c == 'New Zealand'){
                workerEligibleForQA = true;
            } else {
                workerEligibleForQA = false;
            }

            //pull the permission set of the worker
            List<PermissionSetAssignment> listOfPSAs = [SELECT Id, PermissionSetId, PermissionSet.Name, PermissionSet.ProfileId, PermissionSet.Profile.Name, AssigneeId, Assignee.Name FROM PermissionSetAssignment
                                                  WHERE Assignee.Name =: siteFromContact[0].Name
                                                  AND (PermissionSet.Name = 'QA_Support' OR PermissionSet.Name = 'Clinical_Audit' OR PermissionSet.Name = 'Clinical_Audit_Admin')];

            if(listOfPSAs.size() > 0){
                workerEligibleForQA = false;
                workerEligibleForCA = false;

                for(PermissionSetAssignment psa : listOfPSAs){
                    if(psa.PermissionSet.Name == 'QA_Support'){
                        workerEligibleForQA = true;
                    }

                    if(psa.PermissionSet.Name == 'Clinical_Audit' || psa.PermissionSet.Name == 'Clinical_Audit_Admin'){
                        workerEligibleForCA = true;
                    }
                }
            } else {
                workerEligibleForQA = false;
                workerEligibleForCA = false;
            }

            System.debug('QA in setSite: ' + workerEligibleForQA);
            System.debug('CA in setSite: ' + workerEligibleForCA);

        }
        if (selectedSupport != null) {
            getServices();
        }

    }

    //run this function everytime selectedClient changes.
    public void setClientDivision() {
        System.debug('Inside setClientDivision');
        if (selectedClient != null) {
            this.clientDivision = clientInfo.get(selectedClient).Client_Division__c;
        }
    }

    //run this function everytime selectedClient changes.
    public void setSA() {
        if (selectedClient != null) {
            for (Id clientId : cIdSAId.keySet()) {
                if (clientId == selectedClient) {
                    this.selectedSA = CIdSAId.get(clientId);
                    getSAIs();
                    break;
                }
            }
        }
    }

    //run this function everytime selectedSAI changes.
    public void setSC() {
        if (selectedSAI != null) {
            for (Id SAIId : SAIIdSCId.keySet()) {
                if (SAIId == selectedSAI) {
                    this.selectedSupport = SAIIdSCId.get(SAIId);
                    break;
                }
            }
        }
    }

    //run this on page load
    public void setGlobal() {
        this.KPIFactor = 0;
        this.scShorten = new Map<String, String>();
        scShorten.put('Assistance with daily life', 'ADL');
        scShorten.put('Assistance with Social, Economic and Community Participation', 'ASECP');
        scShorten.put('Assistive technology', 'Assis. Tech');
        scShorten.put('BR Private Services', 'BR Private');
        scShorten.put('Consumables', 'Consumables');
        scShorten.put('Daily Activities', 'Daily Act.');
        scShorten.put('Finding and keeping a job', 'Finding Job');
        scShorten.put('Home modifications', 'Home Mods');
        scShorten.put('HSTP', 'HSTP');
        scShorten.put('Improved daily living skills', 'I-Daily living Skills');
        scShorten.put('Improved daily living skills - WA Psych', 'IDL - WA Psych');
        scShorten.put('Improved health and wellbeing', 'I-Health/Wellbeing');
        scShorten.put('Improved learning', 'I-Learning');
        scShorten.put('Improved life choices', 'I-Life Choices');
        scShorten.put('Improved living arrangements', 'I-Living Arran.');
        scShorten.put('Improved relationships', 'I-Relationships');
        scShorten.put('Improved relationships (Specialist)', 'I-Relationships Specialist');
        scShorten.put('Improved relationships (Specialist) - WA TAS', 'I-Relationships - WA TAS');
        scShorten.put('Increased social and community participation', 'I-Social/Comm. Part.');
        scShorten.put('NSW Schools Program', 'NSW-SP');
        scShorten.put('Support Coordination', 'Support Coord.');
        scShorten.put('Transport (auto payments)', 'Transport');
        scShorten.put('Supervision', 'Supervision');
        scShorten.put('Operational Supervision', 'Ops Sup');
        scShorten.put('QA Support', 'QA Sup');
        scShorten.put('Clinical Audit', 'Clinical Audit');
        scShorten.put('Team Support', 'Team Sup');
        scShorten.put('Clinical Group Supervision', 'Clin Grp Sup');
        scShorten.put('Leave', 'Leave');
        scShorten.put('Ramp Up', 'Ramp Up');
        scShorten.put('Ad Hoc Support', 'Ad Hoc Support');
        scShorten.put('Quality Improvement Tasks', 'QI Tasks');
        scShorten.put('1:1', '1:1');
        scShorten.put('Joint Visit', 'Joint Visit');
        scShorten.put('Onboarding', 'Onboarding');
        scShorten.put('Offboarding', 'Offboarding');
        scShorten.put('Probation Review', 'Probation Review');
        scShorten.put('Mid Probation Review', 'Mid Probation Review');
        scShorten.put('Performance Review', 'Performance Review');
        scShorten.put('Support Plan', 'Support Plan');
        scShorten.put('Performance Improvement Plan', 'Performance Improvement Plan');
        scShorten.put('Business Development', 'Business Development');
        scShorten.put('RM Specific Task Allocation', 'RM Specific Task');
        scShorten.put('Supervisor Additional Travel', 'Sup Additional Travel');
        scShorten.put('Limited Registration Supervision', 'Limited Registration Supervision');
    }

     //----------------------------------------------------------- HELPER FUNCTIONS ------------------------------------------------------------//

    public void setServiceRateFinal(SDEPackage sde, Integer x) {
        enrtcr__Service__c tempService;
        enrtcr__Rate__c tempRate;
        if (sde.service != null && sde.rate != null) {
            tempService = [SELECT id, Name FROM enrtcr__Service__c WHERE id =: sde.service];
            tempRate = [SELECT id, Name FROM enrtcr__Rate__c WHERE id =: sde.rate];
            System.debug(tempService);
            //sde.travelCheck(tempService.Name, Integer.valueOf(this.client.MMM_Score__c));
        }

        switch on x {
            when 1 {this.s1 = tempService; this.r1 = tempRate;}
            when 2 {this.s2 = tempService; this.r2 = tempRate;}
            when 3 {this.s3 = tempService; this.r3 = tempRate;}
            when 4 {this.s4 = tempService; this.r4 = tempRate;}
            when 5 {this.s5 = tempService; this.r5 = tempRate;}
            when 6 {this.s6 = tempService; this.r6 = tempRate;}
            when 7 {this.s7 = tempService; this.r7 = tempRate;}
        }
    }

    public enrtcr__Support_Delivered__c createSDE(User u, enrtcr__Support_Contract__c SA, enrtcr__Site_Service__c SSP, SDEPackage sdpack, enrtcr__Service__c service, enrtcr__Rate__c rate, Integer count) {
        enrtcr__Support_Delivered__c SDE = new enrtcr__Support_Delivered__c();
        SDE.enrtcr__Date__c = sdpack.sdeDate;
        SDE.enrtcr__Worker__c = u.Id;
        SDE.enrtcr__Client__c = this.client.Id;
        SDE.enrtcr__Support_CategoryId__c = this.SC.Id;
        SDE.enrtcr__Site__c = this.site.Id;
        SDE.enrtcr__Support_Contract_Item__c = this.serviceAgreementItem.Id;
        SDE.enrtcr__Ad_hoc__c = FALSE;
        SDE.enrtcr__Cancellation__c = FALSE;
        SDE.enrtcr__Client_Rep_Accepted__c = TRUE;
        SDE.enrtcr__Client_Rep_Accepted_Date__c = sdpack.sdeDate;
        SDE.enrtcr__Support_Contract__c = SA.Id;
        SDE.enrtcr__Case_Note__c = sdpack.caseNotes.length() != 0 ? String.valueOf(count + 1) + '. ' + sdpack.caseNotes : sdpack.caseNotes;
        SDE.enrtcr__Comments__c = sdpack.comments.length() > 254 ? sdpack.comments.substring(0, 254) : sdpack.comments;
        SDE.Uncapped_Quantity__c = sdpack.inputtedTravel;
        SDE.New_Delivery__c = true;
        SDE.enrtcr__Quantity__c = sdpack.quantity;
        SDE.Original_Quantity__c = sdpack.originalQuantity;

        if (sdpack.deliver == true) {
            SDE.enrtcr__Site_Service_Program__c = SSP.Id;
            SDE.enrtcr__Adhoc_Service__c = service.Id;
            SDE.enrtcr__Rate__c = rate.Id;
        } else {
            SDE.Original_Service__c = service.Id;
            SDE.enrtcr__Site_Service_Program__c = this.OCSSP.Id;
            SDE.enrtcr__Adhoc_Service__c = this.overclaimRate.enrtcr__Service__r.Id;
            SDE.enrtcr__Rate__c = this.overclaimRate.Id;
            SDE.SD_Status__c = this.overclaimStatus;
        }
        return SDE;
    }

    public Long getTimeDiff(DateTime aTime) {
        //Get the time the user loaded the page
        TimeZone tz = UserInfo.getTimeZone();
        DateTime corrected = aTime.addSeconds((tz.getOffset(aTime)/1000));

        Long one = corrected.getTime();
        Long two = this.start.getTime();
        Long milli = one - two;
        Long seconds = milli / 1000;

        return seconds;
    }

    public void showSDES() {
        System.debug('SDE1 - service = ' + sde1.service + ' quantity = ' + sde1.quantity + ' deliver = ' + sde1.deliver + ' date = ' + sde1.sdeDate + ' td = ' + sde1.totalDollar);
        System.debug('SDE2 - service = ' + sde2.service + ' quantity = ' + sde2.quantity + ' deliver = ' + sde2.deliver + ' date = ' + sde2.sdeDate + ' td = ' + sde2.totalDollar);
        System.debug('SDE3 - service = ' + sde3.service + ' quantity = ' + sde3.quantity + ' deliver = ' + sde3.deliver + ' date = ' + sde3.sdeDate + ' td = ' + sde3.totalDollar);
        System.debug('SDE4 - service = ' + sde4.service + ' quantity = ' + sde4.quantity + ' deliver = ' + sde4.deliver + ' date = ' + sde4.sdeDate + ' td = ' + sde4.totalDollar);
        System.debug('SDE5 - service = ' + sde5.service + ' quantity = ' + sde5.quantity + ' deliver = ' + sde5.deliver + ' date = ' + sde5.sdeDate + ' td = ' + sde5.totalDollar);
        System.debug('SDE6 - service = ' + sde6.service + ' quantity = ' + sde6.quantity + ' deliver = ' + sde6.deliver + ' date = ' + sde6.sdeDate + ' td = ' + sde6.totalDollar);
        if (overclaim != null) {System.debug('SDE7 - service = ' + overclaim.service + ' quantity = ' + overclaim.quantity + ' deliver = ' + overclaim.deliver + ' date = ' + overclaim.sdeDate + ' td = ' + overclaim.totalDollar);}else {System.debug('overclaim null');}
    }

    //----------------------------------------------------------- STATE FUNCTIONS ------------------------------------------------------------//
    public void toggleDisabled(Integer x) {
        if (x == 1) {
            this.submitDisabled = true;
        } else if (x == 0) {
          this.submitDisabled = false;
        }

    }

    public void closePopup() {
        this.displayPopUp = false;
        this.overClaimStatus = 'No new funding expected';
    }

    public void falseOverclaimActions() {
        this.overClaimStatus = 'Awaiting new funding';
        this.displayPopUp = false;
    }



    public void instantiateSDEs() {
        sde1 = new SDEPackage();
        sde2 = new SDEPackage();
        sde3 = new SDEPackage();
        sde4 = new SDEPackage();
        sde5 = new SDEPackage();
        sde6 = new SDEPackage();
        overclaim = new SDEPackage();
    }

    public void resetServiceRates(Integer x) {
        sde1.reset(x);
        sde2.reset(x);
        sde3.reset(x);
        sde4.reset(x);
        sde5.reset(x);
        sde6.reset(x);
    }

    public void resetForm() {
        //select options
        this.clients = null;
        this.SAIs = null;
        this.services = null;

        //sde packages
        resetServiceRates(4);

    //user choices
        this.selectedWorker = null;
        this.selectedClient = null;
        this.selectedSupport = null;
        this.selectedSite = null;
        this.selectedSA = null;
        this.selectedSAI = null;

        //final variables after save
        this.worker = null;
        this.client = null;
        this.SC = null;
        this.site = null;
        this.serviceAgreementItem = null;

        this.s1 = null;
        this.r1 = null;
        this.s2 = null;
        this.r2 = null;
        this.s3 = null;
        this.r3 = null;
        this.s4 = null;
        this.r4 = null;
        this.s5 = null;
        this.r5 = null;
        this.s6 = null;
        this.r6 = null;

    }

    public void resetSDE1() {
        toggleDisabled(1);
        sde1.reset(4);
        this.s1 = null;
        this.r1 = null;
    }
  public void resetSDE2() {
        toggleDisabled(1);
        sde2.reset(4);
        this.s2 = null;
        this.r2 = null;
    }
    public void resetSDE3() {
        toggleDisabled(1);
        sde3.reset(4);
        this.s3 = null;
        this.r3 = null;
    }
    public void resetSDE4() {
        toggleDisabled(1);
        sde4.reset(4);
        this.s4 = null;
        this.r4 = null;
    }
    public void resetSDE5() {
        toggleDisabled(1);
        sde5.reset(4);
        this.s5 = null;
        this.r5 = null;
    }
    public void resetSDE6() {
        toggleDisabled(1);
        sde6.reset(4);
        this.s6 = null;
        this.r6 = null;
    }
    public void resetSDEOC() {
        toggleDisabled(1);
        overclaim.reset(4);
        this.s7 = null;
        this.r7 = null;
    }

    public void resetALLSDEs() {
        resetSDE1();
        resetSDE2();
        resetSDE3();
        resetSDE4();
        resetSDE5();
        resetSDE6();
        resetSDEOC();
    }

    public void overclaimReset() {
        sde1.reset(5);
        sde2.reset(5);
        sde3.reset(5);
        sde4.reset(5);
        sde5.reset(5);
        sde6.reset(5);
        overclaim.reset(4);

    }
    //----------------------------------------------------------- AUDIT FUNCTIONS ------------------------------------------------------------//

    public Integer auditInput() {
        this.errors = new List<String>();
        this.messages = new List<String>();
        Integer pass = 1;
        if (selectedWorker == null) {
            String s = '[Error0x1]Worker has not been selected. \n';
            System.debug(s);
            errors.add(s);
            return 0;
        }

        if (selectedSite == null) {
            String s = '[Error0x4]Site Error. Please make sure your worker profile has a site allocated. \n';
            System.debug(s);
            errors.add(s);
            createAudit(4,s);
            return 0;
        }

        if (selectedSupport == null) {
            String s = '[Error0x3]Support Category Error. Please ask your OM to add a support category line item to your service agreement. \n';
            System.debug(s);
            errors.add(s);
            pass = 0;
        }

        if (sde1.service == null && sde2.service == null && sde3.service == null && sde4.service == null && sde5.service == null && sde6.service == null) {
            String s = '[Error0x7]At least one service delivery entry is required. \n';
            System.debug(s);
            errors.add(s);
            return 0;
        }

        if(selectedClient != null) {
            String MMMScore = [SELECT MMM_Score__c  FROM Contact WHERE id =: selectedClient LIMIT 1][0].MMM_Score__c;
            if (MMMScore == null) {
                String s = '[Error0x16]MMM Score Error. Please ensure the client your billing for has an MMM Score in their client profile under "Client Demographics". \n';
                System.debug(s);
                errors.add(s);
                createAudit(16,s);
                return 0;
            } else {
                //pass = auditCaseNotes() == 1 ? pass : 0;
                pass = auditSDEPackage(sde1,MMMScore) == 1 ? pass : 0;
                pass = auditSDEPackage(sde2,MMMScore) == 1 ? pass : 0;
                pass = auditSDEPackage(sde3,MMMScore) == 1 ? pass : 0;
                pass = auditSDEPackage(sde4,MMMScore) == 1 ? pass : 0;
                pass = auditSDEPackage(sde5,MMMScore) == 1 ? pass : 0;
                pass = auditSDEPackage(sde6,MMMScore) == 1 ? pass : 0;
            }
        } else {
            String s = '[Error0x2]Client has not been selected. \n';
            System.debug(s);
            errors.add(s);
            return 0;
        }

        if (selectedSA != null) {
            enrtcr__Support_Contract__c servag = [SELECT id, enrtcr__Status__c, enrtcr__Client__r.Id FROM enrtcr__Support_Contract__c WHERE id =: this.selectedSA LIMIT 1];
            if (servag != null && servag.enrtcr__Status__c != 'Current') {
                String s = '[Error0x8]The service agreement in your client association is not current or is invalid. Please speak to your OM for a fix and try again. \n';
                System.debug(s);
                errors.add(s);
                createAudit(8,s);
                return 0;
          } else if (selectedClient != servag.enrtcr__Client__r.Id ) {
                String s = '[Error0x17]The service agreement selected does not belong to the client selected. Please refresh the page and try again. \n';
                System.debug(s);
                errors.add(s);
                createAudit(17,s);
                return 0;
            }
        } else {
            String s = '[Error0x6]Service Agreement Error. Please make sure your client clinician association has a valid SA allocated. \n';
            System.debug(s);
            errors.add(s);
            createAudit(6,s);
            return 0;
        }

        if (selectedSAI != null) {
            Double remaining = [SELECT id, enrtcr__Support_Category_Remaining__c FROM enrtcr__Support_Contract_Item__c WHERE id =: selectedSAI LIMIT 1][0].enrtcr__Support_Category_Remaining__c;
            this.totalAmount = sde1.totalDollar + sde2.totalDollar + sde3.totalDollar + sde4.totalDollar + sde5.totalDollar + sde6.totalDollar;
            this.remainingBalance = remaining;
            if (this.totalAmount > remaining && this.totalAmount > 0) {
                Double ocAmount = totalAmount - remaining;
                this.ocAmountDisplay = ocAmount.intValue();
                //String s = '[Error0x14]Not enough money remaining in service agreement balance[Total remaining = $'+remaining+'] and you claimed a total of $'+this.totalAmount+'. This is the breakdown of each -> [sde1-$'+sde1.totalDollar+'||sde2-$'+sde2.totalDollar+'||sde3-$'+sde3.totalDollar+'||sde4-$'+sde4.totalDollar+'||sde5-$'+sde5.totalDollar+'||sde6$-'+sde6.totalDollar+']. \n';
                String m = 'NOTE - You have exceeded the hours currently signed on the service agreement by $' + ocAmount.intValue() + '. The exceeding amount will not be charged to the participant.';
                enrtcr__Rate__c[] overclaimRates = [SELECT id, Name, enrtcr__Service__r.Name, enrtcr__Service__r.Id FROM enrtcr__Rate__c WHERE Name = 'Overclaim' AND enrtcr__Service__r.Name = 'Overclaim' LIMIT 1];
                if (overclaimRates.size() != 0) {
                    this.overclaimRate = overclaimRates[0];
                    this.OCSSP = [SELECT Id, Name, enrtcr__Service__r.Name, enrtcr__Site__r.Name FROM enrtcr__Site_Service__c  WHERE  enrtcr__Site__r.Id =: selectedSite AND enrtcr__Service__r.Id =: overclaimRate.enrtcr__Service__r.Id LIMIT 1];
                    System.debug('Testing: ' + this.OCSSP);
                } else {
                    this.overclaimRate = null;
                }
                System.debug(m);
                this.displayPopUp = true;
                messages.add(m);
                overclaimAudit(remaining);
                createAudit(14,m);
            }
        } else {
            String s = '[Error0x5]Service Agreement Item has not been selected. \n';
            System.debug(s);
            errors.add(s);
            return 0;
        }

        System.debug('the errors are = ' + errors);
        return pass;
    }

    public void overclaimAudit(Double remaining) {
        showSDES();
        List<SDEPackageWrapper> deliveryDollars = new List<SDEPackageWrapper>();
        if (sde1.totalDollar != 0) {deliveryDollars.add(new SDEPackageWrapper(sde1));}
        if (sde2.totalDollar != 0) {deliveryDollars.add(new SDEPackageWrapper(sde2));}
        if (sde3.totalDollar != 0) {deliveryDollars.add(new SDEPackageWrapper(sde3));}
        if (sde4.totalDollar != 0) {deliveryDollars.add(new SDEPackageWrapper(sde4));}
        if (sde5.totalDollar != 0) {deliveryDollars.add(new SDEPackageWrapper(sde5));}
        if (sde6.totalDollar != 0) {deliveryDollars.add(new SDEPackageWrapper(sde6));}
        deliveryDollars.sort();
        Double interimTotal = deliveryDollars[0].pack.totalDollar;
        Integer i = 0;
        Double split = 0;
        while (i < deliveryDollars.size()) {
            if (interimTotal > remaining) {
                split = interimTotal - Utility.checkNegative(remaining);
                break;
            }
            interimTotal += deliveryDollars[i + 1].pack.totalDollar;
            i++;
        }
        //sdes to deliver fully
        for (Integer j = 0; j < i; j++) {
            deliveryDollars[j].pack.deliver = true;
            deliveryDollars[j].pack.split = false;
        }
        //sde to split
        deliveryDollars[i].pack.deliver = true;
        deliveryDollars[i].pack.split = true;

        //calculate how much to zero out the SA and how much is remaining to overclaim
        Double toOverclaimMultiplier = split / deliveryDollars[i].pack.totalDollar;
        Double toOverclaimQuantity = toOverclaimMultiplier * deliveryDollars[i].pack.quantity;
        Double toBillQuantity = Utility.roundDoubleDown(deliveryDollars[i].pack.quantity - toOverclaimQuantity, 1);
        System.debug('Billing was going to be ' + (deliveryDollars[i].pack.quantity - toOverclaimQuantity) + ' but is now ' + toBillQuantity);
        deliveryDollars[i].pack.quantity = toBillQuantity;
        //SDEPackage sde7 = new SDEPackage();
        overclaim.service = deliveryDollars[i].pack.service;
        overclaim.rate = deliveryDollars[i].pack.rate;
        overclaim.quantity = toOverclaimQuantity * KPIFactor;
        overclaim.originalQuantity = toOverclaimQuantity;
        overclaim.sdeDate = deliveryDollars[i].pack.sdeDate;
        overclaim.comments = deliveryDollars[i].pack.comments;
        overclaim.caseNotes = deliveryDollars[i].pack.caseNotes;
        overclaim.deliver = false;
        overclaim.lastClient = deliveryDollars[i].pack.lastClient;
        //this.overclaim = sde7;

        //sdes to fully overclaim
        for (Integer k = i + 1; k < deliveryDollars.size(); k++) {

            deliveryDollars[k].pack.split = false;
            deliveryDollars[k].pack.originalQuantity = deliveryDollars[k].pack.quantity;
            deliveryDollars[k].pack.quantity = deliveryDollars[k].pack.quantity * KPIFactor;
            if (deliveryDollars[k].pack.totalDollar == 0) {
                deliveryDollars[k].pack.deliver = true;
            } else {
                deliveryDollars[k].pack.deliver = false;
            }
        }
        showSDES();
    }

    //purpose to make sure no case notes are the same. Currently not being used
    public Integer auditCaseNotes() {
        if (
            (sde1.service != null && sde1.caseNotes != null && (sde1.caseNotes == sde2.caseNotes || sde1.caseNotes == sde3.caseNotes || sde1.caseNotes == sde4.caseNotes || sde1.caseNotes == sde5.caseNotes || sde1.caseNotes == sde6.caseNotes)) ||
            (sde2.service != null && sde2.caseNotes != null && (sde2.caseNotes == sde3.caseNotes || sde2.caseNotes == sde3.caseNotes || sde2.caseNotes == sde3.caseNotes || sde2.caseNotes == sde3.caseNotes)) ||
            (sde3.service != null && sde3.caseNotes != null && (sde3.caseNotes == sde4.caseNotes || sde3.caseNotes == sde5.caseNotes || sde3.caseNotes == sde6.caseNotes)) ||
            (sde4.service != null && sde4.caseNotes != null && (sde4.caseNotes == sde5.caseNotes || sde4.caseNotes == sde6.caseNotes)) ||
            (sde5.service != null && sde5.caseNotes != null && (sde5.caseNotes == sde6.caseNotes))
        ) {
            String s = '--No two case notes can be the same-- ';
            System.debug(s);
            errors.add(s);
            return 0;
        }
        return 1;
    }

    //Make sure an SDE package is valid
    public Integer auditSDEPackage(SDEPackage sde, String MMMScore) {
        if (sde.service != null) {
            enrtcr__Service__c tempService;
            tempService = [SELECT id, Name FROM enrtcr__Service__c WHERE id =: sde.service];
            sde.travelCheck(tempService.Name, Integer.valueOf(MMMScore));
            system.debug('Late changes MMM = ' + MMMScore + 'tempservice name = ' + tempService.Name);
            if (selectedSite != null) {
                enrtcr__Site_Service__c[] ss = [SELECT id FROM enrtcr__Site_Service__c WHERE  enrtcr__Site__r.Id =: selectedSite AND enrtcr__Service__r.Id =: sde.service];
                if (ss.size() == 0) {
                    String s = '[Error0x9]No site service record for '+tempService.Name+' and site Id ' + selectedSite + '. \n';
                    System.debug(s);
                    errors.add(s);
                    createAudit(9,s);
                    return 0;
                }
            }
            if (sde.validateQuantity() == 0) {
                String s = '[Error0x10]The quantity you entered was invalid. Hours =  ' + sde.hours + ' Minutes = ' + sde.minutes + ' . \n';
                System.debug(s);
                errors.add(s);
                return 0;
            }
            if (sde.rate == null) {
                String s = '[Error0x11]The service ' + tempService.Name + '('+sde.service+') looks like it does not have a rate attached to it. \n';
                System.debug(s);
                errors.add(s);
                createAudit(11,s);
                return 0;
            } else {
                enrtcr__Rate__c auditRate = [SELECT Id,  Name, enrtcr__Service__c FROM enrtcr__Rate__c WHERE Id =: sde.rate LIMIT 1];
                System.debug('service = 1 ' + auditRate.enrtcr__Service__c +  'sde service is = ' + sde.service);
                if (auditRate != null) {
                    if (auditRate.enrtcr__Service__c != sde.service) {
                        String s = '[Error0x12]The auto-selected rate ('+auditRate.Name+') has not been assigned to the service ('+tempService.Name+'). Please refresh the page and try once more. If this keeps happening, please give IT these codes [Rate:'+auditRate.Id+',RateService:'+auditRate.enrtcr__Service__c+'Service:'+sde.service+']. \n';
                        System.debug(s);
                        errors.add(s);
                        createAudit(12,s);
                        return 0;
                    }
                } else {
                    String s = '[Error0x13]Could not find a rate for the service ('+tempService.Name+') selected. Service code is ' + sde.service +'. \n';
                    System.debug(s);
                    errors.add(s);
                    createAudit(13,s);
                    return 0;
                }
            }
            if (selectedSA != null) {
                enrtcr__Support_Contract__c servag = [SELECT id, enrtcr__Start_Date__c, enrtcr__End_Date__c FROM enrtcr__Support_Contract__c WHERE id =: this.selectedSA LIMIT 1];
                if (servag != null && (sde.sdeDate > servag.enrtcr__End_Date__c || sde.sdeDate < servag.enrtcr__Start_Date__c)) {
                    String s = '[Error0x15]The date you are trying to deliver for falls outside of the date range of the service agreement for this client. \n';
                    System.debug(s);
                    errors.add(s);
                    return 0;
                }
            }
            sde.calculateTotal();

        }
        return 1;
    }

    public String captureUserInput() {
        String constants = 'selectedWorker:"'+this.selectedWorker+'",\n selectedClient:"'+this.selectedClient+'",\n selectedSAI:"'+this.selectedSAI+'",\n selectedSite:"'+this.selectedSite+'",\n selectedSA:"'+this.selectedSA+'",\n selectedSupport:"'+this.selectedSupport+'",';
        String sde1Input = 'sde1:{service:"'+this.sde1.service+'",rate:"'+this.sde1.rate+'",hours:"'+this.sde1.hours+'",minutes:"'+this.sde1.minutes+'",lastClient:"'+this.sde1.lastClient+'",comments:"'+this.sde1.comments+'",caseNotes:"'+this.sde1.caseNotes+'"},';
        String sde2Input = 'sde2:{service:"'+this.sde2.service+'",rate:"'+this.sde2.rate+'",hours:"'+this.sde2.hours+'",minutes:"'+this.sde2.minutes+'",lastClient:"'+this.sde2.lastClient+'",comments:"'+this.sde2.comments+'",caseNotes:"'+this.sde2.caseNotes+'"},';
        String sde3Input = 'sde3:{service:"'+this.sde3.service+'",rate:"'+this.sde3.rate+'",hours:"'+this.sde3.hours+'",minutes:"'+this.sde3.minutes+'",lastClient:"'+this.sde3.lastClient+'",comments:"'+this.sde3.comments+'",caseNotes:"'+this.sde3.caseNotes+'"},';
        String sde4Input = 'sde4:{service:"'+this.sde4.service+'",rate:"'+this.sde4.rate+'",hours:"'+this.sde4.hours+'",minutes:"'+this.sde4.minutes+'",lastClient:"'+this.sde4.lastClient+'",comments:"'+this.sde4.comments+'",caseNotes:"'+this.sde4.caseNotes+'"},';
        String sde5Input = 'sde5:{service:"'+this.sde5.service+'",rate:"'+this.sde5.rate+'",hours:"'+this.sde5.hours+'",minutes:"'+this.sde5.minutes+'",lastClient:"'+this.sde5.lastClient+'",comments:"'+this.sde5.comments+'",caseNotes:"'+this.sde5.caseNotes+'"},';
        String sde6Input = 'sde6:{service:"'+this.sde6.service+'",rate:"'+this.sde6.rate+'",hours:"'+this.sde6.hours+'",minutes:"'+this.sde6.minutes+'",lastClient:"'+this.sde6.lastClient+'",comments:"'+this.sde6.comments+'",caseNotes:"'+this.sde6.caseNotes+'"},';
        return constants + '\n' + sde1Input + '\n' + sde2Input + '\n' + sde3Input + '\n' + sde4Input + '\n' + sde5Input + '\n' + sde6Input;
    }

    public void createAudit(Integer type, String error) {
        Audit__c auditForm = new Audit__c();
        Id recordTypeId = [select Id from RecordType where DeveloperName = 'Errors' AND sObjectType = 'Audit__c' limit 1].Id;
        auditForm.RecordTypeId = recordTypeId;
        if (this.selectedWorker != null) {auditForm.Worker__c = this.selectedWorker;}
        if (this.selectedClient != null) {auditForm.Client__c = this.selectedClient;}
        if (remainingBalance != null) {auditForm.Remaining_Balance__c = remainingBalance;}
        if (totalAmount != null) {auditForm.Total_Claimed__c = totalAmount;}
        auditForm.Error_Message__c = error;
        auditForm.Error_Code__c = String.valueOf(type);
        if (type == 14) {
            String form = '-----------[Service Quantity(Rounded/Actual) Amount]-----------';
            String sd1 = '[' + sde1.service + ' ('+ sde1.quantity+'/'+sde1.inputtedTravel +') $' + sde1.totalDollar + ']';
            String sd2 = '[' + sde2.service + ' ('+ sde2.quantity+'/'+sde2.inputtedTravel +') $' + sde2.totalDollar + ']';
            String sd3 = '[' + sde3.service + ' ('+ sde3.quantity+'/'+sde3.inputtedTravel +') $' + sde3.totalDollar + ']';
            String sd4 = '[' + sde4.service + ' ('+ sde4.quantity+'/'+sde4.inputtedTravel +') $' + sde4.totalDollar + ']';
            String sd5 = '[' + sde5.service + ' ('+ sde5.quantity+'/'+sde5.inputtedTravel +') $' + sde5.totalDollar + ']';
            String sd6 = '[' + sde6.service + ' ('+ sde6.quantity+'/'+sde6.inputtedTravel +') $' + sde6.totalDollar + ']';
            auditForm.User_Input__c = form + '\n' + sd1 + '\n' + sd2 + '\n' + sd3 + '\n' + sd4 + '\n' + sd5 + '\n' + sd6;
        } else {
            String heading = '-----------User Input-----------';
          String input = captureUserInput();
            auditForm.User_Input__c = heading + '\n' + input;
        }

        try {
            insert auditForm;
        } catch(Exception e) {
            System.debug('Exception = ' + e.getMessage());
        }
    }

    //----------------------------------------------------------- SAVE FUNCTIONS ------------------------------------------------------------//

    public void saveAction() {
        overclaimReset();
        sde1.getRates();
        sde2.getRates();
        sde3.getRates();
        sde4.getRates();
        sde5.getRates();
        sde6.getRates();
        if (auditInput() == 0) {
            System.debug('Audit was completed on the input. Errors were found.');
        } else {
            toggleDisabled(0);
            System.debug('selected worker = ' + selectedWorker);
            System.debug('selected cli = ' + selectedClient);
            System.debug('selected sup = ' + selectedSupport);
            System.debug('selected ste = ' + selectedSite);
            System.debug('selected sai = ' + selectedSAI);
            if (selectedWorker != null) {
                this.worker = [SELECT id, enrtcr__Display_Full_Name__c, enrtcr__User__r.Id FROM Contact WHERE id =: selectedWorker];
                System.debug('worker in save' + worker);
            }
            if (selectedClient != null) {
                this.client = [SELECT id, enrtcr__Display_Full_Name__c, MMM_Score__c  FROM Contact WHERE id =: selectedClient];
            }
            if (selectedSupport != null) {
                this.SC = [SELECT id, Name FROM enrtcr__Reference_Data__c WHERE id =: selectedSupport];
            }
            if (selectedSite != null) {
                this.site = [SELECT id, Name FROM enrtcr__Site__c WHERE id =: selectedSite];
            }
            if (selectedSAI != null) {
                this.serviceAgreementItem = [SELECT id,  Name, enrtcr__Support_Contract__r.Name FROM enrtcr__Support_Contract_Item__c WHERE id =: selectedSAI];
            }
            setServiceRateFinal(sde1,1);
            setServiceRateFinal(sde2,2);
            setServiceRateFinal(sde3,3);
            setServiceRateFinal(sde4,4);
            setServiceRateFinal(sde5,5);
            setServiceRateFinal(sde6,6);
            setServiceRateFinal(overclaim,7);
        }
    }

    //----------------------------------------------------------- SUBMIT FUNCTIONS ------------------------------------------------------------//

    public PageReference submitAction() {
        this.submissionError = false;
        String allErrors = '';
        Audit__c auditForm = new Audit__c();
        Long diffSeconds = getTimeDiff(DateTime.now());
        System.debug('diffseconds =' + diffSeconds);

        Integer count = 0;
        List<enrtcr__Support_Delivered__c> sdes = new List<enrtcr__Support_Delivered__c>();
        System.debug('worker = ' + worker);
        User u = [SELECT id FROM User WHERE id =: worker.enrtcr__User__r.Id];
        enrtcr__Support_Contract__c ServiceAgreement = [SELECT id FROM enrtcr__Support_Contract__c WHERE id =: this.serviceAgreementItem.enrtcr__Support_Contract__r.Id];
        if (s1 != null) {
            enrtcr__Site_Service__c SSP1 = [SELECT id FROM enrtcr__Site_Service__c  WHERE  enrtcr__Site__r.Id =: selectedSite AND enrtcr__Service__r.Id =: s1.Id];
            sdes.add(createSDE(u, ServiceAgreement, SSP1, sde1, this.s1, this.r1, count));
            sde1.caseNotes = '1. ' + sde1.caseNotes;
            count++;
        }
        if (s2 != null) {
             enrtcr__Site_Service__c SSP2 = [SELECT id FROM enrtcr__Site_Service__c  WHERE  enrtcr__Site__r.Id =: selectedSite AND enrtcr__Service__r.Id =: s2.Id];
            sdes.add(createSDE(u, ServiceAgreement, SSP2, sde2, this.s2, this.r2, count));
            sde2.caseNotes = '2. ' + sde2.caseNotes;
            count++;
        }
        if (s3 != null) {
            enrtcr__Site_Service__c SSP3 = [SELECT id FROM enrtcr__Site_Service__c  WHERE  enrtcr__Site__r.Id =: selectedSite AND enrtcr__Service__r.Id =: s3.Id];
            sdes.add(createSDE(u, ServiceAgreement, SSP3, sde3, this.s3, this.r3, count));
            sde3.caseNotes = '3. ' + sde3.caseNotes;
            count++;
        }
        if (s4 != null) {
            enrtcr__Site_Service__c SSP4 = [SELECT id FROM enrtcr__Site_Service__c  WHERE  enrtcr__Site__r.Id =: selectedSite AND enrtcr__Service__r.Id =: s4.Id];
            sdes.add(createSDE(u, ServiceAgreement, SSP4, sde4, this.s4, this.r4, count));
            sde4.caseNotes = '4. ' + sde4.caseNotes;
            count++;
        }
        if (s5 != null) {
            enrtcr__Site_Service__c SSP5 = [SELECT id FROM enrtcr__Site_Service__c  WHERE  enrtcr__Site__r.Id =: selectedSite AND enrtcr__Service__r.Id =: s5.Id];
            sdes.add(createSDE(u, ServiceAgreement, SSP5, sde5, this.s5, this.r5, count));
            sde5.caseNotes = '5. ' + sde5.caseNotes;
            count++;
        }
        if (s6 != null) {
            enrtcr__Site_Service__c SSP6 = [SELECT id FROM enrtcr__Site_Service__c  WHERE  enrtcr__Site__r.Id =: selectedSite AND enrtcr__Service__r.Id =: s6.Id];
            sdes.add(createSDE(u, ServiceAgreement, SSP6, sde6, this.s6, this.r6, count));
            sde6.caseNotes = '6. ' + sde6.caseNotes;
            count++;
        }
        if (s7 != null) {
            enrtcr__Site_Service__c SSP7 = [SELECT id FROM enrtcr__Site_Service__c  WHERE  enrtcr__Site__r.Id =: selectedSite AND enrtcr__Service__r.Id =: s7.Id];
            sdes.add(createSDE(u, ServiceAgreement, SSP7, overclaim, this.s7, this.r7, count));
            overclaim.caseNotes = '7. ' + overclaim.caseNotes;
            count++;
        }
        PageReference refresh = new PageReference('/apex/BR_SDE');
        String userInput = captureUserInput();
        if (userInput.length() > 32750) {
            auditForm.User_Input__c = userInput.substring(0, 32750);
        } else {
            auditForm.User_Input__c = userInput;
        }
        try {
            insert sdes;
            toggleDisabled(1);
            //dateTime start = System.now();
            //while(System.now() < start.addSeconds(5));
            //CASE NOTE CHANGES
            Map<String,String> commCN = new Map<String,String>();
            if(sde1.comments != null) {commCN.put(sde1.caseNotes, sde1.comments.length() > 80 ? sde1.comments.substring(0, 75) + '...' : sde1.comments);} else {commCN.put(sde1.caseNotes, sde1.comments);}
            if(sde2.comments != null) {commCN.put(sde2.caseNotes, sde2.comments.length() > 80 ? sde2.comments.substring(0, 75) + '...' : sde2.comments);} else {commCN.put(sde2.caseNotes, sde2.comments);}
            if(sde3.comments != null) {commCN.put(sde3.caseNotes, sde3.comments.length() > 80 ? sde3.comments.substring(0, 75) + '...' : sde3.comments);} else {commCN.put(sde3.caseNotes, sde3.comments);}
            if(sde4.comments != null) {commCN.put(sde4.caseNotes, sde4.comments.length() > 80 ? sde4.comments.substring(0, 75) + '...' : sde4.comments);} else {commCN.put(sde4.caseNotes, sde4.comments);}
            if(sde5.comments != null) {commCN.put(sde5.caseNotes, sde5.comments.length() > 80 ? sde5.comments.substring(0, 75) + '...' : sde5.comments);} else {commCN.put(sde5.caseNotes, sde5.comments);}
            if(sde6.comments != null) {commCN.put(sde6.caseNotes, sde6.comments.length() > 80 ? sde6.comments.substring(0, 75) + '...' : sde6.comments);} else {commCN.put(sde6.caseNotes, sde6.comments);}
            List<Id> insertedIds = new List<Id>();
            for (enrtcr__Support_Delivered__c successSDE : sdes) {
                insertedIds.add(successSDE.Id);
            }
            List<enrtcr__Support_Delivered__c> insertedNames = [SELECT Id, Name FROM enrtcr__Support_Delivered__c WHERE Id IN: insertedIds];
            List<String> Names = new List<String>();
            for (enrtcr__Support_Delivered__c Name : insertedNames) {
                Names.add(Name.Name);
            }
            List<enrtcr__Note__c> caseNotes = [SELECT Id, Name, enrtcr__Description__c FROM enrtcr__Note__c WHERE Name IN: Names];
            for (enrtcr__Note__c note : caseNotes) {
                //if (note.enrtcr__Description__c.length() != 2 && commCN.get(note.enrtcr__Description__c) != null) {
                    note.Name = commCN.get(note.enrtcr__Description__c);
                //}
            }
            try {update caseNotes;} catch (DmlException e) {allErrors = allErrors + ' ||| ' + e.getMessage();}

            //AUDIT CREATION
            auditForm.Time_Spent__c = diffSeconds;
            auditForm.Number_of__c = count;
            auditForm.Status__c = 'Success';
            auditForm.Worker__c = this.worker.Id;
            auditForm.Client__c = this.client.Id;
            if(s1 != null) {auditForm.SD1__c = sdes[0].Id;}
            if(s2 != null) {auditForm.SD2__c = sdes[1].Id;}
            if(s3 != null) {auditForm.SD3__c = sdes[2].Id;}
            if(s4 != null) {auditForm.SD4__c = sdes[3].Id;}
            if(s5 != null) {auditForm.SD5__c = sdes[4].Id;}
            if(s6 != null) {auditForm.SD6__c = sdes[5].Id;}

            //Reset the form and refresh the page
            resetForm();
            refresh.setRedirect(true);

        } catch (DmlException e) {
            auditForm.Status__c = 'Failed';
            allErrors = allErrors + ' ||| ' + e.getMessage();
            this.submissionError = true;
            auditForm.Error_Message__c = allErrors;
          insert auditForm;
            return null;
        }


        auditForm.Error_Message__c = allErrors;
        insert auditForm;
    return refresh;
    }
}