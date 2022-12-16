public with sharing class br_constants {   
    
    /*
    	Create and return the table of allowable supervision for direct supervisors
    	
		References:
			br_kpiRecalibration
    */
    static public Map<String, Double> getDirectSupervisorKPITable() {
        return new Map<String, Double>{
            'Graduate Clinician' => 0.5,
            'Early Practicing Clinician' => 0.5,
            'Practicing Clinician' => 0.25,
            'Senior Clinician' => 0.125
        };    
    }
    
     /*
    	Create and return the table of allowable supervision for clinical supervisions (1:1, JV)
    	
		References:
			br_kpiRecalibration
    */
    
    static public Map<String, Double> getClinicalSupervisorKPITableNewFramework() {
        return new Map<String, Double>{
            'Graduate Clinician' => 1.5,
            'Early Practicing Clinician' => 1,
            'Practicing Clinician' => 0.75,
            'Senior Clinician' =>0.25,
            'AHA Early Service' => 0.25,
            'AHA Full Service' => 0.25,
            'AHA Community' => 0.25,
            'AHA Senior Service' => 0.25
        };    
    }
}