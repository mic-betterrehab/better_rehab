//Nad
//Commonly used audit/validation functions for data
//18/04/2021
public with sharing class Validation { 
    // validate hours for sde creation
    // return false for invalid
    // return true for valid
    static public Boolean validateHours(Integer hours) {
        if ( hours < 0 || hours > 10 || hours == null) {
            return false;
        }
        return true;
    }
    
    // validate minutes for sde creation
    // return false for invalid
    // return true for valid
    static public Boolean validateMinutes(Integer minutes) {
        if ( minutes < 0 || minutes > 60 || minutes == null ) {
            return false;
        }
        return true;
    }

}