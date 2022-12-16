@isTest
public class DataSanitizerTest {
    
    public static testMethod void validateSanitizeMobileNumber() {
        System.assertEquals(
            '+61400000000',
            DataSanitizer.sanitizeMobileNumber('0400000000'),
            'Failed to sanitize leading 04 phone number'
        );
    
        System.assertEquals(
            '+61400000000',
            DataSanitizer.sanitizeMobileNumber('400000000'),
            'Failed to sanitize leading 4 phone number'
        );
    
        System.assertEquals(
            '+61400000000',
            DataSanitizer.sanitizeMobileNumber('61400000000'),
            'Failed to sanitize leading 614 phone number'
        );
    
        System.assertEquals(
            '+61400000000',
            DataSanitizer.sanitizeMobileNumber('0 4 0 0 0 0 0 0 0 0'),
            'Failed to sanitize spaced 04 phone number'
        );
    
        System.assertEquals(
            '+61400000000',
            DataSanitizer.sanitizeMobileNumber('04)00000000'),
            'Failed to sanitize ( phone number'
        );
 
        System.assertEquals(
            '+61400000000',
            DataSanitizer.sanitizeMobileNumber('0400)000000'),
            'Failed to sanitize ) phone number'
        );
 
        System.assertEquals(
            '+61400000000',
            DataSanitizer.sanitizeMobileNumber('0-40-00-00000'),
            'Failed to sanitize - phone number'
        );
 
        System.assertEquals(
            '+61400000000',
            DataSanitizer.sanitizeMobileNumber('04_000_00000'),
            'Failed to sanitize _ phone number'
        );
 
        System.assertEquals(
            '+61400000000',
            DataSanitizer.sanitizeMobileNumber('(+61) 4000-000_00'),
            'Failed to sanitize a complex phone number'
        );
 
        System.assertEquals(
            '0',
            DataSanitizer.sanitizeMobileNumber('0'),
            'Failed to not sanitize a non phone number'
        );
    }
}