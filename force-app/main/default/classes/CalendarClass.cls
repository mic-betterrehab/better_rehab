public class CalendarClass {
    public class Worker {
        public String Id;
        public String Name;
    }

    public class Client {
        public String Id;
        public String Name;
    }

    public class Site {
        public String Id;
        public String Name;
    }

    public class EventDetail {
        public String subject;
        public String startTime;
        public String endTime;
        public String eventType;
        public String clients;
        public String workers;
        public String serviceId;
        public String address;
        public String status;
        public Boolean allDay;
        public Boolean reengagement;
        public String comments;
        public String link;
        public String eventLocation;
        public String mode;
        public String site;
    }

    public class RepeatDetail {
        public Boolean repeat;
        public String repeatFrequency; //repeat every
        public String  repeatTime; //repeat day/month/week
        public String  onAfter;
        public String  numberEvents; //cap of 20 events
        public Date    onDate; //date 100 days limit
        public Set<String> repeatDays;
        
    }
    
    public class EventUpdate {
        public String eventId;
        public String subject;
        public String startTime; 
        public String endTime;
        public String eventType;
        public String address;
        public String status;
        public String owner;
        public String comments;
        public String createdDate;
        public String lastModifiedDate;
        public String link;
        public String mode;
    }

}