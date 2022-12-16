public class AnalyticsController {
    
    @AuraEnabled
    public static List<Object> pullData(String selected, String startDate, String endDate) {
        switch on (selected) {
            when 'Clinical Audit' {
                return pullCAData(parseDateString(startDate), parseDateString(endDate));
            }
            when 'Procedural Audit'{
                return pullPAData(parseDateString(startDate), parseDateString(endDate));
            }
        }
        return new List<Object>();
    }
    
    private static List<Object> pullCAData(DateTime startTime, DateTime endTime) {
        return [SELECT BreakdownJSON__c, Clinical_Area__c, Clinician__r.Clinician_Discipline__c FROM Clinical_Audit__c WHERE Audit_Type__c = 'Clinical Audit' AND CreatedDate > :startTime AND CreatedDate < :endTime];
    }
    
    private static List<Object> pullPAData(DateTime startTime, DateTime endTime) {
        return [SELECT BreakdownJSON__c, Clinical_Area__c, Clinician__r.Clinician_Discipline__c FROM Clinical_Audit__c WHERE Audit_Type__c = 'Procedural Audit' AND CreatedDate > :startTime AND CreatedDate < :endTime];
    }
    
    private static DateTime parseDateString(String d) {
        List<String> parts = d.split('-');
        
        Integer year = Integer.valueOf(parts[0]);
        Integer month = Integer.valueOf(parts[1]);
        Integer day = Integer.valueOf(parts[2]);
        
        return DateTime.newInstance(year, month, day);
    }
    
    @AuraEnabled(cacheable=true)
    public static List<User> getCurrentUserKPI(Id userId){
        List<User> currentUser = [SELECT Id, KPI__c, Title, Name FROM User WHERE Id =: userId];
        
        return currentUser;
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, List<AggregateResult>> getAggregateEvents(Id userId){
        //get the Contact ID of the current user
        Contact userContact = [SELECT Id FROM Contact WHERE enrtcr__User__c =: userId];
        
        //set the weekly boundaries        
        Map<String, List<Datetime>> weekToDates = new Map<String, List<Datetime>>();
        
        //week starts on a sunday
        Date thisWeekDate = System.today().toStartOfWeek();
        Date endWeekDate = thisWeekDate.addDays(27);
        
        System.debug('This week start date: ' + thisWeekDate);
        System.debug('End week end date: ' + endWeekDate);
        
        //convert to Datetime
        DateTime startDT = DateTime.newInstance(thisWeekDate.year(), thisWeekDate.month(), thisWeekDate.day());
        DateTime endDT = DateTime.newInstance(endWeekDate.year(), endWeekDate.month(), endWeekDate.day());
        
        System.debug('startDT: ' + startDT);
        System.debug('endDT: ' + endDT);
        
        for(Integer i = 0; i < 4; i++){
            //NEED to get the date of this week, next 1 week, next 2, next 3 weeks            
            List<Datetime> dates = new List<Datetime>();
            Datetime starting = startDT.addDays(i * 7);
            System.debug(starting);
            Datetime ending = starting.addDays(6);
            System.debug(ending);
            dates.add(starting);
            dates.add(ending);
            
            //Integer weekNumber = i + 1;
            
           // Date rangeStart = Date.newInstance(starting.year(), starting.month(), starting.day());
            //Date rangeEnd = Date.newInstance(ending.year(), ending.month(), ending.day());
            
            String rangeStart = starting.day() + '/' + starting.month() + '/' + starting.year();
            String rangeEnd = ending.day() + '/' + ending.month() + '/' + ending.year();
            
            String weekRange = rangeStart + ' - ' + rangeEnd; 
           
            weekToDates.put(weekRange, dates);
           
        }
        
        System.debug('Result of weekToDates map: ' + weekToDates);
        
        
        Map<String, List<AggregateResult>> weekToResult = new Map<String, List<AggregateResult>>();
        
        //we need to query only events where ER = the current user's id
        //get all the events in this KPI period - this is all better rehab's events
        List<Event> evs = [SELECT Id, Event_Type__c, Subject, StartDateTime, EndDateTime, DurationInMinutes FROM Event WHERE 
                           RecordTypeId =: Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('BR_Event').getRecordTypeId() 
                           AND (StartDateTime = THIS_WEEK OR StartDateTime = NEXT_N_WEEKS:3)
                           AND Event_Type__c IN ('Initial Appointment', 'Therapy Session', 'Other PCH')
                           AND Event_Status__c != 'Cancelled'];  
        
        //get all the ER of this person
        List<EventRelation> listOfER = [SELECT Id, EventId, Relation.Name, RelationId FROM EventRelation WHERE EventId IN: evs AND Relation.Name != 'Contact to share events' AND RelationId =: userContact.Id];
        
        //add the sorted event ids here
        Set<Id> eventIds = new Set<Id>();
        for(EventRelation er : listOfER){
            eventIds.add(er.EventId);
        }
        
        for(String weekNumber : weekToDates.keySet()){
            
            List<Datetime> datesToQuery = weekToDates.get(weekNumber);
            
            //in here, we just need to aggregate the result in evs and group them per event type
            //can we replace this with a for loop? CHECK TOMORROW!
            List<AggregateResult> newResult =  [SELECT Event_Type__c, SUM(DurationInMinutes) totalDuration FROM Event WHERE 
                                                (StartDateTime >=: datesToQuery[0] AND StartDateTime <=: datesToQuery[1])
                                                AND Id IN: eventIds
                                                GROUP BY Event_Type__c];
            
            weekToResult.put(weekNumber, newResult);
        }
        
        System.debug('Result of weekToResult map: ' + weekToResult);
        
        return weekToResult;
        
    }
    
    //heap issue
    //used in the diary management reports    
    /*@AuraEnabled(cacheable = true)
    public static Map<String, List<EventDetail>> getEvents(){
        System.debug('Inside getEvents');
        
        //38k records
        Map<Id, EventRelation> newERList = new Map<Id, EventRelation>([SELECT Id, EventId, Relation.Name, RelationId, Event.Event_Type__c, Event.StartDateTime, Event.EndDateTime, Event.DurationInMinutes 
                                                                       FROM EventRelation WHERE Relation.Name != 'Contact to share events' AND Status != 'Declined' 
                                                                       AND Event.RecordTypeId =: Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('BR_Event').getRecordTypeId()
                                                                       AND (Event.StartDateTime = THIS_WEEK OR Event.StartDateTime = NEXT_N_WEEKS:3)
                                                                       AND Event.Event_Status__c != 'Cancelled']);
        
        System.debug('Size of newERList: ' + newERList.size());        
       
        Set<Id> uniqueListOfRelationId = new Set<Id>();
        //this might be inefficient?
        for(EventRelation er : newERList.values()){
            uniqueListOfRelationId.add(er.RelationId);
        }
        
        //400 records?
        Map<Id, Contact> clinicianDetails = new Map<Id, Contact>([SELECT Id, Name, Clinician_Discipline__c, enrtcr__User__r.KPI__c, enrtcr__User__r.TeamLeader__c, enrtcr__Site__r.Name, enrtcr__Site__r.enrtcr__Business_State__c FROM Contact 
                                                                  WHERE Id IN: uniqueListOfRelationId
                                                                  AND Internal_Banding__c NOT IN ('Regional Manager', 'State Manager', 'Director', 'Student')
                                                                  AND Clinician_Discipline__c IN ('Occupational Therapy', 'Speech Therapy', 'Social Work', 'Allied Health Assistant', 'Exercise Physiology', 'PBS', 'Physiotherapy')]);
        
        //make the EventDetail custom object
        //1 list for each worker        
        Map<String, List<EventDetail>> finalResult = new Map<String, List<EventDetail>>();
        
        for(Contact c : clinicianDetails.values()){
            List<EventDetail> listOfEvents = new List<EventDetail>();
            
            for(EventRelation ers : newERList.values()){
                if(ers.RelationId == c.Id){
                    
                    EventDetail newEvent = new EventDetail();
                    
                    newEvent.Id = ers.EventId;
                    DateTime sDT = newERList.get(ers.Id).Event.StartDateTime;
                    newEvent.startDate = Date.newInstance(sDT.year(), sDT.month(), sDT.day());
                    
                    DateTime eDT = newERList.get(ers.Id).Event.EndDateTime;
                    newEvent.endDate = Date.newInstance(eDT.year(), eDT.month(), eDT.day());
                    
                    newEvent.durationInMinutes = newERList.get(ers.Id).Event.DurationInMinutes;
                    
                    newEvent.eventType = newERList.get(ers.Id).Event.Event_Type__c;       
                    
                    //remove the map of event relation to reduce heap size
                    newERList.remove(ers.Id);
                    
                    listOfEvents.add(newEvent);                    
                                        
                }
            }            
            
            String serializedList = JSON.serialize(c);
            finalResult.put(serializedList, listOfEvents);
            
            //remove the map of event relation to reduce heap size
            clinicianDetails.remove(c.Id);
            
        }
        
        System.debug('Heap size that has been used: ' + Limits.getHeapSize());
        System.debug('Heap size that CAN been used: ' + Limits.getLimitHeapSize());
        
        System.debug('Size of finalResult: ' + finalResult.size());
        
        for(String w : finalResult.keySet()){
            System.debug(w);
            System.debug(finalResult.get(w));
        }
        
        return finalResult;
    }*/
    
    //apex cpu time limit issue
    @AuraEnabled(cacheable = true)
    public static Map<String, List<EventDetail>> getEvents(){
        System.debug('Inside getEvents');       
       
        Set<Id> uniqueListOfRelationId = new Set<Id>();
        Map<Id, Event> mapOfEvent = new Map<Id, Event>();
        
        //will get all clinicians in BR
        Map<Id, Contact> clinicianDetails = new Map<Id, Contact>([SELECT Id, Name, Clinician_Discipline__c, enrtcr__User__r.KPI__c, enrtcr__User__r.TeamLeader__c, 
                                                                  enrtcr__Site__r.Name, enrtcr__Site__r.enrtcr__Business_State__c FROM Contact 
                                                                  WHERE enrtcr__Status__c = 'Current' 
                                                                  AND RecordTypeId =: Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Employee').getRecordTypeId()
                                                                  AND enrtcr__User__c != NULL
                                                                  AND enrtcr__Site__c != NULL
                                                                  AND Internal_Banding__c NOT IN ('Regional Manager', 'State Manager', 'Director', 'Student')
                                                                  AND Clinician_Discipline__c IN ('Occupational Therapy', 'Speech Therapy', 'Social Work', 'Allied Health Assistant', 'Exercise Physiology', 'PBS', 'Physiotherapy')
                                                                  ]);
       
        //make the EventDetail custom object
        //1 list for each worker        
        Map<String, List<EventDetail>> finalResult = new Map<String, List<EventDetail>>();
        
        /*for(List<EventRelation> testAgain : [SELECT Id, EventId, Relation.Name, RelationId, Event.Event_Type__c, Event.StartDateTime, Event.EndDateTime, Event.DurationInMinutes 
                                             FROM EventRelation WHERE Relation.Name != 'Contact to share events' AND Status != 'Declined' 
                                             AND Event.RecordTypeId =: Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('BR_Event').getRecordTypeId()
                                             AND (Event.StartDateTime = THIS_WEEK OR Event.StartDateTime = NEXT_N_WEEKS:3)
                                             AND Event.Event_Status__c != 'Cancelled'])
        {
            for(Contact c : clinicianDetails.values()){
                List<EventDetail> listOfEvents = new List<EventDetail>();
                
                for(EventRelation ers : testAgain){
                    if(ers.RelationId == c.Id){
                        
                        EventDetail newEvent = new EventDetail();
                        
                        newEvent.Id = ers.EventId;
                        DateTime sDT = ers.Event.StartDateTime;
                        newEvent.startDate = Date.newInstance(sDT.year(), sDT.month(), sDT.day());
                        
                        DateTime eDT = ers.Event.EndDateTime;
                        newEvent.endDate = Date.newInstance(eDT.year(), eDT.month(), eDT.day());
                        
                        newEvent.durationInMinutes = ers.Event.DurationInMinutes;
                        
                        newEvent.eventType = ers.Event.Event_Type__c;                    
                        
                        listOfEvents.add(newEvent);
                    }
                }      
                String serializedList = JSON.serialize(c);
                finalResult.put(serializedList, listOfEvents);
                
                //remove the map of event relation to reduce heap size
                //clinicianDetails.remove(c.Id);
            }*/
        
        //will be 38k records tho
        for(EventRelation ev : [SELECT Id, EventId, Relation.Name, RelationId, Event.Event_Type__c, Event.StartDateTime, Event.EndDateTime, Event.DurationInMinutes 
                                             FROM EventRelation WHERE Relation.Name != 'Contact to share events' AND Status != 'Declined' 
                                             AND Event.RecordTypeId =: Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('BR_Event').getRecordTypeId()
                                             AND (Event.StartDateTime = THIS_WEEK OR Event.StartDateTime = NEXT_N_WEEKS:3)
                                             AND Event.Event_Status__c != 'Cancelled'])
        {
            for(Contact c : clinicianDetails.values()){
                List<EventDetail> listOfEvents = new List<EventDetail>();                
                
                if(ev.RelationId == c.Id){
                    
                    EventDetail newEvent = new EventDetail();
                    
                    newEvent.Id = ev.EventId;
                    DateTime sDT = ev.Event.StartDateTime;
                    newEvent.startDate = Date.newInstance(sDT.year(), sDT.month(), sDT.day());
                    
                    DateTime eDT = ev.Event.EndDateTime;
                    newEvent.endDate = Date.newInstance(eDT.year(), eDT.month(), eDT.day());
                    
                    newEvent.durationInMinutes = ev.Event.DurationInMinutes;
                    
                    newEvent.eventType = ev.Event.Event_Type__c;                    
                    
                    listOfEvents.add(newEvent);
                }
                      
                String serializedList = JSON.serialize(c);
                finalResult.put(serializedList, listOfEvents);
                
                //remove the map of event relation to reduce heap size
                //clinicianDetails.remove(c.Id);
            }
        }
        
        System.debug('Heap size that has been used: ' + Limits.getHeapSize());
        System.debug('Heap size that CAN been used: ' + Limits.getLimitHeapSize());
        
        System.debug('Size of finalResult: ' + finalResult.size());
        
        for(String w : finalResult.keySet()){
            System.debug(w);
            System.debug(finalResult.get(w));
        }
        
        return finalResult;
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, List<EventDetail>> getTeamLeaderEvents(Id teamLeaderId){
        System.debug('Inside getEvents');
        
        Contact teamLeader = [SELECT Id, Name FROM Contact WHERE enrtcr__User__c =: teamLeaderId];
        
        //get the name or contact id of all the team member
        Map<Id, Contact> teamDetails = new Map<Id, Contact>([SELECT Id, Name, Clinician_Discipline__c, enrtcr__User__r.KPI__c, enrtcr__User__r.TeamLeader__c, enrtcr__Site__r.Name, enrtcr__Site__r.enrtcr__Business_State__c FROM Contact 
                                                             WHERE enrtcr__User__r.TeamLeader__c =: teamLeader.Name AND enrtcr__Status__c = 'Current']);
        
        System.debug('teamdetails: ' + teamDetails);
        
        Map<Id, EventRelation> newERList = new Map<Id, EventRelation>([SELECT Id, EventId, Relation.Name, RelationId, Event.Event_Type__c, Event.StartDateTime, Event.EndDateTime, Event.DurationInMinutes 
                                                                       FROM EventRelation WHERE Relation.Name != 'Contact to share events' AND Status != 'Declined' 
                                                                       AND RelationId IN: teamDetails.keySet()
                                                                       AND Event.RecordTypeId =: Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('BR_Event').getRecordTypeId()
                                                                       AND (Event.StartDateTime = THIS_WEEK OR Event.StartDateTime = NEXT_N_WEEKS:3)
                                                                       AND Event.Event_Status__c != 'Cancelled']);
        
        System.debug('Size of newERList: ' + newERList.size());  
        
        //make the EventDetail custom object
        //1 list for each worker        
        Map<String, List<EventDetail>> finalResult = new Map<String, List<EventDetail>>();
        
        for(Contact c : teamDetails.values()){
            List<EventDetail> listOfEvents = new List<EventDetail>();
            
            for(EventRelation ers : newERList.values()){
                if(ers.RelationId == c.Id){
                    
                    EventDetail newEvent = new EventDetail();
                    
                    newEvent.Id = ers.EventId;
                    DateTime sDT = newERList.get(ers.Id).Event.StartDateTime;
                    newEvent.startDate = Date.newInstance(sDT.year(), sDT.month(), sDT.day());
                    
                    DateTime eDT = newERList.get(ers.Id).Event.EndDateTime;
                    newEvent.endDate = Date.newInstance(eDT.year(), eDT.month(), eDT.day());
                    
                    newEvent.durationInMinutes = newERList.get(ers.Id).Event.DurationInMinutes;
                    
                    newEvent.eventType = newERList.get(ers.Id).Event.Event_Type__c;       
                    
                    //remove the map of event relation to reduce heap size
                    newERList.remove(ers.Id);
                    
                    listOfEvents.add(newEvent);                    
                                        
                }
            }            
            
            String serializedList = JSON.serialize(c);
            finalResult.put(serializedList, listOfEvents);
            
            //remove the map of event relation to reduce heap size
            //clinicianDetails.remove(c.Id);
            
        }
        
        System.debug('Heap size that has been used: ' + Limits.getHeapSize());
        System.debug('Heap size that CAN been used: ' + Limits.getLimitHeapSize());
        
        System.debug('Size of finalResult for teamleader: ' + finalResult.size());
        
        for(String w : finalResult.keySet()){
            System.debug(w);
            System.debug(finalResult.get(w));
        }
        
        return finalResult;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<enrtcr__Site__c> getAllSites(){
        return [SELECT Id, Name, enrtcr__Business_State__c FROM enrtcr__Site__c WHERE RecordTypeId =: Schema.SObjectType.enrtcr__Site__c.getRecordTypeInfosByDeveloperName().get('Other').getRecordTypeId()];
    }
    
    public Class EventDetail {
        @AuraEnabled
        public String Id; //this is the event ID
        @AuraEnabled
        public Date startDate;
        @AuraEnabled
        public Date endDate;
        @AuraEnabled
        public Integer durationInMinutes;
        @AuraEnabled
        public String eventType;
    }
}