public with sharing class br_kpiRecalibration {
    
    String jsonString;
    Map<String, Object> classSettings;
    
    public Boolean classContructionValid = true;
    
    private List<User> userstoUpdate = new List<User>();
    private Map<Id, Double> userIdKPIRelationship = new Map<Id, Double>();
    
    private List<Contact> employees;
    private Map<String, Double> directTable;
    private Map<String, Double> supervisionTableNewFramework;
    
    private Map<Id, List<Contact>> clinicalSupervisees = new Map<Id, List<Contact>>();
    private Map<Id, List<Contact>> directSupervisees = new Map<Id, List<Contact>>();
    
    public Map<String, String> auditMap = new Map<String, String>();
    
    private List<String> allowedDepartments;
    private List<String> allowedIBs;
    private List<String> directSupIBs;
    
    Double weeks_completed_threshold = 12;
    private Id clinician;
    
    public br_kpiRecalibration(Id clinician) {
        // get the kpi flow settings from settings object
        List<Setting__c> kpiFlowSettings = [SELECT id, Name, Settings__c FROM Setting__c WHERE Name = 'kpiFlow' LIMIT 1];
        
        // if not exactly one setting is returned, exit class construction
        if (kpiFlowSettings.size() == 0 || kpiFlowSettings.size() > 1) {
            classContructionValid = false;
            return;
        }
        
        // convert class settings string into Map
        jsonString = kpiFlowSettings[0].Settings__c;
        classSettings = Utility.JSONtoMap(jsonString);
        
        // if the base kpi setting doesnt exist in kpi flow settings, exit class construction
        if (classSettings.keySet().contains('baseKPI') == false || classSettings.keySet().contains('AHA Early Service') == false
            || classSettings.keySet().contains('AHA Full Service') == false || classSettings.keySet().contains('AHA Community') == false
            || classSettings.keySet().contains('AHA Senior Service') == false || classSettings.keySet().contains('baseKPI NZ') == false) {
                classContructionValid = false;
                return;
            }
        
        // get all better rehab employees (contact)
        employees = Utility.getEmployees();
        
        if (employees == null) {
            classContructionValid = false;
        }
        
        // find relationships of clinical/direct supervisees and store them
        buildRelationships(employees);
        
        // initialise the hours allowable tables for direct and clinical supervisors
        directTable = br_constants.getDirectSupervisorKPITable();
        supervisionTableNewFramework = br_constants.getClinicalSupervisorKPITableNewFramework();
        
        // initialise the department and IB allowable lists
        initialiseCheckLists();
    }
    
    private void buildRelationships(List<Contact> allEmployees) {
        for (Contact c : allEmployees) {
            //if employee is in the old system
            if(c.New_Framework__c == FALSE){                
                if (c.Clinical_Supervisor__c != null) {
                    if ( clinicalSupervisees.get(c.Clinical_Supervisor__c) == null ) {
                        clinicalSupervisees.put(c.Clinical_Supervisor__c, new List<Contact>{c});
                    } else {
                        List<Contact> supervisees = clinicalSupervisees.get(c.Clinical_Supervisor__c);
                        supervisees.add(c);
                        clinicalSupervisees.put(c.Clinical_Supervisor__c, supervisees);
                    }
                }
                if (c.Direct_Supervisor__c != null) {
                    if ( directSupervisees.get(c.Direct_Supervisor__c) == null ) {
                        directSupervisees.put(c.Direct_Supervisor__c, new List<Contact>{c});
                    } else {
                        List<Contact> supervisees = directSupervisees.get(c.Direct_Supervisor__c);
                        supervisees.add(c);
                        directSupervisees.put(c.Direct_Supervisor__c, supervisees);
                    }
                }  
                //if employee is in the new system
            } else {
                if (c.Direct_Supervisor__c != null) {
                    if ( directSupervisees.get(c.Direct_Supervisor__c) == null ) {
                        directSupervisees.put(c.Direct_Supervisor__c, new List<Contact>{c});
                    } else {
                        List<Contact> supervisees = directSupervisees.get(c.Direct_Supervisor__c);
                        supervisees.add(c);
                        directSupervisees.put(c.Direct_Supervisor__c, supervisees);
                    }
                }  
            }
        }
    }
    
    private String performUpdates() {
        for (User u : [SELECT id, Name, KPI__c FROM User WHERE id IN :userIdKPIRelationship.keySet()]) {
            Double newKPI = userIdKPIRelationship.get(u.Id);
            createAuditEntry(u, newKPI);
            u.KPI__c = newKPI;
            userstoUpdate.add(u);
        }
        
        try {
            update userstoUpdate;
            return 'Success';
        } catch (DMLException e) {
            return e.getMessage();
        }
    }
    
    //this method is called from br_actions to determine whether to refresh one or all clinician's KPI
    public String performChecks(Id clinician) {     
        for (Contact c : employees) {
            // the first condition will satisfy if we are only running recalibration for one clinician
            // otherwise recalibration will run for all clinicians
            if (clinician != null && c.Id == clinician) {
                userIdKPIRelationship.put(c.enrtcr__User__c, recalibrationAlgo(c));
                
                return performUpdates();
                
            } else if (clinician == null) {
                userIdKPIRelationship.put(c.enrtcr__User__c, recalibrationAlgo(c));
            }
        }
        
        
        return performUpdates();
    }
    
    //for old and new framework
    private Double recalibrationAlgo(Contact clinicianToRecalibrate) {
        // retrieve variables from the contact
        Double supervisorFTE = clinicianToRecalibrate.FTE__c;
        Double KPI;  
        String clinicianIB = clinicianToRecalibrate.Internal_Banding__c;  
        Double recalibrationResult;
        
        //exclude NZ clinicians from any KPI recalibration based on supervisees numbers
        if(clinicianToRecalibrate.enrtcr__Site__r.Business_Country__c == 'New Zealand'){
            System.debug('this clinician is from NZ');
            KPI = Double.valueOf(classSettings.get('baseKPI NZ')); 
            System.debug('KPI for NZ: ' + KPI);
            System.debug('FTE for clinician: ' + supervisorFTE);
            recalibrationResult = supervisorFTE * KPI;
            
        } else {
            
            System.debug('this clinician is NOT NZ');
            //get the base KPI based on the IB
            if(clinicianIB == 'AHA Early Service' || clinicianIB == 'AHA Full Service' || clinicianIB == 'AHA Community' || clinicianIB == 'AHA Senior Service'){
                KPI = Double.valueOf(classSettings.get(clinicianIB)); //key value has to match with IB for AHA
            } else {
                KPI = Double.valueOf(classSettings.get('baseKPI'));  
            }
            
            // get list of all supervisees of this contact
            List<Contact> clinSupervisees = clinicalSupervisees.get(clinicianToRecalibrate.Id);
            List<Contact> dirSupervisees = directSupervisees.get(clinicianToRecalibrate.Id);
            
            // initialise the number of hours to subtract from KPI to 0
            Double hoursToSubtract = 0;       
            
            // increment the number of hours to subtract for each clinical and direct supervisee
            if (dirSupervisees != null) {
                for (Contact supervisee : dirSupervisees) {
                    System.debug('Currently processing DS: ' + supervisee.Name);
                    String IB = supervisee.Internal_Banding__c;
                    Double weeksCompleted = supervisee.Weeks_Completed__c;
                    Double superviseeFTE = supervisee.FTE__c;
                    String Department = supervisee.Clinician_Discipline__c;
                    
                    //have to check whether the supervisee is in the old or new system and get the numbers accordingly
                    if(supervisee.New_Framework__c == FALSE){   
                        System.debug('DS: ' + supervisee.Name + ' is in the OLD system');
                        hoursToSubtract += findHours('direct', null, IB, superviseeFTE);
                        System.debug('findHours for direct supervisee: ' + supervisee.Name + ': ' + findHours('direct', null, IB, superviseeFTE));
                    } else {
                        System.debug('DS: ' + supervisee.Name + ' is in the NEW system');
                        hoursToSubtract += findHours('clinical', Department, IB, superviseeFTE);
                        System.debug('findHours for direct supervisee: ' + supervisee.Name + ': ' + findHours('clinical', Department, IB, superviseeFTE));
                    }
                    
                    
                }            
                
                
            }
            
            
            if ( clinSupervisees != null) {
                for (Contact supervisee : clinSupervisees) {
                    System.debug('Currently processing CS: ' + supervisee.Name);
                    String IB = supervisee.Internal_Banding__c;
                    Double weeksCompleted = supervisee.Weeks_Completed__c;
                    Double superviseeFTE = supervisee.FTE__c;
                    String Department = supervisee.Clinician_Discipline__c;
                    
                    //have to check whether the supervisee is in the old or new system and get the numbers accordingly
                    if(supervisee.New_Framework__c == FALSE){
                        System.debug('CS: ' + supervisee.Name + ' is in the OLD system');
                        hoursToSubtract += findHours('clinical', Department, IB, superviseeFTE);
                        System.debug('findHours for clin supervisee: ' + supervisee.Name + ': ' + findHours('clinical', Department, IB, superviseeFTE));
                    } else {
                        System.debug('CS: ' + supervisee.Name + ' is in the NEW system');
                        System.debug('This supervisee is in the new system, the worker is a site supervisor. No hours to substract');
                        hoursToSubtract += 0;
                        System.debug('findHours for clin supervisee: ' + supervisee.Name + ': ' + 0);
                    }
                } 
            }
            
            System.debug('TOTAL hoursToSubtract: ' + hoursToSubtract);
            
            // calculate calibrated taking into account FTE of contact and hours to subtract
            recalibrationResult = ((supervisorFTE * KPI) - hoursToSubtract) < 0 ? 0 : ((supervisorFTE * KPI) - hoursToSubtract);
                
        }        
        
        System.debug('recalibrationResult: ' + recalibrationResult);
        return recalibrationResult;        
    }
    
    private void createAuditEntry(User u, Double newKPI) {
        String log = 'The KPI of ' + u.Name + ' was updated from ' + String.valueOf(u.KPI__c) + ' to ' + String.valueOf(newKPI) + '.';
        auditMap.put(u.Id, log);
    }
    
    // function to which retrieves the hours allowed to supervise
    private Double findHours(String supervisorType, String department, String IB, Double FTE) {
        
        if ( supervisorType == 'direct' ) {
            if ( !directSupIBs.contains(IB) ) {
                return 0;
            }
            
            return directTable.get(IB) * FTE;
        } else if ( supervisorType == 'clinical' ) {
            if ( !allowedDepartments.contains(department) || !allowedIBs.contains(IB) ) {
                return 0;
            }
            
            return supervisionTableNewFramework.get(IB);
        }
        
        return 0;
    }
    
    private void initialiseCheckLists() {
        allowedDepartments = new List<String>{'Occupational Therapy', 'Speech Pathology', 'Physiotherapy', 'PBS', 'Exercise Physiology', 'Allied Health Assistant'};
            allowedIBs = new List<String>{'Graduate Clinician', 'Early Practicing Clinician', 'Practicing Clinician', 'Senior Clinician', 'AHA Early Service', 'AHA Full Service', 'AHA Community','AHA Senior Service'};
                directSupIBs = new List<String>{'Graduate Clinician', 'Early Practicing Clinician', 'Practicing Clinician', 'Senior Clinician'};
                    }
    
}