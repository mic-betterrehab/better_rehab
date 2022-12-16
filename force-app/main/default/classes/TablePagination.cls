public with sharing class TablePagination {    
    
    @AuraEnabled
    public static List<Map<String, Object>> getCERs(Id eventId) {
         return buildReturnCERs([SELECT id, Event_Link__c, Client__r.Id ,Client__r.Name, Status__c FROM Client_Event_Relation__c WHERE Event_Id__c =: eventId]);
    }
    
    @AuraEnabled
    public static List<Map<String, Object>> getERs(Id eventId) {
        return buildReturnERs([SELECT Id, Status, Relation.Id, Relation.Name FROM EventRelation WHERE EventId =: eventId]); 
    }
    
    @AuraEnabled
    public static List<Map<String, Object>> createCERs(List<String> ids, Id eventId, String action) {
        List<Client_Event_Relation__c> newCERs = new List<Client_Event_Relation__c>();
        List<Id> affectedEventIds = new List<Id>();
        
        if(action == 'saveOne'){
            
            for(String contactId : ids) {
                Client_Event_Relation__c cer = new Client_Event_Relation__c();
                cer.Client__c = contactId;
                cer.Event_Id__c = eventId;
                cer.Status__c = 'Pending';
                
                newCERs.add(cer);
                affectedEventIds.add(cer.Event_Id__c);
            } 
        } else {
            Event e = [SELECT Id, StartDateTime, Event_Recurrence__c FROM Event WHERE Id =: eventId];
            
            DateTime NOW = DateTime.now();
            for(Event ev : [SELECT Id FROM Event WHERE Event_Recurrence__c =: e.Event_Recurrence__c AND (StartDateTime >=: e.StartDateTime AND StartDateTime >=: NOW)]){
                for(String contactId : ids) {
                    Client_Event_Relation__c cer = new Client_Event_Relation__c();
                    cer.Client__c = contactId;
                    cer.Event_Id__c = ev.Id;
                    cer.Status__c = 'Pending';
                    
                    newCERs.add(cer);
                    affectedEventIds.add(cer.Event_Id__c);
                } 
            }
            
        }
        
        try {
            insert newCERs;
            updateEventClients(affectedEventIds, ids.size()); //use the ids size (number of contacts that comes through)
        } catch (DMLException error) {
            System.debug(error.getMessage());
        }

        return getCERs(eventId);    	
    }
    
    
    @AuraEnabled
    public static List<Map<String, Object>> createERs(List<String> ids, Id eventId, String action) {
        List<EventRelation> newERs = new List<EventRelation>();
        List<Id> affectedEventIds = new List<Id>();
        
        if(action == 'saveOne'){
            
            for (String contactId : ids) {
                EventRelation er = new EventRelation();
                er.EventId = eventId;
                er.Status = 'New';
                er.RelationId = contactId;
                
                newERs.add(er);
                affectedEventIds.add(er.EventId);
            }
        } else {
            Event e = [SELECT Id, StartDateTime, Event_Recurrence__c FROM Event WHERE Id =: eventId];
            
            DateTime NOW = DateTime.now();
            
            for(Event ev : [SELECT Id FROM Event WHERE Event_Recurrence__c =: e.Event_Recurrence__c AND StartDateTime >=: e.StartDateTime]){
                for (String contactId : ids) {
                    EventRelation er = new EventRelation();
                    er.EventId = ev.Id;
                    er.Status = 'New';
                    er.RelationId = contactId;
                    
                    newERs.add(er);
                    affectedEventIds.add(er.EventId);
                }
            }
            
        }
        
        System.debug('Size of newERs to add: ' + newERs.size());
        
        try {
            insert newERs;
            updateEventWorkers(affectedEventIds, ids.size());
        } catch (DMLException error) {
            System.debug(error.getMessage());
        }
        
        return getERs(eventId);
    }
    
    @AuraEnabled
    public static void handleCERchange(String action, Id CERid, String newStatus, String saveType) {
        System.debug('Current action: ' + action + ', current newStatus: ' + newStatus);
        
        Client_Event_Relation__c cer = [SELECT id, Client__c, Event_Id__c, Status__c FROM Client_Event_Relation__c WHERE id =: CERid];
        List<Client_Event_Relation__c> newCERs = new List<Client_Event_Relation__c>();
        List<Client_Event_Relation__c> deletedCERs = new List<Client_Event_Relation__c>();
        
        //List for updating the client numbers
        List<Id> eventCERsPreviouslyCancelled = new List<Id>();
        List<Id> eventCERsPreviouslyPending = new List<Id>();
        List<Id> eventCERsRemoved = new List<Id>();
        
        if(saveType == 'saveOne'){
                
            if (action == 'update') {
                
                if(newStatus == 'Booked'){
                    //check the cer's prev status
                    if(cer.Status__c == 'Pending'){ 
                        eventCERsPreviouslyPending.add(cer.Event_Id__c);                                                      
                    } else if(cer.Status__c == 'Cancelled'){
                        eventCERsPreviouslyCancelled.add(cer.Event_Id__c);
                    }  
                } else if(newStatus == 'Cancelled'){
                    eventCERsRemoved.add(cer.Event_Id__c);
                }
                
                cer.Status__c = newStatus;
                newCERs.add(cer);  
                
            } 
            
            /*else if (action == 'delete') {
                deletedCERs.add(cer);
                eventCERsRemoved.add(cer.Event_Id__c);
            }*/
            
        } else {
            Event e = [SELECT Id, StartDateTime, Event_Recurrence__c FROM Event WHERE Id =: cer.Event_Id__c];            
            
            DateTime NOW = DateTime.now();            
            Set<Id> futureEvents = new Set<Id>();
            
            for(Event ev : [SELECT Id FROM Event WHERE Event_Recurrence__c =: e.Event_Recurrence__c AND (StartDateTime >=: e.StartDateTime AND StartDateTime >=: NOW)]){
                futureEvents.add(ev.Id);
            }
            
            //get all of this client's CER
            List<Client_Event_Relation__c> futureCERs = [SELECT Id, Event_Id__c, Status__c FROM Client_Event_Relation__c WHERE Event_Id__c IN: futureEvents AND Client__c =: cer.Client__c];
            
            if (action == 'update') {
                for(Client_Event_Relation__c updateCER : futureCERs){
                    if(newStatus == 'Cancelled'){
                        
                        //checking the prev status of each CER in the list
                        if(updateCER.Status__c == 'Booked'){   
                            System.debug('Status before is booked');
                            updateCER.Status__c = newStatus;
                            newCERs.add(updateCER);
                        } else if(updateCER.Status__c == 'Pending'){
                            deletedCERs.add(updateCER);
                        }
                        
                        System.debug('adding eventCERsRemoved');
                        eventCERsRemoved.add(updateCER.Event_Id__c);
                        
                    } else if(newStatus == 'Booked'){
                        
                        //checking the prev status of each CER in the list
                        if(updateCER.Status__c == 'Pending'){ 
                            eventCERsPreviouslyPending.add(updateCER.Event_Id__c);                                                      
                        } else if(updateCER.Status__c == 'Cancelled'){
                            eventCERsPreviouslyCancelled.add(updateCER.Event_Id__c);
                        }                        
                        
                        //can change CER status to book from any prev status: pending/cancelled
                        updateCER.Status__c = newStatus;
                        newCERs.add(updateCER);  
                    }
                }
            } 
            
            /*else if (action == 'delete') {
                for(Client_Event_Relation__c updateCER : futureCERs){
                    deletedCERs.add(updateCER); 
                    System.debug('adding eventCERsRemoved');
                    eventCERsRemoved.add(updateCER.Event_Id__c);
                }
            }*/        
        }
        
        System.debug('Size of eventCERsRemoved up here: ' + eventCERsRemoved.size());
        
        try {
            update newCERs;
            delete deletedCERs;
        } catch (DMLException error) {
            System.debug(error);
        }      
        
        // update linked event logic        
        if(newStatus == 'Booked'){
            if(!eventCERsPreviouslyCancelled.isEmpty()){
                updateEventClients(eventCERsPreviouslyCancelled, 1);
            }
            
            if(!eventCERsPreviouslyPending.isEmpty()){
                updateEventClients(eventCERsPreviouslyPending, 0);
            }
        }
        
        if (newStatus == 'Cancelled' || action == 'delete'){     
            System.debug('Hello removing a client now');
            System.debug('Size of eventCERsRemoved: ' + eventCERsRemoved.size()); //why does this keep being 0?
            if(!eventCERsRemoved.isEmpty()){
                updateEventClients(eventCERsRemoved, -1);
            }
        }
        
    }
    
    @AuraEnabled
    public static void handleERchange(String action, Id ERid, String newStatus, String saveType) {
        EventRelation er = [SELECT id, RelationId, EventId, Status FROM EventRelation WHERE id =: ERid];
        String translatedNewStatus = translateStatus(newStatus);
        String previousStatus = translateStatus(er.Status);
        
        List<EventRelation> newERs = new List<EventRelation>();
        List<EventRelation> deletedERs = new List<EventRelation>();
        List<Id> affectedEventIds = new List<Id>();
        
        //List for updating the client numbers
        List<Id> eventERsPreviouslyCancelled = new List<Id>();
        List<Id> eventERsPreviouslyPending = new List<Id>();
        List<Id> eventERsRemoved = new List<Id>();
        
        /*if (action == 'update') {
            er.Status = translatedNewStatus;
            
            try {
                update er;
            } catch (DMLException error) {
                System.debug(error);
            }
        } else if (action == 'delete') {
            try {
                delete er;
            } catch (DMLException error) {
                System.debug(error);
            }
        }*/
        
        if(saveType == 'saveOne'){
            affectedEventIds.add(er.EventId);
                
            if (action == 'update') {
                
                if(newStatus == 'Booked'){
                    //check the er's prev status
                    if(translateStatus(er.Status) == 'Pending'){ 
                        eventERsPreviouslyPending.add(er.EventId);                                                      
                    } else if(translateStatus(er.Status) == 'Cancelled'){
                        eventERsPreviouslyCancelled.add(er.EventId);
                    }  
                }  else if(newStatus == 'Cancelled'){
                    eventERsRemoved.add(er.EventId);
                }
                
                er.Status = translatedNewStatus;
                newERs.add(er);    
                
                
            } 
            
            /*else if (action == 'delete') {
                deletedERs.add(er);
                eventERsRemoved.add(er.EventId);
            }*/
            
        } else {
            Event e = [SELECT Id, StartDateTime, Event_Recurrence__c FROM Event WHERE Id =: er.EventId];            
            
            DateTime NOW = DateTime.now();            
            Set<Id> futureEvents = new Set<Id>();
            
            for(Event ev : [SELECT Id FROM Event WHERE Event_Recurrence__c =: e.Event_Recurrence__c AND (StartDateTime >=: e.StartDateTime AND StartDateTime >=: NOW)]){
                futureEvents.add(ev.Id);
                affectedEventIds.add(ev.Id);
            }
            
            //get all of this client's CER
            List<EventRelation> futureERs = [SELECT Id, EventId, Status FROM EventRelation WHERE EventId IN: futureEvents AND RelationId =: er.RelationId];
            System.debug('How many futureERs? ' + futureERs);
            
            if (action == 'update') {
                for(EventRelation updateER : futureERs){
                    System.debug('updateER ' + updateER);
                    
                    if(newStatus == 'Cancelled'){
                        
                        if(translateStatus(updateER.Status) == 'Booked'){                            
                            updateER.Status = translatedNewStatus; // translatedNewStatus is declined
                            newERs.add(updateER);
                            
                        } else if(translateStatus(updateER.Status) == 'Pending'){
                            deletedERs.add(updateER);
                        }
                        
                        eventERsRemoved.add(updateER.EventId);
                        
                    } else if(newStatus == 'Booked'){
                        
                        //checking the prev status of each CER in the list
                        if(translateStatus(updateER.Status) == 'Pending'){ 
                            eventERsPreviouslyPending.add(updateER.EventId); 
                        } else if(translateStatus(updateER.Status) == 'Cancelled'){
                            eventERsPreviouslyCancelled.add(updateER.EventId);
                        }
                        
                        //you can change ER status from anything to booked
                        updateER.Status = translatedNewStatus; // translatedNewStatus is accepted
                        newERs.add(updateER);                            
                    }
                }
                
                
            } 
            
            /*else if (action == 'delete') {
                for(EventRelation updateER : futureERs){
                    deletedERs.add(updateER);
                    eventERsRemoved.add(updateER.EventId);
                }
            }*/        
        }
        
        try {
            update newERs;
            delete deletedERs;
        } catch (DMLException error) {
            System.debug(error);
        }      
        
        // update linked event logic     
        if(newStatus == 'Booked'){
            if(!eventERsPreviouslyCancelled.isEmpty()){
                updateEventWorkers(eventERsPreviouslyCancelled, 1);
            }
            
            if(!eventERsPreviouslyPending.isEmpty()){
                updateEventWorkers(eventERsPreviouslyPending, 0);
            }
        }
        
        if (newStatus == 'Cancelled' || action == 'delete'){            
            if(!eventERsRemoved.isEmpty()){
                System.debug('update event workers when newstatus is cancelled or action is delete');
                updateEventWorkers(eventERsRemoved, -1);
            }
        }
        
    }

    @AuraEnabled
    public static void deleteCER(Id CERid, String saveType) {
        List<Id> affectedEventIds = new List<Id>();
        List<Client_Event_Relation__c> deletedCERs = new List<Client_Event_Relation__c>();
        
        Client_Event_Relation__c cer = [SELECT id, Client__c, Event_Id__c FROM Client_Event_Relation__c WHERE id =: CERid];
        
        if(saveType == 'saveOne'){
            affectedEventIds.add(cer.Event_Id__c);
            
            deletedCERs.add(cer);
            
        } else {
            Event e = [SELECT Id, StartDateTime, Event_Recurrence__c FROM Event WHERE Id =: cer.Event_Id__c];            
            
            DateTime NOW = DateTime.now();            
            Set<Id> futureEvents = new Set<Id>();
            
            for(Event ev : [SELECT Id FROM Event WHERE Event_Recurrence__c =: e.Event_Recurrence__c AND (StartDateTime >=: e.StartDateTime AND StartDateTime >=: NOW)]){
                futureEvents.add(ev.Id);
            }
            
            //get all of this client's CER
            for(Client_Event_Relation__c c : [SELECT Id, Event_Id__c FROM Client_Event_Relation__c WHERE Event_Id__c IN: futureEvents AND Client__c =: cer.Client__c]){
                affectedEventIds.add(c.Event_Id__c);
                deletedCERs.add(c);
            }
        }
        
        try {
            delete deletedCERs;
        } catch (DMLException error) {
            System.debug(error);
        }
        
        updateEventClients(affectedEventIds, -1); //always -1 because no feature to delete >1 client/worker in 1 event
    	
        return;
    }
    
    @AuraEnabled
    public static void deleteER(Id erId, String saveType) {
        List<Id> affectedEventIds = new List<Id>();
        List<EventRelation> deletedERs = new List<EventRelation>();
        
        EventRelation er = [SELECT id, RelationId, EventId FROM EventRelation WHERE id =: erId];
        
        if(saveType == 'saveOne'){
            affectedEventIds.add(er.EventId);
            
            deletedERs.add(er);
            
        } else {
            Event e = [SELECT Id, StartDateTime, Event_Recurrence__c FROM Event WHERE Id =: er.EventId];            
            
            DateTime NOW = DateTime.now();            
            Set<Id> futureEvents = new Set<Id>();
            
            for(Event ev : [SELECT Id FROM Event WHERE Event_Recurrence__c =: e.Event_Recurrence__c AND (StartDateTime >=: e.StartDateTime AND StartDateTime >=: NOW)]){
                futureEvents.add(ev.Id);
            }
            
            //get all of this client's CER
            for(EventRelation worker : [SELECT Id, EventId FROM EventRelation WHERE EventId IN: futureEvents AND RelationId =: er.RelationId]){
                affectedEventIds.add(worker.EventId);
                deletedERs.add(worker);
            }
        }
        
        try {
            delete deletedERs;
        } catch (DMLException error) {
            System.debug(error);
        }
        
        updateEventWorkers(affectedEventIds, -1); //always -1 because no feature to delete >1 client/worker in 1 event
    }
    
    @AuraEnabled
    public static Event getEvent(Id eventId) {
        return [SELECT id, isRecurrence__c, Event_Status__c, OwnerId, Event_Type__c FROM Event WHERE id =: eventId];
    }
    
    @AuraEnabled
    public static Event updateEvent(Id eventId, String status) {
        Event e = [SELECT id, Event_Status__c FROM Event WHERE id =: eventId];
        
        e.Event_Status__c = status;
        
        try {
            update e;
        } catch (DMLException err) {
            System.debug(err);
        }
        
        return e;
    }
    
    /*@AuraEnabled
    public static Boolean validPermissionChecker(Event e, String rowRelatedId, String rtype) {
        return IdsEqual(e.OwnerId, UserInfo.getUserId()) || isSysAdmin() || (rtype == 'ER' && contactIsUser(rowRelatedId, UserInfo.getUserId())) || (rtype == 'CER' && getEROfContact(e.Id, getContactFromUser(UserInfo.getUserId())).size() > 0);
    }*/
    
    private static List<Map<String, Object>> buildReturnCERs(List<Client_Event_Relation__c> cers) {
        List<Map<String, Object>> myobjs = new List<Map<String, Object>>();
        String baseURL = URL.getSalesforceBaseUrl().toExternalForm();
        
        for (Client_Event_Relation__c o : cers) {
            Map<String, Object> obj = new Map<String, Object>();
            
            obj.put('id', o.Id);
            obj.put('name', o.Client__r.Name);
            obj.put('lookupId', o.Client__r.Id);
            obj.put('status', o.Status__c);
            obj.put('type', 'CER');
            obj.put('cerLink', baseURL + '/' + o.Id);
            obj.put('contactLink', baseURL + '/' + o.Client__r.Id);
            
            myobjs.add(obj);
        }
        
        return myobjs;
    }
    
    private static List<Map<String, Object>> buildReturnERs(List<EventRelation> ers) {
        List<Map<String, Object>> myobjs = new List<Map<String, Object>>();
        String baseURL = URL.getSalesforceBaseUrl().toExternalForm();
        
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
            
            myobjs.add(obj);
        }
        
        return myobjs;
    }
    
    private static void updateEventClients(List<Id> eventIds, Integer change) {
        List<Event> updatedEvents = new List<Event>();
        
        System.debug('List of eventIds: ' + eventIds);
        System.debug('change: ' + change);
        
        
        
        for(Event e : [SELECT id, Number_of_Clients__c, Event_Status__c FROM Event WHERE id IN: eventIds]){   
            
            if(e.Number_of_Clients__c != NULL){ 
                e.Number_of_Clients__c = e.Number_of_Clients__c + change;
                e.Event_Status__c = e.Number_of_Clients__c == 0 ? 'Cancelled' : e.Event_Status__c;
                
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
    
    private static void updateEventWorkers(List<Id> eventIds, Integer change) {
        List<Event> updatedEvents = new List<Event>();        
        
        for(Event e : [SELECT id, Number_of_Workers__c, Event_Status__c FROM Event WHERE id IN: eventIds]){  
            
            if(e.Number_of_Workers__c != NULL){                
                e.Number_of_Workers__c = e.Number_of_Workers__c + change;
                e.Event_Status__c = e.Number_of_Workers__c == 0 ? 'Cancelled' : e.Event_Status__c;
            }
            
            updatedEvents.add(e);
        }

        try {
            update updatedEvents;
        } catch(DMLException error) {
            System.debug(error);
        }
    }
    
    private static String translateStatus(String erStatus) {
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
    
    private static Boolean IdsEqual(Id one, Id two) {
        return one == two;
    }
    
    private static Boolean isSysAdmin() {
        return [SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId()].Name == 'System Administrator';
    }
    
    private static Boolean contactIsUser(Id contactId, Id userId) {
        return IdsEqual([SELECT enrtcr__User__c FROM Contact WHERE id =: contactId].enrtcr__User__c, userId);
    }
    
    private static Id getContactFromUser(Id userId) {
        return [SELECT id FROM Contact WHERE enrtcr__User__c =: userId][0].id;
    }
    
    private static List<EventRelation> getEROfContact(Id eventId, Id contactId) {
        return [SELECT id FROM EventRelation WHERE EventId =: eventId AND RelationId =: contactId LIMIT 1];
    }
    
    public class Relation {
        public Id id;
        public String name;
        public Id lookupId;
        public String status;
        public String type;
        public String cerLink;
        public String contactLink;
    }
}