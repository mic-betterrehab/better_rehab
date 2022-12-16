public class DataSanitizer {
    public static String sanitizeMobileNumber(String mobile) {
        String mobilePrefix = '+61';
    
        //Remove all whitespace
        String sanitizedNumber = mobile.normalizeSpace();
        sanitizedNumber = sanitizedNumber.remove(' ');
        sanitizedNumber = sanitizedNumber.remove(')');
        sanitizedNumber = sanitizedNumber.remove('(');
        sanitizedNumber = sanitizedNumber.remove('-');
        sanitizedNumber = sanitizedNumber.remove('_');
        
        //now we check the length to ensure we're dealing with a correct number
        if (sanitizedNumber.length() == 10 && sanitizedNumber.left(2) == '04') {
            sanitizedNumber = sanitizedNumber.mid(1,mobile.length());
            return String.format('{0}{1}',new String[]{mobilePrefix,sanitizedNumber});
        } else if (sanitizedNumber.length() == 9 && sanitizedNumber.left(1) == '4') {
            return String.format('{0}{1}',new String[]{mobilePrefix,sanitizedNumber});
        } else if (sanitizedNumber.length() == 11 && sanitizedNumber.left(3) == '614') {
            return String.format('+{0}',new String[]{sanitizedNumber});
        }
        return sanitizedNumber;
    }
}