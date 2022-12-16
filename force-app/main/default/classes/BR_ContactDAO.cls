public with sharing class BR_ContactDAO {
    public static Contact getContactById(Id contactId) {
        return [SELECT Id, Record_Type_Name__c, enrtcr__User__c FROM Contact WHERE id =: contactId];
    }

    public static Contact getContactByLoginUserIdFirstNameAndLastName() {
        return [
            SELECT Id, Record_Type_Name__c, enrtcr__User__c
            FROM Contact
            WHERE enrtcr__User__c =: UserInfo.getUserId()
            AND (FirstName =: UserInfo.getFirstName() AND LastName =: UserInfo.getLastName())
        ];
    }

    public static Contact getWorkerContactById(Id workerId) {
        return [
            SELECT
                Id,
                Name,
                enrtcr__Site__c,
                enrtcr__Site__r.Name,
                enrtcr__Site__r.enrtcr__Business_Address_1__c,
                enrtcr__User__c,
                enrtcr__User__r.Profile.Name,
                Record_Type_Name__c
            FROM Contact
            WHERE Id =: workerId
        ];
    }

    public static Contact getWorkerContactByLoggedInUserId() {
        return [
            SELECT
                Id,
                Name,
                enrtcr__Site__c,
                enrtcr__Site__r.Name,
                enrtcr__Site__r.enrtcr__Business_Address_1__c,
                enrtcr__Site__r.enrtcr__Business_State__c,
                enrtcr__User__c,
                enrtcr__User__r.Profile.Name,
                Record_Type_Name__c
            FROM Contact
            WHERE enrtcr__User__c =: UserInfo.getUserId()
        ];
    }

    public static List<Contact> getWorkersByRegion(String region) {
        return [
            SELECT
                Id,
                Name,
                enrtcr__Site__c,
                enrtcr__Site__r.Name,
                enrtcr__Site__r.enrtcr__Business_State__c,
                enrtcr__Region__c,
                enrtcr__User__c,
                enrtcr__User__r.Profile.Name,
                Record_Type_Name__c
            FROM Contact
            WHERE enrtcr__Client_Region__c =: region
            AND Record_Type_Name__c = 'Employee'
        ];
    }

    public static List<Contact> getWorkersBySite(String site) {
        return [
            SELECT
                Id,
                Name,
                enrtcr__Site__c,
                enrtcr__Site__r.Name,
                enrtcr__Site__r.enrtcr__Business_State__c,
                enrtcr__Region__c,
                enrtcr__User__c,
                enrtcr__User__r.Profile.Name,
                Record_Type_Name__c
            FROM Contact
            WHERE enrtcr__Status__c = 'Current'
            AND (enrtcr__Office__c =: site OR enrtcr__Site__r.Name =: site)
            AND Record_Type_Name__c = 'Employee'
        ];
    }

    public static List<Contact> getWorkersByDiscipline(String discipline) {
        return [
            SELECT
                Id,
                Name,
                enrtcr__Site__c,
                enrtcr__Site__r.Name,
                enrtcr__Site__r.enrtcr__Business_State__c,
                enrtcr__Region__c,
                enrtcr__User__c,
                enrtcr__User__r.Profile.Name,
                Record_Type_Name__c
            FROM Contact
            WHERE enrtcr__Status__c = 'Current'
            AND (Clinician_Discipline__c =: discipline OR Additional_Disciplines__c INCLUDES(:discipline))
            AND Record_Type_Name__c = 'Employee'
        ];
    }

    public static List<Contact> getWorkersBySiteAndDiscipline(String site, String discipline) {
        return [
            SELECT
                Id,
                Name,
                enrtcr__Site__c,
                enrtcr__Site__r.Name,
                enrtcr__Site__r.enrtcr__Business_State__c,
                enrtcr__Region__c,
                enrtcr__User__c,
                enrtcr__User__r.Profile.Name,
                Record_Type_Name__c
            FROM Contact
            WHERE enrtcr__Status__c = 'Current'
            AND (enrtcr__Office__c =: site OR enrtcr__Site__r.Name =: site)
            AND (Clinician_Discipline__c =: discipline OR Additional_Disciplines__c INCLUDES(:discipline))
            AND Record_Type_Name__c = 'Employee'
        ];
    }

    public static List<Contact> getListWorkerContactById(Set<String> workerId) {
        return [
            SELECT
                Id,
                Name,
                enrtcr__Site__c,
                enrtcr__Site__r.Name,
                enrtcr__Site__r.enrtcr__Business_State__c,
                enrtcr__Region__c,
                enrtcr__User__c,
                enrtcr__User__r.Profile.Name,
                Record_Type_Name__c
            FROM Contact
            WHERE enrtcr__Status__c = 'Current'
            AND Id IN: workerId
        ];
    }

    public static List<Contact> getWorkersBySiteAndMultiLookup(String site, Set<String> workerId) {
        return [
            SELECT
                Id,
                Name,
                enrtcr__Site__c,
                enrtcr__Site__r.Name,
                enrtcr__Site__r.enrtcr__Business_State__c,
                enrtcr__Region__c,
                enrtcr__User__c,
                enrtcr__User__r.Profile.Name,
                Record_Type_Name__c
            FROM Contact
            WHERE enrtcr__Status__c = 'Current'
            AND ((enrtcr__Office__c =: site OR enrtcr__Site__r.Name =: site) OR Id IN: workerId)
            AND Record_Type_Name__c = 'Employee'
        ];
    }

    public static List<Contact> getWorkersByDisciplineAndMultiLookup(String discipline, Set<String> workerId) {
        return [
            SELECT
                Id,
                Name,
                enrtcr__Site__c,
                enrtcr__Site__r.Name,
                enrtcr__Site__r.enrtcr__Business_State__c,
                enrtcr__Region__c,
                enrtcr__User__c,
                enrtcr__User__r.Profile.Name,
                Record_Type_Name__c
            FROM Contact
            WHERE enrtcr__Status__c = 'Current'
            AND ((Clinician_Discipline__c =: discipline OR Additional_Disciplines__c INCLUDES(:discipline)) OR Id IN: workerId)
            AND Record_Type_Name__c = 'Employee'
        ];
    }

    public static List<Contact> getListWorkerContactByMultipleFilter(String site, String discipline, Set<String> workerId) {
        return [
            SELECT
                Id,
                Name,
                enrtcr__Site__c,
                enrtcr__Site__r.Name,
                enrtcr__Site__r.enrtcr__Business_State__c,
                enrtcr__Region__c,
                enrtcr__User__c,
                enrtcr__User__r.Profile.Name,
                Record_Type_Name__c
            FROM Contact
            WHERE enrtcr__Status__c = 'Current'
            AND ((
                    (Clinician_Discipline__c =: discipline OR Additional_Disciplines__c INCLUDES(:discipline)) AND
                    (enrtcr__Office__c =: site OR enrtcr__Site__r.Name =: site)
                ) OR Id IN: workerId
            )
            AND Record_Type_Name__c = 'Employee'
        ];
    }

    public static List<Contact> getContactByFirstNameLastName(String firstName, String lastName) {
        return [
            SELECT Id, Record_Type_Name__c, enrtcr__User__c
            FROM Contact
            WHERE enrtcr__Status__c = 'Current'
            AND (FirstName =: firstName AND LastName =: lastName)
        ];
    }
}