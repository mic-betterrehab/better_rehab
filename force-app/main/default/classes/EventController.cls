public with sharing class EventController {

    /*
     *
     * METHODS FOR EVENTS
     *
     * */

    //get one event
    public static Event getEvent(Id eventId) {
        return [SELECT id, subject, isRecurrence__c, Event_Status__c, OwnerId, Event_Type__c FROM Event WHERE id =: eventId];
    }

    //getting event map
    public static Map<String, Object> getEventMap(Id recordId){
        Event e = [SELECT
                   	id,
                   	Subject,
                   	Event_Status__c,
                   	Event_Type__c,
                   	Event_Address__c,
                   	OwnerId,
                   	Owner.Name,
                   	StartDateTime,
                   	EndDateTime,
                   	IsAllDayEvent,
                   	isRecurrence__c,
                   	Event_Recurrence__c,
                   	Cancellation_Reason__c,
                   	Number_of_Workers__c,
                   	Number_of_Clients__c,
                   	Is_Re_engagement__c,
                   	Meeting_Link__c,
                    Mode_of_Delivery__c,
                   	Comments__c,
                   	CreatedDate,
                   	LastModifiedDate,
                   	CreatedBy.Name,
                   	CreatedById,
                   	LastModifiedBy.Name,
                   	LastModifiedById
                   FROM Event
                   WHERE id =: recordId
                  ];

        List<Client_Event_Relation__c> cers = [SELECT id, Client__r.Name, Status__c, Client__c FROM Client_Event_Relation__c WHERE Event_Id__c =: recordId];
        List<EventRelation> ers = [SELECT id, Relation.Name, Status, RelationId FROM EventRelation WHERE EventId =: recordId AND Relation.Name != 'Contact to share events'];

        return createEventDetail(e, cers, ers);
    }

    //convert 1 event and its list of cers and ers into an event map that the front end can use
    private static Map<String, Object> createEventDetail(Event e, List<Client_Event_Relation__c> cers, List<EventRelation> ers) {
        Map<String, Object> mp = new Map<String,Object>();
        String baseURL = URL.getSalesforceBaseUrl().toExternalForm();

        List<Map<String, Object>> clients = createClientList(cers, baseURL);
        List<Map<String, Object>> workers = createWorkerList(ers, baseURL);

        mp.put('id', e.Id);
        mp.put('subject', e.Subject);
        mp.put('address', e.Event_Address__c);
        mp.put('ownerLink', baseURL + '/' + e.OwnerId);
        mp.put('ownerName', e.Owner.Name);
        mp.put('ownerId', e.OwnerId);
        mp.put('allDay', e.IsAllDayEvent);
        mp.put('start', e.StartDateTime);
        mp.put('end', e.EndDateTime);
        mp.put('isRecurrence', e.isRecurrence__c);
        mp.put('recurrenceId', e.Event_Recurrence__c);
        mp.put('recurrenceLink', baseURL + '/' + e.Event_Recurrence__c);
        mp.put('eventType', e.Event_Type__c);
        mp.put('eventStatus', e.Event_Status__c);
        mp.put('cancellationReason', e.Cancellation_Reason__c);
        mp.put('numWorkers', e.Number_of_Workers__c);
        mp.put('numClients', e.Number_of_Clients__c);
        mp.put('isReengagement', e.Is_Re_engagement__c);
        mp.put('createByName', e.CreatedBy.Name);
        mp.put('createByLink', baseURL + '/' + e.CreatedById);
        mp.put('modifiedName', e.LastModifiedBy.Name);
        mp.put('modifiedLink', baseURL + '/' + e.LastModifiedById);
		mp.put('clients', clients);
        mp.put('workers', workers);
        mp.put('ownerLookup', new Map<String, String>{'Id' => e.OwnerId, 'Name' => e.Owner.Name});
        mp.put('comments', e.Comments__c);
        mp.put('createdDate', e.CreatedDate);
        mp.put('lastModifiedDate', e.LastModifiedDate);
        mp.put('link', e.Meeting_Link__c);
        mp.put('mode', e.Mode_of_Delivery__c);

        return mp;
    }

    //convert cers into a list of maps
    public static List<Map<String, Object>> createClientList(List<Client_Event_Relation__c> cers, String baseURL) {
        List<Map<String, Object>> lmp = new List<Map<String, Object>>();

        for (Client_Event_Relation__c o : cers) {

            Map<String, Object> obj = new Map<String, Object>();

            obj.put('id', o.Id);
            obj.put('name', o.Client__r.Name);
            obj.put('lookupId', o.Client__r.Id);
            obj.put('status', o.Status__c);
            obj.put('type', 'CER');
            obj.put('cerLink', baseURL + '/' + o.Id);
            obj.put('contactLink', baseURL + '/' + o.Client__r.Id);

            lmp.add(obj);

        }

        return lmp;
    }

    //convert ers into a list of maps but with less string
    public static List<Map<String, Object>> createWorkerList(List<EventRelation> ers, String baseURL) {
        List<Map<String, Object>> lmp = new List<Map<String, Object>>();

        for (EventRelation o : ers) {

            if (o.Relation.Name == 'Contact to share events') continue;

            Map<String, Object> obj = new Map<String, Object>();

            obj.put('id', o.Id);
            obj.put('name', o.Relation.Name);
            obj.put('lookupId', o.Relation.Id);
            obj.put('status',translateStatus(o.Status));
            obj.put('type', 'ER');
            obj.put('cerLink', baseURL + '/' + o.Id); //er doesn't have a link anyway
            obj.put('contactLink', baseURL + '/' + o.Relation.Id);

            lmp.add(obj);
        }

        return lmp;
    }

    //to create events (this is the entry point of create event)
    public static List<Event> createEvents(CalendarClass.RepeatDetail eventRepetition, CalendarClass.EventDetail eventObject, List<CalendarClass.Worker> convertedWorkers,
                                            List<CalendarClass.Client> convertedClients, CalendarClass.Site convertedSite, String contactPageUser)
    {
        //broken up into 3 separate functions
        List<Event> eventsCreated = createEventsOnly(eventRepetition, eventObject, convertedWorkers, convertedClients, convertedSite, contactPageUser); //this will create and insert the list of events so we can get the event ID for ER and CER
        List<EventRelation> ers = createERs(eventsCreated, convertedWorkers, eventObject.status);
        List<Client_Event_Relation__c> cers = createCERs(eventsCreated, convertedClients, eventObject.status);

        try {
            insert ers;
            insert cers;
        } catch (DMLException error) {
            System.debug(error.getMessage());
        }

        return eventsCreated;
    }

    //for event creation form - this will create and insert the list of events so we can get the event ID for ER and CER
    private static List<Event> createEventsOnly(CalendarClass.RepeatDetail eventRepetition, CalendarClass.EventDetail eventObject, List<CalendarClass.Worker> convertedWorkers,
                                           List<CalendarClass.Client> convertedClients, CalendarClass.Site convertedSite, String contactPageUser)
    {
        Contact shareContact = [SELECT Id FROM Contact WHERE Name = 'Contact to share events' LIMIT 1];

        List<Event> eventsCreated = new List<Event>();

        // a recurrence is being created
        if (eventRepetition.repeat) {
            System.debug('here recurring events');
            //create event recurrence object
            Event_Recurrence__c event_recur = new Event_Recurrence__c();
            insert event_recur;

            List<DateTime> recurrenceTimes = new List<DateTime>();

            DateTime start;
            DateTime ending;
            Integer duration;

            //if event is not all day
            if (!eventObject.allDay) {
                start = eventObject.startTime.right(1) == 'Z' ? convertToLocal(eventObject.startTime) : convertToDateTime(eventObject.startTime, eventObject.allDay);
                ending = eventObject.endTime.right(1) == 'Z' ? convertToLocal(eventObject.endTime) : convertToDateTime(eventObject.endTime, eventObject.allDay);
                duration = ((ending.getTime() - start.getTime()) / 60000).intValue();
            } else {
                //if event is all day
                // both conversions use startTime for all day event to prevent multi day all day events (occurs if a user selects range across multiple days)
                if (eventObject.startTime.length() == 10) { //10 is YYYY-MM-DD, click through calendar UI
                    start = dateStringToDate(eventObject.startTime);
                    ending = dateStringToDate(eventObject.startTime);
                } else if (eventObject.startTime.right(1) == 'Z') { //if user uses the create form
                    start = convertToLocal(eventObject.startTime);
                    ending = convertToLocal(eventObject.startTime);
                } else { //Calendar UI
                    start = convertToDate(eventObject.startTime);
                    ending = convertToDate(eventObject.startTime);
                }
                duration = 1440;
            }

            //capping the number of weeks/days/months interval
            Integer freq = Integer.valueOf(eventRepetition.repeatFrequency) < 200 ? Integer.valueOf(eventRepetition.repeatFrequency) : 200;

            if(eventRepetition.repeatTime == 'Day' || (eventRepetition.repeatTime == 'Week' && eventRepetition.repeatDays.size() == 0)){
                Integer period = getPeriodInteger(eventRepetition.repeatTime); //convert day,week,month to x days

                if (eventRepetition.onAfter == 'On') {
                    Date endsAt = eventRepetition.onDate.addDays(1); //the date that repeat is over
                    Date startsAt =  convertToDate(eventObject.startTime); //selected start date
                    Integer i = 0;
                    Integer daysBetween = (startsAt.daysBetween(endsAt) + 1) < 100 ? startsAt.daysBetween(endsAt) : 100 ; //if days between is >100, it will cap to only 100 days + start date
                    DateTime toAdd = start;
                    while (i < daysBetween) {
                        recurrenceTimes.add(toAdd);
                        toAdd = toAdd.addDays(freq * period); //freq = repeat every, period = integer in days
                        i = i + (freq * period);
                    }
                } else if (eventRepetition.onAfter == 'After') {
                    for (Integer i = 0 ; i < Integer.valueOf(eventRepetition.numberEvents) ; i++) {
                        DateTime toAdd = start.addDays(freq * period  * i);
                        recurrenceTimes.add(toAdd);
                    }
                }
            }

            if(eventRepetition.repeatTime == 'Week' && eventRepetition.repeatDays.size() != 0){
                DateTime startDateTimeFromEvent = start;
                Date startOfTheWeek = date.newinstance(startDateTimeFromEvent.year(), startDateTimeFromEvent.month(), startDateTimeFromEvent.day()).toStartOfWeek();
                DateTime convertedStartWeek = DateTime.newInstance(startOfTheWeek.year(), startOfTheWeek.month(), startOfTheWeek.day(), startDateTimeFromEvent.hour(), startDateTimeFromEvent.minute(), startDateTimeFromEvent.second());
                Date startsAt =  convertToDate(eventObject.startTime);

                if (eventRepetition.onAfter == 'On'){

                    Date endsAt = eventRepetition.onDate.addDays(1); //the date that repeat is over

                    Integer i = 0;
                    Integer daysBetween = (startsAt.daysBetween(endsAt) + 1) < 100 ? startsAt.daysBetween(endsAt) : 100 ;

                    while (i <= daysBetween) {
                        System.debug('current start of the week: ' + convertedStartWeek);

                        for(Integer j = 0; j <= 7; j++){
                            DateTime dt = convertedStartWeek.addDays(j);
                            //if the date is in the future (of now) and the date is in the future of the cursor (a.k.a start) and the date is before the repetition end date
                            if(System.now() <= dt && startDateTimeFromEvent <= dt && endsAt >= dt){
                                if(eventRepetition.repeatDays.contains(dt.format('EEEE'))){
                                    recurrenceTimes.add(dt);
                                }
                            }
                        }

                        convertedStartWeek = convertedStartWeek.addDays(freq * getPeriodInteger(eventRepetition.repeatTime));
                        i = i + (freq * getPeriodInteger(eventRepetition.repeatTime));
                    }
                } else if (eventRepetition.onAfter == 'After'){
                    //find the weeks between
                    Decimal numberOfWeeks = 0;
                    //example: max 6 events % number of repeating days (e.g. M/F): 2
                    if(Math.Mod(Integer.valueOf(eventRepetition.numberEvents), eventRepetition.repeatDays.size()) == 0){
                        numberOfWeeks = (Decimal.valueOf(eventRepetition.numberEvents)/eventRepetition.repeatDays.size()).round(System.RoundingMode.CEILING) + (freq - 1);
                    } else {
                        //example: max 5 events % number of repeating days (e.g. M/F): 2
                        numberOfWeeks = (Decimal.valueOf(eventRepetition.numberEvents)/eventRepetition.repeatDays.size()).round(System.RoundingMode.CEILING) + ((freq - 1)*2);
                    }

                    Date endsAt = startsAt.addDays(numberOfWeeks.intValue() * getPeriodInteger(eventRepetition.repeatTime));
                    Integer daysBetween = (startsAt.daysBetween(endsAt) + 1) < 100 ? startsAt.daysBetween(endsAt) : 100;

                    Integer i = 0;
                    while (i <= daysBetween) {
                        System.debug('current start of the week: ' + convertedStartWeek);

                        for(Integer j = 0; j <= 7; j++){
                            DateTime dt = convertedStartWeek.addDays(j);
                            if(System.now() <= dt && startDateTimeFromEvent <= dt){
                                if(eventRepetition.repeatDays.contains(dt.format('EEEE'))){
                                    //make sure that we only add the correct number of events
                                    if(recurrenceTimes.size() < Integer.valueOf(eventRepetition.numberEvents)){
                                        recurrenceTimes.add(dt);
                                    } else {
                                        break;
                                    }
                                }
                            }
                        }

                        convertedStartWeek = convertedStartWeek.addDays(freq * getPeriodInteger(eventRepetition.repeatTime));
                        i = i + (freq * getPeriodInteger(eventRepetition.repeatTime));
                    }
                }
            }

            if(eventRepetition.repeatTime == 'Month'){
                DateTime startDateTimeFromEvent = start;
                Date startsAt =  convertToDate(eventObject.startTime); //selected start date

                if (eventRepetition.onAfter == 'On'){
                    Date endsAt = eventRepetition.onDate; //the date that repeat is over
                    Integer yearsBetween = endsAt.year() - startsAt.year();
                    Integer monthsBetween = 0;

                    if(yearsBetween > 1){
                        monthsBetween = 12;
                    } else if(yearsBetween == 1){
                        monthsBetween = (12 - startsAt.month() + endsAt.month()) <= 12 ? (12 - startsAt.month() + endsAt.month()) : 12; //cap this to 12 if this is more than 12?
                    } else if(yearsBetween == 0){
                        monthsBetween = endsAt.month() - startsAt.month();
                    }

                    Integer i = 0;
                    while (i <= monthsBetween) {
                        DateTime dt = startDateTimeFromEvent.addMonths(i);
                        System.debug('Current dt: ' + dt);

                        if(System.now() <= dt && startDateTimeFromEvent <= dt && endsAt >= dt){
                            recurrenceTimes.add(dt);
                        }
                        i = i + freq;
                    }
                } else if(eventRepetition.onAfter == 'After'){
                    Integer i = 0;
                    while (i <= Integer.valueOf(eventRepetition.numberEvents) * freq) {
                        DateTime dt = startDateTimeFromEvent.addMonths(i);
                        System.debug('Current dt: ' + dt);

                        if(System.now() <= dt && startDateTimeFromEvent <= dt){
                            if(recurrenceTimes.size() < Integer.valueOf(eventRepetition.numberEvents)){
                                recurrenceTimes.add(dt);
                            } else {
                                break;
                            }
                        }
                        i = i + freq;
                    }
                }
            }

            System.debug('recurrenceTimes: ' + recurrenceTimes);

            // get the tz and calculate the offset calculated for the first event in the recurrence (this offset is always correct)
            TimeZone tz = UserInfo.getTimeZone();
            Integer offsetSecondsCorrect = tz.getOffset(start)/1000; // seconds

            for (Datetime startdt : recurrenceTimes) {
                // get the offset calculated for all events in the recurrence. For events that are transitioning through DLS, the offset will be incorrect
                Integer offsetCalculated = tz.getOffset(startdt)/1000;

                // get the difference of the offsets. events in same DLS will be equal so diff will be 0, otherwise, transitioned events will be off.
                Integer finalOffsetSeconds = offsetSecondsCorrect - offsetCalculated;

                // create a new Datetime accounting for the incorrect offset
                Datetime finaldt = startdt.addSeconds(finalOffsetSeconds);

                eventsCreated.add(createEventObjectRecurrence(eventObject, finaldt, finaldt.addMinutes(duration), event_recur.Id, convertedWorkers, convertedClients, shareContact, contactPageUser, convertedSite));
            }

        } else {
            System.debug('here single event object');
            eventsCreated.add(createEventObject(eventObject, convertedWorkers, convertedClients, shareContact, contactPageUser, convertedSite));
        }

        System.debug(eventsCreated);

        try {
            insert eventsCreated;
        } catch (DMLException error) {
            System.debug(error.getMessage());
        }

        return eventsCreated;
    }

    //to update event (either from drag/drop/resize or edit form)
    //changeType is either "Edit Form Change" (for changes from edit form) or "Time Change" (for changes from drag/drop/resize)
    public static List<Map<String, String>> updateEvent(String updateJSON, String action, String changeType) {
        System.debug('Inside updateEvent event controller');
        System.debug(updateJSON);
        CalendarClass.EventUpdate eventObject = (CalendarClass.EventUpdate)JSON.deserialize(updateJSON, CalendarClass.EventUpdate.Class);
        System.debug(eventObject.eventId);

        Event e = [SELECT id, Subject, Meeting_Link__c, Mode_of_Delivery__c, Event_Recurrence__c, Event_Address__c, StartDateTime, EndDateTime, Event_Status__c, Event_Type__c, OwnerId, Owner.Name, Comments__c, CreatedDate, LastModifiedDate FROM Event WHERE id =: eventObject.eventId];

        //og dates and dt dates are only for the event where the user clicks on
        DateTime ogStart = e.StartDateTime;
        DateTime ogEnd = e.EndDateTime;
        DateTime dtStart = EventController.convertToLocal(eventObject.startTime);
        DateTime dtEnd = EventController.convertToLocal(eventObject.endTime);

        List<Event> eventsToUpdate = new List<Event>();

        if (action == 'saveOne') {
            eventsToUpdate.add(EventController.updateEventObjectFields(e, eventObject, dtStart, dtEnd, ogStart, ogEnd, changeType));
        } else {
            DateTime NOW = DateTime.now();
            for (Event ev : [SELECT id, Subject, Mode_of_Delivery__c, Meeting_Link__c, Event_Recurrence__c, Event_Address__c, StartDateTime, EndDateTime, Event_Status__c, Event_Type__c, OwnerId, Owner.Name, Comments__c, CreatedDate, LastModifiedDate
                             FROM Event WHERE Event_Recurrence__c =: e.Event_Recurrence__c AND (StartDateTime >=: e.StartDateTime AND StartDateTime >=: NOW)]) {
            	eventsToUpdate.add(EventController.updateEventObjectFields(ev, eventObject, dtStart, dtEnd, ogStart, ogEnd, changeType));
            }
        }

        List<Map<String, String>> resList = new List<Map<String, String>>();
        Set<Id> eventIds = new Set<Id>();
        System.debug('eventsToUpdate: ' + eventsToUpdate);

        //this is the event map that will be passed to the front end
        //in the front end, depending on whether drag/drop was called or edit form was called, only certain event attributes will be passed to the aura:attribute event
        for (Event uev : eventsToUpdate) {
            Map<String, String> res = new Map<String, String>();
            System.debug('event ID in cal controller: ' + uev.Id);
            eventIds.add(uev.id);
            res.put('Id', uev.id);
            res.put('Subject', uev.Subject);
            res.put('Event_Recurrence__c', uev.Event_Recurrence__c);
            res.put('StartDateTime', convertDateTimeToStringGMT(uev.StartDateTime));
            res.put('EndDateTime', convertDateTimeToStringGMT(uev.EndDateTime));
            res.put('Event_Status__c', uev.Event_Status__c);
            res.put('Event_Type__c', uev.Event_Type__c);
            res.put('OwnerId', uev.OwnerId);
            res.put('Event_Address__c', uev.Event_Address__c);
            res.put('action', action);
            res.put('OwnerName', e.Owner.Name);
            res.put('Comments__c', e.Comments__c);
            res.put('Meeting_Link__c', e.Meeting_Link__c);
            res.put('Mode_of_Delivery__c', e.Mode_of_Delivery__c);
            res.put('CreatedDate', convertDateTimeToStringGMT(uev.CreatedDate));
            res.put('LastModifiedDate', convertDateTimeToStringGMT(uev.LastModifiedDate));

            resList.add(res);
        }

        System.debug('resList' + resList);

        List<Client_Event_Relation__c> cers = [SELECT id, Status__c FROM Client_Event_Relation__c WHERE Event_Id__c IN :eventIds AND Status__c = 'Booked'];
        System.debug('how many cers in cal controller? ' + cers.size());

        //need to check what was changed before making status to pending
        for (Client_Event_Relation__c cer : cers) {
            if((ogStart != dtStart) || (ogEnd != dtEnd)){
            	cer.Status__c = 'Pending';
                System.debug('Date was changed!!!');
            } else {
            	cer.Status__c = cer.Status__c;
                System.debug('Date was NOT changed!!!');
            }
        }

        try {
            update eventsToUpdate;
            update cers;
        } catch (DMLException error) {
            System.debug(error);
            return null;
        }


        return resList;
    }

    //to either delete/cancel an event, ERs, CERs, depending on the event type and status
    public static String deleteAnEvent(Id eventId, String reason) {
        List<Client_Event_Relation__c> cers = [SELECT id, Status__c FROM Client_Event_Relation__c WHERE Event_Id__c =: eventId];
        List<EventRelation> ers = [SELECT id, Status FROM EventRelation WHERE EventId =: eventId AND Relation.Name != 'Contact to share events'];

        Event e = [SELECT id, Event_Status__c, Event_Type__c, Number_of_Workers__c, Number_of_Clients__c FROM Event WHERE id =: eventId];

        if (e.Event_Status__c == 'Cancelled') {
            return 'NONE';
        }

        if (e.Event_Status__c == 'Booked' && (e.Event_Type__c == 'Initial Appointment' || e.Event_Type__c == 'Therapy Session')) {
            e.Event_Status__c = 'Cancelled';
            e.Number_of_Clients__c = 0;
            e.Number_of_Workers__c = 0;
            e.Cancellation_Reason__c = reason;
            for (EventRelation er : ers) {
                er.Status = 'Declined';
            }
            for (Client_Event_Relation__c cer : cers) {
                cer.Status__c = 'Cancelled';
            }

            try {
                update e;
                update ers;
                update cers;

                return 'CANCELLED';
            } catch (DMLException err) {
                System.debug(err.getMessage());
                return err.getMessage();
            }
        } else {
            try {
                delete e;
                delete cers;
                //delete ers;

                return 'DELETED';
            } catch (DMLException err) {
                System.debug(err.getMessage());
                return err.getMessage();
            }
        }
    }

    //to book an event, its ers, cers
    public static String bookAnEvent(Id eventId) {
        Set<Id> eventIds = new Set<Id>{eventId};

        List<Client_Event_Relation__c> cers = [SELECT id, Status__c FROM Client_Event_Relation__c WHERE Event_Id__c IN: eventIds AND Status__c != 'Cancelled'];

        for (Client_Event_Relation__c cer : cers) {
            if(cer.Status__c != 'Cancelled'){
                cer.Status__c = 'Booked';
            }
        }

        List<EventRelation> ers = [SELECT id, Status FROM EventRelation WHERE EventId =: eventIds AND Status != 'Declined' AND Relation.Name != 'Contact to share events'];

        for (EventRelation er : ers) {
            if(translateStatus(er.Status) != 'Cancelled'){
                 er.Status = 'Accepted';
            }
        }

        Event e = [SELECT id, Event_Status__c, Event_Type__c, Number_of_Workers__c, Number_of_Clients__c FROM Event WHERE id =: eventId];
        e.Event_Status__c = 'Booked';

        try {
            update e;
            update ers;
            update cers;

            return 'BOOKED';
        } catch (DMLException err) {
            System.debug(err.getMessage());
            return err.getMessage();
        }
    }

    //to book a recurring events, ers, cers
    public static Map<String, String> bookARecurrence(Id eventId) {

        Id recurrenceId = [SELECT id, Event_Recurrence__c FROM Event WHERE id =: eventId].Event_Recurrence__c;

        if (recurrenceId == null) {
            return null;
        }

        List<Event> events = new List<Event>();
        List<Client_Event_Relation__c> cers = new List<Client_Event_Relation__c>();
        List<EventRelation> ers = new List<EventRelation>();

        Map<String, String> changes = new Map<String, String>();

        Map<Id, Event> eventMap = new Map<Id, Event>([SELECT id, Event_Status__c, Event_Type__c, Number_of_Workers__c, Number_of_Clients__c, StartDateTime FROM Event WHERE Event_Recurrence__c =: recurrenceId]);

        //get a map of event id and cer id
        Map<Id, Client_Event_Relation__c> cerMap = new  Map<Id, Client_Event_Relation__c>([SELECT id, Event_Id__c, Status__c FROM Client_Event_Relation__c WHERE Event_Id__c IN: eventMap.keySet()]);
        Map<Id, EventRelation> erMap = new  Map<Id, EventRelation>([SELECT id, EventId, Status FROM EventRelation WHERE EventId =: eventMap.keySet() AND Relation.Name != 'Contact to share events']);

        Map<Id, List<Client_Event_Relation__c>> eventToListOfCER = new Map<Id, List<Client_Event_Relation__c>>();
        Map<Id, List<EventRelation>> eventToListOfER = new Map<Id, List<EventRelation>>();

        for(Event ev : eventMap.values()){
            List<Client_Event_Relation__c> listOfCERForAnEvent = new List<Client_Event_Relation__c>();

            //set up to find a list of cer for each event
            for(Client_Event_Relation__c cer : cerMap.values()){
                if(cer.Event_Id__c == ev.Id){
                    listOfCERForAnEvent.add(cer);
                }
            }

            eventToListOfCER.put(ev.Id, listOfCERForAnEvent);

            List<EventRelation> listOfERForAnEvent = new List<EventRelation>();

            //set up to find a list of cer for each event
            for(EventRelation er : erMap.values()){
                if(er.EventId == ev.Id){
                    listOfERForAnEvent.add(er);
                }
            }

            eventToListOfER.put(ev.Id, listOfERForAnEvent);
        }

        //now do the code
        for(Event event : eventMap.values()){
           //only book events that are later/in the future from where the user clicks on the calendar
           if (event.StartDateTime < eventMap.get(eventId).StartDateTime || event.StartDateTime < System.today()) {
                continue;
            }

            //get the list of CER
            List<Client_Event_Relation__c> eventCERs = eventToListOfCER.get(event.Id);
            List<EventRelation> eventERs = eventToListOfER.get(event.Id);

            event.Event_Status__c = 'Booked';

            for (EventRelation er : eventERs) {
                if(translateStatus(er.Status) != 'Cancelled'){
                    er.Status = 'Accepted';
                }
            }

            for (Client_Event_Relation__c cer : eventCERs) {
                if(cer.Status__c != 'Cancelled'){
                    cer.Status__c = 'Booked';
                }
            }

            events.add(event);
            cers.addAll(eventCERs);
            ers.addAll(eventERs);

            changes.put(event.Id, 'BOOKED');
        }

        try {
            update events;
            update ers;
            update cers;

        } catch (DMLException err) {
            System.debug(err.getMessage());
            return new Map<String, String>{'error' => err.getMessage()};
        }

        return changes;
    }

    //to either delete/cancel each recurring event, ERs, CERs, depending on the event type and status
    public static Map<String, String> deleteARecurrence(Id eventId, String reason) {

        Id recurrenceId = [SELECT id, Event_Recurrence__c FROM Event WHERE id =: eventId].Event_Recurrence__c;

        if (recurrenceId == null) {
            return null;
        }

        Map<String, String> changes = new Map<String, String>();

        // events and relations to delete (global lists)
        List<Event> Devents = new List<Event>();
        List<Client_Event_Relation__c> Dcers = new List<Client_Event_Relation__c>();
        List<EventRelation> Ders = new List<EventRelation>();

        // events and relations to update (global lists)
        List<Event> Uevents = new List<Event>();
        List<Client_Event_Relation__c> Ucers = new List<Client_Event_Relation__c>();
        List<EventRelation> Uers = new List<EventRelation>();
        Map<Id, Event> eventMap = new Map<Id, Event>([SELECT id, Event_Status__c, Event_Type__c, Number_of_Workers__c, Number_of_Clients__c, StartDateTime FROM Event WHERE Event_Recurrence__c =: recurrenceId]);

        //get a map of event id and cer id
        Map<Id, Client_Event_Relation__c> cerMap = new  Map<Id, Client_Event_Relation__c>([SELECT id, Event_Id__c, Status__c FROM Client_Event_Relation__c WHERE Event_Id__c IN: eventMap.keySet()]);
        Map<Id, EventRelation> erMap = new  Map<Id, EventRelation>([SELECT id, EventId, Status FROM EventRelation WHERE EventId =: eventMap.keySet() AND Relation.Name != 'Contact to share events']);

        Map<Id, List<Client_Event_Relation__c>> eventToListOfCER = new Map<Id, List<Client_Event_Relation__c>>();
        Map<Id, List<EventRelation>> eventToListOfER = new Map<Id, List<EventRelation>>();

        for(Event ev : eventMap.values()){
            List<Client_Event_Relation__c> listOfCERForAnEvent = new List<Client_Event_Relation__c>();

            //set up to find a list of cer for each event
            for(Client_Event_Relation__c cer : cerMap.values()){
                if(cer.Event_Id__c == ev.Id){
                    listOfCERForAnEvent.add(cer);
                }
            }

            eventToListOfCER.put(ev.Id, listOfCERForAnEvent);

            List<EventRelation> listOfERForAnEvent = new List<EventRelation>();

            //set up to find a list of cer for each event
            for(EventRelation er : erMap.values()){
                if(er.EventId == ev.Id){
                    listOfERForAnEvent.add(er);
                }
            }

            eventToListOfER.put(ev.Id, listOfERForAnEvent);
        }

        for(Event event : eventMap.values()){
            //only DELETE/CANCEL events that are later/in the future from where the user clicks on the calendar
            if (eventMap.get(eventId).StartDateTime > event.StartDateTime || event.StartDateTime < System.today()) {
                continue;
            }

            //get the list of CER
            List<Client_Event_Relation__c> eventCERs = eventToListOfCER.get(event.Id);
            List<EventRelation> eventERs = eventToListOfER.get(event.Id);

            if (event.Event_Status__c == 'Cancelled') {
                continue;
            }

            if (event.Event_Status__c == 'Booked' && (event.Event_Type__c == 'Initial Appointment' || event.Event_Type__c == 'Therapy Session')) {
                event.Event_Status__c = 'Cancelled';
                event.Number_of_Clients__c = 0;
                event.Number_of_Workers__c = 0;
                event.Cancellation_Reason__c = reason;
                for (EventRelation er : eventERs) {
                    er.Status = 'Declined';
                }
                for (Client_Event_Relation__c cer : eventCERs) {
                    cer.Status__c = 'Cancelled';
                }

                Uevents.add(event);
                Ucers.addAll(eventCERs);
                Uers.addAll(eventERs);

                changes.put(event.Id, 'CANCELLED');
            } else {
                Devents.add(event);
                Dcers.addAll(eventCERs);

                changes.put(event.Id, 'DELETED');
            }
        }

        try {
            update Uevents;
            update Ucers;
            update Uers;
            delete Devents;
            delete Dcers;

        } catch (DMLException error) {
            return new Map<String, String>{'error' => error.getMessage()};
        }

        return changes;
    }

    //to update status of the event based on the number of clients and workers
    private static void updateEventStatusBasedOnNumberOfClientsWorkers(List<Id> eventIds, Integer change, String addType) {
        List<Event> updatedEvents = new List<Event>();

        System.debug('List of eventIds: ' + eventIds);
        System.debug('change: ' + change);

        for(Event e : [SELECT id, Number_of_Clients__c, Number_of_Workers__c, Event_Status__c FROM Event WHERE id IN: eventIds]){
            System.debug('workers: ' + e.Number_of_Workers__c);
            System.debug('clients: ' + e.Number_of_Clients__c);

            if(addType == 'worker'){
                if(e.Number_of_Workers__c != NULL){
                    e.Number_of_Workers__c = e.Number_of_Workers__c == 0 ? 0 : e.Number_of_Workers__c + change;
                    e.Event_Status__c = e.Number_of_Workers__c == 0 ? 'Cancelled' : e.Event_Status__c;
                }

            } else if(addType == 'client'){
                if(e.Number_of_Clients__c != NULL){
                    System.debug('clients: ' + e.Number_of_Clients__c);
                    e.Number_of_Clients__c = e.Number_of_Clients__c == 0 ? 0 : e.Number_of_Clients__c + change;
                    e.Event_Status__c = e.Number_of_Clients__c == 0 ? 'Cancelled' : e.Event_Status__c;
                }
            }

            updatedEvents.add(e);
        }

        try {
            update updatedEvents;
        } catch(DMLException error) {
            System.debug(error);
        }

        return;
    }

    //to update the event map according to the updateEvent changeType
    private static Event updateEventObjectFields(Event e, CalendarClass.EventUpdate eventObject, DateTime dtStart, DateTime dtEnd, DateTime ogStart, DateTime ogEnd, String changeType) {
        System.debug('Inside updateEventObjectFields in event controller');

        // hard reset status if there was a time change
        if ((ogStart != dtStart || ogEnd != dtEnd) && e.Event_Status__c == 'Booked') {
            e.Event_Status__c = 'Pending';
        }

        //these are the list of fields that are editable in the edit form
        Integer minutesToAdd = Utility.XBetweenDTs(ogStart, e.StartDateTime ,'minutes').intValue();
        e.StartDateTime = dtStart.addMinutes(minutesToAdd);
        e.EndDateTime = dtEnd.addMinutes(minutesToAdd);

        //put an if statement here, if change type = time only, do not do this, otherwise do this
        if(changeType == 'Edit Form Change'){
            e.Subject = eventObject.subject;
            e.Event_Type__c = eventObject.eventType;
            e.OwnerId = eventObject.owner;
            e.Event_Address__c = eventObject.address;
            e.Comments__c = eventObject.comments;
            e.Meeting_Link__c = eventObject.link;
            e.Mode_of_Delivery__c = eventObject.mode;
        }


        System.debug('event after update: ' + e);

        return e;
    }

    //to create a recurring event object from JSON event map
    private static Event createEventObjectRecurrence(CalendarClass.EventDetail eventObject, DateTime startTime, DateTime endTime, Id recurrenceId,
                                                     List<CalendarClass.Worker> workers, List<CalendarClass.Client> clients, Contact shareContact,
                                                     String ownerId, CalendarClass.Site siteChosen)
    {
        // create new event
        Event e = new Event();
        e.Subject = eventObject.subject;
        e.Event_Type__c = eventObject.eventType;
        e.Type = 'Other';
        e.Event_Recurrence__c = recurrenceId;
        e.isRecurrence__c = true;
        e.RecordTypeId = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('BR_Event').getRecordTypeId();
        e.Event_Address__c = eventObject.address;
        e.Event_Status__c = eventObject.status;
        e.Number_of_Workers__c = workers.size();
        e.Number_of_Clients__c = clients.size();
        e.Location = eventObject.address;
        e.WhoId = shareContact.Id;
        e.IsAllDayEvent = eventObject.allDay;
        e.Is_Re_engagement__c = eventObject.reengagement;
        e.Comments__c = eventObject.comments;
        e.Meeting_Link__c = eventObject.link;
        e.Mode_of_Delivery__c = eventObject.mode;
        e.Session_Location__c = eventObject.eventLocation;
        e.enrtcr__Site_Visit__c = siteChosen.Id;

        e.OwnerId = ownerId;
        if (!eventObject.allDay) {
            e.StartDateTime = startTime;
            e.EndDateTime = endTime;
        } else {
            // both conversions use startTime for all day event to prevent multi day all day events (occurs if a user selects range across multiple days)
            e.StartDateTime = startTime;
            e.EndDateTime = startTime;
            e.DurationInMinutes = 1440;
        }

        return e;
    }

    //to create a non-recurring event object from JSON event map
    private static Event createEventObject(CalendarClass.EventDetail eventObject, List<CalendarClass.Worker> workers, List<CalendarClass.Client> clients,
                                           Contact shareContact, String ownerId, CalendarClass.Site siteChosen)
    {
        // create new event
        Event e = new Event();
        e.Subject = eventObject.subject;
        e.Event_Type__c = eventObject.eventType;
        e.Type = 'Other';
        e.RecordTypeId = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('BR_Event').getRecordTypeId();
        e.isRecurrence__c = false;
        e.Event_Address__c = eventObject.address;
        e.Event_Status__c = eventObject.status;
        e.Number_of_Workers__c = workers.size();
        e.Number_of_Clients__c = clients.size();
        e.Location = eventObject.address;
        e.WhoId = shareContact.Id;
        e.IsAllDayEvent = eventObject.allDay;
        e.Is_Re_engagement__c = eventObject.reengagement;
        e.Comments__c = eventObject.comments; //RAF adds this
        e.Meeting_Link__c = eventObject.link;
        e.Mode_of_Delivery__c = eventObject.mode;
        e.Session_Location__c = eventObject.eventLocation;
        e.enrtcr__Site_Visit__c = siteChosen.Id;

        e.OwnerId = ownerId;
        if (!eventObject.allDay) {
            e.StartDateTime = eventObject.startTime.right(1) == 'Z' ? convertToLocal(eventObject.startTime) : convertToDateTime(eventObject.startTime, eventObject.allDay);
            e.EndDateTime = eventObject.endTime.right(1) == 'Z' ? convertToLocal(eventObject.endTime) : convertToDateTime(eventObject.endTime, eventObject.allDay);
        } else {
            // both conversions use startTime for all day event to prevent multi day all day events (occurs if a user selects range across multiple days)
            if (eventObject.startTime.length() == 10) {
                e.StartDateTime = dateStringToDate(eventObject.startTime);
                e.EndDateTime = dateStringToDate(eventObject.startTime);
            } else if (eventObject.startTime.right(1) == 'Z') {
                e.StartDateTime = convertToLocal(eventObject.startTime);
                e.EndDateTime = convertToLocal(eventObject.startTime);
            } else {
                e.StartDateTime = convertToDate(eventObject.startTime);
                e.EndDateTime = convertToDate(eventObject.startTime);
            }
            e.DurationInMinutes = 1440;
        }

        return e;
    }

    //to find the events that are clashing with an eventJSON
    private static Map<Id, Event> retrieveClashingEventIds(String eventJSON){
        System.debug('In retrieveEventIdsFromJSON now');

        Set<String> setOfClashingContacts= new Set<String>();
        Map<Id, Event> eventIds;

        Id BR_EVENT = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('BR_Event').getRecordTypeId();

        // parse event details
        CalendarClass.EventDetail eventObject = (CalendarClass.EventDetail)JSON.deserialize(eventJSON, CalendarClass.EventDetail.class);

        DateTime startDateTime;
        DateTime endDateTime;
        Integer duration;

        List<Event> clashedEvents = new List<Event>();

        if(!String.isBlank(eventObject.startTime) && !String.isBlank(eventObject.endTime)){
            System.debug('start date from eventObject: ' + eventObject.startTime);
            System.debug('end date from eventObject: ' + eventObject.endTime);

            if (!eventObject.allDay) {
                startDateTime = eventObject.startTime.right(1) == 'Z' ? convertToLocal(eventObject.startTime) : convertToDateTime(eventObject.startTime, eventObject.allDay);
                endDateTime = eventObject.endTime.right(1) == 'Z' ? convertToLocal(eventObject.endTime) : convertToDateTime(eventObject.endTime, eventObject.allDay);
                duration = ((endDateTime.getTime() - startDateTime.getTime()) / 60000).intValue();

                eventIds = new Map<Id, Event>([SELECT Id, Event_Type__c, StartDateTime, EndDateTime FROM Event WHERE RecordTypeId =: BR_EVENT AND (Event_Status__c = 'Pending' OR Event_Status__c = 'Booked')
                                               AND ((StartDateTime >=: startDateTime AND EndDateTime <=: endDateTime) //for if your event duration is larger than an event's time
                                                    OR (StartDateTime <=: startDateTime AND EndDateTime >: startDateTime) //for if your start time is between an event's time
                                                    OR (StartDateTime <: endDateTime AND EndDateTime >=: endDateTime) //for if your end time is between an event's time
                                                   )]);


            } else {
                // both conversions use startTime for all day event to prevent multi day all day events (occurs if a user selects range across multiple days)
                if (eventObject.startTime.length() == 10) {
                    startDateTime = dateStringToDate(eventObject.startTime);
                    endDateTime = dateStringToDate(eventObject.startTime);
                } else if (eventObject.startTime.right(1) == 'Z') {
                    startDateTime = convertToLocal(eventObject.startTime);
                    endDateTime = convertToLocal(eventObject.startTime);
                } else {
                    startDateTime = convertToDate(eventObject.startTime);
                    endDateTime = convertToDate(eventObject.startTime);
                }
                //duration = 1440;

                eventIds = new Map<Id, Event>([SELECT Id, Event_Type__c, StartDateTime, EndDateTime FROM Event WHERE RecordTypeId =: BR_EVENT AND (Event_Status__c = 'Pending' OR Event_Status__c = 'Booked') AND CALENDAR_MONTH(StartDateTime) =: startDateTime.month()
                                               AND CALENDAR_YEAR(StartDateTime) =: startDateTime.year() AND DAY_IN_MONTH(StartDateTime) =: startDateTime.day()]);
            }

            System.debug('Start date time: ' + startDateTime);
            System.debug('End date time: ' + endDateTime);


            System.debug('Number of clashed events in TOTAL: ' + eventIds.size());
            System.debug('Clashed Events IDs: ' + eventIds);

        } else {
            eventIds.put(null, null);
        }

        return eventIds;
    }

    //to get the relationship between an event and the currently logged in user
    public static String getEventRelationship(String eventId) {
        if (eventId != '') {
            Event e = [SELECT id, OwnerId FROM Event WHERE id =: eventId];

            if (e.OwnerId == UserInfo.getUserId()) return 'owner';
            
            List<Contact> c = [SELECT id FROM Contact WHERE enrtcr__User__c =: UserInfo.getUserId() LIMIT 1];

            if (c.size() != 0) {
                EventRelation[] ers = [SELECT id FROM EventRelation WHERE EventId =: eventId AND RelationId =: c[0].Id];
                if (ers.size() != 0) return 'worker';
            }
        }

        List<PermissionSetAssignment> permissions = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId =: UserInfo.getUserId() AND PermissionSet.Name = 'Diary_Editors'];
        if (permissions.size() > 0) return 'editors';

        // Profile loggedInProfile = [SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId()];
        // if (loggedInProfile.Name == 'System Administrator') return 'sysAdmin';
        // else if (loggedInProfile.Name == 'Enrite Care - Standard') return 'std';
        // else if (loggedInProfile.Name == 'Enrite Care - Advanced') return 'adv';
        

        return 'none';
    }

    /*
     *
     * METHODS FOR WORKER OR ER
     *
     * */

    //to create the ERs
    public static List<EventRelation> createERs(List<Event> events, List<CalendarClass.Worker> workers, String status) {
        List<EventRelation> workerEventRelations = new List<EventRelation>();
        for (Event e : events) {
            for (CalendarClass.Worker worker : workers) {
                EventRelation er = new EventRelation();
                er.EventId = e.Id;
                er.RelationId = worker.Id;
                er.Status = status == 'Pending' ? 'New' : 'Accepted';
                workerEventRelations.add(er);
            }
        }

        return workerEventRelations;
    }

    //to get the currently logged in user and worker info
    public static Map<String, String> getWorker(Id workerId) {
        Contact worker = workerId != null ?
                                    BR_ContactDAO.getWorkerContactById(workerId):
                                    BR_ContactDAO.getWorkerContactByLoggedInUserId();
        User u = [SELECT id, Name, Profile.Name FROM User WHERE id =: UserInfo.getUserId()];

        Map<String, String> details = new Map<String, String>();
        details.put('id', worker.id);
        details.put('Name', worker.Name);
        details.put('enrtcr__Site__c', worker.enrtcr__Site__c);
        details.put('enrtcr__Site__r.Name', worker.enrtcr__Site__r.Name);
        details.put('enrtcr__Site__r.enrtcr__Business_Address_1__c', worker.enrtcr__Site__r.enrtcr__Business_Address_1__c);
        details.put('enrtcr__User__c', worker.enrtcr__User__c);
        details.put('enrtcr__User__r.Profile.Name', worker.enrtcr__User__r.Profile.Name);
        details.put('Record_Type_Name__c', worker.Record_Type_Name__c);
        details.put('userId', u.id);
        details.put('userName', u.Name);
        details.put('userProfile', u.Profile.Name);
        details.put('eventRelationship', getEventRelationship(''));

        return details;
    }

    //get the list of event relations - you can pass multiple workers here if needed for the calendar
    public static List<Map<String, Object>> getWorkerEvents(List<Id> contactIds, Integer cutOffDays) {
        DateTime cutoff = System.today() - cutOffDays;

        List<EventRelation> ers = [SELECT   Id,
                                   Status,
                                   Event.Id,
                                   Event.OwnerId,
                                   Event.enrtcr__Client__c,
                                   Event.StartDateTime,
                                   Event.EndDateTime,
                                   Event.Event_Type__c,
                                   Event.Event_Status__c,
                                   Event.Subject,
                                   Event.IsAllDayEvent,
                                   Event.isRecurrence__c,
                                   Event.Event_Recurrence__c,
                                   Event.Event_Address__c,
                                   Event.Comments__c,
                                   Event.Meeting_Link__c,
                                   Event.Mode_of_Delivery__c,
                                   Event.CreatedDate,
                                   Event.LastModifiedDate,
                                   Event.Owner.Name
                                   FROM EventRelation
                                   WHERE RelationId IN: contactIds
                                   AND Event.StartDateTime >: cutoff
                                   AND Event.RecordTypeId =: Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('BR_Event').getRecordTypeId()
                                  ];
        System.debug(ers);
        return ERsToEvents(ers);
    }

    //to add one or more ERs to an existing event
    public static List<Map<String, Object>> addERsToAnEvent(List<String> ids, Id eventId, String action) {
        List<EventRelation> newERs = new List<EventRelation>();
        List<Event> eventsToUpdate = new List<Event>();

        Event e = [SELECT Id, Event_Status__c, Number_Of_Workers__c, StartDateTime, Event_Recurrence__c FROM Event WHERE Id =: eventId];
        e.Number_of_Workers__c += ids.size();

        if(action == 'saveOne'){
            eventsToUpdate.add(e);

            for (String contactId : ids) {
                EventRelation er = new EventRelation();
                er.EventId = eventId;
                er.Status = translateStatus(e.Event_Status__c);
                er.RelationId = contactId;

                newERs.add(er);
            }
        } else {
            DateTime NOW = DateTime.now();

            for(Event ev : [SELECT Id, Event_Status__c, Number_of_Workers__c FROM Event WHERE Event_Recurrence__c =: e.Event_Recurrence__c AND StartDateTime >=: e.StartDateTime]){
                ev.Number_of_Workers__c += ids.size();
                eventsToUpdate.add(ev);

                for (String contactId : ids) {
                    EventRelation er = new EventRelation();
                    er.EventId = ev.Id;
                    er.Status = translateStatus(ev.Event_Status__c);
                    er.RelationId = contactId;

                    newERs.add(er);
                }
            }

        }

        System.debug('Size of newERs to add: ' + newERs.size());

        try {
            insert newERs;
            update eventsToUpdate;
        } catch (DMLException error) {
            System.debug(error.getMessage());
        }

        String baseURL = URL.getSalesforceBaseUrl().toExternalForm();
        List<EventRelation> ers = [SELECT Id, Status, Relation.Id, Relation.Name FROM EventRelation WHERE EventId =: eventId];
        return createWorkerList(ers, baseURL);
    }

    //to translate between default ER status and our custom ER status
    public static String translateStatus(String erStatus) {
        switch on (erStatus) {
            when 'New' {return 'Pending';}
            when 'Declined' {return 'Cancelled';}
            when 'Accepted' {return 'Booked';}
            when 'Pending' {return 'New';}
            when 'Cancelled' {return 'Declined';}
            when 'Booked' {return 'Accepted';}
        }
        return '';
    }

    //to update an existing ER status on an existing event
    //newStatus can be booked, cancelled, deleted
    //action is always update
    public static void handleERStatusChange(String action, Id ERid, String newStatus, String saveType) {
        System.debug('saveType: ' + saveType);
        System.debug('action: ' + action);

        EventRelation er = [SELECT id, RelationId, EventId, Status FROM EventRelation WHERE id =: ERid]; //add filter here
        String translatedNewStatus = translateStatus(newStatus);
        String previousStatus = translateStatus(er.Status);

        List<EventRelation> newERs = new List<EventRelation>();
        List<EventRelation> deletedERs = new List<EventRelation>();
        List<Id> affectedEventIds = new List<Id>();

        if(saveType == 'saveOne'){
            affectedEventIds.add(er.EventId);

            if (action == 'update') {

                if(newStatus == 'Booked' || newStatus == 'Cancelled'){

                    er.Status = translatedNewStatus;
                    newERs.add(er);

                }  else if(newStatus == 'Deleted'){
                    deletedERs.add(er);
                }
            }

        } else {
            Event e = [SELECT Id, StartDateTime, Event_Recurrence__c FROM Event WHERE Id =: er.EventId];

            DateTime NOW = DateTime.now();
            Set<Id> futureEvents = new Set<Id>();

            for(Event ev : [SELECT Id FROM Event WHERE Event_Recurrence__c =: e.Event_Recurrence__c AND (StartDateTime >=: e.StartDateTime AND StartDateTime >=: NOW)]){
                affectedEventIds.add(ev.Id);
            }

            //get all of this worker's ER
            if (action == 'update') {
                for(EventRelation updateER : [SELECT Id, EventId, Status FROM EventRelation WHERE EventId IN: affectedEventIds AND RelationId =: er.RelationId]){
                    System.debug('Currently updating ER: ' + updateER);

                    if(newStatus == 'Booked' || newStatus == 'Cancelled'){

                        updateER.Status = translatedNewStatus;
                        newERs.add(updateER);

                    }  else if(newStatus == 'Deleted'){
                        deletedERs.add(updateER);
                    }
                }
            }
        }

        System.debug('newERs: ' + newERs);

        try {
            update newERs;
            delete deletedERs;
        } catch (DMLException error) {
            System.debug(error);
        }

        System.debug('deletedERs: ' + deletedERs.size());

        //only need to change the number of workers when an ER is deleted
        if(!deletedERs.isEmpty()){
            updateEventStatusBasedOnNumberOfClientsWorkers(affectedEventIds, -1, 'worker');
        }

    }

    //this is the map of event that will be passed to BR_Calendar, containing details of the event object (not including worker/clients)
    //this is mainly used to load the events in a client/worker calendar
    private static List<Map<String,Object>> ERsToEvents(List<EventRelation> ers) {

        List<Map<String,Object>> events = new List<Map<String,Object>>();

        for (EventRelation er : ers) {
            Map<String, Object> event = new Map<String, Object>();

            event.put('Id', er.Event.Id);
            event.put('Subject', er.Event.Subject);
            event.put('OwnerId', er.Event.OwnerId);
            event.put('enrtcr__Client__c', er.Event.enrtcr__Client__c); //wjat is this?
            event.put('OwnerName', er.Event.Owner.Name);
            event.put('StartDateTime', er.Event.StartDateTime);
            event.put('EndDateTime', er.Event.EndDateTime);
            event.put('Event_Type__c', er.Event.Event_Type__c);
            event.put('Event_Status__c', EventController.translateStatus(er.Status));
            event.put('IsAllDayEvent', er.Event.IsAllDayEvent);
            event.put('isRecurrence__c', er.Event.isRecurrence__c);
            event.put('Event_Recurrence__c', er.Event.Event_Recurrence__c);
            event.put('Event_Address__c', er.Event.Event_Address__c);
            event.put('Comments__c', er.Event.Comments__c);
            event.put('Meeting_Link__c', er.Event.Meeting_Link__c);
            event.put('Mode_of_Delivery__c', er.Event.Mode_of_Delivery__c);
            event.put('CreatedDate', EventController.convertDateTimeToStringGMT(er.Event.CreatedDate));
            event.put('LastModifiedDate', EventController.convertDateTimeToStringGMT(er.Event.LastModifiedDate));


            events.add(event);
        }

        return events;
    }

    /*
     *
     * METHODS FOR CLIENTS OR CER
     *
     * */

    //to add one or more CERs to an existing event
    public static List<Map<String, Object>> addCERsToAnEvent(List<String> ids, Id eventId, String action) {
        System.debug('adding cers to an event');
        List<Client_Event_Relation__c> newCERs = new List<Client_Event_Relation__c>();
        List<Event> eventsToUpdate = new List<Event>();


        //update the number of clients
        Event e = [SELECT Id, Number_of_Clients__c, StartDateTime, Event_Recurrence__c FROM Event WHERE Id =: eventId];
        e.Number_of_Clients__c += ids.size();

        if(action == 'saveOne'){
            eventsToUpdate.add(e);

            for(String contactId : ids) {
                Client_Event_Relation__c cer = new Client_Event_Relation__c();
                cer.Client__c = contactId;
                cer.Event_Id__c = eventId;
                cer.Status__c = 'Pending';

                newCERs.add(cer);
            }
        } else {
            DateTime NOW = DateTime.now();
            for(Event ev : [SELECT Id, Number_of_Clients__c FROM Event WHERE Event_Recurrence__c =: e.Event_Recurrence__c AND (StartDateTime >=: e.StartDateTime AND StartDateTime >=: NOW)]){
                ev.Number_of_Clients__c += ids.size();
                eventsToUpdate.add(ev);

                for(String contactId : ids) {
                    Client_Event_Relation__c cer = new Client_Event_Relation__c();
                    cer.Client__c = contactId;
                    cer.Event_Id__c = ev.Id;
                    cer.Status__c = 'Pending';

                    newCERs.add(cer);
                }
            }

        }

        try {
            insert newCERs;
            update eventsToUpdate;
        } catch (DMLException error) {
            System.debug(error.getMessage());
        }

        String baseURL = URL.getSalesforceBaseUrl().toExternalForm();
        List<Client_Event_Relation__c> cers = [SELECT id, Event_Link__c, Client__r.Id ,Client__r.Name, Status__c FROM Client_Event_Relation__c WHERE Event_Id__c =: eventId];
        return createClientList(cers, baseURL);
    }

    //to update an existing CER status on an existing event
    //action is always update
    //newStatus can be cancelled, booked, deleted
    public static void handleCERStatusChange(String action, Id CERid, String newStatus, String saveType) {
        System.debug('Current action: ' + action + ', current newStatus: ' + newStatus);

        Client_Event_Relation__c cer = [SELECT id, Client__c, Event_Id__c, Status__c FROM Client_Event_Relation__c WHERE id =: CERid];
        List<Client_Event_Relation__c> newCERs = new List<Client_Event_Relation__c>();
        List<Client_Event_Relation__c> deletedCERs = new List<Client_Event_Relation__c>();
        List<Id> affectedEventIds = new List<Id>();

        if(saveType == 'saveOne'){
            affectedEventIds.add(cer.Event_Id__c);

            if (action == 'update') {

                if(newStatus == 'Booked' || newStatus == 'Cancelled'){
                    cer.Status__c = newStatus;
                    newCERs.add(cer);

                } else if(newStatus == 'Deleted'){
                    deletedCERs.add(cer);
                }
            }

        } else {
            Event e = [SELECT Id, StartDateTime, Event_Recurrence__c FROM Event WHERE Id =: cer.Event_Id__c];

            DateTime NOW = DateTime.now();
            Set<Id> futureEvents = new Set<Id>();

            for(Event ev : [SELECT Id FROM Event WHERE Event_Recurrence__c =: e.Event_Recurrence__c AND (StartDateTime >=: e.StartDateTime AND StartDateTime >=: NOW)]){
                affectedEventIds.add(ev.Id);
            }

            //get all of this client's CER
            List<Client_Event_Relation__c> futureCERs = [SELECT Id, Event_Id__c, Status__c FROM Client_Event_Relation__c WHERE Event_Id__c IN: affectedEventIds AND Client__c =: cer.Client__c];

            if (action == 'update') {
                for(Client_Event_Relation__c updateCER : futureCERs){
                    if(newStatus == 'Booked' || newStatus == 'Cancelled'){
                        updateCER.Status__c = newStatus;
                        newCERs.add(updateCER);

                    } else if(newStatus == 'Deleted'){
                        deletedCERs.add(updateCER);
                    }
                }
            }
        }

        try {
            update newCERs;
            delete deletedCERs;
        } catch (DMLException error) {
            System.debug(error);
        }

        if(!deletedCERs.isEmpty()){
            updateEventStatusBasedOnNumberOfClientsWorkers(affectedEventIds, -1, 'client');
        }
    }

    //get the list of cers - you can pass multiple workers here if needed for the calendar
    public static List<Map<String, Object>> getClientEvents(List<Id> contactIds, Integer cutOffDays) {
        List<Client_Event_Relation__c> cers = [SELECT Id, Event_Id__c, Status__c FROM Client_Event_Relation__c WHERE Client__c =: contactIds];

        Map<Id, String> cerStatus = new Map<Id, String>();
        Set<Id> cerIds = new Set<Id>();

        for (Client_Event_Relation__c cer : cers) {
            cerIds.add(cer.Event_Id__c);
            cerStatus.put(cer.Event_Id__c, cer.Status__c);
        }

        DateTime cutoff = System.today() - cutOffDays;

        List<Event> events = [SELECT Id, Owner.Name, Event_Address__c, Comments__c, Meeting_Link__c, Mode_Of_Delivery__c, CreatedDate, LastModifiedDate, OwnerId, enrtcr__Client__c, StartDateTime, Event_Type__c, Event_Recurrence__c,
                              EndDateTime, Event_Status__c, Subject, IsAllDayEvent, isRecurrence__c
                              FROM Event WHERE Id IN: cerIds AND StartDateTime >: cutoff];

        return CERsToEvents(events, cerStatus);
    }

	//this is the map of event that will be passed to BR_Calendar, containing details of the event object (not including worker/clients)
    //this is mainly used to load the events in a client calendar
    private static List<Map<String,Object>> CERsToEvents(List<Event> cers, Map<Id, String> cerStatus) {

        List<Map<String,Object>> events = new List<Map<String,Object>>();

        for (Event cer : cers) {
            Map<String, Object> event = new Map<String, Object>();

            event.put('Id', cer.Id);
            event.put('Subject', cer.Subject);
            event.put('OwnerId', cer.OwnerId);
            event.put('enrtcr__Client__c', cer.enrtcr__Client__c); //what is this?
            event.put('OwnerName', cer.Owner.Name);
            event.put('StartDateTime', cer.StartDateTime);
            event.put('EndDateTime', cer.EndDateTime);
            event.put('Event_Type__c', cer.Event_Type__c);
            event.put('Event_Status__c', cerStatus.get(cer.Id));
            event.put('IsAllDayEvent', cer.IsAllDayEvent);
            event.put('isRecurrence__c', cer.isRecurrence__c);
            event.put('Event_Recurrence__c', cer.Event_Recurrence__c);
            event.put('Event_Address__c', cer.Event_Address__c);
            event.put('Comments__c', cer.Comments__c);
            event.put('Meeting_Link__c', cer.Meeting_Link__c);
            event.put('Mode_of_Delivery__c', cer.Mode_of_Delivery__c);
            event.put('CreatedDate', EventController.convertDateTimeToStringGMT(cer.CreatedDate));
            event.put('LastModifiedDate', EventController.convertDateTimeToStringGMT(cer.LastModifiedDate));

            events.add(event);
        }

        return events;
    }

    //find clashing workers and clients before creating an event
    public static String[] findClashingWorkerAndClientEvents(String eventJSON, CalendarClass.EventDetail eventObject, List<CalendarClass.Worker> convertedWorkers, List<CalendarClass.Client> convertedClients){
        Contact contactToShareEvent = [SELECT Id FROM Contact WHERE LastName = 'to share events'];

        Set<String> setOfClashingWorkersAndClients = new Set<String>();

        List<Id> workerIds = new List<Id>();
        List<Id> clientIds = new List<Id>();

        for(CalendarClass.Worker w : convertedWorkers){
            workerIds.add(w.Id);
        }

        for(CalendarClass.Client c : convertedClients){
            clientIds.add(c.Id);
        }

        Map<Id, Event> idsOfClashedEvents = retrieveClashingEventIds(eventJSON);
        List<ID> eventsForClients = new List<ID>();
        List<ID> eventsForWorkers = new List<ID>();

        //separate between which event we want to check for clash
        //for clients, only check for clash for Initials and Therapy
        //for workers, check for all types of event
        for(Event e : idsOfClashedEvents.values()){
            if(e.Event_Type__c == 'Initial Appointment' || e.Event_Type__c == 'Therapy Session'){
                eventsForClients.add(e.Id);
                eventsForWorkers.add(e.Id);
            } else {
                eventsForWorkers.add(e.Id);
            }
        }

        //always find clash for workers - regardless of what event type the user is creating
        List<EventRelation> listOfER = [SELECT Id, RelationId, Relation.Name, EventId FROM EventRelation WHERE (Status = 'New' OR Status = 'Accepted') AND RelationId IN: workerIds AND EventId IN: eventsForWorkers AND RelationId != :contactToShareEvent.Id ORDER BY RelationId];
        List<Client_Event_Relation__c> listOfCER = new List<Client_Event_Relation__c>();

        //only find clash for worker if the user is trying to make an initial or therapy
        //if the form is NOT initials or therapy, only search the worker avails
        if(eventObject.eventType == 'Initial Appointment' || eventObject.eventType == 'Therapy Session'){
            listOfCER = [SELECT Id, Client__c, Client__r.Id, Client__r.FirstName, Client__r.LastName FROM Client_Event_Relation__c WHERE (Status__c = 'Pending' OR Status__c = 'Booked') AND Client__c IN: clientIds AND Event_Id__c IN: eventsForClients ORDER BY Client__c];
        }


        //for each client, set up the map
        if(!listOfER.isEmpty()){

            for(Id w : workerIds){
                for(EventRelation er : listOfER){
                    if(er.RelationId == w){
                        setOfClashingWorkersAndClients.add(er.Relation.Name);
                        System.debug('This client has a clashing event. Name is: ' + er.Relation.Name);
                    } else {
                        System.debug('This client does NOT have a clashing event. Name is: ' + er.Relation.Name);
                    }
                }
            }
        } else {
            System.debug('No CERs in any of the event that happens at the same time with our worker');
        }

        //for each client, set up the map
        if(!listOfCER.isEmpty()){

            for(Id c : clientIds){
                for(Client_Event_Relation__c cer : listOfCER){
                    if(cer.Client__r.Id == c){
                        String clientFullName = cer.Client__r.FirstName + ' ' + cer.Client__r.LastName;
                        setOfClashingWorkersAndClients.add(clientFullName);
                        System.debug('This client has a clashing event. Name is: ' + cer.Client__r.FirstName);
                    } else {
                        System.debug('This client does NOT have a clashing event. Name is: ' + cer.Client__r.FirstName);
                    }
                }
            }
        } else {
            System.debug('No CERs in any of the event that happens at the same time with our client');
        }

        String[] listOfClashingContacts = new List<String>();

        for(String finalWorkersAndClients : setOfClashingWorkersAndClients){
            listOfClashingContacts.add(finalWorkersAndClients);
        }

        return listOfClashingContacts;

    }

    //to create cers
    public static List<Client_Event_Relation__c> createCERs(List<Event> events , List<CalendarClass.Client> clients, String status) {
        List<Client_Event_Relation__c> clientEventRelations = new List<Client_Event_Relation__c>();
        for (Event e : events) {
            for (CalendarClass.Client client : clients) {
                Client_Event_Relation__c cer = new Client_Event_Relation__c();
                cer.Event_Id__c = e.Id;
                cer.Client__c = client.Id;
                cer.Status__c = status;

                clientEventRelations.add(cer);
            }
        }

        return clientEventRelations;
    }

     /*
     *
     * OTHER UTILITY METHODS
     *
     * */

    private static Integer getPeriodInteger(String period) {
        if (period == 'Day') return 1;
        else if (period == 'Week') return 7;
        //else if (period == 'Month') return 30;

        return 1;
    }

    private static Date dateStringToDate(String dt) {
        List<String> dateParts = dt.split('-');

        Integer year = Integer.valueOf(dateParts[0]);
        Integer month = Integer.valueOf(dateParts[1]);
        Integer day = Integer.valueOf(dateParts[2]);

        Date newDate = Date.newInstance(year, month, day);

        return newDate;
    }

    private static Date convertToDate(String dt) {
        List<String> fullString = dt.split('T');
        List<String> dateParts = fullString[0].split('-');

        Integer year = Integer.valueOf(dateParts[0]);
        Integer month = Integer.valueOf(dateParts[1]);
        Integer day = Integer.valueOf(dateParts[2]);

        Date newDate = Date.newInstance(year, month, day);

        return newDate;
    }

    private static String convertDateTimeToStringGMT(DateTime dt) {
        return dt.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
    }

    private static DateTime convertToLocal(String GMTTime) {
        Timezone tz = UserInfo.getTimeZone();

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

    private static DateTime convertToDateTime(String timeStr, Boolean allDay) {
        List<String> fullString = timeStr.split('T');
        List<String> dateParts = fullString[0].split('-');
        List<String> timeParts = fullString.size() == 2 ? fullString[1].split(':') : null;

        Integer year = Integer.valueOf(dateParts[0]);
        Integer month = Integer.valueOf(dateParts[1]);
        Integer day = Integer.valueOf(dateParts[2]);
        Integer hour = allDay ? 0 : Integer.valueOf(timeParts[0]);
        Integer minute = allDay ? 0 : Integer.valueOf(timeParts[1]);

        DateTime dtObj = DateTime.newInstance(year, month, day, hour, minute, 0);

        return dtObj;
    }
}