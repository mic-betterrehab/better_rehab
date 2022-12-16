public class CalendarController {
    //this class is unique to Better Calendar. For other calendar projects, use EventController and CalendarClass classes to use the global calendar methods and classes
    
    /*
     * 
     * THIS SECTION IS FOR BR CALENDAR CMP
     * 
     * */    
    
    //to get one worker/one client events and load their calendar
    @AuraEnabled
    public static List<Map<String, Object>> getEvents(Id contactId) {
        Contact c = contactId != null ?
                        BR_ContactDAO.getContactById(contactId) :
                        BR_ContactDAO.getContactByLoginUserIdFirstNameAndLastName();
        
        List<Id> contactIds = new List<Id>{c.Id};
        
        //retrieve the setting
        Setting__c cutOff = [SELECT Id, Settings__c FROM Setting__c WHERE Name = 'eventCutoffDate'];
        Map<String, Object> classSettings = Utility.JSONtoMap(cutOff.Settings__c);
        Integer cutOffTime = Integer.valueOf(classSettings.get('Better Calendar'));
        System.debug('cutoff time: ' + cutOffTime);

        return c.Record_Type_Name__c == 'Employee' ? EventController.getWorkerEvents(contactIds, cutOffTime) : EventController.getClientEvents(contactIds, cutOffTime); //review again later
    }

    //for updateEventTime, pass the 'Time Change' string to the event controller
    @AuraEnabled
    public static List<Map<String, String>> updateEventTime(String updateJSON, String action) {
        System.debug('Inside updateEvent calendar controller');
        return EventController.updateEvent(updateJSON, action, 'Time Change');
    }    
	
    //to load the currently logged in user, returning a map of worker and details
    @AuraEnabled
    public static Map<String, String> getWorker(Id workerId) {
       return EventController.getWorker(workerId);
    }
    
     /*
     * 
     * THIS SECTION IS FOR BR CALENDAR CREATE CMP
     * 
     * */
    
    //to find the workers/clients that have a clashing event as the eventJSON
    @AuraEnabled
    public static String[] findClashingWorkerAndClientEvents(String eventJSON){
        // parse event details
        CalendarClass.EventDetail eventObject = (CalendarClass.EventDetail)JSON.deserialize(eventJSON, CalendarClass.EventDetail.Class);
        
        // parse json strings into list of objects - ID, NAME
        List<CalendarClass.Worker> convertedWorkers = (List<CalendarClass.Worker>)JSON.deserialize(eventObject.workers, List<CalendarClass.Worker>.Class);
        List<CalendarClass.Client> convertedClients = (List<CalendarClass.Client>)JSON.deserialize(eventObject.clients, List<CalendarClass.Client>.Class);
        
        return EventController.findClashingWorkerAndClientEvents(eventJSON, eventObject, convertedWorkers, convertedClients);  
    }
    
    //to create a single event
    @AuraEnabled
    public static List<Event> createEvents(String eventJSON, String repeatJSON, String contactPageUser) {
        // parse repeat details
        CalendarClass.RepeatDetail eventRepetition = (CalendarClass.RepeatDetail)JSON.deserialize(repeatJSON, CalendarClass.RepeatDetail.Class);

        // parse event details
        CalendarClass.EventDetail eventObject = (CalendarClass.EventDetail)JSON.deserialize(eventJSON, CalendarClass.EventDetail.Class);

        // parse json strings into list of objects
        List<CalendarClass.Worker> convertedWorkers = (List<CalendarClass.Worker>)JSON.deserialize(eventObject.workers, List<CalendarClass.Worker>.Class);
        List<CalendarClass.Client> convertedClients = (List<CalendarClass.Client>)JSON.deserialize(eventObject.clients, List<CalendarClass.Client>.Class);
        CalendarClass.Site convertedSite = (CalendarClass.Site)JSON.deserialize(eventObject.site, CalendarClass.Site.Class);
        
        return EventController.createEvents(eventRepetition, eventObject, convertedWorkers, convertedClients, convertedSite, contactPageUser);
    }
    
    /*
     * 
     * THIS SECTION IS FOR BR EVENT DETAIL CMP AND BR CALENDAR CMP
     * 
     * */
	
    //to check a user's permission to edit/view an event
    @AuraEnabled
    public static String getEventRelationship(String eventId) {
        return EventController.getEventRelationship(eventId);
     }
    
    /*
     * 
     * THIS SECTION IS FOR BR EVENT DETAIL CMP
     * 
     * */
    
    //for updateEventEditForm, pass the 'Edit Form Change' string to the event controller
    @AuraEnabled
    public static List<Map<String, String>> updateEventEditForm(String updateJSON, String action) {
        System.debug('Inside updateEvent calendar controller');
        return EventController.updateEvent(updateJSON, action, 'Edit Form Change');        
    }
    
    //to handle selection of an event in the calendar UI
    @AuraEnabled
    public static Map<String, Object> getEventMap(Id recordId){
        return EventController.getEventMap(recordId);
    }
    
    
    //to delete a single event
    @AuraEnabled
    public static String deleteAnEvent(Id eventId, String reason) {
        return EventController.deleteAnEvent(eventId, reason);
    }
	
    //to book a single event
    @AuraEnabled
    public static String bookAnEvent(Id eventId) {
        return EventController.bookAnEvent(eventId);
    }
	
    //to book >1 events in a recurrence
    @AuraEnabled
    public static Map<String, String> bookARecurrence(Id eventId) {
        return EventController.bookARecurrence(eventId);
    }
	
    //to delete >1 events in a recurrence
    @AuraEnabled
    public static Map<String, String> deleteARecurrence(Id eventId, String reason) {
        return EventController.deleteARecurrence(eventId, reason);
    }
    
    /*
     * 
     * THIS SECTION IS FOR TABLE PAGINATION, WORKER EVENT RELATIONS, AND CLIENT EVENT RELATIONS CMP
     * 
     * */
    
    @AuraEnabled
    public static List<Map<String, Object>> getCERs(Id eventId) {
        String baseURL = URL.getSalesforceBaseUrl().toExternalForm();
        List<Client_Event_Relation__c> cers = [SELECT id, Event_Link__c, Client__r.Id ,Client__r.Name, Status__c FROM Client_Event_Relation__c WHERE Event_Id__c =: eventId];
        return EventController.createClientList(cers, baseURL);
    }
    
    @AuraEnabled
    public static List<Map<String, Object>> getERs(Id eventId) {
        
        String baseURL = URL.getSalesforceBaseUrl().toExternalForm();
        List<EventRelation> ers = [SELECT Id, Status, Relation.Id, Relation.Name FROM EventRelation WHERE EventId =: eventId];
        return EventController.createWorkerList(ers, baseURL);
    }
    
    @AuraEnabled
    public static List<Map<String, Object>> createCERs(List<String> ids, Id eventId, String action) {
        return EventController.addCERsToAnEvent(ids, eventId, action);
    }
    
    
    @AuraEnabled
    public static List<Map<String, Object>> createERs(List<String> ids, Id eventId, String action) {
        return EventController.addERsToAnEvent(ids, eventId, action);
    }
    
    @AuraEnabled
    public static void handleCERchange(String action, Id CERid, String newStatus, String saveType) {
        EventController.handleCERStatusChange(action, CERid, newStatus, saveType);
    }
    
    @AuraEnabled
    public static void handleERchange(String action, Id ERid, String newStatus, String saveType) {
        EventController.handleERStatusChange(action, ERid, newStatus, saveType);
    }
    
    @AuraEnabled
    public static Event getEvent(Id eventId) {
        return EventController.getEvent(eventId);
    }

}