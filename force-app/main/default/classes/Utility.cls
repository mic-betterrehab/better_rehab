//Nad
//Commonly used utility functions for data manipulation
//18/02/2021
public with sharing class Utility {
    //Round a Double down to the nearest half. (E.g 0.5/0.0 or 0.05/0.00 etc.)
    //Input 99.995 Increment 1 will produce 99.95
    static public Double roundDoubleDown(Double input, Integer increment) {
        Double multiplier = Math.pow(10, increment);
        Double y = input * multiplier;
        Double z = Math.floor(y);
        Double diff = y - z;
        
        if (diff >= 0.5) {
            return (z + 0.5) / multiplier;
        }
        return (z / multiplier);
    }
    
    // check if a double is negative.
    // return 0 if true or itself if false
    static public Double checkNegative(Double input) {
        if ( input < 0 ) {
            return 0;
        }
        return input;
    }
    
    // converts hours and minutes to a decimal (in terms of hours)
    static public Double quantToDecimal(Integer hrs, Integer mnts) {
        String Hours = String.valueOf(hrs);
        Decimal ratio = Decimal.valueOf(String.valueOf(mnts)).divide(60,2);
        String Minutes = String.valueOf(ratio);
        String justMinutes = Minutes.substringAfter('.');
        String quant = Hours  + '.' + justMinutes;
        return Double.valueOf(quant);
    }
    
    // converts seconds to a decimal (in terms of hours)
    static public Double secondsToDecimal(Integer seconds) {
        return Double.valueOf(seconds/3600);
    }
    
    // returns difference between two date time variables in seconds
    static public Long getTimeDiff(DateTime startTime, DateTime endTime) {
        TimeZone tz = UserInfo.getTimeZone();
        DateTime corrected = endTime.addSeconds((tz.getOffset(endTime)/1000));
        
        Long one = corrected.getTime();
        Long two = startTime.getTime();
        Long milli = one - two;
        Long seconds = milli / 1000;
        
        return seconds;
    }
    
    // get a random number between the min and max provided
    static public Integer getRandom(Integer min, Integer max) {
        return Integer.valueOf(Math.floor(Math.random() * (((max-min) + 1) + min) ));
    }
    
    // returns list of selectOption for active client associations for a worker with required filters
    static public List<SelectOption> getClients(Id clinicianId, String[] filters) {
        //String[] filters = new String[]{'%supervision%','%Supervision%','%Better Rehab%'};
        List<SelectOption> clients = new List<SelectOption>();
        
        List<enrtcr__Staff_Allocation__c> contactClients = [SELECT Id, Client__r.Id, Client__r.Name
                                                            FROM enrtcr__Staff_Allocation__c 
                                                            WHERE Clinician__r.Id =: clinicianId 
                                                            AND Clinician_Status__c = 'Active' 
                                                            AND	Client_Status__c = 'Current'
                                                            AND (NOT Client__r.Name LIKE : filters)
                                                           ];
        contactClients.sort();
        for (enrtcr__Staff_Allocation__c cc : contactClients) {
            clients.add(new SelectOption(cc.Client__r.Id, cc.Client__r.Name));
        }
        
        return clients;
    }
    
    // returns list of contact for current workers in the company
    static public List<Contact> getEmployees() {
        return [SELECT id, 
                    Name,
                    FTE__c,
                	FirstName,
                    Direct_Supervisor__c, 
                    Clinical_Supervisor__c, 
                    enrtcr__Status__c, 
                    Clinician_Discipline__c, 
                    New_Framework__c,
                    Internal_Banding__c,
                    enrtcr__User__r.KPI__c,
                    Weeks_Completed__c,
                	enrtcr__Site__r.Business_Country__c
                FROM Contact
                WHERE Record_Type_Name__c = 'Employee'
                	AND enrtcr__Status__c = 'Current'
               ];
    }
    
    // converts JSON string into a queryable Map<String, Object> object
    static public Map<String, Object> JSONtoMap(String jsonString) {
        return (Map<String, Object>) JSON.deserializeUntyped(jsonString);
    }
    
    static public String maptoJSON(Map<String, Object> myMap) {
        return JSON.serialize(myMap);
    }
    
    static public Long daysBetweenDTs(DateTime one, DateTime two) {
        Long dt1Long = one.getTime();
        Long dt2Long = two.getTime();
        Long milliseconds = dt2Long - dt1Long;
        Long seconds = milliseconds / 1000;
        Long minutes = seconds / 60;
        Long hours = minutes / 60;
        Long days = hours / 24;
        
        return days;
    }
    
    static public Long XBetweenDTs(DateTime one, DateTime two, String identifier) {
        Long dt1Long = one.getTime();
        Long dt2Long = two.getTime();
        Long milliseconds = dt2Long - dt1Long;
        Long seconds = milliseconds / 1000;
        Long minutes = seconds / 60;
        Long hours = minutes / 60;
        Long days = hours / 24;
        
        if (identifier == 'milliseconds') return milliseconds;
        else if (identifier == 'seconds') return seconds;
        else if (identifier == 'minutes') return minutes;
        else if (identifier == 'hours') return hours;
        else if (identifier == 'days') return days;
        
        return days;
    }
    
    // accepts GMT String in the form of YYYY-MM-DDTHH:MM:SS.sssZ
    public static DateTime GMTStringToGMTdt(String GMTTime) {
        List<String> fullString = GMTTime.split('T');
        List<String> dateParts = fullString[0].split('-');
        List<String> timeParts = fullString[1].split(':');
        
        Integer year = Integer.valueOf(dateParts[0]);
        Integer month = Integer.valueOf(dateParts[1]);
        Integer day = Integer.valueOf(dateParts[2]);
        Integer hour = Integer.valueOf(timeParts[0]);
        Integer minute = Integer.valueOf(timeParts[1]);
        
        DateTime gmt = DateTime.newInstanceGMT(year, month, day, hour, minute, 0);
        
        return gmt;
    }
}