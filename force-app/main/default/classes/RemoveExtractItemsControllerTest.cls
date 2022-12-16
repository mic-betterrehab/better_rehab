@IsTest
private class RemoveExtractItemsControllerTest {
    @IsTest
    static void testAllRecordsRemoved() {
        Contact c = new Contact(
                LastName = 'test',
                enrtcr__Sex__c = 'Male',
                Birthdate = Date.parse('01/01/1940'),
                enrtcr__Photo__c = '<img src="test" />',
                enrtcr__Secondary_Disability__c = 'test',
                OtherStreet = '123 test Street',
                OtherCity = 'Adelaide',
                OtherState = 'SA',
                OtherPostalCode = '5112',
                enrtcr__Date_Client_Registered__c = Date.today(),
                Phone = '12333333',
                enrtcr__Preferred_Communication_Method__c = 'Phone',
                enrtcr__Primary_Disability__c = 'Autism',
                enrtcr__Status__c = 'Current',
                enrtcr__Summary_Disability__c = 'Autism',
                enrtcr__Requires_Support_for_Decision_Making__c = 'No',
                enrtcr__Client_Region__c = 'Northern',
                MobilePhone = '04111111',
                enrtcr__Palliative_Status__c = 'Stable'
        );

        insert c;

        enrtcr__Extract__c extract = new enrtcr__Extract__c(enrtcr__Start_Date__c=Date.today(), enrtcr__End_Date__c=Date.today());
        insert extract;

        List<enrtcr__Extract_Item__c> extractItems = new List<enrtcr__Extract_Item__c>();
        extractItems.add(new enrtcr__Extract_Item__c(enrtcr__Extract__c = extract.Id, enrtcr__Quantity__c = 0.1, enrtcr__Client_ID__c=c.Id));
        extractItems.add(new enrtcr__Extract_Item__c(enrtcr__Extract__c = extract.Id, enrtcr__Quantity__c = 0.1, enrtcr__Client_ID__c=c.Id));
        extractItems.add(new enrtcr__Extract_Item__c(enrtcr__Extract__c = extract.Id, enrtcr__Quantity__c = 0.1, enrtcr__Client_ID__c=c.Id));
        extractItems.add(new enrtcr__Extract_Item__c(enrtcr__Extract__c = extract.Id, enrtcr__Quantity__c = 0.1, enrtcr__Client_ID__c=c.Id));

        insert extractItems;

        String msg = RemoveExtractItemsController.removeExtractItems(extract.Id);
        System.assertEquals(String.format(RemoveExtractItemsController.NUMBER_RECORDS_REMOVED, new List<String> {String.valueOf(extractItems.size())}), msg);

    }

    @IsTest
    static void testNoRecordsDeleted() {
        Contact c = new Contact(
                LastName = 'test',
                enrtcr__Sex__c = 'Male',
                Birthdate = Date.parse('01/01/1940'),
                enrtcr__Photo__c = '<img src="test" />',
                enrtcr__Secondary_Disability__c = 'test',
                OtherStreet = '123 test Street',
                OtherCity = 'Adelaide',
                OtherState = 'SA',
                OtherPostalCode = '5112',
                enrtcr__Date_Client_Registered__c = Date.today(),
                Phone = '12333333',
                enrtcr__Preferred_Communication_Method__c = 'Phone',
                enrtcr__Primary_Disability__c = 'Autism',
                enrtcr__Status__c = 'Current',
                enrtcr__Summary_Disability__c = 'Autism',
                enrtcr__Requires_Support_for_Decision_Making__c = 'No',
                enrtcr__Client_Region__c = 'Northern',
                MobilePhone = '04111111',
                enrtcr__Palliative_Status__c = 'Stable'
        );

        insert c;

        enrtcr__Extract__c extract = new enrtcr__Extract__c(enrtcr__Start_Date__c=Date.today(), enrtcr__End_Date__c=Date.today());
        insert extract;

        List<enrtcr__Extract_Item__c> extractItems = new List<enrtcr__Extract_Item__c>();
        extractItems.add(new enrtcr__Extract_Item__c(enrtcr__Extract__c = extract.Id, enrtcr__Quantity__c = 0.1, enrtcr__Client_ID__c=c.Id));
        extractItems.add(new enrtcr__Extract_Item__c(enrtcr__Extract__c = extract.Id, enrtcr__Quantity__c = 0.1, enrtcr__Client_ID__c=c.Id));
        extractItems.add(new enrtcr__Extract_Item__c(enrtcr__Extract__c = extract.Id, enrtcr__Quantity__c = 0.1, enrtcr__Client_ID__c=c.Id));
        extractItems.add(new enrtcr__Extract_Item__c(enrtcr__Extract__c = extract.Id, enrtcr__Quantity__c = 0.1, enrtcr__Client_ID__c=c.Id));
        extractItems.add(new enrtcr__Extract_Item__c(enrtcr__Extract__c = extract.Id, enrtcr__Quantity__c = 0.1, enrtcr__Client_ID__c=c.Id));
        extractItems.add(new enrtcr__Extract_Item__c(enrtcr__Extract__c = extract.Id, enrtcr__Quantity__c = 0.1, enrtcr__Client_ID__c=c.Id));
        extractItems.add(new enrtcr__Extract_Item__c(enrtcr__Extract__c = extract.Id, enrtcr__Quantity__c = 0.1, enrtcr__Client_ID__c=c.Id));
        extractItems.add(new enrtcr__Extract_Item__c(enrtcr__Extract__c = extract.Id, enrtcr__Quantity__c = 0.1, enrtcr__Client_ID__c=c.Id));

        insert extractItems;

        String msg = RemoveExtractItemsController.removeExtractItems(extract.Id);
        System.assertEquals(RemoveExtractItemsController.NO_RECORDS_DELETED, msg);
    }

