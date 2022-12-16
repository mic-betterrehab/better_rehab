@isTest
public class SanitizeUsersTest {
 
	public static testMethod void validateBeforeInsert() {
		
		Profile testProfile = [SELECT Id FROM Profile  WHERE Name='System Administrator' LIMIT 1];
 
		User testUser = new User(
			Username = DateTime.now().getTime() + 'InsertUnitTest@Pendula.com',
			LastName = 'TestUser',
			Email = 'Test@User.com',
			Alias = 'utest',
			CommunityNickName = 'UnitTestUser',
			TimeZoneSidKey = 'Australia/Sydney',
			LocaleSidKey = 'en_AU',
			EmailEncodingKey = 'ISO-8859-1',
			LanguageLocaleKey = 'en_US',
			MobilePhone = '0400000000',
			ProfileId = testProfile.Id
		);
		insert testUser;
 
		User insertedUser = [SELECT MobilePhone FROM User WHERE Id = :testUser.Id];
		System.assertEquals(
			insertedUser.MobilePhone,
			'+61400000000'
		);
 
	}
 
	public static testMethod void validateBeforeUpdate() {
		
		Profile testProfile = [SELECT Id FROM Profile  WHERE Name='System Administrator' LIMIT 1];
 
		User testUser = new User(
            Username = DateTime.now().getTime() + 'InsertUnitTest@Pendula.com',
			LastName = 'TestUser',
			Email = 'Test@User.com',
			Alias = 'utest',
			CommunityNickName = 'UnitTestUser',
			TimeZoneSidKey = 'Australia/Sydney',
			LocaleSidKey = 'en_AU',
			EmailEncodingKey = 'ISO-8859-1',
			LanguageLocaleKey = 'en_US',
			ProfileId = testProfile.Id
		);
		insert testUser;
 
		testUser.MobilePhone = '61400000000';
		update testUser;
		
		User updatedUser = [SELECT MobilePhone FROM User WHERE Id = :testUser.Id];
		System.assertEquals(
			updatedUser.MobilePhone,
			'+61400000000'
		);
 
	}
 
}