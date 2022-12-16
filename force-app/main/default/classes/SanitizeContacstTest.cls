@isTest
public class SanitizeContacstTest {
 
	public static testMethod void validateBeforeInsert() {
		
		Contact testContact = new Contact(
            MobilePhone = '0400000000',
			LastName = 'TestName'
		);
        insert testContact;
        
		Contact insertedContact = [SELECT MobilePhone FROM Contact WHERE Id = :testContact.Id];
		System.assertEquals(
			insertedContact.MobilePhone,
			'+61400000000'
		);
	}
 
	public static testMethod void validateBeforeUpdate() {
		
		Contact testContact = new Contact(
			LastName = 'TestName'
		);
        insert testContact;
 
		testContact.MobilePhone = '0400000000';
		update testContact;
 
		Contact updatedContact = [SELECT MobilePhone FROM Contact WHERE Id = :testContact.Id];
		System.assertEquals(
			updatedContact.MobilePhone,
			'+61400000000'
		);
 
	}
 
}