    @IsTest
    static void testHalfDelete() {
        List<Contact> contacts = new List<Contact>();

        Contact c = new Contact(
                LastName = 'test',
                enrtcr__Sex__c = 'Male',
                Birthdate = Date.parse('01/01/1940'),
                enrtcr__Photo__c = '<img src="test" />',
                enrtcr__Secondary_Disability__c = 'test',
                OtherStreet = '123 test Street',
                OtherCity = 'Adelaide',
                OtherState = 'SA',
                OtherPostalCode = '5112',
                enrtcr__Date_Client_Registered__c = Date.today(),
                Phone = '12333333',
                enrtcr__Preferred_Communication_Method__c = 'Phone',
                enrtcr__Primary_Disability__c = 'Autism',
                enrtcr__Status__c = 'Current',
                enrtcr__Summary_Disability__c = 'Autism',
                enrtcr__Requires_Support_for_Decision_Making__c = 'No',
                enrtcr__Client_Region__c = 'Northern',
                MobilePhone = '04111111',
                enrtcr__Palliative_Status__c = 'Stable'
        );

        contacts.add(c);

        Contact c2 = new Contact(
                LastName = 'yeah',
                FirstName='Buddy',
                enrtcr__Sex__c = 'Male',
                Birthdate = Date.parse('01/01/1940'),
                enrtcr__Photo__c = '<img src="test" />',
                enrtcr__Secondary_Disability__c = 'test',
                OtherStreet = '123 test Street',
                OtherCity = 'Adelaide',
                OtherState = 'SA',
                OtherPostalCode = '5112',
                enrtcr__Date_Client_Registered__c = Date.today(),
                Phone = '12333333',
                enrtcr__Preferred_Communication_Method__c = 'Phone',
                enrtcr__Primary_Disability__c = 'Autism',
                enrtcr__Status__c = 'Current',
                enrtcr__Summary_Disability__c = 'Autism',
                enrtcr__Requires_Support_for_Decision_Making__c = 'No',
                enrtcr__Client_Region__c = 'Northern',
                MobilePhone = '04111111',
                enrtcr__Palliative_Status__c = 'Stable'
        );

        contacts.add(c2);


        insert contacts;

        enrtcr__Extract__c extract = new enrtcr__Extract__c(enrtcr__Start_Date__c=Date.today(), enrtcr__End_Date__c=Date.today());
        insert extract;

        List<enrtcr__Extract_Item__c> extractItems = new List<enrtcr__Extract_Item__c>();
        extractItems.add(new enrtcr__Extract_Item__c(enrtcr__Extract__c = extract.Id, enrtcr__Quantity__c = 0.1, enrtcr__Client_ID__c=c.Id));
        extractItems.add(new enrtcr__Extract_Item__c(enrtcr__Extract__c = extract.Id, enrtcr__Quantity__c = 0.1, enrtcr__Client_ID__c=c.Id));
        extractItems.add(new enrtcr__Extract_Item__c(enrtcr__Extract__c = extract.Id, enrtcr__Quantity__c = 0.1, enrtcr__Client_ID__c=c.Id));
        extractItems.add(new enrtcr__Extract_Item__c(enrtcr__Extract__c = extract.Id, enrtcr__Quantity__c = 0.1, enrtcr__Client_ID__c=c.Id));
        extractItems.add(new enrtcr__Extract_Item__c(enrtcr__Extract__c = extract.Id, enrtcr__Quantity__c = 0.1, enrtcr__Client_ID__c=c.Id));
        extractItems.add(new enrtcr__Extract_Item__c(enrtcr__Extract__c = extract.Id, enrtcr__Quantity__c = 0.1, enrtcr__Client_ID__c=c.Id));
        extractItems.add(new enrtcr__Extract_Item__c(enrtcr__Extract__c = extract.Id, enrtcr__Quantity__c = 0.1, enrtcr__Client_ID__c=c.Id));
        extractItems.add(new enrtcr__Extract_Item__c(enrtcr__Extract__c = extract.Id, enrtcr__Quantity__c = 0.1, enrtcr__Client_ID__c=c.Id));

        extractItems.add(new enrtcr__Extract_Item__c(enrtcr__Extract__c = extract.Id, enrtcr__Quantity__c = 0.1, enrtcr__Client_ID__c=c2.Id));
        extractItems.add(new enrtcr__Extract_Item__c(enrtcr__Extract__c = extract.Id, enrtcr__Quantity__c = 0.1, enrtcr__Client_ID__c=c2.Id));
        extractItems.add(new enrtcr__Extract_Item__c(enrtcr__Extract__c = extract.Id, enrtcr__Quantity__c = 0.1, enrtcr__Client_ID__c=c2.Id));
        extractItems.add(new enrtcr__Extract_Item__c(enrtcr__Extract__c = extract.Id, enrtcr__Quantity__c = 0.1, enrtcr__Client_ID__c=c2.Id));

        insert extractItems;

        String msg = RemoveExtractItemsController.removeExtractItems(extract.Id);
        System.assertEquals(String.format(RemoveExtractItemsController.NUMBER_RECORDS_REMOVED, new List<String> {String.valueOf(4)}), msg);

        RemoveExtractItemsController.deleteAllExtractItemsNotApproved(extract.Id);
    }
}