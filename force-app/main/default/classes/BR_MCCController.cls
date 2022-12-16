public class BR_MCCController {
 	//this class is unique to Better Calendar. For other calendar projects, use EventController and CalendarClass classes to use the global calendar methods and classes

    /*
     *
     * THIS SECTION IS FOR BR MCC CMP
     *
     * */
    @AuraEnabled
    public static Map<String, Object> getClinicianAndEvents(String today) {
        Contact loggedInUser = BR_ContactDAO.getWorkerContactByLoggedInUserId();
        List<Contact> workers = new List<Contact>{loggedInUser};

        return formatResponse(workers, today);
    }

    @AuraEnabled
    public static Map<String, Object> getClinicianAndEventsBySite(String today, String site) {
        List<Contact> workers = BR_ContactDAO.getWorkersBySite(site);

        return formatResponse(workers, today);
    }

    @AuraEnabled
    public static Map<String, Object> getClinicianAndEventsByDiscipline(String today, String discipline) {
		List<Contact> workers = BR_ContactDAO.getWorkersByDiscipline(discipline);
		
        return formatResponse(workers, today);
    }

    @AuraEnabled
    public static Map<String, Object> getClinicianAndEventsBySiteAndDiscipline(String today, String site, String discipline) {
        List<Contact> workers = BR_ContactDAO.getWorkersBySiteAndDiscipline(site, discipline);

        return formatResponse(workers, today);
    }

    @AuraEnabled
    public static Map<String, Object> getContactWithMultipleFilter(String today, String site, String discipline, String multiLookup) {
        List<Worker> stringWorkers = (List<Worker>)JSON.deserialize(multiLookup, List<Worker>.Class);
        Set<String> workerIds = new Set<String>();

        for (Worker w : stringWorkers) {
            workerIds.add(w.Id);
        }

        List<Contact> workers = new List<Contact>();

        if (String.isBlank(site)) {
            workers = BR_ContactDAO.getWorkersByDisciplineAndMultiLookup(discipline, workerIds);
        } else if (String.isBlank(discipline)) {
            workers = BR_ContactDAO.getWorkersBySiteAndMultiLookup(site, workerIds);
        } else {
            workers = BR_ContactDAO.getListWorkerContactByMultipleFilter(site, discipline, workerIds);
        }

        return formatResponse(workers, today);
    }

    @AuraEnabled
    public static Map<String, Object> getClinicianAndEventsByMultiLookup(String today, String multiLookup) {
        List<CalendarClass.Worker> stringWorkers = (List<CalendarClass.Worker>)JSON.deserialize(multiLookup, List<CalendarClass.Worker>.Class);
        Set<String> workerIds = new Set<String>();

        for (CalendarClass.Worker w : stringWorkers) {
            workerIds.add(w.Id);
        }

        List<Contact> workers = BR_ContactDAO.getListWorkerContactById(workerIds);

        return formatResponse(workers, today);
    }

    @AuraEnabled
    public static Map<String, Object> getEventsByDate(String startDate, String endDate, List<String> workerIds) {
        Set<Id> workerSetIds = new Set<Id>();

        for (String id : workerIds) {
            workerSetIds.add(id);
        }

        List<EventRelation> events = BR_EventRelationDAO.getWorkerEventsByDate(workerSetIds, startDate, endDate);
        List<Map<String, Object>> mapEvents = formatEvents(events);

        return new Map<String, Object>{
            'events' => mapEvents
        };
    }

    @TestVisible
    private static Map<String, Object> formatResponse(List<Contact> workers, String today) {
        Contact loggedInUser = BR_ContactDAO.getWorkerContactByLoggedInUserId();
        List<Map<String, Object>> clinicians = new List<Map<String, Object>>();
        Set<Id> workerIds = new Set<Id>();
        List<Map<String, Object>> mapEvents = new List<Map<String, Object>>();

        if (workers.size() > 0) {
            for (Contact con : workers) {
                Map<String,Object> o = new Map<String,Object>();
                o.put('Id', con.Id);
                o.put('id', con.Id);
                o.put('Name', con.Name);
                o.put('title', con.Name);
                o.put('siteId', con.enrtcr__Site__c);
                o.put('siteName', con.enrtcr__Site__r.Name);
                o.put('userId', con.enrtcr__User__c);
                o.put('region', con.enrtcr__Site__r.enrtcr__Business_State__c);

                workerIds.add(con.Id);
                clinicians.add(o);
            }

            List<EventRelation> events = BR_EventRelationDAO.getWorkerLastNextSevenDaysEventsById(workerIds, today);
            mapEvents = formatEvents(events);
        }

        return new Map<String, Object>{
            'clinicians' => clinicians,
            'events' => mapEvents,
            'loggedInUser' => loggedInUser
        };
    }

    @TestVisible
    private static List<Map<String, Object>> formatEvents(List<EventRelation> events) {
        List<Map<String, Object>> mapEvents = new List<Map<String, Object>>();

        for (EventRelation er : events) {
            Map<String,Object> o = new Map<String,Object>();

            if (!String.isEmpty(EventController.translateStatus(er.Status))) {
                o.put('id', er.id);
                o.put('eventId', er.Event.Id);
                o.put('title', er.Event.Subject);
                o.put('resourceId', er.RelationId);
                o.put('OwnerId', er.Event.OwnerId);
                o.put('start', er.Event.StartDateTime);
                o.put('end', er.Event.EndDateTime);
                o.put('startTime', er.Event.StartDateTime);
                o.put('endTime', er.Event.EndDateTime);
                o.put('enrtcr__Client__c', er.Event.enrtcr__Client__c);
                o.put('Event_Type__c', er.Event.Event_Type__c);
                o.put('Event_Status__c', EventController.translateStatus(er.Status));
                o.put('allDay', er.Event.IsAllDayEvent);
                o.put('isRecurrence__c', er.Event.isRecurrence__c);
                mapEvents.add(o);
            }
        }

        return mapEvents;
    }

    Class Worker {
        String Id;
        String Name;
    }
}