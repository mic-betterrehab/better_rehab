public without sharing class br_AuditController {
    public List<SelectOption> auditTypeAll {get;set;}
    public String auditType {get; set;}

    public Id Auditor {get;set;}
    public Id Clinician {get;set;}
    public Id Participant {get;set;}
    public Id supervisionProfile {get;set;}
    
    public List<SelectOption> workers {get;set;}
    public List<SelectOption> clients {get;set;}
    public List<SelectOption> supervisionList {get;set;}
    public List<SelectOption> clinicalArea {get;set;}
    public List<SelectOption> YesNo {get;set;}
    
    public List<AuditSectionPackage> sections {get;set;}
    
    public User finalAuditor {get;set;}
    public Contact finalClinician {get;set;}
    public Contact finalClient {get;set;}
    public Contact clin {get;set;}
    public Set<Id> clientIds {get;set;}
    
    public String finalClinArea {get;set;}
    public String finalReportReview {get;set;}
    public Integer finalNumerator {get;set;}
    public Integer finalDenominator {get;set;}
    public String result {get;set;}
    public String strengths {get;set;}
    public String improvements {get;set;}
    public String taskCreateName {get;set;}
    
    public Double threshhold {get;set;}
    public DateTime start {get ; set;}
    public Boolean submitDisabled {get; set;}
    public Boolean displayPopUp {get;set;}
    public Map<String, String> status {get;set;}
        
    public br_AuditController(ApexPages.StandardController stdController) {
        // Add name field std controller for fields you want to retrieve
        if (!Test.isRunningTest()) stdController.addFields(new List<String>{'Name'});
        this.clin = (Contact)stdController.getRecord();
        this.Clinician = this.clin.Id;
        
        // initialise the const variables of the audit form
        initiateAuditVariables();
        
        // get the clients (client will be autoselected)
        findClients();
        selectClient();
        
        // load the audit initially
        loadAudit();
	}
    
    //-----------------------------------------------------------
    //---------------------INITIALISATION FUNCTIONS--------------
    //-----------------------------------------------------------
	public void initiateAuditVariables() {
    	// set the start time of the audit
        TimeZone tz = UserInfo.getTimeZone();
        DateTime dt = DateTime.now();
        this.start = dt.addSeconds((tz.getOffset(dt)/1000));
        
        // set the id of the auditor and their User profile
        this.Auditor = UserInfo.getUserId();
        this.finalAuditor = [SELECT id, Name FROM User WHERE id =: this.Auditor];
        
        // initialise some variables
        status = new Map<String,String>();
        clientIds = new Set<Id>();
        this.submitDisabled = FALSE;
        this.displayPopUp = FALSE;
   		
        // set the audit type picklist options
        auditTypeAll = new List<SelectOption>();
        auditTypeAll.add(new SelectOption('Clinical Audit', 'Clinical Audit'));
        auditTypeAll.add(new SelectOption('Procedural Audit', 'Procedural Audit'));
        this.auditType = 'Clinical Audit';
        
        // set the clinical area picklist options
        clinicalArea = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult = Clinical_Audit__c.Clinical_Area__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple){
			clinicalArea.add(new SelectOption(pickListVal.getLabel(), pickListVal.getLabel()));
		} 
        
        // set the yes/no picklist options
        YesNo = new List<SelectOption>();
        YesNo.add(new SelectOption('Yes', 'Yes'));
        YesNo.add(new SelectOption('No', 'No'));
    }
	
    private void findClients() {
        String[] filters = new String[]{'%supervision%','%Supervision%','%Better Rehab%'};
        clients = Utility.getClients(Clinician, filters);
        
        // get all possible client ids in a set
        //Set<Id> clientIds = new Set<Id>();
        for (SelectOption c : clients) {
            clientIds.add(c.getValue());
        }

        // get clients that have been audited in last 90 days
        DateTime cutoff = DateTime.now() - 90;
        List<Clinical_Audit__c> clientsAudited = [SELECT id, Client__c FROM Clinical_Audit__c WHERE Client__c IN :clientIds AND CreatedDate > :cutoff];

        // remove clients from all possible client set
        for (Clinical_Audit__c ca : clientsAudited) {
            clientIds.remove(ca.Client__c);
        }
    }
    
    public void selectClient() {
        if (clientIds.size() != 0) {
            Integer randomNumber = Utility.getRandom(0, clientIds.size() - 1);
                
            if (randomNumber > clientIds.size()) {
                randomNumber = 0;
            }
            
            this.Participant = new List<Id>(clientIds)[randomNumber];
            this.finalClient = [SELECT id, Name FROM Contact WHERE id =: this.Participant];
        } else {
            this.Participant = null;
            this.finalClient = null;
            
            this.submitDisabled = True;
        }
    }
    
    private void loadAudit() {
        if (this.Participant == null) {
            return;
        }
       
        this.finalNumerator = 0;
        this.finalDenominator = 0;
        
        // initialse sections and questions
        sections = new List<AuditSectionPackage>();
        
        List<Setting__c> audit_settings = [SELECT Settings__c FROM Setting__c WHERE Name =: auditType LIMIT 1];

        if (audit_settings.size() == 0) {
            return;
        }
        
        Map<String, Object> settings = (Map<String, Object>) JSON.deserializeUntyped(audit_settings[0].Settings__c);
        
        this.threshhold = Double.valueOf(settings.get('threshold'));
        List<Object> settingsSections = (List<Object>)settings.get('sections');

        for (Object section : settingsSections) {
            Map<String, Object> sMap = (Map<String, Object>) section;
            Object title = sMap.get('title');
            Object details = sMap.get('details');
            AuditSectionPackage newSection = new AuditSectionPackage((String)title, (String)details); 
            sections.add(newSection);

            List<Object> questions = (List<Object>)sMap.get('questions');
            for(Object question : questions) {
                Map<String, Object> qMap = (Map<String, Object>) question;
                Integer questionNumber = Integer.valueOf(qMap.get('number'));
                String questionName = String.valueOf(qMap.get('question'));
                Boolean mandatory = Boolean.valueOf(qMap.get('mandatory'));
                Integer minScore = Integer.valueOf(qMap.get('minScore'));
                Integer maxScore = Integer.valueOf(qMap.get('maxScore'));
                List<Object> guidelines = (List<Object>)qMap.get('guidelines');
                List<String> stringGuidelines = new List<String>();
                
                for (Object g : guidelines) {
                    stringGuidelines.add(String.valueOf(g));
                }

                newSection.addQuestion(questionNumber, questionName, !mandatory, minScore, maxScore, FALSE, stringGuidelines);
            }
        }
    }
    //-----------------------------------------------------------
    //---------------------USER ACTION FUNCTIONS--------------
    //----------------------------------------------------------- 
    public void clickLoad() {
   		loadAudit();   
    }
	
    public void clickRefreshClient() {
        selectClient();
    }
    
    public PageReference submit() {
        finalAuditor = [SELECT id, Name FROM User WHERE id =: Auditor LIMIT 1];
        finalClinician = [SELECT id, Name, enrtcr__User__r.Id FROM Contact WHERE id =: Clinician LIMIT 1];
        finalClient = [SELECT id, Name FROM Contact WHERE id =: Participant LIMIT 1];
      
        calculateTotal();
        Clinical_Audit__c audit = buildAuditRecord();
        audit.Name = finalClinician.Name + ' ' + System.today().format() + ' Audit x';
        
        // log user input
        Audit__c auditLog = new Audit__c();
        auditLog.Name = finalClinician.Name + ' ' + System.today().format() + ' Audit Log';
        auditLog.Worker__c = finalClinician.Id;
        auditLog.Client__c = finalClient.Id;
        auditLog.User_Input__c = logUserInput();
        auditLog.RecordTypeId = Schema.SObjectType.Audit__c.getRecordTypeInfosByDeveloperName().get('Audits').getRecordTypeId();
        
        try {
            insert audit;
        } catch (DmlException e) {
            auditLog.Error_Message__c = e.getMessage();
            insert auditLog;
            PageReference doNothing = new PageReference('/BR_Audit');
            return doNothing;
        }
        
        postAuditActions(audit.Id);
        insert auditLog;
        PageReference refresh = new PageReference('/' + audit.Id );
        refresh.setRedirect(true);
        return refresh;
    }
    
    public void resetTaskSection() {
        this.taskCreateName = null;
    }
    
    public void closePopup() {
        this.displayPopUp = false;
    }
    
    //-----------------------------------------------------------
    //---------------------sObject POST/GET FUNCTIONS------------
    //-----------------------------------------------------------
    private Task newTask(Integer dueDateDays, Id AssignedTo, String Priority, String Status, String Subject, Id RelatedTo) {
        Task t = new Task();
        t.ActivityDate = System.today() + dueDateDays;
        t.OwnerId = AssignedTo;
        t.Priority = Priority;
        t.Status = Status;
		t.Type = 'Other';
        t.Subject = Subject;
        t.WhatId = RelatedTo;
        t.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Task').getRecordTypeId();
        
        return t;
    }
    
    public Clinical_Audit__c buildAuditRecord() {
        Clinical_Audit__c audit = new Clinical_Audit__c();
        
        audit.Auditor__c = Auditor;
        audit.Client__c = Participant;
        audit.Clinical_Area__c = finalClinArea;
        audit.Clinician__c = Clinician;
        
        audit.Time_taken__c = Utility.getTimeDiff(this.start, DateTime.now());
        audit.Audit_Type__c = auditType;
        audit.Numerator__c = finalNumerator;
        audit.Denominator__c = finalDenominator;
        audit.Strengths__c = strengths;
        audit.Improvements__c = improvements;
        audit.Status__c = result;
        
        audit.Sections__c = formatAuditBreakdown();
        audit.BreakdownJSON__c = buildJSON(); 
        
        return audit;
    }
    
    //-----------------------------------------------------------
    //---------------------HELPER/STATE FUNCTIONS------------
    //-----------------------------------------------------------
    public String formatAuditBreakdown() {
        String header = '---------Main---------\n' + 
            		'Auditor: ' + finalAuditor.Name + '\n' +
         			'Clinician: ' + finalClinician.Name + '\n' +
            		'Client: ' + finalClient.Name + '\n' +
            		'Score: ' + finalNumerator + '/' + finalDenominator + '\n' +
            		'Threshold: ' + this.threshhold + '\n' +
            		'Status: ' + result + '\n' +
            		'-------------------' + '\n' +
            		'Strengths: ' + strengths + '\n' +
            		'Improvements: ' + improvements + '\n' +
            		'-------------------' + '\n' + 
            		'Clinical Area: ' + finalClinArea + '\n' +
            		'Reports Reviewed?: ' + finalReportReview + '\n' + 
            		'-------------------' + '\n';
        
        List<String> sformatted = new List<String>();
        
        for (AuditSectionPackage s : sections) {
        	String sectionHeader = '\n' + 'Section: ' + s.sectionTitle + '\n' +
                					'Score: ' + s.numerator + '/' + s.denominator + '\n' +
                					'Comments: ' + s.comments + '\n' + 
                					'        ***        ' + '\n';
            String sectionBody = s.formatQsForDispaly();
           	
            String sectionFooter = '--------------------';
            
            sformatted.add(sectionHeader + sectionBody + sectionFooter);     					
        }
        
        String finalString = header;
        
        for (String section : sformatted) {
            finalString += section;
        }
        
        return finalString;
    }
    
    private String logUserInput() {
        String header = '---------Main---------\n' + 
            		'Auditor: ' + finalAuditor.Name + '(' + finalAuditor.Id + ')' + '\n' +
         			'Clinician: ' + finalClinician.Name + '(' + finalClinician.Id + ')' + '\n' +
            		'Client: ' + finalClient.Name + '(' + finalClient.Id + ')' + '\n' +
            		'Start: ' + this.start + '\n' +
            		'End: ' + getNowWithTz(DateTime.now(), UserInfo.getTimeZone()) + '\n' +
            		'TaskName: ' + this.taskCreateName + '\n' +
            		'Threshold: ' + this.threshhold + '\n' +
            		'Score: ' + finalNumerator + '/' + finalDenominator + '\n' +
            		'Status: ' + result + '\n' +
            		'-------------------' + '\n' +
            		'Strengths: ' + strengths + '\n' +
            		'Improvements: ' + improvements + '\n' +
            		'-------------------' + '\n' + 
            		'Clinical Area: ' + finalClinArea + '\n' +
            		'Reports Reviewed?: ' + finalReportReview + '\n' + 
            		'-------------------' + '\n';
        
        List<String> sformatted = new List<String>();
        
        for (AuditSectionPackage s : sections) {
        	String sectionHeader = '\n' + 'Section: ' + s.sectionTitle + '\n' +
                					'Score: ' + s.numerator + '/' + s.denominator + '\n' +
                					'Comments: ' + s.comments + '\n' + 
                					'Task: ' + s.taskName + '\n' + 
                					'        ***        ' + '\n';
            String sectionBody = s.formatQsForDispaly();
           	
            String sectionFooter = '--------------------';
            
            sformatted.add(sectionHeader + sectionBody + sectionFooter);     					
        }
        
        String finalString = header;
        
        for (String section : sformatted) {
            finalString += section;
        }
        
        return finalString;
    }
    
    private String buildJSON() {
        Map<String, Object> obj = new Map<String, Object>();
        
        // initialise array of all sections
        List<Map<String,Object>> allSections = new List<Map<String,Object>>();
        
        for (AuditSectionPackage s : sections) {
            // initialise a Map for each section - this will be populated and added to array
            Map<String, Object> section = new Map<String, Object>();
            
            // initialise array for all questions within a section
            List<Map<String,String>> allQuestions = new List<Map<String,String>>();
            
            for (AuditQuestionPackage q : s.questions) {
                // initialise a Map for each question - this will be populated and added to array
                Map<String, String> question = new Map<String, String>();
                question.put('total', String.valueOf(q.maxScore));
                question.put('score', q.score);
                question.put('question', q.question);
                
                allQuestions.add(question);
            }

            section.put('questions', allQuestions);
            
            section.put('comments', s.comments);
            section.put('denominator', s.denominator);
            section.put('numerator', s.numerator);
            section.put('title', s.sectionTitle);
            
            allSections.add(section);
        }
        
        obj.put('sections', allSections);
        obj.put('improvements', improvements);
        obj.put('strengths', strengths);
        obj.put('status', result);
        obj.put('auditType', auditType);
        obj.put('threshold', threshhold);
        obj.put('score', finalNumerator/finalDenominator);
        obj.put('denominator', finalDenominator);
        obj.put('numerator', finalNumerator);
        obj.put('clientId', finalClient.Id);
        obj.put('clientName', finalClient.Name);
        obj.put('clinicianId', finalClinician.Id);
        obj.put('clinicianName', finalClinician.Name);
        obj.put('auditorId', finalAuditor.Id);
        obj.put('auditorName', finalAuditor.Name);
        return JSON.serialize(obj);
        
    }
    
    public void calculateTotal() {
        result = 'CONFORMS';
        for (AuditSectionPackage s : sections) {
            s.calculateTotals();
            if (s.status == 'DOES NOT CONFORM') {
                result = 'DOES NOT CONFORM';
            }
            finalNumerator += s.numerator;
            finalDenominator += s.denominator;
        }
        if ((Double.valueOf(finalNumerator) / Double.valueOf(finalDenominator)) < threshhold) {
            result = 'DOES NOT CONFORM';
        }
    }
    
    private void postAuditActions(Id auditId) {
        createAuditTasks(auditId);
        createAuditLog(auditId);
    }
    
    private void createAuditLog(Id auditId) {
        
    }
    
    private void createAuditTasks(Id auditId) {
        List<Task> tasks = new List<Task>();
      	
        Integer dueDate = 7;
        String priority = 'Normal';
        String status = 'Not Started';
        Id relatedTo = auditId;
        
        // section tasks
        for (AuditSectionPackage section : sections) {
            if (String.isNotBlank(section.taskName)) {
                
                Id assignedTo = finalClinician.enrtcr__User__r.Id;
                String subject = 'Re: ' + finalClient.Name + ' ' + section.taskName;
                
                Task t = newTask(dueDate, assignedTo, priority, status, subject, relatedTo);
            	
                tasks.add(t);
            }
        }
        
        // extras task for clinician
        if (String.isNotBlank(taskCreateName)) {
            Id assignedTo = finalClinician.enrtcr__User__r.Id;
            String subject = 'Re: ' + finalClient.Name + ' ' + taskCreateName;
            
            Task t = newTask(dueDate, assignedTo, priority, status, subject, relatedTo);
            	
            tasks.add(t);
        }
        
        
        // auto auditor tasks
        tasks.add(newTask(dueDate, finalAuditor.Id, priority, status, 'Provide ' + finalClinician.Name + 's audit feedback to the team leader', relatedTo));
        tasks.add(newTask(dueDate, finalAuditor.Id, priority, status, 'Check tasks assigned to ' + finalClinician.Name + ' following audit', relatedTo));
        System.debug(tasks.size());
        try {
        	insert tasks;    
        } catch (DMLException e) {
            this.status.put('Tasks', e.getMessage());
            System.debug(e.getMessage());
        }  
    }
    
    private DateTime getNowWithTz(DateTime dt, TimeZone tz) {
        return dt.addSeconds((tz.getOffset(dt)/1000));
    }
	
}